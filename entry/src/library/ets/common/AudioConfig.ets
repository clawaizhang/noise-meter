/**
 * 音频分析模式
 */
export enum AudioAnalysisMode {
  FAST_RESPONSE = 'FAST_RESPONSE',    // 快速响应模式
  BALANCED = 'BALANCED',              // 平衡模式
  PRECISE = 'PRECISE',                // 精确分析模式
  LOW_FREQUENCY = 'LOW_FREQUENCY'     // 低频分析模式
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
  processInterval: number;  // 处理间隔（毫秒）
  smoothingFactor: number; // 平滑因子
  windowType: WindowType;  // 窗函数类型
  overlap: number;         // 重叠比例 (0-1)
  bufferSize: number;      // 音频缓冲区大小（字节），等于fftSize * 2（16位采样）
}

/**
 * 预设配置
 */
export class AudioPresets {
  // 快速响应模式配置
  public static readonly FAST_RESPONSE: AudioAnalysisConfig = {
    fftSize: 1024,
    processInterval: 25,
    smoothingFactor: 0.3,
    windowType: WindowType.HANNING,
    overlap: 0.5,
    bufferSize: 1024 * 2  // fftSize * 2（16位采样）
  };

  // 平衡模式配置
  public static readonly BALANCED: AudioAnalysisConfig = {
    fftSize: 2048,
    processInterval: 45,
    smoothingFactor: 0.2,
    windowType: WindowType.HANNING,
    overlap: 0.5,
    bufferSize: 2048 * 2  // fftSize * 2（16位采样）
  };

  // 精确分析模式配置
  public static readonly PRECISE: AudioAnalysisConfig = {
    fftSize: 4096,
    processInterval: 85,
    smoothingFactor: 0.1,
    windowType: WindowType.BLACKMAN,
    overlap: 0.75,
    bufferSize: 4096 * 2  // fftSize * 2（16位采样）
  };

  // 低频分析模式配置
  public static readonly LOW_FREQUENCY: AudioAnalysisConfig = {
    fftSize: 8192,
    processInterval: 165,
    smoothingFactor: 0.05,
    windowType: WindowType.BLACKMAN,
    overlap: 0.875,
    bufferSize: 8192 * 2  // fftSize * 2（16位采样）
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
      case AudioAnalysisMode.BALANCED:
        config = AudioPresets.BALANCED;
        break;
      case AudioAnalysisMode.PRECISE:
        config = AudioPresets.PRECISE;
        break;
      case AudioAnalysisMode.LOW_FREQUENCY:
        config = AudioPresets.LOW_FREQUENCY;
        break;
      default:
        config = AudioPresets.BALANCED;
    }
    
    console.info(`[音频配置] 配置详情: FFT大小=${config.fftSize}, ` +
                `处理间隔=${config.processInterval}ms, ` +
                `重叠率=${config.overlap}, ` +
                `缓冲区大小=${config.bufferSize}字节`);
    return config;
  }
}

// 配置相关的首选项键名
export const PREF_ANALYSIS_MODE = 'audio_analysis_mode';
export const PREF_CUSTOM_CONFIG = 'audio_custom_config';
