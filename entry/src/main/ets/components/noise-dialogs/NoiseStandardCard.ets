import common from '@ohos.app.ability.common';
import { NoiseStandard } from '../../models/NoiseStandard';
import { DecibelService } from '../../services/DecibelService';

@ComponentV2
export struct NoiseStandardCard {
  @Param @Require standard: NoiseStandard;
  @Param @Require context: common.Context | null;

  @Builder
  private CardContent() {
    Column() {
      // 标题
      Row() {
        Text(this.standard.typeName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')

      // 分贝范围和描述
      GridRow({ columns: { xs: 12 }, gutter: { x: 16 } }) {
        GridCol({ span: { xs: 5 } }) {
          Column() {
            // 白天分贝
            Row() {
              Text('白天')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
              Text(`${this.standard.dayLimit} dB`)
                .fontSize(18)
                .fontColor(DecibelService.getDecibelColor(this.standard.dayLimit))
                .fontWeight(FontWeight.Bold)
                .margin({ left: 8 })
            }
            .margin({ bottom: 8 })
            
            // 夜间分贝
            Row() {
              Text('夜间')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
              Text(`${this.standard.nightLimit} dB`)
                .fontSize(18)
                .fontColor(DecibelService.getDecibelColor(this.standard.nightLimit))
                .fontWeight(FontWeight.Bold)
                .margin({ left: 8 })
            }
          }
        }

        GridCol({ span: { xs: 7 } }) {
          Column() {
            Text(this.standard.description)
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .lineHeight(20)
          }
        }
      }.margin({ top: 4 })
    }
    .padding(8)
    .width('100%')
  }

  build() {
    Column() {
      this.CardContent()
    }
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(12)
    .shadow({ radius: 0, color: '#33000000', offsetY: 2 })
  }
}

@Builder
export function NoiseStandardCardBuilder(standard: NoiseStandard, context: common.Context | null) {
  NoiseStandardCard({ standard: standard, context: context })
}
