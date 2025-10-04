import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct WelcomePage {
  @Event onNext: () => void;
  @Event onSkip: () => void;

  build() {
    Column({ space: DesignConstants.SPACING_XL }) {
      // 顶部留白
      Blank(DesignConstants.SPACING_3XL)

      // 应用图标
      Image($r('app.media.app_icon_fore'))
        .width(120)
        .height(120)
        .borderRadius(DesignConstants.BORDER_RADIUS_LG)

      // 标题和描述
      Column({ space: DesignConstants.SPACING_MD }) {
        Text('静喵Sound')
          .fontSize(DesignConstants.FONT_SIZE_3XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_emphasize'))

        Text('专业的噪音检测专家')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontColor($r('sys.color.font_primary'))
          .textAlign(TextAlign.Center)

        Text('精准测量环境噪音，保护您的听力健康')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .textAlign(TextAlign.Center)
          .lineHeight(20)
          .margin({ top: DesignConstants.SPACING_LG })
      }
      .alignItems(HorizontalAlign.Center)

      // 底部按钮
      Column({ space: DesignConstants.SPACING_MD }) {
        Button('开始探索', { type: ButtonType.Capsule })
          .width('80%')
          .height(56)
          .backgroundColor($r('sys.color.interactive_active'))
          .fontColor($r('sys.color.font_on_primary'))
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .onClick(() => this.onNext())

        Text('跳过')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .onClick(() => this.onSkip())
      }
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)
      .margin({ bottom: DesignConstants.SPACING_2XL })
    }
    .width('100%')
    .height('100%')
    .padding({
      left: DesignConstants.SPACING_XL,
      right: DesignConstants.SPACING_XL
    })
  }
}