# 布局对齐优化方案

## 当前问题分析

### 问题描述
- **第一页（WelcomePage）**：功能项在居中后再左对齐，导致图标位置错落不齐
- **第二页（RealTimeDetectionPage）**：同样存在图标位置错开的问题
- **第三页（AdvancedFeaturesPage）**：布局正确，所有内容都正确居中
- **核心问题**：当每行文本长度不同时，图标位置会错开，视觉效果不佳

## 优化方案

### 方案一：固定宽度容器 + 完全居中
```typescript
// 功能项容器 - 固定宽度 + 完全居中
Column({ space: DesignConstants.SPACING_SM }) {
  this.buildFeatureItem('实时精准检测', '毫秒级响应，专业级精度')
  this.buildFeatureItem('智能数据分析', '可视化报告，专业评估')
  this.buildFeatureItem('智能提醒保护', '噪音预警，环境监测')
}
.width('90%')  // 固定宽度
.alignItems(HorizontalAlign.Center)  // 完全居中
```

### 方案二：图标和文本分别对齐
```typescript
// 功能项 - 图标和文本分别对齐
@Builder
private buildFeatureItem(title: string, description: string) {
  Row({ space: DesignConstants.SPACING_MD }) {
    // 图标固定宽度，确保对齐
    Column() {
      Image($r('app.media.ic_meter'))
        .width(DesignConstants.ICON_SIZE_MD)
    }
    .width(40)  // 固定图标容器宽度
    
    // 文本内容
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Start)
      
      Text(description)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Start)
    }
    .layoutWeight(1)  // 文本区域占据剩余空间
  }
  .justifyContent(FlexAlign.Start)
  .width('100%')
}
```

### 方案三：网格布局（推荐）
```typescript
// 功能项容器 - 网格布局
Column({ space: DesignConstants.SPACING_SM }) {
  // 每个功能项使用固定宽度的容器
  ForEach(this.features, (item: FeatureItem, index: number) => {
    Column({ space: DesignConstants.SPACING_XS }) {
      Image(item.icon)
        .width(DesignConstants.ICON_SIZE_MD)
      
      Text(item.title)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)
        .maxLines(1)
      
      Text(item.description)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .maxLines(2)
    }
    .width('90%')  // 固定宽度
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .shadow(DesignConstants.SHADOW_SM)
  })
}
.alignItems(HorizontalAlign.Center)
```

### 方案四：统一图标和文本对齐基线
```typescript
// 功能项 - 统一对齐基线
@Builder
private buildFeatureItem(title: string, description: string, icon: Resource) {
  Row({ space: DesignConstants.SPACING_MD }) {
    // 图标区域
    Image(icon)
      .width(DesignConstants.ICON_SIZE_MD)
      .alignSelf(ItemAlign.Start)
    
    // 文本区域 - 统一对齐
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Start)
        .width('100%')
      
      Text(description)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Start)
        .width('100%')
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }
  .justifyContent(FlexAlign.Start)
  .width('90%')
  .alignSelf(ItemAlign.Center)
}
```

## 推荐方案

### 对于WelcomePage和RealTimeDetectionPage：
**推荐使用方案二（图标和文本分别对齐）**，因为：
- 图标位置固定，不会错开
- 文本内容可以自然换行
- 视觉上整齐统一
- 适应不同长度的文本内容

### 实施步骤：
1. 修改WelcomePage的buildFeatureItem方法，使用固定图标容器宽度
2. 修改RealTimeDetectionPage的buildFeatureItem方法，统一对齐方式
3. 确保所有功能项在容器内完全居中
4. 测试不同设备上的显示效果

## 预期效果
- **图标对齐**：所有图标在同一垂直线上
- **文本对齐**：所有文本左对齐，但整体居中
- **视觉统一**：所有功能项看起来整齐划一
- **响应式**：适应不同屏幕尺寸和文本长度