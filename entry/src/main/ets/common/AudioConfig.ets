/**
 * 音频分析模式（符合GB/T 3785.1-2010标准）
 */
export enum AudioAnalysisMode {
  FAST_TIME_WEIGHTING = 'FAST_TIME_WEIGHTING', // 快速时间计权（F）
  SLOW_TIME_WEIGHTING = 'SLOW_TIME_WEIGHTING', // 慢速时间计权（S）
  IMPULSE_TIME_WEIGHTING = 'IMPULSE_TIME_WEIGHTING' // 脉冲时间计权（I）
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
   * @param overrideWindowType 覆盖的窗函数类型（可选）
   * @returns 对应的配置
   */
  public static getConfig(mode: AudioAnalysisMode, overrideWindowType?: WindowType): AudioAnalysisConfig {
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

    // 如果提供了覆盖窗函数类型，则使用覆盖值
    if (overrideWindowType) {
      config = {
        fftSize: config.fftSize,
        updateInterval: config.updateInterval,
        smoothingFactor: config.smoothingFactor,
        overlap: config.overlap,
        bufferSize: config.bufferSize,
        windowType: overrideWindowType
      };
      console.info(`[音频配置] 使用覆盖窗函数: ${overrideWindowType}`);
    }

    console.info(`[音频配置] 配置详情: FFT大小=${config.fftSize}, ` +
      `窗函数=${config.windowType}, ` +
      `更新间隔=${config.updateInterval}ms, ` +
      `重叠率=${config.overlap}, ` +
      `缓冲区大小=${config.bufferSize}字节`);
    return config;
  }
}
