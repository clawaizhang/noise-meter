import { DesignConstants } from '../../constants/DesignConstants';

// 功能卡片接口定义
interface FeatureCard {
  icon: Resource;
  title: string;
  description: string;
}

@ComponentV2
export struct AdvancedFeaturesPage {
  @Param @Require onComplete: () => void;
  @Param @Require onPrev: () => void;
  
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings);
  
  @Local private spectrumData: Float32Array = new Float32Array(1000);
  @Local private frequencies: number[] = [];
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
    { icon: $r('app.media.ic_stats'), title: '频谱分析', description: '多频段可视化分析' },
    { icon: $r('app.media.ic_weighting'), title: '计权模式', description: 'A/C/Z专业计权' },
    { icon: $r('app.media.ic_alarm'), title: '智能警报', description: '阈值警报提醒' },
    { icon: $r('app.media.ic_document_edit'), title: '历史记录', description: '数据追踪分析' },
    { icon: $r('app.media.ic_time_weighting'), title: '时段调度', description: '智能时段阈值' },
    { icon: $r('app.media.ic_info'), title: '专业报告', description: '数据分析报告' }
  ];

  aboutToAppear(): void {
    this.startEntranceAnimation();
    this.initializeFrequencies();
    this.startSpectrumAnimation();
  }

  private initializeFrequencies(): void {
    // 生成对数分布的频率点（20Hz - 20kHz）
    const count = 1000;
    const minFreq = 20;  // 20Hz
    const maxFreq = 20000; // 20kHz
    
    for (let i = 0; i < count; i++) {
      // 对数分布，更符合人耳感知
      const logMin = Math.log10(minFreq);
      const logMax = Math.log10(maxFreq);
      const logFreq = logMin + (logMax - logMin) * i / (count - 1);
      this.frequencies.push(Math.pow(10, logFreq));
    }
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
    const time = Date.now() * 0.002;
    const data = new Float32Array(this.frequencies.length);
    
    for (let i = 0; i < this.frequencies.length; i++) {
      const freq = this.frequencies[i];
      
      // 基础频谱特性
      let amplitude = this.getBaseSpectrumAmplitude(freq);
      
      // 添加动态变化
      amplitude = this.addDynamicVariation(amplitude, freq, time, i);
      
      data[i] = Math.max(0, Math.min(1, amplitude));
    }
    this.spectrumData = data;
  }

  private getBaseSpectrumAmplitude(frequency: number): number {
    // 低频区域（20Hz - 200Hz）：平稳上升
    if (frequency < 200) {
      return 0.2 + 0.3 * (frequency - 20) / 180;
    }
    
    // 中频区域（200Hz - 4000Hz）：达到峰值
    if (frequency < 4000) {
      const midRange = (frequency - 200) / 3800;
      return 0.5 + 0.4 * Math.sin(midRange * Math.PI);
    }
    
    // 高频区域（4000Hz - 20000Hz）：逐渐下降
    const highRange = (frequency - 4000) / 16000;
    return 0.9 - 0.7 * highRange;
  }

  private addDynamicVariation(baseAmplitude: number, frequency: number, time: number, index: number): number {
    const timeFactor = time * 0.001;
    
    // 低频缓慢变化
    const lowFreqMod = frequency < 1000 ? Math.sin(timeFactor * 0.5 + index * 0.01) * 0.1 : 0;
    
    // 中频适度变化
    const midFreqMod = frequency >= 1000 && frequency < 8000 ?
      Math.sin(timeFactor * 2 + index * 0.05) * 0.15 : 0;
    
    // 高频快速变化
    const highFreqMod = frequency >= 8000 ?
      Math.sin(timeFactor * 5 + index * 0.1) * 0.08 : 0;
    
    // 随机噪声
    const noise = Math.random() * 0.05;
    
    return baseAmplitude + lowFreqMod + midFreqMod + highFreqMod + noise;
  }

  // 移除彩色相关的方法，因为现在使用统一的灰色折线图

  private drawMultiBandSpectrum(canvas: CanvasRenderingContext2D): void {
    const width = 280;
    const height = 80;
    
    canvas.clearRect(0, 0, width, height);
    
    // 绘制背景网格
    canvas.strokeStyle = '#F0F0F0';  // 浅灰色网格
    canvas.lineWidth = 0.5;
    
    // 水平网格线
    for (let i = 1; i < 4; i++) {
      const y = i * height / 4;
      canvas.beginPath();
      canvas.moveTo(0, y);
      canvas.lineTo(width, y);
      canvas.stroke();
    }
    
    // 垂直网格线
    for (let i = 1; i < 4; i++) {
      const x = i * width / 4;
      canvas.beginPath();
      canvas.moveTo(x, 0);
      canvas.lineTo(x, height);
      canvas.stroke();
    }
    
    // 绘制频谱折线图
    canvas.beginPath();
    canvas.strokeStyle = '#666666';  // 深灰色折线
    canvas.lineWidth = 1.5;
    
    const pointSpacing = width / (this.spectrumData.length - 1);
    
    for (let i = 0; i < this.spectrumData.length; i++) {
      const x = i * pointSpacing;
      const y = height - this.spectrumData[i] * height * 0.8;
      
      if (i === 0) {
        canvas.moveTo(x, y);
      } else {
        // 使用线段连接，形成平滑折线
        canvas.lineTo(x, y);
      }
    }
    
    canvas.stroke();
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
      Image(item.icon)
        .width(DesignConstants.ICON_SIZE_MD)
      
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
          this.onComplete();
        })
        .margin({ top: DesignConstants.SPACING_2XL })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}