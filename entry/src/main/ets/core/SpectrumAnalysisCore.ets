/**
 * 频谱分析核心模块
 * 提供高精度、可扩展的频谱分析和峰值检测功能
 * 
 * 架构设计原则：
 * 1. 单一职责：每个类只负责一个功能
 * 2. 策略模式：峰值检测算法可插拔
 * 3. 不可变数据：频谱数据流转过程中不被修改
 * 4. 精度优先：使用插值算法提高频率精度到FFT bin以下
 */

import { WindowType } from '../common/WindowType';
import { WeightingType } from '../constants/WeightingConstants';

/**
 * 频谱数据点 - 不可变结构
 */
export interface SpectrumDataPoint {
  readonly frequency: number;  // 频率 (Hz)
  readonly amplitude: number; // 线性幅度
  readonly dbValue: number;   // 分贝值 (dB)
  readonly index: number;     // FFT bin索引
}

/**
 * 峰值信息 - 不可变结构
 */
export interface PeakInfo {
  readonly frequency: number;  // 峰值频率 (Hz)
  readonly dbValue: number;    // 峰值分贝值 (dB)
  readonly amplitude: number;  // 峰值线性幅度
  readonly index: number;      // 峰值FFT bin索引
  readonly confidence: number; // 置信度 (0-1)
}

/**
 * 频谱分析配置
 */
export interface SpectrumAnalysisConfig {
  sampleRate: number;
  fftSize: number;
  windowType: WindowType;
  weightingType: WeightingType;
  enableInterpolation: boolean;  // 是否启用插值
  interpolationMethod: InterpolationMethod;
  minPeakDistanceHz: number;     // 最小峰值间隔 (Hz)
  minPeakHeightDb: number;       // 最小峰值高度 (dB)
  smoothingFactor: number;       // 平滑因子 (0-1)
}

/**
 * 插值方法枚举
 */
export enum InterpolationMethod {
  NONE = 'none',           // 无插值
  PARABOLIC = 'parabolic', // 抛物线插值 (推荐)
  GAUSSIAN = 'gaussian',   // 高斯插值
  CENTROID = 'centroid'    // 重心法
}

/**
 * 频谱分析结果
 */
export interface SpectrumAnalysisResult {
  readonly dataPoints: SpectrumDataPoint[];
  readonly peakInfo: PeakInfo | null;
  readonly peakInfos: PeakInfo[];
  readonly frequencyResolution: number;
  readonly timestamp: number;
}

/**
 * 峰值检测策略接口
 */
export interface PeakDetectionStrategy {
  /**
   * 检测单个峰值
   * @param spectrumData 频谱数据
   * @param startIndex 起始索引
   * @param endIndex 结束索引
   * @param config 分析配置
   * @returns 峰值信息或null
   */
  detectSinglePeak(
    spectrumData: Float32Array,
    startIndex: number,
    endIndex: number,
    config: SpectrumAnalysisConfig
  ): PeakInfo | null;

  /**
   * 检测多个峰值
   * @param spectrumData 频谱数据
   * @param peakCount 峰值数量
   * @param config 分析配置
   * @returns 峰值信息数组
   */
  detectMultiplePeaks(
    spectrumData: Float32Array,
    peakCount: number,
    config: SpectrumAnalysisConfig
  ): PeakInfo[];
}

/**
 * 抛物线插值峰值检测策略
 * 
 * 重要说明：spectrumData 已经是 dB 值（由 FFTAnalyzer 输出）
 * 所有操作都在 dB 域进行，不需要再次对数转换
 */
export class ParabolicPeakDetectionStrategy implements PeakDetectionStrategy {
  detectSinglePeak(
    spectrumData: Float32Array,
    startIndex: number,
    endIndex: number,
    config: SpectrumAnalysisConfig
  ): PeakInfo | null {
    if (startIndex < 0 || endIndex >= spectrumData.length || startIndex >= endIndex) {
      return null;
    }

    // 在范围内查找最大值（dB域中直接比较）
    let maxIndex = startIndex;
    let maxDb = spectrumData[startIndex];
    
    for (let i = startIndex + 1; i <= endIndex; i++) {
      const dbValue = spectrumData[i];
      if (dbValue > maxDb) {
        maxDb = dbValue;
        maxIndex = i;
      }
    }

    // 检查是否为局部最大值
    if (maxIndex <= 0 || maxIndex >= spectrumData.length - 1) {
      return this.createPeakInfo(spectrumData, maxIndex, 0, config);
    }

    const prevDb = spectrumData[maxIndex - 1];
    const nextDb = spectrumData[maxIndex + 1];
    
    if (maxDb < prevDb || maxDb < nextDb) {
      return null; // 不是局部最大值
    }

    if (!config.enableInterpolation || config.interpolationMethod === InterpolationMethod.NONE) {
      return this.createPeakInfo(spectrumData, maxIndex, 0, config);
    }

    // 抛物线插值（在dB域中进行）
    // 注意：dB域中的抛物线插值是近似的，但对于小范围是合理的
    const alpha = prevDb;
    const beta = maxDb;
    const gamma = nextDb;
    const denominator = 2 * (alpha - 2 * beta + gamma);
    
    let interpolatedIndex = maxIndex;
    let confidence = 1.0;
    
    if (Math.abs(denominator) > 1e-10) {
      const delta = (alpha - gamma) / denominator;
      // 限制偏移量在 [-0.5, 0.5] 范围内
      const clampedDelta = Math.max(-0.5, Math.min(0.5, delta));
      interpolatedIndex = maxIndex + clampedDelta;
      confidence = 1.0 - Math.abs(clampedDelta);
    }

    return this.createPeakInfo(spectrumData, interpolatedIndex, confidence, config);
  }

  detectMultiplePeaks(
    spectrumData: Float32Array,
    peakCount: number,
    config: SpectrumAnalysisConfig
  ): PeakInfo[] {
    const peaks: PeakInfo[] = [];
    const processedBins = new Set<number>();
    const minBinDistance = Math.ceil(
      (config.minPeakDistanceHz * config.fftSize) / config.sampleRate
    );

    for (let p = 0; p < peakCount; p++) {
      let bestPeak: PeakInfo | null = null;
      let bestDb = config.minPeakHeightDb;

      for (let i = 1; i < spectrumData.length - 1; i++) {
        // 跳过已处理的bin
        if (processedBins.has(i)) continue;

        // 直接比较dB值（spectrumData已经是dB值）
        const dbValue = spectrumData[i];
        const prevDb = spectrumData[i - 1];
        const nextDb = spectrumData[i + 1];

        // 检查是否为局部最大值
        if (dbValue <= prevDb || dbValue <= nextDb) continue;
        
        // 检查是否满足最小高度要求
        if (dbValue <= bestDb) continue;

        const peak = this.detectSinglePeak(spectrumData, i - 1, i + 1, config);
        if (peak && peak.dbValue > bestDb) {
          bestPeak = peak;
          bestDb = peak.dbValue;
        }
      }

      if (bestPeak) {
        peaks.push(bestPeak);
        // 标记周围bin为已处理
        const centerIndex = Math.round(bestPeak.index);
        for (let i = centerIndex - minBinDistance; i <= centerIndex + minBinDistance; i++) {
          processedBins.add(i);
        }
      } else {
        break; // 没有找到更多峰值
      }
    }

    return peaks;
  }

  private createPeakInfo(
    spectrumData: Float32Array,
    index: number,
    confidence: number,
    config: SpectrumAnalysisConfig
  ): PeakInfo {
    const binIndex = Math.floor(index);
    const fractionalPart = index - binIndex;
    
    // 线性插值获取幅度
    const amplitude = fractionalPart === 0 
      ? Math.abs(spectrumData[binIndex])
      : Math.abs(spectrumData[binIndex]) * (1 - fractionalPart) + 
        Math.abs(spectrumData[Math.min(binIndex + 1, spectrumData.length - 1)]) * fractionalPart;

    // 计算频率
    const frequency = (index * config.sampleRate) / config.fftSize;
    
    // 计算dB值 (功率谱使用 10*log10)
    const dbValue = this.amplitudeToDb(amplitude, config);

    return {
      frequency: Math.max(0, frequency),
      dbValue,
      amplitude,
      index: binIndex,
      confidence
    };
  }

  private amplitudeToDb(amplitude: number, config: SpectrumAnalysisConfig): number {
    // 功率谱：使用 10*log10，不是 20*log10
    const MIN_AMPLITUDE = 1e-10;
    if (amplitude <= MIN_AMPLITUDE) {
      return -120;
    }
    return 10 * Math.log10(amplitude * amplitude);
  }
}

/**
 * 高斯插值峰值检测策略
 * 适用于需要更高精度的场景
 */
export class GaussianPeakDetectionStrategy implements PeakDetectionStrategy {
  detectSinglePeak(
    spectrumData: Float32Array,
    startIndex: number,
    endIndex: number,
    config: SpectrumAnalysisConfig
  ): PeakInfo | null {
    if (startIndex < 0 || endIndex >= spectrumData.length || startIndex >= endIndex) {
      return null;
    }

    // 找到最大值作为峰值中心
    let maxIndex = startIndex;
    let maxValue = Math.abs(spectrumData[startIndex]);
    
    for (let i = startIndex + 1; i <= endIndex; i++) {
      const value = Math.abs(spectrumData[i]);
      if (value > maxValue) {
        maxValue = value;
        maxIndex = i;
      }
    }

    if (!config.enableInterpolation || maxIndex <= 0 || maxIndex >= spectrumData.length - 1) {
      return this.createPeakInfo(spectrumData, maxIndex, 0, config);
    }

    // 高斯插值：ln(y) = a - (x-b)²/(2c²)
    const y0 = Math.log(Math.max(Math.abs(spectrumData[maxIndex - 1]), 1e-10));
    const y1 = Math.log(Math.max(Math.abs(spectrumData[maxIndex]), 1e-10));
    const y2 = Math.log(Math.max(Math.abs(spectrumData[maxIndex + 1]), 1e-10));

    // 计算偏移量
    const delta = (y0 - y2) / (2 * (y0 - 2 * y1 + y2));
    const clampedDelta = Math.max(-0.5, Math.min(0.5, isNaN(delta) ? 0 : delta));
    
    const interpolatedIndex = maxIndex + clampedDelta;
    const confidence = 1.0 - Math.abs(clampedDelta);

    return this.createPeakInfo(spectrumData, interpolatedIndex, confidence, config);
  }

  detectMultiplePeaks(
    spectrumData: Float32Array,
    peakCount: number,
    config: SpectrumAnalysisConfig
  ): PeakInfo[] {
    // 复用抛物线策略的多峰值检测逻辑
    const parabolicStrategy = new ParabolicPeakDetectionStrategy();
    return parabolicStrategy.detectMultiplePeaks(spectrumData, peakCount, config);
  }

  private createPeakInfo(
    spectrumData: Float32Array,
    index: number,
    confidence: number,
    config: SpectrumAnalysisConfig
  ): PeakInfo {
    const frequency = (index * config.sampleRate) / config.fftSize;
    const binIndex = Math.floor(index);
    const amplitude = Math.abs(spectrumData[binIndex]);
    const dbValue = amplitude > 0 ? 10 * Math.log10(amplitude * amplitude) : -120;

    return {
      frequency: Math.max(0, frequency),
      dbValue,
      amplitude,
      index: binIndex,
      confidence
    };
  }
}

/**
 * 频谱分析器核心类
 * 提供统一的频谱分析接口
 */
export class SpectrumAnalyzerCore {
  private peakStrategy: PeakDetectionStrategy;
  private previousSpectrum: Float32Array | null = null;

  constructor(strategy: PeakDetectionStrategy = new ParabolicPeakDetectionStrategy()) {
    this.peakStrategy = strategy;
  }

  /**
   * 设置峰值检测策略
   */
  setPeakStrategy(strategy: PeakDetectionStrategy): void {
    this.peakStrategy = strategy;
  }

  /**
   * 分析频谱数据
   * @param spectrumData 原始频谱数据 (复数或幅度)
   * @param config 分析配置
   * @returns 分析结果
   */
  analyze(
    spectrumData: Float32Array,
    config: SpectrumAnalysisConfig
  ): SpectrumAnalysisResult {
    // 1. 数据验证
    if (!spectrumData || spectrumData.length === 0) {
      return this.createEmptyResult(config);
    }

    // 2. 应用平滑 (可选)
    const smoothedData = config.smoothingFactor > 0 && this.previousSpectrum
      ? this.applySmoothing(spectrumData, config.smoothingFactor)
      : spectrumData;

    this.previousSpectrum = new Float32Array(smoothedData);

    // 3. 生成数据点
    const dataPoints = this.generateDataPoints(smoothedData, config);

    // 4. 检测峰值
    const peakInfo = this.peakStrategy.detectSinglePeak(
      smoothedData, 
      1, 
      smoothedData.length - 2, 
      config
    );

    const peakInfos = this.peakStrategy.detectMultiplePeaks(
      smoothedData, 
      5, // 最多检测5个峰值
      config
    );

    return {
      dataPoints,
      peakInfo,
      peakInfos,
      frequencyResolution: config.sampleRate / config.fftSize,
      timestamp: Date.now()
    };
  }

  /**
   * 重置分析器状态
   */
  reset(): void {
    this.previousSpectrum = null;
  }

  private applySmoothing(
    currentData: Float32Array,
    smoothingFactor: number
  ): Float32Array {
    if (!this.previousSpectrum || this.previousSpectrum.length !== currentData.length) {
      return currentData;
    }

    const smoothed = new Float32Array(currentData.length);
    const factor = Math.max(0, Math.min(1, smoothingFactor));

    for (let i = 0; i < currentData.length; i++) {
      smoothed[i] = factor * currentData[i] + (1 - factor) * this.previousSpectrum[i];
    }

    return smoothed;
  }

  private generateDataPoints(
    spectrumData: Float32Array,
    config: SpectrumAnalysisConfig
  ): SpectrumDataPoint[] {
    const points: SpectrumDataPoint[] = [];
    const nyquistFreq = config.sampleRate / 2;

    for (let i = 0; i < spectrumData.length; i++) {
      const frequency = (i * config.sampleRate) / config.fftSize;
      if (frequency > nyquistFreq) break;

      // 重要：spectrumData 已经是 dB 值（由 FFTAnalyzer 输出）
      const dbValue = spectrumData[i];
      
      // 将dB转回幅度用于显示
      const amplitude = Math.pow(10, dbValue / 20);

      points.push({
        frequency,
        amplitude,
        dbValue,
        index: i
      });
    }

    return points;
  }

  private createEmptyResult(config: SpectrumAnalysisConfig): SpectrumAnalysisResult {
    return {
      dataPoints: [],
      peakInfo: null,
      peakInfos: [],
      frequencyResolution: config.sampleRate / config.fftSize,
      timestamp: Date.now()
    };
  }
}

/**
 * 频谱分析器工厂
 */
export class SpectrumAnalyzerFactory {
  /**
   * 创建标准频谱分析器 (抛物线插值)
   */
  static createStandardAnalyzer(): SpectrumAnalyzerCore {
    return new SpectrumAnalyzerCore(new ParabolicPeakDetectionStrategy());
  }

  /**
   * 创建高精度频谱分析器 (高斯插值)
   */
  static createHighPrecisionAnalyzer(): SpectrumAnalyzerCore {
    return new SpectrumAnalyzerCore(new GaussianPeakDetectionStrategy());
  }

  /**
   * 创建快速频谱分析器 (无插值)
   */
  static createFastAnalyzer(): SpectrumAnalyzerCore {
    const analyzer = new SpectrumAnalyzerCore(new ParabolicPeakDetectionStrategy());
    return analyzer;
  }
}
