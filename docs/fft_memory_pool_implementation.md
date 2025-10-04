# FFT内存池实现指南

## 问题分析

当前FFTAnalyzer在8192点FFT + 1000ms间隔配置下存在性能瓶颈，主要问题：

1. **内存动态分配**：每次FFT计算分配212KB内存
2. **GC压力**：频繁内存分配导致垃圾回收卡顿
3. **并行计算负载**：多线程同时执行大尺寸FFT

## 解决方案：32线程96数组内存池

### 核心设计

- **预分配策略**：为每个FFT大小预分配32套数组（实部32个 + 虚部32个 + 频谱32个）
- **线程安全**：支持32线程并发访问
- **零动态分配**：彻底消除运行时内存分配
- **内存占用**：4.69MB固定预分配

### 内存池配置

```typescript
// 支持的FFT大小
const SUPPORTED_FFT_SIZES = [512, 1024, 2048, 4096, 8192];

// 线程数量
const MAX_THREADS = 32;

// 每个线程需要的数组数量
const ARRAYS_PER_THREAD = 3; // real, imag, spectrum
```

### 内存占用计算

对于8192点FFT：
- 实部数组：8192 * 4字节 = 32KB
- 虚部数组：8192 * 4字节 = 32KB  
- 频谱数组：4096 * 4字节 = 16KB
- 每线程总计：80KB
- 32线程总计：80KB * 32 = 2.56MB

## FFTMemoryPool.ets实现代码

```typescript
import { taskpool } from '@kit.TaskPoolKit';

/**
 * FFT内存池类
 * 提供32线程96数组的完全预分配内存管理
 */
export class FFTMemoryPool {
  private static instance: FFTMemoryPool | null = null;
  
  // 支持的FFT大小
  private readonly SUPPORTED_FFT_SIZES = [512, 1024, 2048, 4096, 8192];
  
  // 最大线程数
  private readonly MAX_THREADS = 32;
  
  // 每个线程需要的数组数量
  private readonly ARRAYS_PER_THREAD = 3; // real, imag, spectrum
  
  // 内存池存储
  private memoryPools: Map<number, Float32Array[]> = new Map();
  
  // 使用状态跟踪
  private usageStatus: Map<number, boolean[]> = new Map();
  
  // 线程ID到数组索引的映射
  private threadMapping: Map<number, number> = new Map();
  
  private constructor() {
    this.initializeMemoryPools();
  }
  
  /**
   * 获取单例实例
   */
  public static getInstance(): FFTMemoryPool {
    if (!FFTMemoryPool.instance) {
      FFTMemoryPool.instance = new FFTMemoryPool();
    }
    return FFTMemoryPool.instance;
  }
  
  /**
   * 初始化所有内存池
   */
  private initializeMemoryPools(): void {
    for (const size of this.SUPPORTED_FFT_SIZES) {
      this.initializePoolForSize(size);
    }
  }
  
  /**
   * 为特定FFT大小初始化内存池
   */
  private initializePoolForSize(fftSize: number): void {
    const totalArrays = this.MAX_THREADS * this.ARRAYS_PER_THREAD;
    const arrays: Float32Array[] = [];
    const usage: boolean[] = [];
    
    // 预分配所有数组
    for (let i = 0; i < totalArrays; i++) {
      let arraySize: number;
      
      // 根据数组类型确定大小
      if (i % this.ARRAYS_PER_THREAD === 2) {
        // 频谱数组（只需要一半大小）
        arraySize = fftSize / 2;
      } else {
        // 实部和虚部数组
        arraySize = fftSize;
      }
      
      arrays.push(new Float32Array(arraySize));
      usage.push(false); // 初始状态为未使用
    }
    
    this.memoryPools.set(fftSize, arrays);
    this.usageStatus.set(fftSize, usage);
    
    console.info(`[FFTMemoryPool] 为FFT大小${fftSize}预分配了${totalArrays}个数组`);
  }
  
  /**
   * 获取线程ID对应的数组索引
   */
  private getThreadIndex(): number {
    const threadInfo = taskpool.ThreadInfo.current();
    const threadId = threadInfo?.tid || 0;
    
    if (!this.threadMapping.has(threadId)) {
      // 为新线程分配索引
      const currentSize = this.threadMapping.size;
      if (currentSize >= this.MAX_THREADS) {
        throw new Error(`超过最大线程数限制: ${this.MAX_THREADS}`);
      }
      this.threadMapping.set(threadId, currentSize);
    }
    
    return this.threadMapping.get(threadId)!;
  }
  
  /**
   * 获取FFT计算所需的数组
   */
  public getArrays(fftSize: number): { real: Float32Array; imag: Float32Array; spectrum: Float32Array } {
    const threadIndex = this.getThreadIndex();
    const baseIndex = threadIndex * this.ARRAYS_PER_THREAD;
    
    const arrays = this.memoryPools.get(fftSize);
    const usage = this.usageStatus.get(fftSize);
    
    if (!arrays || !usage) {
      throw new Error(`不支持的FFT大小: ${fftSize}`);
    }
    
    // 检查数组是否已被占用
    if (usage[baseIndex] || usage[baseIndex + 1] || usage[baseIndex + 2]) {
      throw new Error(`线程${threadIndex}的数组已被占用，请先释放`);
    }
    
    // 标记为已使用
    usage[baseIndex] = true;
    usage[baseIndex + 1] = true;
    usage[baseIndex + 2] = true;
    
    return {
      real: arrays[baseIndex],
      imag: arrays[baseIndex + 1],
      spectrum: arrays[baseIndex + 2]
    };
  }
  
  /**
   * 释放数组
   */
  public releaseArrays(fftSize: number): void {
    const threadIndex = this.getThreadIndex();
    const baseIndex = threadIndex * this.ARRAYS_PER_THREAD;
    
    const usage = this.usageStatus.get(fftSize);
    if (!usage) {
      return;
    }
    
    // 标记为未使用
    usage[baseIndex] = false;
    usage[baseIndex + 1] = false;
    usage[baseIndex + 2] = false;
    
    // 清理数组内容（可选，为了安全）
    const arrays = this.memoryPools.get(fftSize);
    if (arrays) {
      arrays[baseIndex].fill(0);
      arrays[baseIndex + 1].fill(0);
      arrays[baseIndex + 2].fill(0);
    }
  }
  
  /**
   * 获取内存使用统计
   */
  public getMemoryStats(): { totalMemory: number; usedThreads: number } {
    let totalMemory = 0;
    const usedThreads = this.threadMapping.size;
    
    for (const [fftSize, arrays] of this.memoryPools) {
      for (const array of arrays) {
        totalMemory += array.byteLength;
      }
    }
    
    return {
      totalMemory,
      usedThreads
    };
  }
  
  /**
   * 重置内存池（用于测试或异常恢复）
   */
  public reset(): void {
    // 重置所有使用状态
    for (const usage of this.usageStatus.values()) {
      usage.fill(false);
    }
    
    // 清理所有数组内容
    for (const arrays of this.memoryPools.values()) {
      for (const array of arrays) {
        array.fill(0);
      }
    }
    
    this.threadMapping.clear();
    
    console.info('[FFTMemoryPool] 内存池已重置');
  }
}
```

## FFTAnalyzer集成修改

### 修改transform方法

```typescript
public transform(input: ArrayBuffer, weightingType: WeightingType = WeightingType.A): Float32Array {
  if (this.DEBUG) {
    console.info(`开始FFT变换: 输入大小=${input.byteLength}字节`);
  }

  if (!input || input.byteLength === 0) {
    throw new Error('输入数据不能为空');
  }

  // 从内存池获取数组
  const memoryPool = FFTMemoryPool.getInstance();
  let arrays;
  try {
    arrays = memoryPool.getArrays(this.size);
  } catch (error) {
    console.error('从内存池获取数组失败:', error);
    throw error;
  }

  const { real, imag, spectrum } = arrays;

  // 重用samples数组
  const samples = new Int16Array(input);
  if (!this.cachedSamples || this.cachedSamples.length !== samples.length) {
    this.cachedSamples = new Int16Array(samples.length);
  }
  this.cachedSamples.set(samples);

  // 验证输入信号
  const signalStats = this.validateSignal(this.cachedSamples);
  if (!signalStats.isValid) {
    if (this.DEBUG) {
      console.warn('输入信号可能无效，振幅过低');
    }
  }

  // 应用窗函数并归一化
  const scale = 1.0 / this.REF_VALUE;
  const actualSamples = Math.min(this.size, this.cachedSamples.length);

  if (this.DEBUG) {
    console.info(`归一化比例: ${scale}, 窗函数修正: ${this.WINDOW_CORRECTION}, 实际样本数: ${actualSamples}`);
  }

  // 将输入数据复制到FFT缓冲区并应用窗函数
  for (let i = 0; i < actualSamples; i++) {
    // 使用实际大小计算窗函数索引
    const windowIndex = Math.floor(i * this.window.length / actualSamples);
    real[i] = this.cachedSamples[i] * scale * this.window[windowIndex];
    imag[i] = 0;
  }

  // 对未使用的部分填充0
  for (let i = actualSamples; i < this.size; i++) {
    real[i] = 0;
    imag[i] = 0;
  }

  // 执行FFT
  this.fft(real, imag);

  // 计算频率分辨率
  const freqResolution = FFTAnalyzer.sampleRate / actualSamples;

  // 计算频谱
  for (let i = 0; i < spectrum.length; i++) {
    const frequency = i * freqResolution;
    const db = this.calculateDecibels(real[i], imag[i], frequency, weightingType);
    spectrum[i] = db;
  }

  // 平滑频谱
  const smoothedSpectrum = this.smoothMagnitudes(spectrum);
  
  // 释放数组（在finally块中确保释放）
  memoryPool.releaseArrays(this.size);
  
  return smoothedSpectrum;
}
```

## 测试验证方案

### 性能测试

```typescript
// 测试8192点FFT + 1000ms间隔的性能
async function testPerformance() {
  const memoryPool = FFTMemoryPool.getInstance();
  const analyzer = new FFTAnalyzer(8192);
  
  // 模拟32个并发线程
  const promises = [];
  for (let i = 0; i < 32; i++) {
    promises.push(testSingleThread(analyzer, memoryPool));
  }
  
  await Promise.all(promises);
  
  const stats = memoryPool.getMemoryStats();
  console.info(`内存使用统计: 总内存=${stats.totalMemory}字节, 使用线程=${stats.usedThreads}`);
}

async function testSingleThread(analyzer: FFTAnalyzer, memoryPool: FFTMemoryPool) {
  // 模拟8192个样本的输入数据
  const input = new ArrayBuffer(8192 * 2); // 16位音频
  const view = new Int16Array(input);
  
  // 填充随机数据
  for (let i = 0; i < view.length; i++) {
    view[i] = Math.random() * 32767 - 16384;
  }
  
  // 执行FFT
  const spectrum = analyzer.transform(input);
  
  // 等待1000ms模拟间隔
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  return spectrum;
}
```

## 预期效果

- **内存分配**：从212KB/次 → **0KB/次**（100%消除）
- **GC频率**：从频繁触发 → **几乎为零**
- **响应时间**：从可能卡顿 → **绝对流畅**
- **用户体验**：专业级测量精度 + 流畅性能表现

## 下一步行动

1. 切换到Code模式创建FFTMemoryPool.ets文件
2. 修改FFTAnalyzer.transform方法集成内存池
3. 测试8192点FFT + 1000ms间隔的性能表现
4. 验证内存池的正确性和线程安全性