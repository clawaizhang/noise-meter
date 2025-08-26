import { PreferenceService, PreferenceValue } from '../services/PreferenceService';
import { PreferenceKeyConstants } from '../constants/PreferenceKeyConstants';
import { navigationStack } from '../constants/ProviderConstant';

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

              Image($r('app.media.app_icon_back'))
                .width(16)
                .height(16)
                .fillColor($r('app.color.text_secondary'))
            }
            .listItemRow()
          }
          .listItemStyle()
        }.onClick(() => {
          this.navigateToAudioAnalysis();
        })

        ListItem() {
          Text('时间计权模式、频率加权、声级校准等设置')
            .itemDescription()
        }
        .descriptionContainer()

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

              Text('>')
                .fontSize(18)
                .fontColor($r('app.color.text_secondary'))
            }
            .listItemRow()
          }
          .listItemStyle()
        }.onClick(() => {
          this.navigateToAlerts();
        })

        ListItem() {
          Text('噪音警报阈值和通知设置')
            .itemDescription()
        }
        .descriptionContainer()

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

              Text('>')
                .fontSize(18)
                .fontColor($r('app.color.text_secondary'))
            }
            .listItemRow()
          }
          .listItemStyle()
        }.onClick(() => {
          this.navigateToDataPrivacy();
        })

        ListItem() {
          Text('地理位置、音频记录等隐私设置')
            .itemDescription()
        }
        .descriptionContainer()

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

              Text('>')
                .fontSize(18)
                .fontColor($r('app.color.text_secondary'))
            }
            .listItemRow()
          }
          .listItemStyle()
        }.onClick(() => {
          this.navigateToDeviceSettings();
        })

        ListItem() {
          Text('屏幕常亮、后台运行等设备设置')
            .itemDescription()
        }
        .descriptionContainer()

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

              Text('>')
                .fontSize(18)
                .fontColor($r('app.color.text_secondary'))
            }
            .listItemRow()
          }
          .listItemStyle()
        }.onClick(() => {
          this.navigateToAbout();
        })

        ListItem() {
          Text('应用信息、隐私政策和技术支持')
            .itemDescription()
        }
        .descriptionContainer()
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.background_tertiary'))
      .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_tertiary'))
  }
}