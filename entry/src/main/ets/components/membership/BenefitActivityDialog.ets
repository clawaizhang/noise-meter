/**
 * 马年抽签活动弹窗组件
 * 【活动已结束】
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { SpringFestivalConstants } from '../../constants/SpringFestivalConstants';
import { DialogHub } from '@hadss/dialoghub';

export interface BenefitActivityDialogProps {
  onDismiss: () => void;
}

@Builder
export function BenefitActivityDialogBuilder(props: BenefitActivityDialogProps) {
  BenefitActivityDialog({ onDismiss: props.onDismiss });
}

@ComponentV2
export struct BenefitActivityDialog {
  @Event onDismiss: () => void = () => {};

  aboutToAppear(): void {
    // 【活动已结束】显示提示
  }

  build() {
    Column({ space: 20 }) {
      Text('🐎')
        .fontSize(64)

      Text('马年鸿运抽吉签')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)

      Text('活动已圆满结束')
        .fontSize(18)
        .fontColor('#666')

      Text('感谢各位用户的热情参与！\n新的会员服务即将上线，敬请期待')
        .fontSize(14)
        .fontColor('#999')
        .textAlign(TextAlign.Center)

      Button('知道了')
        .width('80%')
        .height(44)
        .fontSize(16)
        .backgroundColor(SpringFestivalConstants.COLOR_CHINESE_RED)
        .fontColor(Color.White)
        .borderRadius(22)
        .onClick(() => {
          this.onDismiss();
        })
    }
    .padding(32)
    .backgroundColor(SpringFestivalConstants.COLOR_BG_WARM)
    .borderRadius(16)
    .width('100%')
  }
}
