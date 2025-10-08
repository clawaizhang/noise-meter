# 完整警报系统重构方案

## 发现的问题

### 1. AlertFrequencyController 职责混淆 ✅ 已修复
- 已重构为纯通知频率控制器
- 重命名方法：`canTriggerAlert()` → `canSendNotification()`
- 重命名方法：`recordAlert()` → `recordNotificationSent()`

### 2. AlertService.triggerAlert() 逻辑错误 ✅ 已修复
- 已确保警报状态总是更新（无频率限制）
- 只在频率允许时发送通知

### 3. AlertsContent.checkAlertStatus() 职责混淆 ❌ 需要修复
**当前错误逻辑**：
```typescript
const shouldAlert = currentDecibel >= threshold && this.pk.system_notification_enabled;
```

**问题**：将警报触发检测与通知发送决策耦合在一起

## 正确的职责分离

### 警报触发检测
- **条件**：`currentDecibel >= threshold`
- **目的**：检测噪音是否超标
- **频率**：无限制，实时检测

### 通知发送决策
- **条件**：`system_notification_enabled && frequencyController.canSendNotification()`
- **目的**：决定是否发送系统通知
- **频率**：有智能频率控制

## 需要修复的代码

### AlertsContent.checkAlertStatus()
**当前**：
```typescript
private async checkAlertStatus(currentDecibel: number): Promise<void> {
  const threshold = ThresholdManager.getCurrentEffectiveThreshold();
  const shouldAlert = currentDecibel >= threshold && this.pk.system_notification_enabled;

  const isAlarmActive = this.ak.dataProcessingState.alertState.isActive;

  if (shouldAlert && !isAlarmActive) {
    // 触发警报
    await this.triggerAlarm(currentDecibel);
  } else if (!shouldAlert && isAlarmActive) {
    // 解除警报
    this.clearAlarm();
  } else if (!shouldAlert) {
    // 噪音恢复正常，重置警报状态
    this.alertService.resetAlertState();
  }
}
```

**修复后**：
```typescript
private async checkAlertStatus(currentDecibel: number): Promise<void> {
  const threshold = ThresholdManager.getCurrentEffectiveThreshold();
  const shouldAlert = currentDecibel >= threshold; // 只基于分贝值与阈值比较

  const isAlarmActive = this.ak.dataProcessingState.alertState.isActive;

  if (shouldAlert && !isAlarmActive) {
    // 触发警报（总是触发，不受通知设置影响）
    await this.triggerAlarm(currentDecibel);
  } else if (!shouldAlert && isAlarmActive) {
    // 解除警报
    this.clearAlarm();
  } else if (!shouldAlert) {
    // 噪音恢复正常，重置警报状态
    this.alertService.resetAlertState();
  }
}
```

### AlertService.triggerAlert() 需要进一步优化
**当前**：
```typescript
public async triggerAlert(currentDecibel: number, threshold: number): Promise<void> {
  try {
    // 1. 总是更新 DataProcessingState 中的警报状态（没有频率限制）
    const appKeys: AppKeys = AppStorageV2.connect(AppKeys)!;
    appKeys.dataProcessingState.alertState.triggerAlert();
    
    // 2. 检查是否可以发送通知（有频率限制）
    if (this.frequencyController.canSendNotification()) {
      // 发布通知
      await this.publishAlertNotification(currentDecibel, threshold);
      
      // 记录通知发送
      this.frequencyController.recordNotificationSent();
      
      hilog.info(DOMAIN, TAG, `警报触发成功并发送通知: ${currentDecibel}dB > ${threshold}dB`);
    } else {
      hilog.info(DOMAIN, TAG, `警报触发但通知在静默期内: ${currentDecibel}dB > ${threshold}dB`);
    }
  } catch (error) {
    // 错误处理
  }
}
```

**需要添加通知启用检查**：
```typescript
public async triggerAlert(currentDecibel: number, threshold: number): Promise<void> {
  try {
    // 1. 总是更新 DataProcessingState 中的警报状态（没有频率限制）
    const appKeys: AppKeys = AppStorageV2.connect(AppKeys)!;
    appKeys.dataProcessingState.alertState.triggerAlert();
    
    // 2. 检查是否启用通知
    const pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
    if (!pk.system_notification_enabled) {
      hilog.info(DOMAIN, TAG, `警报触发但通知已关闭: ${currentDecibel}dB > ${threshold}dB`);
      return;
    }
    
    // 3. 检查是否可以发送通知（有频率限制）
    if (this.frequencyController.canSendNotification()) {
      // 发布通知
      await this.publishAlertNotification(currentDecibel, threshold);
      
      // 记录通知发送
      this.frequencyController.recordNotificationSent();
      
      hilog.info(DOMAIN, TAG, `警报触发成功并发送通知: ${currentDecibel}dB > ${threshold}dB`);
    } else {
      hilog.info(DOMAIN, TAG, `警报触发但通知在静默期内: ${currentDecibel}dB > ${threshold}dB`);
    }
  } catch (error) {
    // 错误处理
  }
}
```

## 总结

通过这次完整重构，我们实现了：

1. **警报触发检测**：实时、无频率限制，只基于分贝值与阈值比较
2. **通知发送决策**：基于用户设置和智能频率控制
3. **职责清晰**：每个组件有明确的单一职责

这样既能保证用户及时知道噪音超标情况，又能避免通知过于频繁打扰用户。