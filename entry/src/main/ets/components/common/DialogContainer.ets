import hilog from '@ohos.hilog'
import { noiseMeterNavStack } from '../../constants/ProviderConstant';

const TAG = 'DialogContainer';
const DOMAIN = 0x0000;

@ComponentV2
export struct DialogContainer {
  @Consumer(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack();
  @Local translateY: number = 1000;
  @Local bgOpacity: number = 0;
  private startY: number = 0;

  async aboutToAppear() {
    try {
      this.bgOpacity = 0;
      animateTo({ duration: 800, curve: Curve.Smooth }, () => {
        this.translateY = 0;
        setTimeout(() => {
          animateTo({ duration: 400, curve: Curve.EaseIn }, () => {
            this.bgOpacity = 0.18;
          });
        }, 400);
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化失败: %{public}s', error instanceof Error ? error.message : String(error));
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        // 背景遮罩层
        Column()
          .width('100%')
          .height('100%')
          .onClick(() => {
            this.navStack.pop();
            animateTo({ duration: 1200, curve: Curve.EaseIn }, () => {
              this.translateY = 1000;
            });
            animateTo({ duration: 600, curve: Curve.EaseIn }, () => {
              this.bgOpacity = 0;
            });
          })

        // 弹窗内容
        Column() {
          // 顶部拖动条
          Row() {
            Row()
              .width(40)
              .height(4)
              .borderRadius(2)
              .backgroundColor($r('app.color.background_secondary'))
          }
          .width('100%')
          .height(20)
          .justifyContent(FlexAlign.Center)

          // 内容区域
          Column() {
            this.ContentBuilder()
          }
          .width('100%')
        }
        .id("dialogRoot")
        .width('100%')
        .backgroundColor($r('app.color.background_primary'))
        .borderRadius({ topLeft: 16, topRight: 16 })
        .translate({ y: this.translateY })
        .onClick(() => {
          // 阻止事件冒泡
        })
        .gesture(
          PanGesture({ direction: PanDirection.Vertical })
            .onActionStart((event: GestureEvent) => {
              this.startY = event.offsetY;
            })
            .onActionUpdate((event: GestureEvent) => {
              const deltaY = event.offsetY - this.startY;
              if (deltaY > 0) {
                this.translateY = deltaY;
                this.bgOpacity = Math.max(0, 0.18 * (1 - deltaY / 250));
              }
            })
            .onActionEnd(() => {
              if (this.translateY > 100) {
                this.navStack.pop();
                animateTo({ duration: 1200, curve: Curve.EaseIn }, () => {
                  this.translateY = 1000;
                });
              } else {
                animateTo({ duration: 800, curve: Curve.Smooth }, () => {
                  this.translateY = 0;
                  this.bgOpacity = 0.18;
                });
              }
            })
        )
        .animation({
          duration: 800,
          curve: Curve.Smooth
        })
      }
      .height('100%')
      .width('100%')
    }
    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
    .animation({
      duration: 400,
      curve: Curve.EaseOut,
      iterations: 1,
      playMode: PlayMode.Normal
    })
    .hideTitleBar(true)
    .mode(NavDestinationMode.DIALOG)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onBackPressed(() => {
      this.navStack.pop();
      animateTo({ duration: 1200, curve: Curve.EaseIn }, () => {
        this.translateY = 1000;
      });
      animateTo({ duration: 600, curve: Curve.EaseIn }, () => {
        this.bgOpacity = 0;
      });
      return true;
    })
  }

  @BuilderParam
  ContentBuilder: () => void
}

@Builder
export function DialogContainerBuilder(contentBuilder: () => void) {
  DialogContainer({ ContentBuilder: contentBuilder })
}
