import { SpectrumDataProcessor, SpectrumDataPoint, PeakInfo, PeakInterpolationMethod, PeakStabilizer } from '../components/decibel-meter/SpectrumDataProcessor';
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
  displayMode?: SpectrumDisplayMode; // 可选，默认为 LINE
  smoothingFactor: number;
  exponentialSmoothingFactor: number; // 新增：指数平滑因子
  showPeakFrequency: boolean;
  peakCount: number; // 新增：显示峰值数量
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
  peakInfos: PeakInfo[]; // 新增：多个峰值信息
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
  private peakStabilizer: PeakStabilizer = new PeakStabilizer(); // 新增：峰值稳定器
  
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
      displayMode: SpectrumDisplayMode.LINE, // 固定为线性图模式
      smoothingFactor: pk.spectrum_smoothing_factor,
      exponentialSmoothingFactor: pk.custom_audio_config.exponentialSmoothingFactor, // 从custom_audio_config中获取指数平滑因子
      showPeakFrequency: pk.spectrum_show_peak_frequency,
      peakCount: pk.spectrum_peak_count || 1, // 新增：默认显示1个峰值
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
    pk.spectrum_smoothing_factor = config.smoothingFactor;
    pk.custom_audio_config.exponentialSmoothingFactor = config.exponentialSmoothingFactor; // 保存指数平滑因子到custom_audio_config
    pk.spectrum_show_peak_frequency = config.showPeakFrequency;
    pk.spectrum_peak_count = config.peakCount; // 新增：保存峰值数量
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
    
    // 3. 生成频谱数据点（注意：smoothedSpectrumData 已经是分贝值）
    const dataPoints = this.generateSpectrumDataPointsFromDb(
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
    
    // 6. 查找多个峰值频率
    const rawPeakInfos = this.findMultiplePeakFrequencies(filteredDataPoints, fftSize, sampleRate, config.peakCount);
    
    // 7. 应用峰值稳定算法
    const peakInfos = this.peakStabilizer.stabilizePeaks(rawPeakInfos);
    
    // 8. 生成频率标签
    const frequencyLabels = this.generateFrequencyLabels(minFreq, maxFreq);
    
    // 9. 获取分贝步进
    const decibelSteps = this.getDecibelSteps(minDb, maxDb);
    
    // 10. 获取频率步进
    const frequencySteps = this.getFrequencySteps(minFreq, maxFreq);
    
    return {
      dataPoints: filteredDataPoints,
      peakInfo,
      peakInfos, // 新增：多个峰值信息
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
        amplitude: currentPeakInfo.amplitude,
        confidence: currentPeakInfo.confidence
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
      amplitude: smoothingFactor * currentPeakInfo.amplitude + (1 - smoothingFactor) * previousSmoothedPeakInfo.amplitude,
      confidence: currentPeakInfo.confidence
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
  getFrequencyRange(
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
  getDecibelRange(config: SpectrumDisplayConfig): DecibelRangeConfig {
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
   * 从分贝值生成频谱数据点
   * 注意：输入的 spectrumData 已经是分贝值，不需要再次转换
   */
  private generateSpectrumDataPointsFromDb(
    spectrumData: Float32Array,
    fftSize: number,
    sampleRate: number,
    minFreq: number,
    maxFreq: number
  ): SpectrumDataPoint[] {
    const dataPoints: SpectrumDataPoint[] = [];
    
    for (let i = 0; i < fftSize / 2 && i < spectrumData.length; i++) {
      const frequency = (i * sampleRate) / fftSize;
      
      if (frequency < minFreq || frequency > maxFreq) {
        continue;
      }
      
      // 直接使用分贝值，不需要转换
      const dbValue = spectrumData[i];
      // 将dB转回幅度用于显示（如果需要原始幅度）
      const amplitude = Math.pow(10, dbValue / 20);
      
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
      amplitude: maxPoint.amplitude,
      confidence: 1.0
    };
  }
  
  /**
   * 查找多个峰值频率
   */
  private findMultiplePeakFrequencies(
    dataPoints: SpectrumDataPoint[],
    fftSize: number,
    sampleRate: number,
    peakCount: number
  ): PeakInfo[] {
    if (dataPoints.length === 0 || peakCount <= 0) {
      return [];
    }
    
    // 将数据点转换为频谱数据格式，以便使用SpectrumDataProcessor的方法
    const spectrumData = new Float32Array(dataPoints.length);
    for (let i = 0; i < dataPoints.length; i++) {
      spectrumData[i] = dataPoints[i].amplitude;
    }
    
    // 使用SpectrumDataProcessor的findMultiplePeaks方法
    return SpectrumDataProcessor.findMultiplePeaks(
      spectrumData,
      fftSize,
      sampleRate,
      peakCount,
      10, // 最小峰值间隔
      -60, // 最小峰值高度
      true // 使用插值
    );
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
  getDecibelSteps(minDb: number, maxDb: number): number[] {
    // 使用SpectrumDataProcessor的静态方法获取标准分贝步进
    const allDbSteps = SpectrumDataProcessor.getDbSteps();
    
    // 过滤出在指定范围内的步进值
    return allDbSteps.filter(db => db >= minDb && db <= maxDb);
  }
  
  /**
   * 获取频率步进
   */
  getFrequencySteps(minFreq: number, maxFreq: number): number[] {
    // 使用SpectrumDataProcessor的静态方法获取标准频率步进
    const allFreqSteps = SpectrumDataProcessor.getFrequencySteps();
    
    // 过滤出在指定范围内的步进值
    return allFreqSteps.filter(freq => freq >= minFreq && freq <= maxFreq);
  }
}