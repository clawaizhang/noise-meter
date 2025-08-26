import { PreferenceService, PreferenceValue } from '../services/PreferenceService';
import { PreferenceKeyConstants } from '../constants/PreferenceKeyConstants';
import { navigationStack } from '../constants/ProviderConstant';

@Extend(Image)
function itemIcon() {
  .width(24)
  .height(24)
  .margin({ right: 12 })
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
  .margin({ left: 36, top: 4 })
}

@Extend(Column)
function listItemStyle() {
  .width('100%')
  .padding({ left: 24, right: 24 })
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(Row)
function listItemRow() {
  .width('100%')
  .height(64)
  .alignItems(VerticalAlign.Center)
}

@Extend(ListItem)
function dividerStyle() {
  .width('100%')
  .height(0.5)
  .backgroundColor($r('app.color.divider'))
  .margin({ left: 24, right: 24 })
}

@Extend(ListItem)
function descriptionContainer() {
  .backgroundColor($r('app.color.background_secondary'))
  .padding({ top: 8, bottom: 16, left: 24, right: 24 })
}

@Extend(Image)
function arrowIcon() {
  .width(20)
  .height(20)
  .fillColor($r('app.color.text_tertiary'))
}

@Extend(Column)
function listItemWithDescription() {
  .width('100%')
  .padding({ left: 24, right: 24, top: 16, bottom: 16 })
  .backgroundColor($r('app.color.background_secondary'))
}

@ComponentV2
export struct Settings {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    // 初始化设置
  }

  // 导航到音频分析设置页面
  private navigateToAudioAnalysis() {
    this.navStack.pushPathByName('AudioAnalysisSettings', null);
  }

  // 导航到警报与通知设置页面
  private navigateToAlerts() {
    this.navStack.pushPathByName('AlertsSettings', null);
  }

  // 导航到数据记录与隐私设置页面
  private navigateToDataPrivacy() {
    this.navStack.pushPathByName('DataPrivacySettings', null);
  }

  // 导航到设备设置页面
  private navigateToDeviceSettings() {
    this.navStack.pushPathByName('DeviceSettings', null);
  }

  // 导航到关于页面
  private navigateToAbout() {
    this.navStack.pushPathByName('AboutSettings', null);
  }

  build() {
    Column() {
      List() {
        // 音频分析设置
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_audio_analysis'))
                  .itemIcon()

                Text('音频分析设置')
                  .itemTitle()
              }

              Blank()

              Image($r('app.media.ic_arrow_right'))
                .arrowIcon()
            }
            .listItemRow()

            Text('时间计权模式、频率加权、声级校准等设置')
              .itemDescription()
          }
          .listItemWithDescription()
        }.onClick(() => {
          this.navigateToAudioAnalysis();
        })

        ListItem() {
        }.dividerStyle()

        // 警报与通知
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_alarm'))
                  .itemIcon()

                Text('警报与通知')
                  .itemTitle()
              }

              Blank()

              Image($r('app.media.ic_arrow_right'))
                .arrowIcon()
            }
            .listItemRow()

            Text('噪音警报阈值和通知设置')
              .itemDescription()
          }
          .listItemWithDescription()
        }.onClick(() => {
          this.navigateToAlerts();
        })

        ListItem() {
        }.dividerStyle()

        // 数据记录与隐私
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_security'))
                  .itemIcon()

                Text('数据记录与隐私')
                  .itemTitle()
              }

              Blank()

              Image($r('app.media.ic_arrow_right'))
                .arrowIcon()
            }
            .listItemRow()

            Text('地理位置、音频记录等隐私设置')
              .itemDescription()
          }
          .listItemWithDescription()
        }.onClick(() => {
          this.navigateToDataPrivacy();
        })

        ListItem() {
        }.dividerStyle()

        // 设备设置
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_settings'))
                  .itemIcon()

                Text('设备设置')
                  .itemTitle()
              }

              Blank()

              Image($r('app.media.ic_arrow_right'))
                .arrowIcon()
            }
            .listItemRow()

            Text('屏幕常亮、后台运行等设备设置')
              .itemDescription()
          }
          .listItemWithDescription()
        }.onClick(() => {
          this.navigateToDeviceSettings();
        })

        ListItem() {
        }.dividerStyle()

        // 关于
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_info'))
                  .itemIcon()

                Text('关于')
                  .itemTitle()
              }

              Blank()

              Image($r('app.media.ic_arrow_right'))
                .arrowIcon()
            }
            .listItemRow()

            Text('应用信息、隐私政策和技术支持')
              .itemDescription()
          }
          .listItemWithDescription()
        }.onClick(() => {
          this.navigateToAbout();
        })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.background_primary'))
      .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
  }
}