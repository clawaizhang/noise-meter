# 警报持续时间刷新修正方案

## 问题分析

我之前的实现有误，没有正确理解双管线架构：

**错误理解：**
- 在 AudioControllerService 中添加后台定时器来更新 DataProcessingState
- 认为 DataProcessingState 需要在后台手动触发更新

**正确理解：**
- DataProcessingState 应该始终运行，无论前台还是后台
- 后台运行时，DataProcessingState 继续计算，但 UIDisplayState 停止同步
- 前台运行时，UIDisplayState 从 DataProcessingState 同步数据

## 修正方案

### 1. 移除 AudioControllerService 中的后台定时器

需要移除：
- `backgroundAlertTimer` 字段
- `startBackgroundAlertUpdate()` 方法  
- `stopBackgroundAlertUpdate()` 方法
- 在 `pauseUIUpdates()` 和 `resumeUIUpdates()` 中的相关调用

### 2. 确保 DataProcessingState 持续运行

DataProcessingState 应该由音频处理服务或其他持续运行的服务来更新，而不是在 AudioControllerService 中手动触发。

### 3. 正确的数据流向

```
前台运行：
DataProcessingState (持续计算) → UIDisplayState (同步) → UI显示

后台运行：
DataProcessingState (持续计算) → UIDisplayState (停止同步) → UI不更新
```

## 具体修正

需要回滚 AudioControllerService 的修改，保持其原有的前后台切换逻辑，只控制 UIDisplayState 的同步，不干预 DataProcessingState 的运行。