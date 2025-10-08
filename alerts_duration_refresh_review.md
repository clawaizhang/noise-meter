# 警报持续时间刷新方案审查与调整

## 当前实现的问题

### 1. 架构问题
- **业务逻辑泄露**：在 AlertsContent 组件中添加定时刷新，违反了组件只负责显示的原则
- **关注点混淆**：UI组件不应该包含定时器逻辑

### 2. 设计原则违反
- **单一职责原则**：AlertsContent 应该只负责显示，不应该管理定时刷新
- **依赖倒置原则**：UI组件不应该直接控制数据更新频率

## 正确的架构设计

### 数据流向应该为：
```
DataProcessingState (持续计算) → UIDisplayState (自动同步) → AlertsContent (纯显示)
```

### 调整方案

## 方案一：在 DataProcessingState 中实现自动更新

**优点：**
- 数据层负责数据更新逻辑
- UI层保持纯净
- 符合双管线架构设计

**实现：**
```typescript
// 在 DataProcessingState 中添加定时器
private alertDurationTimer: number = 0;

// 启动警报持续时间自动更新
startAlertDurationUpdate(): void {
  this.alertDurationTimer = setInterval(() => {
    if (this.alertState.isActive) {
      this.alertState.updateDuration();
    }
  }, 1000);
}

// 停止警报持续时间更新
stopAlertDurationUpdate(): void {
  if (this.alertDurationTimer) {
    clearInterval(this.alertDurationTimer);
    this.alertDurationTimer = 0;
  }
}
```

## 方案二：在 AudioController 中统一更新

**优点：**
- 利用现有的音频处理循环
- 不需要额外的定时器
- 性能更好

**实现：**
```typescript
// 在 AudioController.updateStatistics 中
private updateStatistics(currentDb: number, spectrumData: Float32Array): void {
  // 现有逻辑...
  
  // 更新警报持续时间
  if (this.ak.dataProcessingState.alertState.isActive) {
    this.ak.dataProcessingState.alertState.updateDuration();
  }
  
  // 同步到UI
  this.ak.uiDisplayState.syncFromProcessingState(this.ak.dataProcessingState);
}
```

## 方案三：使用响应式更新机制

**优点：**
- 最符合 ArkUI 的设计理念
- 自动触发UI更新
- 性能最优

**实现：**
```typescript
// 在 AlertState 中使用 @Trace 自动触发更新
@ObservedV2
export class AlertState {
  @Trace
  isActive: boolean = false;
  
  @Trace
  startTime: number = 0;
  
  @Trace
  currentDuration: number = 0; // 这个字段变化会自动触发UI更新
  
  updateDuration(): void {
    if (this.isActive) {
      this.currentDuration = Date.now() - this.startTime;
    }
  }
}
```

## 推荐方案

**选择方案二 + 方案三的组合：**

1. **在 AudioController 中更新**：利用现有的音频处理循环，避免额外定时器
2. **使用响应式更新**：通过 @Trace 自动触发UI刷新，不需要手动定时器
3. **AlertsContent 保持纯净**：只负责显示，不包含任何业务逻辑

这样既保证了性能，又符合架构设计原则。