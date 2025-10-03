# 显示模式按钮进一步优化方案

## 当前问题
当前按钮尺寸仍然偏大，需要进一步缩小，让三个按钮占据右侧大约一半的位置。

## 优化方案

### 新的按钮尺寸
- **按钮高度**: 32px（原40px）
- **按钮内边距**: 左右8px（原12px）
- **字体大小**: 12px（原14px）
- **图标大小**: 14px（原16px）
- **按钮间距**: 2px（原4px）

### 布局调整
- 按钮容器整体更紧凑
- 使用更小的圆角：16px（原20px）
- 减少内边距，让按钮更加紧凑

### 代码实现

```typescript
// 构建显示模式选项卡
@Builder
private buildDisplayModeTabs() {
  // 选项卡容器
  Row({ space: 2 }) {
    ForEach(['default', 'light', 'dark'], (displayMode: string) => {
      // 选项卡内容
      Row({ space: 2 }) {
        // 显示模式图标（更小的图标）
        Image(this.getDisplayModeIcon(displayMode))
          .width(14)
          .height(14)
          .fillColor(this.selectedDisplayMode === displayMode ?
          $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))

        // 显示模式名称（更小的字体）
        Text(this.getDisplayModeText(displayMode))
          .fontSize(12)
          .fontWeight(this.selectedDisplayMode === displayMode ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.selectedDisplayMode === displayMode ?
          $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .height(32)
      .padding({ left: 8, right: 8 })
      .backgroundColor(this.selectedDisplayMode === displayMode ?
      $r('sys.color.interactive_active') : $r('sys.color.comp_background_primary'))
      .borderRadius(16)
      .onClick(() => {
        this.handleDisplayModeSelect(displayMode);
      })
    })
  }
  .backgroundColor($r('sys.color.comp_background_primary'))
  .borderRadius(16)
  .height(32)
  .padding(2)
}
```

## 预期效果

### 优化后的布局比例：
```
┌─────────────────────────────────────────┐
│ 显示模式图标  显示模式      [自] [浅] [深] │
└─────────────────────────────────────────┘
```

### 尺寸对比：
- **原尺寸**: 按钮高度56px，占据整个右侧
- **第一次优化**: 按钮高度40px，仍然偏大
- **最终优化**: 按钮高度32px，占据右侧约一半位置

### 视觉优势：
1. **更加紧凑**: 按钮尺寸显著减小，布局更加平衡
2. **比例协调**: 标题区域和按钮区域的比例更加协调
3. **操作友好**: 仍然保持足够的点击区域，操作体验良好
4. **视觉统一**: 与整体应用的设计风格保持一致

这样的尺寸调整后，三个按钮将占据右侧大约一半的位置，既节省空间又保持美观。