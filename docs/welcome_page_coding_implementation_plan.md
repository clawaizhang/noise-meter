# 欢迎页编码实现方案

## 文件结构
```
entry/src/main/ets/components/welcome/
├── WelcomeGuide.ets          # 主引导页容器
├── WelcomePage.ets           # 第1页：欢迎页
├── RealTimeDetectionPage.ets # 第2页：实时检测页
├── AdvancedFeaturesPage.ets  # 第3页：高级功能页
├── PrivacyPolicyPage.ets     # 第4页：隐私政策页
└── index.ets                 # 导出文件
```

## 1. 主引导页容器 (WelcomeGuide.ets)

```typescript
import { WelcomePage } from './WelcomePage';
import { RealTimeDetectionPage } from './RealTimeDetectionPage';
import { AdvancedFeaturesPage } from './AdvancedFeaturesPage';
import { PrivacyPolicyPage } from './PrivacyPolicyPage';
import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct WelcomeGuide {
  @Param @Require onComplete: () => void;
  @Param @Require onCancel: () => void;
  
  @Local private currentPage: number = 0;
  @Local private totalPages: number = 4;
  @Local private privacyAgreed: boolean = false;

  // 页面切换方法
  private goToNextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
    } else {
      this.handleComplete();
    }
  }

  private goToPrevPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
    }
  }

  private skipToEnd(): void {
    this.currentPage = this.totalPages - 1;
  }

  private handleComplete(): void {
    if (this.currentPage === this.totalPages - 1 && this.privacyAgreed) {
      this.onComplete();
    }
  }

  private setPrivacyAgreed(agreed: boolean): void {
    this.privacyAgreed = agreed;
  }

  build() {
    Column({ space: 0 }) {
      // 页面内容区域
      Stack({ alignContent: Alignment.TopStart }) {
        this.buildCurrentPage()
      }
      .width('100%')
      .height('100%')

      // 页面指示器和操作按钮
      this.buildFooter()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
  }

  @Builder
  private buildCurrentPage() {
    switch (this.currentPage) {
      case 0:
        WelcomePage({
          onNext: () => this.goToNextPage(),
          onSkip: () => this.skipToEnd()
        })
        break;
      case 1:
        RealTimeDetectionPage({
          onNext: () => this.goToNextPage(),
          onPrev: () => this.goToPrevPage(),
          onSkip: () => this.skipToEnd()
        })
        break;
      case 2:
        AdvancedFeaturesPage({
          onNext: () => this.goToNextPage(),
          onPrev: () => this.goToPrevPage(),
          onSkip: () => this.skipToEnd()
        })
        break;
      case 3:
        PrivacyPolicyPage({
          onAgree: () => {
            this.setPrivacyAgreed(true);
            this.handleComplete();
          },
          onCancel: () => this.onCancel(),
          onPrev: () => this.goToPrevPage(),
          privacyAgreed: this.privacyAgreed,
          onPrivacyAgreedChange: (agreed: boolean) => this.setPrivacyAgreed(agreed)
        })
        break;
    }
  }

  @Builder
  private buildFooter() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 页面指示器
      Row({ space: DesignConstants.SPACING_SM }) {
        ForEach(Array.from({ length: this.totalPages }, (_, i) => i), (index: number) => {
          Circle({ width: 8, height: 8 })
            .fillColor(index === this.currentPage ? 
              $r('sys.color.interactive_active') : 
              $r('sys.color.comp_background_secondary'))
            .opacity(index === this.currentPage ? 1 : 0.5)
        })
      }
      .justifyContent(FlexAlign.Center)

      // 跳过按钮（前3页显示）
      if (this.currentPage < this.totalPages - 1) {
        Text('跳过')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .onClick(() => this.skipToEnd())
      }
    }
    .width('100%')
    .padding({
      bottom: DesignConstants.SPACING_XL,
      left: DesignConstants.SPACING_LG,
      right: DesignConstants.SPACING_LG
    })
  }
}

// Builder版本
@Builder
export function WelcomeGuideBuilder(params: WelcomeGuideParams) {
  WelcomeGuide({
    onComplete: params.onComplete,
    onCancel: params.onCancel
  })
}

export interface WelcomeGuideParams {
  onComplete: () => void;
  onCancel: () => void;
}
```

## 2. 第1页：欢迎页 (WelcomePage.ets)

```typescript
import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct WelcomePage {
  @Param @Require onNext: () => void;
  @Param @Require onSkip: () => void;

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
```

## 3. 第2页：实时检测页 (RealTimeDetectionPage.ets)

```typescript
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
        Rectangle()
          .width(200)
          .height(12)
          .fillColor($r('sys.color.comp_background_secondary'))
          .borderRadius(6)

        Rectangle()
          .width(Math.min(this.currentDecibel / 100 * 200, 200))
          .height(12)
          .fillColor(this.getDecibelColor(this.currentDecibel))
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
```

## 4. 第3页：高级功能页 (AdvancedFeaturesPage.ets)

```typescript
import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct AdvancedFeaturesPage {
  @Param @Require onNext: () => void;
  @Param @Require onPrev: () => void;
  @Param @Require onSkip: () => void;

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
      Canvas(this.getContext())
        .width('100%')
        .height(80)
        .onReady((canvas: RenderingContext) => {
          this.drawSpectrum(canvas);
        })

      Text('实时频谱分析')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
    }
    .alignItems(HorizontalAlign.Center)
    .padding(DesignConstants.SPACING_XL)
  }

  private drawSpectrum(canvas: RenderingContext): void {
    const width = 200;
    const height = 60;
    
    canvas.clearRect(0, 0, width, height);
    canvas.beginPath();
    
    for (let i = 0; i < width; i++) {
      const x = i;
      const y = height / 2 + Math.sin(i * 0.1 + Date.now() * 0.005) * 20;
      
      if (i === 0) {
        canvas.moveTo(x,