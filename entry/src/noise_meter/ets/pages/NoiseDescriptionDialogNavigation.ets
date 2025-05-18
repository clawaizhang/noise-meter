import { DecibelService } from '../services/DecibelService';
import { DialogContainer } from '../../../library/ets/components/common/DialogContainer';

@ComponentV2
export struct NoiseDescriptionDialog {
  build() {
    DialogContainer({
      ContentBuilder: this.NoiseDescriptionDialogBuilder
    }
    )
  }

  @Builder
  NoiseDescriptionDialogBuilder() {
    Column() {
      // 标题
      Text('噪音场景参考')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ bottom: 16 })

      // 噪音等级列表
      Column() {
        ForEach([110, 100, 90, 80, 70, 60, 50, 40, 30, 20, 10], (db: number) => {
          Row() {
            Text(`${db} dB`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(DecibelService.getDecibelColor(db - 1))
              .width('25%')

            Text(DecibelService.getDecibelDescription(db - 1))
              .fontSize(14)
              .fontColor('#666666')
              .width('75%')
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({
            top: 8,
            bottom: 8,
            left: 12,
            right: 12
          })
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 2 })
        })
      }
    }
    .padding(16)
  }
}

// 对话框构建器
@Builder
export function NoiseDescriptionDialogBuilder() {
  NoiseDescriptionDialog()
}