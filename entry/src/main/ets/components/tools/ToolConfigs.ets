import { AudioAnalysisMode } from "../../common/AudioConfig";
import { WeightingType } from "../../constants/WeightingConstants";
import { AppKeys } from "../../models/AppKeys";
import { PreferenceKeys } from "../../models/PreferenceKeys";
import { WindowType } from "../../common/WindowType";
import { ToolConfig, ToolCategory, ToolPriority } from "./ToolsContent";


// 工具创建工厂类
export class ToolConfigFactory {
  private pk: PreferenceKeys;
  private ak: AppKeys;

  constructor(pk: PreferenceKeys, ak: AppKeys) {
    this.pk = pk;
    this.ak = ak;
  }

  // 创建校准工具
  createCalibrationTool(navigateToAudioCalibration: () => void): ToolConfig {
    return {
      id: 'calibration',
      title: '声级校准',
      icon: $r('app.media.ic_calibration'),
      description: '自动和手动校准',
      category: ToolCategory.BASIC_MEASUREMENT,
      priority: ToolPriority.ESSENTIAL,
      usageHint: '确保测量精度的关键步骤',
      learnMore: () => this.showLearnMore('校准'),
      getStatus: () => `当前: ${this.pk.calibration_value}dB`,
      getStatusColor: () => $r('sys.color.font_primary'),
      onTap: navigateToAudioCalibration
    };
  }

  // 创建频率加权工具
  createFrequencyWeightingTool(navigateToFrequencyWeighting: () => void, getWeightingDisplayName: (weighting: WeightingType) => string): ToolConfig {
    return {
      id: 'frequency_weighting',
      title: '频率加权',
      icon: $r('app.media.ic_frequency_weighting'),
      description: 'A/C/Z计权设置',
      category: ToolCategory.BASIC_MEASUREMENT,
      priority: ToolPriority.ESSENTIAL,
      usageHint: 'A计权适用于环境噪声测量',
      learnMore: () => this.showLearnMore('频率加权'),
      getStatus: () => getWeightingDisplayName(this.pk.weighting_type),
      getStatusColor: () => $r('sys.color.font_primary'),
      onTap: navigateToFrequencyWeighting
    };
  }

  // 创建音频分析模式工具
  createAudioAnalysisModeTool(navigateToAudioAnalysisMode: () => void, getAnalysisModeDisplayName: (mode: AudioAnalysisMode) => string): ToolConfig {
    return {
      id: 'audio_analysis_mode',
      title: '音频分析模式',
      icon: $r('app.media.ic_time_weighting'),
      description: '快速/慢速/脉冲',
      category: ToolCategory.BASIC_MEASUREMENT,
      priority: ToolPriority.RECOMMENDED,
      usageHint: '快速模式适用于实时测量',
      learnMore: () => this.showLearnMore('时间加权'),
      getStatus: () => getAnalysisModeDisplayName(this.pk.audio_analysis_mode),
      getStatusColor: () => $r('sys.color.font_primary'),
      onTap: navigateToAudioAnalysisMode
    };
  }

  // 创建音频记录工具
  createAudioRecordingTool(toggleAudioRecording: () => void): ToolConfig {
    return {
      id: 'audio_recording',
      title: '音频记录',
      icon: $r('app.media.ic_mic'),
      description: '保存原始音频',
      category: ToolCategory.DATA_MANAGEMENT,
      priority: ToolPriority.RECOMMENDED,
      usageHint: '记录音频用于后续分析',
      getStatus: () => this.pk.record_enabled ? '已开启' : '已关闭',
      getStatusColor: () => this.pk.record_enabled ? $r('sys.color.confirm') : $r('sys.color.font_secondary'),
      onTap: toggleAudioRecording
    };
  }

  // 创建自动保存工具
  createAutoSaveTool(navigateToAutoSave: () => void): ToolConfig {
    return {
      id: 'auto_save',
      title: '自动保存',
      icon: $r('app.media.ic_save'),
      description: '自动保存设置',
      category: ToolCategory.DATA_MANAGEMENT,
      priority: ToolPriority.ESSENTIAL,
      usageHint: '防止数据丢失的重要功能',
      getStatus: () => this.pk.auto_save_enabled ? '已开启' : '已关闭',
      getStatusColor: () => this.pk.auto_save_enabled ? $r('sys.color.confirm') : $r('sys.color.font_secondary'),
      onTap: navigateToAutoSave
    };
  }

  // 创建位置服务工具
  createLocationServiceTool(toggleLocationService: () => void, getLocationStatus: () => string, getLocationStatusColor: () => Resource): ToolConfig {
    return {
      id: 'location_service',
      title: '位置服务',
      icon: $r('app.media.ic_location'),
      description: '记录位置信息',
      category: ToolCategory.DATA_MANAGEMENT,
      priority: ToolPriority.RECOMMENDED,
      usageHint: '为测量数据添加地理标签',
      getStatus: getLocationStatus,
      getStatusColor: getLocationStatusColor,
      onTap: toggleLocationService
    };
  }

  // 创建频谱显示工具
  createSpectrumDisplayTool(navigateToSpectrumDisplaySettings: () => void): ToolConfig {
    return {
      id: 'spectrum_display',
      title: '频谱显示设置',
      icon: $r('app.media.ic_frequency_weighting'),
      description: '平滑、峰值、频率范围',
      category: ToolCategory.DISPLAY_SETTINGS,
      priority: ToolPriority.RECOMMENDED,
      usageHint: '调整频谱图的显示效果',
      learnMore: () => this.showLearnMore('频谱显示'),
      getStatus: () => '可调整',
      getStatusColor: () => $r('sys.color.font_primary'),
      onTap: navigateToSpectrumDisplaySettings
    };
  }

  // 创建警报工具
  createAlertsTool(navigateToAlerts: () => void): ToolConfig {
    return {
      id: 'alerts',
      title: '警报设置',
      icon: $r('app.media.ic_alarm'),
      description: '阈值和通知管理',
      category: ToolCategory.ALERT_SYSTEM,
      priority: ToolPriority.ESSENTIAL,
      usageHint: '及时响应噪声超标',
      learnMore: () => this.showLearnMore('警报系统'),
      getStatus: () => `阈值: ${this.pk.alarm_threshold.currentEffectiveThreshold}dB`,
      getStatusColor: () => $r('sys.color.font_primary'),
      onTap: navigateToAlerts
    };
  }

  // 创建采样率工具
  createSampleRateTool(navigateToSampleRateSettings: () => void, getSampleRateDisplayText: () => string): ToolConfig {
    return {
      id: 'sample_rate',
      title: '采样率设置',
      icon: $r('app.media.ic_frequency_weighting'),
      description: '音频采样率和降采样',
      category: ToolCategory.ADVANCED_SETTINGS,
      priority: ToolPriority.ADVANCED,
      usageHint: '更高采样率提供更精确的分析',
      learnMore: () => this.showLearnMore('采样率'),
      getStatus: () => getSampleRateDisplayText(),
      getStatusColor: () => $r('sys.color.font_primary'),
      onTap: navigateToSampleRateSettings
    };
  }

  // 创建窗函数工具
  createWindowFunctionTool(navigateToWindowFunctionSettings: () => void, getWindowFunctionDisplayName: (windowType: WindowType) => string): ToolConfig {
    return {
      id: 'window_function',
      title: '窗函数设置',
      icon: $r('app.media.ic_filter'),
      description: 'FFT窗函数选择',
      category: ToolCategory.ADVANCED_SETTINGS,
      priority: ToolPriority.ADVANCED,
      usageHint: '不同窗函数适用于不同信号类型',
      learnMore: () => this.showLearnMore('窗函数'),
      getStatus: () => getWindowFunctionDisplayName(this.pk.window_function_type),
      getStatusColor: () => $r('sys.color.font_primary'),
      onTap: navigateToWindowFunctionSettings
    };
  }

  // 创建窗函数参数工具
  createWindowParamsTool(navigateToWindowFunctionParamsSettings: () => void, getWindowParamsDisplayName: () => string): ToolConfig {
    return {
      id: 'window_params',
      title: '窗函数参数',
      icon: $r('app.media.ic_filter'),
      description: '可调窗函数参数',
      category: ToolCategory.ADVANCED_SETTINGS,
      priority: ToolPriority.ADVANCED,
      usageHint: '精细调整窗函数特性',
      learnMore: () => this.showLearnMore('窗函数参数'),
      getStatus: () => getWindowParamsDisplayName(),
      getStatusColor: () => $r('sys.color.font_primary'),
      onTap: navigateToWindowFunctionParamsSettings
    };
  }

  // 显示学习更多内容的通用方法
  private showLearnMore(topic: string): void {
    console.info(`[学习更多] 用户想了解: ${topic}`);
    // 这里可以导入LEARN_MORE_CONTENT并使用
    // TODO: 实现对话框显示或跳转到帮助页面
  }
}