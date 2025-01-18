import { NoiseStandard } from '../../models/NoiseStandard';
import { NoiseStandardType } from '../../constants/NoiseStandardConstants';
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
      Text(this.standard.typeName)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 8 })

      // 分贝范围
      Row() {
        Text('分贝范围：')
          .fontSize(14)
          .fontColor('#666666')
        Text(`${this.standard.dayLimit} - ${this.standard.nightLimit} dB`)
          .fontSize(14)
          .fontColor(this.decibelService.getDecibelColor((this.standard.dayLimit + this.standard.nightLimit) / 2))
      }
      .margin({ bottom: 8 })

      // 描述
      Text(this.standard.description)
        .fontSize(14)
        .fontColor('#666666')
        .lineHeight(20)
    }
    .padding(16)
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
export function NoiseStandardCardBuilder(standard: NoiseStandard, context: common.Context|null) {
  NoiseStandardCard({ standard: standard, context: context })
}