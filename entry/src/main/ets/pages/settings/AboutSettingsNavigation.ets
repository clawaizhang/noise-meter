import { privacyManager } from '@kit.StoreKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { commonEventManager } from '@kit.BasicServicesKit';
import { Want } from '@kit.AbilityKit';
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
export struct AboutSettings {
  @Local isLandscape: boolean = false;
  @Local gridColumns: number = 1;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
  }

  build() {
    NavDestination() {
      Scroll() {


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
                  .fontSize(DesignConstants.FONT_SIZE_MD)
                  .fontColor($r('app.color.text_secondary'))
              }
              .listItemRow()
            }
            .cardStyle()
          }

          ListItem() {
            Text('静喵Sound - 专业的噪音检测工具')
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

        .lanes({ minLength: 350, maxLength: 350 }, 8)
        .layoutWeight(1)
        .backgroundColor('transparent')
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.On)
      .scrollBarWidth(4)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)

      // 给作者留言按钮
      Button('给作者留言')
        .width(300)
        .height(40)
        .margin({
          bottom: 30,
          top: DesignConstants.SPACING_MD,
          left: DesignConstants.SPACING_MD,
          right: DesignConstants.SPACING_MD
        })
        .backgroundColor($r('app.color.toggle_active'))
        .borderRadius(8)
        .shadow({
          radius: 4,
          color: $r('app.color.shadow_medium'),
          offsetX: 0,
          offsetY: 1
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

    }


    .backgroundColor($r('app.color.background_tertiary')).title('关于')
  }
}

@Builder
export function AboutSettingsBuilder() {
  AboutSettings()
}