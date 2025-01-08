import { WeightingType } from '../constants/WeightingConstants';

/**
 * 频率计权工具类
 */
export class FrequencyWeighting {
  // FFT 分析的采样点数
  private static readonly FFT_SIZE: number = 2048;
  
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

    // A计权和C计权使用FFT分析
    return FrequencyWeighting.calculateFrequencyWeightedDecibel(buffer, weightingType);
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
    return 20 * Math.log10(Math.max(combined, 1) / FrequencyWeighting.REF_VALUE);
  }

  /**
   * 使用频率计权计算分贝值
   * @param buffer 音频数据
   * @param weightingType 计权类型
   * @returns 分贝值
   */
  private static calculateFrequencyWeightedDecibel(buffer: ArrayBuffer, weightingType: WeightingType): number {
    // 将音频数据转换为浮点数组
    const int16Array = new Int16Array(buffer);
    const floatArray = new Float32Array(int16Array.length);
    for (let i = 0; i < int16Array.length; i++) {
      floatArray[i] = int16Array[i] / 32768.0;
    }

    // 执行FFT
    const fftResult = FrequencyWeighting.performFFT(floatArray);
    
    // 获取频谱
    const spectrum = FrequencyWeighting.getSpectrum(fftResult);
    
    // 应用频率计权
    let weightedSum = 0;
    for (let i = 0; i < FrequencyWeighting.STANDARD_FREQUENCIES.length; i++) {
      const frequency = FrequencyWeighting.STANDARD_FREQUENCIES[i];
      const amplitude = FrequencyWeighting.getAmplitudeAtFrequency(spectrum, frequency, 48000); // 假设采样率为48kHz
      
      // 根据计权类型选择修正值
      let correction = 0;
      switch (weightingType) {
        case WeightingType.A:
          correction = FrequencyWeighting.A_WEIGHTING[i];
          break;
        case WeightingType.C:
          correction = FrequencyWeighting.C_WEIGHTING[i];
          break;
      }
      
      // 应用修正值并累加
      const weightedAmplitude = amplitude * Math.pow(10, correction / 20);
      weightedSum += weightedAmplitude * weightedAmplitude;
    }
    
    // 计算最终的分贝值
    const weightedRMS = Math.sqrt(weightedSum);
    return 20 * Math.log10(Math.max(weightedRMS, 1e-6));
  }

  /**
   * 执行FFT变换
   * @param input 输入数据
   * @returns FFT结果
   */
  private static performFFT(input: Float32Array): Float32Array {
    // 这里使用简化的FFT实现
    // 在实际应用中,建议使用成熟的FFT库
    const fftSize = FrequencyWeighting.FFT_SIZE;
    const output = new Float32Array(fftSize);
    
    // 复制输入数据并应用窗函数
    for (let i = 0; i < fftSize && i < input.length; i++) {
      // 使用汉宁窗
      const window = 0.5 * (1 - Math.cos(2 * Math.PI * i / fftSize));
      output[i] = input[i] * window;
    }
    
    // TODO: 实现实际的FFT算法
    // 当前返回模拟的频谱数据
    return output;
  }

  /**
   * 获取频谱数据
   * @param fftResult FFT结果
   * @returns 频谱数据
   */
  private static getSpectrum(fftResult: Float32Array): Float32Array {
    const spectrum = new Float32Array(fftResult.length / 2);
    for (let i = 0; i < spectrum.length; i++) {
      const real = fftResult[2 * i];
      const imag = fftResult[2 * i + 1];
      spectrum[i] = Math.sqrt(real * real + imag * imag);
    }
    return spectrum;
  }

  /**
   * 获取指定频率的幅值
   * @param spectrum 频谱数据
   * @param frequency 目标频率
   * @param sampleRate 采样率
   * @returns 幅值
   */
  private static getAmplitudeAtFrequency(spectrum: Float32Array, frequency: number, sampleRate: number): number {
    const binSize = sampleRate / (2 * spectrum.length);
    const binIndex = Math.round(frequency / binSize);
    return binIndex < spectrum.length ? spectrum[binIndex] : 0;
  }
} 