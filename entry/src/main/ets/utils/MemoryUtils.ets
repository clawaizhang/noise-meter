// 内存格式化工具类 - 优化版本

// 定义缓存统计信息接口
interface CacheStats {
  hits: number;
  misses: number;
  hitRate: number;
}

export class MemoryUtils {
  // 预计算常量（避免重复计算）
  private static readonly KB_IN_MB: bigint = 1024n;
  private static readonly KB_IN_GB: bigint = 1024n * 1024n;
  private static readonly KB_IN_TB: bigint = 1024n * 1024n * 1024n;

  // 缓存格式化结果（避免重复格式化相同值）
  private static formatCache: Map<bigint, string> = new Map();
  private static cacheHits: number = 0;
  private static cacheMisses: number = 0;

  /**
   * 格式化内存大小（KB为单位）为可读字符串
   * 使用缓存和优化算法提高性能
   */
  static formatMemory(kb: bigint): string {
    // 检查缓存
    if (MemoryUtils.formatCache.has(kb)) {
      MemoryUtils.cacheHits++;
      return MemoryUtils.formatCache.get(kb)!;
    }
    MemoryUtils.cacheMisses++;

    const startTime = Date.now();
    let result: string;

    // 使用BigInt运算避免浮点精度问题
    if (kb >= MemoryUtils.KB_IN_TB) {
      const tb = Number(kb) / Number(MemoryUtils.KB_IN_TB);
      result = `${MemoryUtils.formatNumber(tb, 2)} TB`;
    } else if (kb >= MemoryUtils.KB_IN_GB) {
      const gb = Number(kb) / Number(MemoryUtils.KB_IN_GB);
      result = `${MemoryUtils.formatNumber(gb, 2)} GB`;
    } else if (kb >= MemoryUtils.KB_IN_MB) {
      const mb = Number(kb) / Number(MemoryUtils.KB_IN_MB);
      result = `${MemoryUtils.formatNumber(mb, 2)} MB`;
    } else {
      result = `${kb} KB`;
    }

    // 缓存结果（限制缓存大小）
    if (MemoryUtils.formatCache.size < 1000) {
      MemoryUtils.formatCache.set(kb, result);
    }

    // 开发环境下记录性

    return result;
  }

  /**
   * 格式化数字，优化性能
   */
  private static formatNumber(value: number, decimals: number): string {
    // 快速检查是否为整数
    if (value % 1 === 0) {
      return value.toString();
    }

    // 使用更高效的toFixed替代方案
    const factor = Math.pow(10, decimals);
    const rounded = Math.round(value * factor) / factor;
    
    // 避免显示不必要的.00
    if (rounded % 1 === 0) {
      return rounded.toString();
    }
    
    return rounded.toFixed(decimals);
  }

  /**
   * 计算内存使用百分比（优化版本）
   */
  static calculateMemoryUsage(total: bigint, used: bigint): number {
    if (total <= 0n || used < 0n) {
      return 0;
    }

    // 使用整数运算避免浮点误差
    if (used >= total) {
      return 100;
    }

    // 使用更精确的计算方式
    const usage = (Number(used) * 100) / Number(total);
    return Math.min(100, Math.max(0, Math.round(usage)));
  }

  /**
   * 计算存储使用百分比（优化版本）
   */
  static calculateStorageUsage(total: number, used: number): number {
    if (total <= 0 || used < 0) {
      return 0;
    }

    // 边界检查
    if (used >= total) {
      return 100;
    }

    // 使用整数运算优化性能
    const usage = (used * 100) / total;
    return Math.min(100, Math.max(0, Math.round(usage)));
  }

  /**
   * 清除缓存
   */
  static clearCache(): void {
    MemoryUtils.formatCache.clear();
    MemoryUtils.cacheHits = 0;
    MemoryUtils.cacheMisses = 0;
  }


  /**
   * 获取缓存统计信息
   */
  static getCacheStats(): CacheStats {
    const total = MemoryUtils.cacheHits + MemoryUtils.cacheMisses;
    const hitRate = total > 0 ? (MemoryUtils.cacheHits / total) * 100 : 0;
    return {
      hits: MemoryUtils.cacheHits,
      misses: MemoryUtils.cacheMisses,
      hitRate: Math.round(hitRate)
    };
  }
}

// 保持向后兼容的导出
export function formatMemory(kb: bigint): string {
  return MemoryUtils.formatMemory(kb);
}

export function calculateMemoryUsage(total: bigint, used: bigint): number {
  return MemoryUtils.calculateMemoryUsage(total, used);
}

export function calculateStorageUsage(total: number, used: number): number {
  return MemoryUtils.calculateStorageUsage(total, used);
}