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
    .combine(TransitionEffect.translate({ x: 0, y: 0 }).animation({ curve: curves.springMotion() })))
}

@Extend(Row)
function listItemRow() {
  .alignItems(VerticalAlign.Center)
  .justifyContent(FlexAlign.Start)
}

@Builder
export function AlertsSettingsBuilder() {
  AlertsSettings()
}

@ComponentV2
export struct AlertsSettings {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  @Local noiseAlarmDescription: string = '';
  @Local gridColumns: number = 1;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
  }

  private updateNoiseAlarmDescription() {
    this.noiseAlarmDescription = this.pk.noise_alarm_enabled
      ? '检测到噪音超过阈值时将触发警报'
      : '系统不会发出噪音超标警报';
  }

  build() {
    // 列表布局（保持原有代码）
    GridRow({
      columns:
      1,
      breakpoints: { reference: BreakpointsReference.WindowSize }
    , gutter: 16
    }) {
      // 噪音阈值警报的开关
      GridCol() {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Row() {
              Image($r('app.media.ic_alarm'))
                .itemIcon()

              Text('噪音警报')
                .itemTitle()
            }.layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.pk.noise_alarm_enabled })
              .onChange((isOn: boolean) => {
                this.pk.noise_alarm_enabled = isOn;
                this.updateNoiseAlarmDescription();
              })
          }
          .listItemRow()

          Text(this.noiseAlarmDescription)
            .itemDescription()
        }
        .cardStyle()
      }

      // 噪音阈值的设置
      GridCol() {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Row() {
              Image($r('app.media.ic_threshold'))
                .itemIcon()
              Text('噪音警报阈值')
                .itemTitle()
            }.layoutWeight(1)

            Text(`${this.pk.noise_threshold}dB`)
              .fontSize(DesignConstants.FONT_SIZE_MD)
          }
          .listItemRow()

          Slider({
            value: this.pk.noise_threshold,
            min: 30,
            max: 120,
            style: SliderStyle.InSet
          })
            .blockColor($r('app.color.primary'))
            .trackColor($r('app.color.background_secondary'))
            .selectedColor($r('app.color.primary'))
            .onChange((value: number) => {
              this.pk.noise_threshold = value;
            })
            .margin({
              top: DesignConstants.SPACING_MD,
              bottom: DesignConstants.SPACING_MD
            })
            .height(24)
            .trackThickness(24)
            .blockSize({ width: 24, height: 24 })
          Text('环境噪音超过设定阈值时，系统将发出警报提示')
            .itemDescription()
        }
        .cardStyle()
      }
    }
    .padding(16).backgroundColor($r('sys.color.background_secondary'))
  }
}
