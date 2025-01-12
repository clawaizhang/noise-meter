import { WeightingType } from '../constants/WeightingConstants';
import { FFTAnalyzer } from './FFTAnalyzer';
import { AudioAnalysisMode, AudioPresets } from '../common/AudioConfig';

/**
 * 频率计权工具类
 */
export class FrequencyWeighting {
  // FFT分析器实例
  private static fftAnalyzer: FFTAnalyzer;
  
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
   * 初始化FFT分析器
   * @param mode 分析模式
   */
  public static initializeAnalyzer(mode: AudioAnalysisMode = AudioAnalysisMode.BALANCED): void {
    console.info(`[频率计权] 初始化分析器: 模式=${mode}`);
    const config = AudioPresets.getConfig(mode);
    FrequencyWeighting.fftAnalyzer = new FFTAnalyzer(
      config.fftSize,
      config.windowType,
      config.smoothingFactor
    );
    
    console.info(`[频率计权] 分析器配置: FFT大小=${config.fftSize}, ` +
                `窗函数=${config.windowType}, ` +
                `平滑因子=${config.smoothingFactor}`);
  }

  /**
   * 更新分析模式
   * @param mode 分析模式
   */
  public static updateAnalysisMode(mode: AudioAnalysisMode): void {
    const config = AudioPresets.getConfig(mode);
    FrequencyWeighting.fftAnalyzer = new FFTAnalyzer(
      config.fftSize,
      config.windowType,
      config.smoothingFactor
    );
    console.info(`[频率计权] 切换到${mode}模式`);
  }

  /**
   * 获取频率分辨率
   */
  public static getFrequencyResolution(): number {
    return FrequencyWeighting.fftAnalyzer.getFrequencyResolution();
  }

  /**
   * 获取时间分辨率（毫秒）
   */
  public static getTimeResolution(): number {
    return FrequencyWeighting.fftAnalyzer.getTimeResolution();
  }

  /**
   * 重置分析器状态
   */
  public static reset(): void {
    FrequencyWeighting.fftAnalyzer.reset();
  }

  /**
   * 获取频谱数据用于显示
   * @param buffer 音频数据
   * @param weightingType 计权类型
   * @returns 频谱数据
   */
  public static getSpectrumData(buffer: ArrayBuffer, weightingType: WeightingType = WeightingType.A): Float32Array {
    if (!FrequencyWeighting.fftAnalyzer) {
      console.error('[频谱分析] FFT分析器未初始化');
      return new Float32Array(1024);
    }

    try {
      console.info(`[频谱分析] 开始处理音频数据: 数据大小=${buffer.byteLength}字节`);

      // 执行FFT变换并获取频谱数据
      const spectrum = FrequencyWeighting.fftAnalyzer.transform(buffer,weightingType);
      console.info(`[频谱分析] FFT变换完成: 频谱长度=${spectrum.length}`);
      console.info(`[频谱分析] 原始频谱样本: ${spectrum[0]}, ${spectrum[1]}, ${spectrum[2]}, ${spectrum[3]}, ${spectrum[4]}`);

      // 应用计权
      const weightedSpectrum = FrequencyWeighting.fftAnalyzer.applyWeighting(spectrum, weightingType);
      console.info(`[频谱分析] 计权后频谱样本: ${weightedSpectrum[0]}, ${weightedSpectrum[1]}, ${weightedSpectrum[2]}, ${weightedSpectrum[3]}, ${weightedSpectrum[4]}`);

      return weightedSpectrum;
    } catch (error) {
      console.error('[频谱分析] 处理失败:', error);
      return new Float32Array(1024);
    }
  }

  public static calculateAverageDb(weightedSpectrum: Float32Array): number {
    return FrequencyWeighting.fftAnalyzer.calculateAverageDb(weightedSpectrum);
  }
}