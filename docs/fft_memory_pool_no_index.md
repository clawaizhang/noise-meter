# FFT内存池无索引极简方案

## 设计理念

**内存池只预分配96个数组，FFT每次随机取3个用，用完也不需要标记，不需要索引**

## 无索引极简实现方案

```typescript
export class FFTMemoryPool {
  private static instance: FFTMemoryPool | null = null;
  
  // 支持的FFT大小（从256开始，支持所有2的幂次方）
  private readonly SUPPORTED_FFT_SIZES = [256, 512, 1024, 2048, 4096, 8192];
  
  // 每个FFT大小预分配96个数组
  private readonly TOTAL_ARRAYS = 96;
  
  // 内存池存储：FFT大小 -> 数组列表
  private memoryPools: Map<number, Float32Array[]> = new Map();
  
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
   * 初始化内存池
   */
  private initializeMemoryPools(): void {
    for (const size of this.SUPPORTED_FFT_SIZES) {
      const arrays: Float32Array[] = [];
      
      // 预分配96个数组，所有数组都是完整大小
      for (let i = 0; i < this.TOTAL_ARRAYS; i++) {
        arrays.push(new Float32Array(size));
      }
      
      this.memoryPools.set(size, arrays);
      console.info(`[FFTMemoryPool] 为FFT大小${size}预分配了96个数组`);
    }
  }
  
  /**
   * 获取指定长度的数组（随机返回一个）
   */
  public getArray(arraySize: number): Float32Array | null {
    // 找到支持的最小FFT大小
    const supportedSize = this.findSupportedSize(arraySize);
    if (!supportedSize) {
      return null;
    }
    
    const arrays = this.memoryPools.get(supportedSize);
    if (!arrays || arrays.length === 0) {
      return null;
    }
    
    // 随机返回一个数组（不需要索引，不需要标记）
    const randomIndex = Math.floor(Math.random() * arrays.length);
    return arrays[randomIndex];
  }
  
  /**
   * 找到支持的最小FFT大小
   */
  private findSupportedSize(requiredSize: number): number | null {
    for (const size of this.SUPPORTED_FFT_SIZES) {
      if (size >= requiredSize) {
        return size;
      }
    }
    return null;
  }
  
  /**
   * 获取可用的数组数量
   */
  public getAvailableCount(): number {
    return this.TOTAL_ARRAYS;
  }
  
  /**
   * 清理所有数组内容（可选）
   */
  public clearArrays(): void {
    for (const arrays of this.memoryPools.values()) {
      for (const array of arrays) {
        array.fill(0);
      }
    }
  }
}
```

## 在FFTAnalyzer中的无索引使用

```typescript
public transform(input: ArrayBuffer, weightingType: WeightingType = WeightingType.A): Float32Array {
  // 从内存池获取数组
  const memoryPool = FFTMemoryPool.getInstance();
  
  // FFT里面需要3个数组，就调用3次getArray（不需要索引）
  const real = memoryPool.getArray(this.size);
  const imag = memoryPool.getArray(this.size);
  const spectrum = memoryPool.getArray(this.size / 2);
  
  if (!real || !imag || !spectrum) {
    throw new Error('无法从内存池获取数组');
  }
  
  // 重用samples数组
  const samples = new Int16Array(input);
  if (!this.cachedSamples || this.cachedSamples.length !== samples.length) {
    this.cachedSamples = new Int16Array(samples.length);
  }
  this.cachedSamples.set(samples);
  
  // 应用窗函数并归一化
  const scale = 1.0 / this.REF_VALUE;
  const actualSamples = Math.min(this.size, this.cachedSamples.length);
  
  // 将输入数据复制到FFT缓冲区并应用窗函数
  for (let i = 0; i < actualSamples; i++) {
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
  return this.smoothMagnitudes(spectrum);
}
```

## 核心特点

### 内存池职责（极简）
- ✅ 预分配96个数组
- ✅ 随机返回一个数组
- ❌ 不需要索引
- ❌ 不需要使用状态标记
- ❌ 不关心数组用途
- ❌ 没有释放逻辑

### FFT职责
- ✅ 需要3个数组就调用3次getArray
- ✅ 不需要传递索引
- ✅ 自己管理数组用途
- ✅ 自己确保使用正确的长度

## 使用方式（极简）

```typescript
// 线程0：需要3个数组就调用3次getArray
const real0 = memoryPool.getArray(8192);
const imag0 = memoryPool.getArray(8192);
const spectrum0 = memoryPool.getArray(4096);

// 线程1：需要3个数组就调用3次getArray
const real1 = memoryPool.getArray(8192);
const imag1 = memoryPool.getArray(8192);
const spectrum1 = memoryPool.getArray(4096);

// 线程2：需要3个数组就调用3次getArray
const real2 = memoryPool.getArray(8192);
const imag2 = memoryPool.getArray(8192);
const spectrum2 = memoryPool.getArray(4096);

// 以此类推，最多32个线程同时调用
```

## 优势

1. **极简设计**：内存池只有预分配和随机返回数组两个功能
2. **零索引**：不需要任何索引管理
3. **零状态**：没有任何使用状态标记
4. **完全通用**：支持所有FFT大小
5. **高性能**：直接数组访问
6. **易于维护**：逻辑极其简单清晰

## 内存占用

- 256: 96 × 256 × 4字节 = 96KB
- 512: 96 × 512 × 4字节 = 192KB  
- 1024: 96 × 1024 × 4字节 = 384KB
- 2048: 96 × 2048 × 4字节 = 768KB
- 4096: 96 × 4096 × 4字节 = 1.5MB
- 8192: 96 × 8192 × 4字节 = 3MB

**总内存占用**: 约6MB固定预分配

这个无索引方案完全符合您的需求：**内存池只预分配96个数组，FFT每次随机取3个用，用完也不需要标记，不需要索引**。