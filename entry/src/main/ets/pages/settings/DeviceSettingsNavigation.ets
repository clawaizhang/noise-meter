import { PreferenceService, PreferenceValue } from '../../services/PreferenceService';
import { PreferenceKeyConstants } from '../../constants/PreferenceKeyConstants';
import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';
import { curves } from '@kit.ArkUI';

@Extend(Image)
function itemIcon() {
  .width(DesignConstants.ICON_SIZE_MD)
  .height(DesignConstants.ICON_SIZE_MD)
  .fillColor($r('sys.color.background_secondary'))
}

@Extend(Text)
function itemTitle() {
  .fontWeight(FontWeight.Medium)
}

@Extend(Text)
function itemDescription() {
  .fontColor($r('sys.color.font_secondary'))
  .fontSize(DesignConstants.FONT_SIZE_MD)
  .textAlign(TextAlign.Start)
  .alignSelf(ItemAlign.Start)
}

@Extend(Column)
function cardStyle() {
  .backgroundColor($r('sys.color.background_secondary'))
  .justifyContent(FlexAlign.Start)
  .alignItems(HorizontalAlign.Start)
  .borderRadius(16)
  .padding(16)
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
    .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
    .combine(TransitionEffect.translate({ y: 150 }).animation({ curve: curves.springMotion() })))
}

@Extend(Row)
function listItemRow() {
  .alignItems(VerticalAlign.Center)
  .justifyContent(FlexAlign.Start)
}

@ComponentV2
export struct DeviceSettings {
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  @Local isKeepScreenOn: boolean = true;
  @Local isBackgroundRunning: boolean = false;
  @Local gridColumns: number = 1;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.isKeepScreenOn = this.preferenceService.getBoolean(PreferenceKeyConstants.KEEP_SCREEN_ON, true);
    this.isBackgroundRunning = this.preferenceService.getBoolean(PreferenceKeyConstants.BACKGROUND_RUNNING, false);
  }

  build() {
    NavDestination() {
      Scroll() {
        GridRow({
          columns:
          {
            sm: 1,
            md: 2,
            lg: 2,
            xl: 3
          },
          breakpoints: { reference: BreakpointsReference.WindowSize }
        , gutter: 16
        }) {
          // 后台运行设置
          GridCol() {
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                Row() {
                  Image($r('app.media.ic_meter'))
                    .itemIcon()

                  Text($r('app.string.background_running'))
                    .itemTitle()
                }.layoutWeight(1)

                Toggle({ type: ToggleType.Switch, isOn: this.isBackgroundRunning })
                  .selectedColor($r('app.color.toggle_active'))
                  .switchPointColor($r('app.color.background_primary'))
                  .onChange((isOn: boolean) => {
                    void this.preferenceService.setBoolean(PreferenceKeyConstants.BACKGROUND_RUNNING, isOn);
                    this.isBackgroundRunning = isOn;
                  })
              }
              .listItemRow()

              Text(this.isBackgroundRunning ? $r('app.string.background_running_desc_on') :
              $r('app.string.background_running_desc_off'))
                .itemDescription()
            }
            .cardStyle()
          }

          // 屏幕常亮设置
          GridCol() {
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                Row() {
                  Image($r('app.media.ic_keep_screen_on'))
                    .itemIcon()

                  Text('屏幕常亮')
                    .itemTitle()
                }.layoutWeight(1)

                Toggle({ type: ToggleType.Switch, isOn: this.isKeepScreenOn })
                  .selectedColor($r('app.color.toggle_active'))
                  .switchPointColor($r('app.color.background_primary'))
                  .onChange((isOn: boolean) => {
                    void this.preferenceService.setBoolean(PreferenceKeyConstants.KEEP_SCREEN_ON, isOn);
                    this.isKeepScreenOn = isOn;
                  })
              }
              .listItemRow()

              Text(this.isKeepScreenOn ? '屏幕将保持常亮状态' : '屏幕会根据系统设置自动休眠')
                .itemDescription()
            }
            .cardStyle()
          }
        }
      }.scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)

    }.backgroundColor($r('sys.color.background_primary')).padding(16)
    .title('设备设置')
  }
}


@Builder
export function DeviceSettingsBuilder() {
  DeviceSettings()
}