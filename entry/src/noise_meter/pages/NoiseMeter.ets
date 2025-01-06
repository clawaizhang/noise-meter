import { DecibelMeter } from '../ets/components/DecibelMeter';
import { noiseMeterNavStack } from '../ets/constant/ProviderConstant';
import { getTitleName } from '../MainPageInfo';
import { DecibelHistory } from './DecibelHistory';

@ComponentV2
export struct NoiseMeter {
  @Provider(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack()
  @Local currentIndex: number = 0

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
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
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
        .tabBar(this.TabBuilder('开始检测', $r('app.media.ic_mic'), 0))

        TabContent() {
          DecibelHistory()
        }
        .tabBar(this.TabBuilder('检测记录', $r('app.media.ic_history'), 1))
      }
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .width('100%')
      .height('100%')
      .barHeight(56)
      .barMode(BarMode.Fixed)
    }
    .titleMode(NavigationTitleMode.Mini)
    .title(this.NoiseTitle())
    .hideBackButton(true)
    .backgroundColor('#F5F5F5')
    .navBarPosition(NavBarPosition.Start)
    .hideToolBar(true)
  }

  @Builder
  TabBuilder(title: string, icon: Resource, index: number) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? '#2196F3' : '#666666')
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? '#2196F3' : '#666666')
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}