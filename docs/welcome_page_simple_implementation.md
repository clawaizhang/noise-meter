# 欢迎页简洁实现方案

## 概述
直接复用现有组件，无需任何修改，快速实现欢迎页功能。

## 可直接复用的组件

### 1. 分贝显示核心部分
直接从 [`DecibelDisplayComponent.ets`](entry/src/main/ets/components/decibel-meter/DecibelDisplayComponent.ets) 中提取显示逻辑：

```typescript
// 直接复用分贝值显示部分
Column({ space: DesignConstants.SPACING_MD }) {
  // 当前分贝值
  Text(`${this.currentDecibel}`)
    .fontSize(DesignConstants.FONT_SIZE_4XL)
    .fontWeight(FontWeight.Bold)
    .fontColor(this.getDecibelColor(this.currentDecibel))

  Text('分贝')
    .fontSize(DesignConstants.FONT_SIZE_LG)
    .fontColor($r('app.color.text_secondary'))

  // 分贝等级指示
  Text(this.getDecibelLevelText(this.currentDecibel))
    .fontSize(DesignConstants.FONT_SIZE_MD)
    .fontColor(this.getDecibelColor(this.currentDecibel))
}
```

### 2. 频谱图组件
直接使用 [`SpectrumChartComponent.ets`](entry/src/main/ets/components/decibel-meter/SpectrumChartComponent.ets)：

```typescript
SpectrumChartComponent({
  spectrumData: this.spectrumData
})
```

## 完整的欢迎页实现代码

### 第2页：实时检测页

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

  private startDemoAnimation(): void {
    // 简单的分贝值循环动画
    const values = [35, 65, 85, 45];
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

  private getDecibelColor(decibel: number): Resource {
    if (decibel <= 50) return $r('app.color.decibel_safe');
    if (decibel <= 70) return $r('app.color.decibel_warning');
    return $r('app.color.decibel_danger');
  }

  private getDecibelLevelText(decibel: number): string {
    if (decibel <= 40) return '非常安静';
    if (decibel <= 60) return '安静';
    if (decibel <= 75) return '适中';
    if (decibel <= 85) return '嘈杂';
    return '非常嘈杂';
  }

  build() {
    Column({ space: DesignConstants.SPACING_XL }) {
      // 顶部导航
      this.buildHeader()

      // 分贝显示（直接复用显示逻辑）
      Column({ space: DesignConstants.SPACING_MD }) {
        // 当前分贝值
        Text(`${this.currentDecibel}`)
          .fontSize(DesignConstants.FONT_SIZE_4XL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getDecibelColor(this.currentDecibel))

        Text('分贝')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontColor($r('app.color.text_secondary'))

        // 分贝等级
        Text(this.getDecibelLevelText(this.currentDecibel))
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(this.getDecibelColor(this.currentDecibel))

        // 简单的进度条
        Stack({ alignContent: Alignment.BottomStart }) {
          Rectangle()
            .width(200)
            .height(12)
            .fillColor($r('app.color.background_secondary'))
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

### 第3页：高级功能页

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
      // 简单的频谱形状
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

      // 直接使用频谱图组件
      SpectrumChartComponent({
        spectrumData: this.spectrumData
      })
      .height(120)

      // 功能描述
      this.buildFeatureDescription()

      // 功能图标
      this.buildFeatureIcons()

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
  private buildFeatureIcons() {
    Row({ space: DesignConstants.SPACING_MD }) {
      Column({ space: DesignConstants.SPACING_XS }) {
        Image($r('app.media.ic_frequency_weighting'))
          .width(32)
          .height(32)
          .fillColor($r('app.color.primary'))
        Text('频谱分析')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('app.color.text_secondary'))
      }

      Column({ space: DesignConstants.SPACING_XS }) {
        Image($r('app.media.ic_history'))
          .width(32)
          .height(32)
          .fillColor($r('app.color.primary'))
        Text('数据记录')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('app.color.text_secondary'))
      }

      Column({ space: DesignConstants.SPACING_XS }) {
        Image($r('app.media.ic_weighting'))
          .width(32)
          .height(32)
          .fillColor($r('app.color.primary'))
        Text('加权模式')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('app.color.text_secondary'))
      }
    }
    .justifyContent(FlexAlign.SpaceAround)
    .width('100%')
    .margin({ top: DesignConstants.SPACING_LG })
  }
}
```

## 优势

1. **零修改**：不需要修改任何现有组件
2. **快速实现**：直接复制显示逻辑，立即可用
3. **一致性**：使用相同的颜色、字体和设计规范
4. **维护简单**：没有额外的模式参数，代码清晰

## 实现步骤

1. 创建4个欢迎页组件文件
2. 复制现有的显示逻辑到相应页面
3. 添加简单的动画效果
4. 集成到Index.ets中

这个方案最简单直接，可以立即开始编码实现。