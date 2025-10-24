/**
 * 内存对象池管理器
 * 用于复用Float32Array等对象，减少GC压力
 */

/**
 * 内存池配置接口
 */
export interface MemoryPoolConfig {
  maxPoolSize: number;        // 最大池大小
  initialSize: number;        // 初始大小
  growFactor: number;         // 增长因子
  shrinkThreshold: number;    // 收缩阈值
}

/**
 * 默认内存池配置
 */
export const DefaultMemoryPoolConfig: MemoryPoolConfig = {
  maxPoolSize: 100,
  initialSize: 20,
  growFactor: 1.5,
  shrinkThreshold: 0.3
};

/**
 * 内存池统计信息
 */
export interface MemoryPoolStats {
  poolSize: number;
  availableCount: number;
  allocatedCount: number;
  totalMemoryBytes: number;
  hitRate: number;
}

/**
 * Float32Array内存池
 */
export class Float32ArrayPool {
  private pool: Float32Array[] = [];
  private allocated: Set<Float32Array> = new Set();
  private config: MemoryPoolConfig;
  private totalRequests: number = 0;
  private hitCount: number = 0;

  constructor(config: MemoryPoolConfig = DefaultMemoryPoolConfig) {
    this.config = config;
    this.initializePool();
  }

  /**
   * 初始化内存池
   */
  private initializePool(): void {
    for (let i = 0; i < this.config.initialSize; i++) {
      this.pool.push(new Float32Array(0));
    }
    console.info(`[MemoryPool] 初始化Float32Array池，大小: ${this.pool.length}`);
  }

  /**
   * 获取指定长度的Float32Array
   * @param length 数组长度
   * @returns Float32Array实例
   */
  acquire(length: number): Float32Array {
    this.totalRequests++;

    // 查找可复用的数组
    for (let i = 0; i < this.pool.length; i++) {
      const array = this.pool[i];
      if (array.length >= length) {
        // 从池中移除
        this.pool.splice(i, 1);
        this.allocated.add(array);
        this.hitCount++;
        
        // 如果长度不匹配，重新创建
        if (array.length !== length) {
          const newArray = new Float32Array(length);
          this.allocated.delete(array);
          this.allocated.add(newArray);
          return newArray;
        }
        
        return array;
      }
    }

    // 池中没有合适的数组，创建新的
    const newArray = new Float32Array(length);
    this.allocated.add(newArray);
    return newArray;
  }

  /**
   * 释放Float32Array回池中
   * @param array 要释放的数组
   */
  release(array: Float32Array): void {
    if (!this.allocated.has(array)) {
      console.warn('[MemoryPool] 尝试释放未分配的数组');
      return;
    }

    this.allocated.delete(array);

    // 检查是否需要收缩池
    if (this.pool.length >= this.config.maxPoolSize) {
      // 池已满，丢弃这个数组
      return;
    }

    // 清空数组内容（可选，为了安全）
    array.fill(0);

    // 添加到池中
    this.pool.push(array);
  }

  /**
   * 批量获取多个Float32Array
   * @param lengths 长度数组
   * @returns Float32Array数组
   */
  acquireBatch(lengths: number[]): Float32Array[] {
    const arrays: Float32Array[] = [];
    for (const length of lengths) {
      arrays.push(this.acquire(length));
    }
    return arrays;
  }

  /**
   * 批量释放多个Float32Array
   * @param arrays 要释放的数组
   */
  releaseBatch(arrays: Float32Array[]): void {
    for (const array of arrays) {
      this.release(array);
    }
  }

  /**
   * 智能收缩池大小
   */
  shrink(): void {
    const currentSize = this.pool.length;
    const targetSize = Math.floor(currentSize * this.config.shrinkThreshold);
    
    if (currentSize > targetSize) {
      const removeCount = currentSize - targetSize;
      this.pool.splice(0, removeCount);
      console.info(`[MemoryPool] 收缩池大小: ${currentSize} -> ${targetSize}`);
    }
  }

  /**
   * 智能扩展池大小
   */
  grow(): void {
    const currentSize = this.pool.length;
    const targetSize = Math.min(
      Math.floor(currentSize * this.config.growFactor),
      this.config.maxPoolSize
    );
    
    if (targetSize > currentSize) {
      const addCount = targetSize - currentSize;
      for (let i = 0; i < addCount; i++) {
        this.pool.push(new Float32Array(0));
      }
      console.info(`[MemoryPool] 扩展池大小: ${currentSize} -> ${targetSize}`);
    }
  }

  /**
   * 获取内存池统计信息
   */
  getStats(): MemoryPoolStats {
    const poolSize = this.pool.length;
    const allocatedCount = this.allocated.size;
    const availableCount = poolSize;
    const totalMemoryBytes = this.calculateTotalMemory();
    const hitRate = this.totalRequests > 0 ? this.hitCount / this.totalRequests : 0;

    return {
      poolSize,
      availableCount,
      allocatedCount,
      totalMemoryBytes,
      hitRate
    };
  }

  /**
   * 计算总内存使用量
   */
  private calculateTotalMemory(): number {
    let totalBytes = 0;
    
    // 计算池中数组的内存
    for (const array of this.pool) {
      totalBytes += array.length * 4; // Float32Array每个元素4字节
    }
    
    // 计算已分配数组的内存
    for (const array of this.allocated) {
      totalBytes += array.length * 4;
    }
    
    return totalBytes;
  }

  /**
   * 清空内存池
   */
  clear(): void {
    this.pool = [];
    this.allocated.clear();
    this.totalRequests = 0;
    this.hitCount = 0;
    console.info('[MemoryPool] 清空内存池');
  }

  /**
   * 重置统计信息
   */
  resetStats(): void {
    this.totalRequests = 0;
    this.hitCount = 0;
  }
}

/**
 * 全局内存池管理器
 */
export class GlobalMemoryPoolManager {
  private static instance: GlobalMemoryPoolManager;
  private pools: Map<string, Float32ArrayPool> = new Map();

  private constructor() {
    // 初始化默认池
    this.createPool('default', DefaultMemoryPoolConfig);
    this.createPool('spectrum', {
      maxPoolSize: 50,
      initialSize: 10,
      growFactor: 1.2,
      shrinkThreshold: 0.4
    });
  }

  /**
   * 获取单例实例
   */
  static getInstance(): GlobalMemoryPoolManager {
    if (!GlobalMemoryPoolManager.instance) {
      GlobalMemoryPoolManager.instance = new GlobalMemoryPoolManager();
    }
    return GlobalMemoryPoolManager.instance;
  }

  /**
   * 创建内存池
   */
  createPool(name: string, config: MemoryPoolConfig): Float32ArrayPool {
    const pool = new Float32ArrayPool(config);
    this.pools.set(name, pool);
    return pool;
  }

  /**
   * 获取内存池
   */
  getPool(name: string): Float32ArrayPool | undefined {
    return this.pools.get(name);
  }

  /**
   * 获取默认内存池
   */
  getDefaultPool(): Float32ArrayPool {
    return this.pools.get('default')!;
  }

  /**
   * 获取频谱数据内存池
   */
  getSpectrumPool(): Float32ArrayPool {
    return this.pools.get('spectrum')!;
  }

  /**
   * 获取所有内存池统计信息
   */
  getAllStats(): Map<string, MemoryPoolStats> {
    const stats = new Map<string, MemoryPoolStats>();
    for (const entry of this.pools) {
      const name = entry[0];
      const pool = entry[1];
      stats.set(name, pool.getStats());
    }
    return stats;
  }

  /**
   * 定期维护所有内存池
   */
  maintenance(): void {
    for (const entry of this.pools) {
      const name = entry[0];
      const pool = entry[1];
      const stats = pool.getStats();
      
      // 根据命中率决定是否扩展或收缩
      if (stats.hitRate > 0.8) {
        pool.grow();
      } else if (stats.hitRate < 0.2) {
        pool.shrink();
      }
    }
  }
}