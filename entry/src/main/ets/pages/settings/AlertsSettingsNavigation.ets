import { PreferenceService } from '../../services/PreferenceService';
import { PreferenceKeyConstants } from '../../constants/PreferenceKeyConstants';
import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';

@Extend(Image)
function itemIcon() {
  .width(DesignConstants.ICON_SIZE_MD)
  .height(DesignConstants.ICON_SIZE_MD)
  .margin({ right: DesignConstants.SPACING_MD })
}

@Extend(Text)
function itemTitle() {
  .fontWeight(FontWeight.Medium)
  .fontColor($r('app.color.text_primary'))
  .fontSize(DesignConstants.FONT_SIZE_LG)
}

@Extend(Text)
function itemDescription() {
  .fontColor($r('app.color.text_secondary'))
  .fontSize(DesignConstants.FONT_SIZE_MD)
  .textAlign(TextAlign.Start)

  .margin({ left: DesignConstants.SPACING_XL })
}

@Extend(Column)
function listItemStyle() {

  .padding({
    left: DesignConstants.SPACING_LG,
    right: DesignConstants.SPACING_LG
  })
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(Column)
function cardStyle() {
  .backgroundColor($r('app.color.background_secondary'))
  .borderRadius(12)
  .shadow({
    radius: 8,
    color: $r('app.color.shadow_medium'),
    offsetX: 0,
    offsetY: 2
  })
  .padding({
    top: DesignConstants.SPACING_MD,
    bottom: DesignConstants.SPACING_MD,
    left: DesignConstants.SPACING_LG,
    right: DesignConstants.SPACING_LG
  })
  .margin({
    top: DesignConstants.SPACING_MD,
    bottom: DesignConstants.SPACING_MD,
    left: DesignConstants.SPACING_MD,
    right: DesignConstants.SPACING_MD
  })
}

@Extend(Row)
function listItemRow() {

  .height(56)
  .alignItems(VerticalAlign.Center)
}

@Extend(ListItem)
function dividerStyle() {

  .height(1)
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(ListItem)
function descriptionContainer() {
  .backgroundColor($r('app.color.background_secondary'))
  .padding({
    top: DesignConstants.SPACING_SM,
    bottom: DesignConstants.SPACING_MD
  })
}


@Builder
export function AlertsSettingsBuilder() {
  AlertsSettings()
}

@ComponentV2
export struct AlertsSettings {
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  @Local isNoiseAlarmEnabled: boolean = true;
  @Local noiseThreshold: number = 80;
  @Local noiseAlarmDescription: string = '';
  @Local gridColumns: number = 1;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.isNoiseAlarmEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.NOISE_ALARM_ENABLED, true);
    this.noiseThreshold = this.preferenceService.getNumber(PreferenceKeyConstants.NOISE_THRESHOLD, 80);
  }

  private updateNoiseAlarmDescription() {
    this.noiseAlarmDescription = this.isNoiseAlarmEnabled
      ? '检测到噪音超过阈值时将触发警报'
      : '系统不会发出噪音超标警报';
  }

  build() {
    NavDestination() {
      // 列表布局（保持原有代码）
      List() {
        // 噪音阈值警报的开关
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_alarm'))
                  .itemIcon()

                Text('噪音警报')
                  .itemTitle()
              }

              Blank()

              Toggle({ type: ToggleType.Switch, isOn: this.isNoiseAlarmEnabled })
                .selectedColor($r('app.color.primary'))
                .switchPointColor($r('app.color.background_primary'))
                .onChange((isOn: boolean) => {
                  void this.preferenceService.setBoolean(PreferenceKeyConstants.NOISE_ALARM_ENABLED, isOn);
                  this.isNoiseAlarmEnabled = isOn;
                  this.updateNoiseAlarmDescription();
                })
            }
            .listItemRow()
          }
          .cardStyle()
        }

        ListItem() {
          Text(this.noiseAlarmDescription)
            .itemDescription()
        }
        .descriptionContainer()

        // 噪音阈值的设置
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_threshold'))
                  .itemIcon()

                Text('噪音警报阈值')
                  .itemTitle()
              }

              Blank()

              Text(`${this.noiseThreshold}dB`)
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('app.color.text_secondary'))
                .margin({ right: DesignConstants.SPACING_MD })
            }
            .listItemRow()

            Slider({
              value: this.noiseThreshold,
              min: 30,
              max: 120,
              style: SliderStyle.InSet
            })
              .blockColor($r('app.color.primary'))
              .trackColor($r('app.color.background_secondary'))
              .selectedColor($r('app.color.primary'))
              .onChange((value: number) => {
                this.noiseThreshold = value;
                void this.preferenceService.setNumber(PreferenceKeyConstants.NOISE_THRESHOLD, value);
              })
              .margin({
                top: DesignConstants.SPACING_MD,
                bottom: DesignConstants.SPACING_MD
              })
              .height(24)
              .trackThickness(24)
              .blockSize({ width: 24, height: 24 })
          }
          .cardStyle()
        }

        ListItem() {
          Text('环境噪音超过设定阈值时，系统将发出警报提示')
            .itemDescription()
        }
        .descriptionContainer()
      }

      .layoutWeight(1)
      .backgroundColor('transparent')
    }.title('警报与通知')
  }
}
