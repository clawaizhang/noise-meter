import { common } from '@kit.AbilityKit';
import { BannerCard } from '../library/ets/components/business/BannerCard';
import { NoiseDecibel } from './ets/components/NoiseDecibel';

@Component
export struct MainPage {
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
        Row() {
          BannerCard({
            context: getContext(this) as common.Context,
            adId: 'testw6vs28auh3',
            onItemClick: () => {
              console.info('广告被点击了');
            }
          })
        }
        .width('92%')
        .height(57)
        .margin({ top: 12, bottom: 12 })

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