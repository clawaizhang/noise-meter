/**
 * FFT内存池类
 * 提供32线程96数组的完全预分配内存管理
 * 解决8192点FFT + 1000ms间隔配置的性能瓶颈
 */
export class FFTMemoryPool {
  private static instance: FFTMemoryPool = new FFTMemoryPool()
  
  // 支持的FFT大小（从256开始，支持所有2的幂次方）
  private readonly SUPPORTED_FFT_SIZES = [256, 512, 1024, 2048, 4096, 8192];
  
  // 每个FFT大小预分配96个数组（32线程 × 3数组）
  private readonly TOTAL_ARRAYS = 192;
  
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
        arrays.push(new Float32Array(size).fill(0));
        usage.push(false); // 初始状态为未使用
      }
      
      this.memoryPools.set(size, arrays);
      this.usageStatus.set(size, usage);
      console.info(`[FFTMemoryPool] 为FFT大小${size}预分配了96个数组`);
    }
  }
  
  /**
   * 获取指定长度的数组（从索引0开始顺序分配）
   * @param arraySize 需要的数组长度
   * @returns Float32Array | null
   */
  public getArray(arraySize: number): Float32Array | null {
    // 找到支持的最小FFT大小
    const supportedSize = this.findSupportedSize(arraySize);
    if (!supportedSize) {
      console.warn(`[FFTMemoryPool] 不支持的数组大小: ${arraySize}`);
      return null;
    }
    
    const arrays = this.memoryPools.get(supportedSize);
    const usage = this.usageStatus.get(supportedSize);
    
    if (!arrays || !usage) {
      console.warn(`[FFTMemoryPool] 无法找到大小为${supportedSize}的内存池`);
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
   * @param array 要释放的数组
   * @param size 数组的大小
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
   * @param requiredSize 需要的数组大小
   * @returns number | null
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
   * @param arraySize 数组大小
   * @returns 可用数组数量
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
   * 清理所有数组内容并重置使用状态
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
