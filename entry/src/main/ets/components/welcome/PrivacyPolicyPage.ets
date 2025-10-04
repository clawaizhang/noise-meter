import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct PrivacyPolicyPage {
  @Event onPrev: () => void;
  @Event onSkip: () => void;
  @Event onAgree: () => void;

  @Local private privacyAgreed: boolean = false;
  @Local private showFullPolicy: boolean = false;

  build() {
    Column({ space: DesignConstants.SPACING_XL }) {
      // 顶部导航
      this.buildHeader()

      // 标题
      this.buildTitle()

      // 隐私政策内容
      this.buildPolicyContent()

      // 同意按钮
      this.buildAgreementButton()
    }
    .width('100%')
    .height('100%')
    .padding(DesignConstants.SPACING_LG)
  }

  @Builder
  private buildHeader() {
    Row() {
      Button('', { type: ButtonType.Circle })
        .width(40)
        .height(40)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .onClick(() => this.onPrev())

      Blank()

      Text('跳过')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .onClick(() => this.onSkip())
    }
    .width('100%')
  }

  @Builder
  private buildTitle() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('隐私保护')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_emphasize'))

      Text('我们重视您的隐私安全')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildPolicyContent() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_MD }) {
        // 隐私政策摘要
        this.buildPolicySummary()

        // 展开/收起按钮
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
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .layoutWeight(1)
  }

  @Builder
  private buildPolicySummary() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('数据使用说明')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_emphasize'))
        .alignSelf(ItemAlign.Start)

      this.buildPolicyItem('音频数据', '仅用于实时噪音分析，不会上传到服务器')
      this.buildPolicyItem('位置信息', '用于环境噪音记录，可选择关闭')
      this.buildPolicyItem('设备信息', '用于优化应用性能和兼容性')
      this.buildPolicyItem('本地存储', '检测数据仅保存在您的设备中')
    }
    .width('100%')
  }

  @Builder
  private buildPolicyItem(title: string, description: string) {
    Row({ space: DesignConstants.SPACING_MD }) {
      Image($r('app.media.ic_favorite'))
        .width(20)
        .height(20)
        .fillColor($r('sys.color.confirm'))

      Column({ space: DesignConstants.SPACING_XS }) {
        Text(title)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_emphasize'))
          .alignSelf(ItemAlign.Start)

        Text(description)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .alignSelf(ItemAlign.Start)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

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

  @Builder
  private buildAgreementButton() {
    Column({ space: DesignConstants.SPACING_SM }) {
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
    }
    .width('100%')
  }
}