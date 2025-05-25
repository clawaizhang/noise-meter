import { common } from '@kit.AbilityKit';
import { DialogContainer } from '../components/common/DialogContainer';
import { NoiseStandardCardBuilder } from '../components/noise-dialogs/NoiseStandardCard';
import { NoiseStandards } from '../constants/NoiseStandardConstants';
import { NoiseStandard } from '../models/NoiseStandard';

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
        .fontColor($r('app.color.dark_text_secondary'))
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
