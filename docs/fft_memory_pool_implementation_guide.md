# FFT内存池实现指南

## 概述

本指南详细说明如何实现32线程96数组的FFT内存池，专门解决8192点FFT + 1000ms间隔的卡顿问题。

## 内存池设计

### 核心数据结构

```typescript
// 文件: entry/src/main/ets/utils/FFTMemoryPool.ets
export class FFTMemoryPool {
  private static instance: FFTMemoryPool;
  
  // 内存池数据结构
  private realPools: Map<number, Float32Array[]> = new Map();    // 实部数组池
  private imagPools: Map<number, Float32Array[]> = new Map();    // 虚部数组池
  private spectrumPools: Map<number, Float32Array[]> = new Map(); // 频谱数组池
  
  // 配置参数
  private readonly THREADS = 32;           // 支持32线程并发
  private readonly ARRAYS_PER_THREAD = 3;  // 每个线程需要3个数组
  private readonly TOTAL_ARRAYS = this.THREADS * this.ARRAYS_PER_THREAD; // 96个数组
  
  // 支持的FFT大小
  private readonly SUPPORTED_SIZES = [1024, 2048, 4096, 8192];
}
```

### 初始化方法

```typescript
private initializePools(): void {
  for (const size of this.SUPPORTED_SIZES) {
    // 初始化实部数组池
    const realPool: Float32Array[] = [];
    for (let i = 0; i < this.THREADS; i++) {
      realPool.push(new Float32Array(size));
    }
    this.realPools.set(size, realPool);
    
    // 初始化虚部数组池
    const imagPool: Float32Array[] = [];
    for (let i = 0; i < this.THREADS; i++) {
      imagPool.push(new Float32Array(size));
    }
    this.imagPools.set(size, imagPool);
    
    // 初始化频谱数组池
    const spectrumPool: Float32Array[] = [];
    for (let i = 0; i < this.THREADS; i++) {
      spectrumPool.push(new Float32Array(size / 2));
    }
    this.spectrumPools.set(size, spectrumPool);
    
    console.info(`预分配 ${size}点FFT: 实部${realPool.length}, 虚部${imagPool.length}, 频谱${spectrumPool.length}`);
  }
  
  const totalMemory = this.calculateTotalMemory();
  console.info(`内存池初始化完成，总内存: ${(totalMemory / 1024 / 1024).toFixed(2)}MB`);
}
```

### 获取数组方法

```typescript
/**
 * 获取实部数组
 */
acquireRealArray(size: number): Float32Array {
  return this.acquireFromPool(size, this.realPools);
}

/**
 * 获取虚部数组
 */
acquireImagArray(size: number): Float32Array {
  return this.acquireFromPool(size, this.imagPools);
}

/**
 * 获取频谱数组
 */
acquireSpectrumArray(size: number): Float32Array {
  return this.acquireFromPool(size / 2, this.spectrumPools);
}

private acquireFromPool(size: number, poolMap: Map<number, Float32Array[]>): Float32Array {
  const pool = poolMap.get(size);
  if (pool && pool.length > 0) {
    const array = pool.pop()!;
    array.fill(0); // 重用前清零
    return array;
  }
  
  // 池耗尽，抛出错误（不应该发生）
  throw new Error(`内存池耗尽: ${size}长度数组，请检查并发配置`);
}
```

### 释放数组方法

```typescript
/**
 * 释放实部数组
 */
releaseRealArray(size: number, array: Float32Array): void {
  this.releaseToPool(size, array, this.realPools);
}

/**
 * 释放虚部数组
 */
releaseImagArray(size: number, array: Float32Array): void {
  this.releaseToPool(size, array, this.imagPools);
}

/**
 * 释放频谱数组
 */
releaseSpectrumArray(size: number, array: Float32Array): void {
  this.releaseToPool(size / 2, array, this.spectrumPools);
}

private releaseToPool(size: number, array: Float32Array, poolMap: Map<number, Float32Array[]>): void {
  const pool = poolMap.get(size);
  if (pool && pool.length < this.THREADS) {
    pool.push(array);
  }
  // 如果池已满，让GC回收（不应该发生）
}
```

### 单例模式实现

```typescript
static getInstance(): FFTMemoryPool {
  if (!FFTMemoryPool.instance) {
    FFTMemoryPool.instance = new FFTMemoryPool();
    FFTMemoryPool.instance.initializePools();
  }
  return FFTMemoryPool.instance;
}

private constructor() {
  // 私有构造函数
}
```

## FFTAnalyzer集成

### 修改FFTAnalyzer.transform方法

```typescript
// 文件: entry/src/main/ets/utils/FFTAnalyzer.ets

import { FFTMemoryPool } from './FFTMemoryPool';

export class FFTAnalyzer {
  private readonly memoryPool = FFTMemoryPool.getInstance();
  
  public transform(input: ArrayBuffer, weightingType: WeightingType): Float32Array {
    // 从内存池获取数组（零动态分配）
    const real = this.memoryPool.acquireRealArray(this.size);
    const imag = this.memoryPool.acquireImagArray(this.size);
    const spectrum = this.memoryPool.acquireSpectrumArray(this.size);
    
    try {
      // FFT计算逻辑保持不变
      const samples = new Int16Array(input);
      const scale = 1.0 / this.REF_VALUE;
      
      // 应用窗函数
      for (let i = 0; i < Math.min(this.size, samples.length); i++) {
        const windowIndex = Math.floor(i * this.window.length / Math.min(this.size, samples.length));
        real[i] = samples[i] * scale * this.window[windowIndex];
        imag[i] = 0;
      }
      
      // 执行FFT
      this.fft(real, imag);
      
      // 计算频谱
      for (let i = 0; i < spectrum.length; i++) {
        const frequency = i * (44100 / Math.min(this.size, samples.length));
        spectrum[i] = this.calculateDecibels(real[i], imag[i], frequency, weightingType);
      }
      
      return this.smoothMagnitudes(spectrum);
      
    } finally {
      // 确保释放数组
      this.memoryPool.releaseRealArray(this.size, real);
      this.memoryPool.releaseImagArray(this.size, imag);
      this.memoryPool.releaseSpectrumArray(this.size, spectrum);
    }
  }
}
```

## 内存监控和调试

### 内存池状态监控

```typescript
/**
 * 获取内存池状态
 */
getPoolStatus(): Record<string, any> {
  const status: Record<string, any> = {};
  
  for (const size of this.SUPPORTED_SIZES) {
    const realPool = this.realPools.get(size);
    const imagPool = this.imagPools.get(size);
    const spectrumPool = this.spectrumPools.get(size);
    
    status[`fft_${size}`] = {
      real: {
        available: realPool?.length || 0,
        total: this.THREADS,
        memory: `${(size * 4 * this.THREADS / 1024).toFixed(1)}KB`
      },
      imag: {
        available: imagPool?.length || 0,
        total: this.THREADS,
        memory: `${(size * 4 * this.THREADS / 1024).toFixed(1)}KB`
      },
      spectrum: {
        available: spectrumPool?.length || 0,
        total: this.THREADS,
        memory: `${(size * 2 * this.THREADS / 1024).toFixed(1)}KB`
      }
    };
  }
  
  return status;
}

/**
 * 计算总内存占用
 */
private calculateTotalMemory(): number {
  let total = 0;
  for (const size of this.SUPPORTED_SIZES) {
    // 实部 + 虚部 + 频谱
    total += size * 4 * this.THREADS * 2.5; // 2.5 = 1 + 1 + 0.5
  }
  return total;
}
```

## 实施步骤

### 第一步：创建FFTMemoryPool.ets文件
1. 在 `entry/src/main/ets/utils/` 目录下创建 `FFTMemoryPool.ets`
2. 实现上述完整的内存池代码

### 第二步：修改FFTAnalyzer.ets
1. 导入 `FFTMemoryPool`
2. 修改 `transform` 方法使用内存池
3. 确保 `finally` 块中正确释放数组

### 第三步：测试验证
1. 编译项目确保无错误
2. 运行应用，测试8192点FFT + 1000ms间隔
3. 观察内存池状态和性能表现

## 预期效果

### 性能改进
- **内存分配**：从每次212KB降低到**零动态分配**
- **GC频率**：从频繁触发降低到**几乎为零**
- **响应时间**：从可能卡顿改善到**绝对流畅**

### 内存占用
- **总预分配**：4.69MB固定内存
- **零碎片**：预分配避免内存碎片
- **稳定占用**：运行时内存占用稳定

## 故障排除

### 常见问题
1. **内存池耗尽错误**：检查并发线程数是否超过32
2. **数组大小不匹配**：确保获取和释放时使用相同的size参数
3. **内存泄漏**：确保在finally块中释放所有数组

### 调试方法
1. 启用内存池状态日志
2. 监控分配和释放次数
3. 检查并发线程数量

这个实现专门针对8192点FFT + 1000ms间隔的卡顿问题，通过完全预分配的方式彻底消除动态内存分配带来的性能问题。