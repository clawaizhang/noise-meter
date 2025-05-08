/**
 * 首选项键名常量
 */
export class PreferenceKeyConstants {
  /**
   * 位置开关状态键名
   */
  static readonly LOCATION: string = 'location_enabled';

  /**
   * 录音开关状态键名
   */
  static readonly RECORD: string = 'record_enabled';

  /**
   * 分贝加权类型
   */
  static readonly WEIGHTING: string = 'weighting_type';

  /**
   * 音频分析模式
   */
  static readonly ANALYSIS_MODE: string = 'audio_analysis_mode';

  /**
   * 分贝校准值
   */
  static readonly CALIBRATION: string = 'calibration_value';

  /**
   * 屏幕常亮设置
   */
  static readonly KEEP_SCREEN_ON: string = 'keep_screen_on';

  static readonly NOISE_ALARM_ENABLED: string = 'noise_alarm_enabled';
  static readonly NOISE_THRESHOLD: string = 'noise_threshold';
  
  /**
   * 隐私协议同意状态
   */
  static readonly PRIVACY_AGREED: string = 'privacy_agreed';
}
