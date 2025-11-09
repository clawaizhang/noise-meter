import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { camera } from '@kit.CameraKit';
import common from '@ohos.app.ability.common';
import { Throttle } from '../../utils/Debounce';
import { WeightingType } from '../../constants/WeightingConstants';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import {
  AudioCalibrationProps,
  AudioCalibrationSettingsBuilder
} from '../../pages/settings/AudioCalibrationNavigation';
import { AlertsSettingsBuilder, AlertsSettingsProps } from '../../pages/settings/AlertsSettingsNavigation';
import {
  FrequencyWeightingDialogBuilder,
  FrequencyWeightingDialogParams,
} from '../frequency-weighting/FrequencyWeightingDialog';
import {
  AutoSaveDialogParams,
  AutoSaveSettings,
  AutoSaveSettingsDialogBuilder,
} from '../auto-save/AutoSaveSettingsDialog';
import {
  TimeWeightingDialogBuilder, TimeWeightingDialogParams,
} from '../time-weighting/TimeWeightingDialog';
import { AudioAnalysisMode } from '../../common/AudioConfig';
import {
  SpectrumDisplaySettingsBuilder,
  SpectrumDisplaySettingsParams,
} from '../decibel-meter/SpectrumDisplaySettingsDialog';
import {
  SpectrumDisplayService,
  SpectrumDisplayConfig
} from '../../services/SpectrumDisplayService';
import { LocationInfo, LocationService } from '../../services/LocationService';
import {
  SampleRateSettingsBuilder,
  SampleRateSettingsParams
} from './SampleRateSettingsDialog';
import { AudioService } from '../../services/AudioService';
import {
  WindowFunctionDialogBuilder,
  WindowFunctionDialogContent,
  WindowFunctionDialogParams,
} from './WindowFunctionDialog';
import {
  WindowFunctionParamsDialogBuilder,
  WindowFunctionParamsDialogParams,
  showWindowFunctionParamsDialog
} from './WindowFunctionParamsDialog';
import { WindowType } from '../../common/WindowType';

// 功能分类枚举
enum ToolCategory {
  BASIC_MEASUREMENT = 'BASIC_MEASUREMENT',    // 基础测量
  DATA_MANAGEMENT = 'DATA_MANAGEMENT',        // 数据管理
  DISPLAY_SETTINGS = 'DISPLAY_SETTINGS',       // 显示设置
  ALERT_SYSTEM = 'ALERT_SYSTEM',             // 警报系统
  ADVANCED_SETTINGS = 'ADVANCED_SETTINGS',     // 高级设置
  SYSTEM_TOOLS = 'SYSTEM_TOOLS'              // 系统工具
}

// 工具功能配置接口
interface ToolConfig {
  id: string;
  title: string;
  icon: Resource;
  description: string;
  category: ToolCategory;
  isAdvanced?: boolean;
  getStatus?: () => string;
  getStatusColor?: () => Resource;
  onTap: () => void;
}

// 功能分类配置接口
interface CategoryConfig {
  title: string;
  icon: Resource;
  description: string;
  color: Resource;
  tools: ToolConfig[];
}

@ComponentV2
export struct ToolsContent {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local isTorchOn: boolean = false;
  @Local private isLocationRefreshing: boolean = false;
  @Local expandedCategories: Set<ToolCategory> = new Set();
  @Local isAdvancedMode: boolean = false;
  @Local animatingCategories: Set<ToolCategory> = new Set();
  @Local hoveredTool: string = '';
  @Local pressedTool: string = '';
  private locationService: LocationService = LocationService.getInstance();

  aboutToAppear(): void {
    // 如果位置服务已开启，自动获取位置
    if (this.pk.location_enabled) {
      this.refreshLocation();
    }
    
    // 默认展开基础测量和数据管理
    this.expandedCategories.add(ToolCategory.BASIC_MEASUREMENT);
    this.expandedCategories.add(ToolCategory.DATA_MANAGEMENT);
  }

  aboutToDisappear(): void {
  }

  // 获取所有功能分类配置
  private getCategories(): CategoryConfig[] {
    const categories: CategoryConfig[] = [
      {
        title: '基础测量',
        icon: $r('app.media.ic_meter'),
        description: '核心测量功能设置',
        color: $r('sys.color.brand'),
        tools: [
          {
            id: 'calibration',
            title: '声级校准',
            icon: $r('app.media.ic_calibration'),
            description: '自动和手动校准',
            category: ToolCategory.BASIC_MEASUREMENT,
            getStatus: () => `当前: ${this.pk.calibration_value}dB`,
            getStatusColor: () => $r('sys.color.font_primary'),
            onTap: (): void => this.navigateToAudioCalibration()
          },
          {
            id: 'frequency_weighting',
            title: '频率加权',
            icon: $r('app.media.ic_frequency_weighting'),
            description: 'A/C/Z计权设置',
            category: ToolCategory.BASIC_MEASUREMENT,
            getStatus: () => this.getWeightingDisplayName(this.pk.weighting_type),
            getStatusColor: () => $r('sys.color.font_primary'),
            onTap: (): void => this.navigateToFrequencyWeighting()
          },
          {
            id: 'audio_analysis_mode',
            title: '音频分析模式',
            icon: $r('app.media.ic_time_weighting'),
            description: '快速/慢速/脉冲',
            category: ToolCategory.BASIC_MEASUREMENT,
            getStatus: () => this.getAnalysisModeDisplayName(this.pk.audio_analysis_mode),
            getStatusColor: () => $r('sys.color.font_primary'),
            onTap: (): void => this.navigateToAudioAnalysisMode()
          }
        ]
      },
      {
        title: '数据管理',
        icon: $r('app.media.ic_save'),
        description: '数据记录和存储设置',
        color: $r('sys.color.confirm'),
        tools: [
          {
            id: 'audio_recording',
            title: '音频记录',
            icon: $r('app.media.ic_mic'),
            description: '保存原始音频',
            category: ToolCategory.DATA_MANAGEMENT,
            getStatus: () => this.pk.record_enabled ? '已开启' : '已关闭',
            getStatusColor: () => this.pk.record_enabled ? $r('sys.color.confirm') : $r('sys.color.font_secondary'),
            onTap: (): void => this.toggleAudioRecording()
          },
          {
            id: 'auto_save',
            title: '自动保存',
            icon: $r('app.media.ic_save'),
            description: '自动保存设置',
            category: ToolCategory.DATA_MANAGEMENT,
            getStatus: () => this.pk.auto_save_enabled ? '已开启' : '已关闭',
            getStatusColor: () => this.pk.auto_save_enabled ? $r('sys.color.confirm') : $r('sys.color.font_secondary'),
            onTap: (): void => this.navigateToAutoSave()
          },
          {
            id: 'location_service',
            title: '位置服务',
            icon: $r('app.media.ic_location'),
            description: '记录位置信息',
            category: ToolCategory.DATA_MANAGEMENT,
            getStatus: () => this.locationStatus,
            getStatusColor: () => this.locationStatusColor,
            onTap: () => this.toggleLocationService()
          }
        ]
      },
      {
        title: '显示设置',
        icon: $r('app.media.ic_frequency_weighting'),
        description: '频谱显示配置',
        color: $r('sys.color.font_emphasize'),
        tools: [
          {
            id: 'spectrum_display',
            title: '频谱显示设置',
            icon: $r('app.media.ic_frequency_weighting'),
            description: '线形图/柱状图/混合模式',
            category: ToolCategory.DISPLAY_SETTINGS,
            getStatus: () => this.getSpectrumDisplayModeText(),
            getStatusColor: () => $r('sys.color.font_primary'),
            onTap: (): void => this.navigateToSpectrumDisplaySettings()
          }
        ]
      },
      {
        title: '警报系统',
        icon: $r('app.media.ic_alarm'),
        description: '阈值和通知管理',
        color: $r('sys.color.warning'),
        tools: [
          {
            id: 'alerts',
            title: '警报设置',
            icon: $r('app.media.ic_alarm'),
            description: '阈值和通知管理',
            category: ToolCategory.ALERT_SYSTEM,
            getStatus: () => `阈值: ${this.pk.alarm_threshold.currentEffectiveThreshold}dB`,
            getStatusColor: () => $r('sys.color.font_primary'),
            onTap: (): void => this.navigateToAlerts()
          }
        ]
      },
      {
        title: '高级设置',
        icon: $r('app.media.ic_filter'),
        description: '专业音频处理设置',
        color: $r('sys.color.font_secondary'),
        tools: [
          {
            id: 'sample_rate',
            title: '采样率设置',
            icon: $r('app.media.ic_frequency_weighting'),
            description: '音频采样率和降采样',
            category: ToolCategory.ADVANCED_SETTINGS,
            isAdvanced: true,
            getStatus: () => this.getSampleRateDisplayText(),
            getStatusColor: () => $r('sys.color.font_primary'),
            onTap: (): void => this.navigateToSampleRateSettings()
          },
          {
            id: 'window_function',
            title: '窗函数设置',
            icon: $r('app.media.ic_filter'),
            description: 'FFT窗函数选择',
            category: ToolCategory.ADVANCED_SETTINGS,
            isAdvanced: true,
            getStatus: () => this.getWindowFunctionDisplayName(this.pk.window_function_type),
            getStatusColor: () => $r('sys.color.font_primary'),
            onTap: (): void => this.navigateToWindowFunctionSettings()
          },
          {
            id: 'window_params',
            title: '窗函数参数',
            icon: $r('app.media.ic_filter'),
            description: '可调窗函数参数',
            category: ToolCategory.ADVANCED_SETTINGS,
            isAdvanced: true,
            getStatus: () => this.getWindowParamsDisplayName(),
            getStatusColor: () => $r('sys.color.font_primary'),
            onTap: (): void => this.navigateToWindowFunctionParamsSettings()
          }
        ]
      },
      {
        title: '系统工具',
        icon: $r('app.media.ic_flashlight_bold'),
        description: '设备辅助功能',
        color: $r('sys.color.font_secondary'),
        tools: [
          {
            id: 'flashlight',
            title: '手电筒',
            icon: $r('app.media.ic_flashlight_bold'),
            description: '开启/关闭手电筒',
            category: ToolCategory.SYSTEM_TOOLS,
            getStatus: () => this.isTorchOn ? '开启' : '关闭',
            getStatusColor: () => this.isTorchOn ? $r('sys.color.confirm') : $r('sys.color.font_secondary'),
            onTap: (): void => this.toggleTorch()
          }
        ]
      }
    ];

    return categories;
  }

  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {
        // 模式切换
        this.buildModeToggle()

        // 功能分类列表 - 根据模式过滤
        ForEach(this.getCategories().filter(category => {
          // 在基础模式下，隐藏高级设置分类
          if (!this.isAdvancedMode && category.title === '高级设置') {
            return false;
          }
          return true;
        }), (category: CategoryConfig) => {
          this.buildCategorySection(category)
        })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .padding(DesignConstants.SPACING_MD)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  private buildModeToggle() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 模式切换按钮
      Row({ space: DesignConstants.SPACING_MD }) {
        Column() {
          Text('基础模式')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor(!this.isAdvancedMode ? $r('sys.color.background_secondary') : $r('sys.color.font_secondary'))
            .fontWeight(!this.isAdvancedMode ? FontWeight.Medium : FontWeight.Normal)
            .animation({
              duration: DesignConstants.ANIMATION_DURATION_SM,
              curve: Curve.EaseInOut
            })
        }
        .layoutWeight(1)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(!this.isAdvancedMode ? $r('sys.color.brand') : $r('sys.color.comp_background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_SM)
        .onClick(() => {
          this.isAdvancedMode = false;
        })
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_SM,
          curve: Curve.EaseInOut
        })

        Column() {
          Text('专业模式')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor(this.isAdvancedMode ? $r('sys.color.background_secondary') : $r('sys.color.font_secondary'))
            .fontWeight(this.isAdvancedMode ? FontWeight.Medium : FontWeight.Normal)
            .animation({
              duration: DesignConstants.ANIMATION_DURATION_SM,
              curve: Curve.EaseInOut
            })
        }
        .layoutWeight(1)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.isAdvancedMode ? $r('sys.color.brand') : $r('sys.color.comp_background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_SM)
        .onClick(() => {
          this.isAdvancedMode = true;
        })
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_SM,
          curve: Curve.EaseInOut
        })
      }
      .width('100%')
      .height(40)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .padding(2)
      
      // 模式说明
      Column({ space: DesignConstants.SPACING_XS }) {
        Text(this.isAdvancedMode ? '专业模式：显示所有高级音频处理功能' : '基础模式：显示常用核心功能')
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_secondary'))
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ top: DesignConstants.SPACING_XS })
      .animation({
        duration: DesignConstants.ANIMATION_DURATION_SM,
        curve: Curve.EaseInOut
      })
    }
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .margin({ bottom: DesignConstants.SPACING_MD })
    .padding(DesignConstants.SPACING_MD)
  }

  @Builder
  private buildCategorySection(category: CategoryConfig) {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 分类标题
      this.buildCategoryHeader(category)

      // 分类内容 - 使用动画展开/收起
      if (this.expandedCategories.has(category.tools[0].category)) {
        Column({ space: DesignConstants.SPACING_SM }) {
          ForEach(category.tools, (tool: ToolConfig) => {
            // 根据模式过滤高级功能
            if (!tool.isAdvanced || this.isAdvancedMode) {
              this.buildToolCard(tool)
            }
          })
        }
        .width('100%')
        .margin({ top: DesignConstants.SPACING_SM })
        .opacity(this.animatingCategories.has(category.tools[0].category) ? 0 : 1)
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_MD,
          curve: Curve.EaseInOut,
          delay: this.animatingCategories.has(category.tools[0].category) ? 0 : 50
        })
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_SM)
  }

  @Builder
  private buildCategoryHeader(category: CategoryConfig) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 分类图标
      Image(category.icon)
        .width(24)
        .height(24)
        .fillColor(category.color)
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_SM,
          curve: Curve.EaseInOut
        })

      // 分类信息
      Column({ space: DesignConstants.SPACING_XS }) {
        Row() {
          Text(category.title)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))

          // 高级标识
          if (category.title === '高级设置') {
            Text('PRO')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.background_secondary'))
              .backgroundColor(category.color)
              .borderRadius(DesignConstants.BORDER_RADIUS_XS)
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })
              .margin({ left: DesignConstants.SPACING_XS })
              .animation({
                duration: DesignConstants.ANIMATION_DURATION_SM,
                curve: Curve.EaseInOut
              })
          }

          Blank()
        }
        .width('100%')

        Text(category.description)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 展开指示器 - 带动画
      Image($r('sys.media.ohos_ic_public_arrow_down'))
        .width(16)
        .height(16)
        .fillColor($r('sys.color.font_secondary'))
        .rotate({
          angle: this.expandedCategories.has(category.tools[0].category) ? 180 : 0
        })
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_SM,
          curve: Curve.EaseInOut
        })
    }
    .width('100%')
    .padding({ top: DesignConstants.SPACING_SM, bottom: DesignConstants.SPACING_SM })
    .onClick(() => {
      this.toggleCategory(category.tools[0].category)
    })
    .gesture(
      TapGesture()
        .onAction(() => {
          // 添加触觉反馈效果
          this.animateCategoryPress(category.tools[0].category);
        })
    )
  }

  @Builder
  private buildToolCard(tool: ToolConfig) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标区域
      Image(tool.icon)
        .width(24)
        .height(24)
        .fillColor(this.hoveredTool === tool.id ? $r('sys.color.brand') : $r('sys.color.icon_primary'))
        .scale({ x: this.pressedTool === tool.id ? 0.9 : 1.0, y: this.pressedTool === tool.id ? 0.9 : 1.0 })
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_XS,
          curve: Curve.EaseInOut
        })

      // 右侧内容区域
      Column({ space: DesignConstants.SPACING_XS }) {
        // 标题行
        Row() {
          Text(tool.title)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.hoveredTool === tool.id ? $r('sys.color.brand') : $r('sys.color.font_primary'))
            .animation({
              duration: DesignConstants.ANIMATION_DURATION_XS,
              curve: Curve.EaseInOut
            })

          Blank()
        }
        .width('100%')

        // 描述和状态行
        Row() {
          Text(tool.description)
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)

          if (tool.getStatus && tool.getStatusColor) {
            Text(tool.getStatus())
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontWeight(FontWeight.Medium)
              .fontColor(tool.getStatusColor())
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(60)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor(this.pressedTool === tool.id ? $r('sys.color.comp_background_emphasize') :
                   this.hoveredTool === tool.id ? $r('sys.color.comp_background_secondary') :
                   $r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .shadow(this.hoveredTool === tool.id ? DesignConstants.SHADOW_MD : DesignConstants.SHADOW_SM)
    .animation({
      duration: DesignConstants.ANIMATION_DURATION_XS,
      curve: Curve.EaseInOut
    })
    .onClick(() => {
      Throttle.click(() => {
        tool.onTap()
      });
    })
    .onHover((isHovered: boolean) => {
      this.hoveredTool = isHovered ? tool.id : '';
    })
  }

  // 切换分类展开状态
  private toggleCategory(category: ToolCategory): void {
    // 添加动画状态
    this.animatingCategories.add(category);
    
    if (this.expandedCategories.has(category)) {
      this.expandedCategories.delete(category);
    } else {
      this.expandedCategories.add(category);
    }
    
    // 延迟清除动画状态
    setTimeout(() => {
      this.animatingCategories.delete(category);
    }, DesignConstants.ANIMATION_DURATION_MD);
  }
  
  // 分类按压动画效果
  private animateCategoryPress(category: ToolCategory): void {
    // 可以在这里添加更复杂的动画效果
  }

  // 导航到声级校准设置
  private navigateToAudioCalibration = () => {
    let calibrationDialog: InfSheet;
    let props: AudioCalibrationProps = {
      onSave: () => {
        calibrationDialog.dismiss();
      },
      onClose: () => {
        calibrationDialog.dismiss();
      }
    }
    calibrationDialog = DialogHub.getSheet()
      .setStyle({ showClose: false, backgroundColor: $r('sys.color.background_secondary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(AudioCalibrationSettingsBuilder), props)
      .build();
    calibrationDialog.show();
  }

  // 导航到警报与通知设置
  private navigateToAlerts = () => {
    let alertsDialog: InfSheet;
    let props: AlertsSettingsProps = {
      onSave: () => {
        alertsDialog.dismiss();
      },
      onClose: () => {
        alertsDialog.dismiss();
      }
    }
    alertsDialog = DialogHub.getSheet()
      .setStyle({ showClose: false, backgroundColor: $r('sys.color.background_secondary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(AlertsSettingsBuilder), props)
      .build();
    alertsDialog.show();
  }

  // 导航到频率加权设置
  private navigateToFrequencyWeighting = () => {
    let frequencyDialog: InfSheet;
    let param: FrequencyWeightingDialogParams = {
      currentWeighting: this.pk.weighting_type,
      onSettingsApplied: (selectedWeighting: WeightingType) => {
        // 即时生效：立即应用新设置
        this.pk.weighting_type = selectedWeighting;
      },
      onClose: () => {
        frequencyDialog?.dismiss();
      }
    }
    frequencyDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(FrequencyWeightingDialogBuilder), param)
      .build();

    frequencyDialog.show();
  }

  // 导航到自动保存设置
  private navigateToAutoSave = () => {
    let autoSaveDialog: InfSheet;
    let param: AutoSaveDialogParams = {
      onClose: () => {
        autoSaveDialog?.dismiss();
      },
      onSettingsApplied: (settings: AutoSaveSettings) => {
        // 应用设置并显示统一提示
        this.applyAutoSaveSettings(settings);
      }
    }
    autoSaveDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(AutoSaveSettingsDialogBuilder), param)
      .build();

    autoSaveDialog.show();
  }

  // 应用自动保存设置
  private applyAutoSaveSettings(settings: AutoSaveSettings) {
    // 更新持久化存储
    this.pk.auto_save_enabled = settings.enabled;
    this.pk.auto_save_interval = settings.interval;
  }
  
  // 应用频谱显示设置
  private applySpectrumDisplaySettings(config: SpectrumDisplayConfig) {
    // 使用SpectrumDisplayService应用配置
    const spectrumDisplayService = SpectrumDisplayService.getInstance();
    spectrumDisplayService.applyDisplayConfig(this.pk, config);
  }

  // 获取计权类型显示名称
  private getWeightingDisplayName(weighting: WeightingType): string {
    switch (weighting) {
      case WeightingType.A:
        return 'A计权';
      case WeightingType.C:
        return 'C计权';
      case WeightingType.Z:
        return 'Z计权';
      default:
        return 'A计权';
    }
  }

  // 手电筒切换功能
  private toggleTorch() {
    Throttle.click(() => {
      let cameraManager: camera.CameraManager = camera.getCameraManager(getContext(this) as common.UIAbilityContext);
      if (cameraManager.isTorchSupported()) {
        cameraManager.setTorchMode(this.isTorchOn ? camera.TorchMode.OFF : camera.TorchMode.ON);
        this.isTorchOn = !this.isTorchOn;
      }
    })
  }

  // 导航到音频分析模式设置
  private navigateToAudioAnalysisMode = () => {
    let audioAnalysisDialog: InfSheet;
    let param: TimeWeightingDialogParams = {
      currentMode: this.pk.audio_analysis_mode,
      onSettingsApplied: (selectedMode: AudioAnalysisMode) => {
        // 即时生效：立即应用新设置
        this.pk.audio_analysis_mode = selectedMode;
      },
      onClose: () => {
        audioAnalysisDialog?.dismiss();
      }
    }
    audioAnalysisDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(TimeWeightingDialogBuilder), param)
      .build();

    audioAnalysisDialog.show();
  }

  // 音频记录开关切换
  private toggleAudioRecording() {
    Throttle.click(() => {
      this.pk.record_enabled = !this.pk.record_enabled;
    })
  }

  // 获取音频分析模式显示名称
  private getAnalysisModeDisplayName(mode: AudioAnalysisMode): string {
    switch (mode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        return '快速(F)';
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        return '慢速(S)';
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        return '脉冲(I)';
      default:
        return '自定义模式';
    }
  }

  // 位置状态计算属性 - 操作台只显示开启/关闭状态
  @Computed
  get locationStatus(): string {
    return this.pk.location_enabled ? '已开启' : '已关闭';
  }

  @Computed
  get locationStatusColor(): Resource {
    return this.pk.location_enabled ? $r('sys.color.confirm') : $r('sys.color.font_secondary');
  }

  // 位置服务开关方法
  private toggleLocationService(): void {
    Throttle.click(() => {
      this.pk.location_enabled = !this.pk.location_enabled;
      // 如果开启位置服务，自动获取位置
      if (this.pk.location_enabled) {
        this.refreshLocation();
      } else {
      }
    });
  }

  // 刷新位置信息方法
  private async refreshLocation(): Promise<void> {
    if (!this.pk.location_enabled || this.isLocationRefreshing) {
      return;
    }

    try {
      this.isLocationRefreshing = true;

      // 检查定位服务是否开启
      const isServiceEnabled = this.locationService.checkLocationEnabled();
      if (!isServiceEnabled) {
        return;
      }

      // 检查定位权限
      const hasPermission = await this.locationService.requestLocationPermission();
      if (!hasPermission) {
        this.pk.location_enabled = false;
        return;
      }

      // 获取位置信息
      const locationInfo: LocationInfo = await this.locationService.requestSingleLocation();
    } catch (error) {
      console.error('获取位置信息失败:', error);
    } finally {
      this.isLocationRefreshing = false;
    }
  }

  // 导航到频谱显示设置
  private navigateToSpectrumDisplaySettings = () => {
    let spectrumDialog: InfSheet;
    let param: SpectrumDisplaySettingsParams = {
      onClose: () => {
        spectrumDialog?.dismiss();
      },
      onSettingsApplied: (config: SpectrumDisplayConfig) => {
        // 应用频谱显示设置
        this.applySpectrumDisplaySettings(config);
      },
    }
    spectrumDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(SpectrumDisplaySettingsBuilder), param)
      .build();

    spectrumDialog.show();
  }

  // 获取频谱显示模式显示名称
  private getSpectrumDisplayModeText(): string {
    switch (this.pk.spectrum_display_mode) {
      case 'line':
        return '线形图';
      case 'bar':
        return '柱状图';
      case 'hybrid':
        return '混合模式';
      default:
        return '线形图';
    }
  }

  // 监听位置服务开关变化
  @Monitor('pk.location_enabled')
  onLocationEnabledChange(monitor: IMonitor) {
    const beforeEnabled = monitor.value<boolean>()?.before;
    const newEnabled = monitor.value<boolean>()?.now;
    if (newEnabled !== beforeEnabled) {
      if (newEnabled) {
        // 开启时自动刷新位置
        this.refreshLocation();
      } else {
      }
    }
  }

  // 导航到采样率设置
  private navigateToSampleRateSettings = () => {
    let sampleRateDialog: InfSheet;
    let param: SampleRateSettingsParams = {
      onClose: () => {
        sampleRateDialog?.dismiss();
      },
      onSettingsApplied: async (sampleRate: number, decimationEnabled: boolean, decimationFactor: number) => {
        // 应用采样率设置
        await this.applySampleRateSettings(sampleRate, decimationEnabled, decimationFactor);
      }
    }
    sampleRateDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(SampleRateSettingsBuilder), param)
      .build();

    sampleRateDialog.show();
  }

  // 应用采样率设置
  private async applySampleRateSettings(sampleRate: number, decimationEnabled: boolean, decimationFactor: number): Promise<void> {
    // 更新持久化存储
    this.pk.audio_sample_rate = sampleRate;
    this.pk.audio_decimation_enabled = decimationEnabled;
    this.pk.audio_decimation_factor = decimationFactor;
    
    // 应用到AudioService
    const audioService = AudioService.getInstance(this.pk);
    await audioService.applySampleRateSettings(sampleRate, decimationEnabled, decimationFactor);
    
    console.info(`[采样率设置] 已应用: 采样率=${sampleRate}Hz, 降采样启用=${decimationEnabled}, 降采样因子=${decimationFactor}`);
  }

  // 获取采样率显示文本
  private getSampleRateDisplayText(): string {
    const sampleRateText = `${(this.pk.audio_sample_rate / 1000).toFixed(1)}kHz`;
    
    if (this.pk.audio_decimation_enabled && this.pk.audio_decimation_factor > 1) {
      // 计算降采样指数
      const decimationExponent = Math.round(Math.log2(this.pk.audio_decimation_factor));
      return `${sampleRateText} (降采样${decimationExponent}级/${this.pk.audio_decimation_factor}倍)`;
    } else {
      return sampleRateText;
    }
  }

  // 导航到窗函数设置
  private navigateToWindowFunctionSettings = () => {
    let windowFunctionDialog: InfSheet;
    let param: WindowFunctionDialogParams = {
      currentWindowType: this.pk.window_function_type,
      onSettingsApplied: async (selectedWindowType: WindowType) => {
        // 即时生效：立即应用新设置
        this.pk.window_function_type = selectedWindowType;
        
        // 应用到AudioService
        const audioService = AudioService.getInstance(this.pk);
        await audioService.applyWindowFunctionSettings(
          selectedWindowType,
          this.pk.window_kaiser_beta,
          this.pk.window_gaussian_sigma,
          this.pk.window_tukey_alpha,
          this.pk.window_chebyshev_attenuation
        );
        
        console.info(`[窗函数设置] 已应用: 窗函数类型=${selectedWindowType}`);
      },
      onClose: () => {
        windowFunctionDialog?.dismiss();
      }
    }
    windowFunctionDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.comp_background_primary'),
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(WindowFunctionDialogContent), param)
      .build();
    windowFunctionDialog.show();
  }

  // 获取窗函数显示名称
  private getWindowFunctionDisplayName(windowType: WindowType): string {
    switch (windowType) {
      case WindowType.HANNING:
        return '汉宁窗';
      case WindowType.BLACKMAN:
        return '布莱克曼窗';
      case WindowType.HAMMING:
        return '汉明窗';
      case WindowType.BARTLETT:
        return '巴特利特窗';
      case WindowType.KAISER:
        return '凯泽窗';
      case WindowType.FLATTOP:
        return '平顶窗';
      case WindowType.TRIANGULAR:
        return '三角窗';
      case WindowType.WELCH:
        return '韦尔奇窗';
      case WindowType.SINE:
        return '正弦窗';
      case WindowType.GAUSSIAN:
        return '高斯窗';
      case WindowType.TUKEY:
        return '图基窗';
      case WindowType.CHEBYSHEV:
        return '切比雪夫窗';
      default:
        return '汉宁窗';
    }
  }

  // 获取窗函数参数显示名称
  private getWindowParamsDisplayName(): string {
    switch (this.pk.window_function_type) {
      case WindowType.KAISER:
        return `Beta=${this.pk.window_kaiser_beta.toFixed(1)}`;
      case WindowType.GAUSSIAN:
        return `Sigma=${this.pk.window_gaussian_sigma.toFixed(2)}`;
      case WindowType.TUKEY:
        return `Alpha=${this.pk.window_tukey_alpha.toFixed(2)}`;
      case WindowType.CHEBYSHEV:
        return `${this.pk.window_chebyshev_attenuation.toFixed(0)}dB`;
      default:
        return '固定参数';
    }
  }

  // 导航到窗函数参数设置
  private navigateToWindowFunctionParamsSettings = () => {
    let windowFunctionParamsDialog: InfSheet;
    let param: WindowFunctionParamsDialogParams = {
      currentWindowType: this.pk.window_function_type,
      currentKaiserBeta: this.pk.window_kaiser_beta,
      currentGaussianSigma: this.pk.window_gaussian_sigma,
      currentTukeyAlpha: this.pk.window_tukey_alpha,
      currentChebyshevAttenuation: this.pk.window_chebyshev_attenuation,
      onSettingsApplied: async (windowType: WindowType, kaiserBeta?: number, gaussianSigma?: number,
        tukeyAlpha?: number, chebyshevAttenuation?: number) => {
        // 即时生效：立即应用新设置
        this.pk.window_function_type = windowType;
        if (kaiserBeta !== undefined) {
          this.pk.window_kaiser_beta = kaiserBeta;
        }
        if (gaussianSigma !== undefined) {
          this.pk.window_gaussian_sigma = gaussianSigma;
        }
        if (tukeyAlpha !== undefined) {
          this.pk.window_tukey_alpha = tukeyAlpha;
        }
        if (chebyshevAttenuation !== undefined) {
          this.pk.window_chebyshev_attenuation = chebyshevAttenuation;
        }

        // 应用到AudioService
        const audioService = AudioService.getInstance(this.pk);
        await audioService.applyWindowFunctionSettings(
          windowType,
          this.pk.window_kaiser_beta,
          this.pk.window_gaussian_sigma,
          this.pk.window_tukey_alpha,
          this.pk.window_chebyshev_attenuation
        );

        console.info(`[窗函数参数设置] 已应用: 窗函数类型=${windowType}, KaiserBeta=${this.pk.window_kaiser_beta}, GaussianSigma=${this.pk.window_gaussian_sigma}, TukeyAlpha=${this.pk.window_tukey_alpha}, ChebyshevAttenuation=${this.pk.window_chebyshev_attenuation}`);
      },
      onClose: () => {
        windowFunctionParamsDialog?.dismiss();
      }
    }
    windowFunctionParamsDialog = showWindowFunctionParamsDialog(param);
    windowFunctionParamsDialog.show();
  }
}