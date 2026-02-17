/**
 * 马年抽签动画组件
 * 【活动已结束】
 */

import { SpringFestivalConstants } from '../../constants/SpringFestivalConstants';

export interface LuckyDrawAnimationProps {
  luckySign?: string;
}

@Builder
export function LuckyDrawAnimationBuilder(props: LuckyDrawAnimationProps) {
  LuckyDrawAnimation({ luckySign: props.luckySign ?? '' });
}

@Component
export struct LuckyDrawAnimation {
  @Prop luckySign: string = '';

  build() {
    Column({ space: 20 }) {
      Text('🐎')
        .fontSize(64)

      Text('抽签活动已结束')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)

      Text('感谢您的参与')
        .fontSize(14)
        .fontColor('#999')
    }
    .padding(32)
    .backgroundColor(SpringFestivalConstants.COLOR_BG_WARM)
    .borderRadius(16)
    .width('100%')
  }
}
