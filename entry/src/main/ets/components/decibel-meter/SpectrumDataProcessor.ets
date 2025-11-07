import { resourceManager } from '@kit.LocalizationKit';

/**
 * 频谱数据点类型
 */
export interface SpectrumDataPoint {
  frequency: number;  // 频率 (Hz)
  amplitude: number;   // 幅值
  dbValue: number;    // 分贝值
  index: number;      // 在原始数组中的索引
}

/**
 * 峰值信息类型
 */
export interface PeakInfo {
  frequency: number;  // 峰值频率 (Hz)
  dbValue: number;    // 峰值分贝值
  index: number;      // 峰值在数组中的索引
  amplitude: number;  // 峰值幅值
}

/**
 * 频谱数据处理器
 * 提供统一的频谱数据处理方法，供折线图和柱状图共同使用
 */
export class SpectrumDataProcessor {
  // 标准频率步进点
  private static readonly FREQUENCY_STEPS = [16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
  
  // 标准分贝步进点
  private static readonly DB_STEPS = [-20, 0, 20, 40, 60, 80, 100, 120, 140];
  
  // 有效频率范围 (人耳听觉范围)
  private static readonly MIN_FREQUENCY = 16;    // 16Hz
  private static readonly MAX_FREQUENCY = 20000; // 20kHz
  
  // 对数坐标常量
  private static readonly LOG_MIN_FREQ = Math.log10(SpectrumDataProcessor.MIN_FREQUENCY);
  
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
   * 获取频率对应的索引
   */
  static getFrequencyIndex(frequency: number, fftSize: number, sampleRate: number): number {
    // 确保频率在有效范围内
    const validFreq = Math.max(0, Math.min(frequency, sampleRate / 2));
    return Math.round(validFreq * fftSize / sampleRate);
  }
  
  /**
   * 获取索引对应的频率
   */
  static getIndexFrequency(index: number, fftSize: number, sampleRate: number): number {
    // 确保索引在有效范围内
    const validIndex = Math.max(0, Math.min(index, fftSize / 2));
    return validIndex * sampleRate / fftSize;
  }
  
  /**
   * 计算分贝值
   * @param amplitude 幅值
   * @param fftSize FFT大小
   * @param referenceValue 参考值，默认为1.0
   */
  static calculateDbValue(amplitude: number, fftSize: number, referenceValue: number = 1.0): number {
    // FFT大小补偿
    const fftCorrection = 20 * Math.log10(fftSize / 2);

    // 确保最小值避免log(0)
    const safeAmplitude = Math.max(amplitude, referenceValue * 0.00001);

    return 20 * Math.log10(safeAmplitude / referenceValue) + fftCorrection;
  }
  
  /**
   * 获取分贝值（直接使用，因为FFT分析器已输出分贝值）
   * @param dbValue 已有的分贝值
   */
  static getDbValue(dbValue: number): number {
    return dbValue;
  }

  /**
   * 查找峰值频率
   * @param spectrumData 频谱数据
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @param minFreq 最小频率限制
   * @param maxFreq 最大频率限制
   */
  static findPeakFrequency(
    spectrumData: Float32Array, 
    fftSize: number, 
    sampleRate: number,
    minFreq: number = SpectrumDataProcessor.MIN_FREQUENCY,
    maxFreq: number = SpectrumDataProcessor.MAX_FREQUENCY
  ): PeakInfo | null {
    if (spectrumData.length === 0) {
      return null;
    }
    
    // 限制频率范围
    const actualMinFreq = Math.max(minFreq, SpectrumDataProcessor.MIN_FREQUENCY);
    const actualMaxFreq = Math.min(maxFreq, Math.min(sampleRate / 2, SpectrumDataProcessor.MAX_FREQUENCY));
    
    const minIndex = SpectrumDataProcessor.getFrequencyIndex(actualMinFreq, fftSize, sampleRate);
    const maxIndex = SpectrumDataProcessor.getFrequencyIndex(actualMaxFreq, fftSize, sampleRate);
    
    let maxIndexInRange = minIndex;
    let maxValueInRange = Math.abs(spectrumData[minIndex]);
    
    // 在有效频率范围内查找峰值
    for (let i = minIndex + 1; i <= maxIndex && i < spectrumData.length; i++) {
      const absValue = Math.abs(spectrumData[i]);
      if (absValue > maxValueInRange) {
        maxValueInRange = absValue;
        maxIndexInRange = i;
      }
    }
    
    const peakFrequency = SpectrumDataProcessor.getIndexFrequency(maxIndexInRange, fftSize, sampleRate);
    const peakDbValue = SpectrumDataProcessor.calculateDbValue(maxValueInRange, fftSize);
    
    return {
      frequency: peakFrequency,
      dbValue: peakDbValue,
      index: maxIndexInRange,
      amplitude: maxValueInRange
    };
  }
  
  /**
   * 生成对数分布的频率索引
   * 用于柱状图显示，更好地匹配人耳听觉特性
   */
  static generateLogarithmicIndices(count: number, fftSize: number): number[] {
    const indices: number[] = [];
    const maxIndex = fftSize / 2;
    
    for (let i = 0; i < count; i++) {
      // 使用对数分布
      const logRatio = i / (count - 1);
      const index = Math.round(Math.pow(10, logRatio * Math.log10(maxIndex)));
      indices.push(Math.min(index, maxIndex));
    }
    
    return indices;
  }
  
  /**
   * 生成线性分布的频率索引
   * 用于折线图显示
   */
  static generateLinearIndices(count: number, fftSize: number): number[] {
    const indices: number[] = [];
    const maxIndex = fftSize / 2;
    const step = maxIndex / count;
    
    for (let i = 0; i < count; i++) {
      indices.push(Math.round(i * step));
    }
    
    return indices;
  }
  
  /**
   * 处理频谱数据，转换为标准数据点数组
   * @param spectrumData 原始频谱数据
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @param indices 要处理的索引数组
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
        const dbValue = SpectrumDataProcessor.calculateDbValue(amplitude, fftSize);
        
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
    
    const smoothedData = new Float32Array(currentData.length);
    
    for (let i = 0; i < currentData.length; i++) {
      smoothedData[i] = 
        smoothingFactor * currentData[i] + 
        (1 - smoothingFactor) * previousData[i];
    }
    
    return smoothedData;
  }
  
  /**
   * 计算自适应平滑因子
   * 根据信号强度动态调整平滑因子
   */
  static calculateAdaptiveSmoothingFactor(signalStrength: number): number {
    // 强信号使用较少平滑，弱信号使用较多平滑
    if (signalStrength > 0.1) {
      return 0.4; // 较少平滑
    } else if (signalStrength > 0.01) {
      return 0.3; // 中等平滑
    } else {
      return 0.2; // 较多平滑
    }
  }
  
  /**
   * 计算平均信号强度
   */
  static calculateAverageSignalStrength(spectrumData: Float32Array): number {
    if (spectrumData.length === 0) {
      return 0;
    }
    
    let sum = 0;
    for (let i = 0; i < spectrumData.length; i++) {
      sum += Math.abs(spectrumData[i]);
    }
    return sum / spectrumData.length;
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
        return false; // 不是局部最大值
      }
    }
    
    return true;
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
      return '#FF00FF00';    // 绿色 - 安全
    } else if (dbValue < 70) {
      return '#FFFFFF00';   // 黄色 - 注意
    } else if (dbValue < 85) {
      return '#FFFF8800';   // 橙色 - 警告
    } else {
      return '#FFFF0000';   // 红色 - 危险
    }
  }
}