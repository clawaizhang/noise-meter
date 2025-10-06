# 校准进度显示优化计划

## 问题分析

### 1. 进度条重复问题
- **文件**: [`ImprovedAutoCalibration.ets`](entry/src/main/ets/components/calibration/ImprovedAutoCalibration.ets:1)
- **问题**: 存在两个环形进度条显示
- **解决方案**: 保留主要校准进度条，移除重复显示

### 2. 文案显示错误
- **位置**: [`ImprovedAutoCalibration.ets`](entry/src/main/ets/components/calibration/ImprovedAutoCalibration.ets:142)
- **当前文案**: `校准中... ${8 - this.calibrationProgress}秒`
- **问题**: `calibrationProgress` 是百分比(0-100)，但直接与8相减导致时间计算错误
- **正确计算**: `剩余 ${Math.ceil(8 - (this.calibrationProgress / 100 * 8))}秒`

### 3. 校准时间配置
- **总时长**: 11秒
  - **倒计时**: 3秒 ([`COUNTDOWN_DURATION`](entry/src/main/ets/constants/CalibrationConstants.ets:132))
  - **校准过程**: 8秒 ([`AUTO_CALIBRATION_DURATION`](entry/src/main/ets/constants/CalibrationConstants.ets:131))

## 具体修改方案

### 1. 修复时间计算错误
```typescript
// 当前错误代码 (第142行)
Text(`校准中... ${8 - this.calibrationProgress}秒`)

// 修改为正确代码
Text(`校准中... 剩余 ${Math.ceil(8 - (this.calibrationProgress / 100 * 8))}秒`)
```

### 2. 优化进度显示逻辑
- 倒计时阶段：显示"X秒后开始校准..."
- 校准阶段：显示"校准中... 剩余X秒"
- 完成阶段：显示校准结果

### 3. 验证校准流程一致性
检查 [`AudioAnalysisSettingsNavigation.ets`](entry/src/main/ets/pages/settings/AudioAnalysisSettingsNavigation.ets:1) 中的校准逻辑是否与配置一致。

## 实施步骤

1. **修复时间计算错误** - 修改第142行的文案显示
2. **优化状态描述** - 确保倒计时和校准阶段的文案清晰
3. **验证配置一致性** - 确保所有组件使用相同的校准时长配置
4. **测试校准流程** - 验证总时长11秒的准确性

## 预期效果

- 消除进度显示重复问题
- 修复时间计算错误，显示准确的剩余时间
- 提供清晰的校准状态反馈
- 确保校准流程的时间逻辑一致性