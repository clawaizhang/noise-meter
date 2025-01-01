import { AudioService } from '../../services/AudioService';
import common from '@ohos.app.ability.common';

@Component
export struct AudioRecordDisplay {
  @Link isRecordEnabled: boolean

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
            .fontColor('#000000')

          Text(this.isRecordEnabled ? ' 已开启' : ' 已关闭')
            .fontSize(14)
            .fontColor(this.isRecordEnabled ? '#0091FF' : '#666666')
        }

        Blank()

        Toggle({ type: ToggleType.Switch, isOn: this.isRecordEnabled })
          .selectedColor('#0091FF')
          .switchPointColor('#FFFFFF')
          .onChange((isOn: boolean) => {
            this.isRecordEnabled = isOn;
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      if (this.isRecordEnabled) {
        Text('本次检测期间的音频将被记录')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: 16, top: -8 })
      } else {
        Text('开启后可记录检测过程中的音频')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ left: 16, top: -8 })
      }
    }
    .width('100%')
    .padding({
      left: 20,
      right: 20,
      top: 16,
      bottom: 16
    })
    .borderRadius(20)
    .backgroundColor(Color.White)
    .margin({
      top: 16,
      bottom: 16,
      left: 16,
      right: 16
    })
    .shadow({ radius: 1, color: '#1A000000', offsetY: 2 })
  }
} 