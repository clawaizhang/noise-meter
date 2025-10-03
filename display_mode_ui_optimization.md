# 显示模式UI布局优化方案

## 当前问题分析
当前显示模式设置占用两行空间：
- 第一行：显示模式标题和图标
- 第二行：三个大按钮（自动、浅色、深色）

这种布局占用空间较大，不够紧凑。

## 优化方案

### 新布局设计
将显示模式按钮放在同一行，位于"显示模式"标题的右侧：

```
┌─────────────────────────────────────────┐
│ 显示模式图标  显示模式    [自动] [浅色] [深色] │
└─────────────────────────────────────────┘
```

### 具体实现方案

#### 1. 布局结构调整
- 使用 `Row` 容器，左侧为标题区域，右侧为按钮区域
- 标题区域：图标 + 文本
- 按钮区域：三个紧凑的按钮在同一行

#### 2. 按钮尺寸优化
- 按钮高度：40px（原56px）
- 按钮宽度：自适应内容
- 按钮间距：8px
- 字体大小：14px（原16px）

#### 3. 视觉样式调整
- 保持原有的颜色和交互效果
- 按钮使用圆角设计，保持视觉一致性
- 选中状态使用高亮背景色

### 代码实现预览

```typescript
@Builder
private buildDisplayModeTabs() {
  Row({ space: 0 }) {
    ForEach(['default', 'light', 'dark'], (displayMode: string) => {
      Row({ space: 4 }) {
        // 显示模式图标（可选，为了节省空间可以省略）
        Image(this.getDisplayModeIcon(displayMode))
          .width(16)
          .height(16)
          .fillColor(this.selectedDisplayMode === displayMode ?
          $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))

        // 显示模式名称
        Text(this.getDisplayModeText(displayMode))
          .fontSize(14)
          .fontWeight(this.selectedDisplayMode === displayMode ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.selectedDisplayMode === displayMode ?
          $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .height(40)
      .padding({ left: 12, right: 12 })
      .backgroundColor(this.selectedDisplayMode === displayMode ?
      $r('sys.color.interactive_active') : $r('sys.color.comp_background_primary'))
      .borderRadius(20)
      .onClick(() => {
        this.handleDisplayModeSelect(displayMode);
      })
    })
  }
  .backgroundColor($r('sys.color.comp_background_primary'))
  .borderRadius(20)
  .height(40)
  .padding(4)
}
```

### 组件整体布局

```typescript
build() {
  Column({ space: 8 }) {
    Row() {
      // 左侧：标题区域
      Row({ space: 8 }) {
        Image($r('sys.media.ohos_ic_public_device_smartscreen'))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.font_primary'))
        Text('显示模式')
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
      }.layoutWeight(1)

      // 右侧：按钮区域
      this.buildDisplayModeTabs()
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
  }
  .backgroundColor($r('sys.color.comp_background_primary'))
  .justifyContent(FlexAlign.Start)
  .alignItems(HorizontalAlign.Start)
  .borderRadius(16)
  .padding(16)
}
```

## 优势

1. **空间效率**：从两行变为一行，节省50%的垂直空间
2. **视觉平衡**：标题和按钮在同一行，布局更加平衡
3. **操作便捷**：所有选项在同一视觉区域内，用户操作更加直观
4. **保持功能**：所有原有功能保持不变，包括选中状态、悬停效果等

## 预期效果

优化后的显示模式设置将更加紧凑，适合在"MyContent"页面中与其他设置项保持一致的布局风格，同时提供良好的用户体验。