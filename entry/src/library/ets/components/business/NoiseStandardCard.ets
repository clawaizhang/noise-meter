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
        Text(this.standard.typeName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
      }
      .width('100%')

      // 分贝范围和描述
      GridRow({ columns: { xs: 12 }, gutter: { x: 16 } }) {
        GridCol({ span: { xs: 5 } }) {
          Column() {
            Text(`${this.standard.dayLimit} - ${this.standard.nightLimit} dB`)
              .fontSize(18)
              .fontColor(this.decibelService.getDecibelColor((this.standard.dayLimit + this.standard.nightLimit) / 2))
              .fontWeight(FontWeight.Bold)
          }
        }

        GridCol({ span: { xs: 7 } }) {
          Column() {
            Text(this.standard.description)
              .fontSize(14)
              .fontColor('#333333')
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
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 0, color: '#1A000000', offsetY: 2 })
  }
}

@Builder
export function NoiseStandardCardBuilder(standard: NoiseStandard, context: common.Context | null) {
  NoiseStandardCard({ standard: standard, context: context })
}
