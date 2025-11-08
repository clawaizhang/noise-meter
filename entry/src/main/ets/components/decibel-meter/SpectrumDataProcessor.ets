import { resourceManager } from '@kit.LocalizationKit';

/**
 * 峰值插值方法（内部实现细节）
 */
export enum PeakInterpolationMethod {
  NONE = 'none',           // 不使用插值
  PARABOLIC = 'parabolic', // 抛物线插值
  CENTROID = 'centroid'    // 重心法
}

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
 * 频率和幅度结果接口
 */
export interface FrequencyAmplitudeResult {
  frequency: number;
  amplitude: number;
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
  public static readonly MIN_FREQUENCY = 16;    // 16Hz
  public static readonly MAX_FREQUENCY = 20000; // 20kHz
  
  // 对数坐标常量
  private static readonly LOG_MIN_FREQ = Math.log10(SpectrumDataProcessor.MIN_FREQUENCY);
  
  /**
   * 抛物线插值方法
   * 通过在峰值点及其邻近两点拟合抛物线来提高频率精度
   * @param spectrumData 频谱数据
   * @param peakIndex 峰值索引
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @returns 插值后的频率和幅度
   */
  static parabolicInterpolation(
    spectrumData: Float32Array,
    peakIndex: number,
    fftSize: number,
    sampleRate: number
  ): FrequencyAmplitudeResult {
    // 边界检查
    if (peakIndex <= 0 || peakIndex >= spectrumData.length - 1) {
      const result: FrequencyAmplitudeResult = {
        frequency: SpectrumDataProcessor.getIndexFrequency(peakIndex, fftSize, sampleRate),
        amplitude: Math.abs(spectrumData[peakIndex])
      };
      return result;
    }
    
    const y1 = Math.abs(spectrumData[peakIndex - 1]);
    const y2 = Math.abs(spectrumData[peakIndex]);
    const y3 = Math.abs(spectrumData[peakIndex + 1]);
    
    // 计算偏移量：δ = (y1 - y3) / (2 * (y1 - 2*y2 + y3))
    const denominator = 2 * (y1 - 2 * y2 + y3);
    if (Math.abs(denominator) < 1e-10) {
      // 避免除零，返回离散值
      const result: FrequencyAmplitudeResult = {
        frequency: SpectrumDataProcessor.getIndexFrequency(peakIndex, fftSize, sampleRate),
        amplitude: y2
      };
      return result;
    }
    
    const delta = (y1 - y3) / denominator;
    const preciseIndex = peakIndex + delta;
    
    // 计算精确峰值幅度
    const amplitude = y2 - 0.25 * (y1 - y3) * delta;
    
    const result: FrequencyAmplitudeResult = {
      frequency: (preciseIndex * sampleRate) / fftSize,
      amplitude: amplitude
    };
    return result;
  }

  /**
   * 重心法
   * 通过计算峰值周围区域的加权中心来确定精确峰值位置
   * @param spectrumData 频谱数据
   * @param peakIndex 峰值索引
   * @param windowSize 窗口大小
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @returns 重心法计算后的频率和幅度
   */
  static centroidMethod(
    spectrumData: Float32Array,
    peakIndex: number,
    windowSize: number = 3,
    fftSize: number,
    sampleRate: number
  ): FrequencyAmplitudeResult {
    const start = Math.max(0, peakIndex - windowSize);
    const end = Math.min(spectrumData.length - 1, peakIndex + windowSize);
    
    let weightedSum = 0;
    let magnitudeSum = 0;
    let maxMagnitude = 0;
    
    for (let i = start; i <= end; i++) {
      const magnitude = Math.abs(spectrumData[i]);
      weightedSum += i * magnitude;
      magnitudeSum += magnitude;
      if (magnitude > maxMagnitude) {
        maxMagnitude = magnitude;
      }
    }
    
    const centroidIndex = weightedSum / magnitudeSum;
    
    const result: FrequencyAmplitudeResult = {
      frequency: (centroidIndex * sampleRate) / fftSize,
      amplitude: maxMagnitude
    };
    return result;
  }

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
   * @param useInterpolation 是否使用插值
   * @param interpolationMethod 插值方法
   */
  static findPeakFrequency(
    spectrumData: Float32Array,
    fftSize: number,
    sampleRate: number,
    minFreq: number = SpectrumDataProcessor.MIN_FREQUENCY,
    maxFreq: number = SpectrumDataProcessor.MAX_FREQUENCY,
    useInterpolation: boolean = true,
    interpolationMethod: PeakInterpolationMethod = PeakInterpolationMethod.PARABOLIC
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
    
    // 使用插值提高精度
    if (useInterpolation && maxIndexInRange > 0 && maxIndexInRange < spectrumData.length - 1) {
      let interpolated: FrequencyAmplitudeResult;
      
      switch (interpolationMethod) {
        case PeakInterpolationMethod.PARABOLIC:
          interpolated = SpectrumDataProcessor.parabolicInterpolation(
            spectrumData, maxIndexInRange, fftSize, sampleRate
          );
          break;
        case PeakInterpolationMethod.CENTROID:
          interpolated = SpectrumDataProcessor.centroidMethod(
            spectrumData, maxIndexInRange, 3, fftSize, sampleRate
          );
          break;
        default:
          // 不使用插值
          interpolated = {
            frequency: SpectrumDataProcessor.getIndexFrequency(maxIndexInRange, fftSize, sampleRate),
            amplitude: maxValueInRange
          } as FrequencyAmplitudeResult;
      }
      
      return {
        frequency: interpolated.frequency,
        dbValue: SpectrumDataProcessor.calculateDbValue(interpolated.amplitude, fftSize),
        index: maxIndexInRange,
        amplitude: interpolated.amplitude
      };
    } else {
      // 不使用插值或边界情况
      const peakFrequency = SpectrumDataProcessor.getIndexFrequency(maxIndexInRange, fftSize, sampleRate);
      const peakDbValue = SpectrumDataProcessor.calculateDbValue(maxValueInRange, fftSize);
      
      return {
        frequency: peakFrequency,
        dbValue: peakDbValue,
        index: maxIndexInRange,
        amplitude: maxValueInRange
      };
    }
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
  
  /**
   * 查找多个峰值频率
   * @param spectrumData 频谱数据
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @param peakCount 最大峰值数量
   * @param minPeakDistance 最小峰值间隔
   * @param minPeakHeight 最小峰值高度(dB)
   * @param useInterpolation 是否使用插值
   * @param interpolationMethod 插值方法
   * @returns 峰值信息数组，按幅度降序排列
   */
  static findMultiplePeaks(
    spectrumData: Float32Array,
    fftSize: number,
    sampleRate: number,
    peakCount: number = 3,
    minPeakDistance: number = 10,
    minPeakHeight: number = -60,
    useInterpolation: boolean = true,
    interpolationMethod: PeakInterpolationMethod = PeakInterpolationMethod.PARABOLIC
  ): PeakInfo[] {
    if (spectrumData.length === 0) {
      return [];
    }
    
    const peaks: PeakInfo[] = [];
    const processed = new Set<number>();
    
    // 寻找多个局部最大值
    for (let i = 1; i < spectrumData.length - 1; i++) {
      if (processed.has(i)) continue;
      
      const currentValue = Math.abs(spectrumData[i]);
      const currentValueDb = SpectrumDataProcessor.calculateDbValue(currentValue, fftSize);
      
      // 检查是否为局部最大值且满足最小高度要求
      if (currentValueDb >= minPeakHeight &&
          currentValue >= Math.abs(spectrumData[i - 1]) &&
          currentValue >= Math.abs(spectrumData[i + 1])) {
        
        let interpolated: FrequencyAmplitudeResult;
        
        // 使用插值提高精度
        if (useInterpolation) {
          switch (interpolationMethod) {
            case PeakInterpolationMethod.PARABOLIC:
              interpolated = SpectrumDataProcessor.parabolicInterpolation(
                spectrumData, i, fftSize, sampleRate
              );
              break;
            case PeakInterpolationMethod.CENTROID:
              interpolated = SpectrumDataProcessor.centroidMethod(
                spectrumData, i, 3, fftSize, sampleRate
              );
              break;
            default:
              interpolated = {
                frequency: SpectrumDataProcessor.getIndexFrequency(i, fftSize, sampleRate),
                amplitude: currentValue
              };
          }
        } else {
          interpolated = {
            frequency: SpectrumDataProcessor.getIndexFrequency(i, fftSize, sampleRate),
            amplitude: currentValue
          };
        }
        
        const peakInfo: PeakInfo = {
          frequency: interpolated.frequency,
          dbValue: SpectrumDataProcessor.calculateDbValue(interpolated.amplitude, fftSize),
          index: i,
          amplitude: interpolated.amplitude
        };
        
        peaks.push(peakInfo);
        
        // 标记已处理的区域避免重复检测
        for (let j = Math.max(0, i - minPeakDistance); j <= Math.min(spectrumData.length - 1, i + minPeakDistance); j++) {
          processed.add(j);
        }
      }
    }
    
    // 按幅度排序并返回前N个峰值
    peaks.sort((a, b) => b.dbValue - a.dbValue);
    return peaks.slice(0, peakCount);
  }
}