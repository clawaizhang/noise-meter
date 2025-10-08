# 警报持续时间刷新 - 最终设计方案

## 架构设计原则

### 1. 关注点分离
- **DataProcessingState**：负责数据计算和自动更新
- **UIDisplayState**：负责UI状态同步
- **AlertsContent**：只负责显示，不包含业务逻辑

### 2. 数据流向
```
DataProcessingState (自动更新) → UIDisplayState (同步) → AlertsContent (显示)
```

## 具体实现方案

### 1. DataProcessingState 中的自动更新

在 DataProcessingState 中添加定时器管理：

```typescript
@ObservedV2
export class DataProcessingState {
  // 现有字段...
  
  // 警报状态
  @Trace alertState: AlertState = new AlertState();
  
  // 警报持续时间更新定时器
  private alertDurationTimer: number = 0;

  constructor() {
    // 初始化状态
    this.startAlertDurationUpdate();
  }

  /**
   * 启动警报持续时间自动更新
   */
  private startAlertDurationUpdate(): void {
    // 每秒更新一次警报持续时间
    this.alertDurationTimer = setInterval(() => {
      if (this.alertState.isActive) {
        this.alertState.updateDuration();
      }
    }, 1000);
  }

  /**
   * 停止警报持续时间更新（如果需要）
   */
  private stopAlertDurationUpdate(): void {
    if (this.alertDurationTimer) {
      clearInterval(this.alertDurationTimer);
      this.alertDurationTimer = 0;
    }
  }

  /**
   * 更新警报持续时间（供外部调用）
   */
  updateAlertDuration(): void {
    this.alertState.updateDuration();
  }
}
```

### 2. AlertState 的响应式设计

```typescript
@ObservedV2
export class AlertState {
  // 警报是否激活
  @Trace
  isActive: boolean = false;

  // 警报开始时间戳
  @Trace
  startTime: number = 0;

  // 当前持续时间（毫秒）- 这个字段变化会自动触发UI更新
  @Trace
  currentDuration: number = 0;

  // 最后更新时间
  @Trace
  lastUpdateTime: number = 0;

  constructor() {
    this.lastUpdateTime = Date.now();
  }

  /**
   * 触发警报
   */
  triggerAlert(): void {
    this.isActive = true;
    this.startTime = Date.now();
    this.currentDuration = 0;
    this.lastUpdateTime = Date.now();
  }

  /**
   * 解除警报
   */
  clearAlert(): void {
    this.isActive = false;
    this.currentDuration = Date.now() - this.startTime;
    this.lastUpdateTime = Date.now();
  }

  /**
   * 更新持续时间
   */
  updateDuration(): void {
    if (this.isActive) {
      this.currentDuration = Date.now() - this.startTime;
      this.lastUpdateTime = Date.now();
    }
  }

  /**
   * 重置警报状态
   */
  reset(): void {
    this.isActive = false;
    this.startTime = 0;
    this.currentDuration = 0;
    this.lastUpdateTime = Date.now();
  }
}
```

### 3. 移除 AlertsContent 中的业务逻辑

需要从 AlertsContent 中移除：
- `refreshTimer` 字段
- `startDurationRefresh()` 方法
- `stopDurationRefresh()` 方法
- 定时器相关的生命周期调用

### 4. 保持其他组件的修改

其他组件的修改保持不变：
- **UIDisplayState**：同步警报显示状态
- **AlertService**：更新 DataProcessingState 中的警报状态
- **AudioController**：可以移除 updateAlertDuration 调用（因为 DataProcessingState 自动更新）

## 优势

1. **架构清晰**：数据层完全负责数据更新
2. **性能优化**：只有一个定时器，避免重复更新
3. **维护简单**：业务逻辑集中在 DataProcessingState
4. **扩展性好**：易于添加其他自动更新功能
5. **符合双管线架构**：DataProcessingState 持续运行，UIDisplayState 控制UI同步

## 实现步骤

1. 在 DataProcessingState 中添加自动更新定时器
2. 从 AlertsContent 中移除定时器逻辑
3. 验证响应式更新是否正常工作
4. 测试前后台切换功能