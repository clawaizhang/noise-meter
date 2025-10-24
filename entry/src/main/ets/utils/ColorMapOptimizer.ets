/**
 * 颜色映射优化器
 * 预计算和缓存颜色映射，减少实时计算开销
 */

/**
 * 颜色映射类型
 */
export enum ColorMapType {
  HEAT = 'heat',
  RAINBOW = 'rainbow',
  GRAYSCALE = 'grayscale',
  JET = 'jet',
  VIRIDIS = 'viridis'
}

/**
 * 颜色映射配置
 */
export interface ColorMapConfig {
  type: ColorMapType;
  minValue: number;
  maxValue: number;
  opacity: number;
  resolution: number; // 颜色映射分辨率
}

/**
 * RGB颜色接口
 */
interface RGBColor {
  r: number;
  g: number;
  b: number;
}

/**
 * 颜色映射缓存项
 */
interface ColorMapCacheItem {
  config: ColorMapConfig;
  colors: string[];
  timestamp: number;
  hitCount: number;
}

/**
 * 缓存统计信息接口
 */
interface ColorMapCacheStats {
  totalItems: number;
  hitRate: number;
  mostUsedTypes: string[];
}

/**
 * 优化的颜色映射生成器
 */
export class ColorMapOptimizer {
  private cache: Map<string, ColorMapCacheItem> = new Map();
  private maxCacheSize: number = 20;
  private precomputedMaps: Map<ColorMapType, string[]> = new Map();

  constructor() {
    this.precomputeColorMaps();
  }

  /**
   * 预计算常用颜色映射
   */
  private precomputeColorMaps(): void {
    // 预计算256色的常用颜色映射
    const resolution = 256;
    
    // 热力图
    this.precomputedMaps.set(ColorMapType.HEAT, this.generateHeatMap(resolution));
    
    // 彩虹图
    this.precomputedMaps.set(ColorMapType.RAINBOW, this.generateRainbowMap(resolution));
    
    // 灰度图
    this.precomputedMaps.set(ColorMapType.GRAYSCALE, this.generateGrayscaleMap(resolution));
    
    // Jet颜色映射
    this.precomputedMaps.set(ColorMapType.JET, this.generateJetMap(resolution));
    
    // Viridis颜色映射
    this.precomputedMaps.set(ColorMapType.VIRIDIS, this.generateViridisMap(resolution));
    
    console.info('[ColorMapOptimizer] 预计算颜色映射完成');
  }

  /**
   * 获取颜色映射
   */
  getColorMap(config: ColorMapConfig): string[] {
    const cacheKey = this.generateCacheKey(config);
    
    // 检查缓存
    let cachedItem = this.cache.get(cacheKey);
    if (cachedItem) {
      cachedItem.hitCount++;
      cachedItem.timestamp = Date.now();
      return cachedItem.colors;
    }

    // 生成新的颜色映射
    const colors = this.generateColorMap(config);
    
    // 缓存结果
    if (this.cache.size >= this.maxCacheSize) {
      this.evictLeastUsed();
    }
    
    cachedItem = {
      config,
      colors,
      timestamp: Date.now(),
      hitCount: 1
    };
    
    this.cache.set(cacheKey, cachedItem);
    return colors;
  }

  /**
   * 生成缓存键
   */
  private generateCacheKey(config: ColorMapConfig): string {
    return `${config.type}_${config.minValue}_${config.maxValue}_${config.opacity}_${config.resolution}`;
  }

  /**
   * 生成颜色映射
   */
  private generateColorMap(config: ColorMapConfig): string[] {
    // 检查预计算映射
    const precomputed = this.precomputedMaps.get(config.type);
    if (precomputed && config.resolution === 256) {
      return this.applyOpacity(precomputed, config.opacity);
    }

    // 动态生成
    const colors: string[] = [];
    for (let i = 0; i < config.resolution; i++) {
      const normalized = i / (config.resolution - 1);
      const color = this.calculateColor(config.type, normalized, config.opacity);
      colors.push(color);
    }
    
    return colors;
  }

  /**
   * 应用透明度
   */
  private applyOpacity(colors: string[], opacity: number): string[] {
    if (opacity >= 1.0) {
      return colors;
    }
    
    return colors.map(color => {
      // 解析颜色值
      const rgbaMatch = color.match(/rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)/);
      if (rgbaMatch) {
        const r = rgbaMatch[1];
        const g = rgbaMatch[2];
        const b = rgbaMatch[3];
        return `rgba(${r}, ${g}, ${b}, ${opacity})`;
      }
      
      // 如果是RGB格式，转换为RGBA
      const rgbMatch = color.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
      if (rgbMatch) {
        const r = rgbMatch[1];
        const g = rgbMatch[2];
        const b = rgbMatch[3];
        return `rgba(${r}, ${g}, ${b}, ${opacity})`;
      }
      
      return color;
    });
  }

  /**
   * 计算单个颜色
   */
  private calculateColor(type: ColorMapType, normalized: number, opacity: number): string {
    let r: number, g: number, b: number;

    switch (type) {
      case ColorMapType.HEAT:
        const heatColor = this.calculateHeatColor(normalized);
        r = heatColor.r;
        g = heatColor.g;
        b = heatColor.b;
        break;
      case ColorMapType.RAINBOW:
        const rainbowColor = this.calculateRainbowColor(normalized);
        r = rainbowColor.r;
        g = rainbowColor.g;
        b = rainbowColor.b;
        break;
      case ColorMapType.GRAYSCALE:
        const grayscaleColor = this.calculateGrayscaleColor(normalized);
        r = grayscaleColor.r;
        g = grayscaleColor.g;
        b = grayscaleColor.b;
        break;
      case ColorMapType.JET:
        const jetColor = this.calculateJetColor(normalized);
        r = jetColor.r;
        g = jetColor.g;
        b = jetColor.b;
        break;
      case ColorMapType.VIRIDIS:
        const viridisColor = this.calculateViridisColor(normalized);
        r = viridisColor.r;
        g = viridisColor.g;
        b = viridisColor.b;
        break;
      default:
        const defaultColor = this.calculateHeatColor(normalized);
        r = defaultColor.r;
        g = defaultColor.g;
        b = defaultColor.b;
    }

    return `rgba(${Math.floor(r)}, ${Math.floor(g)}, ${Math.floor(b)}, ${opacity})`;
  }

  /**
   * 计算热力图颜色
   */
  private calculateHeatColor(normalized: number): RGBColor {
    let r: number, g: number, b: number;

    if (normalized < 0.25) {
      r = 0;
      g = normalized * 4 * 255;
      b = 255;
    } else if (normalized < 0.5) {
      r = 0;
      g = 255;
      b = (1 - (normalized - 0.25) * 4) * 255;
    } else if (normalized < 0.75) {
      r = (normalized - 0.5) * 4 * 255;
      g = 255;
      b = 0;
    } else {
      r = 255;
      g = (1 - (normalized - 0.75) * 4) * 255;
      b = 0;
    }

    return { r, g, b };
  }

  /**
   * 计算彩虹颜色
   */
  private calculateRainbowColor(normalized: number): RGBColor {
    const hue = (1 - normalized) * 240; // 240度色相范围
    return this.hslToRgb(hue / 360, 1, 0.5);
  }

  /**
   * 计算灰度颜色
   */
  private calculateGrayscaleColor(normalized: number): RGBColor {
    const intensity = normalized * 255;
    return { r: intensity, g: intensity, b: intensity };
  }

  /**
   * 计算Jet颜色映射
   */
  private calculateJetColor(normalized: number): RGBColor {
    let r: number, g: number, b: number;

    if (normalized < 0.125) {
      r = 0;
      g = 0;
      b = 0.5 + 4 * normalized;
    } else if (normalized < 0.375) {
      r = 0;
      g = 4 * (normalized - 0.125);
      b = 1;
    } else if (normalized < 0.625) {
      r = 4 * (normalized - 0.375);
      g = 1;
      b = 1 - 4 * (normalized - 0.375);
    } else if (normalized < 0.875) {
      r = 1;
      g = 1 - 4 * (normalized - 0.625);
      b = 0;
    } else {
      r = 1 - 4 * (normalized - 0.875);
      g = 0;
      b = 0;
    }

    return { r: r * 255, g: g * 255, b: b * 255 };
  }

  /**
   * 计算Viridis颜色映射
   */
  private calculateViridisColor(normalized: number): RGBColor {
    // Viridis颜色映射的简化实现
    // 实际Viridis映射更复杂，这里使用近似值
    const r = Math.max(0, Math.min(255, 
      68.0 + normalized * (253.0 - 68.0)
    ));
    const g = Math.max(0, Math.min(255, 
      1.0 + normalized * (231.0 - 1.0)
    ));
    const b = Math.max(0, Math.min(255, 
      84.0 + normalized * (159.0 - 84.0)
    ));
    
    return { r, g, b };
  }

  /**
   * HSL转RGB
   */
  private hslToRgb(h: number, s: number, l: number): RGBColor {
    let r: number, g: number, b: number;

    if (s === 0) {
      r = g = b = l; // 灰度
    } else {
      const hue2rgb = (p: number, q: number, t: number) => {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
        return p;
      };

      const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      const p = 2 * l - q;
      r = hue2rgb(p, q, h + 1 / 3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1 / 3);
    }

    return { r: r * 255, g: g * 255, b: b * 255 };
  }

  /**
   * 生成热力图预计算映射
   */
  private generateHeatMap(resolution: number): string[] {
    const colors: string[] = [];
    for (let i = 0; i < resolution; i++) {
      const normalized = i / (resolution - 1);
      const color = this.calculateHeatColor(normalized);
      const r = color.r;
      const g = color.g;
      const b = color.b;
      colors.push(`rgb(${Math.floor(r)}, ${Math.floor(g)}, ${Math.floor(b)})`);
    }
    return colors;
  }

  /**
   * 生成彩虹图预计算映射
   */
  private generateRainbowMap(resolution: number): string[] {
    const colors: string[] = [];
    for (let i = 0; i < resolution; i++) {
      const normalized = i / (resolution - 1);
      const color = this.calculateRainbowColor(normalized);
      const r = color.r;
      const g = color.g;
      const b = color.b;
      colors.push(`rgb(${Math.floor(r)}, ${Math.floor(g)}, ${Math.floor(b)})`);
    }
    return colors;
  }

  /**
   * 生成灰度图预计算映射
   */
  private generateGrayscaleMap(resolution: number): string[] {
    const colors: string[] = [];
    for (let i = 0; i < resolution; i++) {
      const normalized = i / (resolution - 1);
      const color = this.calculateGrayscaleColor(normalized);
      const r = color.r;
      const g = color.g;
      const b = color.b;
      colors.push(`rgb(${Math.floor(r)}, ${Math.floor(g)}, ${Math.floor(b)})`);
    }
    return colors;
  }

  /**
   * 生成Jet颜色映射预计算映射
   */
  private generateJetMap(resolution: number): string[] {
    const colors: string[] = [];
    for (let i = 0; i < resolution; i++) {
      const normalized = i / (resolution - 1);
      const color = this.calculateJetColor(normalized);
      const r = color.r;
      const g = color.g;
      const b = color.b;
      colors.push(`rgb(${Math.floor(r)}, ${Math.floor(g)}, ${Math.floor(b)})`);
    }
    return colors;
  }

  /**
   * 生成Viridis颜色映射预计算映射
   */
  private generateViridisMap(resolution: number): string[] {
    const colors: string[] = [];
    for (let i = 0; i < resolution; i++) {
      const normalized = i / (resolution - 1);
      const color = this.calculateViridisColor(normalized);
      const r = color.r;
      const g = color.g;
      const b = color.b;
      colors.push(`rgb(${Math.floor(r)}, ${Math.floor(g)}, ${Math.floor(b)})`);
    }
    return colors;
  }

  /**
   * 驱逐最少使用的缓存项
   */
  private evictLeastUsed(): void {
    let leastUsed: ColorMapCacheItem | null = null;
    let leastUsedKey: string | null = null;
    
    const entries = Array.from(this.cache.entries());
    for (let i = 0; i < entries.length; i++) {
      const key = entries[i][0];
      const item = entries[i][1];
      if (!leastUsed || item.hitCount < leastUsed.hitCount) {
        leastUsed = item;
        leastUsedKey = key;
      }
    }
    
    if (leastUsedKey) {
      this.cache.delete(leastUsedKey);
      console.debug(`[ColorMapOptimizer] 驱逐缓存项: ${leastUsedKey}`);
    }
  }

  /**
   * 获取颜色值（用于单个数据点）
   */
  getColorForValue(
    value: number,
    config: ColorMapConfig
  ): string {
    // 归一化值
    const normalized = Math.max(0, Math.min(1, 
      (value - config.minValue) / (config.maxValue - config.minValue)
    ));
    
    // 获取颜色映射
    const colorMap = this.getColorMap(config);
    
    // 计算颜色索引
    const index = Math.floor(normalized * (colorMap.length - 1));
    return colorMap[Math.max(0, Math.min(colorMap.length - 1, index))];
  }

  /**
   * 批量获取颜色值
   */
  getColorsForValues(
    values: number[],
    config: ColorMapConfig
  ): string[] {
    const colorMap = this.getColorMap(config);
    const colors: string[] = [];
    
    for (const value of values) {
      const normalized = Math.max(0, Math.min(1, 
        (value - config.minValue) / (config.maxValue - config.minValue)
      ));
      const index = Math.floor(normalized * (colorMap.length - 1));
      colors.push(colorMap[Math.max(0, Math.min(colorMap.length - 1, index))]);
    }
    
    return colors;
  }

  /**
   * 获取缓存统计信息
   */
  getCacheStats(): ColorMapCacheStats {
    let totalHits = 0;
    const typeCounts = new Map<ColorMapType, number>();
    
    for (const item of this.cache.values()) {
      totalHits += item.hitCount;
      typeCounts.set(
        item.config.type,
        (typeCounts.get(item.config.type) || 0) + item.hitCount
      );
    }
    
    const hitRate = totalHits > 0 ? totalHits / (totalHits + this.cache.size) : 0;
    
    // 获取最常用的类型
    const mostUsedTypes = Array.from(typeCounts.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)
      .map((entry) => entry[0]);

    return {
      totalItems: this.cache.size,
      hitRate,
      mostUsedTypes
    };
  }

  /**
   * 清空缓存
   */
  clearCache(): void {
    this.cache.clear();
    console.info('[ColorMapOptimizer] 清空颜色映射缓存');
  }

  /**
   * 预计算所有颜色映射
   */
  precomputeAllMaps(resolution: number = 256): void {
    const types = Object.values(ColorMapType);
    
    for (let i = 0; i < types.length; i++) {
      const type = types[i];
      const config: ColorMapConfig = {
        type,
        minValue: 0,
        maxValue: 1,
        opacity: 1.0,
        resolution
      };
      
      // 预计算并缓存
      this.getColorMap(config);
    }
    
    console.info(`[ColorMapOptimizer] 预计算所有颜色映射完成，分辨率: ${resolution}`);
  }
}