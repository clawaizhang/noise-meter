/**
 * 音频分析模式（符合GB/T 3785.1-2010标准）
 */
export enum AudioAnalysisMode {
  FAST_RESPONSE = 'FAST_RESPONSE',    // 快速响应模式（F）
  SLOW_RESPONSE = 'SLOW_RESPONSE',    // 慢速响应模式（S）
  IMPULSE_RESPONSE = 'IMPULSE_RESPONSE' // 脉冲响应模式（I）
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
  // 快速响应模式配置（F）
  public static readonly FAST_RESPONSE: AudioAnalysisConfig = {
    fftSize: 512,          // 较小FFT size，提高时间分辨率
    updateInterval: 125,   // 125ms符合快速响应时间常数
    smoothingFactor: 0.125,
    windowType: WindowType.HANNING,
    overlap: 0.5,
    bufferSize: 512 * 2
  };

  // 慢速响应模式配置（S）
  public static readonly SLOW_RESPONSE: AudioAnalysisConfig = {
    fftSize: 1024,         // 中等FFT size，平衡时间和频率分辨率
    updateInterval: 1000,  // 1000ms符合慢速响应时间常数
    smoothingFactor: 0.0625,
    windowType: WindowType.HANNING,
    overlap: 0.5,
    bufferSize: 1024 * 2
  };

  // 脉冲响应模式配置（I）
  public static readonly IMPULSE_RESPONSE: AudioAnalysisConfig = {
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
      case AudioAnalysisMode.FAST_RESPONSE:
        config = AudioPresets.FAST_RESPONSE;
        break;
      case AudioAnalysisMode.SLOW_RESPONSE:
        config = AudioPresets.SLOW_RESPONSE;
        break;
      case AudioAnalysisMode.IMPULSE_RESPONSE:
        config = AudioPresets.IMPULSE_RESPONSE;
        break;
      default:
        config = AudioPresets.FAST_RESPONSE;
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
