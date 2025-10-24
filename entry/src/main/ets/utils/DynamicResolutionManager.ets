/**
 * 动态分辨率管理器
 * 根据性能需求智能调整数据分辨率和采样率
 */

/**
 * 性能等级枚举
 */
export enum PerformanceLevel {
  LOW = 'low',        // 低性能设备
  MEDIUM = 'medium',  // 中等性能设备
  HIGH = 'high',      // 高性能设备
  ULTRA = 'ultra'     // 超高性能设备
}
/**
 * 窗口数据接口
 */
interface WindowData {
  spectra: Float32Array[];
  timestamps: number[];
}

/**
 * 分辨率配置接口
 */
export interface ResolutionConfig {
  fftSize: number;           // FFT大小
  frameRate: number;         // 帧率
  compressionRatio: number;  // 压缩比例
  logCompression: boolean;   // 是否启用对数压缩
  maxHistorySize: number;    // 最大历史大小
}
/**
 * 窗口统计信息接口
 */
interface WindowStats {
  size: number;
  currentIndex: number;
  memoryUsage: number;
}

/**
 * 性能监控数据接口
 */
export interface PerformanceMetrics {
  frameTime: number;         // 帧渲染时间(ms)
  memoryUsage: number;       // 内存使用量(MB)
  fps: number;               // 当前帧率
  cpuUsage: number;          // CPU使用率(估算)
  droppedFrames: number;     // 丢帧数
}

/**
 * 动态分辨率配置
 */
export interface DynamicResolutionConfig {
  targetFPS: number;                    // 目标帧率
  maxMemoryMB: number;                  // 最大内存使用量(MB)
  performanceLevel: PerformanceLevel;   // 性能等级
  enableAutoAdjust: boolean;            // 是否启用自动调整
  adjustmentInterval: number;           // 调整间隔(ms)
}

/**
 * 性能统计信息接口
 */
export interface PerformanceStats {
  currentLevel: PerformanceLevel;
  performanceScore: number;
  adjustmentCount: number;
  metrics: PerformanceMetrics;
}

/**
 * 默认动态分辨率配置
 */
export const DefaultDynamicResolutionConfig: DynamicResolutionConfig = {
  targetFPS: 30,
  maxMemoryMB: 50,
  performanceLevel: PerformanceLevel.MEDIUM,
  enableAutoAdjust: true,
  adjustmentInterval: 5000
};

/**
 * 分辨率预设配置
 */
const ResolutionPresets: Record<PerformanceLevel, ResolutionConfig> = {
  [PerformanceLevel.LOW]: {
    fftSize: 512,
    frameRate: 15,
    compressionRatio: 4,
    logCompression: true,
    maxHistorySize: 50
  },
  [PerformanceLevel.MEDIUM]: {
    fftSize: 1024,
    frameRate: 25,
    compressionRatio: 2,
    logCompression: true,
    maxHistorySize: 80
  },
  [PerformanceLevel.HIGH]: {
    fftSize: 2048,
    frameRate: 30,
    compressionRatio: 1,
    logCompression: false,
    maxHistorySize: 100
  },
  [PerformanceLevel.ULTRA]: {
    fftSize: 4096,
    frameRate: 60,
    compressionRatio: 1,
    logCompression: false,
    maxHistorySize: 150
  }
};

/**
 * 动态分辨率管理器
 */
export class DynamicResolutionManager {
  private config: DynamicResolutionConfig;
  private currentConfig: ResolutionConfig;
  private performanceMetrics: PerformanceMetrics;
  private lastAdjustmentTime: number = 0;
  private frameTimes: number[] = [];
  private memorySamples: number[] = [];
  private adjustmentCount: number = 0;

  constructor(config: DynamicResolutionConfig = DefaultDynamicResolutionConfig) {
    this.config = config;
    this.currentConfig = this.getPresetConfig(config.performanceLevel);
    this.performanceMetrics = this.initializeMetrics();
  }

  /**
   * 初始化性能指标
   */
  private initializeMetrics(): PerformanceMetrics {
    return {
      frameTime: 0,
      memoryUsage: 0,
      fps: this.config.targetFPS,
      cpuUsage: 0,
      droppedFrames: 0
    };
  }

  /**
   * 获取预设配置
   */
  private getPresetConfig(level: PerformanceLevel): ResolutionConfig {
    const preset = ResolutionPresets[level];
    return {
      fftSize: preset.fftSize,
      frameRate: preset.frameRate,
      compressionRatio: preset.compressionRatio,
      logCompression: preset.logCompression,
      maxHistorySize: preset.maxHistorySize
    };
  }

  /**
   * 更新性能指标
   */
  updateMetrics(metrics: Partial<PerformanceMetrics>): void {
    this.performanceMetrics = {
      frameTime: metrics.frameTime ?? this.performanceMetrics.frameTime,
      memoryUsage: metrics.memoryUsage ?? this.performanceMetrics.memoryUsage,
      fps: metrics.fps ?? this.performanceMetrics.fps,
      cpuUsage: metrics.cpuUsage ?? this.performanceMetrics.cpuUsage,
      droppedFrames: metrics.droppedFrames ?? this.performanceMetrics.droppedFrames
    };

    // 记录帧时间用于计算平均帧率
    if (metrics.frameTime) {
      this.frameTimes.push(metrics.frameTime);
      if (this.frameTimes.length > 60) {
        this.frameTimes.shift();
      }
    }

    // 记录内存使用量
    if (metrics.memoryUsage) {
      this.memorySamples.push(metrics.memoryUsage);
      if (this.memorySamples.length > 30) {
        this.memorySamples.shift();
      }
    }

    // 自动调整分辨率
    if (this.config.enableAutoAdjust) {
      this.autoAdjustResolution();
    }
  }

  /**
   * 自动调整分辨率
   */
  private autoAdjustResolution(): void {
    const currentTime = Date.now();
    if (currentTime - this.lastAdjustmentTime < this.config.adjustmentInterval) {
      return;
    }

    this.lastAdjustmentTime = currentTime;
    this.adjustmentCount++;

    // 计算平均性能指标
    const avgFrameTime = this.frameTimes.length > 0 ? 
      this.frameTimes.reduce((a, b) => a + b, 0) / this.frameTimes.length : 0;
    
    const avgMemoryUsage = this.memorySamples.length > 0 ?
      this.memorySamples.reduce((a, b) => a + b, 0) / this.memorySamples.length : 0;

    const currentFPS = avgFrameTime > 0 ? 1000 / avgFrameTime : this.config.targetFPS;

    // 性能评估
    const performanceScore = this.calculatePerformanceScore(currentFPS, avgMemoryUsage);
    const newLevel = this.determinePerformanceLevel(performanceScore);

    // 如果性能等级发生变化，更新配置
    if (newLevel !== this.config.performanceLevel) {
      console.info(`[动态分辨率] 性能等级调整: ${this.config.performanceLevel} -> ${newLevel}`);
      this.config.performanceLevel = newLevel;
      this.currentConfig = this.getPresetConfig(newLevel);
    }

    // 微调配置
    this.fineTuneConfig(currentFPS, avgMemoryUsage);
  }

  /**
   * 计算性能分数
   */
  private calculatePerformanceScore(fps: number, memoryUsage: number): number {
    const fpsScore = Math.min(1, fps / this.config.targetFPS);
    const memoryScore = Math.max(0, 1 - (memoryUsage / this.config.maxMemoryMB));
    
    return (fpsScore * 0.7 + memoryScore * 0.3) * 100;
  }

  /**
   * 确定性能等级
   */
  private determinePerformanceLevel(score: number): PerformanceLevel {
    if (score >= 90) return PerformanceLevel.ULTRA;
    if (score >= 75) return PerformanceLevel.HIGH;
    if (score >= 50) return PerformanceLevel.MEDIUM;
    return PerformanceLevel.LOW;
  }

  /**
   * 微调配置
   */
  private fineTuneConfig(fps: number, memoryUsage: number): void {
    const fpsRatio = fps / this.config.targetFPS;
    const memoryRatio = memoryUsage / this.config.maxMemoryMB;

    // 帧率调整
    if (fpsRatio < 0.8) {
      // 帧率过低，降低分辨率
      this.currentConfig.compressionRatio = Math.min(
        this.currentConfig.compressionRatio + 1,
        8
      );
      console.debug(`[动态分辨率] 增加压缩比例: ${this.currentConfig.compressionRatio}`);
    } else if (fpsRatio > 1.2 && this.currentConfig.compressionRatio > 1) {
      // 帧率过高，提高分辨率
      this.currentConfig.compressionRatio = Math.max(
        this.currentConfig.compressionRatio - 1,
        1
      );
      console.debug(`[动态分辨率] 降低压缩比例: ${this.currentConfig.compressionRatio}`);
    }

    // 内存调整
    if (memoryRatio > 0.9) {
      // 内存使用过高，减少历史大小
      this.currentConfig.maxHistorySize = Math.max(
        Math.floor(this.currentConfig.maxHistorySize * 0.8),
        20
      );
      console.debug(`[动态分辨率] 减少历史大小: ${this.currentConfig.maxHistorySize}`);
    } else if (memoryRatio < 0.6 && fpsRatio > 1.1) {
      // 内存充足且帧率良好，增加历史大小
      this.currentConfig.maxHistorySize = Math.min(
        Math.floor(this.currentConfig.maxHistorySize * 1.2),
        200
      );
      console.debug(`[动态分辨率] 增加历史大小: ${this.currentConfig.maxHistorySize}`);
    }
  }

  /**
   * 获取当前分辨率配置
   */
  getCurrentConfig(): ResolutionConfig {
    return {
      fftSize: this.currentConfig.fftSize,
      frameRate: this.currentConfig.frameRate,
      compressionRatio: this.currentConfig.compressionRatio,
      logCompression: this.currentConfig.logCompression,
      maxHistorySize: this.currentConfig.maxHistorySize
    };
  }

  /**
   * 设置性能等级
   */
  setPerformanceLevel(level: PerformanceLevel): void {
    this.config.performanceLevel = level;
    this.currentConfig = this.getPresetConfig(level);
    console.info(`[动态分辨率] 手动设置性能等级: ${level}`);
  }

  /**
   * 应用对数频率压缩
   */
  applyLogCompression(spectrum: Float32Array): Float32Array {
    if (!this.currentConfig.logCompression || spectrum.length <= 256) {
      return spectrum;
    }

    const compressedSize = 256; // 固定压缩到256个点
    const compressed = new Float32Array(compressedSize);
    
    // 对数频率映射
    const logMin = Math.log10(16);
    const logMax = Math.log10(16000);
    const logRange = logMax - logMin;

    for (let i = 0; i < compressedSize; i++) {
      // 计算对数频率位置
      const logPos = logMin + (i / (compressedSize - 1)) * logRange;
      const freq = Math.pow(10, logPos);
      
      // 找到对应的原始频谱位置
      const originalIndex = Math.floor((freq / 16000) * spectrum.length);
      const clampedIndex = Math.min(Math.max(originalIndex, 0), spectrum.length - 1);
      
      // 使用最近邻采样
      compressed[i] = spectrum[clampedIndex];
    }

    return compressed;
  }

  /**
   * 动态调整FFT大小
   */
  getAdaptiveFFTSize(): number {
    return this.currentConfig.fftSize;
  }

  /**
   * 获取动态帧率
   */
  getAdaptiveFrameRate(): number {
    return this.currentConfig.frameRate;
  }

  /**
   * 获取压缩比例
   */
  getCompressionRatio(): number {
    return this.currentConfig.compressionRatio;
  }

  /**
   * 获取最大历史大小
   */
  getMaxHistorySize(): number {
    return this.currentConfig.maxHistorySize;
  }

  /**
   * 获取性能统计信息
   */
  getPerformanceStats(): PerformanceStats {
    const avgFrameTime = this.frameTimes.length > 0 ? 
      this.frameTimes.reduce((a, b) => a + b, 0) / this.frameTimes.length : 0;
    
    const performanceScore = this.calculatePerformanceScore(
      avgFrameTime > 0 ? 1000 / avgFrameTime : this.config.targetFPS,
      this.performanceMetrics.memoryUsage
    );

    return {
      currentLevel: this.config.performanceLevel,
      performanceScore,
      adjustmentCount: this.adjustmentCount,
      metrics: this.performanceMetrics
    };
  }

  /**
   * 重置管理器
   */
  reset(): void {
    this.currentConfig = this.getPresetConfig(this.config.performanceLevel);
    this.performanceMetrics = this.initializeMetrics();
    this.frameTimes = [];
    this.memorySamples = [];
    this.adjustmentCount = 0;
    console.info('[动态分辨率] 重置管理器');
  }

  /**
   * 更新配置
   */
  updateConfig(newConfig: Partial<DynamicResolutionConfig>): void {
    this.config = {
      targetFPS: newConfig.targetFPS ?? this.config.targetFPS,
      maxMemoryMB: newConfig.maxMemoryMB ?? this.config.maxMemoryMB,
      performanceLevel: newConfig.performanceLevel ?? this.config.performanceLevel,
      enableAutoAdjust: newConfig.enableAutoAdjust ?? this.config.enableAutoAdjust,
      adjustmentInterval: newConfig.adjustmentInterval ?? this.config.adjustmentInterval
    };
    
    // 如果性能等级发生变化，更新当前配置
    if (newConfig.performanceLevel) {
      this.currentConfig = this.getPresetConfig(newConfig.performanceLevel);
    }
  }
}

/**
 * 滑动窗口数据管理器
 */
export class SlidingWindowManager {
  private windowSize: number;
  private data: Float32Array[] = [];
  private timestamps: number[] = [];
  private currentIndex: number = 0;

  constructor(windowSize: number = 100) {
    this.windowSize = windowSize;
  }

  /**
   * 添加数据到滑动窗口
   */
  addData(spectrum: Float32Array, timestamp: number = Date.now()): void {
    // 如果窗口已满，移除最旧的数据
    if (this.data.length >= this.windowSize) {
      this.data.shift();
      this.timestamps.shift();
    }

    // 添加新数据
    this.data.push(spectrum);
    this.timestamps.push(timestamp);
    this.currentIndex++;
  }


  /**
   * 获取窗口数据
   */
  getWindowData(): WindowData {
    return {
      spectra: [...this.data],
      timestamps: [...this.timestamps]
    };
  }

  /**
   * 获取最近N个数据点
   */
  getRecentData(count: number): WindowData {
    const startIndex = Math.max(0, this.data.length - count);
    return {
      spectra: this.data.slice(startIndex),
      timestamps: this.timestamps.slice(startIndex)
    };
  }

  /**
   * 清空窗口
   */
  clear(): void {
    this.data = [];
    this.timestamps = [];
    this.currentIndex = 0;
  }


  /**
   * 获取窗口统计信息
   */
  getStats(): WindowStats {
    let memoryUsage = 0;
    for (const spectrum of this.data) {
      memoryUsage += spectrum.length * 4; // Float32Array每个元素4字节
    }

    return {
      size: this.data.length,
      currentIndex: this.currentIndex,
      memoryUsage: memoryUsage / (1024 * 1024) // 转换为MB
    };
  }

  /**
   * 设置窗口大小
   */
  setWindowSize(size: number): void {
    this.windowSize = size;
    
    // 如果当前数据超过新的大小，截断数据
    if (this.data.length > size) {
      this.data = this.data.slice(-size);
      this.timestamps = this.timestamps.slice(-size);
    }
  }
}