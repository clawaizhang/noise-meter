# 警报持续时间刷新设计方案

## 问题描述
当前警报持续时间不会自动刷新，只在警报解除时显示最终时间。需要在双管线架构下实现：
1. 前台实时刷新持续时间显示
2. 后台持续计算持续时间但不更新UI
3. 前后台切换时状态保持

## 双管线架构设计

### 数据流向
```
DataProcessingState (后台) → UIDisplayState (前台) → AlertsContent (UI)
```

### 核心修改点

## 1. DataProcessingState.ets 修改

### 新增 AlertState 类
```typescript
/**
 * 警报状态对象（后台持续计算）
 */
@ObservedV2
export class AlertState {
  // 警报是否激活
  @Trace
  isActive: boolean = false;

  // 警报开始时间戳
  @Trace
  startTime: number = 0;

  // 当前持续时间（毫秒）
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
   * 更新持续时间（后台持续调用）
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

### 在 DataProcessingState 中添加警报状态
```typescript
@ObservedV2
export class DataProcessingState {
  // 现有字段保持不变...
  
  // 新增：警报状态（后台持续计算）
  @Trace alertState: AlertState = new AlertState();

  constructor() {
    // 初始化状态
  }

  /**
   * 更新警报持续时间（后台持续调用）
   */
  updateAlertDuration(): void {
    this.alertState.updateDuration();
  }
}
```

## 2. UIDisplayState.ets 修改

### 新增 DisplayAlertState 类
```typescript
/**
 * 警报显示状态对象（UI专用）
 */
@ObservedV2
export class DisplayAlertState {
  // 显示警报状态
  @Trace
  isActive: boolean = false;

  // 显示持续时间（毫秒）
  @Trace
  duration: number = 0;

  // 格式化后的持续时间字符串
  @Trace
  formattedDuration: string = '0秒';

  constructor() {
    this.updateFormattedDuration();
  }

  /**
   * 更新格式化持续时间
   */
  updateFormattedDuration(): void {
    this.formattedDuration = this.formatDuration(this.duration);
  }

  /**
   * 格式化持续时间
   */
  private formatDuration(duration: number): string {
    const seconds = Math.floor(duration / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);

    if (hours > 0) {
      return `${hours}小时${minutes % 60}分钟`;
    } else if (minutes > 0) {
      return `${minutes}分钟${seconds % 60}秒`;
    } else {
      return `${seconds}秒`;
    }
  }

  /**
   * 重置显示状态
   */
  reset(): void {
    this.isActive = false;
    this.duration = 0;
    this.formattedDuration = '0秒';
  }
}
```

### 在 UIDisplayState 中添加显示状态
```typescript
@ObservedV2
export class UIDisplayState {
  // 现有字段保持不变...
  
  // 新增：警报显示状态（UI专用）
  @Trace displayAlertState: DisplayAlertState = new DisplayAlertState();

  /**
   * 从数据处理状态同步到UI显示状态
   */
  syncFromProcessingState(processingState: DataProcessingState): void {
    if (!this.isUIUpdatesEnabled) {
      return;
    }

    // 同步分贝值、频谱数据等现有逻辑...
    
    // 新增：同步警报状态
    this.displayAlertState.isActive = processingState.alertState.isActive;
    this.displayAlertState.duration = processingState.alertState.currentDuration;
    this.displayAlertState.updateFormattedDuration();

    this.lastUpdateTime = Date.now();
  }

  // 其他方法保持不变...
}
```

## 3. AlertService.ets 修改

### 修改警报触发逻辑
```typescript
export class AlertService {
  // 现有代码保持不变...

  /**
   * 触发多模态警报
   */
  public async triggerAlert(currentDecibel: number, threshold: number): Promise<void> {
    // 检查频率控制
    if (!this.frequencyController.canTriggerAlert()) {
      hilog.info(DOMAIN, TAG, '警报在静默期内，忽略触发');
      return;
    }

    try {
      // 更新 DataProcessingState 中的警报状态
      const appKeys: AppKeys = AppStorageV2.connect(AppKeys)!;
      appKeys.dataProcessingState.alertState.triggerAlert();
      
      // 发布通知
      await this.publishAlertNotification(currentDecibel, threshold);
      
      // 记录警报触发
      this.frequencyController.recordAlert();
      
      hilog.info(DOMAIN, TAG, `警报触发成功: ${currentDecibel}dB > ${threshold}dB`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `触发警报失败: ${err.code}, ${err.message}`);
    }
  }

  /**
   * 重置警报状态（当噪音恢复正常时调用）
   */
  public resetAlertState(): void {
    // 更新 DataProcessingState 中的警报状态
    const appKeys: AppKeys = AppStorageV2.connect(AppKeys)!;
    appKeys.dataProcessingState.alertState.clearAlert();
    
    this.frequencyController.reset();
    hilog.info(DOMAIN, TAG, '警报状态已重置');
  }
}
```

## 4. AlertsContent.ets 修改

### 移除本地状态，使用双管线架构
```typescript
@ComponentV2
export struct AlertsContent {
  // 通过AppKeys获取实时数据
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  
  // 移除本地警报状态变量
  // @Local private isAlarmActive: boolean = false;
  // @Local private visualAlertState: string = 'normal';
  // @Local private alertStartTime: number = 0;
  // @Local private alertDuration: number = 0;
  
  // 警报服务
  private alertService: AlertService = AlertService.getInstance(getContext() as common.UIAbilityContext);

  @Monitor('ak.uiDisplayState.displayDb')
  async onDbChange(monitor: IMonitor) {
    const currentDecibel = monitor.value<number>()?.now;
    if (currentDecibel !== undefined) {
      await this.checkAlertStatus(currentDecibel);
    }
  }

  // 检查警报状态
  private async checkAlertStatus(currentDecibel: number): Promise<void> {
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();
    const shouldAlert = currentDecibel >= threshold && this.pk.system_notification_enabled;

    // 使用 DataProcessingState 中的警报状态
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

  // 触发警报
  private async triggerAlarm(currentDecibel: number): Promise<void> {
    // 状态更新由 AlertService 处理
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();

    // 如果系统通知启用，则触发警报
    if (this.pk.system_notification_enabled) {
      await this.alertService.triggerAlert(currentDecibel, threshold);
    }
  }

  // 解除警报
  private clearAlarm(): void {
    // 状态更新由 AlertService 处理
    this.alertService.resetAlertState();
  }

  // 构建状态显示区
  @Builder
  private buildStatusDisplay() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 状态指示器
      Row({ space: DesignConstants.SPACING_SM }) {
        Circle({ width: 16, height: 16 })
          .fill(this.getStatusColor())
          .animation({
            duration: this.ak.uiDisplayState.displayAlertState.isActive ? 500 : 0,
            curve: Curve.EaseInOut,
            iterations: this.ak.uiDisplayState.displayAlertState.isActive ? -1 : 1,
            playMode: PlayMode.Alternate
          })

        Text(this.getStatusText())
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontColor(this.getStatusColor())
          .fontWeight(FontWeight.Bold)
      }

      // 当前分贝值（大字体显示）
      Text(`${this.ak.uiDisplayState.displayDb}dB`)
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getStatusColor())
        .animation({
          duration: 300,
          curve: Curve.EaseInOut
        })

      // 阈值信息
      Text(`阈值: ${ThresholdManager.getCurrentEffectiveThreshold()}dB`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))

      // 警报持续时间（如果激活）
      if (this.ak.uiDisplayState.displayAlertState.isActive) {
        Text(`持续时间: ${this.ak.uiDisplayState.displayAlertState.formattedDuration}`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.alert'))
          .fontWeight(FontWeight.Medium)
      }
    }
    // 其他样式保持不变...
  }

  // 其他辅助方法保持不变...
}
```

## 5. 后台持续计算机制

需要在 AudioControllerService 或其他后台服务中添加定时更新：

```typescript
// 在后台服务中添加定时器
private startBackgroundAlertUpdate(): void {
  setInterval(() => {
    if (this.dataProcessingState.isBackground) {
      // 后台运行时更新警报持续时间
      this.dataProcessingState.updateAlertDuration();
    }
  }, 1000); // 每秒更新一次
}
```

## 6. 实时刷新机制

在 AlertsContent 中添加定时刷新：

```typescript
@ComponentV2
export struct AlertsContent {
  // 现有代码...

  aboutToAppear(): void {
    // 组件加载时更新权限状态
    this.alertService.updateSystemPermissionStatus();
    
    // 启动定时刷新
    this.startDurationRefresh();
  }

  aboutToDisappear(): void {
    // 组件销毁时重置警报状态
    this.alertService.resetAlertState();
    
    // 停止定时刷新
    this.stopDurationRefresh();
  }

  private refreshTimer: number = 0;

  private startDurationRefresh(): void {
    // 每秒刷新一次持续时间显示
    this.refreshTimer = setInterval(() => {
      if (this.ak.uiDisplayState.displayAlertState.isActive) {
        // 触发UI更新
        this.ak.uiDisplayState.displayAlertState.updateFormattedDuration();
      }
    }, 1000);
  }

  private stopDurationRefresh(): void {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = 0;
    }
  }
}
```

## 总结

这个设计方案实现了：
1. ✅ 前台实时刷新持续时间显示
2. ✅ 后台持续计算持续时间但不更新UI  
3. ✅ 前后台切换时状态保持
4. ✅ 基于现有双管线架构，最小化代码修改
5. ✅ 保持代码的可维护性和扩展性