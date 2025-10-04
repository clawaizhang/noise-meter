# 欢迎页实现指南

## 概述
本文档提供"静喵Sound"应用欢迎页的完整实现方案，包含4页滑动引导页设计。

## 文件结构
```
entry/src/main/ets/components/welcome/
├── WelcomeGuide.ets          # 主引导页容器
├── WelcomePage.ets           # 第1页：欢迎页
├── RealTimeDetectionPage.ets # 第2页：实时检测页
├── AdvancedFeaturesPage.ets  # 第3页：高级功能页
├── PrivacyPolicyPage.ets     # 第4页：隐私政策页
└── WelcomeStateManager.ets   # 状态管理服务
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
  @Local private canSkip: boolean = true;
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
    this.currentPage = this.totalPages - 1; // 直接跳转到隐私政策页
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
              $r('app.color.primary') : 
              $r('app.color.icon_inactive'))
            .opacity(index === this.currentPage ? 1 : 0.5)
        })
      }
      .justifyContent(FlexAlign.Center)

      // 操作按钮（根据当前页面显示不同按钮）
      if (this.currentPage < this.totalPages - 1) {
        // 前3页显示跳过按钮
        Text('跳过')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('app.color.text_secondary'))
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

// Builder版本用于在Index.ets中调用
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
          .fontColor($r('app.color.text_primary'))

        Text('专业的噪音检测专家')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)

        Text('精准测量环境噪音，保护您的听力健康')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('app.color.text_tertiary'))
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
          .backgroundColor($r('app.color.primary'))
          .fontColor($r('app.color.white'))
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .onClick(() => this.onNext())

        Text('跳过')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('app.color.text_secondary'))
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
    this.startDecibelAnimation();
  }

  private startDecibelAnimation(): void {
    // 模拟分贝值变化动画
    const values = [35, 65, 85, 45, 75];
    let index = 0;
    
    const animate = () => {
      if (this.isAnimating) {
        this.currentDecibel = values[index];
        index = (index + 1) % values.length;
        setTimeout(animate, 1500);
      }
    };
    
    animate();
  }

  aboutToDisappear(): void {
    this.isAnimating = false;
  }

  private getDecibelColor(decibel: number): Resource {
    if (decibel <= 50) return $r('app.color.decibel_safe');
    if (decibel <= 70) return $r('app.color.decibel_warning');
    return $r('app.color.decibel_danger');
  }

  build() {
    Column({ space: DesignConstants.SPACING_XL }) {
      // 顶部导航
      this.buildHeader()

      // 分贝计模拟器
      this.buildDecibelMeter()

      // 功能描述
      this.buildFeatureDescription()

      // 场景示例
      this.buildSceneExamples()

      // 操作按钮
      this.buildActionButtons()
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
        .backgroundColor($r('app.color.background_secondary'))
        .onClick(() => this.onPrev())
        .opacity(0.6)

      Blank()

      Text('跳过')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.text_secondary'))
        .onClick(() => this.onSkip())
    }
    .width('100%')
  }

  @Builder
  private buildDecibelMeter() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 分贝值显示
      Text(`${this.currentDecibel}`)
        .fontSize(DesignConstants.FONT_SIZE_4XL)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getDecibelColor(this.currentDecibel))

      Text('分贝')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontColor($r('app.color.text_secondary'))

      // 模拟分贝计
      Stack({ alignContent: Alignment.BottomStart }) {
        // 背景条
        Rectangle()
          .width(200)
          .height(20)
          .fillColor($r('app.color.background_secondary'))
          .borderRadius(10)

        // 进度条
        Rectangle()
          .width(Math.min(this.currentDecibel / 100 * 200, 200))
          .height(20)
          .fillColor(this.getDecibelColor(this.currentDecibel))
          .borderRadius(10)
      }
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
        .fontColor($r('app.color.text_primary'))
        .alignSelf(ItemAlign.Start)

      Text('• 毫秒级响应，实时显示分贝值')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.text_secondary'))
        .alignSelf(ItemAlign.Start)

      Text('• 智能识别噪音等级，颜色直观提示')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.text_secondary'))
        .alignSelf(ItemAlign.Start)

      Text('• 支持多种环境场景检测')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.text_secondary'))
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
  }

  @Builder
  private buildSceneExamples() {
    Row({ space: DesignConstants.SPACING_MD }) {
      this.buildSceneCard('图书馆', '35dB', $r('app.color.decibel_safe'))
      this.buildSceneCard('办公室', '65dB', $r('app.color.decibel_warning'))
      this.buildSceneCard('街道', '85dB', $r('app.color.decibel_danger'))
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
        .fontColor($r('app.color.text_secondary'))

      Text(value)
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor(color)
    }
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  @Builder
  private buildActionButtons() {
    Button('下一页', { type: ButtonType.Capsule })
      .width('100%')
      .height(56)
      .backgroundColor($r('app.color.primary'))
      .fontColor($r('app.color.white'))
      .fontSize(DesignConstants.FONT_SIZE_LG)
      .fontWeight(FontWeight.Medium)
      .onClick(() => this.onNext())
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

  build() {
    Column({ space: DesignConstants.SPACING_XL }) {
      // 顶部导航
      this.buildHeader()

      // 频谱分析动画
      this.buildSpectrumAnimation()

      // 功能描述
      this.buildFeatureDescription()

      // 功能图标网格
      this.buildFeatureGrid()

      // 操作按钮
      this.buildActionButtons()
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
        .backgroundColor($r('app.color.background_secondary'))
        .onClick(() => this.onPrev())
        .opacity(0.6)

      Blank()

      Text('跳过')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.text_secondary'))
        .onClick(() => this.onSkip())
    }
    .width('100%')
  }

  @Builder
  private buildSpectrumAnimation() {
    // 简化的频谱波浪效果
    Column({ space: DesignConstants.SPACING_MD }) {
      Canvas(this.getContext())
        .width('100%')
        .height(80)
        .onReady((canvas: RenderingContext) => {
          this.drawSpectrum(canvas);
        })

      Text('实时频谱分析')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.text_secondary'))
    }
    .alignItems(HorizontalAlign.Center)
    .padding(DesignConstants.SPACING_XL)
  }

  private drawSpectrum(canvas: RenderingContext): void {
    // 简化的频谱绘制逻辑
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
        .fontColor($r('app.color.text_primary'))
        .alignSelf(ItemAlign.Start)

      Text('• 实时频谱分析 - 可视化音频频率分布')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.text_secondary'))
        .alignSelf(ItemAlign.Start)

      Text('• 智能数据记录 - 自动保存检测历史')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.text_secondary'))
        .alignSelf(ItemAlign.Start)

      Text('• 多种加权模式 - A/C/Z专业计权')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.text_secondary'))
        .alignSelf(ItemAlign.Start)

