import { AudioService } from '../../services/AudioService';
import common from '@ohos.app.ability.common';

@ComponentV2
export struct AudioRecordDisplay {
  @Param isRecordEnabled: boolean = false;
  @Event onRecordEnabledChange: (value: boolean) => void;

  build() {
    Column() {
      Row() {
        Row() {
          Image($r('app.media.ic_mic'))
            .width(16)
            .height(16)
            .fillColor('#666666')
            .margin({ right: 8 })

          Text('录音')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.black'))

          Text(this.isRecordEnabled ? ' 已开启' : ' 已关闭')
            .fontSize(14)
            .fontColor(this.isRecordEnabled ? '#0091FF' : '#666666')
        }

        Blank()

        Toggle({ type: ToggleType.Switch, isOn: this.isRecordEnabled })
          .selectedColor('#0091FF')
          .switchPointColor($r('sys.color.comp_background_list_card'))
          .onChange((isOn: boolean) => {
            this.onRecordEnabledChange(isOn);
          })
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)

      if (this.isRecordEnabled) {
        Text('检测结束后自动保存音频')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: 4, top: 2 })
          .textAlign(TextAlign.Start)
          .width('100%')
      } else {
        Text('开启后将自动保存检测音频')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ left: 4, top: 2 })
          .textAlign(TextAlign.Start)
          .width('100%')
      }
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 8,
      bottom: 12
    })
    .borderRadius(20)
    .backgroundColor(Color.White)
    .margin({
      top: 16,
      bottom: 16,
      left: 8,
      right: 8
    })
    .shadow({ radius: 1, color: '#1A000000', offsetY: 2 })
  }
} 