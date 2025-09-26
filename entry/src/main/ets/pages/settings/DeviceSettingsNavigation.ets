import { PreferenceKeys } from '../../models/PreferenceKeys';
import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';
import { curves, PersistenceV2 } from '@kit.ArkUI';

@Extend(Image)
function itemIcon() {
  .width(DesignConstants.ICON_SIZE_MD)
  .height(DesignConstants.ICON_SIZE_MD)
  .fillColor($r('sys.color.font_primary'))
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
  .backgroundColor($r('sys.color.comp_background_primary'))
  .justifyContent(FlexAlign.Start)
  .alignItems(HorizontalAlign.Start)
  .borderRadius(16)
  .padding(16)
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
    .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
    .combine(TransitionEffect.translate({ x: -150, y: 0 }).animation({ curve: curves.springMotion() })))
}

@Extend(Row)
function listItemRow() {
  .alignItems(VerticalAlign.Center)
  .justifyContent(FlexAlign.Start)
}

@ComponentV2
export struct DeviceSettings {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local gridColumns: number = 1;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
  }

  build() {
    GridRow({
      columns:
      1,
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

            Toggle({ type: ToggleType.Switch, isOn: this.pk.background_running })
              .selectedColor($r('app.color.toggle_active'))
              .switchPointColor($r('app.color.background_primary'))
              .onChange((isOn: boolean) => {
                this.pk.background_running = isOn;
              })
          }
          .listItemRow()

          Text(this.pk.background_running ? $r('app.string.background_running_desc_on') :
          $r('app.string.background_running_desc_off'))
            .itemDescription()
        }
        .cardStyle()
      }

      // 屏幕常亮设置
      // GridCol() {
      //   Column({ space: 8 }) {
      //     Row({ space: 8 }) {
      //       Row() {
      //         Image($r('app.media.ic_keep_screen_on'))
      //           .itemIcon()
      //
      //         Text('屏幕常亮')
      //           .itemTitle()
      //       }.layoutWeight(1)
      //
      //       Toggle({ type: ToggleType.Switch, isOn: this.pk.keep_screen_on })
      //         .selectedColor($r('app.color.toggle_active'))
      //         .switchPointColor($r('app.color.background_primary'))
      //         .onChange((isOn: boolean) => {
      //           this.pk.keep_screen_on = isOn;
      //         })
      //     }
      //     .listItemRow()
      //
      //     Text(this.pk.keep_screen_on ? '屏幕将保持常亮状态' : '屏幕会根据系统设置自动休眠')
      //       .itemDescription()
      //   }
      //   .cardStyle()
      // }
    }.backgroundColor($r('sys.color.background_secondary')).padding(16)
  }
}


@Builder
export function DeviceSettingsBuilder() {
  DeviceSettings()
}