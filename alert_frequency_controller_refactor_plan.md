# AlertFrequencyController 重构计划

## 当前问题分析

### 职责混淆
当前的 `AlertFrequencyController` 存在职责混淆问题：
- 既负责通知发送频率控制
- 又参与了警报触发决策逻辑

### 耦合点识别
1. **在 `AlertService.triggerAlert()` 中**：
   ```typescript
   // 检查频率控制
   if (!this.frequencyController.canTriggerAlert()) {
     hilog.info(DOMAIN, TAG, '警报在静默期内，忽略触发');
     return;
   }
   ```

2. **在 `AlertsContent.checkAlertStatus()` 中**：
   ```typescript
   if (shouldAlert && !isAlarmActive) {
     // 触发警报
     await this.triggerAlarm(currentDecibel);
   }
   ```

## 重构目标

### 职责分离
- **AlertFrequencyController**: 纯频率控制器，只负责通知发送频率管理
- **AlertTriggerService**: 独立的警报触发检测服务
- **AlertService**: 警报执行服务

## 详细重构方案

### 1. 重构 AlertFrequencyController

**当前接口**：
```typescript
class AlertFrequencyController {
  canTriggerAlert(): boolean
  recordAlert(): void
  reset(): void
  getStatus(): AlertCount
}
```

**重构后接口**：
```typescript
class AlertFrequencyController {
  canSendNotification(): boolean
  recordNotificationSent(): void
  reset(): void
  getStatus(): NotificationFrequencyStatus
}
```

**具体更改**：
- 重命名 `canTriggerAlert()` → `canSendNotification()`
- 重命名 `recordAlert()` → `recordNotificationSent()`
- 更新 `getStatus()` 返回类型为 `NotificationFrequencyStatus`

### 2. 创建 AlertTriggerService

**新服务接口**：
```typescript
class AlertTriggerService {
  shouldTriggerAlert(currentDecibel: number, threshold: number): boolean
  isAlertActive(): boolean
  getAlertStatus(): AlertStatus
}
```

**实现逻辑**：
- 包含所有警报触发检测逻辑
- 与频率控制完全解耦
- 返回布尔值表示是否应该触发警报

### 3. 重构 AlertService

**主要更改**：
```typescript
// 在 triggerAlert 方法中
public async triggerAlert(currentDecibel: number, threshold: number): Promise<void> {
  // 1. 检查频率控制（使用新的频率控制器）
  if (!this.frequencyController.canSendNotification()) {
    hilog.info(DOMAIN, TAG, '通知在静默期内，忽略发送');
    return;
  }

  // 2. 执行警报逻辑
  try {
    // 更新 DataProcessingState 中的警报状态
    const appKeys: AppKeys = AppStorageV2.connect(AppKeys)!;
    appKeys.dataProcessingState.alertState.triggerAlert();
    
    // 发布通知
    await this.publishAlertNotification(currentDecibel, threshold);
    
    // 记录通知发送（使用新的频率控制器）
    this.frequencyController.recordNotificationSent();
    
    hilog.info(DOMAIN, TAG, `警报触发成功: ${currentDecibel}dB > ${threshold}dB`);
  } catch (error) {
    // 错误处理
  }
}
```

### 4. 重构 AlertsContent

**主要更改**：
```typescript
// 使用新的 AlertTriggerService
private async checkAlertStatus(currentDecibel: number): Promise<void> {
  const threshold = ThresholdManager.getCurrentEffectiveThreshold();
  const shouldAlert = this.alertTriggerService.shouldTriggerAlert(currentDecibel, threshold);
  const isAlarmActive = this.alertTriggerService.isAlertActive();

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

## 文件更改清单

### 需要修改的文件：
1. `entry/src/main/ets/services/AlertService.ets`
   - 重构 AlertFrequencyController 类
   - 更新 AlertService 中的调用

2. `entry/src/main/ets/services/AlertTriggerService.ets` (新文件)
   - 创建独立的警报触发检测服务

3. `entry/src/main/ets/components/alerts/AlertsContent.ets`
   - 更新警报检测逻辑调用

4. `entry/src/main/ets/constants/AlertsConstants.ets`
   - 添加新的类型定义

## 实施步骤

1. **创建 AlertTriggerService** - 实现独立的警报触发检测
2. **重构 AlertFrequencyController** - 改为纯频率控制器
3. **更新 AlertService** - 适配新的接口
4. **更新 AlertsContent** - 使用新的服务
5. **测试验证** - 确保功能完整性

## 预期收益

1. **职责清晰**：每个类有明确的单一职责
2. **可测试性**：可以独立测试频率控制和警报触发逻辑
3. **可维护性**：修改频率策略不会影响警报触发逻辑
4. **扩展性**：更容易添加新的警报类型或频率策略