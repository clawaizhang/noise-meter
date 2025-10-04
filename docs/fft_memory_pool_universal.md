# FFT内存池通用化方案

## 设计理念

**支持从256开始的FFT大小，让内存池更通用化，用户直接传入需要的数组长度即可**

## 通用化实现方案

```typescript
export class FFTMemoryPool {
  private static instance: FFTMemoryPool | null = null;
  
  // 支持的FFT大小（从256开始，支持所有2的幂次方）
  private readonly SUPPORTED_FFT_SIZES = [256, 512, 1024, 2048, 4096, 8192];
  
  // 每个FFT大小预分配96个数组（32线程 × 3数组）
  private readonly TOTAL_ARRAYS_PER_SIZE = 96;
  
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
      for (let i = 0; i < this.TOTAL_ARRAYS_PER_SIZE; i++) {
        arrays.push(new Float32Array(size));
      }
      
      this.memoryPools.set(size, arrays);
      console.info(`[FFTMemoryPool] 为FFT大小${size}预分配了96个数组`);
    }
  }
  
  /**
   * 获取指定长度的数组
   */
  public getArray(arraySize: number, index: number): Float32Array | null {
    // 找到支持的最小FFT大小
    const supportedSize = this.findSupportedSize(arraySize);
    if (!supportedSize) {
      return null;
    }
    
    const arrays = this.memoryPools.get(supportedSize);
    if (!arrays || index >= arrays.length) {
      return null;
    }
    
    // 返回对应的数组（用户自己负责使用正确的长度）
    return arrays[index];
  }
  
  /**
   * 获取数组组（real, imag, spectrum）
   */
  public getArrays(fftSize: number, threadIndex: number): { real: Float32Array; imag: Float32Array; spectrum: Float32Array } | null {
    const baseIndex = threadIndex * 3;
    
    // 获取实部数组（完整FFT大小）
    const real = this.getArray(fftSize, baseIndex);
    // 获取虚部数组（完整FFT大小）
    const imag = this.getArray(fftSize, baseIndex + 1);
    // 获取频谱数组（一半大小）
    const spectrum = this.getArray(fftSize / 2, baseIndex + 2);
    
    if (!real || !imag || !spectrum) {
      return null;
    }
    
    return { real, imag, spectrum };
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
   * 获取可用的数组组数量
   */
  public getAvailableCount(): number {
    return Math.floor(this.TOTAL_ARRAYS_PER_SIZE / 3);
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

## 使用方式

### 方式1：直接获取单个数组
```typescript
// 获取8192长度的数组（索引0）
const realArray = memoryPool.getArray(8192, 0);

// 获取4096长度的数组（索引1）
const spectrumArray = memoryPool.getArray(4096, 1);

// 获取2048长度的数组（索引2）
const smallArray = memoryPool.getArray(2048, 2);
```

### 方式2：获取完整的FFT数组组
```typescript
// 获取第0组FFT数组（线程0使用）
const arrays0 = memoryPool.getArrays(8192, 0);
if (arrays0) {
  // arrays0.real: 8192长度的实部数组
  // arrays0.imag: 8192长度的虚部数组  
  // arrays0.spectrum: 4096长度的频谱数组
}

// 获取第1组FFT数组（线程1使用）
const arrays1 = memoryPool.getArrays(4096, 1);
if (arrays1) {
  // arrays1.real: 4096长度的实部数组
  // arrays1.imag: 4096长度的虚部数组
  // arrays1.spectrum: 2048长度的频谱数组
}
```

## 在FFTAnalyzer中的通用集成

```typescript
public transform(input: ArrayBuffer, weightingType: WeightingType = WeightingType.A, threadIndex: number = 0): Float32Array {
  // 从内存池获取数组
  const memoryPool = FFTMemoryPool.getInstance();
  const arrays = memoryPool.getArrays(this.size, threadIndex);
  
  if (!arrays) {
    throw new Error('无法从内存池获取数组');
  }
  
  const { real, imag, spectrum } = arrays;
  
  // 注意：real和imag是this.size长度，spectrum是this.size/2长度
  // 用户需要自己确保使用正确的长度
  
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
  
  // 计算频谱（注意spectrum长度是this.size/2）
  for (let i = 0; i < spectrum.length; i++) {
    const frequency = i * freqResolution;
    const db = this.calculateDecibels(real[i], imag[i], frequency, weightingType);
    spectrum[i] = db;
  }
  
  // 平滑频谱
  return this.smoothMagnitudes(spectrum);
}
```

## 优势

1. **完全通用化**：支持从256开始的所有FFT大小
2. **灵活使用**：用户可以获取任意长度的数组
3. **自动适配**：自动找到支持的最小FFT大小
4. **保持极简**：仍然没有任何使用状态标记
5. **向后兼容**：支持现有的FFT大小需求

## 内存占用

- 256: 96 × 256 × 4字节 = 96KB
- 512: 96 × 512 × 4字节 = 192KB  
- 1024: 96 × 1024 × 4字节 = 384KB
- 2048: 96 × 2048 × 4字节 = 768KB
- 4096: 96 × 4096 × 4字节 = 1.5MB
- 8192: 96 × 8192 × 4字节 = 3MB

**总内存占用**: 约6MB固定预分配

这个通用化方案完全符合您的需求：**支持从256开始的FFT大小，让内存池更通用化，用户直接传入需要的数组长度即可**。