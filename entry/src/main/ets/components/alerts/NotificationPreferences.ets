/**
 * 系统通知设置组件
 * 配置噪音警报的系统通知开关
 */

import { ALERT_COLORS } from '../../constants/AlertsConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { curves } from '@kit.ArkUI';

@ComponentV2
export struct NotificationPreferences {
  @Param @Require systemNotificationEnabled: boolean = true; // 系统通知开关
  @Param @Require onSystemNotificationChange: (enabled: boolean) => void; // 系统通知变化回调

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
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor(ALERT_COLORS.CARD_BACKGROUND)
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_SM)
  }
}