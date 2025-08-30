import { privacyManager } from '@kit.StoreKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { commonEventManager } from '@kit.BasicServicesKit';
import { Want } from '@kit.AbilityKit';
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
export struct AboutSettings {
  @Local currentListItemLayoutMode: ListItemLayoutMode = ListItemLayoutMode.LIST;
  @Local isLandscape: boolean = false;
  @Local gridColumns: number = 1;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

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

  build() {
    NavDestination() {
      Scroll() {

        Column() {

          // 根据布局模式选择不同的容器
          if (this.currentListItemLayoutMode === ListItemLayoutMode.GRID) {
            // 网格布局
            Grid() {
              // 隐私政策
              GridItem() {
                Column() {
                  Row() {
                    Row() {
                      Image($r('app.media.ic_info'))
                        .itemIcon()

                      Text('隐私政策')
                        .itemTitle()
                    }

                    Blank()
                  }
                  .listItemRow()

                  // 描述信息
                  Text('查看应用的隐私政策')
                    .itemDescription()
                    .margin({ top: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
                }
                .cardStyle()
                .width(responsiveListItemWidth(300, this.gridColumns))
                .onClick(async () => {
                  // 这里添加打开隐私政策的逻辑
                  const uiContext = getContext(this) as common.UIAbilityContext;
                  await privacyManager.requestAppPrivacyConsent(uiContext);
                })
              }

              // 应用信息
              GridItem() {
                Column() {
                  Row() {
                    Row() {
                      Image($r('app.media.ic_info'))
                        .itemIcon()

                      Text('应用信息')
                        .itemTitle()
                    }

                    Blank()

                    Text('v1.0.0')
                      .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
                      .fontColor($r('app.color.text_secondary'))
                  }
                  .listItemRow()

                  // 描述信息
                  Text('噪音分贝仪pro - 专业的噪音检测工具')
                    .itemDescription()
                    .margin({ top: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
                }
                .cardStyle()
                .width(responsiveListItemWidth(300, this.gridColumns))
              }

              // 技术支持
              GridItem() {
                Column() {
                  Row() {
                    Row() {
                      Image($r('app.media.ic_info'))
                        .itemIcon()

                      Text('技术支持')
                        .itemTitle()
                    }

                    Blank()
                  }
                  .listItemRow()

                  // 描述信息
                  Text('如有问题请联系技术支持团队')
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
              // 隐私政策
              ListItem() {
                Column() {
                  Row() {
                    Row() {
                      Image($r('app.media.ic_info'))
                        .itemIcon()

                      Text('隐私政策')
                        .itemTitle()
                    }

                    Blank()
                  }
                  .listItemRow()
                }
                .cardStyle()
              }.onClick(async () => {
                // 这里添加打开隐私政策的逻辑
                const uiContext = getContext(this) as common.UIAbilityContext;
                await privacyManager.requestAppPrivacyConsent(uiContext);
              })

              ListItem() {
                Text('查看应用的隐私政策')
                  .itemDescription()
              }
              .descriptionContainer()

              // 应用信息
              ListItem() {
                Column() {
                  Row() {
                    Row() {
                      Image($r('app.media.ic_info'))
                        .itemIcon()

                      Text('应用信息')
                        .itemTitle()
                    }

                    Blank()

                    Text('v1.0.0')
                      .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
                      .fontColor($r('app.color.text_secondary'))
                  }
                  .listItemRow()
                }
                .cardStyle()
              }

              ListItem() {
                Text('噪音分贝仪pro - 专业的噪音检测工具')
                  .itemDescription()
              }
              .descriptionContainer()

              // 技术支持
              ListItem() {
                Column() {
                  Row() {
                    Row() {
                      Image($r('app.media.ic_info'))
                        .itemIcon()

                      Text('技术支持')
                        .itemTitle()
                    }

                    Blank()
                  }
                  .listItemRow()
                }
                .cardStyle()
              }

              ListItem() {
                Text('如有问题请联系技术支持团队')
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

      // 给作者留言按钮
      Button('给作者留言')
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
          const context = getContext(this) as common.UIAbilityContext;
          const want: Want = {
            action: 'ohos.want.action.appdetail',
            uri: 'store://appgallery.huawei.com/app/detail?id=yu.zhang.myapplication.noise_meter_pro&action=write-review'
          };
          context.startAbility(want).then(() => {
            console.info('Succeeded in starting Ability successfully.');
          }).catch((err: BusinessError) => {
            console.error(`Failed to start ability. Code: ${err.code}, message: ${err.message}`);
          });
        })

      // 返回按钮
      Button('返回')
        .width(responsiveListItemWidth(300, 1))
        .height(responsiveListItemSpacing(40))
        .margin({
          bottom: responsiveListItemSpacing(30),
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
    .backgroundColor($r('app.color.background_tertiary')).title('关于')
  }
}

@Builder
export function AboutSettingsBuilder() {
  AboutSettings()
}