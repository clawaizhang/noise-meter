# 设备方向设置说明

## 功能概述

本应用根据设备类型自动设置合适的屏幕方向，以提供最佳的用户体验。

## 设备类型与方向设置

| 设备类型 | 方向设置 | 说明 |
|---------|---------|------|
| **phone** | `PORTRAIT` | 手机设备强制竖屏，提供最佳的单手操作体验 |
| **tablet** | `LANDSCAPE` | 平板设备默认横屏，充分利用大屏幕空间 |
| **car** | `AUTO_ROTATION` | 车载设备允许自动旋转，适应不同安装方式 |
| **2in1** | `AUTO_ROTATION` | 二合一设备允许自动旋转，支持多种使用模式 |

## 实现位置

设备类型检测和方向设置在 [`EntryAbility.ets`](../entry/src/main/ets/entryability/EntryAbility.ets) 文件的 `onWindowStageCreate` 方法中实现：

```typescript
// 获取设备类型
let deviceTypeInfo: string = deviceInfo.deviceType;
let orientation = window.Orientation.AUTO_ROTATION;

// 判断设备类型来设置窗口显示方向
if (deviceTypeInfo == 'phone') {
  // 手机设备强制竖屏
  orientation = window.Orientation.PORTRAIT;
} else if (deviceTypeInfo == 'tablet') {
  // 平板设备默认横屏
  orientation = window.Orientation.LANDSCAPE;
} else {
  // 其他设备类型（car、2in1等）保持自动旋转
  orientation = window.Orientation.AUTO_ROTATION;
}
```

## 设计考虑

### 手机设备 (PORTRAIT)
- 强制竖屏确保一致的用户体验
- 避免横屏时界面布局问题
- 符合手机应用的使用习惯

### 平板设备 (LANDSCAPE)
- 默认横屏充分利用屏幕宽度
- 适合显示更多内容和图表
- 提供更好的数据可视化体验

### 其他设备 (AUTO_ROTATION)
- 车载和二合一设备允许自动旋转
- 适应不同的安装和使用场景
- 提供更大的灵活性

## 测试建议

1. **手机设备测试**：确保手机设备始终显示为竖屏，无法旋转
2. **平板设备测试**：确保平板设备默认显示为横屏
3. **其他设备测试**：验证车载和二合一设备可以正常旋转

## 日志输出

设备类型检测结果会在日志中输出，便于调试：
```
the value of the deviceType is:phone
```

方向设置成功或失败也会有相应的日志记录。