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
  .padding(16)    .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
    .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
    .combine(TransitionEffect.translate({ y: 150 }).animation({ curve: curves.springMotion() })))
}

@Extend(Row)
function listItemRow() {
  .alignItems(VerticalAlign.Center)
  .justifyContent(FlexAlign.Start)
}

@ComponentV2
export struct DataPrivacySettings {
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  @Local isLocationEnabled: boolean = true;
  @Local isRecordEnabled: boolean = true;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.isLocationEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.LOCATION, true);
    this.isRecordEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.RECORD, true);

  }

  build() {
    NavDestination() {
      Scroll(){
        GridRow({
          columns:
          {
            sm: 1,
            md: 2,
            lg:2,
            xl:3
          },
          breakpoints: { reference: BreakpointsReference.WindowSize }
        , gutter: 16
        }) {
          // 位置开关
          GridCol() {
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                Row() {
                  Image($r('app.media.ic_location'))
                    .itemIcon()

                  Text('地理位置')
                    .itemTitle()
                }.layoutWeight(1)

                Toggle({ type: ToggleType.Switch, isOn: this.isLocationEnabled })
                  .selectedColor($r('app.color.toggle_active'))
                  .switchPointColor($r('app.color.background_primary'))
                  .onChange((isOn: boolean) => {
                    void this.preferenceService.setBoolean(PreferenceKeyConstants.LOCATION, isOn);
                    this.isLocationEnabled = isOn;
                  })
              }
              .listItemRow()

              Text(this.isLocationEnabled ? '记录检测地点的位置信息' : '不会采集地理位置信息')
                .itemDescription()
            }
            .cardStyle()
          }

          // 录音开关
          GridCol() {
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                Row() {
                  Image($r('app.media.ic_mic'))
                    .itemIcon()

                  Text('音频记录')
                    .itemTitle()
                }.layoutWeight(1)

                Toggle({ type: ToggleType.Switch, isOn: this.isRecordEnabled })
                  .selectedColor($r('app.color.toggle_active'))
                  .switchPointColor($r('app.color.background_primary'))
                  .onChange((isOn: boolean) => {
                    void this.preferenceService.setBoolean(PreferenceKeyConstants.RECORD, isOn);
                    this.isRecordEnabled = isOn;
                  })
              }
              .listItemRow()

              Text(this.isRecordEnabled ? '保存原始音频数据用于后期分析' : '不会保存音频数据')
                .itemDescription()
            }
            .cardStyle()
          }
        }
      }.scrollBar(BarState.Off)      .edgeEffect(EdgeEffect.Spring)

    }.backgroundColor($r('sys.color.background_primary')).padding(16).title('数据记录与隐私')
  }
}

@Builder
export function DataPrivacySettingsBuilder() {
  DataPrivacySettings()
}