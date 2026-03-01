/**
 * 频谱数据处理器
 * 基于 SpectrumAnalysisCore 的包装器，提供向后兼容的接口
 * 
 * 主要修复：
 * 1. 幅度转换：功率谱使用 10*log10，不是 20*log10
 * 2. 峰值检测：统一使用抛物线插值
 * 3. 数据流：减少不必要的转换和复制
 */

import {
  SpectrumAnalyzerCore,
  SpectrumAnalyzerFactory,
  SpectrumAnalysisConfig,
  SpectrumAnalysisResult,
  PeakInfo as CorePeakInfo,
  InterpolationMethod
} from '../../core/SpectrumAnalysisCore';
import { WindowType } from '../../common/WindowType';
import { WeightingType } from '../../constants/WeightingConstants';

/**
 * 频谱数据点类型 - 保持向后兼容
 */
export interface SpectrumDataPoint {
  frequency: number; // 频率 (Hz)
  amplitude: number; // 幅值 (线性)
  dbValue: number;   // 分贝值 (dB)
  index: number;     // 在原始数组中的索引
}

/**
 * 峰值信息类型 - 保持向后兼容
 */
export interface PeakInfo extends CorePeakInfo {}

/**
 * 频率和幅度结果接口 - 保持向后兼容
 */
export interface FrequencyAmplitudeResult {
  frequency: number;
  amplitude: number;
}

/**
 * 峰值插值方法枚举 - 保持向后兼容，但内部统一使用新架构
 */
export enum PeakInterpolationMethod {
  NONE = 'none',
  PARABOLIC = 'parabolic',
  CENTROID = 'centroid',
  QUADRATIC = 'quadratic',
  GAUSSIAN = 'gaussian',
  SINC = 'sinc',
  PHASE_VOCODER = 'phase_vocoder',
  INTERPOLATIVE = 'interpolative',
  ADAPTIVE = 'adaptive',
  HYBRID = 'hybrid'
}

/**
 * 频谱数据处理器
 * 提供统一的频谱数据处理方法
 */
export class SpectrumDataProcessor {
  // 标准频率步进点
  private static readonly FREQUENCY_STEPS = [16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
  // 标准分贝步进点
  private static readonly DB_STEPS = [-20, 0, 20, 40, 60, 80, 100, 120, 140];
  // 有效频率范围 (人耳听觉范围)
  public static readonly MIN_FREQUENCY = 16;
  public static readonly MAX_FREQUENCY = 20000;

  // 单例分析器核心
  private static analyzerCore: SpectrumAnalyzerCore = SpectrumAnalyzerFactory.createStandardAnalyzer();

  // ============ 幅度/分贝转换工具方法 ============

  /**
   * 幅度转分贝 (功率谱)
   * 修复：功率谱使用 10*log10(amplitude^2) = 20*log10(amplitude)
   * @param amplitude 线性幅度
   * @returns 分贝值
   */
  static amplitudeToDb(amplitude: number): number {
    const MIN_AMPLITUDE = 1e-10;
    if (amplitude <= MIN_AMPLITUDE) {
      return -120;
    }
    // 功率谱：10 * log10(power) = 10 * log10(amplitude^2) = 20 * log10(amplitude)
    return 20 * Math.log10(amplitude);
  }

  /**
   * 分贝转幅度 (功率谱)
   * 修复：幅度 = 10^(dB/20)
   * @param dbValue 分贝值
   * @returns 线性幅度
   */
  static dbToAmplitude(dbValue: number): number {
    if (dbValue <= -120) {
      return 0;
    }
    // 修复：原来是 dbValue / 20，这是正确的
    // 因为 amplitude = 10^(dB/20)
    return Math.pow(10, dbValue / 20);
  }

  /**
   * 功率转分贝
   * @param power 功率值
   * @returns 分贝值
   */
  static powerToDb(power: number): number {
    const MIN_POWER = 1e-12;
    if (power <= MIN_POWER) {
      return -120;
    }
    return 10 * Math.log10(power);
  }

  /**
   * 分贝转功率
   * @param dbValue 分贝值
   * @returns 功率值
   */
  static dbToPower(dbValue: number): number {
    if (dbValue <= -120) {
      return 0;
    }
    return Math.pow(10, dbValue / 10);
  }

  // ============ 频率/索引转换 ============

  /**
   * 获取频率对应的索引
   */
  static getFrequencyIndex(frequency: number, fftSize: number, sampleRate: number): number {
    const validFreq = Math.max(0, Math.min(frequency, sampleRate / 2));
    return Math.round(validFreq * fftSize / sampleRate);
  }

  /**
   * 获取索引对应的频率
   */
  static getIndexFrequency(index: number, fftSize: number, sampleRate: number): number {
    const validIndex = Math.max(0, Math.min(index, fftSize / 2));
    return validIndex * sampleRate / fftSize;
  }

  // ============ 峰值检测 (使用新架构) ============

  /**
   * 查找峰值频率 - 统一使用抛物线插值
   * @param spectrumData 频谱数据
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @param minFreq 最小频率限制
   * @param maxFreq 最大频率限制
   * @returns 峰值信息或null
   */
  static findPeakFrequency(
    spectrumData: Float32Array,
    fftSize: number,
    sampleRate: number,
    minFreq: number = SpectrumDataProcessor.MIN_FREQUENCY,
    maxFreq: number = SpectrumDataProcessor.MAX_FREQUENCY,
    useInterpolation: boolean = true
  ): PeakInfo | null {
    if (spectrumData.length === 0) {
      return null;
    }

    const config: SpectrumAnalysisConfig = {
      sampleRate,
      fftSize,
      windowType: WindowType.HANNING,
      weightingType: WeightingType.Z,
      enableInterpolation: useInterpolation,
      interpolationMethod: InterpolationMethod.PARABOLIC,
      minPeakDistanceHz: 10,
      minPeakHeightDb: -60,
      smoothingFactor: 0
    };

    const result = SpectrumDataProcessor.analyzerCore.analyze(spectrumData, config);
    
    // 过滤频率范围
    if (result.peakInfo) {
      const peak = result.peakInfo;
      if (peak.frequency >= minFreq && peak.frequency <= maxFreq) {
        return peak;
      }
    }

    return null;
  }

  /**
   * 查找多个峰值频率 - 统一使用抛物线插值
   * @param spectrumData 频谱数据
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @param peakCount 最大峰值数量
   * @param minPeakDistance 最小峰值间隔 (Hz)
   * @param minPeakHeight 最小峰值高度 (dB)
   * @returns 峰值信息数组
   */
  static findMultiplePeaks(
    spectrumData: Float32Array,
    fftSize: number,
    sampleRate: number,
    peakCount: number = 3,
    minPeakDistance: number = 10,
    minPeakHeight: number = -60,
    useInterpolation: boolean = true
  ): PeakInfo[] {
    if (spectrumData.length === 0 || peakCount <= 0) {
      return [];
    }

    const config: SpectrumAnalysisConfig = {
      sampleRate,
      fftSize,
      windowType: WindowType.HANNING,
      weightingType: WeightingType.Z,
      enableInterpolation: useInterpolation,
      interpolationMethod: InterpolationMethod.PARABOLIC,
      minPeakDistanceHz: minPeakDistance,
      minPeakHeightDb: minPeakHeight,
      smoothingFactor: 0
    };

    const result = SpectrumDataProcessor.analyzerCore.analyze(spectrumData, config);
    return result.peakInfos.slice(0, peakCount);
  }

  // ============ 频谱数据处理 ============

  /**
   * 处理频谱数据，转换为标准数据点数组
   * @param spectrumData 原始频谱数据 (幅度值)
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @param indices 要处理的索引数组
   * @returns 频谱数据点数组
   */
  static processSpectrumData(
    spectrumData: Float32Array,
    fftSize: number,
    sampleRate: number,
    indices: number[]
  ): SpectrumDataPoint[] {
    const dataPoints: SpectrumDataPoint[] = [];

    for (const index of indices) {
      if (index < spectrumData.length) {
        const frequency = SpectrumDataProcessor.getIndexFrequency(index, fftSize, sampleRate);
        const amplitude = Math.abs(spectrumData[index]);
        // 修复：使用正确的幅度转分贝公式
        const dbValue = SpectrumDataProcessor.amplitudeToDb(amplitude);

        dataPoints.push({
          frequency,
          amplitude,
          dbValue,
          index
        });
      }
    }

    return dataPoints;
  }

  /**
   * 生成增强的频谱数据
   * 简化版本：直接返回原始FFT数据点，不进行插值
   */
  static generateEnhancedSpectrumData(
    spectrumData: Float32Array,
    fftSize: number,
    sampleRate: number,
    minFreq: number = SpectrumDataProcessor.MIN_FREQUENCY,
    maxFreq: number = SpectrumDataProcessor.MAX_FREQUENCY
  ): SpectrumDataPoint[] {
    const dataPoints: SpectrumDataPoint[] = [];

    for (let i = 0; i < fftSize / 2 && i < spectrumData.length; i++) {
      const frequency = SpectrumDataProcessor.getIndexFrequency(i, fftSize, sampleRate);
      
      if (frequency < minFreq || frequency > maxFreq) {
        continue;
      }

      const amplitude = Math.abs(spectrumData[i]);
      // 修复：使用正确的幅度转分贝公式
      const dbValue = SpectrumDataProcessor.amplitudeToDb(amplitude);

      dataPoints.push({
        frequency,
        amplitude,
        dbValue,
        index: i
      });
    }

    return dataPoints;
  }

  /**
   * 应用数据平滑处理
   * @param currentData 当前频谱数据
   * @param previousData 上一次频谱数据
   * @param smoothingFactor 平滑因子 (0-1)
   */
  static applyDataSmoothing(
    currentData: Float32Array,
    previousData: Float32Array,
    smoothingFactor: number = 0.3
  ): Float32Array {
    if (currentData.length === 0) {
      return new Float32Array();
    }

    if (previousData.length !== currentData.length) {
      return new Float32Array(currentData);
    }

    const smoothedData = new Float32Array(currentData.length);
    const factor = Math.max(0, Math.min(1, smoothingFactor));

    for (let i = 0; i < currentData.length; i++) {
      smoothedData[i] = factor * currentData[i] + (1 - factor) * previousData[i];
    }

    return smoothedData;
  }

  // ============ 工具方法 ============

  /**
   * 获取标准频率步进点
   */
  static getFrequencySteps(): number[] {
    return [...SpectrumDataProcessor.FREQUENCY_STEPS];
  }

  /**
   * 获取标准分贝步进点
   */
  static getDbSteps(): number[] {
    return [...SpectrumDataProcessor.DB_STEPS];
  }

  /**
   * 格式化频率显示
   */
  static formatFrequency(freq: number): string {
    if (freq < 1000) {
      return `${Math.round(freq)}Hz`;
    } else {
      return `${(freq / 1000).toFixed(1)}kHz`;
    }
  }

  /**
   * 根据分贝值获取颜色
   */
  static getDbColor(dbValue: number): string {
    if (dbValue < 50) {
      return '#FF00FF00'; // 绿色 - 安全
    } else if (dbValue < 70) {
      return '#FFFFFF00'; // 黄色 - 注意
    } else if (dbValue < 85) {
      return '#FFFF8800'; // 橙色 - 警告
    } else {
      return '#FFFF0000'; // 红色 - 危险
    }
  }

  /**
   * 验证峰值是否为局部最大值
   */
  static validatePeak(
    spectrumData: Float32Array,
    peakIndex: number,
    windowSize: number = 3
  ): boolean {
    if (peakIndex < 0 || peakIndex >= spectrumData.length) {
      return false;
    }

    const peakValue = Math.abs(spectrumData[peakIndex]);
    const startIdx = Math.max(0, peakIndex - windowSize);
    const endIdx = Math.min(spectrumData.length - 1, peakIndex + windowSize);

    for (let i = startIdx; i <= endIdx; i++) {
      if (i !== peakIndex && Math.abs(spectrumData[i]) >= peakValue) {
        return false;
      }
    }

    return true;
  }

  /**
   * 重置处理器状态
   */
  static reset(): void {
    SpectrumDataProcessor.analyzerCore.reset();
  }
}

/**
 * 峰值稳定器类
 * 用于减少峰值显示的跳变，提高用户体验
 * 优化：降低延迟，提高响应性
 */
export class PeakStabilizer {
  private previousPeaks: PeakInfo[] = [];
  private lastUpdateTime: number = 0;
  private readonly UPDATE_THRESHOLD_MS: number = 150; // 降低从300ms到150ms
  private readonly FREQUENCY_CHANGE_THRESHOLD_HZ: number = 30; // 降低从50Hz到30Hz
  private readonly DB_CHANGE_THRESHOLD: number = 2.0; // 降低从3.0dB到2.0dB
  private readonly SMOOTHING_FACTOR: number = 0.35; // 增加从0.2到0.35

  /**
   * 稳定峰值数据
   * @param currentPeaks 当前检测到的峰值
   * @returns 稳定后的峰值
   */
  stabilizePeaks(currentPeaks: PeakInfo[]): PeakInfo[] {
    const currentTime = Date.now();

    // 如果是第一次检测到峰值，直接使用
    if (this.previousPeaks.length === 0) {
      this.previousPeaks = [...currentPeaks];
      this.lastUpdateTime = currentTime;
      return currentPeaks;
    }

    // 检查是否满足时间间隔要求
    if (currentTime - this.lastUpdateTime < this.UPDATE_THRESHOLD_MS) {
      return this.previousPeaks;
    }

    const stabilizedPeaks: PeakInfo[] = [];

    // 为每个当前峰值找到最接近的历史峰值
    for (let i = 0; i < currentPeaks.length && i < 5; i++) {
      const currentPeak = currentPeaks[i];
      let bestMatch: PeakInfo | null = null;
      let minDistance = Infinity;

      // 找到最接近的历史峰值
      for (const prevPeak of this.previousPeaks) {
        const freqDistance = Math.abs(currentPeak.frequency - prevPeak.frequency);
        const dbDistance = Math.abs(currentPeak.dbValue - prevPeak.dbValue);
        const combinedDistance = freqDistance / 100 + dbDistance;

        if (combinedDistance < minDistance) {
          minDistance = combinedDistance;
          bestMatch = prevPeak;
        }
      }

      if (bestMatch) {
        const freqChange = Math.abs(currentPeak.frequency - bestMatch.frequency);
        const dbChange = Math.abs(currentPeak.dbValue - bestMatch.dbValue);

        if (freqChange < this.FREQUENCY_CHANGE_THRESHOLD_HZ && dbChange < this.DB_CHANGE_THRESHOLD) {
          // 变化较小，应用平滑算法
          const stabilizedPeak: PeakInfo = {
            frequency: this.SMOOTHING_FACTOR * currentPeak.frequency +
              (1 - this.SMOOTHING_FACTOR) * bestMatch.frequency,
            dbValue: this.SMOOTHING_FACTOR * currentPeak.dbValue +
              (1 - this.SMOOTHING_FACTOR) * bestMatch.dbValue,
            index: currentPeak.index,
            amplitude: this.SMOOTHING_FACTOR * currentPeak.amplitude +
              (1 - this.SMOOTHING_FACTOR) * bestMatch.amplitude,
            confidence: currentPeak.confidence
          };
          stabilizedPeaks.push(stabilizedPeak);
        } else {
          // 变化较大，直接使用当前值
          stabilizedPeaks.push(currentPeak);
        }
      } else {
        stabilizedPeaks.push(currentPeak);
      }
    }

    this.previousPeaks = [...stabilizedPeaks];
    this.lastUpdateTime = currentTime;

    return stabilizedPeaks;
  }

  /**
   * 重置稳定器状态
   */
  reset(): void {
    this.previousPeaks = [];
    this.lastUpdateTime = 0;
  }
}
