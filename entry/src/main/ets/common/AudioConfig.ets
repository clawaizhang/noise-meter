import { PersistenceV2 } from "@kit.ArkUI";
import { PreferenceKeys } from "../models/PreferenceKeys";

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
 * 窗函数类型
 */
export enum WindowType {
  HANNING = 'HANNING', // 汉宁窗
  BLACKMAN = 'BLACKMAN' // 布莱克曼窗
}

/**
 * 音频分析配置
 */
@ObservedV2
export class AudioAnalysisConfig {
  @Trace
  fftSize: number; // FFT大小（必须是2的幂次方）
  @Trace
  updateInterval: number; // 更新间隔（毫秒）
  @Trace
  smoothingFactor: number; // 平滑因子
  @Trace
  windowType: WindowType; // 窗函数类型
  @Trace
  overlap: number; // 重叠比例 (0-1)
  @Trace
  bufferSize: number; // 音频缓冲区大小（字节），等于fftSize * 2（16位采样）

  constructor(fftSize: number, updateInterval: number, smoothingFactor: number, windowType: WindowType, overlap: number,
    bufferSize: number) {
    this.fftSize = fftSize;
    this.updateInterval = updateInterval;
    this.smoothingFactor = smoothingFactor;
    this.windowType = windowType;
    this.overlap = overlap;
    this.bufferSize = bufferSize;
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
export const DEFAULT_CUSTOM_CONFIG: AudioAnalysisConfig =
  new AudioAnalysisConfig(2048, 200, 0.2, WindowType.HANNING, 0.4, 4096);

/**
 * 预设配置
 */
export class AudioPresets {
  // 快速音频分析模式配置（F）
  public static readonly FAST_TIME_WEIGHTING: AudioAnalysisConfig =
    new AudioAnalysisConfig(2048, 200, 0.2, WindowType.BLACKMAN, 0.4, 2048 * 2);
  // 慢速音频分析模式配置（S）
  public static readonly SLOW_TIME_WEIGHTING: AudioAnalysisConfig =
    new AudioAnalysisConfig(4096, 500, 0.05, WindowType.BLACKMAN, 0.6, 4096 * 2);
  // 脉冲音频分析模式配置（I）
  public static readonly IMPULSE_TIME_WEIGHTING: AudioAnalysisConfig =
    new AudioAnalysisConfig(1024, 35, 0.3, WindowType.BLACKMAN, 0.75, 1024 * 2);

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
        config = PersistenceV2.connect(PreferenceKeys)!.custom_audio_config;
        console.info(`[音频配置] 使用自定义配置`);
        break;
      default:
        config = AudioPresets.FAST_TIME_WEIGHTING;
    }

    console.info(`[音频配置] 配置详情: FFT大小=${config.fftSize}, ` +
      `窗函数=${config.windowType}, ` +
      `更新间隔=${config.updateInterval}ms, ` +
      `重叠率=${config.overlap}, ` +
      `缓冲区大小=${config.bufferSize}字节`);
    return config;
  }
}
