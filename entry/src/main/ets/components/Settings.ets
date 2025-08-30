import { PreferenceService, PreferenceValue } from '../services/PreferenceService';
import { PreferenceKeyConstants } from '../constants/PreferenceKeyConstants';
import { navigationStack } from '../constants/ProviderConstant';
import {
  responsiveLayout,
  responsiveFontSize,
  responsiveIconSize,
  responsiveListItemSpacing,
  responsiveListItemPadding,
  responsiveListItemMargin,
  Breakpoint,
  LayoutMode,
  ListItemLayoutMode
} from '../utils/ResponsiveLayout';
import { DesignConstants } from '../constants/DesignConstants';

@Extend(Image)
function itemIcon() {
  .width(responsiveIconSize(DesignConstants.ICON_SIZE_MD))
  .height(responsiveIconSize(DesignConstants.ICON_SIZE_MD))
  .margin({ right: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
}

@Extend(Text)
function itemTitle() {
  .fontWeight(FontWeight.Medium)
  .fontColor($r('app.color.text_primary'))
  .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_LG))
}

@Extend(Text)
function itemDescription() {
  .fontColor($r('app.color.text_secondary'))
  .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
  .textAlign(TextAlign.Start)
  .width('100%')
  .margin({
    left: responsiveListItemSpacing(DesignConstants.SPACING_XL),
    top: responsiveListItemSpacing(DesignConstants.SPACING_XS)
  })
}

@Extend(Column)
function listItemStyle() {
  .width('100%')
  .padding({
    left: responsiveListItemPadding(DesignConstants.SPACING_LG),
    right: responsiveListItemPadding(DesignConstants.SPACING_LG)
  })
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(Row)
function listItemRow() {
  .width('100%')
  .height(responsiveListItemSpacing(64))
  .alignItems(VerticalAlign.Center)
}

@Extend(ListItem)
function dividerStyle() {
  .width('100%')
  .height(0.5)
  .backgroundColor($r('app.color.divider'))
  .margin({
    left: responsiveListItemMargin(DesignConstants.SPACING_LG),
    right: responsiveListItemMargin(DesignConstants.SPACING_LG)
  })
}

@Extend(ListItem)
function descriptionContainer() {
  .backgroundColor($r('app.color.background_secondary'))
  .padding({
    top: responsiveListItemPadding(DesignConstants.SPACING_SM),
    bottom: responsiveListItemPadding(DesignConstants.SPACING_LG),
    left: responsiveListItemPadding(DesignConstants.SPACING_LG),
    right: responsiveListItemPadding(DesignConstants.SPACING_LG)
  })
}

@Extend(Image)
function arrowIcon() {
  .width(responsiveIconSize(DesignConstants.ICON_SIZE_SM))
  .height(responsiveIconSize(DesignConstants.ICON_SIZE_SM))
  .fillColor($r('app.color.text_tertiary'))
}

@Extend(Column)
function listItemWithDescription() {
  .width('100%')
  .padding({
    left: responsiveListItemPadding(DesignConstants.SPACING_LG),
    right: responsiveListItemPadding(DesignConstants.SPACING_LG),
    top: responsiveListItemPadding(DesignConstants.SPACING_LG),
    bottom: responsiveListItemPadding(DesignConstants.SPACING_LG)
  })
  .backgroundColor($r('app.color.background_secondary'))
}

@ComponentV2
export struct Settings {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  @Local currentListItemLayoutMode: ListItemLayoutMode = ListItemLayoutMode.LIST;
  @Local isLandscape: boolean = false;
  @Local gridColumns: number = 1;

  aboutToAppear() {
    // 初始化响应式布局
    this.initializeResponsiveLayout();
  }

  /**
   * 初始化响应式布局监听
   */
  private initializeResponsiveLayout(): void {
    // 获取初始布局模式
    const screenInfo = responsiveLayout.getCurrentScreenInfo();
    this.currentListItemLayoutMode = screenInfo.listItemLayoutMode;
    this.isLandscape = screenInfo.isLandscape;
    this.updateGridColumns(screenInfo.breakpoint, screenInfo.isLandscape);

    // 注册布局变化监听器
    responsiveLayout.addChangeListener((width: number, height: number, breakpoint: Breakpoint,
      layoutMode: LayoutMode, listItemLayoutMode: ListItemLayoutMode, isLandscape: boolean) => {
      this.currentListItemLayoutMode = listItemLayoutMode;
      this.isLandscape = isLandscape;
      this.updateGridColumns(breakpoint, isLandscape);
    });
  }

  /**
   * 根据断点和屏幕方向更新网格列数
   */
  private updateGridColumns(breakpoint: Breakpoint, isLandscape: boolean): void {
    if (this.currentListItemLayoutMode === ListItemLayoutMode.GRID) {
      if (isLandscape) {
        // 横屏模式下增加列数
        switch (breakpoint) {
          case Breakpoint.XS:
          case Breakpoint.SM:
            this.gridColumns = 2;
            break;
          case Breakpoint.MD:
            this.gridColumns = 3;
            break;
          case Breakpoint.LG:
            this.gridColumns = 4;
            break;
          case Breakpoint.XL:
            this.gridColumns = 5;
            break;
          default:
            this.gridColumns = 2;
        }
      } else {
        // 竖屏模式下
        switch (breakpoint) {
          case Breakpoint.XS:
            this.gridColumns = 1;
            break;
          case Breakpoint.SM:
            this.gridColumns = 2;
            break;
          case Breakpoint.MD:
            this.gridColumns = 2;
            break;
          case Breakpoint.LG:
            this.gridColumns = 3;
            break;
          case Breakpoint.XL:
            this.gridColumns = 4;
            break;
          default:
            this.gridColumns = 2;
        }
      }
    } else {
      // 非网格布局时使用单列
      this.gridColumns = 1;
    }
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
    Column() {
      // 根据布局模式选择不同的渲染方式
      if (this.currentListItemLayoutMode === ListItemLayoutMode.GRID && this.isLandscape) {
        this.GridLayoutView()
      } else {
        this.ListLayoutView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
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
    .width('100%')
    .layoutWeight(1)
    .backgroundColor($r('app.color.background_primary'))
    .margin({ top: responsiveListItemSpacing(DesignConstants.SPACING_LG) })
  }

  /**
   * 网格布局视图 - 横屏模式下使用
   */
  @Builder
  GridLayoutView() {
    Scroll() {
      GridRow({
        columns: {
          xs: 1,
          sm: 2,
          md: 3,
          lg: 4,
          xl: 5
        },
        gutter: {
          x: {
            xs: responsiveListItemSpacing(DesignConstants.SPACING_SM),
            sm: responsiveListItemSpacing(DesignConstants.SPACING_MD),
            md: responsiveListItemSpacing(DesignConstants.SPACING_MD),
            lg: responsiveListItemSpacing(DesignConstants.SPACING_MD),
            xl: responsiveListItemSpacing(DesignConstants.SPACING_MD)
          },
          y: {
            xs: responsiveListItemSpacing(DesignConstants.SPACING_SM),
            sm: responsiveListItemSpacing(DesignConstants.SPACING_MD),
            md: responsiveListItemSpacing(DesignConstants.SPACING_MD),
            lg: responsiveListItemSpacing(DesignConstants.SPACING_MD),
            xl: responsiveListItemSpacing(DesignConstants.SPACING_MD)
          }
        },
        breakpoints: {
          value: ['320vp', '600vp', '840vp', '1080vp', '1320vp']
        }
      }) {
        // 音频分析设置卡片
        GridCol({
          span: {
            xs: 1,
            sm: 1,
            md: 1,
            lg: 1,
            xl: 1
          }
        }) {
          Column() {
            this.GridSettingItem(
              $r('app.media.ic_audio_analysis'),
              '音频分析',
              '时间计权、频率加权设置',
              this.navigateToAudioAnalysis
            )
          }
          .width('100%')
          .margin({ bottom: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
        }

        // 警报与通知卡片
        GridCol({
          span: {
            xs: 1,
            sm: 1,
            md: 1,
            lg: 1,
            xl: 1
          }
        }) {
          Column() {
            this.GridSettingItem(
              $r('app.media.ic_alarm'),
              '警报与通知',
              '噪音阈值警报设置',
              this.navigateToAlerts
            )
          }
          .width('100%')
          .margin({ bottom: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
        }

        // 数据记录与隐私卡片
        GridCol({
          span: {
            xs: 1,
            sm: 1,
            md: 1,
            lg: 1,
            xl: 1
          }
        }) {
          Column() {
            this.GridSettingItem(
              $r('app.media.ic_security'),
              '数据隐私',
              '地理位置、录音设置',
              this.navigateToDataPrivacy
            )
          }
          .width('100%')
          .margin({ bottom: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
        }

        // 设备设置卡片
        GridCol({
          span: {
            xs: 1,
            sm: 1,
            md: 1,
            lg: 1,
            xl: 1
          }
        }) {
          Column() {
            this.GridSettingItem(
              $r('app.media.ic_settings'),
              '设备设置',
              '屏幕常亮、后台运行',
              this.navigateToDeviceSettings
            )
          }
          .width('100%')
          .margin({ bottom: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
        }

        // 关于卡片
        GridCol({
          span: {
            xs: 1,
            sm: 1,
            md: 1,
            lg: 1,
            xl: 1
          }
        }) {
          Column() {
            this.GridSettingItem(
              $r('app.media.ic_info'),
              '关于',
              '应用信息、技术支持',
              this.navigateToAbout
            )
          }
          .width('100%')
          .margin({ bottom: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
        }
      }
      .width('100%')
      .padding({
        left: responsiveListItemPadding(DesignConstants.SPACING_MD),
        right: responsiveListItemPadding(DesignConstants.SPACING_MD),
        top: responsiveListItemPadding(DesignConstants.SPACING_MD),
        bottom: responsiveListItemPadding(DesignConstants.SPACING_MD)
      })
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 网格布局下的设置项组件
   */
  @Builder
  GridSettingItem(icon: Resource, title: string, description: string, onClick: () => void) {
    Column() {
      // 图标区域
      Row() {
        Image(icon)
          .width(responsiveIconSize(DesignConstants.ICON_SIZE_XL))
          .height(responsiveIconSize(DesignConstants.ICON_SIZE_XL))
          .fillColor($r('app.color.icon_primary'))
      }
      .width('100%')
      .height(responsiveListItemSpacing(60))
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: responsiveListItemSpacing(DesignConstants.SPACING_SM) })

      // 标题区域
      Text(title)
        .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_LG))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: responsiveListItemSpacing(DesignConstants.SPACING_XS) })

      // 描述区域
      Text(description)
        .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_SM))
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 箭头指示器
      Row() {
        Image($r('app.media.ic_arrow_right'))
          .width(responsiveIconSize(DesignConstants.ICON_SIZE_SM))
          .height(responsiveIconSize(DesignConstants.ICON_SIZE_SM))
          .fillColor($r('app.color.text_tertiary'))
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .margin({ top: responsiveListItemSpacing(DesignConstants.SPACING_SM) })
    }
    .width('100%')
    .padding({
      left: responsiveListItemPadding(DesignConstants.SPACING_LG),
      right: responsiveListItemPadding(DesignConstants.SPACING_LG),
      top: responsiveListItemPadding(DesignConstants.SPACING_LG),
      bottom: responsiveListItemPadding(DesignConstants.SPACING_LG)
    })
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(responsiveListItemSpacing(DesignConstants.BORDER_RADIUS_LG))
    .shadow(DesignConstants.SHADOW_MD)
    .onClick(onClick)
  }
}