import { WeightingType } from '../constants/WeightingConstants';
import { FFTAnalyzer } from './FFTAnalyzer';

/**
 * 频率计权工具类
 */
export class FrequencyWeighting {
  // FFT分析器实例
  private static readonly fftAnalyzer: FFTAnalyzer = new FFTAnalyzer(2048);
  
  // 标准频率点(Hz)
  private static readonly STANDARD_FREQUENCIES: number[] = [
    10, 12.5, 16, 20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400,
    500, 630, 800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000,
    12500, 16000, 20000
  ];

  // A计权修正值(dB)
  private static readonly A_WEIGHTING: number[] = [
    -70.4, -63.4, -56.7, -50.5, -44.7, -39.4, -34.6, -30.2, -26.2, -22.5, -19.1,
    -16.1, -13.4, -10.9, -8.6, -6.6, -4.8, -3.2, -1.9, -0.8, 0.0, 0.6, 1.0, 1.2,
    1.3, 1.2, 1.0, 0.5, -0.1, -1.1, -2.5, -4.3, -6.6, -9.3
  ];

  // C计权修正值(dB)
  private static readonly C_WEIGHTING: number[] = [
    -14.3, -11.2, -8.5, -6.2, -4.4, -3.0, -2.0, -1.3, -0.8, -0.5, -0.3, -0.2,
    -0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, -0.1, -0.2, -0.3, -0.5,
    -0.8, -1.3, -2.0, -3.0, -4.4, -6.2, -8.5, -11.2
  ];

  // 16位音频的最大值
  private static readonly REF_VALUE: number = 32767.0;

  /**
   * 对音频数据进行计权计算
   * @param buffer 音频数据
   * @param bytesRead 读取的字节数
   * @param weightingType 计权类型
   * @returns 计权后的分贝值
   */
  public static calculateWeightedDecibel(buffer: ArrayBuffer, bytesRead: number, weightingType: WeightingType): number {
    // Z计权使用简单的RMS计算
    if (weightingType === WeightingType.Z) {
      return FrequencyWeighting.calculateZWeightedDecibel(buffer, bytesRead);
    }

    // 执行FFT分析
    const spectrum = FrequencyWeighting.fftAnalyzer.transform(buffer);
    
    // 计算加权和
    let weightedSum = 0;
    const sampleRate = 44100; // 采样率
    
    // 对每个标准频率点应用计权
    for (let i = 0; i < FrequencyWeighting.STANDARD_FREQUENCIES.length; i++) {
      const frequency = FrequencyWeighting.STANDARD_FREQUENCIES[i];
      const amplitude = FrequencyWeighting.fftAnalyzer.getAmplitudeAtFrequency(spectrum, frequency, sampleRate);
      
      // 根据计权类型选择修正值
      const correction = weightingType === WeightingType.A ? 
        FrequencyWeighting.A_WEIGHTING[i] : FrequencyWeighting.C_WEIGHTING[i];
      
      // 应用修正值并累加
      const weightedAmplitude = amplitude * Math.pow(10, correction / 20);
      weightedSum += weightedAmplitude * weightedAmplitude;
    }
    
    // 计算最终的分贝值
    const weightedRMS = Math.sqrt(weightedSum / FrequencyWeighting.STANDARD_FREQUENCIES.length);
    return 20 * Math.log10(Math.max(weightedRMS, 1e-6)) + 90;
  }

  /**
   * 计算Z计权(零频率计权)分贝值
   * @param buffer 音频数据
   * @param bytesRead 读取的字节数
   * @returns 分贝值
   */
  private static calculateZWeightedDecibel(buffer: ArrayBuffer, bytesRead: number): number {
    const int16Array = new Int16Array(buffer, 0, bytesRead / 2);
    let sum = 0;
    let maxAbs = 0;
    
    // 计算均方根值和最大绝对值
    for (let i = 0; i < int16Array.length; i++) {
      const value = Math.abs(int16Array[i]);
      sum += value * value;
      maxAbs = Math.max(maxAbs, value);
    }

    // 使用均方根值和最大值的组合
    const rms = Math.sqrt(sum / int16Array.length);
    const combined = Math.max(rms, maxAbs * 0.8);  // 增加峰值的权重
    
    // 计算分贝值
    return 20 * Math.log10(Math.max(combined, 1) / FrequencyWeighting.REF_VALUE) + 90;
  }
  
  /**
   * 获取频谱数据用于显示
   * @param buffer 音频数据
   * @returns 频谱数据
   */
  public static getSpectrumData(buffer: ArrayBuffer): Float32Array {
    return FrequencyWeighting.fftAnalyzer.transform(buffer);
  }
  
  /**
   * 获取特定频段的能量
   * @param buffer 音频数据
   * @param startFreq 起始频率
   * @param endFreq 结束频率
   * @returns 频段能量
   */
  public static getBandEnergy(buffer: ArrayBuffer, startFreq: number, endFreq: number): number {
    const spectrum = FrequencyWeighting.fftAnalyzer.transform(buffer);
    return FrequencyWeighting.fftAnalyzer.getFrequencyRangeEnergy(spectrum, startFreq, endFreq, 44100);
  }
} 