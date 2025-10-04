# FFT内存池极简实现方案

## 核心思想

**直接预分配96个数组，无需任何使用状态标记，用户直接使用**

## 极简实现方案

```typescript
export class FFTMemoryPool {
  private static instance: FFTMemoryPool | null = null;
  
  // 支持的FFT大小
  private readonly SUPPORTED_FFT_SIZES = [512, 1024, 2048, 4096, 8192];
  
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
      
      // 预分配96个数组
      for (let i = 0; i < this.TOTAL_ARRAYS_PER_SIZE; i++) {
        let arraySize: number;
        
        // 每3个数组为一组：real, imag, spectrum
        if (i % 3 === 2) {
          // 频谱数组（只需要一半大小）
          arraySize = size / 2;
        } else {
          // 实部和虚部数组
          arraySize = size;
        }
        
        arrays.push(new Float32Array(arraySize));
      }
      
      this.memoryPools.set(size, arrays);
      console.info(`[FFTMemoryPool] 为FFT大小${size}预分配了96个数组`);
    }
  }
  
  /**
   * 获取指定索引的数组组
   */
  public getArrays(fftSize: number, index: number): { real: Float32Array; imag: Float32Array; spectrum: Float32Array } | null {
    const arrays = this.memoryPools.get(fftSize);
    
    if (!arrays) {
      return null;
    }
    
    const baseIndex = index * 3;
    
    // 检查索引是否有效
    if (baseIndex + 2 >= arrays.length) {
      return null;
    }
    
    return {
      real: arrays[baseIndex],
      imag: arrays[baseIndex + 1],
      spectrum: arrays[baseIndex + 2]
    };
  }
  
  /**
   * 获取可用的数组组数量
   */
  public getAvailableCount(fftSize: number): number {
    const arrays = this.memoryPools.get(fftSize);
    return arrays ? Math.floor(arrays.length / 3) : 0;
  }
  
  /**
   * 清理所有数组内容（可选）
   */
  public clearArrays(fftSize: number): void {
    const arrays = this.memoryPools.get(fftSize);
    if (arrays) {
      for (const array of arrays) {
        array.fill(0);
      }
    }
  }
}
```

## 使用方式

```typescript
// 获取内存池实例
const memoryPool = FFTMemoryPool.getInstance();

// 获取第0组数组（线程0使用）
const arrays0 = memoryPool.getArrays(8192, 0);
if (arrays0) {
  // 直接使用 arrays0.real, arrays0.imag, arrays0.spectrum
  // 不需要释放标记
}

// 获取第1组数组（线程1使用）
const arrays1 = memoryPool.getArrays(8192, 1);
if (arrays1) {
  // 直接使用 arrays1.real, arrays1.imag, arrays1.spectrum
  // 不需要释放标记
}

// 以此类推，最多32个线程
```

## 在FFTAnalyzer中的集成

```typescript
public transform(input: ArrayBuffer, weightingType: WeightingType = WeightingType.A, threadIndex: number = 0): Float32Array {
  // 从内存池获取数组
  const memoryPool = FFTMemoryPool.getInstance();
  const arrays = memoryPool.getArrays(this.size, threadIndex);
  
  if (!arrays) {
    throw new Error('无法从内存池获取数组');
  }
  
  const { real, imag, spectrum } = arrays;
  
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

## 优势

1. **极简设计**：没有任何复杂的使用状态标记
2. **零动态分配**：完全预分配，彻底消除GC压力
3. **线程安全**：每个线程使用固定的数组组
4. **高性能**：直接数组访问，无额外开销
5. **易于维护**：逻辑极其简单

## 内存占用

对于8192点FFT：
- 实部数组：8192 * 4字节 = 32KB
- 虚部数组：8192 * 4字节 = 32KB  
- 频谱数组：4096 * 4字节 = 16KB
- 每线程总计：80KB
- 32线程总计：80KB * 32 = 2.56MB

这个方案完全符合您的需求：**直接预分配96个数组，用户直接拿来用，不需要任何使用状态标记**。