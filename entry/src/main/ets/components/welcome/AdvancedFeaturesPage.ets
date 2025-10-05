import { DesignConstants } from '../../constants/DesignConstants';

// 功能卡片接口定义
interface FeatureCard {
  icon: string;
  title: string;
  description: string;
}

@ComponentV2
export struct AdvancedFeaturesPage {
  @Param @Require onNext: () => void;
  @Param @Require onPrev: () => void;
  
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);
  
  @Local private spectrumData: Float32Array = new Float32Array(8);
  @Local private contentOpacity: number = 0.8;
  @Local private titleOpacity: number = 0;
  @Local private featuresOpacity: number = 0;
  @Local private buttonOpacity: number = 0;
  @Local private buttonScale: number = 1.0;
  @Local private cardScales: number[] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0];
  @Local private isAnimating: boolean = true;
  @Local private useNowButtonScale: number = 0.8;
  @Local private useNowButtonOpacity: number = 0;

  // 功能卡片数据
  private readonly features: FeatureCard[] = [
    { icon: '📊', title: '频谱分析', description: '多频段可视化分析' },
    { icon: '⚖️', title: '计权模式', description: 'A/C/Z专业计权' },
    { icon: '🔔', title: '智能警报', description: '阈值警报提醒' },
    { icon: '📝', title: '历史记录', description: '数据追踪分析' },
    { icon: '⏰', title: '时段调度', description: '智能时段阈值' },
    { icon: '📋', title: '专业报告', description: '数据分析报告' }
  ];

  aboutToAppear(): void {
    this.startEntranceAnimation();
    this.startSpectrumAnimation();
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

    // 功能卡片渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.featuresOpacity = 1;
      });
    }, 600);

    // 按钮渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.buttonOpacity = 1;
      });
    }, 900);

    // 立即使用按钮渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.useNowButtonScale = 1.0;
        this.useNowButtonOpacity = 1;
      });
    }, 1200);
  }

  private startSpectrumAnimation(): void {
    const animateSpectrum = () => {
      if (this.isAnimating) {
        this.generateMultiBandSpectrum();
        setTimeout(animateSpectrum, 100);
      }
    };
    animateSpectrum();
  }

  private generateMultiBandSpectrum(): void {
    const bands = 8;
    const data = new Float32Array(bands);
    const time = Date.now() * 0.002;
    
    for (let i = 0; i < bands; i++) {
      // 模拟不同频段的能量分布，每个频段有不同的频率和相位
      const base = Math.sin(i * 0.8 + time) * 0.3;
      const peak = Math.exp(-Math.pow(i - 3, 2) / 8) * Math.sin(time * 2) * 0.4;
      const noise = Math.random() * 0.1;
      data[i] = Math.max(0, base + peak + noise);
    }
    this.spectrumData = data;
  }

  private getBandColor(bandIndex: number): string {
    const colors = [
      '#FF6B6B', '#FF9E6B', '#FFD166', '#06D6A0',
      '#118AB2', '#073B4C', '#7209B7', '#F72585'
    ];
    return colors[bandIndex % colors.length];
  }

  private drawMultiBandSpectrum(canvas: CanvasRenderingContext2D): void {
    const width = 280;
    const height = 80;
    const bands = this.spectrumData.length;
    const bandWidth = width / bands;
    
    canvas.clearRect(0, 0, width, height);
    
    // 绘制背景网格
    canvas.strokeStyle = '#E0E0E0';
    canvas.lineWidth = 0.5;
    
    // 水平网格线
    for (let i = 1; i < 4; i++) {
      const y = i * height / 4;
      canvas.beginPath();
      canvas.moveTo(0, y);
      canvas.lineTo(width, y);
      canvas.stroke();
    }
    
    // 绘制频段
    for (let i = 0; i < bands; i++) {
      const barHeight = this.spectrumData[i] * height * 0.8;
      const x = i * bandWidth + 2;
      const y = height - barHeight;
      
      // 绘制频段柱状图
      canvas.fillStyle = this.getBandColor(i);
      canvas.fillRect(x, y, bandWidth - 4, barHeight);
      
      // 添加渐变效果
      const gradient = canvas.createLinearGradient(x, y, x, y + barHeight);
      gradient.addColorStop(0, this.getBandColor(i));
      gradient.addColorStop(1, this.getBandColor(i) + '80');
      canvas.fillStyle = gradient;
      canvas.fillRect(x, y, bandWidth - 4, barHeight);
    }
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
      // 频谱分析区域
      this.buildSpectrumDisplay()

      // 标题区域
      this.buildTitle()

      // 功能卡片网格
      this.buildFeatureGrid()

      // 立即使用按钮
      this.buildUseNowButton()
    }
    .width('100%')
    .height('100%')
    .padding(DesignConstants.SPACING_LG)
    .justifyContent(FlexAlign.Center)  // 垂直居中
    .opacity(this.contentOpacity)
  }


  @Builder
  private buildSpectrumDisplay() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Canvas(this.canvasContext)
        .width('100%')
        .height(80)
        .onReady(() => {
          this.drawMultiBandSpectrum(this.canvasContext);
        })

      // 频率标注
      Row({ space: 0 }) {
        Text('20Hz')
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_secondary'))
        
        Blank()
        
        Text('20kHz')
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Center)
    .padding(DesignConstants.SPACING_XL)
  }

  @Builder
  private buildTitle() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('专业分析，精准守护')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_emphasize'))
        .textAlign(TextAlign.Center)
        .opacity(this.titleOpacity)

      Text('可视化音频分析，智能噪音防护')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .opacity(this.titleOpacity)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildFeatureGrid() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 第一行功能卡片
      Row({ space: DesignConstants.SPACING_MD }) {
        ForEach(this.features.slice(0, 3), (item: FeatureCard, index: number) => {
          this.buildFeatureCard(item, index)
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      // 第二行功能卡片
      Row({ space: DesignConstants.SPACING_MD }) {
        ForEach(this.features.slice(3, 6), (item: FeatureCard, index: number) => {
          this.buildFeatureCard(item, index + 3)
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .margin({ top: DesignConstants.SPACING_XL })
    .opacity(this.featuresOpacity)
  }

  @Builder
  private buildFeatureCard(item: FeatureCard, index: number) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(item.icon)
        .fontSize(DesignConstants.FONT_SIZE_XL)
      
      Text(item.title)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)

      Text(item.description)
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .maxLines(2)
    }
    .width('30%')
    .height(80)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .shadow(DesignConstants.SHADOW_SM)
    .scale({ x: this.cardScales[index], y: this.cardScales[index] })
    .onHover((isHover: boolean) => this.handleCardHover(isHover, index))
  }

  // 构建立即使用按钮
  @Builder
  private buildUseNowButton() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Button('立即使用', { type: ButtonType.Capsule })
        .width('80%')
        .height(56)
        .backgroundColor($r('sys.color.interactive_active'))
        .fontColor($r('sys.color.font_on_primary'))
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .borderRadius(28)
        .shadow(DesignConstants.SHADOW_MD)
        .scale({ x: this.useNowButtonScale, y: this.useNowButtonScale })
        .opacity(this.useNowButtonOpacity)
        .onClick(() => {
          // 直接完成引导，进入主应用
          this.onNext();
        })
        .margin({ top: DesignConstants.SPACING_2XL })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}