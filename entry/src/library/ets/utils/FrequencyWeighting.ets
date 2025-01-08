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
  // 最小有效值
  private static readonly MIN_VALUE: number = 1e-6;
  // SPL参考值修正
  private static readonly SPL_CORRECTION: number = 94;
  // RMS最小阈值
  private static readonly MIN_RMS_THRESHOLD: number = 1.0;
  // 最小有效样本数
  private static readonly MIN_VALID_SAMPLES: number = 10;
  // 无效数据返回值
  private static readonly INVALID_DB: number = -100;  

  /**
   * 对音频数据进行计权计算
   * @param buffer 音频数据
   * @param bytesRead 读取的字节数
   * @param weightingType 计权类型
   * @returns 计权后的分贝值
   */
  public static calculateWeightedDecibel(buffer: ArrayBuffer, bytesRead: number, weightingType: WeightingType): number {
    console.info(`[计权计算] 开始计算，计权类型: ${weightingType}, bytesRead: ${bytesRead}`);

    // 检查数据有效性
    if (!buffer || bytesRead <= 0) {
      console.error('[计权计算] 无效的输入数据');
      return FrequencyWeighting.INVALID_DB;
    }

    try {
      // 执行FFT分析，直接传入计权类型
      const spectrum = FrequencyWeighting.fftAnalyzer.transform(buffer);
      
      // 计算有效的分贝值平均值
      let sum: number = 0;
      let validCount: number = 0;
      
      for (let i = 0; i < spectrum.length; i++) {
        if (!isNaN(spectrum[i]) && spectrum[i] > FrequencyWeighting.INVALID_DB) {
          sum += spectrum[i];
          validCount++;
        }
      }
      
      // 检查是否有足够的有效样本
      if (validCount < FrequencyWeighting.MIN_VALID_SAMPLES) {
        console.warn(`[计权计算] 有效样本数不足: ${validCount}`);
        return FrequencyWeighting.INVALID_DB;
      }
      
      const averageDb = sum / validCount;
      console.info(`[计权计算] 计算完成，平均分贝值: ${averageDb.toFixed(2)}`);
      
      return averageDb;
    } catch (error) {
      console.error(`[计权计算] 处理过程出错: ${error}`);
      return FrequencyWeighting.INVALID_DB;
    }
  }

  /**
   * 计算Z计权(零频率计权)分贝值
   * @param buffer 音频数据
   * @param bytesRead 读取的字节数
   * @returns 分贝值
   */
  private static calculateZWeightedDecibel(buffer: ArrayBuffer, bytesRead: number): number {
    console.info(`[Z计权] 开始计算，bytesRead: ${bytesRead}`);
    
    // 检查数据有效性
    if (!buffer || bytesRead <= 0) {
      console.info('[Z计权] 无效的输入数据');
      return 0;
    }
    
    const int16Array = new Int16Array(buffer, 0, bytesRead / 2);
    console.info(`[Z计权] 样本数量: ${int16Array.length}`);
    
    // 检查样本数量
    if (int16Array.length < FrequencyWeighting.MIN_VALID_SAMPLES) {
      console.info('[Z计权] 样本数量不足');
      return 0;
    }
    
    // 查看前几个样本值
    const samplePreview = Array.from(int16Array.slice(0, 5));
    console.info(`[Z计权] 样本预览: ${JSON.stringify(samplePreview)}`);
    
    let sumSquares = 0;
    let maxSample = 0;
    let validSamples = 0;
    
    // 计算有效样本的RMS值
    for (let i = 0; i < int16Array.length; i++) {
      const sample = Math.abs(int16Array[i]);
      if (sample > 0) {
        sumSquares += sample * sample;
        maxSample = Math.max(maxSample, sample);
        validSamples++;
      }
    }

    console.info(`[Z计权] 最大样本值: ${maxSample}`);
    console.info(`[Z计权] 平方和: ${sumSquares}`);
    console.info(`[Z计权] 有效样本数: ${validSamples}`);

    // 检查是否有足够的有效样本
    if (validSamples < FrequencyWeighting.MIN_VALID_SAMPLES) {
      console.info('[Z计权] 有效样本数不足');
      return 0;
    }
    
    // 计算RMS值
    const rms = Math.sqrt(sumSquares / validSamples);
    console.info(`[Z计权] RMS值: ${rms}`);
    
    // 如果RMS值过小，返回0
    if (rms < FrequencyWeighting.MIN_RMS_THRESHOLD) {
      console.info('[Z计权] RMS值过小');
      return 0;
    }
    
    // 计算分贝值
    const decibelValue = 20 * Math.log10(rms / FrequencyWeighting.REF_VALUE) + FrequencyWeighting.SPL_CORRECTION;
    console.info(`[Z计权] 计算的分贝值: ${decibelValue}`);
    
    return decibelValue;
  }
  
  /**
   * 计算指定频率范围内的能量
   * @param buffer 音频数据
   * @param startFreq 起始频率
   * @param endFreq 结束频率
   * @returns 频率范围内的能量值
   */
  public static calculateFrequencyRangeEnergy(
    buffer: ArrayBuffer, 
    startFreq: number, 
    endFreq: number
  ): number {
    const spectrum = FrequencyWeighting.fftAnalyzer.transform(buffer);
    return FrequencyWeighting.fftAnalyzer.getFrequencyRangeEnergy(spectrum, startFreq, endFreq, 44100);
  }

  /**
   * 获取频谱数据用于显示
   * @param buffer 音频数据
   * @param weightingType 计权类型
   * @returns 频谱数据
   */
  public static getSpectrumData(buffer: ArrayBuffer, weightingType: WeightingType = WeightingType.A): Float32Array {
    return FrequencyWeighting.fftAnalyzer.transform(buffer);
  }
  
  /**
   * 获取特定频段的能量
   * @param buffer 音频数据
   * @param startFreq 起始频率
   * @param endFreq 结束频率
   * @param weightingType 计权类型
   * @returns 频段能量
   */
  public static getBandEnergy(
    buffer: ArrayBuffer, 
    startFreq: number, 
    endFreq: number, 
    weightingType: WeightingType = WeightingType.A
  ): number {
    const spectrum = FrequencyWeighting.fftAnalyzer.transform(buffer);
    return FrequencyWeighting.fftAnalyzer.getFrequencyRangeEnergy(spectrum, startFreq, endFreq, 44100);
  }
}