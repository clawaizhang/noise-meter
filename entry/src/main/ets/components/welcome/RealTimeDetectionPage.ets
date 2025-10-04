import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct RealTimeDetectionPage {
  @Param @Require onNext: () => void;
  @Param @Require onPrev: () => void;
  @Param @Require onSkip: () => void;

  @Local private currentDecibel: number = 35;
  @Local private isAnimating: boolean = true;

  aboutToAppear(): void {
    this.startDemoAnimation();
  }

  aboutToDisappear(): void {
    this.isAnimating = false;
  }

  private startDemoAnimation(): void {
    const demoSequence = [35, 65, 85, 45];
    let index = 0;
    
    const animate = () => {
      if (this.isAnimating) {
        this.currentDecibel = demoSequence[index];
        index = (index + 1) % demoSequence.length;
        setTimeout(animate, 1500);
      }
    };
    
    animate();
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

  build() {
    Column({ space: DesignConstants.SPACING_XL }) {
      // 顶部导航
      this.buildHeader()

      // 分贝显示
      this.buildDecibelDisplay()

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
        .onClick(() => this.onNext())
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
  private buildDecibelDisplay() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text(`${this.currentDecibel}`)
        .fontSize(DesignConstants.FONT_SIZE_4XL)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getDecibelColor(this.currentDecibel))

      Text('分贝')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontColor($r('sys.color.font_secondary'))

      Text(this.getDecibelLevelText(this.currentDecibel))
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor(this.getDecibelColor(this.currentDecibel))

      // 进度条
      Stack({ alignContent: Alignment.BottomStart }) {
        Column()
          .width(200)
          .height(12)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(6)

        Column()
          .width(Math.min(this.currentDecibel / 100 * 200, 200))
          .height(12)
          .backgroundColor(this.getDecibelColor(this.currentDecibel))
          .borderRadius(6)
      }
      .margin({ top: DesignConstants.SPACING_MD })
    }
    .alignItems(HorizontalAlign.Center)
    .padding(DesignConstants.SPACING_XL)
  }

  @Builder
  private buildFeatureDescription() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('实时精准检测')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_emphasize'))
        .alignSelf(ItemAlign.Start)

      Text('• 毫秒级响应，实时显示分贝值')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)

      Text('• 智能识别噪音等级，颜色直观提示')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)

      Text('• 支持多种环境场景检测')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
  }

  @Builder
  private buildSceneExamples() {
    Row({ space: DesignConstants.SPACING_MD }) {
      this.buildSceneCard('图书馆', '35dB', $r('app.color.decibel_very_quiet'))
      this.buildSceneCard('办公室', '65dB', $r('app.color.decibel_normal'))
      this.buildSceneCard('街道', '85dB', $r('app.color.decibel_very_noisy'))
    }
    .justifyContent(FlexAlign.SpaceAround)
    .width('100%')
    .margin({ top: DesignConstants.SPACING_LG })
  }

  @Builder
  private buildSceneCard(title: string, value: string, color: Resource) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))

      Text(value)
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(color)
    }
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }
}