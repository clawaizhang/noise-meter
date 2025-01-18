import { NoiseStandard } from '../../models/NoiseStandard';
import common from '@ohos.app.ability.common';
import { DecibelService } from '../../../../noise_meter/ets/services/DecibelService';

@ComponentV2
export struct NoiseStandardCard {
  @Param @Require standard: NoiseStandard;
  @Param @Require context: common.Context | null;
  private decibelService: DecibelService = new DecibelService();

  @Builder
  private CardContent() {
    Column() {
      // 标题
      Row() {
        Image($r('app.media.ic_info'))
          .width(24)
          .height(24)
          .margin({ right: 8 })

        Text(this.standard.typeName)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 分隔线
      Divider()
        .strokeWidth(1)
        .color('#F0F0F0')
        .margin({ bottom: 12 })

      // 分贝范围
      GridRow() {
        GridCol({ span: { xs: 24 } }) {
          Column() {
            Text('分贝范围')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ bottom: 4 })

            Text(`${this.standard.dayLimit} - ${this.standard.nightLimit} dB`)
              .fontSize(16)
              .fontColor(this.decibelService.getDecibelColor((this.standard.dayLimit + this.standard.nightLimit) / 2))
              .fontWeight(FontWeight.Medium)
          }
        }
      }
      .margin({ bottom: 16 })

      // 描述
      GridRow() {
        GridCol({ span: { xs: 24 } }) {
          Column() {
            Text('描述')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ bottom: 4 })

            Text(this.standard.description)
              .fontSize(14)
              .fontColor('#666666')
              .lineHeight(20)
          }
        }
      }
    }
    .padding(16)
    .width('100%')
  }

  build() {
    Column() {
      this.CardContent()
    }
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
    .margin({ bottom: 12 })
  }
}

@Builder
export function NoiseStandardCardBuilder(standard: NoiseStandard, context: common.Context | null) {
  NoiseStandardCard({ standard: standard, context: context })
}