import { PreferencesUtil } from "@pura/harmony-utils";
import { AudioAnalysisMode, AudioPresets } from "../common/AudioConfig";
import { WeightingType } from "../constants/WeightingConstants";

/**
 * 首选项键名常量
 */
@ObservedV2
export class PreferenceKeys {
  /**
   * 位置开关状态键名
   */
  @Trace
  location_enabled: boolean = PreferencesUtil.getBooleanSync('location_enabled',true);
  /**
   * 录音开关状态键名
   */
  @Trace
  record_enabled: boolean = PreferencesUtil.getBooleanSync('record_enabled',true);


  @Trace
  nature_sound_enabled: boolean = true;
  /**
   * 分贝加权类型
   */
  @Trace
  weighting_type: WeightingType = PreferencesUtil.getStringSync('weighting_type', WeightingType.A) as WeightingType;

  @Trace
  display_mode: string = 'default';
  /**
   * 音频分析模式
   */
  @Trace
  audio_analysis_mode: AudioAnalysisMode = PreferencesUtil.getStringSync('audio_analysis_mode',AudioAnalysisMode.FAST_TIME_WEIGHTING) as AudioAnalysisMode;

  /**
   * 分贝校准值
   */
  @Trace
  calibration_value: number = PreferencesUtil.getNumberSync('calibration_value',0);
  /**
   * 屏幕常亮设置
   */
  @Trace
  keep_screen_on: boolean = PreferencesUtil.getBooleanSync('keep_screen_on', true);
  @Trace
  noise_alarm_enabled: boolean = PreferencesUtil.getBooleanSync('noise_alarm_enabled',true);
  @Trace
  noise_threshold: number = PreferencesUtil.getNumberSync('noise_threshold',80);
  /**
   * 隐私协议同意状态
   */
  @Trace
  privacy_agreed: boolean = PreferencesUtil.getBooleanSync('privacy_agreed',false);

  /**
   * 后台运行开关状态键名
   */
  @Trace
  background_running: boolean = PreferencesUtil.getBooleanSync('background_running', false);
}
