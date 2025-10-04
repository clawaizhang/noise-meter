import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct PrivacyPolicyPage {
  @Event onPrev: () => void;
  @Event onSkip: () => void;
  @Event onAgree: () => void;

  @Local private privacyAgreed: boolean = false;
  @Local private showFullPolicy: boolean = false;

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

  // 构建内容区域 - 集成隐私政策对话框的设计
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

      // 隐私政策链接和展开功能
      this.buildPolicyExpandSection()
    }
    .width('100%')
    .padding({ left: DesignConstants.SPACING_LG, right: DesignConstants.SPACING_LG })
  }

  // 构建隐私政策展开部分 - 保留原欢迎页的功能
  @Builder
  private buildPolicyExpandSection() {
    Column({ space: DesignConstants.SPACING_MD }) {
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

      // 展开/收起完整隐私政策
      if (!this.showFullPolicy) {
        Text('查看完整隐私政策')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.interactive_active'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .onClick(() => {
            this.showFullPolicy = true;
          })
      } else {
        // 完整隐私政策
        this.buildFullPolicy()
      }
    }
    .width('100%')
  }

  // 构建完整隐私政策 - 保留原欢迎页的功能
  @Builder
  private buildFullPolicy() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('完整隐私政策')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_emphasize'))
        .alignSelf(ItemAlign.Start)

      Text('1. 数据收集')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_emphasize'))
        .alignSelf(ItemAlign.Start)

      Text('我们收集的音频数据仅用于实时噪音检测和分析，不会用于其他目的。位置信息仅在您明确授权时用于环境噪音记录。')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)

      Text('2. 数据存储')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_emphasize'))
        .alignSelf(ItemAlign.Start)

      Text('所有检测数据都存储在您的设备本地，不会上传到任何服务器。您可以随时在设置中清除所有数据。')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)

      Text('3. 权限使用')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_emphasize'))
        .alignSelf(ItemAlign.Start)

      Text('麦克风权限：仅用于噪音检测\n位置权限：可选，用于环境记录\n存储权限：用于保存检测历史')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)

      Text('收起')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.interactive_active'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .onClick(() => {
          this.showFullPolicy = false;
        })
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