import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';
import { curves, PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PrivacyPolicyViewBuilder } from '../../components/privacy/PrivacyPolicyDialog';
import { DialogHub, InfSheet } from '@hadss/dialoghub';

@Extend(Image)
function itemIcon() {
  .width(DesignConstants.ICON_SIZE_MD)
  .height(DesignConstants.ICON_SIZE_MD)
  .fillColor($r('sys.color.font_primary'))
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
  
  // DialogHub实例缓存
  private privacyPolicyDialog: InfSheet | null = null;
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
            Image($r('app.media.app_icon_default'))
              .width(80)
              .height(80)
              .borderRadius(16)
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
            Text('v1.0.9')
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
              .fontColor($r('sys.color.font_primary'))
              .alignSelf(ItemAlign.Start)
            
            // 查看隐私政策
            Row({ space: 8 }) {
              Row() {
                Image($r('app.media.ic_info'))
                  .itemIcon()
                Hyperlink($r('app.string.privacy_policy_link'),$r('app.string.privacy_policy_link_text'))
              }.layoutWeight(1)

              Blank()
            }
            .listItemRow()
            .onClick(() => {
              if (!this.privacyPolicyDialog) {
                this.privacyPolicyDialog = DialogHub.getSheet().setConfig({enableOutsideInteractive:true}).setStyle({backgroundColor:$r('sys.color.background_secondary')}).setContent(wrapBuilder(PrivacyPolicyViewBuilder)).build();
              }
              this.privacyPolicyDialog.show();
            })

            // 取消隐私授权
            Row({ space: 8 }) {
              Row() {
                Image($r('app.media.ic_lock'))
                  .itemIcon()
                Text($r('app.string.revoke_privacy_agreement'))
                  .itemTitle()
              }.layoutWeight(1)

              Blank()
            }
            .listItemRow()
            .onClick(() => {
              AlertDialog.show({
                title: $r('app.string.revoke_privacy_confirm_title'),
                message: $r('app.string.revoke_privacy_confirm_message'),
                primaryButton: {
                  value: $r('app.string.revoke_privacy_confirm_button'),
                  action: () => {
                    this.revokePrivacyAgreement();
                  }
                },
                secondaryButton: {
                  value: $r('app.string.revoke_privacy_cancel_button'),
                  action: () => {
                    this.showRevokeConfirmDialog = false;
                  }
                },
                cancel: () => {
                  this.showRevokeConfirmDialog = false;
                }
              })
            })
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
      }
      .backgroundColor('transparent')
    }
    .padding(16)
    .backgroundColor($r('sys.color.background_secondary'))
  }

  // 取消隐私授权
  private revokePrivacyAgreement() {
    // 撤销隐私同意状态
    this.pk.privacy_agreed = false;
    // 退出APP
    const context = getContext(this) as common.UIAbilityContext;
    context.terminateSelf();
  }
}

@Builder
export function AboutSettingsBuilder() {
  AboutSettings()
}