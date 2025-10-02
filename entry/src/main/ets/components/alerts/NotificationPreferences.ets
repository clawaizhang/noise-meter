/**
 * 通知偏好设置组件
 * 配置警报触发时的通知方式
 */

import { ALERT_COLORS, NotificationType } from '../../constants/AlertsConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { curves } from '@kit.ArkUI';

@ComponentV2
export struct NotificationPreferences {
  @Param @Require soundEnabled: boolean = true; // 声音提示开关
  @Param @Require vibrationEnabled: boolean = true; // 振动提示开关
  @Param @Require visualEnabled: boolean = true; // 视觉提示开关
  @Param @Require systemNotificationEnabled: boolean = true; // 系统通知开关
  @Param @Require onSoundChange: (enabled: boolean) => void; // 声音变化回调
  @Param @Require onVibrationChange: (enabled: boolean) => void; // 振动变化回调
  @Param @Require onVisualChange: (enabled: boolean) => void; // 视觉变化回调
  @Param @Require onSystemNotificationChange: (enabled: boolean) => void; // 系统通知变化回调
  @Local previewText: string = '当前启用: ';

  aboutToAppear(): void {
    this.setPreviewText();
  }

  private setPreviewText() {
    this.previewText = '当前启用: ';
    if (this.soundEnabled) {
      this.previewText += '声音、';
    }
    if (this.vibrationEnabled) {
      this.previewText += '振动、';
    }
    if (this.visualEnabled) {
      this.previewText += '视觉、';
    }
    if (this.systemNotificationEnabled) {
      this.previewText += '系统通知、';
    }
    if (!this.soundEnabled && !this.visualEnabled && !this.vibrationEnabled && !this.systemNotificationEnabled) {
      this.previewText = '所有通知类型已关闭';
    }
    this.previewText = this.previewText.slice(0, -1);
  }

  @Monitor('soundEnabled', 'vibrationEnabled', 'visualEnabled', 'systemNotificationEnabled')
  private onNotifyChange(monitor: IMonitor) {
    this.setPreviewText();
  }

  // 构建通知类型设置项
  @Builder
  private buildNotificationItem(
    type: NotificationType,
    title: string,
    description: string,
    icon: Resource,
    enabled: boolean,
    onChange: (enabled: boolean) => void
  ) {
    Column({ space: DesignConstants.SPACING_SM }) {
      Row({ space: DesignConstants.SPACING_SM }) {
        Image(icon)
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor(enabled ? ALERT_COLORS.PRIMARY : $r('sys.color.font_secondary'))

        Column({ space: DesignConstants.SPACING_XS }) {
          Text(title)
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Medium)
            .fontColor(enabled ? $r('sys.color.font_primary') : $r('sys.color.font_secondary'))

          Text(description)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Toggle({ type: ToggleType.Switch, isOn: enabled })
          .onChange((isOn: boolean) => {
            onChange(isOn);
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .animation({
      duration: 200,
      curve: curves.springMotion()
    })
  }

  // 构建声音通知设置
  @Builder
  private buildSoundNotification() {
    this.buildNotificationItem(
      NotificationType.SOUND,
      '声音提示',
      '警报触发时播放提示音',
      $r('app.media.ic_audio_analysis'),
      this.soundEnabled,
      (enabled: boolean) => {
        this.onSoundChange(enabled);
      }
    )
  }

  // 构建振动通知设置
  @Builder
  private buildVibrationNotification() {
    this.buildNotificationItem(
      NotificationType.VIBRATION,
      '振动提示',
      '警报触发时设备振动',
      $r('app.media.ic_sensor'),
      this.vibrationEnabled,
      (enabled: boolean) => {
        this.onVibrationChange(enabled);
      }
    )
  }

  // 构建视觉通知设置
  @Builder
  private buildVisualNotification() {
    this.buildNotificationItem(
      NotificationType.VISUAL,
      '视觉提示',
      '屏幕闪烁或颜色变化提示',
      $r('app.media.ic_meter'),
      this.visualEnabled,
      (enabled: boolean) => {
        this.onVisualChange(enabled);
      }
    )
  }

  // 构建系统通知设置
  @Builder
  private buildSystemNotification() {
    this.buildNotificationItem(
      NotificationType.SYSTEM,
      '系统通知',
      '在通知栏显示警报信息',
      $r('app.media.ic_alarm'),
      this.systemNotificationEnabled,
      (enabled: boolean) => {
        this.onSystemNotificationChange(enabled);
      }
    )
  }

  // 构建通知组合预览
  @Builder
  private buildNotificationPreview() {

    Column({ space: DesignConstants.SPACING_XS }) {
      Text('通知组合预览')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      Text(this.previewText)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor(this.previewText !== '所有通知类型已关闭' ? ALERT_COLORS.SUCCESS : ALERT_COLORS.WARNING)
        .textAlign(TextAlign.Start)
        .alignSelf(ItemAlign.Start)

      if (this.previewText === '所有通知类型已关闭') {
        Text('建议至少启用一种通知方式')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(ALERT_COLORS.WARNING)
          .textAlign(TextAlign.Start)
          .alignSelf(ItemAlign.Start)
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .margin({ top: DesignConstants.SPACING_MD })
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题区域
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_alarm'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.font_primary'))

        Text('通知偏好设置')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 通知类型设置
      Column({ space: DesignConstants.SPACING_MD }) {
        this.buildSoundNotification()
        this.buildVibrationNotification()
        this.buildVisualNotification()
        this.buildSystemNotification()
      }
      .width('100%')

      // 通知组合预览
      this.buildNotificationPreview()

      // 使用说明
      Text('警报触发时，系统将按照您的设置发送通知。建议根据使用场景选择合适的通知组合。')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Start)
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor(ALERT_COLORS.CARD_BACKGROUND)
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_SM)
  }
}