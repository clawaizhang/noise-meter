import { PreferenceService, PreferenceValue } from '../../services/PreferenceService';
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

@ComponentV2
export struct DataPrivacySettings {
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  @Local isLocationEnabled: boolean = true;
  @Local isRecordEnabled: boolean = true;
  @Local gridColumns: number = 1;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.isLocationEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.LOCATION, true);
    this.isRecordEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.RECORD, true);

  }

  build() {
    NavDestination() {
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
          .cardStyle()
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
          .cardStyle()
        }

        ListItem() {
          Text(this.isRecordEnabled ? '保存原始音频数据用于后期分析' : '不会保存音频数据')
            .itemDescription()
        }
        .descriptionContainer()
      }

      .layoutWeight(1)
      .backgroundColor('transparent')

    }.title('数据记录与隐私')
  }
}

@Builder
export function DataPrivacySettingsBuilder() {
  DataPrivacySettings()
}