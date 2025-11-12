import { resourceManager } from '@kit.LocalizationKit';

/**
 * 峰值插值方法（内部实现细节）
 */
export enum PeakInterpolationMethod {
  NONE = 'none',           // 不使用插值
  PARABOLIC = 'parabolic', // 抛物线插值
  CENTROID = 'centroid',    // 重心法
  QUADRATIC = 'quadratic',  // 二次拟合插值
  GAUSSIAN = 'gaussian',   // 高斯拟合插值
  INTERPOLATIVE = 'interpolative', // 插值法（改进的抛物线）
  SINC = 'sinc',          // Sinc插值法
  PHASE_VOCODER = 'phase_vocoder', // 相位声码器法
  ADAPTIVE = 'adaptive', // 自适应算法，根据频率范围自动选择
  HYBRID = 'hybrid' // 混合算法，结合多种算法的结果
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
 * 频率索引点接口
 */
export interface FrequencyIndexPoint {
  freq: number;
  index: number;
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
   * 二次拟合插值方法
   * 使用三点二次拟合来提高频率精度，比抛物线插值更稳定
   * @param spectrumData 频谱数据
   * @param peakIndex 峰值索引
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @returns 插值后的频率和幅度
   */
  static quadraticInterpolation(
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
    
    // 使用二次拟合公式
    // δ = (y1 - y3) / (2 * (y1 - 2*y2 + y3))
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
   * 高斯拟合插值方法
   * 使用高斯函数拟合峰值区域，提供更精确的频率估计
   * @param spectrumData 频谱数据
   * @param peakIndex 峰值索引
   * @param windowSize 窗口大小
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @returns 插值后的频率和幅度
   */
  static gaussianInterpolation(
    spectrumData: Float32Array,
    peakIndex: number,
    windowSize: number = 5,
    fftSize: number,
    sampleRate: number
  ): FrequencyAmplitudeResult {
    const start = Math.max(0, peakIndex - windowSize);
    const end = Math.min(spectrumData.length - 1, peakIndex + windowSize);
    
    let sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumX2Y = 0;
    let maxAmplitude = 0;
    let maxIndex = peakIndex;
    
    // 高斯拟合：ln(y) = a*x^2 + b*x + c
    for (let i = start; i <= end; i++) {
      const amplitude = Math.abs(spectrumData[i]);
      if (amplitude > maxAmplitude) {
        maxAmplitude = amplitude;
        maxIndex = i;
      }
      
      const x = i - peakIndex;
      const y = Math.log(Math.max(amplitude, 1e-10)); // 避免log(0)
      
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
      sumX2Y += x * x * y;
    }
    
    const n = end - start + 1;
    const denominator = n * sumX2 - sumX * sumX;
    
    if (Math.abs(denominator) < 1e-10) {
      // 拟合失败，返回离散值
      const result: FrequencyAmplitudeResult = {
        frequency: SpectrumDataProcessor.getIndexFrequency(maxIndex, fftSize, sampleRate),
        amplitude: maxAmplitude
      };
      return result;
    }
    
    // 计算二次拟合系数
    const a = (n * sumX2Y - sumX2 * sumY) / denominator;
    const b = (sumXY * sumX2 - sumX * sumX2Y) / denominator;
    
    // 高斯拟合的峰值位置：x = -b/(2a)
    const peakOffset = -b / (2 * a);
    const preciseIndex = peakIndex + peakOffset;
    
    // 计算峰值幅度
    const amplitude = maxAmplitude * Math.exp(-a * peakOffset * peakOffset);
    
    const result: FrequencyAmplitudeResult = {
      frequency: (preciseIndex * sampleRate) / fftSize,
      amplitude: amplitude
    };
    return result;
  }
  
  /**
   * Sinc插值方法
   * 使用Sinc函数进行频域插值，提供高精度的频率估计
   * @param spectrumData 频谱数据
   * @param peakIndex 峰值索引
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @param interpolationPoints 插值点数
   * @returns 插值后的频率和幅度
   */
  static sincInterpolation(
    spectrumData: Float32Array,
    peakIndex: number,
    fftSize: number,
    sampleRate: number,
    interpolationPoints: number = 10
  ): FrequencyAmplitudeResult {
    // 边界检查
    if (peakIndex <= 0 || peakIndex >= spectrumData.length - 1) {
      const result: FrequencyAmplitudeResult = {
        frequency: SpectrumDataProcessor.getIndexFrequency(peakIndex, fftSize, sampleRate),
        amplitude: Math.abs(spectrumData[peakIndex])
      };
      return result;
    }
    
    let maxAmplitude = 0;
    let bestOffset = 0;
    
    // 在峰值附近进行Sinc插值
    for (let offset = -0.5; offset <= 0.5; offset += 1.0 / interpolationPoints) {
      let interpolatedValue = 0;
      
      // Sinc插值公式
      for (let i = -2; i <= 2; i++) {
        const dataIndex = peakIndex + i;
        if (dataIndex >= 0 && dataIndex < spectrumData.length) {
          const sincArg = Math.PI * (offset - i);
          const sincValue = (Math.abs(sincArg) < 1e-10) ? 1 : Math.sin(sincArg) / sincArg;
          interpolatedValue += Math.abs(spectrumData[dataIndex]) * sincValue;
        }
      }
      
      if (interpolatedValue > maxAmplitude) {
        maxAmplitude = interpolatedValue;
        bestOffset = offset;
      }
    }
    
    const preciseIndex = peakIndex + bestOffset;
    
    const result: FrequencyAmplitudeResult = {
      frequency: (preciseIndex * sampleRate) / fftSize,
      amplitude: maxAmplitude
    };
    return result;
  }
  
  /**
   * 相位声码器法
   * 利用相位信息进行高精度频率估计
   * @param spectrumData 频谱数据
   * @param phaseData 相位数据（如果可用）
   * @param peakIndex 峰值索引
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @returns 插值后的频率和幅度
   */
  static phaseVocoderMethod(
    spectrumData: Float32Array,
    phaseData: Float32Array | null,
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
    
    const amplitude = Math.abs(spectrumData[peakIndex]);
    
    // 如果没有相位数据，使用抛物线插值
    if (!phaseData || peakIndex >= phaseData.length) {
      return SpectrumDataProcessor.parabolicInterpolation(spectrumData, peakIndex, fftSize, sampleRate);
    }
    
    // 使用相位差估计真实频率
    const currentPhase = phaseData[peakIndex];
    const prevPhase = peakIndex > 0 ? phaseData[peakIndex - 1] : currentPhase;
    
    // 计算相位差
    let phaseDiff = currentPhase - prevPhase;
    
    // 相位解缠绕
    while (phaseDiff > Math.PI) phaseDiff -= 2 * Math.PI;
    while (phaseDiff < -Math.PI) phaseDiff += 2 * Math.PI;
    
    // 估计频率偏移
    const freqOffset = phaseDiff / (2 * Math.PI);
    const preciseIndex = peakIndex + freqOffset;
    
    const result: FrequencyAmplitudeResult = {
      frequency: (preciseIndex * sampleRate) / fftSize,
      amplitude: amplitude
    };
    return result;
  }
  
  /**
   * 改进的抛物线插值法
   * 结合多种技术的混合方法，提供更稳定的峰值估计
   * @param spectrumData 频谱数据
   * @param peakIndex 峰值索引
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @returns 插值后的频率和幅度
   */
  static interpolativeMethod(
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
    
    // 获取三个点的幅度
    const y1 = Math.abs(spectrumData[peakIndex - 1]);
    const y2 = Math.abs(spectrumData[peakIndex]);
    const y3 = Math.abs(spectrumData[peakIndex + 1]);
    
    // 使用改进的插值公式
    // 首先尝试标准抛物线插值
    const denominator = 2 * (y1 - 2 * y2 + y3);
    if (Math.abs(denominator) < 1e-10) {
      // 避免除零，返回离散值
      const result: FrequencyAmplitudeResult = {
        frequency: SpectrumDataProcessor.getIndexFrequency(peakIndex, fftSize, sampleRate),
        amplitude: y2
      };
      return result;
    }
    
    // 计算偏移量
    let delta = (y1 - y3) / denominator;
    
    // 限制偏移量在合理范围内
    delta = Math.max(-0.5, Math.min(0.5, delta));
    
    // 使用加权平均来提高稳定性
    const weight = 0.7; // 抛物线插值的权重
    const preciseIndex = peakIndex + delta * weight;
    
    // 计算精确峰值幅度
    const amplitude = y2 - 0.25 * (y1 - y3) * delta * weight;
    
    const result: FrequencyAmplitudeResult = {
      frequency: (preciseIndex * sampleRate) / fftSize,
      amplitude: amplitude
    };
    return result;
  }
  
  /**
   * 自适应峰值检测方法
   * 根据频率范围自动选择最适合的峰值检测算法
   * @param spectrumData 频谱数据
   * @param peakIndex 峰值索引
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @param minFreq 最小频率
   * @param maxFreq 最大频率
   * @returns 插值后的频率和幅度
   */
  static adaptivePeakDetection(
    spectrumData: Float32Array,
    peakIndex: number,
    fftSize: number,
    sampleRate: number,
    minFreq: number,
    maxFreq: number
  ): FrequencyAmplitudeResult {
    // 边界检查
    if (peakIndex <= 0 || peakIndex >= spectrumData.length - 1) {
      const result: FrequencyAmplitudeResult = {
        frequency: SpectrumDataProcessor.getIndexFrequency(peakIndex, fftSize, sampleRate),
        amplitude: Math.abs(spectrumData[peakIndex])
      };
      return result;
    }
    
    // 根据频率范围选择最适合的算法
    const freqRange = maxFreq - minFreq;
    const centerFreq = (minFreq + maxFreq) / 2;
    
    // 低频段 (16-250Hz): 使用重心法，因为低频信号通常较宽，重心法更稳定
    if (centerFreq <= 250) {
      console.info(`[自适应峰值检测] 低频段(${centerFreq.toFixed(1)}Hz)，使用重心法`);
      return SpectrumDataProcessor.centroidMethod(spectrumData, peakIndex, 5, fftSize, sampleRate);
    }
    
    // 中频段 (250-2000Hz): 使用改进的抛物线插值，平衡精度和稳定性
    if (centerFreq <= 2000) {
      console.info(`[自适应峰值检测] 中频段(${centerFreq.toFixed(1)}Hz)，使用改进的抛物线插值`);
      return SpectrumDataProcessor.interpolativeMethod(spectrumData, peakIndex, fftSize, sampleRate);
    }
    
    // 高频段 (2000-8000Hz): 使用二次拟合插值，高频信号需要更高精度
    if (centerFreq <= 8000) {
      console.info(`[自适应峰值检测] 高频段(${centerFreq.toFixed(1)}Hz)，使用二次拟合插值`);
      return SpectrumDataProcessor.quadraticInterpolation(spectrumData, peakIndex, fftSize, sampleRate);
    }
    
    // 甚高频段 (8000-20000Hz): 使用Sinc插值，甚高频需要最高精度
    console.info(`[自适应峰值检测] 甚高频段(${centerFreq.toFixed(1)}Hz)，使用Sinc插值`);
    return SpectrumDataProcessor.sincInterpolation(spectrumData, peakIndex, fftSize, sampleRate, 15);
  }
  
  /**
   * 混合峰值检测方法
   * 结合多种算法的结果，提供最可靠的峰值估计
   * @param spectrumData 频谱数据
   * @param peakIndex 峰值索引
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @param minFreq 最小频率
   * @param maxFreq 最大频率
   * @returns 插值后的频率和幅度
   */
  static hybridPeakDetection(
    spectrumData: Float32Array,
    peakIndex: number,
    fftSize: number,
    sampleRate: number,
    minFreq: number,
    maxFreq: number
  ): FrequencyAmplitudeResult {
    // 边界检查
    if (peakIndex <= 0 || peakIndex >= spectrumData.length - 1) {
      const result: FrequencyAmplitudeResult = {
        frequency: SpectrumDataProcessor.getIndexFrequency(peakIndex, fftSize, sampleRate),
        amplitude: Math.abs(spectrumData[peakIndex])
      };
      return result;
    }
    
    // 获取多种算法的结果
    const parabolicResult = SpectrumDataProcessor.parabolicInterpolation(spectrumData, peakIndex, fftSize, sampleRate);
    const quadraticResult = SpectrumDataProcessor.quadraticInterpolation(spectrumData, peakIndex, fftSize, sampleRate);
    const interpolativeResult = SpectrumDataProcessor.interpolativeMethod(spectrumData, peakIndex, fftSize, sampleRate);
    
    // 计算频率一致性
    const freqDiff1 = Math.abs(parabolicResult.frequency - quadraticResult.frequency);
    const freqDiff2 = Math.abs(parabolicResult.frequency - interpolativeResult.frequency);
    const freqDiff3 = Math.abs(quadraticResult.frequency - interpolativeResult.frequency);
    
    // 如果三种算法结果很接近，使用加权平均
    if (freqDiff1 < 1.0 && freqDiff2 < 1.0 && freqDiff3 < 1.0) {
      console.info(`[混合峰值检测] 算法结果一致，使用加权平均`);
      const avgFrequency = (parabolicResult.frequency + quadraticResult.frequency + interpolativeResult.frequency) / 3;
      const avgAmplitude = (parabolicResult.amplitude + quadraticResult.amplitude + interpolativeResult.amplitude) / 3;
      
      return {
        frequency: avgFrequency,
        amplitude: avgAmplitude
      };
    }
    
    // 否则使用最稳定的结果（改进的抛物线插值）
    console.info(`[混合峰值检测] 算法结果不一致，使用最稳定的改进抛物线插值`);
    return interpolativeResult;
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
        case PeakInterpolationMethod.QUADRATIC:
          interpolated = SpectrumDataProcessor.quadraticInterpolation(
            spectrumData, maxIndexInRange, fftSize, sampleRate
          );
          break;
        case PeakInterpolationMethod.GAUSSIAN:
          interpolated = SpectrumDataProcessor.gaussianInterpolation(
            spectrumData, maxIndexInRange, 5, fftSize, sampleRate
          );
          break;
        case PeakInterpolationMethod.SINC:
          interpolated = SpectrumDataProcessor.sincInterpolation(
            spectrumData, maxIndexInRange, fftSize, sampleRate, 10
          );
          break;
        case PeakInterpolationMethod.PHASE_VOCODER:
          interpolated = SpectrumDataProcessor.phaseVocoderMethod(
            spectrumData, null, maxIndexInRange, fftSize, sampleRate
          );
          break;
        case PeakInterpolationMethod.INTERPOLATIVE:
          interpolated = SpectrumDataProcessor.interpolativeMethod(
            spectrumData, maxIndexInRange, fftSize, sampleRate
          );
          break;
        case PeakInterpolationMethod.ADAPTIVE:
          interpolated = SpectrumDataProcessor.adaptivePeakDetection(
            spectrumData, maxIndexInRange, fftSize, sampleRate, actualMinFreq, actualMaxFreq
          );
          break;
        case PeakInterpolationMethod.HYBRID:
          interpolated = SpectrumDataProcessor.hybridPeakDetection(
            spectrumData, maxIndexInRange, fftSize, sampleRate, actualMinFreq, actualMaxFreq
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
  
  /**
   * 生成增强的频谱数据（包含低频插值点）
   * 解决不同FFT大小导致的低频数据缺失问题，提供更密集的低频数据点
   * @param spectrumData 原始频谱数据
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @param minFreq 最小频率
   * @param maxFreq 最大频率
   * @returns 增强后的频谱数据点数组
   */
  static generateEnhancedSpectrumData(
    spectrumData: Float32Array,
    fftSize: number,
    sampleRate: number,
    minFreq: number = SpectrumDataProcessor.MIN_FREQUENCY,
    maxFreq: number = SpectrumDataProcessor.MAX_FREQUENCY
  ): SpectrumDataPoint[] {
    const dataPoints: SpectrumDataPoint[] = [];
    const freqResolution = sampleRate / fftSize;
    
    // 1. 添加原始FFT数据点
    for (let i = 0; i < fftSize / 2; i++) {
      const frequency = SpectrumDataProcessor.getIndexFrequency(i, fftSize, sampleRate);
      if (frequency < minFreq || frequency > maxFreq) {
        continue;
      }
      
      if (i < spectrumData.length) {
        const dbValue = spectrumData[i];
        dataPoints.push({
          frequency,
          amplitude: Math.pow(10, dbValue / 20), // 将分贝转换回幅度
          dbValue,
          index: i
        });
      }
    }
    
    // 2. 根据FFT大小添加低频插值点
    const lowFreqPoints = SpectrumDataProcessor.generateLowFrequencyInterpolationPoints(fftSize, sampleRate);
    
    for (const point of lowFreqPoints) {
      if (point.index < spectrumData.length && point.index > 0) {
        const dbValue = spectrumData[point.index];
        dataPoints.push({
          frequency: point.freq,
          amplitude: Math.pow(10, dbValue / 20), // 将分贝转换回幅度
          dbValue,
          index: point.index
        });
      }
    }
    
    // 3. 为低频区域添加额外的插值点，确保显示密集
    // 特别是在频率分辨率较粗的情况下
    if (freqResolution > 20) { // 如果频率分辨率大于20Hz，添加额外插值点
      const additionalPoints = SpectrumDataProcessor.generateAdditionalLowFrequencyPoints(
        spectrumData, fftSize, sampleRate, minFreq, maxFreq
      );
      dataPoints.push(...additionalPoints);
    }
    
    // 4. 按频率排序并去重
    dataPoints.sort((a, b) => a.frequency - b.frequency);
    const uniqueDataPoints: SpectrumDataPoint[] = [];
    const seenFrequencies = new Set<number>();
    
    for (const point of dataPoints) {
      if (!seenFrequencies.has(Math.round(point.frequency * 10) / 10)) { // 保留1位小数精度
        seenFrequencies.add(Math.round(point.frequency * 10) / 10);
        uniqueDataPoints.push(point);
      }
    }
    
    console.info(`[频谱处理] FFT大小=${fftSize}, 频率分辨率=${freqResolution.toFixed(1)}Hz, ` +
      `原始数据点=${fftSize / 2}, 插值点=${lowFreqPoints.length}, 最终数据点=${uniqueDataPoints.length}`);
    
    return uniqueDataPoints;
  }
  
  /**
   * 为低频区域生成额外的插值点
   * 确保在频率分辨率较粗的情况下，低频区域仍有足够密集的数据点
   * @param spectrumData 原始频谱数据
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @param minFreq 最小频率
   * @param maxFreq 最大频率
   * @returns 额外的低频插值点数组
   */
  private static generateAdditionalLowFrequencyPoints(
    spectrumData: Float32Array,
    fftSize: number,
    sampleRate: number,
    minFreq: number,
    maxFreq: number
  ): SpectrumDataPoint[] {
    const additionalPoints: SpectrumDataPoint[] = [];
    const freqResolution = sampleRate / fftSize;
    
    // 在16-250Hz范围内生成更密集的频率点
    // 使用对数间隔，符合人耳听觉特性
    const startFreq = Math.max(minFreq, 16);
    const endFreq = Math.min(maxFreq, 250);
    
    // 生成约50个低频点，确保显示密集
    const numPoints = 50;
    const logStart = Math.log10(startFreq);
    const logEnd = Math.log10(endFreq);
    
    for (let i = 0; i < numPoints; i++) {
      const logFreq = logStart + (logEnd - logStart) * (i / (numPoints - 1));
      const frequency = Math.pow(10, logFreq);
      
      // 计算对应的FFT索引
      const index = Math.round(frequency / freqResolution);
      
      if (index >= 0 && index < spectrumData.length && index < fftSize / 2) {
        // 使用线性插值计算分贝值
        const dbValue = SpectrumDataProcessor.interpolateDbValue(
          spectrumData, frequency, index, freqResolution
        );
        
        additionalPoints.push({
          frequency,
          amplitude: Math.pow(10, dbValue / 20),
          dbValue,
          index
        });
      }
    }
    
    console.info(`[频谱处理] 生成了${additionalPoints.length}个额外低频插值点，频率分辨率=${freqResolution.toFixed(1)}Hz`);
    return additionalPoints;
  }
  
  /**
   * 线性插值计算分贝值
   * @param spectrumData 频谱数据
   * @param targetFrequency 目标频率
   * @param nearestIndex 最近FFT索引
   * @param freqResolution 频率分辨率
   * @returns 插值后的分贝值
   */
  private static interpolateDbValue(
    spectrumData: Float32Array,
    targetFrequency: number,
    nearestIndex: number,
    freqResolution: number
  ): number {
    // 如果正好在FFT点上，直接返回
    if (Math.abs(targetFrequency - nearestIndex * freqResolution) < 0.1) {
      return spectrumData[nearestIndex];
    }
    
    // 计算插值位置
    const position = targetFrequency / freqResolution;
    const lowerIndex = Math.floor(position);
    const upperIndex = Math.ceil(position);
    
    // 确保索引在有效范围内
    if (lowerIndex < 0 || upperIndex >= spectrumData.length) {
      return spectrumData[Math.max(0, Math.min(nearestIndex, spectrumData.length - 1))];
    }
    
    // 线性插值
    const fraction = position - lowerIndex;
    const lowerValue = spectrumData[lowerIndex];
    const upperValue = spectrumData[upperIndex];
    
    return lowerValue + fraction * (upperValue - lowerValue);
  }
  
  /**
   * 生成低频插值点
   * 根据FFT大小动态调整插值策略，提供更密集的低频数据点
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @returns 低频插值点数组
   */
  private static generateLowFrequencyInterpolationPoints(
    fftSize: number,
    sampleRate: number
  ): FrequencyIndexPoint[] {
    const freqResolution = sampleRate / fftSize;
    let points: FrequencyIndexPoint[] = [];
    
    // 根据FFT大小和频率分辨率计算低频插值密度
    // 确保低频区域有足够密集的数据点，符合专业音频分析标准
    if (fftSize <= 1024) {
      // 脉冲模式：频率分辨率约43Hz，需要密集插值点
      // 在16-250Hz范围内提供更多数据点，确保低频显示密集
      const lowFreqPoints = [16, 20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250];
      points = lowFreqPoints.map(freq => {
        const point: FrequencyIndexPoint = {
          freq: freq,
          index: Math.round(freq / freqResolution)
        };
        return point;
      });
    } else if (fftSize <= 2048) {
      // 快速模式：频率分辨率约21.5Hz，中等密度插值点
      // 在16-250Hz范围内提供适量数据点
      const lowFreqPoints = [16, 20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250];
      points = lowFreqPoints.map(freq => {
        const point: FrequencyIndexPoint = {
          freq: freq,
          index: Math.round(freq / freqResolution)
        };
        return point;
      });
    } else {
      // 慢速模式：频率分辨率约10.8Hz，相对较少但仍需保证关键点
      // 在16-250Hz范围内提供关键频率点
      const lowFreqPoints = [16, 20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250];
      points = lowFreqPoints.map(freq => {
        const point: FrequencyIndexPoint = {
          freq: freq,
          index: Math.round(freq / freqResolution)
        };
        return point;
      });
    }
    
    // 过滤掉超出FFT范围的点
    const maxIndex = fftSize / 2;
    points = points.filter(point => point.index >= 0 && point.index < maxIndex);
    
    console.info(`[频谱处理] 生成${points.length}个低频插值点，频率分辨率=${freqResolution.toFixed(1)}Hz`);
    return points;
  }
}