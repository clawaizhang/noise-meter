import { common } from '@kit.AbilityKit';
import { NoiseStandardCardBuilder } from '../../../library/ets/components/business/NoiseStandardCard';
import { DialogContainer } from '../../../library/ets/components/common/DialogContainer';
import { NoiseStandards } from '../../../library/ets/constants/NoiseStandardConstants';
import { NoiseStandard } from '../../../library/ets/models/NoiseStandard';

@ComponentV2
export struct NoiseStandardDialog {
  build() {
    Column() {
      DialogContainer({
        ContentBuilder: this.StandardCardBuilder
      })
    }
  }

  @Builder
  StandardCardBuilder() {
    Column() {
      Text('噪音参考标准')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })
        .width('100%')
        .textAlign(TextAlign.Center)
        
      Text('（白天：6:00-22:00，夜间：22:00-6:00）')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ bottom: 16 })
        .width('100%')
        .textAlign(TextAlign.Center)
        
      ForEach(NoiseStandards, (standard: NoiseStandard, index: number) => {
        NoiseStandardCardBuilder(standard, getContext(this) as common.UIAbilityContext)
      }
      )
    }.margin({ bottom: 16 })
  }
}

@Builder
export function NoiseStandardDialogBuilder() {
  NoiseStandardDialog()
}
