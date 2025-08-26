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
    Column() {
      // 页面标题
      Text('数据记录与隐私')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 16, bottom: 16 })
        .width('100%')
        .textAlign(TextAlign.Center)

      List() {
        // 位置开关
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_location'))
                  .itemIcon()

                Text('地理位置')
                  .itemTitle()
              }

              Blank()

              Toggle({ type: ToggleType.Switch, isOn: this.isLocationEnabled })
                .selectedColor($r('app.color.toggle_active'))
                .switchPointColor($r('app.color.background_primary'))
                .onChange((isOn: boolean) => {
                  void this.preferenceService.setBoolean(PreferenceKeyConstants.LOCATION, isOn);
                  this.isLocationEnabled = isOn;
                })
            }
            .listItemRow()
          }
          .listItemStyle()
        }

        ListItem() {
          Text(this.isLocationEnabled ? '记录检测地点的位置信息' : '不会采集地理位置信息')
            .itemDescription()
        }
        .descriptionContainer()

        // 录音开关
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_mic'))
                  .itemIcon()

                Text('音频记录')
                  .itemTitle()
              }

              Blank()

              Toggle({ type: ToggleType.Switch, isOn: this.isRecordEnabled })
                .selectedColor($r('app.color.toggle_active'))
                .switchPointColor($r('app.color.background_primary'))
                .onChange((isOn: boolean) => {
                  void this.preferenceService.setBoolean(PreferenceKeyConstants.RECORD, isOn);
                  this.isRecordEnabled = isOn;
                })
            }
            .listItemRow()
          }
          .listItemStyle()
        }

        ListItem() {
          Text(this.isRecordEnabled ? '保存原始音频数据用于后期分析' : '不会保存音频数据')
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

@Builder
export function DataPrivacySettingsBuilder() {
  DataPrivacySettings()
}