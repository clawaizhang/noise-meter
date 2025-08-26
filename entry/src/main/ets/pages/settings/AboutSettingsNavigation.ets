import { privacyManager } from '@kit.StoreKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { commonEventManager } from '@kit.BasicServicesKit';
import { Want } from '@kit.AbilityKit';
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
export struct AboutSettings {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  build() {    NavDestination() {

    Column() {


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
          .listItemStyle()
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
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
            }
            .listItemRow()
          }
          .listItemStyle()
        }

        ListItem() {
          Text('止喧噪音检测仪 - 专业的噪音检测工具')
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
          .listItemStyle()
        }

        ListItem() {
          Text('如有问题请联系技术支持团队')
            .itemDescription()
        }
        .descriptionContainer()
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.background_tertiary'))
      .margin({ top: 12 })

      // 给作者留言按钮
      Button('给作者留言')
        .width('90%')
        .height(40)
        .margin({ bottom: 30, top: 12 })
        .backgroundColor($r('app.color.toggle_active'))
        .onClick(() => {
          const context = getContext(this) as common.UIAbilityContext;
          const want: Want = {
            action: 'ohos.want.action.appdetail',
            uri: 'store://appgallery.huawei.com/app/detail?id=yu.zhang.myapplication.noise_meter&action=write-review'
          };
          context.startAbility(want).then(() => {
            console.info('Succeeded in starting Ability successfully.');
          }).catch((err:BusinessError) => {
            console.error(`Failed to start ability. Code: ${err.code}, message: ${err.message}`);
          });
        })

      // 返回按钮
      Button('返回')
        .width('90%')
        .height(40)
        .margin({ bottom: 30 })
        .backgroundColor($r('app.color.toggle_active'))
        .onClick(() => {
          this.navStack.pop();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_tertiary'))}.title('关于')
  }
}

@Builder
export function AboutSettingsBuilder() {
  AboutSettings()
}