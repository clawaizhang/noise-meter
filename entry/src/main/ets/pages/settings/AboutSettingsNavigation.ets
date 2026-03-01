import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';
import { curves, PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PrivacyPolicyViewBuilder } from '../../components/privacy/PrivacyPolicyDialog';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { DialogStyleManager } from '../../utils/DialogStyleManager';
import { Throttle } from '../../utils/Debounce';
import { CommentService } from '../../services/CommentService';
import { privacyManager } from '@kit.StoreKit';

@Extend(Image)
function itemIcon() {
  .width(DesignConstants.ICON_SIZE_MD)
  .height(DesignConstants.ICON_SIZE_MD)
  .fillColor($r('sys.color.brand'))
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
  .backgroundColor($r('sys.color.comp_background_primary'))
  .justifyContent(FlexAlign.Start)
  .alignItems(HorizontalAlign.Start)
  .borderRadius(16)
  .padding(16)
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
    .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
    .combine(TransitionEffect.translate({ x: -150, y: 0 }).animation({ curve: curves.springMotion() })))
}

@Extend(Column)
function appInfoCardStyle() {
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
  .borderRadius(16)
  .padding(24)
  .margin({ bottom: 16 })
  .width('100%')
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) })
    .combine(TransitionEffect.scale({ x: 0, y: 0 }))
    .combine(TransitionEffect.translate({ x: -150, y: 0 }).animation({ curve: curves.springMotion() })))
}

@Extend(Row)
function listItemRow() {
  .alignItems(VerticalAlign.Center)
  .justifyContent(FlexAlign.Start)
}

@ComponentV2
export struct AboutSettings {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local showRevokeConfirmDialog: boolean = false;

  build() {
    Row() {
      GridRow({
        columns:
        1,
        breakpoints: { reference: BreakpointsReference.WindowSize }
      , gutter: 16
      }) {
        // 应用信息展示区域 - 在页面顶部
        GridCol({ span: 1 }) {
          Column({ space: 12 }) {
            // APP图标
            Image($r('app.media.app_icon_fore'))
              .width(80)
              .height(80)
              .borderRadius(16)
              .backgroundColor('#e50D1B2A')
              .objectFit(ImageFit.Contain)

            // 应用名称
            Text('静喵Sound')
              .fontSize(DesignConstants.FONT_SIZE_XL)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))

            // 应用描述
            Text('专业级环境噪音检测分析工具')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_secondary'))
              .textAlign(TextAlign.Center)

            // 版本号
            Text('v2.0.0')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_tertiary'))
              .textAlign(TextAlign.Center)
          }
          .appInfoCardStyle()
        }.width('100%')

        // 隐私政策管理
        GridCol({ span: 1 }) {
          Column({ space: 12 }) {
            // 标题
            Text($r('app.string.privacy_policy_management_title'))
              .fontSize(DesignConstants.FONT_SIZE_LG)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.brand'))
              .alignSelf(ItemAlign.Start)

            // 查看隐私政策
            Row({ space: 8 }) {
              Row() {
                Image($r('app.media.ic_info'))
                  .itemIcon()
                Text('撤销隐私授权')
                  .fontColor($r('sys.color.font_emphasize'))
                  .onClick(() => {
                    Throttle.click(async () => {
                      // 这里添加打开隐私政策的逻辑
                      const uiContext = getContext(this) as common.UIAbilityContext;
                      await privacyManager.requestAppPrivacyConsent(uiContext);
                    })
                  })
              }.layoutWeight(1)

              Blank()
            }
            .listItemRow()

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

        GridCol({ span: 1 }) {
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
              Throttle.click(async () => {
                try {
                  const context = getContext(this) as common.UIAbilityContext;
                  const commentService = CommentService.getInstance();
                  await commentService.showCommentDialog(context);
                  console.info('评论对话框显示成功');
                } catch (error) {
                  console.error(`显示评论对话框失败: ${error instanceof Error ? error.message : String(error)}`);
                }
              })
            })
        }
      }
      .backgroundColor('transparent')
    }
    .padding(16)
    .backgroundColor($r('sys.color.background_secondary'))
  }

  // 取消隐私授权
  private revokePrivacyAgreement() {
    // 退出APP
    const context = getContext(this) as common.UIAbilityContext;
    context.terminateSelf();
  }
}

@Builder
export function AboutSettingsBuilder() {
  AboutSettings()
}