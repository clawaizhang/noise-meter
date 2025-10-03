# 设置项状态显示正确设计

## UI结构分析

参考频率加权和时间计权模式的UI结构：

### 频率加权模式（第439-479行）
- **左侧**：图标 + "频率加权"标题
- **右侧**：当前值（如"A计权"）+ 右箭头
- **下方**：描述信息（如"A计权模拟人耳对声音的感知"）

### 时间计权模式（第383-437行）
- **左侧**：图标 + "时间计权模式"标题
- **右侧**：当前值（如"快速(F)"）+ 右箭头
- **下方**：描述信息 + 技术参数

## 正确的UI设计

### 1. 声级校准设置项
**UI结构**：
- **左侧**：图标 + "声级校准"标题
- **右侧**：显示当前校准值（如"+2.5 dB"）+ 右箭头
- **下方**：描述信息（如"当前校准值用于调整麦克风灵敏度"）

**数据源**：`pk.calibration_value`

### 2. 警报与通知设置项
**UI结构**：
- **左侧**：图标 + "警报与通知"标题
- **右侧**：显示"开启"或"关闭" + 右箭头
- **下方**：描述信息
  - 如果开启：显示"当噪音超过XX dB时发送通知"
  - 如果关闭：显示"警报通知已关闭"

**数据源**：
- `pk.system_notification_enabled`（开关状态）
- `ThresholdManager.getCurrentEffectiveThreshold()`（当前阈值）

### 3. 自动保存设置项
**UI结构**：
- **左侧**：图标 + "自动保存"标题
- **右侧**：显示"开启"或"关闭" + 右箭头
- **下方**：描述信息
  - 如果开启：显示"系统会每隔X分钟自动保存一次"
  - 如果关闭：显示"自动保存已关闭"

**数据源**：
- `pk.auto_save_enabled`（开关状态）
- `pk.auto_save_interval`（保存间隔）

## 实现策略

需要将现有的`buildListItem`调用改为使用完整的GridCol结构，类似于频率加权和时间计权模式的实现。

### 声级校准示例结构：
```typescript
GridCol() {
  Column() {
    Row() {
      // 左侧：图标 + 标题
      Row({ space: 8 }) {
        Image($r('app.media.ic_audio_analysis')).itemIcon()
        Text('声级校准').itemTitle()
      }.layoutWeight(1)
      
      // 右侧：当前值 + 箭头
      Row({ space: DesignConstants.SPACING_XS }) {
        Text(this.getCalibrationDisplayValue())
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
        Image($r('sys.media.ohos_ic_public_arrow_right'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor($r('sys.color.font_secondary'))
      }
      .padding({...})
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_SM)
    }
    .listItemRow()
    
    // 下方描述
    Text(this.getCalibrationDescription())
      .itemDescription()
  }
  .onClick(() => { this.navigateToAudioAnalysis(); })
  .cardStyle()
}
```

## 需要创建的方法

### 声级校准
- `getCalibrationDisplayValue()`: 返回显示在右侧的值（如"+2.5 dB"）
- `getCalibrationDescription()`: 返回下方描述信息

### 警报与通知
- `getAlertsDisplayValue()`: 返回"开启"或"关闭"
- `getAlertsDescription()`: 返回阈值描述或关闭提示

### 自动保存
- `getAutoSaveDisplayValue()`: 返回"开启"或"关闭"
- `getAutoSaveDescription()`: 返回间隔描述或关闭提示

这种设计将确保UI风格的一致性，让用户能够快速了解当前设置状态。