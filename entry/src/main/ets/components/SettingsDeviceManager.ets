import { privacyManager } from '@kit.StoreKit';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

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

  .textAlign(TextAlign.Start)
  .width( '100%')
  .margin({ left: 48 })
}

@Extend(Column)
function listItemStyle() {

  .padding({ left: 16, right: 16 })
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(Row)
function listItemRow() {

  .height(56)
  .alignItems(VerticalAlign.Center)
}

@Extend(Text)
function detailText() {
  .fontColor($r('app.color.text_secondary'))

  .margin({ top: 4, left: 48 })
}

@Extend(ListItem)
function dividerStyle() {

  .height(1)
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(ListItem)
function descriptionContainer() {
  .backgroundColor($r('app.color.background_secondary'))
  .padding({ top: 8, bottom: 12 })
}

@ComponentV2
export struct SettingsDeviceManager {
  // 新增状态变量来控制每个 AccordionItem 的展开和收起状态
  @Local isAboutExpanded: boolean = false;

  aboutToAppear() {
  }


  build() {
    Column() {

      List() {

        // 关于
        ListItem() {
          Column() {
            Row() {
              Text('关于')
                .itemTitle()
              Blank()
            }
            .listItemRow()
          }
          .listItemStyle()
        }.onClick(() => {
          animateTo({
            duration: 300,
            onFinish: () => {
              console.info('animation end');
            }
          }, () => {
            this.isAboutExpanded = !this.isAboutExpanded;
          })
        })

        ListItem() {
        }.dividerStyle() // 添加分隔符

        if (this.isAboutExpanded) {
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
        }
      }

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
            uri: 'store://appgallery.huawei.com/app/detail?id=yu.zhang.myapplication.device_manager&action=write-review'
          };
          context.startAbility(want).then(() => {
            console.info('Succeeded in starting Ability successfully.');
          }).catch((err:BusinessError) => {
            console.error(`Failed to start ability. Code: ${err.code}, message: ${err.message}`);
          });
        })
    }


    .backgroundColor($r('app.color.background_tertiary'))
  }
}