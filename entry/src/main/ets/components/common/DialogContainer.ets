import hilog from '@ohos.hilog'
import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';
import { DialogConstants } from '../../constants/DialogConstants';
import { ImageSoundPlayerState } from '../decibel-meter/PressureSounds';

const TAG = 'DialogContainer';
const DOMAIN = 0x0000;

@ComponentV2
export struct DialogContainer {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  @Local translateY: number = 1000;
  @Local bgOpacity: number = 0;
  @Local scaleValue: number = 0.95;
  @Local dragProgress: number = 0;
  private startY: number = 0;

  async aboutToAppear() {
    try {
      this.bgOpacity = 0;
      this.scaleValue = 0.95;
      animateTo({
        duration: DialogConstants.ANIMATION.ENTER_DURATION,
        curve: Curve.EaseOut
      }, () => {
        this.translateY = 0;
        this.scaleValue = 1;
        setTimeout(() => {
          animateTo({
            duration: DialogConstants.ANIMATION.BACKGROUND_DURATION,
            curve: Curve.EaseOut
          }, () => {
            this.bgOpacity = DialogConstants.DIALOG.BACKGROUND_OPACITY;
          });
        }, 200);
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化失败: %{public}s', error instanceof Error ? error.message : String(error));
    }
  }

  private closeDialog() {
    this.navStack.pop();
    animateTo({
      duration: DialogConstants.ANIMATION.EXIT_DURATION,
      curve: Curve.EaseInOut
    }, () => {
      this.translateY = 1000;
      this.scaleValue = 0.95;
    });
    animateTo({
      duration: DialogConstants.ANIMATION.BACKGROUND_DURATION,
      curve: Curve.EaseIn
    }, () => {
      this.bgOpacity = 0;
    });
  }

  build() {
    NavDestination() {
      // 弹窗内容
      Column() {
        this.ContentBuilder(this.contentParam)
      }
      .id("dialogRoot")
      .width('100%')
      .height(DialogConstants.DIALOG.MAX_HEIGHT)
      .backgroundColor($r('app.color.background_primary'))
      .borderRadius({
        topLeft: DialogConstants.DIALOG.BORDER_RADIUS,
        topRight: DialogConstants.DIALOG.BORDER_RADIUS
      })
      .shadow(DesignConstants.SHADOW_LG)
      .translate({ y: this.translateY })
      .scale({ x: this.scaleValue, y: this.scaleValue })
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
              this.dragProgress = Math.min(1, deltaY / DialogConstants.GESTURE.MAX_DRAG_DISTANCE);
              this.bgOpacity = Math.max(0, DialogConstants.DIALOG.BACKGROUND_OPACITY * (1 - this.dragProgress));
              this.scaleValue = 1 - (this.dragProgress * DialogConstants.DIALOG.SCALE_FACTOR);
            }
          })
          .onActionEnd(() => {
            if (this.translateY > DialogConstants.DIALOG.DRAG_THRESHOLD) {
              this.closeDialog();
            } else {
              animateTo({
                duration: DialogConstants.ANIMATION.ENTER_DURATION,
                curve: Curve.EaseOut
              }, () => {
                this.translateY = 0;
                this.scaleValue = 1;
                this.dragProgress = 0;
                this.bgOpacity = DialogConstants.DIALOG.BACKGROUND_OPACITY;
              });
            }
          })
      )
      .animation({
        duration: DialogConstants.DIALOG.ANIMATION_DURATION,
        curve: Curve.EaseOut
      })
    }
    .width('100%')
    .hideBackButton(true)
    .backgroundBlurStyle(BlurStyle.BACKGROUND_REGULAR)
    .animation({
      duration: 300,
      curve: Curve.EaseOut,
      iterations: 1,
      playMode: PlayMode.Normal
    })
    .mode(NavDestinationMode.DIALOG)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [ LayoutSafeAreaEdge.BOTTOM])
    .onBackPressed(() => {
      this.closeDialog();
      return true;
    })
  }

  @BuilderParam
  ContentBuilder: (contentParam: Array<ImageSoundPlayerState>) => void
  @BuilderParam
  contentParam: Array<ImageSoundPlayerState>
}

@Builder
export function DialogContainerBuilder(contentBuilder: () => void, contentParam: Array<ImageSoundPlayerState>) {
  DialogContainer({ ContentBuilder: contentBuilder, contentParam: contentParam })
}
