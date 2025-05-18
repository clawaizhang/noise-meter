import { DialogContainer } from '../../../library/ets/components/common/DialogContainer';

import { DecibelService, NoiseLevel } from '../services/DecibelService';

const noiseLevels = DecibelService.getNoiseLevels();

@ComponentV2
export struct NoiseLevelDialog {
  @Builder
  ContentBuilder() {
    Column() {
      Text('噪音等级说明')
        .fontSize(20)
        .fontColor('#333333')
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 });

      Column() {
        ForEach(noiseLevels, (item: NoiseLevel) => {
          Row() {
            Text(item.range)
              .fontSize(16)
              .fontColor(item.color)
              .fontWeight(FontWeight.Bold)
              .margin({ right: 8 });

            Text(item.level)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ right: 8 });

            Text(item.description)
              .fontSize(12)
              .fontColor('#999999')
              .lineHeight(16)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .shadow({ radius: 2, color: '#1A000000', offsetY: 2 })
          .margin({ bottom: 8 });
        });
      }
    }
    .padding(16)
    .backgroundColor('#F5F5F5')
  }

  build() {
    DialogContainer({
      ContentBuilder: this.ContentBuilder
    }
    )
  }
}

@Builder
export function NoiseLevelDialogBuilder() {
  NoiseLevelDialog()
}