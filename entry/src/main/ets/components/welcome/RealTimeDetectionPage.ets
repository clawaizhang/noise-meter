import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct RealTimeDetectionPage {
  @Param @Require onNext: () => void;
  @Param @Require onPrev: () => void;
  @Param @Require onSkip: () => void;

  @Local private currentDecibel: number = 35;
  @Local private isAnimating: boolean = true;
  @Local private contentOpacity: number = 0.8;
  @Local private meterScale: number = 1.0;
  @Local private buttonScale: number = 1.0;
  @Local private cardScales: number[] = [1.0, 1.0, 1.0];
  @Local private titleOpacity: number = 0;
  @Local private featuresOpacity: number = 0;
  @Local private scenesOpacity: number = 0;
  @Local private buttonOpacity: number = 0;

  aboutToAppear(): void {
    this.startEntranceAnimation();
    this.startDemoAnimation();
    this.startPulseAnimation();
  }

  aboutToDisappear(): void {
    this.isAnimating = false;
  }

  private startEntranceAnimation(): void {
    // 页面整体渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.contentOpacity = 1;
      });
    }, 100);

    // 标题渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.titleOpacity = 1;
      });
    }, 300);

    // 功能描述渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.featuresOpacity = 1;
      });
    }, 600);

    // 场景示例渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.scenesOpacity = 1;
      });
    }, 900);

    // 按钮渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.buttonOpacity = 1;
      });
    }, 1200);
  }

  private startPulseAnimation(): void {
    animateTo({
      duration: 2000,
      curve: Curve.EaseInOut,
      iterations: -1,
      playMode: PlayMode.Alternate
    }, () => {
      this.meterScale = 1.02;
    });
  }

  private startDemoAnimation(): void {
    const demoSequence = [35, 65, 85, 45];
    let index = 0;
    
    const animate = () => {
      if (this.isAnimating) {
        this.updateDecibelValue(demoSequence[index]);
        index = (index + 1) % demoSequence.length;
        setTimeout(animate, 1500);
      }
    };
    
    animate();
  }

  private updateDecibelValue(newValue: number): void {
    animateTo({
      duration: DesignConstants.ANIMATION_DURATION_SM,
      curve: Curve.EaseInOut
    }, () => {
      this.currentDecibel = newValue;
    });
  }

  private getDecibelColor(decibel: number): Resource {
    if (decibel <= 40) return $r('app.color.decibel_very_quiet');
    if (decibel <= 50) return $r('app.color.decibel_quiet');
    if (decibel <= 65) return $r('app.color.decibel_normal');
    if (decibel <= 75) return $r('app.color.decibel_noisy');
    if (decibel <= 85) return $r('app.color.decibel_very_noisy');
    return $r('app.color.decibel_unbearable');
  }

  private getDecibelLevelText(decibel: number): string {
    if (decibel <= 40) return '非常安静';
    if (decibel <= 50) return '安静';
    if (decibel <= 65) return '适中';
    if (decibel <= 75) return '嘈杂';
    if (decibel <= 85) return '非常嘈杂';
    return '难以忍受';
  }

  private handleButtonClick(): void {
    animateTo({
      duration: DesignConstants.ANIMATION_DURATION_XS,
      curve: Curve.EaseOut
    }, () => {
      this.buttonScale = 0.98;
    });

    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_SM,
        curve: Curve.EaseOut
      }, () => {
        this.buttonScale = 1.0;
      });

      setTimeout(() => {
        this.onNext();
      }, 100);
    }, 50);
  }

  private handleCardHover(isHover: boolean, index: number): void {
    animateTo({
      duration: DesignConstants.ANIMATION_DURATION_XS,
      curve: Curve.EaseOut
    }, () => {
      this.cardScales[index] = isHover ? 1.05 : 1.0;
    });
  }

  build() {
    Column({ space: DesignConstants.SPACING_XL }) {
      // 顶部导航
      this.buildHeader()

      // 分贝显示区域 - 圆形仪表盘
      this.buildDecibelMeter()

      // 功能描述
      this.buildFeatureDescription()

      // 场景示例
      this.buildSceneExamples()

      // 操作按钮
      Button('下一页', { type: ButtonType.Capsule })
        .width('100%')
        .height(56)
        .backgroundColor($r('sys.color.interactive_active'))
        .fontColor($r('sys.color.font_on_primary'))
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .scale({ x: this.buttonScale, y: this.buttonScale })
        .opacity(this.buttonOpacity)
        .onClick(() => this.handleButtonClick())
    }
    .width('100%')
    .height('100%')
    .padding(DesignConstants.SPACING_LG)
    .opacity(this.contentOpacity)
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
  private buildDecibelMeter() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 圆形仪表盘
      Stack({ alignContent: Alignment.Center }) {
        // 外圈背景
        Circle({ width: 120, height: 120 })
          .fill($r('sys.color.comp_background_secondary'))
          .scale({ x: this.meterScale, y: this.meterScale })

        // 进度环
        Circle({ width: 120, height: 120 })
          .fill(this.getDecibelColor(this.currentDecibel))
          .opacity(0.2)
          .scale({ x: this.meterScale, y: this.meterScale })

        // 分贝值显示
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(`${this.currentDecibel}`)
            .fontSize(DesignConstants.FONT_SIZE_3XL)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getDecibelColor(this.currentDecibel))

          Text('分贝')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
      }

      // 噪音等级文字
      Text(this.getDecibelLevelText(this.currentDecibel))
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontColor(this.getDecibelColor(this.currentDecibel))
        .fontWeight(FontWeight.Medium)
    }
    .alignItems(HorizontalAlign.Center)
    .padding(DesignConstants.SPACING_XL)
  }

  @Builder
  private buildFeatureDescription() {
    Column({ space: DesignConstants.SPACING_LG }) {
      Text('实时守护您的听力健康 😊')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_emphasize'))
        .textAlign(TextAlign.Center)
        .margin({ bottom: DesignConstants.SPACING_MD })
        .opacity(this.titleOpacity)

      // 功能亮点卡片
      Column({ space: DesignConstants.SPACING_MD }) {
        this.buildFeatureItem('🎵 即时响应，随时了解环境噪音')
        this.buildFeatureItem('🎯 智能识别，贴心提醒')
        this.buildFeatureItem('🏠 支持多种环境场景检测')
      }
      .width('100%')
      .opacity(this.featuresOpacity)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildFeatureItem(text: string) {
    Text(text)
      .fontSize(DesignConstants.FONT_SIZE_MD)
      .fontColor($r('sys.color.font_secondary'))
      .textAlign(TextAlign.Center)
      .padding({
        top: DesignConstants.SPACING_MD,
        bottom: DesignConstants.SPACING_MD,
        left: DesignConstants.SPACING_LG,
        right: DesignConstants.SPACING_LG
      })
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .width('100%')
  }

  @Builder
  private buildSceneExamples() {
    Row({ space: DesignConstants.SPACING_MD }) {
      this.buildSceneCard('图书馆', '35dB', $r('app.color.decibel_very_quiet'), '📚', 0)
      this.buildSceneCard('办公室', '65dB', $r('app.color.decibel_normal'), '💼', 1)
      this.buildSceneCard('街道', '85dB', $r('app.color.decibel_very_noisy'), '🚗', 2)
    }
    .justifyContent(FlexAlign.SpaceAround)
    .width('100%')
    .margin({ top: DesignConstants.SPACING_LG })
    .opacity(this.scenesOpacity)
  }

  @Builder
  private buildSceneCard(title: string, value: string, color: Resource, icon: string, index: number) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(icon)
        .fontSize(DesignConstants.FONT_SIZE_XL)
      
      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))

      Text(value)
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(color)
    }
    .padding(DesignConstants.SPACING_MD)
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .shadow(DesignConstants.SHADOW_SM)
    .scale({ x: this.cardScales[index], y: this.cardScales[index] })
    .onHover((isHover: boolean) => this.handleCardHover(isHover, index))
  }
}