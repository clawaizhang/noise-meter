import { DecibelMeter } from '../ets/components/DecibelMeter';
import { noiseMeterNavStack } from '../ets/constant/ProviderConstant';
import { getTitleName } from '../MainPageInfo';
import { DecibelHistory } from './DecibelHistory';
import { CustomTitleBar } from '../../library/ets/components/common/CustomTitleBar';

@ComponentV2
export struct NoiseMeter {
  @Provider(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack()
  @Local currentIndex: number = 0

  build() {
    Navigation(this.navStack) {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          Column() {
            // 使用自定义标题栏
            CustomTitleBar({ title: getTitleName() })

            // 噪音检测区域
            DecibelMeter()
              .width('92%')
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#F5F5F5')
          .alignItems(HorizontalAlign.Center)
        }
        .tabBar(this.TabBuilder('开始检测', $r('app.media.ic_mic'), 0))

        TabContent() {
          DecibelHistory({ currentTabIndex: this.currentIndex })
        }
        .tabBar(this.TabBuilder('检测记录', $r('app.media.ic_history'), 1))
      }
      .scrollable(false)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .width('100%')
      .height('100%')
      .barHeight(56)
      .barMode(BarMode.Fixed)
      .animationDuration(0)
    }
    .hideTitleBar(true)
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