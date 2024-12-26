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
        .padding(16)
        .borderRadius(24)
        .backgroundColor(Color.White)
        .margin({ top: 24, bottom: 16 })
        .shadow({ radius: 12, color: '#1A000000', offsetY: 2 })

        // 噪音检测区域
        NoiseDecibel()
          .width('92%')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}