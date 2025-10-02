# 全局响应式设计系统使用指南

## 概述

本系统提供了一个基于横向断点、纵向断点和窗口尺寸的全局响应式设计系统，所有尺寸值统一在 AppKeys 中管理，窗口变化时自动更新。

## 核心特性

- **断点驱动**：基于系统提供的横向断点、纵向断点和窗口尺寸
- **统一管理**：所有响应式尺寸在 AppKeys 中统一更新
- **实时响应**：窗口变化时自动重新计算所有尺寸
- **简洁易用**：属性命名简洁，使用方便

## 使用方法

### 1. 在组件中连接 AppKeys

```typescript
import { AppKeys } from '../models/AppKeys';
import { AppStorageV2 } from '@kit.ArkUI';

@Local as: AppKeys = AppStorageV2.connect(AppKeys)!;
```

### 2. 使用响应式字体

```typescript
// 标题
Text('分贝值')
  .fontSize(this.as.responsive.fontSize.xxxxl)  // 32px * scale

// 正文
Text('描述文本')
  .fontSize(this.as.responsive.fontSize.md)    // 14px * scale

// 小文本
Text('标签')
  .fontSize(this.as.responsive.fontSize.sm)    // 12px * scale
```

### 3. 使用响应式间距

```typescript
// 组件间距
Column({ space: this.as.responsive.spacing.md }) // 12px * scale

// 边距
Stack()
  .margin({
    top: this.as.responsive.spacing.lg,    // 16px * scale
    bottom: this.as.responsive.spacing.lg,
    left: this.as.responsive.spacing.lg,
    right: this.as.responsive.spacing.lg
  })

// 内边距
Column()
  .padding(this.as.responsive.spacing.sm)  // 8px * scale
```

### 4. 使用响应式图标尺寸

```typescript
Image($r('app.media.ic_mic'))
  .width(this.as.responsive.iconSize.lg)   // 24px * scale
  .height(this.as.responsive.iconSize.lg)
```

### 5. 使用响应式圆角

```typescript
Stack()
  .borderRadius(this.as.responsive.borderRadius.lg)  // 16px * scale

// 圆形按钮
Button()
  .borderRadius(this.as.responsive.borderRadius.full) // 999px (固定值)
```

## 响应式尺寸范围

### 字体系统
- `xs`: 10px * scale
- `sm`: 12px * scale  
- `md`: 14px * scale
- `lg`: 16px * scale
- `xl`: 18px * scale
- `xxl`: 20px * scale
- `xxxl`: 24px * scale
- `xxxxl`: 32px * scale

### 间距系统
- `xs`: 4px * scale
- `sm`: 8px * scale
- `md`: 12px * scale
- `lg`: 16px * scale
- `xl`: 20px * scale
- `xxl`: 24px * scale
- `xxxl`: 32px * scale
- `xxxxl`: 40px * scale

### 图标尺寸
- `xs`: 12px * scale
- `sm`: 16px * scale
- `md`: 20px * scale
- `lg`: 24px * scale
- `xl`: 32px * scale
- `xxl`: 40px * scale
- `xxxl`: 48px * scale

### 圆角系统
- `xs`: 4px * scale
- `sm`: 8px * scale
- `md`: 12px * scale
- `lg`: 16px * scale
- `xl`: 20px * scale
- `xxl`: 24px * scale
- `full`: 999px (固定值)

## 响应式比例计算

系统基于以下因素计算响应式比例：

### 横向断点影响
- `WIDTH_XS` (< 320vp): 0.9x
- `WIDTH_SM` (320-599vp): 1.0x
- `WIDTH_MD` (600-839vp): 1.05x
- `WIDTH_LG` (840-1439vp): 1.1x
- `WIDTH_XL` (>= 1440vp): 1.15x
- `WIDTH_XXL`: 1.2x

### 纵向断点影响
- `HEIGHT_XS`: 0.95x
- `HEIGHT_SM`: 1.0x
- `HEIGHT_MD`: 1.02x
- `HEIGHT_LG`: 1.05x
- `HEIGHT_XL`: 1.08x
- `HEIGHT_XXL`: 1.1x

最终比例限制在 0.8 - 1.3 范围内。

## 最佳实践

### 1. 优先使用响应式尺寸
```typescript
// ✅ 推荐
Text('标题').fontSize(this.as.responsive.fontSize.xl)

// ❌ 不推荐
Text('标题').fontSize(18)
```

### 2. 组合使用间距
```typescript
// ✅ 推荐
Column({ space: this.as.responsive.spacing.md })
  .padding(this.as.responsive.spacing.lg)

// ❌ 不推荐
Column({ space: 12 })
  .padding(16)
```

### 3. 保持一致性
```typescript
// ✅ 推荐 - 使用相同的间距级别
Row({ space: this.as.responsive.spacing.md })
Column({ space: this.as.responsive.spacing.md })

// ❌ 不推荐 - 混合使用不同间距
Row({ space: 8 })
Column({ space: 16 })
```

## 迁移指南

### 从硬编码值迁移
```typescript
// 旧代码
Text('标题').fontSize(18)
Column({ space: 12 })

// 新代码
Text('标题').fontSize(this.as.responsive.fontSize.xl)
Column({ space: this.as.responsive.spacing.md })
```

### 从 DesignConstants 迁移
```typescript
// 旧代码
import { DesignConstants } from '../constants/DesignConstants';
Text('标题').fontSize(DesignConstants.FONT_SIZE_XL)

// 新代码
Text('标题').fontSize(this.as.responsive.fontSize.xl)
```

## 调试和测试

### 查看当前响应式比例
```typescript
// 在控制台查看当前比例
console.info(`当前响应式比例: ${this.as.responsive.fontSize.xl / 18}`)
```

### 测试不同断点
- 调整窗口大小观察尺寸变化
- 使用不同设备模拟器测试
- 验证横竖屏切换时的响应性

这个响应式设计系统确保了应用在所有设备上的一致性和良好的用户体验。