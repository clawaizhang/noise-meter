import { AudioAnalysisMode } from "../../common/AudioConfig";
import { WeightingType } from "../../constants/WeightingConstants";
import { AppKeys } from "../../models/AppKeys";
import { PreferenceKeys } from "../../models/PreferenceKeys";
import { WindowType } from "../../common/WindowType";
import { ToolConfig, ToolCategory, ToolPriority } from "./ToolsContent";
import { EnhancedDesignConstants, UserSkillLevel } from "../../constants/EnhancedDesignConstants";

// 场景枚举
export enum MeasurementScene {
  INDOOR = 'INDOOR',           // 室内环境
  OUTDOOR = 'OUTDOOR',         // 室外环境
  INDUSTRIAL = 'INDUSTRIAL',   // 工业环境
  RESIDENTIAL = 'RESIDENTIAL', // 住宅环境
  TRAFFIC = 'TRAFFIC',         // 交通环境
  CUSTOM = 'CUSTOM'            // 自定义
}

// 场景配置接口
export interface SceneConfig {
  id: MeasurementScene;
  title: string;
  description: string;
  icon: Resource;
  color: Resource;
  recommendedTools: string[];
  quickSettings: {
    weighting?: WeightingType;
    analysisMode?: AudioAnalysisMode;
    threshold?: number;
    sampleRate?: number;
  };
}

// 增强版工具配置接口
export interface EnhancedToolConfig extends ToolConfig {
  scene?: MeasurementScene;
  quickSetup?: () => void;
  isLocked?: boolean;
  unlockCondition?: string;
  usageFrequency?: number; // 使用频率 0-1
  lastUsed?: Date;
  progress?: number; // 配置完成度 0-1
}

// 增强版工具创建工厂类
export class EnhancedToolConfigFactory {
  private pk: PreferenceKeys;
  private ak: AppKeys;

  constructor(pk: PreferenceKeys, ak: AppKeys) {
    this.pk = pk;
    this.ak = ak;
  }

  // 获取所有场景配置
  getSceneConfigs(): SceneConfig[] {
    return [
      {
        id: MeasurementScene.INDOOR,
        title: '室内环境',
        description: '家庭、办公室、教室等室内空间',
        icon: $r('app.media.ic_scene_indoor'),
        color: EnhancedDesignConstants.COLOR_SCENE_INDOOR,
        recommendedTools: ['calibration', 'frequency_weighting', 'auto_save'],
        quickSettings: {
          weighting: WeightingType.A,
          analysisMode: AudioAnalysisMode.SLOW_TIME_WEIGHTING,
          threshold: 55
        }
      },
      {
        id: MeasurementScene.OUTDOOR,
        title: '室外环境',
        description: '公园、广场、街道等室外空间',
        icon: $r('app.media.ic_scene_outdoor'),
        color: EnhancedDesignConstants.COLOR_SCENE_OUTDOOR,
        recommendedTools: ['calibration', 'frequency_weighting', 'location_service'],
        quickSettings: {
          weighting: WeightingType.A,
          analysisMode: AudioAnalysisMode.FAST_TIME_WEIGHTING,
          threshold: 70
        }
      },
      {
        id: MeasurementScene.INDUSTRIAL,
        title: '工业环境',
        description: '工厂、车间、建筑工地等工业场所',
        icon: $r('app.media.ic_scene_industrial'),
        color: EnhancedDesignConstants.COLOR_SCENE_INDUSTRIAL,
        recommendedTools: ['calibration', 'frequency_weighting', 'alerts', 'sample_rate'],
        quickSettings: {
          weighting: WeightingType.C,
          analysisMode: AudioAnalysisMode.FAST_TIME_WEIGHTING,
          threshold: 85,
          sampleRate: 48000
        }
      },
      {
        id: MeasurementScene.RESIDENTIAL,
        title: '住宅环境',
        description: '居民区、公寓楼等居住空间',
        icon: $r('app.media.ic_scene_residential'),
        color: EnhancedDesignConstants.COLOR_SCENE_INDOOR,
        recommendedTools: ['calibration', 'frequency_weighting', 'alerts'],
        quickSettings: {
          weighting: WeightingType.A,
          analysisMode: AudioAnalysisMode.SLOW_TIME_WEIGHTING,
          threshold: 60
        }
      },
      {
        id: MeasurementScene.TRAFFIC,
        title: '交通环境',
        description: '道路、桥梁、隧道等交通设施',
        icon: $r('app.media.ic_scene_traffic'),
        color: EnhancedDesignConstants.COLOR_SCENE_OUTDOOR,
        recommendedTools: ['calibration', 'frequency_weighting', 'location_service', 'auto_save'],
        quickSettings: {
          weighting: WeightingType.A,
          analysisMode: AudioAnalysisMode.FAST_TIME_WEIGHTING,
          threshold: 75
        }
      }
    ];
  }

  // 创建增强版校准工具
  createEnhancedCalibrationTool(navigateToAudioCalibration: () => void, userSkillLevel: UserSkillLevel): EnhancedToolConfig {
    return {
      id: 'calibration',
      title: '声级校准',
      icon: $r('app.media.ic_calibration'),
      description: userSkillLevel === UserSkillLevel.BEGINNER ? '确保测量精度的基础步骤' : '自动和手动校准',
      category: ToolCategory.BASIC_MEASUREMENT,
      priority: ToolPriority.ESSENTIAL,
      scene: MeasurementScene.INDOOR,
      usageHint: userSkillLevel === UserSkillLevel.BEGINNER ? '首次使用必须进行校准' : '定期校准保证测量准确性',
      learnMore: () => this.showLearnMore('校准'),
      getStatus: () => `当前: ${this.pk.calibration_value}dB`,
      getStatusColor: () => this.getCalibrationStatusColor(),
      onTap: navigateToAudioCalibration,
      quickSetup: () => this.quickCalibration(),
      usageFrequency: 0.9,
      progress: this.pk.calibration_value > 0 ? 1.0 : 0.0
    };
  }

  // 创建增强版频率加权工具
  createEnhancedFrequencyWeightingTool(
    navigateToFrequencyWeighting: () => void, 
    getWeightingDisplayName: (weighting: WeightingType) => string,
    userSkillLevel: UserSkillLevel
  ): EnhancedToolConfig {
    return {
      id: 'frequency_weighting',
      title: '频率加权',
      icon: $r('app.media.ic_frequency_weighting'),
      description: userSkillLevel === UserSkillLevel.BEGINNER ? '选择适合的测量模式' : 'A/C/Z计权设置',
      category: ToolCategory.BASIC_MEASUREMENT,
      priority: ToolPriority.ESSENTIAL,
      scene: MeasurementScene.INDOOR,
      usageHint: this.getFrequencyWeightingHint(userSkillLevel),
      learnMore: () => this.showLearnMore('频率加权'),
      getStatus: () => getWeightingDisplayName(this.pk.weighting_type),
      getStatusColor: () => $r('sys.color.font_primary'),
      onTap: navigateToFrequencyWeighting,
      quickSetup: () => this.quickFrequencyWeighting(),
      usageFrequency: 0.8,
      progress: 1.0
    };
  }

  // 创建增强版音频分析模式工具
  createEnhancedAudioAnalysisModeTool(
    navigateToAudioAnalysisMode: () => void, 
    getAnalysisModeDisplayName: (mode: AudioAnalysisMode) => string,
    userSkillLevel: UserSkillLevel
  ): EnhancedToolConfig {
    return {
      id: 'audio_analysis_mode',
      title: '时间加权',
      icon: $r('app.media.ic_time_weighting'),
      description: userSkillLevel === UserSkillLevel.BEGINNER ? '测量响应速度设置' : '快速/慢速/脉冲',
      category: ToolCategory.BASIC_MEASUREMENT,
      priority: ToolPriority.RECOMMENDED,
      usageHint: this.getTimeWeightingHint(userSkillLevel),
      learnMore: () => this.showLearnMore('时间加权'),
      getStatus: () => getAnalysisModeDisplayName(this.pk.audio_analysis_mode),
      getStatusColor: () => $r('sys.color.font_primary'),
      onTap: navigateToAudioAnalysisMode,
      quickSetup: () => this.quickTimeWeighting(),
      usageFrequency: 0.6,
      progress: 1.0
    };
  }

  // 创建增强版警报工具
  createEnhancedAlertsTool(
    navigateToAlerts: () => void,
    userSkillLevel: UserSkillLevel
  ): EnhancedToolConfig {
    return {
      id: 'alerts',
      title: '警报系统',
      icon: $r('app.media.ic_alarm'),
      description: userSkillLevel === UserSkillLevel.BEGINNER ? '噪声超标提醒' : '阈值和通知管理',
      category: ToolCategory.ALERT_SYSTEM,
      priority: ToolPriority.ESSENTIAL,
      usageHint: this.getAlertsHint(userSkillLevel),
      learnMore: () => this.showLearnMore('警报系统'),
      getStatus: () => `阈值: ${this.pk.alarm_threshold.currentEffectiveThreshold}dB`,
      getStatusColor: () => this.getAlertStatusColor(),
      onTap: navigateToAlerts,
      quickSetup: () => this.quickAlertSetup(),
      usageFrequency: 0.7,
      progress: this.pk.alarm_threshold.currentEffectiveThreshold > 0 ? 1.0 : 0.3
    };
  }

  // 创建增强版采样率工具
  createEnhancedSampleRateTool(
    navigateToSampleRateSettings: () => void, 
    getSampleRateDisplayText: () => string,
    userSkillLevel: UserSkillLevel
  ): EnhancedToolConfig {
    const isLocked = userSkillLevel === UserSkillLevel.BEGINNER;
    
    return {
      id: 'sample_rate',
      title: '采样率设置',
      icon: $r('app.media.ic_frequency_weighting'),
      description: isLocked ? '专业功能' : '音频采样率和降采样',
      category: ToolCategory.ADVANCED_SETTINGS,
      priority: ToolPriority.ADVANCED,
      usageHint: isLocked ? '升级后可使用' : '更高采样率提供更精确的分析',
      learnMore: isLocked ? undefined : () => this.showLearnMore('采样率'),
      getStatus: () => isLocked ? '未解锁' : getSampleRateDisplayText(),
      getStatusColor: () => isLocked ? EnhancedDesignConstants.COLOR_LOCKED : $r('sys.color.font_primary'),
      onTap: isLocked ? () => this.showUnlockDialog('采样率设置') : navigateToSampleRateSettings,
      isLocked: isLocked,
      unlockCondition: '提升用户等级至中级',
      usageFrequency: isLocked ? 0.0 : 0.4,
      progress: isLocked ? 0.0 : 1.0
    };
  }

  // 创建快速设置工具
  createQuickSetupTool(
    applySceneSettings: (scene: MeasurementScene) => void,
    currentScene: MeasurementScene
  ): EnhancedToolConfig {
    const sceneConfig = this.getSceneConfigs().find(s => s.id === currentScene);
    
    return {
      id: 'quick_setup',
      title: '快速设置',
      icon: $r('app.media.ic_quick_setup'),
      description: sceneConfig ? `应用${sceneConfig.title}最佳配置` : '一键应用推荐设置',
      category: ToolCategory.BASIC_MEASUREMENT,
      priority: ToolPriority.ESSENTIAL,
      usageHint: '根据场景自动优化参数',
      learnMore: () => this.showLearnMore('快速设置'),
      getStatus: () => sceneConfig ? sceneConfig.title : '未选择场景',
      getStatusColor: () => sceneConfig ? sceneConfig.color : $r('sys.color.font_secondary'),
      onTap: () => applySceneSettings(currentScene),
      quickSetup: () => applySceneSettings(currentScene),
      usageFrequency: 0.9,
      progress: currentScene !== MeasurementScene.CUSTOM ? 1.0 : 0.0
    };
  }

  // 创建场景选择工具
  createSceneSelectorTool(
    selectScene: (scene: MeasurementScene) => void,
    currentScene: MeasurementScene
  ): EnhancedToolConfig {
    const sceneConfig = this.getSceneConfigs().find(s => s.id === currentScene);
    
    return {
      id: 'scene_selector',
      title: '测量场景',
      icon: $r('app.media.ic_scene_selector'),
      description: '选择当前测量环境',
      category: ToolCategory.BASIC_MEASUREMENT,
      priority: ToolPriority.ESSENTIAL,
      usageHint: '不同场景有不同推荐设置',
      learnMore: () => this.showLearnMore('测量场景'),
      getStatus: () => sceneConfig ? sceneConfig.title : '未选择',
      getStatusColor: () => sceneConfig ? sceneConfig.color : $r('sys.color.font_secondary'),
      onTap: () => this.showSceneSelector(selectScene, currentScene),
      usageFrequency: 0.8,
      progress: currentScene !== MeasurementScene.CUSTOM ? 1.0 : 0.5
    };
  }

  // 私有辅助方法

  private getCalibrationStatusColor(): Resource {
    if (this.pk.calibration_value <= 0) {
      return $r('sys.color.warning');
    }
    return $r('sys.color.confirm');
  }

  private getAlertStatusColor(): Resource {
    if (this.pk.alarm_threshold.currentEffectiveThreshold <= 0) {
      return $r('sys.color.warning');
    }
    return $r('sys.color.confirm');
  }

  private getFrequencyWeightingHint(userSkillLevel: UserSkillLevel): string {
    switch (userSkillLevel) {
      case UserSkillLevel.BEGINNER:
        return 'A计权适用于大多数情况';
      case UserSkillLevel.INTERMEDIATE:
        return '不同计权适用于不同噪声类型';
      case UserSkillLevel.EXPERT:
        return '可自定义计权曲线';
      default:
        return 'A计权适用于环境噪声测量';
    }
  }

  private getTimeWeightingHint(userSkillLevel: UserSkillLevel): string {
    switch (userSkillLevel) {
      case UserSkillLevel.BEGINNER:
        return '慢速模式更稳定';
      case UserSkillLevel.INTERMEDIATE:
        return '快速模式捕捉瞬时变化';
      case UserSkillLevel.EXPERT:
        return '脉冲模式测量冲击噪声';
      default:
        return '快速模式适用于实时测量';
    }
  }

  private getAlertsHint(userSkillLevel: UserSkillLevel): string {
    switch (userSkillLevel) {
      case UserSkillLevel.BEGINNER:
        return '设置安全阈值提醒';
      case UserSkillLevel.INTERMEDIATE:
        return '可设置多级警报';
      case UserSkillLevel.EXPERT:
        return '支持自定义警报逻辑';
      default:
        return '及时响应噪声超标';
    }
  }

  // 快速设置方法
  private quickCalibration(): void {
    console.info('[快速设置] 应用默认校准值');
    // 实现快速校准逻辑
  }

  private quickFrequencyWeighting(): void {
    console.info('[快速设置] 应用A计权');
    this.pk.weighting_type = WeightingType.A;
  }

  private quickTimeWeighting(): void {
    console.info('[快速设置] 应用慢速时间加权');
    this.pk.audio_analysis_mode = AudioAnalysisMode.SLOW_TIME_WEIGHTING;
  }

  private quickAlertSetup(): void {
    console.info('[快速设置] 应用默认警报阈值');
    this.pk.alarm_threshold.currentEffectiveThreshold = 70;
  }

  // 显示学习更多内容的通用方法
  private showLearnMore(topic: string): void {
    console.info(`[学习更多] 用户想了解: ${topic}`);
    // TODO: 实现增强版帮助系统
  }

  // 显示解锁对话框
  private showUnlockDialog(feature: string): void {
    console.info(`[解锁功能] 用户尝试解锁: ${feature}`);
    // TODO: 实现功能解锁对话框
  }

  // 显示场景选择器
  private showSceneSelector(selectScene: (scene: MeasurementScene) => void, currentScene: MeasurementScene): void {
    console.info(`[场景选择] 当前场景: ${currentScene}`);
    // TODO: 实现场景选择器对话框
  }
}