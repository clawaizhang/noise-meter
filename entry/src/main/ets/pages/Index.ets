import { LocationDisplay, BannerCard } from '@ohos/library';
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
        // 广告Banner
        BannerCard({
          title: "噪音检测专业版",
          description: "解锁更多高级功能，提供更专业的噪音分析",
          imageUrl: "/common/images/default_banner.png",
          onItemClick: () => {
            console.info('Banner clicked')
          }
        })
        .width('92%')
        .margin({ top: 16, bottom: 12 })

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