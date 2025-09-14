import { privacyManager } from '@kit.StoreKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Want } from '@kit.AbilityKit';
import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';
import { curves } from '@kit.ArkUI';

@Extend(Image)
function itemIcon() {
  .width(DesignConstants.ICON_SIZE_MD)
  .height(DesignConstants.ICON_SIZE_MD)
  .fillColor($r('sys.color.background_secondary'))
}

@Extend(Text)
function itemTitle() {
  .fontWeight(FontWeight.Medium)
}

@Extend(Text)
function itemDescription() {
  .fontColor($r('sys.color.font_secondary'))
  .fontSize(DesignConstants.FONT_SIZE_MD)
  .textAlign(TextAlign.Start)
  .alignSelf(ItemAlign.Start)
}

@Extend(Column)
function cardStyle() {
  .backgroundColor($r('sys.color.background_secondary'))
  .justifyContent(FlexAlign.Start)
  .alignItems(HorizontalAlign.Start)
  .borderRadius(16)
  .padding(16)
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
    .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
    .combine(TransitionEffect.translate({ y: 150 }).animation({ curve: curves.springMotion() })))
}

@Extend(Row)
function listItemRow() {
  .alignItems(VerticalAlign.Center)
  .justifyContent(FlexAlign.Start)
}

@ComponentV2
export struct AboutSettings {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  build() {
    NavDestination() {
      Scroll() {
        GridRow({
          columns:
          {
            sm: 1,
            md: 2,
            lg: 2,
            xl: 3
          },
          breakpoints: { reference: BreakpointsReference.WindowSize }
        , gutter: 16
        }) {
          // 隐私政策
          GridCol({ span: 1 }) {
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                Row() {
                  Image($r('app.media.ic_info'))
                    .itemIcon()
                  Text('隐私政策')
                    .itemTitle()
                }.layoutWeight(1)

                Blank()
              }
              .listItemRow()

              Text('查看应用的隐私政策')
                .itemDescription()
            }
            .cardStyle()
          }.width('100%').onClick(async () => {
            // 这里添加打开隐私政策的逻辑
            const uiContext = getContext(this) as common.UIAbilityContext;
            await privacyManager.requestAppPrivacyConsent(uiContext);
          })

          // 应用信息
          GridCol({ span: 1 }) {
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                Row() {
                  Image($r('app.media.ic_info'))
                    .itemIcon()
                  Text('应用信息')
                    .itemTitle()
                }.layoutWeight(1)

                Blank()
                Text('v1.0.9')
                  .fontSize(DesignConstants.FONT_SIZE_MD)
                  .fontColor($r('sys.color.font_secondary'))
              }
              .listItemRow()

              Text('静喵Sound - 专业的噪音检测工具')
                .itemDescription()
            }
            .cardStyle()
          }.width('100%')

          // 技术支持
          GridCol({ span: 1 }) {
            Column({ space: 8 }) {
              Row() {
                Row() {
                  Image($r('app.media.ic_info'))
                    .itemIcon()

                  Text('技术支持')
                    .itemTitle()
                }
                .layoutWeight(1)

                Blank()
              }
              .listItemRow()

              Text('如有问题请联系技术支持团队')
                .itemDescription()
            }
            .cardStyle()
          }
        }
        .backgroundColor('transparent')
      }
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

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

    }.padding(16)
    .backgroundColor($r('sys.color.background_primary')).title('关于')
  }
}

@Builder
export function AboutSettingsBuilder() {
  AboutSettings()
}