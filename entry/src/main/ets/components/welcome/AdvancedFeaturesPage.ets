import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct AdvancedFeaturesPage {
  @Param @Require onNext: () => void;
  @Param @Require onPrev: () => void;
  @Param @Require onSkip: () => void;
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true) // Canvas设置
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings) // Canvas上下文
  @Local private spectrumData: Float32Array = new Float32Array(128);

  aboutToAppear(): void {
    this.generateDemoSpectrum();
  }

  private generateDemoSpectrum(): void {
    const data = new Float32Array(128);
    for (let i = 0; i < data.length; i++) {
      const base = Math.sin(i * 0.1) * 0.5;
      const peak = Math.exp(-Math.pow(i - 40, 2) / 200) * 0.8;
      data[i] = Math.max(base, peak) + Math.random() * 0.1;
    }
    this.spectrumData = data;
  }

  build() {
    Column({ space: DesignConstants.SPACING_XL }) {
      // 顶部导航
      this.buildHeader()

      // 频谱图
      this.buildSpectrumDisplay()

      // 功能描述
      this.buildFeatureDescription()

      // 功能图标
      this.buildFeatureIcons()

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
  private buildSpectrumDisplay() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Canvas(this.canvasContext)
        .width('100%')
        .height(80)
        .onReady(() => {
          this.drawSpectrum(this.canvasContext);
        })

      Text('实时频谱分析')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
    }
    .alignItems(HorizontalAlign.Center)
    .padding(DesignConstants.SPACING_XL)
  }

  private drawSpectrum(canvas: CanvasRenderingContext2D): void {
    const width = 200;
    const height = 60;
    
    canvas.clearRect(0, 0, width, height);
    canvas.beginPath();
    
    for (let i = 0; i < width; i++) {
      const x = i;
      const y = height / 2 + Math.sin(i * 0.1 + Date.now() * 0.005) * 20;
      
      if (i === 0) {
        canvas.moveTo(x, y);
      } else {
        canvas.lineTo(x, y);
      }
    }
    
    canvas.strokeStyle = '#1890FF';
    canvas.lineWidth = 2;
    canvas.stroke();
  }

  @Builder
  private buildFeatureDescription() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('专业分析工具')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_emphasize'))
        .alignSelf(ItemAlign.Start)

      Text('• 实时频谱分析 - 可视化音频频率分布')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)

      Text('• 智能数据记录 - 自动保存检测历史')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)

      Text('• 多种加权模式 - A/C/Z专业计权')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
  }

  @Builder
  private buildFeatureIcons() {
    Row({ space: DesignConstants.SPACING_MD }) {
      Column({ space: DesignConstants.SPACING_XS }) {
        Image($r('app.media.ic_frequency_weighting'))
          .width(32)
          .height(32)
          .fillColor($r('sys.color.interactive_active'))
        Text('频谱分析')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }

      Column({ space: DesignConstants.SPACING_XS }) {
        Image($r('app.media.ic_history'))
          .width(32)
          .height(32)
          .fillColor($r('sys.color.interactive_active'))
        Text('数据记录')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }

      Column({ space: DesignConstants.SPACING_XS }) {
        Image($r('app.media.ic_weighting'))
          .width(32)
          .height(32)
          .fillColor($r('sys.color.interactive_active'))
        Text('加权模式')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }

      Column({ space: DesignConstants.SPACING_XS }) {
        Image($r('app.media.ic_settings'))
          .width(32)
          .height(32)
          .fillColor($r('sys.color.interactive_active'))
        Text('自定义')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
    }
    .justifyContent(FlexAlign.SpaceAround)
    .width('100%')
    .margin({ top: DesignConstants.SPACING_LG })
  }
}