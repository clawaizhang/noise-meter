/**
 * 系统通知设置组件
 * 配置噪音警报的系统通知开关
 */

import { ALERT_COLORS } from '../../constants/AlertsConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { AlertService } from '../../services/AlertService';
import { AppStorageV2, curves, PersistenceV2 } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppKeys } from '../../models/AppKeys';
import { notificationManager } from '@kit.NotificationKit';

@ComponentV2
export struct NotificationPreferences {
  @Param @Require systemNotificationEnabled: boolean = true; // 系统通知开关
  @Param @Require onSystemNotificationChange: (enabled: boolean) => void; // 系统通知变化回调
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local private as: AppKeys = AppStorageV2.connect(AppKeys)!;
  private alertService: AlertService = AlertService.getInstance(getContext() as common.UIAbilityContext);
  private intervalId?: number;

  aboutToAppear() {
  }

  @Computed
  get showPermissionWarning() {
    return this.pk.system_notification_enabled && !this.as.systemNotificationPermissionGranted;
  }

  // 跳转到系统设置
  private async openSystemSettings() {
    await this.alertService.openSystemNotificationSettings();
    this.intervalId = setInterval(() => {
      let isEnabled = notificationManager.isNotificationEnabledSync();
      AppStorageV2.connect(AppKeys)!.systemNotificationPermissionGranted = isEnabled;
      if (isEnabled) {
        clearInterval(this.intervalId);
      }
    }, 500);
  }

  // 构建权限警告卡片
  @Builder
  private buildPermissionWarning() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题行
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('sys.media.anahs_notification_icon'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.warning'))

        Text('系统通知权限提醒')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.warning'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 描述文字
      Text('系统通知权限被拒绝\n即使开启警报通知，也无法收到警报')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.warning'))
        .textAlign(TextAlign.Center)
        .lineHeight(20)

      // 操作按钮
      Button('去系统设置开启通知', { type: ButtonType.Normal })
        .width('80%')
        .backgroundColor($r('sys.color.warning'))
        .fontColor(Color.White)
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          this.openSystemSettings();
        })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_warning_secondary'))
    .border({ width: 1, color: $r('sys.color.warning') })
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题区域 - 包含噪音警报主开关
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_alarm'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.font_primary'))

        Text('警报通知')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        // 噪音警报主开关
        Toggle({ type: ToggleType.Switch, isOn: this.systemNotificationEnabled })
          .onChange((isOn: boolean) => {
            this.onSystemNotificationChange(isOn);
            // 开关变化后更新权限状态
            this.alertService.updateSystemPermissionStatus();
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 使用说明
      Text(this.systemNotificationEnabled ?
        '警报触发时，系统将发送通知。' :
        '通知已关闭，系统不会通知噪音超标情况。')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Start)
        .alignSelf(ItemAlign.Start)

      // 权限警告卡片（条件渲染）
      if (this.showPermissionWarning) {
        this.buildPermissionWarning()
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor(ALERT_COLORS.CARD_BACKGROUND)
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_SM)
  }
}