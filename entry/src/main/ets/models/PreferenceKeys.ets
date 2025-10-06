import { PreferencesUtil } from '@pura/harmony-utils';
import {
  AudioAnalysisConfig,
  AudioAnalysisMode,
  DEFAULT_CUSTOM_CONFIG,
} from '../common/AudioConfig';
import { WeightingType } from '../constants/WeightingConstants';
import { MembershipStatus } from '../services/MembershipManager';
import { ContinuousUsageData } from './ContinuousUsageData';
import { CUSTOM_THRESHOLD_CONFIG, DEFAULT_THRESHOLD_CONFIG, PresetType, ThresholdConfig } from './ThresholdConfig';

/**
 * 首选项键名常量
 */
@ObservedV2
export class PreferenceKeys {
  /**
   * 位置开关状态键名
   */
  @Trace
  location_enabled: boolean = PreferencesUtil.getBooleanSync('location_enabled', true);
  /**
   * 录音开关状态键名
   */
  @Trace
  record_enabled: boolean = PreferencesUtil.getBooleanSync('record_enabled', true);
  @Trace
  nature_sound_enabled: boolean = true;
  /**
   * 分贝加权类型
   */
  @Trace
  weighting_type: WeightingType = PreferencesUtil.getStringSync('weighting_type', WeightingType.A) as WeightingType;
  @Trace
  display_mode: string = 'dark';
  /**
   * 音频分析模式
   */
  @Trace
  audio_analysis_mode: AudioAnalysisMode =
    PreferencesUtil.getStringSync('audio_analysis_mode', AudioAnalysisMode.FAST_TIME_WEIGHTING) as AudioAnalysisMode;
  /**
   * 分贝校准值
   */
  @Trace
  calibration_value: number = PreferencesUtil.getNumberSync('calibration_value', 0);
  /**
   * 屏幕常亮设置
   */
  @Trace
  keep_screen_on: boolean = PreferencesUtil.getBooleanSync('keep_screen_on', true);
  @Trace
  noise_threshold: number = PreferencesUtil.getNumberSync('noise_threshold', 80);
  /**
   * 隐私协议同意状态
   */
  @Trace
  privacy_agreed: boolean = PreferencesUtil.getBooleanSync('privacy_agreed', false);
  /**
   * 隐私协议同意状态
   */
  @Trace
  show_welcome_guide: boolean = PreferencesUtil.getBooleanSync('show_welcome_guide', true);
  /**
   * 后台运行开关状态键名
   */
  @Trace
  background_running: boolean = PreferencesUtil.getBooleanSync('background_running', true);
  /**
   * 麦克风权限请求状态
   */
  @Trace
  microphone_permission_requested: boolean = PreferencesUtil.getBooleanSync('microphone_permission_requested', false);
  /**
   * 系统通知开关（合并了原来的主开关和系统通知开关）
   */
  @Trace
  system_notification_enabled: boolean = PreferencesUtil.getBooleanSync('system_notification_enabled', true);
  /**
   * 阈值
   */
  @Trace
  alarm_threshold: ThresholdConfig = DEFAULT_THRESHOLD_CONFIG;
  /**
   * 是否申请过系统通知权限
   */
  @Trace
  notification_permission_requested: boolean =
    PreferencesUtil.getBooleanSync('notification_permission_requested', false);
  /**
   * 自动保存开关
   */
  @Trace
  auto_save_enabled: boolean = PreferencesUtil.getBooleanSync('auto_save_enabled', false);
  /**
   * 自动保存间隔（分钟）
   */
  @Trace
  auto_save_interval: number = PreferencesUtil.getNumberSync('auto_save_interval', 5);
  /**
   * 自定义分析模式开关
   */
  @Trace
  custom_audio_config_enabled: boolean = PreferencesUtil.getBooleanSync('custom_audio_config_enabled', false);
  /**
   * 自定义分析模式数据
   */
  @Trace
  custom_audio_config: AudioAnalysisConfig =
    new AudioAnalysisConfig(DEFAULT_CUSTOM_CONFIG.fftSize, DEFAULT_CUSTOM_CONFIG.updateInterval,
      DEFAULT_CUSTOM_CONFIG.smoothingFactor, DEFAULT_CUSTOM_CONFIG.windowType, DEFAULT_CUSTOM_CONFIG.overlap,
      DEFAULT_CUSTOM_CONFIG.bufferSize);
  /**
   * 会员奖励协议同意状态
   */
  @Trace
  has_agreed_membership_reward: boolean = PreferencesUtil.getBooleanSync('has_agreed_membership_reward', false);

  @Trace
  member_ship: MembershipStatus = new MembershipStatus();

  /**
   * 连续使用数据
   */
  @Trace
  continuous_usage_data: ContinuousUsageData = new ContinuousUsageData();

  /**
   * 最后进入前台时间戳
   */
  @Trace
  last_app_foreground_time: number = 0;

  /**
   * 今日累计使用秒数（备份字段）
   */
  @Trace
  total_app_usage_today: number = 0;
}
