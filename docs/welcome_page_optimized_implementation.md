# 欢迎页优化实现指南

## 概述
利用项目中现有的组件快速实现欢迎页，减少重复开发工作。

## 可复用的现有组件

### 1. 分贝显示组件
**文件**: [`DecibelDisplayComponent.ets`](entry/src/main/ets/components/decibel-meter/DecibelDisplayComponent.ets)
```typescript
// 可以直接复用的组件
DecibelDisplayComponent({
  currentDecibel: this.currentDecibel,
  minDecibel: this.minDecibel,
  maxDecibel: this.maxDecibel,
  avgDecibel: this.avgDecibel,
  weightingType: 'A' // 默认A加权
})
```

### 2. 频谱图组件
**文件**: [`SpectrumChartComponent.ets`](entry/src/main/ets/components/decibel-meter/SpectrumChartComponent.ets)
```typescript
// 简化版本的频谱图
SpectrumChartComponent({
  spectrumData: this.currentSpectrum,
  isSimplified: true // 添加简化模式参数
})
```

### 3. 设计系统
**文件**: [`DesignConstants.ets`](entry/src/main/ets/constants/DesignConstants.ets)
- 完整的间距、字体、颜色系统
- 动画时长配置
- 阴影和圆角规范

## 优化后的实现方案

### 第2页：实时检测页（复用现有组件）

```typescript
import { DecibelDisplayComponent } from '../decibel-meter/DecibelDisplayComponent';
import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct RealTimeDetectionPage {
  @Param @Require onNext: () => void;
  @Param @Require onPrev: () => void;
  @Param @Require onSkip: () => void;

  @Local private currentDecibel: number = 35;
  @Local private minDecibel: number = 30;
  @Local private avgDecibel: number = 45;
  @Local private maxDecibel: number = 85;
  @Local private isAnimating: boolean = true;

  aboutToAppear(): void {
    this.startDemoAnimation();
  }

  private startDemoAnimation(): void {
    // 模拟真实的分贝值变化
    const demoSequence = [
      { current: 35, min: 30, avg: 33, max: 40 },   // 安静环境
      { current: 65, min: 30, avg: 55, max: 70 },   // 正常对话
      { current: 85, min: 30, avg: 75, max: 90 },   // 嘈杂环境
      { current: 45, min: 30, avg: 40, max: 50 }    // 回归安静
    ];
    
    let index = 0;
    const animate = () => {
      if (this.isAnimating) {
        const data = demoSequence[index];
        this.currentDecibel = data.current;
        this.minDecibel = data.min;
        this.avgDecibel = data.avg;
        this.maxDecibel = data.max;
        
        index = (index + 1) % demoSequence.length;
        setTimeout(animate, 2000);
      }
    };
    
    animate();
  }

  build() {
    Column({ space: DesignConstants.SPACING_XL }) {
      // 顶部导航
      this.buildHeader()

      // 使用现有的分贝显示组件
      DecibelDisplayComponent({
        currentDecibel: this.currentDecibel,
        minDecibel: this.minDecibel,
        avgDecibel: this.avgDecibel,
        maxDecibel: this.maxDecibel,
        weightingType: 'A',
        isDemoMode: true // 添加演示模式，隐藏不必要的控制元素
      })

      // 功能描述
      this.buildFeatureDescription()

      // 操作按钮
      Button('下一页', { type: ButtonType.Capsule })
        .width('100%')
        .height(56)
        .backgroundColor($r('app.color.primary'))
        .fontColor($r('app.color.white'))
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
        .backgroundColor($r('app.color.background_secondary'))
        .onClick(() => this.onPrev())

      Blank()

      Text('跳过')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.text_secondary'))
        .onClick(() => this.onSkip())
    }
    .width('100%')
  }

  @Builder
  private buildFeatureDescription() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('实时精准检测')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

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
}
```

### 第3页：高级功能页（复用频谱组件）

```typescript
import { SpectrumChartComponent } from '../decibel-meter/SpectrumChartComponent';
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
    // 生成演示用的频谱数据
    const data = new Float32Array(128);
    for (let i = 0; i < data.length; i++) {
      // 模拟真实的频谱形状
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

      // 使用现有的频谱图组件
      SpectrumChartComponent({
        spectrumData: this.spectrumData,
        isSimplified: true // 简化模式，适合引导页展示
      })
      .height(120)

      // 功能描述
      this.buildFeatureDescription()

      // 功能图标网格
      this.buildFeatureGrid()

      // 操作按钮
      Button('下一页', { type: ButtonType.Capsule })
        .width('100%')
        .height(56)
        .backgroundColor($r('app.color.primary'))
        .fontColor($r('app.color.white'))
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .onClick(() => this.onNext())
    }
    .width('100%')
    .height('100%')
    .padding(DesignConstants.SPACING_LG)
  }

  @Builder
  private buildFeatureDescription() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('专业分析工具')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

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
    }
    .width('100%')
  }

  @Builder
  private buildFeatureGrid() {
    Row({ space: DesignConstants.SPACING_MD }) {
      this.buildFeatureItem('频谱分析', $r('app.media.ic_frequency_weighting'))
      this.buildFeatureItem('数据记录', $r('app.media.ic_history'))
      this.buildFeatureItem('加权模式', $r('app.media.ic_weighting'))
      this.buildFeatureItem('自定义', $r('app.media.ic_settings'))
    }
    .justifyContent(FlexAlign.SpaceAround)
    .width('100%')
    .margin({ top: DesignConstants.SPACING_LG })
  }

  @Builder
  private buildFeatureItem(title: string, icon: Resource) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Image(icon)
        .width(DesignConstants.ICON_SIZE_LG)
        .height(DesignConstants.ICON_SIZE_LG)
        .fillColor($r('app.color.primary'))

      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
    }
    .padding(DesignConstants.SPACING_MD)
  }
}
```

## 需要修改的现有组件

### 1. 为分贝显示组件添加演示模式
在 [`DecibelDisplayComponent.ets`](entry/src/main/ets/components/decibel-meter/DecibelDisplayComponent.ets) 中添加：

```typescript
@Param isDemoMode: boolean = false;

// 在build方法中根据isDemoMode隐藏控制元素
if (!this.isDemoMode) {
  // 显示正常的控制按钮
} else {
  // 简化显示，只保留核心的分贝值展示
}
```

### 2. 为频谱组件添加简化模式
在 [`SpectrumChartComponent.ets`](entry/src/main/ets/components/decibel-meter/SpectrumChartComponent.ets) 中添加：

```typescript
@Param isSimplified: boolean = false;

// 在绘制逻辑中根据isSimplified调整样式
if (this.isSimplified) {
  // 使用更简洁的样式，隐藏坐标轴等
} else {
  // 完整的频谱图显示
}
```

## 集成到Index.ets的代码

```typescript
// 在Index.ets的build方法中
if (this.pk.privacy_agreed) {
  if (!this.pk.has_seen_welcome) {
    // 显示欢迎页
    WelcomeGuideBuilder({
      onComplete: () => {
        this.pk.has_seen_welcome = true;
        // 进入主应用
        MainPage()
      },
      onCancel: () => {
        this.context.terminateSelf();
      }
    })
  } else {
    // 直接进入主应用
    MainPage()
  }
} else {
  // 原有的隐私政策逻辑保持不变
  // 用户同意后会进入欢迎页
}
```

## 优势

1. **开发效率高**：复用现有组件，减少重复代码
2. **一致性**：使用相同的设计系统和组件，保证UI一致性
3. **维护简单**：核心逻辑在现有组件中，欢迎页只负责展示
4. **性能优化**：复用经过优化的现有组件

这个方案可以快速实现高质量的欢迎页，同时保持代码的可维护性。