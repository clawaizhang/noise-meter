import { common } from '@kit.AbilityKit';
import { BannerCard } from '../../library/ets/components/business/BannerCard';
import { DecibelMeter } from '../ets/components/DecibelMeter';
import { getTitleName, noiseMeterNavStack } from '../MainPageInfo';

@Component
export struct NoiseMeter {
  @State bgColor: string = '#F1F3F5'
  @Provide(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack()

  @Builder
  NoiseTitle() {
    Stack() {
      Text(getTitleName())
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(56)
    .backgroundColor('#F5F5F5')
  }

  build() {
    Navigation(this.navStack) {
      Stack({ alignContent: Alignment.Center }) {
        // 背景
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(this.bgColor)

        Column() {


          // 噪音检测区域
          DecibelMeter()
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
    .titleMode(NavigationTitleMode.Mini)
    .title(this.NoiseTitle())
    .hideBackButton(true)
    .backgroundColor('#F5F5F5')
    .navBarPosition(NavBarPosition.Start)
  }
}