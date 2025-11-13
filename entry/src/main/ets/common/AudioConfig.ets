import { PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../models/PreferenceKeys';
import { WindowType } from './WindowType';

/**
 * 音频分析模式（符合GB/T 3785.1-2010标准）
 */
export enum AudioAnalysisMode {
  FAST_TIME_WEIGHTING = 'FAST_TIME_WEIGHTING', // 快速音频分析（F）
  SLOW_TIME_WEIGHTING = 'SLOW_TIME_WEIGHTING', // 慢速音频分析（S）
  IMPULSE_TIME_WEIGHTING = 'IMPULSE_TIME_WEIGHTING', // 脉冲音频分析（I）
  CUSTOM_TIME_WEIGHTING = 'CUSTOM_TIME_WEIGHTING' // 自定义音频分析
}

/**
 * 音频分析配置
 */
@ObservedV2
export class AudioAnalysisConfig {
  @Trace
  fftSize: number = 2048; // FFT大小（必须是2的幂次方）
  @Trace
  updateInterval: number = 200; // 更新间隔（毫秒）
  @Trace
  smoothingFactor: number = 0.2; // 平滑因子
  @Trace
  windowType: WindowType = WindowType.HANNING; // 窗函数类型
  @Trace
  overlap: number = 0.4; // 重叠比例 (0-1)
  @Trace
  bufferSize: number = 4096; // 音频缓冲区大小（字节），等于fftSize * 2（16位采样）
  @Trace
  sampleRate: number = 44100; // 采样率（Hz）
  @Trace
  decimationEnabled: boolean = false; // 是否启用降采样
  @Trace
  decimationFactor: number = 2; // 降采样因子
  @Trace
  kaiserBeta: number = 6.0; // Kaiser窗的Beta参数
  @Trace
  gaussianSigma: number = 0.5; // Gaussian窗的Sigma参数
  @Trace
  tukeyAlpha: number = 0.5; // Tukey窗的Alpha参数
  @Trace
  chebyshevAttenuation: number = 60.0; // Chebyshev窗的衰减参数(dB)
  @Trace
  exponentialSmoothingFactor: number = 0.3; // 指数平滑因子 (0-0.99)

  static fast() {
    let fast = new AudioAnalysisConfig();
    fast.fftSize = 4096; // 增加FFT大小以提高低频分辨率
    fast.updateInterval = 200;
    fast.smoothingFactor = 0.2;
    fast.windowType = WindowType.BLACKMAN;
    fast.overlap = 0.4;
    fast.bufferSize = 4096 * 2;
    fast.sampleRate = 44100;
    fast.decimationEnabled = false;
    fast.decimationFactor = 2;
    fast.kaiserBeta = 6.0;
    fast.gaussianSigma = 0.5;
    fast.tukeyAlpha = 0.5;
    fast.chebyshevAttenuation = 60.0;
    fast.exponentialSmoothingFactor = 0.3;
    
    return fast;
  }

  static slow() {
    let slow = new AudioAnalysisConfig();
    slow.fftSize = 4096;
    slow.updateInterval = 500;
    slow.smoothingFactor = 0.05;
    slow.windowType = WindowType.BLACKMAN;
    slow.overlap = 0.6;
    slow.bufferSize = 4096 * 2;
    slow.sampleRate = 44100;
    slow.decimationEnabled = false;
    slow.decimationFactor = 2;
    slow.kaiserBeta = 6.0;
    slow.gaussianSigma = 0.5;
    slow.tukeyAlpha = 0.5;
    slow.chebyshevAttenuation = 60.0;
    slow.exponentialSmoothingFactor = 0.5;
    
    return slow;
  }

  static impulse() {
    let impulse = new AudioAnalysisConfig();
    impulse.fftSize = 2048; // 增加FFT大小以提高低频分辨率
    impulse.updateInterval = 35;
    impulse.smoothingFactor = 0.3;
    impulse.windowType = WindowType.BLACKMAN;
    impulse.overlap = 0.75;
    impulse.bufferSize = 2048 * 2;
    impulse.sampleRate = 44100;
    impulse.decimationEnabled = false;
    impulse.decimationFactor = 2;
    impulse.kaiserBeta = 6.0;
    impulse.gaussianSigma = 0.5;
    impulse.tukeyAlpha = 0.5;
    impulse.chebyshevAttenuation = 60.0;
    impulse.exponentialSmoothingFactor = 0.1;
    
    return impulse;
  }

  clone() {
    let clone = new AudioAnalysisConfig();
    clone.fftSize = this.fftSize;
    clone.updateInterval = this.updateInterval;
    clone.smoothingFactor = this.smoothingFactor;
    clone.windowType = this.windowType;
    clone.overlap = this.overlap;
    clone.bufferSize = this.bufferSize;
    clone.sampleRate = this.sampleRate;
    clone.decimationEnabled = this.decimationEnabled;
    clone.decimationFactor = this.decimationFactor;
    clone.kaiserBeta = this.kaiserBeta;
    clone.gaussianSigma = this.gaussianSigma;
    clone.tukeyAlpha = this.tukeyAlpha;
    clone.chebyshevAttenuation = this.chebyshevAttenuation;
    clone.exponentialSmoothingFactor = this.exponentialSmoothingFactor;
    
    return clone;
  }
}


/**
 * 自定义配置存储键名
 */
export class CustomConfigKeys {
  public static readonly CUSTOM_AUDIO_CONFIG = 'custom_audio_config';
}

/**
 * 默认自定义配置
 */
export const DEFAULT_CUSTOM_CONFIG: AudioAnalysisConfig = new AudioAnalysisConfig();

/**
 * 预设配置
 */
export class AudioPresets {
  // 快速音频分析模式配置（F）
  public static readonly FAST_TIME_WEIGHTING: AudioAnalysisConfig = AudioAnalysisConfig.fast();
  // 慢速音频分析模式配置（S）
  public static readonly SLOW_TIME_WEIGHTING: AudioAnalysisConfig = AudioAnalysisConfig.slow();
  // 脉冲音频分析模式配置（I）
  public static readonly IMPULSE_TIME_WEIGHTING: AudioAnalysisConfig = AudioAnalysisConfig.impulse();
  public static pk:PreferenceKeys ;

  public static init(pk:PreferenceKeys){
    AudioPresets.pk = pk;
  }

  /**
   * 根据模式获取配置
   * @param mode 分析模式
   * @returns 对应的配置
   */
  public static getConfig(mode: AudioAnalysisMode): AudioAnalysisConfig {
    console.info(`[音频配置] 获取${mode}模式配置`);
    let config: AudioAnalysisConfig;

    switch (mode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        config = AudioPresets.FAST_TIME_WEIGHTING;
        break;
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        config = AudioPresets.SLOW_TIME_WEIGHTING;
        break;
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        config = AudioPresets.IMPULSE_TIME_WEIGHTING;
        break;
      case AudioAnalysisMode.CUSTOM_TIME_WEIGHTING:
        // 自定义模式使用用户保存的配置
        config = AudioPresets.pk.custom_audio_config;
        console.info(`[音频配置] 使用自定义配置`);
        break;
      default:
        config = AudioPresets.FAST_TIME_WEIGHTING;
    }

    // 从PreferenceKeys加载采样率配置（仅对非自定义模式应用）
    if (mode !== AudioAnalysisMode.CUSTOM_TIME_WEIGHTING) {
      // 对于预设模式，应用全局采样率设置
      config.sampleRate = AudioPresets.pk.audio_sample_rate;
      config.decimationEnabled = AudioPresets.pk.audio_decimation_enabled;
      config.decimationFactor = AudioPresets.pk.audio_decimation_factor;
      // 应用窗函数类型设置
      config.windowType = AudioPresets.pk.window_function_type;
      // 应用窗函数参数设置
      config.kaiserBeta = AudioPresets.pk.window_kaiser_beta;
      config.gaussianSigma = AudioPresets.pk.window_gaussian_sigma;
      config.tukeyAlpha = AudioPresets.pk.window_tukey_alpha;
      config.chebyshevAttenuation = AudioPresets.pk.window_chebyshev_attenuation;
      // 应用指数平滑因子设置（从custom_audio_config中获取）
      config.exponentialSmoothingFactor = AudioPresets.pk.custom_audio_config.exponentialSmoothingFactor;
    } else {
      // 对于自定义模式，保留自定义配置中的采样率设置，但确保有默认值
      if (config.sampleRate === 0) {
        config.sampleRate = AudioPresets.pk.audio_sample_rate;
      }
      if (config.decimationFactor === 0) {
        config.decimationFactor = AudioPresets.pk.audio_decimation_factor;
      }
      // 对于自定义模式，应用窗函数类型设置
      config.windowType = AudioPresets.pk.window_function_type;
      // 应用窗函数参数设置
      config.kaiserBeta = AudioPresets.pk.window_kaiser_beta;
      config.gaussianSigma = AudioPresets.pk.window_gaussian_sigma;
      config.tukeyAlpha = AudioPresets.pk.window_tukey_alpha;
      config.chebyshevAttenuation = AudioPresets.pk.window_chebyshev_attenuation;
      // 指数平滑因子已经在custom_audio_config中设置，不需要重复设置
    }

    console.info(`[音频配置] 配置详情: FFT大小=${config.fftSize}, ` +
      `窗函数=${config.windowType}, ` +
      `更新间隔=${config.updateInterval}ms, ` +
      `重叠率=${config.overlap}, ` +
      `缓冲区大小=${config.bufferSize}字节, ` +
      `采样率=${config.sampleRate}Hz, ` +
      `降采样启用=${config.decimationEnabled}, ` +
      `降采样因子=${config.decimationFactor}`);
    return config;
  }
}
