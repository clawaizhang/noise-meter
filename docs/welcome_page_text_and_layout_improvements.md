# 欢迎页面文本和布局改进计划

## 问题分析

### 当前问题
1. **文本内容不够专业**：
   - "您的听力健康守护专家" → 过于强调听力健康，而噪音分析主要涉及环境监测
   - "实时守护您的听力健康" → 同样过于强调听力保护

2. **布局问题**：
   - 功能项在整个屏幕左对齐，视觉效果不佳
   - 需要改为在屏幕居中后再左对齐

## 改进方案

### 1. 文本内容优化

#### WelcomePage 修改：
- **主标题**：静喵Sound（保持不变）
- **副标题**：从"您的听力健康守护专家"改为"专业噪音分析工具"
- **描述**：从"精准检测环境噪音，保护您的听力健康"改为"精准检测环境噪音，专业数据分析"

#### RealTimeDetectionPage 修改：
- **标题**：从"实时守护您的听力健康"改为"实时噪音监测分析"
- **功能项**：
  - "即时响应，随时了解环境噪音" → "即时响应，实时环境噪音监测"
  - "智能识别，贴心提醒" → "智能识别，专业数据分析"
  - "支持多种环境场景检测" → "支持多种环境场景分析"

### 2. 布局优化

#### 实现方案：
- 在功能项容器外层使用 `Column` 或 `Row` 实现居中
- 在功能项内部使用 `Column` 或 `Row` 实现左对齐
- 设置合适的宽度限制，避免功能项过宽

### 3. 具体修改文件

#### 需要修改的文件：
1. `entry/src/main/ets/components/welcome/WelcomePage.ets`
2. `entry/src/main/ets/components/welcome/RealTimeDetectionPage.ets`

## 技术实现细节

### WelcomePage 布局改进
```typescript
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
```

### RealTimeDetectionPage 布局改进
```typescript
// 功能描述 - 居中后再左对齐
Column({ space: DesignConstants.SPACING_LG }) {
  Text('实时噪音监测分析')
    .fontSize(DesignConstants.FONT_SIZE_XL)
    .fontWeight(FontWeight.Bold)
    .fontColor($r('sys.color.font_emphasize'))
    .textAlign(TextAlign.Center)

  // 功能亮点卡片 - 居中
  Column({ space: DesignConstants.SPACING_MD }) {
    this.buildFeatureItem('即时响应，实时环境噪音监测', $r('app.media.ic_audio_analysis'))
    this.buildFeatureItem('智能识别，专业数据分析', $r('app.media.ic_meter'))
    this.buildFeatureItem('支持多种环境场景分析', $r('app.media.ic_home'))
  }
  .width('80%')  // 限制宽度
  .alignItems(HorizontalAlign.Start)  // 内部左对齐
}
.alignItems(HorizontalAlign.Center)  // 外部居中
```

## 预期效果

### 改进后的优势：
1. **更专业的定位**：强调噪音分析的专业性，而非听力保护
2. **更好的视觉效果**：功能项在屏幕居中后再左对齐，布局更美观
3. **一致的品牌形象**：所有页面保持统一的专业定位
4. **更好的用户体验**：布局更合理，信息层次更清晰

## 实施步骤

1. 修改 WelcomePage 的文本内容和布局
2. 修改 RealTimeDetectionPage 的文本内容和布局  
3. 测试布局效果和文本显示
4. 验证在不同设备上的兼容性