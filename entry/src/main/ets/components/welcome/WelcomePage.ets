import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct WelcomePage {
  @Event onNext: () => void;

  // 动画状态变量
  @Local private iconScale: number = 1.0;
  @Local private iconRotation: number = 0;
  @Local private buttonScale: number = 1.0;
  @Local private contentOpacity: number = 0;
  @Local private featuresOpacity: number = 0;

  aboutToAppear(): void {
    // 启动页面进入动画
    this.startEntranceAnimation();
  }

  private startEntranceAnimation(): void {
    // 图标脉动动画
    animateTo({
      duration: DesignConstants.ANIMATION_DURATION_LG,
      curve: Curve.EaseInOut,
      iterations: -1, // 无限循环
      playMode: PlayMode.Alternate
    }, () => {
      this.iconScale = 1.1;
    });

    // 图标轻微旋转动画
    animateTo({
      duration: 8000,
      curve: Curve.Linear,
      iterations: -1,
      playMode: PlayMode.AlternateReverse
    }, () => {
      this.iconRotation = 5;
    });

    // 内容渐显动画
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.contentOpacity = 1;
      });
    }, 300);

    // 功能亮点渐显动画
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.featuresOpacity = 1;
      });
    }, 600);
  }


  build() {
    Column({ space: DesignConstants.SPACING_XL }) {
      // 动画应用图标
      Stack({ alignContent: Alignment.Center }) {

        // 应用图标 - 移除边框和阴影，更简洁现代
        Image($r('app.media.app_icon_fore'))
          .width(120)
          .height(120)
          .backgroundColor('#e50D1B2A')
          .borderRadius(DesignConstants.BORDER_RADIUS_LG)
          .scale({ x: this.iconScale, y: this.iconScale })
          .rotate({ angle: this.iconRotation })
      }

      // 标题和描述区域
      Column({ space: DesignConstants.SPACING_MD }) {
        Text('静喵Sound')
          .fontSize(DesignConstants.FONT_SIZE_4XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_emphasize'))
          .textAlign(TextAlign.Center)
          .opacity(this.contentOpacity)

        Text('专业噪音分析工具')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .textAlign(TextAlign.Center)
          .opacity(this.contentOpacity)

        Text('精准检测环境噪音，专业数据分析')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .textAlign(TextAlign.Center)
          .lineHeight(20)
          .margin({ top: DesignConstants.SPACING_LG })
          .opacity(this.contentOpacity)
      }
      .alignItems(HorizontalAlign.Center)

      // 价值主张展示 - 强调噪音监测的重要性
      Column({ space: DesignConstants.SPACING_MD }) {
        Text('为什么需要噪音监测？')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_emphasize'))
          .opacity(this.featuresOpacity)

        // 价值主张描述
        Column({ space: DesignConstants.SPACING_SM }) {
          this.buildValueItem('保护听力健康', '长期噪音暴露可能导致听力损伤')
          this.buildValueItem('提升生活质量', '安静环境有助于提高专注力和睡眠质量')
          this.buildValueItem('工作环境优化', '符合职业健康安全标准')
        }
        .width('85%')  // 限制宽度
        .alignItems(HorizontalAlign.Start)  // 内部左对齐
      }
      .alignItems(HorizontalAlign.Center)  // 外部居中
      .width('100%')
      .padding({
        top: DesignConstants.SPACING_XL,
        bottom: DesignConstants.SPACING_XL
      })
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .shadow(DesignConstants.SHADOW_SM)
    }
    .width('100%')
    .height('100%')
    .padding({
      left: DesignConstants.SPACING_XL,
      right: DesignConstants.SPACING_XL
    })
    .justifyContent(FlexAlign.Center)  // 垂直居中
    .backgroundColor($r('sys.color.background_secondary'))
    .backgroundBlurStyle(BlurStyle.Thin)
  }

  @Builder
  private buildValueItem(title: string, description: string) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 图标区域 - 固定宽度确保对齐
      Column() {
        // 根据价值主张选择对应的图标
        if (title.includes('保护听力健康')) {
          Image($r('app.media.ic_user'))
            .fillColor($r('sys.color.brand'))
            .width(DesignConstants.ICON_SIZE_MD)
        } else if (title.includes('提升生活质量')) {
          Image($r('app.media.ic_smile'))
            .fillColor($r('sys.color.brand'))
            .width(DesignConstants.ICON_SIZE_MD)
        } else if (title.includes('工作环境优化')) {
          Image($r('app.media.ic_security'))
            .fillColor($r('sys.color.brand'))
            .width(DesignConstants.ICON_SIZE_MD)
        }
      }
      .width(40)  // 固定图标容器宽度
      .alignItems(HorizontalAlign.Center)
      
      // 文本区域 - 统一对齐
      Column({ space: DesignConstants.SPACING_XS }) {
        Text(title)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .textAlign(TextAlign.Start)
          .width('100%')

        Text(description)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .textAlign(TextAlign.Start)
          .width('100%')
      }
      .layoutWeight(1)  // 文本区域占据剩余空间
      .alignItems(HorizontalAlign.Start)
    }
    .justifyContent(FlexAlign.Start)
    .width('90%')  // 限制整体宽度
    .padding({
      top: DesignConstants.SPACING_MD,
      bottom: DesignConstants.SPACING_MD,
      left: DesignConstants.SPACING_LG,
      right: DesignConstants.SPACING_LG
    })
    .backgroundColor($r('sys.color.background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .shadow(DesignConstants.SHADOW_SM)
    .opacity(this.featuresOpacity)
    .alignSelf(ItemAlign.Center)  // 确保每个价值项都居中
  }
}