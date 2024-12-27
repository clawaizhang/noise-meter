import { LocationDisplay } from '@ohos/library';
import { NoiseDecibel } from '../components/NoiseDecibel';

@Entry
@Component
struct Index {
  @State bgColor: string = '#F1F3F5'

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.bgColor)

      Column() {
        // 顶部位置信息
        Column() {
          LocationDisplay()
        }
        .width('92%')
        .padding(12)
        .borderRadius(24)
        .backgroundColor(Color.White)
        .margin({ top: 16, bottom: 12 })
        .shadow({ radius: 12, color: '#1A000000', offsetY: 2 })

        // 噪音检测区域
        NoiseDecibel()
          .width('92%')
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}