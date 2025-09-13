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

  .margin({
    left: DesignConstants.SPACING_XL,
    top: DesignConstants.SPACING_XS
  })
}

@Extend(Column)
function listItemStyle() {

  .padding({
    left: DesignConstants.SPACING_LG,
    right: DesignConstants.SPACING_LG
  })
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(Row)
function listItemRow() {

  .height(64)
  .alignItems(VerticalAlign.Center)
}

@Extend(ListItem)
function dividerStyle() {

  .height(0.5)
  .backgroundColor($r('app.color.divider'))
  .margin({
    left: DesignConstants.SPACING_LG,
    right: DesignConstants.SPACING_LG
  })
}

@Extend(ListItem)
function descriptionContainer() {
  .backgroundColor($r('app.color.background_secondary'))
  .padding({
    top: DesignConstants.SPACING_SM,
    bottom: DesignConstants.SPACING_LG,
    left: DesignConstants.SPACING_LG,
    right: DesignConstants.SPACING_LG
  })
}

@Extend(Image)
function arrowIcon() {
  .width(DesignConstants.ICON_SIZE_SM)
  .height(DesignConstants.ICON_SIZE_SM)
  .fillColor($r('app.color.text_tertiary'))
}

@Extend(Column)
function listItemWithDescription() {

  .padding({
    left: DesignConstants.SPACING_LG,
    right: DesignConstants.SPACING_LG,
    top: DesignConstants.SPACING_LG,
    bottom: DesignConstants.SPACING_LG
  })
  .backgroundColor($r('app.color.background_secondary'))
}

@Builder
function SettingsBuilder() {
  Settings()
}

@ComponentV2
export struct Settings {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  @Local isLandscape: boolean = false;
  @Local gridColumns: number = 1;

  aboutToAppear() {
  }

  // 导航到音频分析设置页面
  private navigateToAudioAnalysis = () => {
    this.navStack.pushPathByName('AudioAnalysisSettings', null);
  }
  // 导航到警报与通知设置页面
  private navigateToAlerts = () => {
    this.navStack.pushPathByName('AlertsSettings', null);
  }
  // 导航到数据记录与隐私设置页面
  private navigateToDataPrivacy = () => {
    this.navStack.pushPathByName('DataPrivacySettings', null);
  }
  // 导航到设备设置页面
  private navigateToDeviceSettings = () => {
    this.navStack.pushPathByName('DeviceSettings', null);
  }
  // 导航到关于页面
  private navigateToAbout = () => {
    this.navStack.pushPathByName('AboutSettings', null);
  }

  build() {
    NavDestination() {
      Column() {
          this.ListLayoutView()
      }


      .backgroundColor($r('app.color.background_primary'))
    }.title('设置')
  }

  /**
   * 列表布局视图
   */
  @Builder
  ListLayoutView() {
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

    .layoutWeight(1)
    .backgroundColor($r('app.color.background_primary'))
    .margin({ top: DesignConstants.SPACING_LG })
  }

}