/**
 * 音频分析模式（符合GB/T 3785.1-2010标准）
 */
export enum AudioAnalysisMode {
  FAST_TIME_WEIGHTING = 'FAST_TIME_WEIGHTING',    // 快速时间计权（F）
  SLOW_TIME_WEIGHTING = 'SLOW_TIME_WEIGHTING',    // 慢速时间计权（S）
  IMPULSE_TIME_WEIGHTING = 'IMPULSE_TIME_WEIGHTING' // 脉冲时间计权（I）
}

/**
 * 窗函数类型
 */
export enum WindowType {
  HANNING = 'HANNING',      // 汉宁窗
  BLACKMAN = 'BLACKMAN'     // 布莱克曼窗
}

/**
 * 音频分析配置
 */
export interface AudioAnalysisConfig {
  fftSize: number;          // FFT大小（必须是2的幂次方）
  updateInterval: number;   // 更新间隔（毫秒）
  smoothingFactor: number; // 平滑因子
  windowType: WindowType;  // 窗函数类型
  overlap: number;         // 重叠比例 (0-1)
  bufferSize: number;      // 音频缓冲区大小（字节），等于fftSize * 2（16位采样）
}

/**
 * 预设配置
 */
export class AudioPresets {
  // 快速时间计权模式配置（F）
  public static readonly FAST_TIME_WEIGHTING: AudioAnalysisConfig = {
    fftSize: 512,          // 较小FFT size，提高时间分辨率
    updateInterval: 125,   // 125ms符合快速响应时间常数
    smoothingFactor: 0.125,
    windowType: WindowType.HANNING,
    overlap: 0.5,
    bufferSize: 512 * 2
  };

  // 慢速时间计权模式配置（S）
  public static readonly SLOW_TIME_WEIGHTING: AudioAnalysisConfig = {
    fftSize: 1024,         // 中等FFT size，平衡时间和频率分辨率
    updateInterval: 1000,  // 1000ms符合慢速响应时间常数
    smoothingFactor: 0.0625,
    windowType: WindowType.HANNING,
    overlap: 0.5,
    bufferSize: 1024 * 2
  };

  // 脉冲时间计权模式配置（I）
  public static readonly IMPULSE_TIME_WEIGHTING: AudioAnalysisConfig = {
    fftSize: 2048,         // 较大FFT size，提高频率分辨率
    updateInterval: 35,    // 35ms符合脉冲响应时间常数
    smoothingFactor: 0.25,
    windowType: WindowType.BLACKMAN,
    overlap: 0.75,
    bufferSize: 2048 * 2
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
      default:
        config = AudioPresets.FAST_TIME_WEIGHTING;
    }
    
    console.info(`[音频配置] 配置详情: FFT大小=${config.fftSize}, ` +
                `更新间隔=${config.updateInterval}ms, ` +
                `重叠率=${config.overlap}, ` +
                `缓冲区大小=${config.bufferSize}字节`);
    return config;
  }
}

// 配置相关的首选项键名
export const PREF_ANALYSIS_MODE = 'audio_analysis_mode';
export const PREF_CUSTOM_CONFIG = 'audio_custom_config';
