# DialogContainer 组件改进说明

## 🎯 改进概述

对原有的DialogContainer组件进行了全面的UI和交互优化，提升了用户体验和视觉效果。

## ✨ 主要改进特性

### 1. 视觉设计升级
- **现代化阴影效果**: 使用DesignConstants中的阴影系统
- **改进的拖动条**: 更精致的视觉设计，拖动时有透明度变化
- **更好的背景遮罩**: 透明度从0.18提升到0.25，层次感更强

### 2. 动画效果优化
- **弹簧动画**: 使用Curve.Spring替代简单的EaseIn/Smooth曲线
- **缩放效果**: 弹窗出现时有轻微缩放动画
- **流畅的过渡**: 优化了动画时长和曲线参数

### 3. 交互体验增强
- **手势反馈**: 拖动时提供视觉反馈（透明度和缩放变化）
- **更灵敏的拖动手势**: 改进的手势识别逻辑
- **ESC键支持**: 支持键盘ESC键关闭弹窗

### 4. 响应式设计
- **屏幕适配**: 针对不同屏幕尺寸优化布局
- **最大高度控制**: 根据屏幕高度动态调整弹窗最大高度
- **圆角适配**: 不同屏幕宽度下使用不同的圆角值

### 5. 代码结构优化
- **常量分离**: 创建DialogConstants管理所有弹窗相关配置
- **类型安全**: 使用接口定义配置结构
- **易于维护**: 所有设计参数集中管理

## 🚀 使用方法

### 基础用法
```typescript
import { DialogContainerBuilder } from './DialogContainer';

// 在build方法中使用
DialogContainerBuilder(() => {
  Column() {
    Text('弹窗内容')
      .fontSize(16)
  }
  .padding(16)
})
```

### 复杂示例
```typescript
// 表单弹窗
DialogContainerBuilder(() => {
  Column() {
    Text('标题').fontSize(18).fontWeight(FontWeight.Bold)
    TextInput({ placeholder: '输入内容' })
    Button('确认').onClick(() => { /* 处理逻辑 */ })
  }
  .padding(20)
})
```

## ⚙️ 配置说明

所有配置都在 `DialogConstants` 中管理：

### 动画配置
- `ANIMATION.ENTER_DURATION`: 进入动画时长 (600ms)
- `ANIMATION.EXIT_DURATION`: 退出动画时长 (400ms)
- `ANIMATION.SPRING_TENSION`: 弹簧张力 (0.6)
- `ANIMATION.SPRING_FRICTION`: 弹簧摩擦 (0.9)

### 视觉配置
- `DIALOG.BACKGROUND_OPACITY`: 背景遮罩透明度 (0.25)
- `DIALOG.BORDER_RADIUS`: 弹窗圆角 (16px)
- `DIALOG.MAX_HEIGHT`: 最大高度 ('85%')

### 手势配置
- `GESTURE.MAX_DRAG_DISTANCE`: 最大拖动距离 (150px)
- `GESTURE.DRAG_PROGRESS_FACTOR`: 拖动进度因子 (0.4)
- `DIALOG.DRAG_THRESHOLD`: 拖动关闭阈值 (120px)

## 🎨 设计规范

### 颜色使用
- 背景色: `$r('app.color.background_primary')`
- 拖动条: `$r('app.color.divider')`
- 遮罩层: `$r('app.color.transparent_black_70')`

### 间距系统
使用DesignConstants中的标准间距：
- `SPACING_SM`: 8px
- `SPACING_MD`: 12px  
- `SPACING_LG`: 16px
- `SPACING_XL`: 20px

### 圆角系统
使用标准圆角值：
- `BORDER_RADIUS_MD`: 12px
- `BORDER_RADIUS_LG`: 16px
- `BORDER_RADIUS_XL`: 20px

## 🔧 自定义配置

如需自定义配置，可以直接修改 `DialogConstants` 中的值：

```typescript
// 修改动画时长
DialogConstants.ANIMATION.ENTER_DURATION = 800;

// 修改最大高度
DialogConstants.DIALOG.MAX_HEIGHT = '90%';
```

## 📱 响应式适配

组件自动适配不同屏幕尺寸：

```typescript
// 获取响应式配置
const maxHeight = DialogConstants.getResponsiveMaxHeight(screenHeight);
const borderRadius = DialogConstants.getResponsiveBorderRadius(screenWidth);
```

## 🎭 主题支持

支持深色模式适配：

```typescript
// 深色模式版本
DarkModeDialogContainer({ ContentBuilder: contentBuilder })
```

## 📊 性能优化

- 使用硬件加速动画
- 避免不必要的重渲染
- 优化手势事件处理
- 使用常量避免重复计算

## 🔍 调试提示

如果遇到问题，可以：
1. 检查DialogConstants配置是否正确
2. 确认颜色资源存在
3. 验证手势事件处理逻辑
4. 检查动画曲线参数

## 📝 版本历史

### v2.0 (当前)
- 全面UI重设计
- 动画效果优化
- 响应式支持
- 代码结构重构

### v1.0 (原始)
- 基础弹窗功能
- 简单手势支持
- 基本动画效果