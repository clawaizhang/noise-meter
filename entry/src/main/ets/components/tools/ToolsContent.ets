import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { LocationInfo } from '../../services/LocationService';
import { LocationDisplay } from '../business/LocationDisplay';
import { camera } from '@kit.CameraKit';
import common from '@ohos.app.ability.common';
import { Throttle } from '../../utils/Debounce';
import { WeightingType } from '../../constants/WeightingConstants';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { AudioCalibrationProps, AudioCalibrationSettingsBuilder } from '../../pages/settings/AudioCalibrationNavigation';
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
  @Local private currentLocation: LocationInfo | null = null;

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 页面标题
      this.buildPageHeader()
      
      // 工具功能卡片区
      this.buildToolsCards()
    }
    .width('100%')
    .height('100%')
    .padding(DesignConstants.SPACING_MD)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  private buildPageHeader() {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text('实用工具')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
      
      Text('辅助功能和设备管理')
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
          onTap: () => { this.navigateToAudioCalibration() }
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
          onTap: () => { this.navigateToFrequencyWeighting() }
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
          onTap: () => { this.navigateToAlerts() }
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
          onTap: () => { this.navigateToAutoSave() }
        })
      }
      
      // 系统工具
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '位置服务',
          icon: $r('app.media.ic_location'),
          description: '当前位置显示',
          status: this.pk.location_enabled ? '已开启' : '已关闭',
          statusColor: this.pk.location_enabled ? $r('sys.color.confirm') : $r('sys.color.font_secondary'),
          onTap: () => { this.toggleLocation() }
        })
      }
      
      GridCol({ span: 1 }) {
        this.buildToolCard({
          title: '手电筒',
          icon: $r('app.media.ic_flashlight_bold'),
          description: '开启/关闭手电筒',
          status: this.isTorchOn ? '开启' : '关闭',
          statusColor: this.isTorchOn ? $r('sys.color.confirm') : $r('sys.color.font_secondary'),
          onTap: () => { this.toggleTorch() }
        })
      }
    }
    .width('100%')

    // 位置显示区域（如果位置服务开启）
    if (this.pk.location_enabled) {
      this.buildLocationDisplay()
    }
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
    .onClick(config.onTap)
  }

  @Builder
  private buildLocationDisplay() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('当前位置信息')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      LocationDisplay({
        onLocationUpdate: (locationInfo: LocationInfo | null) => {
          // 更新本地位置状态
          this.currentLocation = locationInfo;
          console.info('[TOOLS][Location] 位置更新事件接收:', locationInfo);
        }
      })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .margin({ top: DesignConstants.SPACING_MD })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
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

  // 位置服务切换
  private toggleLocation() {
    Throttle.click(() => {
      this.pk.location_enabled = !this.pk.location_enabled;
    })
  }
}