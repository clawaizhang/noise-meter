/**
 * 自定义隐私政策对话框组件
 * 替换系统隐私政策配方，提供更好的用户体验和控制
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { common } from '@kit.AbilityKit';

@ComponentV2
export struct PrivacyPolicyDialog {
  @Param @Require onAgree: () => void; // 同意回调
  @Param @Require onCancel: () => void; // 取消回调（退出APP）
  @Param isViewMode: boolean = false; // 是否为查看模式（不显示操作按钮）
  @Local context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  // 构建Header区域 - APP图标和名称
  @Builder
  private buildHeader() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Image($r('app.media.app_icon_fore'))
        .width(80)
        .height(80)
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)

      Text($r('app.string.EntryAbility_label'))
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_emphasize'))
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding({ top: DesignConstants.SPACING_XL, bottom: DesignConstants.SPACING_LG })
  }

  // 构建权限说明列表
  @Builder
  private buildPermissionList() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 麦克风权限
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_mic'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.font_primary'))

        Text($r('app.string.privacy_policy_microphone_permission'))
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
      }
      .width('100%')

      // 位置权限
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_location'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.font_primary'))

        Text($r('app.string.privacy_policy_location_permission'))
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
      }
      .width('100%')

      // 后台运行权限
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_power_on'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.font_primary'))

        Text($r('app.string.privacy_policy_background_permission'))
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  // 构建内容区域
  @Builder
  private buildContent() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 欢迎文本
      Text($r('app.string.privacy_policy_welcome'))
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_emphasize'))
        .textAlign(TextAlign.Center)
        .width('100%')

      // 描述文本
      Text($r('app.string.privacy_policy_description'))
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Start)
        .width('100%')
        .lineHeight(20)

      // 权限说明
      Text($r('app.string.privacy_policy_permissions_title'))
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 权限列表
      this.buildPermissionList()

      // 隐私政策链接
      Row({ space: DesignConstants.SPACING_SM }) {
        Text($r('app.string.privacy_policy_agreement_text'))
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))

        Hyperlink($r('app.string.privacy_policy_link'),
          $r('app.string.privacy_policy_link_text'))
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width('100%')
    }
    .width('100%')
    .padding({ left: DesignConstants.SPACING_LG, right: DesignConstants.SPACING_LG })
  }

  // 构建操作按钮区域
  @Builder
  private buildActionButtons() {
    if (this.isViewMode) {
      // 查看模式：只显示返回按钮
      Button($r('app.string.privacy_policy_back_button'), { type: ButtonType.Capsule })
        .width('100%')
        .backgroundColor($r('sys.color.interactive_active'))
        .fontColor($r('sys.color.font_on_primary'))
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          this.handleCancel();
        })
        .height(56)
        .margin(DesignConstants.SPACING_MD)
    } else {
      // 正常模式：显示取消和同意按钮
      Row({ space: DesignConstants.SPACING_MD }) {
        // 取消按钮 - 退出APP
        Button($r('app.string.privacy_policy_cancel_button'), { type: ButtonType.Capsule })
          .layoutWeight(1)
          .backgroundColor($r('sys.color.comp_background_primary'))
          .fontColor($r('sys.color.font_primary'))
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .border({
            width: DesignConstants.BORDER_WIDTH_SM,
            color: $r('sys.color.comp_border_color'),
            style: BorderStyle.Solid
          })
          .onClick(() => {
            this.handleCancel();
          })
          .height(56)

        // 同意按钮 - 继续使用
        Button($r('app.string.privacy_policy_agree_button'), { type: ButtonType.Capsule })
          .layoutWeight(1)
          .backgroundColor($r('sys.color.interactive_active'))
          .fontColor($r('sys.color.font_on_primary'))
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            this.handleAgree();
          })
          .height(56)
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
    }
  }

  // 处理同意操作
  private handleAgree() {
    if (this.onAgree) {
      this.onAgree();
    }
  }

  // 处理取消操作 - 退出APP
  private handleCancel() {
    if (this.onCancel) {
      this.onCancel();
    }
  }

  build() {
    Column({ space: 0 }) {
      // Header区域
      this.buildHeader()

      // 可滚动内容区域
      Scroll() {
        Column({ space: DesignConstants.SPACING_LG }) {
          // 主要内容区域
          this.buildContent()
        }
        .width('100%')
        .padding({ bottom: DesignConstants.SPACING_LG })
      }
      .scrollBar(BarState.Auto)
      .scrollable(ScrollDirection.Vertical)
      .width('100%')
      .layoutWeight(1)

      // 操作按钮区域
      this.buildActionButtons()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
  }
}

// 隐私政策对话框的Builder版本 - 正常模式
@Builder
export function PrivacyPolicyDialogBuilder(param: PrivacyPolicyDialogParams) {
  PrivacyPolicyDialog({
    onAgree: param.onAgree,
    onCancel: param.onCancel,
    isViewMode: false
  })
}

// 隐私政策查看模式的Builder版本
@Builder
export function PrivacyPolicyViewBuilder() {
  PrivacyPolicyDialog({
    onAgree: () => {},
    onCancel: () => {},
    isViewMode: true
  })
}

export interface PrivacyPolicyDialogParams {
  onAgree: () => void;
  onCancel: () => void;
}

export interface PrivacyPolicyViewParams {
  onClose: () => void;
}