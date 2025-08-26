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
  .width('100%')
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
export struct DeviceSettings {
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  @Local isKeepScreenOn: boolean = true;
  @Local isBackgroundRunning: boolean = false;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.isKeepScreenOn = this.preferenceService.getBoolean(PreferenceKeyConstants.KEEP_SCREEN_ON, true);
    this.isBackgroundRunning = this.preferenceService.getBoolean(PreferenceKeyConstants.BACKGROUND_RUNNING, false);
  }

  build() {
    NavDestination() {

      Column() {

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
            .listItemStyle()
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
            .listItemStyle()
          }

          ListItem() {
            Text(this.isKeepScreenOn ? '屏幕将保持常亮状态' : '屏幕会根据系统设置自动休眠')
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
    }.title('设备设置')
  }
}

@Builder
export function DeviceSettingsBuilder() {
  DeviceSettings()
}