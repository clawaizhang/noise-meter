import { SpectrumDataProcessor, SpectrumDataPoint, PeakInfo, PeakInterpolationMethod } from '../components/decibel-meter/SpectrumDataProcessor';
import { PreferenceKeys } from '../models/PreferenceKeys';

/**
 * 频谱显示模式枚举
 */
export enum SpectrumDisplayMode {
  LINE = 'line',      // 线形图
  BAR = 'bar',        // 柱状图
  HYBRID = 'hybrid'    // 混合模式
}

/**
 * 频率范围枚举
 */
export enum FrequencyRange {
  FULL = 'full',        // 全频段 16Hz-20kHz
  LOW = 'low',          // 低频段 16Hz-250Hz
  MID = 'mid',          // 中频段 250Hz-2kHz
  HIGH = 'high',        // 高频段 2kHz-20kHz
  CUSTOM = 'custom'      // 自定义范围
}

/**
 * 分贝范围枚举
 */
export enum DecibelRange {
  AUTO = 'auto',        // 自动范围
  NARROW = 'narrow',    // 窄范围 40-80dB
  NORMAL = 'normal',     // 正常范围 20-100dB
  WIDE = 'wide',        // 宽范围 0-120dB
  CUSTOM = 'custom'      // 自定义范围
}

/**
 * 频率范围配置类
 */
export class FrequencyRangeConfig {
  minFreq: number = 0;
  maxFreq: number = 0;

  constructor(minFreq: number, maxFreq: number) {
    this.minFreq = minFreq;
    this.maxFreq = maxFreq;
  }
}

/**
 * 分贝范围配置类
 */
export class DecibelRangeConfig {
  minDb: number = 0;
  maxDb: number = 0;

  constructor(minDb: number, maxDb: number) {
    this.minDb = minDb;
    this.maxDb = maxDb;
  }
}

/**
 * 频谱显示配置接口
 */
export interface SpectrumDisplayConfig {
  displayMode: SpectrumDisplayMode;
  smoothingFactor: number;
  showPeakFrequency: boolean;
  frequencyRange: FrequencyRange;
  decibelRange: DecibelRange;
  customFrequencyMin?: number;
  customFrequencyMax?: number;
  customDecibelMin?: number;
  customDecibelMax?: number;
}

/**
 * 频谱显示数据接口
 */
export interface SpectrumDisplayData {
  dataPoints: SpectrumDataPoint[];
  peakInfo: PeakInfo | null;
  frequencyLabels: string[];
  decibelSteps: number[];
  frequencySteps: number[];
}

/**
 * 统一的频谱显示服务
 * 提供频谱数据处理和显示配置管理
 */
export class SpectrumDisplayService {
  private static instance: SpectrumDisplayService | null = null;
  private previousSpectrumData: Float32Array = new Float32Array();
  private smoothedPeakInfo: PeakInfo | null = null;
  private lastPeakUpdateTime: number = 0;
  
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  static getInstance(): SpectrumDisplayService {
    if (!SpectrumDisplayService.instance) {
      SpectrumDisplayService.instance = new SpectrumDisplayService();
    }
    return SpectrumDisplayService.instance;
  }
  
  /**
   * 从PreferenceKeys获取频谱显示配置
   */
  getDisplayConfig(pk: PreferenceKeys): SpectrumDisplayConfig {
    return {
      displayMode: pk.spectrum_display_mode as SpectrumDisplayMode || SpectrumDisplayMode.LINE,
      smoothingFactor: pk.spectrum_smoothing_factor,
      showPeakFrequency: pk.spectrum_show_peak_frequency,
      frequencyRange: pk.spectrum_frequency_range as FrequencyRange || FrequencyRange.FULL,
      decibelRange: pk.spectrum_db_range as DecibelRange || DecibelRange.AUTO,
      customFrequencyMin: pk.spectrum_custom_frequency_min,
      customFrequencyMax: pk.spectrum_custom_frequency_max,
      customDecibelMin: pk.spectrum_custom_decibel_min,
      customDecibelMax: pk.spectrum_custom_decibel_max
    };
  }
  
  /**
   * 应用频谱显示配置到PreferenceKeys
   */
  applyDisplayConfig(pk: PreferenceKeys, config: SpectrumDisplayConfig): void {
    pk.spectrum_display_mode = config.displayMode;
    pk.spectrum_smoothing_factor = config.smoothingFactor;
    pk.spectrum_show_peak_frequency = config.showPeakFrequency;
    pk.spectrum_frequency_range = config.frequencyRange;
    pk.spectrum_db_range = config.decibelRange;
    
    // 保存自定义范围值
    if (config.customFrequencyMin !== undefined) {
      pk.spectrum_custom_frequency_min = config.customFrequencyMin;
    }
    if (config.customFrequencyMax !== undefined) {
      pk.spectrum_custom_frequency_max = config.customFrequencyMax;
    }
    if (config.customDecibelMin !== undefined) {
      pk.spectrum_custom_decibel_min = config.customDecibelMin;
    }
    if (config.customDecibelMax !== undefined) {
      pk.spectrum_custom_decibel_max = config.customDecibelMax;
    }
  }
  
  /**
   * 处理频谱数据，返回用于显示的数据
   */
  processSpectrumData(
    rawSpectrumData: Float32Array,
    fftSize: number,
    sampleRate: number,
    config: SpectrumDisplayConfig
  ): SpectrumDisplayData {
    // 1. 应用数据平滑
    const smoothedSpectrumData = this.applyDataSmoothing(rawSpectrumData, config.smoothingFactor);
    
    // 2. 获取频率和分贝范围
    const frequencyRangeConfig = this.getFrequencyRange(config, fftSize, sampleRate);
    const decibelRangeConfig = this.getDecibelRange(config);
    const minFreq = frequencyRangeConfig.minFreq;
    const maxFreq = frequencyRangeConfig.maxFreq;
    const minDb = decibelRangeConfig.minDb;
    const maxDb = decibelRangeConfig.maxDb;
    
    // 3. 生成增强的频谱数据点
    const dataPoints = SpectrumDataProcessor.generateEnhancedSpectrumData(
      smoothedSpectrumData,
      fftSize,
      sampleRate,
      minFreq,
      maxFreq
    );
    
    // 4. 过滤数据点到指定范围
    const filteredDataPoints = this.filterDataPoints(dataPoints, minFreq, maxFreq, minDb, maxDb);
    
    // 5. 查找峰值频率
    const peakInfo = this.findPeakFrequency(filteredDataPoints, fftSize, sampleRate);
    
    // 6. 生成频率标签
    const frequencyLabels = this.generateFrequencyLabels(minFreq, maxFreq);
    
    // 7. 获取分贝步进
    const decibelSteps = this.getDecibelSteps(minDb, maxDb);
    
    // 8. 获取频率步进
    const frequencySteps = this.getFrequencySteps(minFreq, maxFreq);
    
    return {
      dataPoints: filteredDataPoints,
      peakInfo,
      frequencyLabels,
      decibelSteps,
      frequencySteps
    };
  }
  
  /**
   * 应用峰值平滑处理
   */
  applyPeakSmoothing(
    currentPeakInfo: PeakInfo,
    previousSmoothedPeakInfo: PeakInfo | null,
    lastUpdateTime: number
  ): PeakInfo | null {
    if (!currentPeakInfo) {
      return null;
    }

    const currentTime = Date.now();
    const PEAK_UPDATE_THRESHOLD_MS = 200;
    const PEAK_CHANGE_THRESHOLD_DB = 2.0;
    const PEAK_CHANGE_THRESHOLD_HZ = 100;
    
    // 如果是第一次检测到峰值，直接使用
    if (!previousSmoothedPeakInfo) {
      this.smoothedPeakInfo = {
        frequency: currentPeakInfo.frequency,
        dbValue: currentPeakInfo.dbValue,
        index: currentPeakInfo.index,
        amplitude: currentPeakInfo.amplitude
      };
      this.lastPeakUpdateTime = currentTime;
      return this.smoothedPeakInfo;
    }

    // 检查是否满足时间间隔要求
    if (currentTime - lastUpdateTime < PEAK_UPDATE_THRESHOLD_MS) {
      return previousSmoothedPeakInfo; // 时间间隔太短，不更新
    }

    // 检查峰值变化是否超过阈值
    const dbChange = Math.abs(currentPeakInfo.dbValue - previousSmoothedPeakInfo.dbValue);
    const freqChange = Math.abs(currentPeakInfo.frequency - previousSmoothedPeakInfo.frequency);

    if (dbChange < PEAK_CHANGE_THRESHOLD_DB && freqChange < PEAK_CHANGE_THRESHOLD_HZ) {
      return previousSmoothedPeakInfo; // 变化太小，不更新
    }

    // 应用平滑算法：加权平均
    const smoothingFactor = 0.15; // 平滑因子，越小越平滑
    this.smoothedPeakInfo = {
      frequency: smoothingFactor * currentPeakInfo.frequency + (1 - smoothingFactor) * previousSmoothedPeakInfo.frequency,
      dbValue: smoothingFactor * currentPeakInfo.dbValue + (1 - smoothingFactor) * previousSmoothedPeakInfo.dbValue,
      index: currentPeakInfo.index,
      amplitude: smoothingFactor * currentPeakInfo.amplitude + (1 - smoothingFactor) * previousSmoothedPeakInfo.amplitude
    };
    
    this.lastPeakUpdateTime = currentTime;
    return this.smoothedPeakInfo;
  }
  
  /**
   * 应用数据平滑处理
   */
  private applyDataSmoothing(
    currentData: Float32Array,
    smoothingFactor: number
  ): Float32Array {
    if (this.previousSpectrumData.length !== currentData.length) {
      this.previousSpectrumData = new Float32Array(currentData.length);
      this.previousSpectrumData.set(currentData);
      return currentData; // 第一次或长度不匹配，直接返回原始数据
    }
    
    // 使用SpectrumDataProcessor的静态方法进行平滑处理
    const smoothedData = SpectrumDataProcessor.applyDataSmoothing(
      currentData,
      this.previousSpectrumData,
      smoothingFactor
    );
    
    // 保存当前数据用于下次平滑
    this.previousSpectrumData.set(currentData);
    
    return smoothedData;
  }
  
  /**
   * 获取频率范围
   */
  private getFrequencyRange(
    config: SpectrumDisplayConfig,
    fftSize: number,
    sampleRate: number
  ): FrequencyRangeConfig {
    // 默认频率范围
    let minFreq = SpectrumDataProcessor.MIN_FREQUENCY; // 16Hz
    let maxFreq = Math.min(SpectrumDataProcessor.MAX_FREQUENCY, sampleRate / 2); // 20kHz或奈奎斯特频率
    
    // 根据配置调整频率范围
    switch (config.frequencyRange) {
      case FrequencyRange.LOW:
        maxFreq = 250;
        break;
      case FrequencyRange.MID:
        minFreq = 250;
        maxFreq = 2000;
        break;
      case FrequencyRange.HIGH:
        minFreq = 2000;
        break;
      case FrequencyRange.CUSTOM:
        minFreq = config.customFrequencyMin || minFreq;
        maxFreq = config.customFrequencyMax || maxFreq;
        break;
    }
    
    return new FrequencyRangeConfig(minFreq, maxFreq);
  }
  
  /**
   * 获取分贝范围
   */
  private getDecibelRange(config: SpectrumDisplayConfig): DecibelRangeConfig {
    // 默认分贝范围
    let minDb = -20;
    let maxDb = 140;
    
    // 根据配置调整分贝范围
    switch (config.decibelRange) {
      case DecibelRange.NARROW:
        minDb = 40;
        maxDb = 80;
        break;
      case DecibelRange.NORMAL:
        minDb = 20;
        maxDb = 100;
        break;
      case DecibelRange.WIDE:
        minDb = 0;
        maxDb = 120;
        break;
      case DecibelRange.CUSTOM:
        minDb = config.customDecibelMin || minDb;
        maxDb = config.customDecibelMax || maxDb;
        break;
    }
    
    return new DecibelRangeConfig(minDb, maxDb);
  }
  
  /**
   * 过滤数据点到指定范围
   */
  private filterDataPoints(
    dataPoints: SpectrumDataPoint[],
    minFreq: number,
    maxFreq: number,
    minDb: number,
    maxDb: number
  ): SpectrumDataPoint[] {
    return dataPoints.filter(point => 
      point.frequency >= minFreq && 
      point.frequency <= maxFreq && 
      point.dbValue >= minDb && 
      point.dbValue <= maxDb
    );
  }
  
  /**
   * 查找峰值频率
   */
  private findPeakFrequency(
    dataPoints: SpectrumDataPoint[],
    fftSize: number,
    sampleRate: number
  ): PeakInfo | null {
    if (dataPoints.length === 0) {
      return null;
    }
    
    // 找到最大值点
    let maxPoint = dataPoints[0];
    for (const point of dataPoints) {
      if (point.dbValue > maxPoint.dbValue) {
        maxPoint = point;
      }
    }
    
    return {
      frequency: maxPoint.frequency,
      dbValue: maxPoint.dbValue,
      index: maxPoint.index,
      amplitude: maxPoint.amplitude
    };
  }
  
  /**
   * 生成频率标签
   */
  private generateFrequencyLabels(minFreq: number, maxFreq: number): string[] {
    // 使用SpectrumDataProcessor的静态方法获取标准频率步进
    const standardFreqs = SpectrumDataProcessor.getFrequencySteps();
    const labels: string[] = [];
    
    for (const freq of standardFreqs) {
      if (freq >= minFreq && freq <= maxFreq) {
        // 使用SpectrumDataProcessor的格式化方法
        labels.push(SpectrumDataProcessor.formatFrequency(freq));
      }
    }
    
    return labels;
  }
  
  /**
   * 获取分贝步进
   */
  private getDecibelSteps(minDb: number, maxDb: number): number[] {
    // 使用SpectrumDataProcessor的静态方法获取标准分贝步进
    const allDbSteps = SpectrumDataProcessor.getDbSteps();
    
    // 过滤出在指定范围内的步进值
    return allDbSteps.filter(db => db >= minDb && db <= maxDb);
  }
  
  /**
   * 获取频率步进
   */
  private getFrequencySteps(minFreq: number, maxFreq: number): number[] {
    // 使用SpectrumDataProcessor的静态方法获取标准频率步进
    const allFreqSteps = SpectrumDataProcessor.getFrequencySteps();
    
    // 过滤出在指定范围内的步进值
    return allFreqSteps.filter(freq => freq >= minFreq && freq <= maxFreq);
  }
}