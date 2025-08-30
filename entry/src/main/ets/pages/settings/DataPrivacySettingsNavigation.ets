import { PreferenceService, PreferenceValue } from '../../services/PreferenceService';
import { PreferenceKeyConstants } from '../../constants/PreferenceKeyConstants';
import { navigationStack } from '../../constants/ProviderConstant';
import {
  responsiveLayout,
  responsiveFontSize,
  responsiveIconSize,
  responsiveListItemSpacing,
  responsiveListItemPadding,
  responsiveListItemMargin,
  responsiveListItemWidth,
  Breakpoint,
  LayoutMode,
  ListItemLayoutMode
} from '../../utils/ResponsiveLayout';
import { DesignConstants } from '../../constants/DesignConstants';

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
  .margin({ left: responsiveListItemSpacing(DesignConstants.SPACING_XL) })
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

@Extend(Column)
function cardStyle() {
  .backgroundColor($r('app.color.background_secondary'))
  .borderRadius(responsiveListItemSpacing(12))
  .shadow({
    radius: responsiveListItemSpacing(8),
    color: $r('app.color.shadow_medium'),
    offsetX: 0,
    offsetY: responsiveListItemSpacing(2)
  })
  .padding({
    top: responsiveListItemPadding(DesignConstants.SPACING_MD),
    bottom: responsiveListItemPadding(DesignConstants.SPACING_MD),
    left: responsiveListItemPadding(DesignConstants.SPACING_LG),
    right: responsiveListItemPadding(DesignConstants.SPACING_LG)
  })
  .margin({
    top: responsiveListItemMargin(DesignConstants.SPACING_MD),
    bottom: responsiveListItemMargin(DesignConstants.SPACING_MD),
    left: responsiveListItemMargin(DesignConstants.SPACING_MD),
    right: responsiveListItemMargin(DesignConstants.SPACING_MD)
  })
}

@Extend(Row)
function listItemRow() {
  .width('100%')
  .height(responsiveListItemSpacing(56))
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
  .padding({
    top: responsiveListItemPadding(DesignConstants.SPACING_SM),
    bottom: responsiveListItemPadding(DesignConstants.SPACING_MD)
  })
}

@ComponentV2
export struct DataPrivacySettings {
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  @Local isLocationEnabled: boolean = true;
  @Local isRecordEnabled: boolean = true;
  @Local currentListItemLayoutMode: ListItemLayoutMode = ListItemLayoutMode.LIST;
  @Local isLandscape: boolean = false;
  @Local gridColumns: number = 1;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.isLocationEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.LOCATION, true);
    this.isRecordEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.RECORD, true);

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
    this.updateGridColumns();

    // 注册布局变化监听器
    responsiveLayout.addChangeListener((width: number, height: number, breakpoint: Breakpoint,
      layoutMode: LayoutMode, listItemLayoutMode: ListItemLayoutMode, isLandscape: boolean) => {
      this.currentListItemLayoutMode = listItemLayoutMode;
      this.isLandscape = isLandscape;
      this.updateGridColumns();
    });
  }

  /**
   * 根据布局模式和屏幕宽度更新网格列数
   */
  private updateGridColumns(): void {
    // 获取当前屏幕宽度
    const screenInfo = responsiveLayout.getCurrentScreenInfo();
    const screenWidth = screenInfo.width;
    
    switch (this.currentListItemLayoutMode) {
      case ListItemLayoutMode.GRID:
        // 根据屏幕宽度动态计算列数
        if (screenWidth >= 1200) { // XL断点及以上
          this.gridColumns = this.isLandscape ? 4 : 3;
        } else if (screenWidth >= 840) { // LG断点
          this.gridColumns = this.isLandscape ? 3 : 2;
        } else if (screenWidth >= 600) { // MD断点
          this.gridColumns = this.isLandscape ? 2 : 2;
        } else { // SM和XS断点
          this.gridColumns = 1; // 小屏幕使用单列
        }

        break;
      case ListItemLayoutMode.DETAIL:
        this.gridColumns = 1; // 详情布局使用1列
        break;
      case ListItemLayoutMode.COMPACT:
        // 紧凑模式下根据屏幕宽度调整列数
        if (screenWidth >= 840) {
          this.gridColumns = 4;
        } else if (screenWidth >= 600) {
          this.gridColumns = 3;
        } else {
          this.gridColumns = 2;
        }
        break;
      default:
        this.gridColumns = 1; // 列表布局使用1列
    }
  }


  /**
   * 根据列数生成网格模板字符串
   */
  private getGridColumnsTemplate(): string {
    return Array(this.gridColumns).fill('1fr').join(' ');
  }

  build() {
    NavDestination() {

      Column() {
        // 添加Scroll组件包裹主要内容
        Scroll() {
          Column() {
            // 根据布局模式选择不同的容器
            if (this.currentListItemLayoutMode === ListItemLayoutMode.GRID) {
              // 网格布局 - 使用 GridRow 和 GridCol
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
                // 位置开关
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

                    // 描述信息
                    Text(this.isLocationEnabled ? '记录检测地点的位置信息' : '不会采集地理位置信息')
                      .itemDescription()
                      .margin({ top: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
                  }
                  .cardStyle()
                  .width('100%')
                }

                // 录音开关
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

                    // 描述信息
                    Text(this.isRecordEnabled ? '保存原始音频数据用于后期分析' : '不会保存音频数据')
                      .itemDescription()
                      .margin({ top: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
                  }
                  .cardStyle()
                  .width('100%')
                }
              }
              .width('100%')
              .padding({
                left: responsiveListItemPadding(DesignConstants.SPACING_MD),
                right: responsiveListItemPadding(DesignConstants.SPACING_MD),
                top: responsiveListItemPadding(DesignConstants.SPACING_MD),
                bottom: responsiveListItemPadding(DesignConstants.SPACING_MD)
              })
            } else {
              // 列表布局（保持原有代码）
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
              .width('100%')
              .layoutWeight(1)
              .backgroundColor('transparent')
            }
          }
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.On)
        .scrollBarWidth(responsiveListItemSpacing(4))
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)

      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_tertiary'))
    }.title('数据记录与隐私')
  }
}

@Builder
export function DataPrivacySettingsBuilder() {
  DataPrivacySettings()
}