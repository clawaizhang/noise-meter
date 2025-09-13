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
      List() {
        // 后台运行设置
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_meter'))
                  .itemIcon()

                Text($r('app.string.background_running'))
                  .itemTitle()
              }

              Blank()

              Toggle({ type: ToggleType.Switch, isOn: this.isBackgroundRunning })
                .selectedColor($r('app.color.toggle_active'))
                .switchPointColor($r('app.color.background_primary'))
                .onChange((isOn: boolean) => {
                  void this.preferenceService.setBoolean(PreferenceKeyConstants.BACKGROUND_RUNNING, isOn);
                  this.isBackgroundRunning = isOn;
                })
            }
            .listItemRow()
          }
          .cardStyle()
        }

        ListItem() {
          Text(this.isBackgroundRunning ? $r('app.string.background_running_desc_on') :
          $r('app.string.background_running_desc_off'))
            .itemDescription()
        }
        .descriptionContainer()

        // 屏幕常亮设置
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_keep_screen_on'))
                  .itemIcon()

                Text('屏幕常亮')
                  .itemTitle()
              }

              Blank()

              Toggle({ type: ToggleType.Switch, isOn: this.isKeepScreenOn })
                .selectedColor($r('app.color.toggle_active'))
                .switchPointColor($r('app.color.background_primary'))
                .onChange((isOn: boolean) => {
                  void this.preferenceService.setBoolean(PreferenceKeyConstants.KEEP_SCREEN_ON, isOn);
                  this.isKeepScreenOn = isOn;
                })
            }
            .listItemRow()
          }
          .cardStyle()
        }

        ListItem() {
          Text(this.isKeepScreenOn ? '屏幕将保持常亮状态' : '屏幕会根据系统设置自动休眠')
            .itemDescription()
        }
        .descriptionContainer()
      }

      .layoutWeight(1)
      .backgroundColor('transparent')
    }

    .title('设备设置')
  }
}


@Builder
export function DeviceSettingsBuilder() {
  DeviceSettings()
}