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
  @Local currentListItemLayoutMode: ListItemLayoutMode = ListItemLayoutMode.LIST;
  @Local isLandscape: boolean = false;
  @Local gridColumns: number = 1;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    this.isNoiseAlarmEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.NOISE_ALARM_ENABLED, true);
    this.noiseThreshold = this.preferenceService.getNumber(PreferenceKeyConstants.NOISE_THRESHOLD, 80);
    this.updateNoiseAlarmDescription();

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
   * 根据布局模式更新网格列数
   */
  private updateGridColumns(): void {
    switch (this.currentListItemLayoutMode) {
      case ListItemLayoutMode.GRID:
        if (this.isLandscape) {
          this.gridColumns = 2; // 横屏网格布局使用2列
        } else {
          this.gridColumns = 2; // 竖屏网格布局也使用2列
        }
        break;
      case ListItemLayoutMode.DETAIL:
        this.gridColumns = 1; // 详情布局使用1列
        break;
      case ListItemLayoutMode.COMPACT:
        this.gridColumns = 3; // 紧凑布局使用3列
        break;
      default:
        this.gridColumns = 1; // 列表布局使用1列
    }
  }

  private updateNoiseAlarmDescription() {
    this.noiseAlarmDescription = this.isNoiseAlarmEnabled
      ? '检测到噪音超过阈值时将触发警报'
      : '系统不会发出噪音超标警报';
  }

  build() {
    NavDestination() {

      Column() {
        // 添加Scroll组件包裹主要内容
        Scroll() {
          Column() {
            // 根据布局模式选择不同的容器
            if (this.currentListItemLayoutMode === ListItemLayoutMode.GRID) {
              // 网格布局
              Grid() {
                // 噪音警报开关
                GridItem() {
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

                    // 描述信息
                    Text(this.noiseAlarmDescription)
                      .itemDescription()
                      .margin({ top: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
                  }
                  .cardStyle()
                  .width(responsiveListItemWidth(300, this.gridColumns))
                }

                // 噪音阈值设置
                GridItem() {
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
                        .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
                        .fontColor($r('app.color.text_secondary'))
                        .margin({ right: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
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
                      .margin({
                        top: responsiveListItemSpacing(DesignConstants.SPACING_MD),
                        bottom: responsiveListItemSpacing(DesignConstants.SPACING_MD)
                      })
                      .height(responsiveListItemSpacing(24))
                      .trackThickness(responsiveListItemSpacing(24))
                      .blockSize({ width: responsiveListItemSpacing(24), height: responsiveListItemSpacing(24) })

                    // 描述信息
                    Text('环境噪音超过设定阈值时，系统将发出警报提示')
                      .itemDescription()
                      .margin({ top: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
                  }
                  .cardStyle()
                  .width(responsiveListItemWidth(300, this.gridColumns))
                }
              }
              .columnsTemplate('1fr 1fr')
              .rowsTemplate('auto')
              .columnsGap(responsiveListItemSpacing(DesignConstants.SPACING_MD))
              .rowsGap(responsiveListItemSpacing(DesignConstants.SPACING_MD))
              .layoutWeight(1)
              .backgroundColor('transparent')
            } else {
              // 列表布局（保持原有代码）
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
                  .cardStyle()
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
                        .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
                        .fontColor($r('app.color.text_secondary'))
                        .margin({ right: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
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
                      .margin({
                        top: responsiveListItemSpacing(DesignConstants.SPACING_MD),
                        bottom: responsiveListItemSpacing(DesignConstants.SPACING_MD)
                      })
                      .height(responsiveListItemSpacing(24))
                      .trackThickness(responsiveListItemSpacing(24))
                      .blockSize({ width: responsiveListItemSpacing(24), height: responsiveListItemSpacing(24) })
                  }
                  .cardStyle()
                }

                ListItem() {
                  Text('环境噪音超过设定阈值时，系统将发出警报提示')
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

        // 返回按钮
        Button('返回')
          .width(responsiveListItemWidth(300, 1))
          .height(responsiveListItemSpacing(40))
          .margin({
            bottom: responsiveListItemSpacing(30),
            top: responsiveListItemSpacing(DesignConstants.SPACING_MD),
            left: responsiveListItemMargin(DesignConstants.SPACING_MD),
            right: responsiveListItemMargin(DesignConstants.SPACING_MD)
          })
          .backgroundColor($r('app.color.toggle_active'))
          .borderRadius(responsiveListItemSpacing(8))
          .shadow({
            radius: responsiveListItemSpacing(4),
            color: $r('app.color.shadow_medium'),
            offsetX: 0,
            offsetY: responsiveListItemSpacing(1)
          })
          .onClick(() => {
            this.navStack.pop();
          })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_tertiary'))
    }.title('警报与通知')
  }
}
