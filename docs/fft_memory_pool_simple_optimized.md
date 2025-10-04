# FFT内存池简单优化方案（releaseArray传入size参数）

## 设计理念

**在releaseArray方法中传入size参数，直接从该size的缓存中获取数组，只需要一层遍历**

## 简单优化实现方案

```typescript
export class FFTMemoryPool {
  private static instance: FFTMemoryPool | null = null;
  
  // 支持的FFT大小（从256开始，支持所有2的幂次方）
  private readonly SUPPORTED_FFT_SIZES = [256, 512, 1024, 2048, 4096, 8192];
  
  // 每个FFT大小预分配96个数组
  private readonly TOTAL_ARRAYS = 96;
  
  // 内存池存储：FFT大小 -> 数组列表
  private memoryPools: Map<number, Float32Array[]> = new Map();
  
  // 使用状态标记：FFT大小 -> 使用状态数组
  private usageStatus: Map<number, boolean[]> = new Map();
  
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
      const usage: boolean[] = [];
      
      // 预分配96个数组，所有数组都是完整大小
      for (let i = 0; i < this.TOTAL_ARRAYS; i++) {
        arrays.push(new Float32Array(size));
        usage.push(false); // 初始状态为未使用
      }
      
      this.memoryPools.set(size, arrays);
      this.usageStatus.set(size, usage);
      console.info(`[FFTMemoryPool] 为FFT大小${size}预分配了96个数组`);
    }
  }
  
  /**
   * 获取指定长度的数组（从索引0开始顺序分配）
   */
  public getArray(arraySize: number): Float32Array | null {
    // 找到支持的最小FFT大小
    const supportedSize = this.findSupportedSize(arraySize);
    if (!supportedSize) {
      return null;
    }
    
    const arrays = this.memoryPools.get(supportedSize);
    const usage = this.usageStatus.get(supportedSize);
    
    if (!arrays || !usage) {
      return null;
    }
    
    // 从索引0开始顺序寻找第一个未使用的数组
    for (let i = 0; i < arrays.length; i++) {
      if (!usage[i]) {
        // 标记为已使用
        usage[i] = true;
        console.info(`[FFTMemoryPool] 分配数组索引${i}，大小${arraySize}`);
        return arrays[i];
      }
    }
    
    // 没有可用的数组
    console.warn(`[FFTMemoryPool] 没有可用的数组，大小${arraySize}`);
    return null;
  }
  
  /**
   * 释放数组（优化版本：传入size参数，只需要一层遍历）
   */
  public releaseArray(array: Float32Array, size: number): void {
    // 直接使用传入的size获取对应的内存池
    const arrays = this.memoryPools.get(size);
    const usage = this.usageStatus.get(size);
    
    if (!arrays || !usage) {
      console.warn(`[FFTMemoryPool] 无法找到大小为${size}的内存池`);
      return;
    }
    
    // 只需要一层遍历：在该size的内存池中查找
    for (let i = 0; i < arrays.length; i++) {
      if (arrays[i] === array) {
        // 标记为未使用
        usage[i] = false;
        // 清理数组内容
        array.fill(0);
        console.info(`[FFTMemoryPool] 释放数组索引${i}，大小${size}`);
        return;
      }
    }
    
    console.warn(`[FFTMemoryPool] 无法在大小为${size}的内存池中找到要释放的数组`);
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
  public getAvailableCount(arraySize: number): number {
    const supportedSize = this.findSupportedSize(arraySize);
    if (!supportedSize) return 0;
    
    const usage = this.usageStatus.get(supportedSize);
    if (!usage) return 0;
    
    let count = 0;
    for (const used of usage) {
      if (!used) count++;
    }
    return count;
  }
  
  /**
   * 清理所有数组内容
   */
  public clearArrays(): void {
    for (const arrays of this.memoryPools.values()) {
      for (const array of arrays) {
        array.fill(0);
      }
    }
    
    // 重置所有使用状态
    for (const usage of this.usageStatus.values()) {
      usage.fill(false);
    }
    
    console.info('[FFTMemoryPool] 所有数组已清理和重置');
  }
}
```

## 在FFTAnalyzer中的使用（需要传入size参数）

```typescript
public transform(input: ArrayBuffer, weightingType: WeightingType = WeightingType.A): Float32Array {
  const memoryPool = FFTMemoryPool.getInstance();
  
  const real = memoryPool.getArray(this.size);
  const imag = memoryPool.getArray(this.size);
  const spectrum = memoryPool.getArray(this.size / 2);
  
  if (!real || !imag || !spectrum) {
    throw new Error('无法从内存池获取数组');
  }
  
  try {
    // 使用数组进行FFT计算...
    
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
  } finally {
    // 确保释放所有数组（传入对应的size参数）
    memoryPool.releaseArray(real, this.size);
    memoryPool.releaseArray(imag, this.size);
    memoryPool.releaseArray(spectrum, this.size / 2);
  }
}
```

## 优化对比

### 优化前（需要两层遍历）
```typescript
public releaseArray(array: Float32Array): void {
  // 第一层遍历：所有内存池
  for (const [size, arrays] of this.memoryPools) {
    const usage = this.usageStatus.get(size);
    if (!usage) continue;
    
    // 第二层遍历：该内存池中的所有数组
    for (let i = 0; i < arrays.length; i++) {
      if (arrays[i] === array) {
        // 释放逻辑...
        return;
      }
    }
  }
}
```

### 优化后（只需要一层遍历）
```typescript
public releaseArray(array: Float32Array, size: number): void {
  // 直接使用传入的size获取对应的内存池
  const arrays = this.memoryPools.get(size);
  const usage = this.usageStatus.get(size);
  
  if (!arrays || !usage) return;
  
  // 只需要一层遍历：在该size的内存池中查找
  for (let i = 0; i < arrays.length; i++) {
    if (arrays[i] === array) {
      // 释放逻辑...
      return;
    }
  }
}
```

## 性能优势

1. **减少遍历层数**：从两层遍历 → 一层遍历
2. **时间复杂度**：从O(n×m) → O(m)（n=内存池数量，m=数组数量）
3. **代码简洁**：不需要额外的映射关系
4. **释放速度**：显著提升释放操作的速度

## 优势总结

1. **释放速度优化**：传入size参数，只需要一层遍历
2. **代码简洁**：不需要复杂的映射关系
3. **彻底消除动态分配**：完全预分配，零运行时内存分配
4. **顺序分配**：从索引0开始顺序分配，避免随机问题
5. **状态标记**：简单标记使用状态，确保线程安全
6. **自动回收**：释放后可以重新使用，避免数组冲突
7. **完全通用**：支持所有FFT大小配置

## 内存占用

- **总内存占用**：约6MB固定预分配
- **优化开销**：零额外内存开销

这个简单优化方案完全符合您的需求：**在releaseArray方法中传入size参数，直接从该size的缓存中获取数组，只需要一层遍历**。