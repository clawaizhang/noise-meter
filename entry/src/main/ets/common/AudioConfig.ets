import { PersistenceV2 } from "@kit.ArkUI";
import { PreferenceKeys } from "../models/PreferenceKeys";

/**
 * 音频分析模式（符合GB/T 3785.1-2010标准）
 */
export enum AudioAnalysisMode {
  FAST_TIME_WEIGHTING = 'FAST_TIME_WEIGHTING', // 快速时间计权（F）
  SLOW_TIME_WEIGHTING = 'SLOW_TIME_WEIGHTING', // 慢速时间计权（S）
  IMPULSE_TIME_WEIGHTING = 'IMPULSE_TIME_WEIGHTING', // 脉冲时间计权（I）
  CUSTOM_TIME_WEIGHTING = 'CUSTOM_TIME_WEIGHTING' // 自定义时间计权
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
export interface AudioAnalysisConfig {
  fftSize: number; // FFT大小（必须是2的幂次方）
  updateInterval: number; // 更新间隔（毫秒）
  smoothingFactor: number; // 平滑因子
  windowType: WindowType; // 窗函数类型
  overlap: number; // 重叠比例 (0-1)
  bufferSize: number; // 音频缓冲区大小（字节），等于fftSize * 2（16位采样）
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
export const DEFAULT_CUSTOM_CONFIG: AudioAnalysisConfig = {
  fftSize: 2048,
  updateInterval: 200,
  smoothingFactor: 0.2,
  windowType: WindowType.HANNING,
  overlap: 0.4,
  bufferSize: 4096
};

/**
 * 自定义配置管理器
 */
export class CustomConfigManager {
  /**
   * 获取自定义配置
   */
  public static getCustomConfig(): AudioAnalysisConfig {
    try {
      const config = PersistenceV2.connect(PreferenceKeys)!.custom_audio_config;
      if (config) {
        return config as AudioAnalysisConfig;
      }
    } catch (error) {
      console.error('[自定义配置] 获取配置失败:', error);
    }

    // 返回默认配置
    return {
      fftSize: DEFAULT_CUSTOM_CONFIG.fftSize,
      updateInterval: DEFAULT_CUSTOM_CONFIG.updateInterval,
      smoothingFactor: DEFAULT_CUSTOM_CONFIG.smoothingFactor,
      windowType: DEFAULT_CUSTOM_CONFIG.windowType,
      overlap: DEFAULT_CUSTOM_CONFIG.overlap,
      bufferSize: DEFAULT_CUSTOM_CONFIG.bufferSize
    };
  }

  /**
   * 保存自定义配置
   */
  public static saveCustomConfig(config: AudioAnalysisConfig): void {
    try {
      PersistenceV2.connect(PreferenceKeys)!.custom_audio_config = config;
      console.info('[自定义配置] 配置已保存');
    } catch (error) {
      console.error('[自定义配置] 保存配置失败:', error);
    }
  }

  /**
   * 重置自定义配置为默认值
   */
  public static resetCustomConfig(): void {
    try {
      PersistenceV2.connect(PreferenceKeys)!.custom_audio_config = DEFAULT_CUSTOM_CONFIG;
      console.info('[自定义配置] 配置已重置为默认值');
    } catch (error) {
      console.error('[自定义配置] 重置配置失败:', error);
    }
  }
}

/**
 * 预设配置
 */
export class AudioPresets {
  // 快速时间计权模式配置（F）
  public static readonly FAST_TIME_WEIGHTING: AudioAnalysisConfig = {
    fftSize: 2048, // 中等FFT size，平衡时间和频率分辨率
    updateInterval: 200, // 200ms符合快速响应时间常数
    smoothingFactor: 0.2, // 增加平滑度，减少快速变化带来的波动
    windowType: WindowType.BLACKMAN, // 使用主瓣更窄的窗函数
    overlap: 0.4, // 降低重叠率，提高时间分辨率
    bufferSize: 2048 * 2
  };
  // 慢速时间计权模式配置（S）
  public static readonly SLOW_TIME_WEIGHTING: AudioAnalysisConfig = {
    fftSize: 4096, // 较大FFT size，提高频率分辨率
    updateInterval: 500, // 500ms符合慢速响应时间常数
    smoothingFactor: 0.05, // 降低平滑度，保留更多细节
    windowType: WindowType.HANNING,
    overlap: 0.6, // 提高重叠率，增加频率分辨率
    bufferSize: 4096 * 2
  };
  // 脉冲时间计权模式配置（I）
  public static readonly IMPULSE_TIME_WEIGHTING: AudioAnalysisConfig = {
    fftSize: 1024, // 较小FFT size，提高时间分辨率
    updateInterval: 35, // 35ms符合脉冲响应时间常数
    smoothingFactor: 0.3, // 增加平滑度，减少脉冲噪声影响
    windowType: WindowType.BLACKMAN,
    overlap: 0.75,
    bufferSize: 1024 * 2
  };

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
        config = CustomConfigManager.getCustomConfig();
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
