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
import { LocationInfo, LocationService } from '../../services/LocationService';

// 工具功能卡片配置
interface ToolCardConfig {
  title: string;
  icon: Resource;
  description: string;
  status?: string;
  statusColor?: Resource;
  onTap: () => void;
}


@ComponentV2
export struct ToolsContent {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local isTorchOn: boolean = false;
  @Local private isLocationRefreshing: boolean = false;
  private locationService: LocationService = LocationService.getInstance();

  aboutToAppear(): void {
    // 如果位置服务已开启，自动获取位置
    if (this.pk.location_enabled) {
      this.refreshLocation();
    }
  }

  aboutToDisappear(): void {
  }



  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {

        // 工具功能卡片区
        this.buildToolsCards()
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
  private buildPageHeader() {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text('操作控制台')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))

      Text('检测控制和系统设置')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  @Builder
  private buildToolsCards() {
    GridRow({ columns: 2, gutter: DesignConstants.SPACING_MD }) {
      // 测量工具
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '声级校准',
          icon: $r('app.media.ic_calibration'),
          description: '自动和手动校准',
          status: `当前: ${this.pk.calibration_value}dB`,
          statusColor: $r('sys.color.font_primary'),
          onTap: () => {
            this.navigateToAudioCalibration()
          }
        })
      }

      // 分析工具
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '频率加权',
          icon: $r('app.media.ic_frequency_weighting'),
          description: 'A/C/Z计权设置',
          status: `当前: ${this.getWeightingDisplayName(this.pk.weighting_type)}`,
          statusColor: $r('sys.color.font_primary'),
          onTap: () => {
            this.navigateToFrequencyWeighting()
          }
        })
      }

      // 音频分析模式
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '音频分析模式',
          icon: $r('app.media.ic_time_weighting'),
          description: '快速/慢速/脉冲',
          status: `当前: ${this.getAnalysisModeDisplayName(this.pk.audio_analysis_mode)}`,
          statusColor: $r('sys.color.font_primary'),
          onTap: () => {
            this.navigateToAudioAnalysisMode()
          }
        })
      }

      // 音频记录开关
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '音频记录',
          icon: $r('app.media.ic_mic'),
          description: '保存原始音频',
          status: this.pk.record_enabled ? '已开启' : '已关闭',
          statusColor: this.pk.record_enabled ? $r('sys.color.confirm') : $r('sys.color.font_secondary'),
          onTap: () => {
            this.toggleAudioRecording()
          }
        })
      }

      // 警报工具
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '警报设置',
          icon: $r('app.media.ic_alarm'),
          description: '阈值和通知管理',
          status: `阈值: ${this.pk.alarm_threshold.currentEffectiveThreshold}dB`,
          statusColor: $r('sys.color.font_primary'),
          onTap: () => {
            this.navigateToAlerts()
          }
        })
      }

      // 数据工具
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '自动保存',
          icon: $r('app.media.ic_save'),
          description: '自动保存设置',
          status: this.pk.auto_save_enabled ? '已开启' : '已关闭',
          statusColor: this.pk.auto_save_enabled ? $r('sys.color.confirm') : $r('sys.color.font_secondary'),
          onTap: () => {
            this.navigateToAutoSave()
          }
        })
      }

      // 位置服务卡片
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '位置服务',
          icon: $r('app.media.ic_location'),
          description: '记录位置信息',
          status: this.locationStatus,
          statusColor: this.locationStatusColor,
          onTap: () => {
            this.toggleLocationService()
          }
        })
      }

      // 手电筒卡片
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '手电筒',
          icon: $r('app.media.ic_flashlight_bold'),
          description: '开启/关闭手电筒',
          status: this.isTorchOn ? '开启' : '关闭',
          statusColor: this.isTorchOn ? $r('sys.color.confirm') : $r('sys.color.font_secondary'),
          onTap: () => {
            this.toggleTorch()
          }
        })
      }
    }
    .width('100%')
  }

  @Builder
  private buildToolCard(config: ToolCardConfig) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标区域
      Image(config.icon)
        .width(32)
        .height(32)
        .fillColor($r('sys.color.icon_primary'))

      // 右侧内容区域
      Column({ space: DesignConstants.SPACING_XS }) {
        // 标题行
        Row() {
          Text(config.title)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))

          Blank()
        }
        .width('100%')

        // 描述行
        Row() {
          Text(config.description)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))

          Blank()
        }
        .width('100%')

        // 状态显示区域
        if (config.status) {
          Row() {
            Text(config.status)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontWeight(FontWeight.Medium)
              .fontColor(config.statusColor || $r('sys.color.font_primary'))

            Blank()
          }
          .width('100%')
          .margin({ top: DesignConstants.SPACING_XS })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(80)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .shadow(DesignConstants.SHADOW_SM)
    .onClick(() => {
      Throttle.click(() => {
        config.onTap()
      });
    })
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
}