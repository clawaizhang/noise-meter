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
        // 背景光晕效果
        Circle({ width: 140, height: 140 })
          .fill($r('sys.color.brand'))
          .opacity(0.1)
          .scale({ x: this.iconScale, y: this.iconScale })

        // 应用图标
        Image($r('app.media.app_icon_fore'))
          .width(120)
          .height(120)
          .borderRadius(DesignConstants.BORDER_RADIUS_LG)
          .shadow(DesignConstants.SHADOW_MD)
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

      // 功能亮点展示 - 居中后再左对齐
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('核心功能')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_emphasize'))
          .opacity(this.featuresOpacity)

        // 功能项容器 - 居中
        Column({ space: DesignConstants.SPACING_SM }) {
          this.buildFeatureItem('实时精准检测', '毫秒级响应，专业级精度')
          this.buildFeatureItem('智能数据分析', '可视化报告，专业评估')
          this.buildFeatureItem('智能提醒保护', '噪音预警，环境监测')
        }
        .width('80%')  // 限制宽度
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
  private buildFeatureItem(title: string, description: string) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 图标区域 - 固定宽度确保对齐
      Column() {
        // 根据标题内容选择对应的图标
        if (title.includes('实时精准检测')) {
          Image($r('app.media.ic_meter'))
            .width(DesignConstants.ICON_SIZE_MD)
        } else if (title.includes('智能数据分析')) {
          Image($r('app.media.ic_stats'))
            .width(DesignConstants.ICON_SIZE_MD)
        } else if (title.includes('智能提醒保护')) {
          Image($r('app.media.ic_alarm'))
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
    .alignSelf(ItemAlign.Center)  // 确保每个功能项都居中
  }
}