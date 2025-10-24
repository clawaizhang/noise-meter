/**
 * Canvas缓存管理器
 * 用于预渲染和缓存静态元素，减少实时绘制开销
 */

/**
 * 缓存项接口
 */
export interface CacheItem {
  id: string;
  canvas: ImageBitmap | null;
  context: OffscreenCanvasRenderingContext2D | null;
  width: number;
  height: number;
  lastUsed: number;
  hitCount: number;
  size: number; // 估算大小（字节）
}

/**
 * 缓存配置接口
 */
export interface CacheConfig {
  maxCacheSize: number;        // 最大缓存大小（字节）
  maxItems: number;            // 最大缓存项数量
  defaultTTL: number;          // 默认生存时间（毫秒）
  enableCompression: boolean;  // 是否启用压缩
  autoCleanup: boolean;        // 是否自动清理
}

/**
 * 默认缓存配置
 */
export const DefaultCacheConfig: CacheConfig = {
  maxCacheSize: 50 * 1024 * 1024, // 50MB
  maxItems: 20,
  defaultTTL: 5 * 60 * 1000,      // 5分钟
  enableCompression: false,
  autoCleanup: true
};

/**
 * 预渲染元素类型
 */
export enum PreRenderElementType {
  GRID = 'grid',
  AXES = 'axes',
  BACKGROUND = 'background',
  COLOR_MAP = 'color_map',
  LEGEND = 'legend'
}

/**
 * 边距配置类
 */
export class MarginConfig {
  top: number = 0;
  right: number = 0;
  bottom: number = 0;
  left: number = 0;

  constructor(top?: number, right?: number, bottom?: number, left?: number) {
    if (top !== undefined) this.top = top;
    if (right !== undefined) this.right = right;
    if (bottom !== undefined) this.bottom = bottom;
    if (left !== undefined) this.left = left;
  }
}

/**
 * 预渲染配置类
 */
export class PreRenderConfig {
  width: number = 0;
  height: number = 0;
  margin: MarginConfig = new MarginConfig();
  gridColor: string = '';
  axisColor: string = '';
  backgroundColor: string = '';
  fontSize: number = 12;

  constructor(width?: number, height?: number, margin?: MarginConfig, gridColor?: string, axisColor?: string, backgroundColor?: string, fontSize?: number) {
    if (width !== undefined) this.width = width;
    if (height !== undefined) this.height = height;
    if (margin !== undefined) this.margin = margin;
    if (gridColor !== undefined) this.gridColor = gridColor;
    if (axisColor !== undefined) this.axisColor = axisColor;
    if (backgroundColor !== undefined) this.backgroundColor = backgroundColor;
    if (fontSize !== undefined) this.fontSize = fontSize;
  }
}

/**
 * 缓存统计信息接口
 */
export interface CacheStats {
  totalItems: number;
  totalSize: number;
  hitRate: number;
  mostUsed: string[];
}

/**
 * Canvas缓存管理器
 */
export class CanvasCacheManager {
  private cache: Map<string, CacheItem> = new Map();
  private config: CacheConfig;
  private totalSize: number = 0;
  private cleanupInterval: number | null = null;

  constructor(config: CacheConfig = DefaultCacheConfig) {
    this.config = config;
    
    if (config.autoCleanup) {
      this.startAutoCleanup();
    }
  }

  /**
   * 创建缓存项
   */
  createCacheItem(
    id: string, 
    width: number, 
    height: number
  ): CacheItem | null {
    try {
      // 检查是否已存在
      if (this.cache.has(id)) {
        return this.cache.get(id)!;
      }

      // 检查缓存限制
      if (this.cache.size >= this.config.maxItems) {
        this.evictLeastUsed();
      }

      // 创建离屏Canvas
      const canvas = new OffscreenCanvas(width, height);
      const context = canvas.getContext('2d');
      
      if (!context) {
        console.warn(`[CanvasCache] 无法创建Canvas上下文: ${id}`);
        return null;
      }

      // 将OffscreenCanvas转换为ImageBitmap
      const imageBitmap = canvas.transferToImageBitmap();

      const item: CacheItem = {
        id,
        canvas: imageBitmap,
        context,
        width,
        height,
        lastUsed: Date.now(),
        hitCount: 0,
        size: width * height * 4 // 估算：宽×高×4字节（RGBA）
      };

      // 检查总大小
      if (this.totalSize + item.size > this.config.maxCacheSize) {
        this.evictBySize();
      }

      this.cache.set(id, item);
      this.totalSize += item.size;

      console.debug(`[CanvasCache] 创建缓存项: ${id}, 大小: ${item.size}字节`);
      return item;
    } catch (error) {
      console.error(`[CanvasCache] 创建缓存项失败: ${id}`, error);
      return null;
    }
  }

  /**
   * 获取缓存项
   */
  getCacheItem(id: string): CacheItem | null {
    const item = this.cache.get(id);
    
    if (item) {
      item.lastUsed = Date.now();
      item.hitCount++;
      return item;
    }
    
    return null;
  }

  /**
   * 预渲染网格
   */
  preRenderGrid(config: PreRenderConfig): CacheItem | null {
    const id = `${PreRenderElementType.GRID}_${config.width}x${config.height}`;
    
    // 检查是否已缓存
    let item = this.getCacheItem(id);
    if (item) {
      return item;
    }

    // 创建新的缓存项
    item = this.createCacheItem(id, config.width, config.height);
    if (!item || !item.context) {
      return null;
    }

    const ctx = item.context;
    const width = config.width;
    const height = config.height;
    const margin = config.margin;
    const gridColor = config.gridColor;

    // 清除画布
    ctx.clearRect(0, 0, width, height);

    // 设置绘制样式
    ctx.strokeStyle = gridColor;
    ctx.lineWidth = 0.5;
    ctx.globalAlpha = 0.3;

    const chartWidth = width - margin.left - margin.right;
    const chartHeight = height - margin.top - margin.bottom;

    // 绘制水平网格线
    for (let i = 0; i <= 5; i++) {
      const y = margin.top + (chartHeight / 5) * i;
      ctx.beginPath();
      ctx.moveTo(margin.left, y);
      ctx.lineTo(margin.left + chartWidth, y);
      ctx.stroke();
    }

    // 绘制垂直网格线
    for (let i = 0; i <= 8; i++) {
      const x = margin.left + (chartWidth / 8) * i;
      ctx.beginPath();
      ctx.moveTo(x, margin.top);
      ctx.lineTo(x, margin.top + chartHeight);
      ctx.stroke();
    }

    ctx.globalAlpha = 1.0;
    console.debug(`[CanvasCache] 预渲染网格完成: ${id}`);
    return item;
  }

  /**
   * 预渲染坐标轴
   */
  preRenderAxes(config: PreRenderConfig): CacheItem | null {
    const id = `${PreRenderElementType.AXES}_${config.width}x${config.height}`;
    
    // 检查是否已缓存
    let item = this.getCacheItem(id);
    if (item) {
      return item;
    }

    // 创建新的缓存项
    item = this.createCacheItem(id, config.width, config.height);
    if (!item || !item.context) {
      return null;
    }

    const ctx = item.context;
    const width = config.width;
    const height = config.height;
    const margin = config.margin;
    const axisColor = config.axisColor;
    const fontSize = config.fontSize;

    // 清除画布
    ctx.clearRect(0, 0, width, height);

    // 设置绘制样式
    ctx.strokeStyle = axisColor;
    ctx.lineWidth = 1;
    ctx.fillStyle = axisColor;
    ctx.font = `${fontSize}px Arial`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';

    const chartWidth = width - margin.left - margin.right;
    const chartHeight = height - margin.top - margin.bottom;

    // 绘制X轴
    ctx.beginPath();
    ctx.moveTo(margin.left, margin.top + chartHeight);
    ctx.lineTo(margin.left + chartWidth, margin.top + chartHeight);
    ctx.stroke();

    // 绘制Y轴
    ctx.beginPath();
    ctx.moveTo(margin.left, margin.top);
    ctx.lineTo(margin.left, margin.top + chartHeight);
    ctx.stroke();

    // 绘制频率刻度（对数坐标）
    const frequencies = [16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
    const logMin = Math.log10(16);
    const logMax = Math.log10(16000);
    
    for (const freq of frequencies) {
      const logFreq = Math.log10(freq);
      const x = margin.left + ((logFreq - logMin) / (logMax - logMin)) * chartWidth;
      
      // 绘制刻度线
      ctx.beginPath();
      ctx.moveTo(x, margin.top + chartHeight);
      ctx.lineTo(x, margin.top + chartHeight + 5);
      ctx.stroke();
      
      // 绘制标签
      const label = freq >= 1000 ? `${freq / 1000}k` : freq.toString();
      ctx.fillText(label, x, margin.top + chartHeight + 15);
    }

    // 绘制时间刻度
    const timeIntervals = [0, 1, 2, 3, 4, 5]; // 秒
    for (const time of timeIntervals) {
      const y = margin.top + chartHeight - (time / 5) * chartHeight;
      
      // 绘制刻度线
      ctx.beginPath();
      ctx.moveTo(margin.left - 5, y);
      ctx.lineTo(margin.left, y);
      ctx.stroke();
      
      // 绘制标签
      ctx.textAlign = 'right';
      ctx.fillText(`${time}s`, margin.left - 8, y);
      ctx.textAlign = 'center';
    }

    console.debug(`[CanvasCache] 预渲染坐标轴完成: ${id}`);
    return item;
  }

  /**
   * 预渲染背景
   */
  preRenderBackground(config: PreRenderConfig): CacheItem | null {
    const id = `${PreRenderElementType.BACKGROUND}_${config.width}x${config.height}`;
    
    // 检查是否已缓存
    let item = this.getCacheItem(id);
    if (item) {
      return item;
    }

    // 创建新的缓存项
    item = this.createCacheItem(id, config.width, config.height);
    if (!item || !item.context) {
      return null;
    }

    const ctx = item.context;
    const width = config.width;
    const height = config.height;
    const backgroundColor = config.backgroundColor;

    // 绘制背景
    ctx.fillStyle = backgroundColor;
    ctx.fillRect(0, 0, width, height);

    console.debug(`[CanvasCache] 预渲染背景完成: ${id}`);
    return item;
  }

  /**
   * 预渲染颜色映射图例
   */
  preRenderColorMapLegend(
    colorMap: string[], 
    minDb: number, 
    maxDb: number,
    width: number = 200,
    height: number = 20
  ): CacheItem | null {
    const id = `${PreRenderElementType.COLOR_MAP}_${width}x${height}`;
    
    // 检查是否已缓存
    let item = this.getCacheItem(id);
    if (item) {
      return item;
    }

    // 创建新的缓存项
    item = this.createCacheItem(id, width, height);
    if (!item || !item.context) {
      return null;
    }

    const ctx = item.context;

    // 绘制颜色渐变条
    const gradient = ctx.createLinearGradient(0, 0, width, 0);
    
    // 添加颜色停止点
    for (let i = 0; i < colorMap.length; i++) {
      const position = i / (colorMap.length - 1);
      gradient.addColorStop(position, colorMap[i]);
    }

    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);

    // 绘制边框
    ctx.strokeStyle = '#666';
    ctx.lineWidth = 1;
    ctx.strokeRect(0, 0, width, height);

    // 绘制刻度标签
    ctx.fillStyle = '#333';
    ctx.font = '10px Arial';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';

    // 最小值和最大值
    ctx.fillText(minDb.toFixed(0), 0, height + 5);
    ctx.fillText(maxDb.toFixed(0), width, height + 5);

    console.debug(`[CanvasCache] 预渲染颜色映射图例完成: ${id}`);
    return item;
  }

  /**
   * 绘制缓存内容到目标Canvas
   */
  drawCachedItem(
    targetCtx: CanvasRenderingContext2D,
    cacheId: string,
    x: number = 0,
    y: number = 0
  ): boolean {
    const item = this.getCacheItem(cacheId);
    
    if (!item || !item.canvas) {
      return false;
    }

    try {
      targetCtx.drawImage(item.canvas, x, y);
      return true;
    } catch (error) {
      console.error(`[CanvasCache] 绘制缓存项失败: ${cacheId}`, error);
      return false;
    }
  }

  /**
   * 驱逐最少使用的缓存项
   */
  private evictLeastUsed(): void {
    let leastUsed: CacheItem | null = null;
    
    for (const item of this.cache.values()) {
      if (!leastUsed || item.lastUsed < leastUsed.lastUsed) {
        leastUsed = item;
      }
    }
    
    if (leastUsed) {
      this.evictItem(leastUsed.id);
    }
  }

  /**
   * 按大小驱逐缓存项
   */
  private evictBySize(): void {
    const items = Array.from(this.cache.values())
      .sort((a, b) => b.lastUsed - a.lastUsed); // 按最近使用时间排序
    
    while (this.totalSize > this.config.maxCacheSize * 0.8 && items.length > 0) {
      const item = items.pop()!;
      this.evictItem(item.id);
    }
  }

  /**
   * 驱逐指定缓存项
   */
  evictItem(id: string): boolean {
    const item = this.cache.get(id);
    
    if (item) {
      this.totalSize -= item.size;
      this.cache.delete(id);
      console.debug(`[CanvasCache] 驱逐缓存项: ${id}`);
      return true;
    }
    
    return false;
  }

  /**
   * 清理过期缓存项
   */
  cleanupExpired(): number {
    const now = Date.now();
    let cleanedCount = 0;
    
    const entries = Array.from(this.cache.entries());
    for (let i = 0; i < entries.length; i++) {
      const id = entries[i][0];
      const item = entries[i][1];
      if (now - item.lastUsed > this.config.defaultTTL) {
        this.evictItem(id);
        cleanedCount++;
      }
    }
    
    if (cleanedCount > 0) {
      console.info(`[CanvasCache] 清理了 ${cleanedCount} 个过期缓存项`);
    }
    
    return cleanedCount;
  }

  /**
   * 启动自动清理
   */
  private startAutoCleanup(): void {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
    }
    
    this.cleanupInterval = setInterval(() => {
      this.cleanupExpired();
    }, this.config.defaultTTL) as number;
  }

  /**
   * 停止自动清理
   */
  stopAutoCleanup(): void {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
  }

  /**
   * 获取缓存统计信息
   */
  getCacheStats(): CacheStats {
    let totalHits = 0;
    const items = Array.from(this.cache.values());
    
    for (const item of items) {
      totalHits += item.hitCount;
    }
    
    const hitRate = totalHits > 0 ? totalHits / (totalHits + this.cache.size) : 0;
    
    // 获取最常用的缓存项
    const mostUsed = items
      .sort((a, b) => b.hitCount - a.hitCount)
      .slice(0, 5)
      .map(item => item.id);

    return {
      totalItems: this.cache.size,
      totalSize: this.totalSize,
      hitRate,
      mostUsed
    };
  }

  /**
   * 清空所有缓存
   */
  clearAll(): void {
    this.cache.clear();
    this.totalSize = 0;
    console.info('[CanvasCache] 清空所有缓存');
  }

  /**
   * 销毁管理器
   */
  destroy(): void {
    this.stopAutoCleanup();
    this.clearAll();
  }
}