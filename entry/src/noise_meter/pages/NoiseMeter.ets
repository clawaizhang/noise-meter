import { DecibelMeter } from '../ets/components/DecibelMeter';
import { noiseMeterNavStack } from '../ets/constant/ProviderConstant';
import { getTitleName } from '../MainPageInfo';

@ComponentV2
export struct NoiseMeter {
  @Provider(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack()

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
          .backgroundColor('#F5F5F5')

        Column() {


          // 噪音检测区域
          DecibelMeter()
            .width('92%')
        }
        .width('100%')
        .height('100%')
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