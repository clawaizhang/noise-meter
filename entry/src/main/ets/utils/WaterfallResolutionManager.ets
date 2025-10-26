/**
 * 瀑布图动态分辨率管理器
 * 根据Canvas尺寸自动计算像素大小和绘制参数
 */

/**
 * 分辨率配置接口
 */
export interface ResolutionConfig {
  minPixelSize: number;        // 最小像素大小
  maxPixelSize: number;        // 最大像素大小
  targetRows: number;          // 目标显示行数
  enableGap: boolean;          // 是否启用行间间隙
  gapRatio: number;            // 间隙比例
  performanceMode: 'quality' | 'performance' | 'balanced';
}

/**
 * 分辨率计算结果接口
 */
export interface ResolutionResult {
  pixelSize: number;           // 计算后的像素大小
  rowSpacing: number;          // 行间距
  maxDisplayRows: number;      // 最大显示行数
  actualRows: number;          // 实际显示行数
  gapSize: number;             // 间隙大小
}

/**
 * Canvas尺寸类
 */
export class CanvasSize {
  width: number;
  height: number;

  constructor(width: number, height: number) {
    this.width = width;
    this.height = height;
  }
}

/**
 * 缓存统计类
 */
export class CacheStats {
  isCached: boolean;
  lastCanvasSize: CanvasSize | null;

  constructor(isCached: boolean, lastCanvasSize: CanvasSize | null) {
    this.isCached = isCached;
    this.lastCanvasSize = lastCanvasSize;
  }
}

/**
 * 默认分辨率配置
 * 只限制目标行数，让像素大小自适应Canvas高度
 */
export const DefaultResolutionConfig: ResolutionConfig = {
  minPixelSize: 1,      // 保留最小像素大小作为保护
  maxPixelSize: 20,     // 大幅提高最大像素大小，让像素大小自适应
  targetRows: 120,      // 固定目标行数，像素大小将基于Canvas高度计算
  enableGap: false,     // 默认不启用间隙
  gapRatio: 0.1,        // 10%间隙比例
  performanceMode: 'balanced'
};

/**
 * 性能模式配置预设
 * 只限制目标行数，让像素大小自适应Canvas高度
 */
export const PerformanceConfigs: Record<'quality' | 'performance' | 'balanced', Partial<ResolutionConfig>> = {
  "quality": {
    minPixelSize: 1,
    maxPixelSize: 20,
    targetRows: 100,    // 高质量模式：较少行数，较大像素
    enableGap: false,
    gapRatio: 0.1
  },
  "performance": {
    minPixelSize: 1,
    maxPixelSize: 20,
    targetRows: 180,    // 性能模式：较多行数，较小像素
    enableGap: false,
    gapRatio: 0
  },
  "balanced": {
    minPixelSize: 1,
    maxPixelSize: 20,
    targetRows: 120,    // 平衡模式：中等行数
    enableGap: false,
    gapRatio: 0.1
  }
};

/**
 * 瀑布图动态分辨率管理器
 */
export class WaterfallResolutionManager {
  private config: ResolutionConfig;
  private lastResult: ResolutionResult | null = null;
  private lastCanvasSize: CanvasSize | null = null;

  constructor(config?: Partial<ResolutionConfig>) {
    // 手动合并配置，避免使用受限的Object.assign
    this.config = this.mergeConfig(DefaultResolutionConfig, config);
  }

  /**
   * 计算分辨率参数
   */
  calculateResolution(canvasWidth: number, canvasHeight: number): ResolutionResult {
    // 检查缓存，避免重复计算
    if (this.lastResult && 
        this.lastCanvasSize && 
        this.lastCanvasSize.width === canvasWidth && 
        this.lastCanvasSize.height === canvasHeight) {
      console.debug(`[分辨率管理器] 使用缓存结果`);
      return this.lastResult;
    }

    console.info(`[分辨率管理器] 计算分辨率，Canvas尺寸: ${canvasWidth}x${canvasHeight}`);

    const pixelSize = this.calculatePixelSize(canvasHeight);
    const rowSpacing = this.calculateRowSpacing(pixelSize);
    const maxDisplayRows = this.calculateDisplayRows(canvasHeight, rowSpacing);
    const gapSize = this.config.enableGap ? pixelSize * this.config.gapRatio : 0;
    
    const result: ResolutionResult = {
      pixelSize,
      rowSpacing,
      maxDisplayRows,
      actualRows: maxDisplayRows,
      gapSize
    };

    // 更新缓存
    this.lastResult = result;
    this.lastCanvasSize = new CanvasSize(canvasWidth, canvasHeight);

    console.info(`[分辨率管理器] 计算结果: pixelSize=${result.pixelSize}, rowSpacing=${result.rowSpacing}, maxDisplayRows=${result.maxDisplayRows}, gapSize=${result.gapSize}`);

    return result;
  }

  /**
   * 计算像素大小
   * 基于Canvas高度和目标行数计算，确保像素大小能填满Canvas高度
   */
  private calculatePixelSize(canvasHeight: number): number {
    // 确保至少显示1行数据
    const effectiveTargetRows = Math.max(1, this.config.targetRows);
    const baseSize = canvasHeight / effectiveTargetRows;
    
    // 应用最小和最大保护，确保像素大小在合理范围内
    const protectedSize = Math.max(this.config.minPixelSize, Math.min(this.config.maxPixelSize, baseSize));
    const roundedSize = Math.max(1, Math.round(protectedSize));
    
    console.debug(`[分辨率管理器] 像素大小计算: canvasHeight=${canvasHeight}, targetRows=${effectiveTargetRows}, base=${baseSize.toFixed(2)}, protected=${protectedSize.toFixed(2)}, rounded=${roundedSize}`);
    
    return roundedSize;
  }

  /**
   * 计算行间距
   */
  private calculateRowSpacing(pixelSize: number): number {
    let spacing = pixelSize;
    
    if (this.config.enableGap) {
      spacing = pixelSize + (pixelSize * this.config.gapRatio);
    }
    
    const roundedSpacing = Math.round(spacing);
    
    console.debug(`[分辨率管理器] 行间距计算: pixelSize=${pixelSize}, gap=${this.config.enableGap}, spacing=${spacing.toFixed(2)}, rounded=${roundedSpacing}`);
    
    return roundedSpacing;
  }

  /**
   * 计算显示行数
   * 确保能充分利用Canvas高度，不限制最大行数
   */
  private calculateDisplayRows(canvasHeight: number, rowSpacing: number): number {
    const rows = Math.floor(canvasHeight / rowSpacing);
    // 确保至少显示1行，不限制最大行数，让数据充分利用Canvas高度
    const clampedRows = Math.max(1, rows);
    
    console.debug(`[分辨率管理器] 显示行数计算: canvasHeight=${canvasHeight}, rowSpacing=${rowSpacing}, raw=${rows}, clamped=${clampedRows}`);
    
    return clampedRows;
  }

  /**
   * 更新配置
   */
  updateConfig(newConfig: Partial<ResolutionConfig>): void {
    this.config = this.mergeConfig(this.config, newConfig);
    
    // 清除缓存
    this.lastResult = null;
    this.lastCanvasSize = null;
    
    console.info(`[分辨率管理器] 配置已更新: minPixelSize=${this.config.minPixelSize}, maxPixelSize=${this.config.maxPixelSize}, targetRows=${this.config.targetRows}`);
  }

  /**
   * 设置性能模式
   */
  setPerformanceMode(mode: 'quality' | 'performance' | 'balanced'): void {
    const modeConfig = PerformanceConfigs[mode];
    this.updateConfig(modeConfig);
    console.info(`[分辨率管理器] 性能模式设置为: ${mode}`);
  }

  /**
   * 获取当前配置
   */
  getCurrentConfig(): ResolutionConfig {
    return this.mergeConfig({} as ResolutionConfig, this.config);
  }

  /**
   * 获取缓存状态
   */
  getCacheStats(): CacheStats {
    return new CacheStats(this.lastResult !== null, this.lastCanvasSize);
  }

  /**
   * 清除缓存
   */
  clearCache(): void {
    this.lastResult = null;
    this.lastCanvasSize = null;
    console.debug(`[分辨率管理器] 缓存已清除`);
  }

  /**
   * 手动合并配置对象，避免使用受限的Object.assign
   */
  private mergeConfig(target: ResolutionConfig, source?: Partial<ResolutionConfig>): ResolutionConfig {
    if (!source) {
      return target;
    }

    const result: ResolutionConfig = {
      minPixelSize: source.minPixelSize !== undefined ? source.minPixelSize : target.minPixelSize,
      maxPixelSize: source.maxPixelSize !== undefined ? source.maxPixelSize : target.maxPixelSize,
      targetRows: source.targetRows !== undefined ? source.targetRows : target.targetRows,
      enableGap: source.enableGap !== undefined ? source.enableGap : target.enableGap,
      gapRatio: source.gapRatio !== undefined ? source.gapRatio : target.gapRatio,
      performanceMode: source.performanceMode !== undefined ? source.performanceMode : target.performanceMode
    };

    return result;
  }

  /**
   * 验证分辨率参数是否有效
   */
  validateResolution(canvasWidth: number, canvasHeight: number): boolean {
    if (canvasWidth <= 0 || canvasHeight <= 0) {
      console.warn(`[分辨率管理器] 无效的Canvas尺寸: ${canvasWidth}x${canvasHeight}`);
      return false;
    }

    const resolution = this.calculateResolution(canvasWidth, canvasHeight);
    
    // 只检查最小像素大小，不限制最大像素大小
    if (resolution.pixelSize < this.config.minPixelSize) {
      console.warn(`[分辨率管理器] 像素大小过小: ${resolution.pixelSize}`);
      return false;
    }

    if (resolution.maxDisplayRows < 10) {
      console.warn(`[分辨率管理器] 显示行数过少: ${resolution.maxDisplayRows}`);
      return false;
    }

    return true;
  }
}

/**
 * 创建默认分辨率管理器实例
 */
export function createDefaultResolutionManager(): WaterfallResolutionManager {
  return new WaterfallResolutionManager();
}

/**
 * 创建性能模式分辨率管理器
 */
export function createPerformanceResolutionManager(mode: 'quality' | 'performance' | 'balanced'): WaterfallResolutionManager {
  const manager = new WaterfallResolutionManager(PerformanceConfigs[mode]);
  return manager;
}