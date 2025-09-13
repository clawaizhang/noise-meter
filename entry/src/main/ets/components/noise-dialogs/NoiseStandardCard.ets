import common from '@ohos.app.ability.common';
import { NoiseStandard } from '../../models/NoiseStandard';
import { DecibelService } from '../../services/DecibelService';
import { LengthMetrics } from '@kit.ArkUI';

@ComponentV2
export struct NoiseStandardCard {
  @Param @Require standard: NoiseStandard;
  @Param @Require context: common.Context | null;

  aboutToAppear() {
  }

  build() {
    Column() {
      // 标题
      Text(this.standard.typeName)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      // 分贝范围和描述 - 使用响应式网格布局
      Flex({
        direction: FlexDirection.Row,
        wrap: FlexWrap.NoWrap,
        alignItems: ItemAlign.Center,
        space: { main: LengthMetrics.vp(16) }
      }) {

        Column({ space: 8 }) {
          // 白天分贝
          Row() {
            Text('白天')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
            Text(`${this.standard.dayLimit} dB`)

              .fontColor(DecibelService.getDecibelColor(this.standard.dayLimit))
              .fontWeight(FontWeight.Bold)
              .margin({ left: 8 })
          }

          // 夜间分贝
          Row() {
            Text('夜间')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
            Text(`${this.standard.nightLimit} dB`)

              .fontColor(DecibelService.getDecibelColor(this.standard.nightLimit))
              .fontWeight(FontWeight.Bold)
              .margin({ left: 8 })
          }
        }.flexShrink(0)

        Column() {
          Text(this.standard.description)
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
        }.flexGrow(1)
      }.width('100%')

    }
    .padding(16)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(12)
    .alignItems(HorizontalAlign.Center)
    .shadow({
      radius: 3,
      color: '#33000000',
      offsetY: 2
    })
  }
}

@Builder
export function NoiseStandardCardBuilder(standard: NoiseStandard, context: common.Context | null) {
  NoiseStandardCard({ standard: standard, context: context })
}
