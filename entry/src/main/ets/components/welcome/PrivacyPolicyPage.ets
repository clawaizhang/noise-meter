import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct PrivacyPolicyPage {
  @Event onPrev: () => void;
  @Event onSkip: () => void;
  @Event onAgree: () => void;

  @Local private privacyAgreed: boolean = false;

  build() {
    Column({ space: 0 }) {
      // Header区域 - 集成隐私政策对话框的设计
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

  // 构建Header区域 - 集成隐私政策对话框的设计
  @Builder
  private buildHeader() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // APP图标和名称
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

  // 构建权限说明列表 - 集成隐私政策对话框的设计
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

  // 构建内容区域 - 专注于隐私政策内容
  @Builder
  private buildContent() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 隐私政策标题
      Text('隐私保护')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_emphasize'))
        .textAlign(TextAlign.Center)
        .width('100%')

      // 隐私政策描述
      Text('我们重视您的隐私安全，请了解我们的数据使用政策')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .lineHeight(20)

      // 权限说明
      Text('应用权限说明')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 权限列表
      this.buildPermissionList()

      // 隐私政策链接
      this.buildPolicyLink()
    }
    .width('100%')
    .padding({ left: DesignConstants.SPACING_LG, right: DesignConstants.SPACING_LG })
  }

  // 构建隐私政策链接部分 - 简化版本
  @Builder
  private buildPolicyLink() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 隐私政策链接
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('请阅读并同意')
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
  }


  // 构建操作按钮区域 - 集成原欢迎页的复选框和按钮设计
  @Builder
  private buildActionButtons() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 复选框和同意文本
      Row({ space: DesignConstants.SPACING_MD }) {
        Checkbox({ name: 'privacyAgreement', group: 'privacy' })
          .select(this.privacyAgreed)
          .onChange((value: boolean) => {
            this.privacyAgreed = value;
          })

        Text('我已阅读并同意隐私政策')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_emphasize'))
          .onClick(() => {
            this.privacyAgreed = !this.privacyAgreed;
          })
      }

      // 同意按钮
      Button('同意并继续', { type: ButtonType.Capsule })
        .width('100%')
        .height(56)
        .backgroundColor(this.privacyAgreed ? $r('sys.color.interactive_active') : $r('sys.color.comp_background_tertiary'))
        .fontColor(this.privacyAgreed ? $r('sys.color.font_on_primary') : $r('sys.color.font_on_primary'))
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .enabled(this.privacyAgreed)
        .onClick(() => {
          if (this.privacyAgreed) {
            this.onAgree();
          }
        })

      // 导航按钮
      Row({ space: DesignConstants.SPACING_MD }) {
        Button('上一页', { type: ButtonType.Normal })
          .layoutWeight(1)
          .backgroundColor($r('sys.color.comp_background_primary'))
          .fontColor($r('sys.color.font_primary'))
          .onClick(() => this.onPrev())

        Text('跳过')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .onClick(() => this.onSkip())
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
  }
}