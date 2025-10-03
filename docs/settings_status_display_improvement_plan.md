# 设置项状态显示改进计划

## 问题分析

当前 [`SettingsNavigation.ets`](entry/src/main/ets/pages/noisemeter/SettingsNavigation.ets:1) 文件中存在以下状态显示不完整的问题：

### 1. 声级校准设置项（第443-451行）
- **当前状态**：只显示"声级校准、自动校准等设置"
- **缺失信息**：没有显示当前的校准值（`pk.calibration_value`）
- **期望显示**：应显示"当前校准值: X.X dB"

### 2. 警报与通知设置项（第453-460行）
- **当前状态**：只显示"噪音警报阈值和通知设置"
- **缺失信息**：
  - 没有显示警报是否开启（`pk.system_notification_enabled`）
  - 没有显示当前阈值（需要从阈值管理器获取）
- **期望显示**：应显示"警报状态: 开启/关闭 | 阈值: XX dB"

### 3. 自动保存设置项（第462-470行）
- **当前状态**：只显示"自动保存与时间间隔"
- **缺失信息**：
  - 没有显示自动保存是否开启（`pk.auto_save_enabled`）
  - 没有显示当前保存间隔（`pk.auto_save_interval`）
- **期望显示**：应显示"自动保存: 开启/关闭 | 间隔: X分钟"

## 技术实现方案

### 1. 声级校准状态显示
```typescript
private getCalibrationStatus(): string {
  const value = this.pk.calibration_value;
  if (value === 0) {
    return "当前校准值: 0 dB (未校准)";
  } else if (value > 0) {
    return `当前校准值: +${value.toFixed(1)} dB (增益)`;
  } else {
    return `当前校准值: ${value.toFixed(1)} dB (衰减)`;
  }
}
```

### 2. 警报与通知状态显示
```typescript
private getAlertsStatus(): string {
  const enabled = this.pk.system_notification_enabled;
  const threshold = ThresholdManager.getCurrentEffectiveThreshold();
  const timePeriod = ThresholdManager.getCurrentTimePeriod();
  
  if (!enabled) {
    return "警报: 关闭";
  } else {
    return `警报: 开启 | ${timePeriod}阈值: ${threshold} dB`;
  }
}
```

### 3. 自动保存状态显示
```typescript
private getAutoSaveStatus(): string {
  const enabled = this.pk.auto_save_enabled;
  const interval = this.pk.auto_save_interval;
  
  if (!enabled) {
    return "自动保存: 关闭";
  } else {
    return `自动保存: 开启 | 间隔: ${interval}分钟`;
  }
}
```

## 具体修改内容

### 修改 `buildListItem` 方法调用

**声级校准设置项**：
```typescript
this.buildListItem({
  icon: $r('app.media.ic_audio_analysis'),
  title: '声级校准',
  desc: this.getCalibrationStatus(),
  action: () => {
    this.navigateToAudioAnalysis();
  }
})
```

**警报与通知设置项**：
```typescript
this.buildListItem({
  icon: $r('app.media.ic_alarm'),
  title: '警报与通知',
  desc: this.getAlertsStatus(),
  action: () => {
    this.navigateToAlerts();
  }
})
```

**自动保存设置项**：
```typescript
this.buildListItem({
  icon: $r('app.media.ic_save'),
  title: '自动保存',
  desc: this.getAutoSaveStatus(),
  action: () => {
    this.openAutoSaveDialog();
  }
})
```

## 数据源依赖

### 1. 声级校准
- `pk.calibration_value` - 来自 [`PreferenceKeys.ets`](entry/src/main/ets/models/PreferenceKeys.ets:42)

### 2. 警报与通知
- `pk.system_notification_enabled` - 来自 [`PreferenceKeys.ets`](entry/src/main/ets/models/PreferenceKeys.ets:90)
- `ThresholdManager.getCurrentEffectiveThreshold()` - 来自 [`ThresholdManager.ets`](entry/src/main/ets/services/ThresholdManager.ets:124)
- `ThresholdManager.getCurrentTimePeriod()` - 来自 [`ThresholdManager.ets`](entry/src/main/ets/services/ThresholdManager.ets:137)

### 3. 自动保存
- `pk.auto_save_enabled` - 来自 [`PreferenceKeys.ets`](entry/src/main/ets/models/PreferenceKeys.ets:108)
- `pk.auto_save_interval` - 来自 [`PreferenceKeys.ets`](entry/src/main/ets/models/PreferenceKeys.ets:114)

## 预期效果

改进后，用户在主设置页面就能一目了然地看到：
- 当前的声级校准值
- 警报是否开启及当前阈值
- 自动保存是否开启及保存间隔

这将大大提升用户体验，减少用户需要进入子页面才能查看当前设置的麻烦。