import { PreferenceService, PreferenceValue } from '../../services/PreferenceService';
import { PreferenceKeyConstants } from '../../constants/PreferenceKeyConstants';
import { navigationStack } from '../../constants/ProviderConstant';

@Extend(Image)
function itemIcon() {
  .width(24)
  .height(24)
  .margin({ right: 8 })
}

@Extend(Text)
function itemTitle() {
  .fontWeight(FontWeight.Medium)
  .fontColor($r('app.color.text_primary'))
  .fontSize(16)
}

@Extend(Text)
function itemDescription() {
  .fontColor($r('app.color.text_secondary'))
  .fontSize(14)
  .textAlign(TextAlign.Start)
  .width( '100%')
  .margin({ left: 48 })
}

@Extend(Column)
function listItemStyle() {
  .width('100%')
  .padding({ left: 16, right: 16 })
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(Row)
function listItemRow() {
  .width('100%')
  .height(56)
  .alignItems(VerticalAlign.Center)
}

@Extend(ListItem)
function dividerStyle() {
  .width('100%')
  .height(1)
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(ListItem)
function descriptionContainer() {
  .backgroundColor($r('app.color.background_secondary'))
  .padding({ top: 8, bottom: 12 })
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
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.isNoiseAlarmEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.NOISE_ALARM_ENABLED, true);
    this.noiseThreshold = this.preferenceService.getNumber(PreferenceKeyConstants.NOISE_THRESHOLD, 80);
    this.updateNoiseAlarmDescription();
  }

  private updateNoiseAlarmDescription() {
    this.noiseAlarmDescription = this.isNoiseAlarmEnabled
      ? '检测到噪音超过阈值时将触发警报'
      : '系统不会发出噪音超标警报';
  }

  build() {
    Column() {
      // 页面标题
      Text('警报与通知')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 16, bottom: 16 })
        .width('100%')
        .textAlign(TextAlign.Center)

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
          .listItemStyle()
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
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ right: 8 })
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
              .margin({ top: 12, bottom: 12 })
              .height(24)
              .trackThickness(24)
              .blockSize({ width: 24, height: 24 })
          }
          .listItemStyle()
        }

        ListItem() {
          Text('环境噪音超过设定阈值时，系统将发出警报提示')
            .itemDescription()
        }
        .descriptionContainer()
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.background_tertiary'))
      .margin({ top: 12 })

      // 返回按钮
      Button('返回')
        .width('90%')
        .height(40)
        .margin({ bottom: 30, top: 12 })
        .backgroundColor($r('app.color.toggle_active'))
        .onClick(() => {
          this.navStack.pop();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_tertiary'))
  }
}
