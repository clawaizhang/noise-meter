import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { LocationInfo, LocationService } from '../../services/LocationService';
import {
  AutoSaveDialogParams,
  AutoSaveSettings,
  AutoSaveSettingsDialogBuilder,
} from '../auto-save/AutoSaveSettingsDialog';
import { AlertsSettingsBuilder, AlertsSettingsProps } from '../../pages/settings/AlertsSettingsNavigation';
import { isProMember } from '../membership/PremiumLockViews';


/**
 * 数据与警报设置内容组件
 * 采用设置项列表样式，点击配置按钮弹出对应弹窗
 */
@ComponentV2
export struct DataAndAlertsContent {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private isLocationRefreshing: boolean = false;

  private locationService: LocationService = LocationService.getInstance();

  aboutToAppear() {
    // 如果位置服务已开启，自动获取位置
    if (this.pk.location_enabled) {
      this.refreshLocation();
    }
  }

  // 刷新位置信息
  private async refreshLocation(): Promise<void> {
    if (!this.pk.location_enabled || this.isLocationRefreshing) {
      return;
    }

    try {
      this.isLocationRefreshing = true;

      const isServiceEnabled = this.locationService.checkLocationEnabled();
      if (!isServiceEnabled) {
        return;
      }

      const hasPermission = await this.locationService.requestLocationPermission();
      if (!hasPermission) {
        this.pk.location_enabled = false;
        return;
      }

      const locationInfo: LocationInfo = await this.locationService.requestSingleLocation();
      console.info('获取位置信息成功:', JSON.stringify(locationInfo));
    } catch (error) {
      console.error('获取位置信息失败:', error);
    } finally {
      this.isLocationRefreshing = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {
        // 数据管理分组
        this.buildDataManagementSection()

        // 警报设置分组
        this.buildAlertsSection()
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(DesignConstants.SPACING_MD)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
    .edgeEffect(EdgeEffect.Spring)
  }

  // 数据管理分组
  @Builder
  private buildDataManagementSection() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 分组标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_save'))
          .width(20)
          .height(20)
          .fillColor($r('sys.color.icon_primary'))

        Text('数据管理')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        Blank()
      }
      .width('100%')

      // 自动保存设置项
      this.buildAutoSaveItem()

      // 音频记录设置项
      this.buildAudioRecordingItem()

      // 位置服务设置项
      this.buildLocationServiceItem()
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  // 自动保存设置项 - 所有用户都可点击进入弹窗
  @Builder
  private buildAutoSaveItem() {
    this.buildAutoSaveContent()
  }

  // 自动保存内容
  @Builder
  private buildAutoSaveContent() {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标
      Row() {
        Image($r('app.media.ic_save'))
          .width(20)
          .height(20)
          .fillColor($r('sys.color.icon_primary'))
      }
      .width(36)
      .height(36)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(8)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 内容区
      Column({ space: 2 }) {
        Text('自动保存')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))

        Text(this.getAutoSaveStatusText())
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(this.pk.auto_save_enabled ? $r('sys.color.font_emphasize') : $r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (isProMember()) {
        // 专业版：配置按钮 + Toggle
        if (this.pk.auto_save_enabled) {
          Button('配置')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_emphasize'))
            .backgroundColor($r('sys.color.comp_background_secondary'))
            .height(32)
            .padding({ left: 12, right: 12 })
            .margin({ right: 8 })
            .onClick(() => {
              Throttle.click(() => {
                this.openAutoSaveDialog();
              });
            })
        }

        Toggle({ type: ToggleType.Switch, isOn: this.pk.auto_save_enabled })
          .selectedColor($r('sys.color.font_emphasize'))
          .onChange((isOn: boolean) => {
            this.pk.auto_save_enabled = isOn;
          })
      } else {
        // 免费版：未开启 + 🔒配置按钮
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('未开启')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))

          Button() {
            Row({ space: 4 }) {
              Image($r('app.media.ic_lock'))
                .width(12)
                .height(12)
                .fillColor('#FF6B6B')
              Text('配置')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor('#FF6B6B')
            }
          }
          .height(28)
          .padding({ left: 10, right: 10 })
          .backgroundColor('rgba(255, 107, 107, 0.1)')
          .borderRadius(14)
        }
        .onClick(() => {
          Throttle.click(() => {
            this.openAutoSaveDialog();
          });
        })
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  // 音频记录设置项 - 所有人都可以使用
  @Builder
  private buildAudioRecordingItem() {
    this.buildAudioRecordingContent()
  }

  // 音频记录内容
  @Builder
  private buildAudioRecordingContent() {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标
      Row() {
        Image($r('app.media.ic_mic'))
          .width(20)
          .height(20)
          .fillColor(this.pk.record_enabled ? $r('sys.color.font_emphasize') : $r('sys.color.icon_primary'))
      }
      .width(36)
      .height(36)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(8)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 内容区
      Column({ space: 2 }) {
        Text('音频记录')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))

        Text(this.pk.record_enabled ? '录制原始音频用于后续分析' : '仅保存分贝数据，不录制音频')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(this.pk.record_enabled ? $r('sys.color.font_emphasize') : $r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 开关
      Toggle({ type: ToggleType.Switch, isOn: this.pk.record_enabled })
        .selectedColor($r('sys.color.font_emphasize'))
        .onChange((isOn: boolean) => {
          this.pk.record_enabled = isOn;
        })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  // 位置服务设置项
  @Builder
  private buildLocationServiceItem() {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标
      Row() {
        Image($r('app.media.ic_location'))
          .width(20)
          .height(20)
          .fillColor(this.pk.location_enabled ? $r('sys.color.font_emphasize') : $r('sys.color.icon_primary'))
      }
      .width(36)
      .height(36)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(8)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 内容区
      Column({ space: 2 }) {
        Text('位置服务')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))

        Text(this.getLocationStatusText())
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(this.pk.location_enabled ? $r('sys.color.font_emphasize') : $r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 开关
      Toggle({ type: ToggleType.Switch, isOn: this.pk.location_enabled })
        .selectedColor($r('sys.color.font_emphasize'))
        .onChange((isOn: boolean) => {
          this.pk.location_enabled = isOn;
          if (isOn) {
            this.refreshLocation();
          }
        })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  // 警报设置分组
  @Builder
  private buildAlertsSection() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 分组标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_alarm'))
          .width(20)
          .height(20)
          .fillColor($r('sys.color.icon_primary'))

        Text('警报设置')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        Blank()
      }
      .width('100%')

      // 警报设置项
      this.buildAlertItem()

      // 警报说明
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_info'))
          .width(16)
          .height(16)
          .fillColor($r('sys.color.font_secondary'))

        Text('💡 建议：长期暴露在85dB以上环境可能造成听力损伤')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .layoutWeight(1)
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  // 警报设置项
  @Builder
  private buildAlertItem() {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标
      Row() {
        Image($r('app.media.ic_alarm'))
          .width(20)
          .height(20)
          .fillColor(this.pk.system_notification_enabled ? $r('sys.color.font_emphasize') : $r('sys.color.icon_primary'))
      }
      .width(36)
      .height(36)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(8)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 内容区
      Column({ space: 2 }) {
        Text('噪声警报')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))

        Text(this.getAlertStatusText())
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(this.pk.system_notification_enabled ? $r('sys.color.font_emphasize') : $r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 配置按钮（仅在开启时显示）或开关
      if (this.pk.system_notification_enabled) {
        Button('配置')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_emphasize'))
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .height(32)
          .padding({ left: 12, right: 12 })
          .margin({ right: 8 })
          .onClick(() => {
            Throttle.click(() => {
              this.openAlertsDialog();
            });
          })
      }

      Toggle({ type: ToggleType.Switch, isOn: this.pk.system_notification_enabled })
        .selectedColor($r('sys.color.font_emphasize'))
        .onChange((isOn: boolean) => {
          this.pk.system_notification_enabled = isOn;
          // 如果开启，打开配置弹窗
          if (isOn) {
            this.openAlertsDialog();
          }
        })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  // ==================== 打开弹窗方法 ====================

  // 打开自动保存弹窗
  private openAutoSaveDialog(): void {
    let autoSaveDialog: InfSheet;
    let param: AutoSaveDialogParams = {
      onClose: () => {
        autoSaveDialog?.dismiss();
      },
      onSettingsApplied: (settings: AutoSaveSettings) => {
        // 设置已应用
        console.info('自动保存设置已更新:', settings);
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

  // 打开警报设置弹窗
  private openAlertsDialog(): void {
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

  // ==================== 辅助方法 ====================

  private getAutoSaveStatusText(): string {
    if (this.pk.auto_save_enabled) {
      return `每${this.pk.auto_save_interval}分钟自动保存`;
    }
    return '已关闭，手动保存数据';
  }

  private getLocationStatusText(): string {
    if (!this.pk.location_enabled) {
      return '已关闭';
    }
    if (this.isLocationRefreshing) {
      return '正在获取位置...';
    }
    return '已开启，记录测量位置';
  }

  private getAlertStatusText(): string {
    if (this.pk.system_notification_enabled) {
      return `阈值 ${this.pk.alarm_threshold.currentEffectiveThreshold}dB，超标时警报`;
    }
    return '已关闭';
  }
}
