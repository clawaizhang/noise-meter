# 噪音警报反馈呈现实现方案

## 概述

本文档详细说明如何在噪音计应用中实现多模态警报反馈呈现功能，包括声音、振动、视觉和系统通知。

## 当前系统分析

### 现有组件
- **AlertsSettingsNavigation.ets** - 警报设置主页面
- **EnhancedThresholdManager.ets** - 阈值管理组件  
- **AlertsStatusIndicator.ets** - 警报状态指示器
- **NotificationPreferences.ets** - 通知偏好设置
- **DecibelMeter.ets** - 主分贝计组件
- **DecibelDisplayComponent.ets** - 分贝显示组件
- **ThresholdManager.ets** - 阈值管理服务
- **NotificationHelper.ets** - 系统通知助手

### 架构缺陷
- 警报设置已完善但缺少实际触发机制
- 需要在DecibelMeter中集成实时警报检测
- 缺少多模态反馈执行器

## 技术实现方案

### 1. 新增服务组件

#### AlertsManager.ets
```typescript
/**
 * 警报管理器服务
 * 统一管理警报状态和触发逻辑
 */
export class AlertsManager {
  private static instance: AlertsManager;
  private context: common.UIAbilityContext;
  private currentAlertState: AlertState = AlertState.IDLE;
  private alertHistory: AlertRecord[] = [];
  private feedbackController: AlertFeedbackController;
  
  // 警报状态变化事件
  private alertStateSubject = new Subject<AlertState>();
  
  public static getInstance(context: common.UIAbilityContext): AlertsManager {
    if (!AlertsManager.instance) {
      AlertsManager.instance = new AlertsManager(context);
    }
    return AlertsManager.instance;
  }
  
  // 检测警报触发
  public checkAlert(currentDecibel: number, threshold: number, isEnabled: boolean): void {
    if (!isEnabled) {
      this.clearAlert();
      return;
    }
    
    if (currentDecibel >= threshold) {
      this.triggerAlert(currentDecibel, threshold);
    } else {
      this.clearAlert();
    }
  }
  
  // 触发警报
  private triggerAlert(currentDecibel: number, threshold: number): void {
    if (this.currentAlertState === AlertState.ALERT) return;
    
    this.currentAlertState = AlertState.ALERT;
    this.alertStateSubject.next(this.currentAlertState);
    
    // 记录警报历史
    const alertRecord: AlertRecord = {
      timestamp: Date.now(),
      decibel: currentDecibel,
      threshold: threshold,
      duration: 0
    };
    this.alertHistory.push(alertRecord);
    
    // 执行反馈
    this.feedbackController.executeFeedback();
  }
  
  // 清除警报
  private clearAlert(): void {
    if (this.currentAlertState === AlertState.IDLE) return;
    
    this.currentAlertState = AlertState.IDLE;
    this.alertStateSubject.next(this.currentAlertState);
    
    // 更新最后一条警报记录的持续时间
    if (this.alertHistory.length > 0) {
      const lastAlert = this.alertHistory[this.alertHistory.length - 1];
      lastAlert.duration = Date.now() - lastAlert.timestamp;
    }
    
    // 停止反馈
    this.feedbackController.stopFeedback();
  }
}
```

#### AlertFeedbackController.ets
```typescript
/**
 * 警报反馈控制器
 * 根据用户偏好执行多模态反馈
 */
export class AlertFeedbackController {
  private soundService: AlertSoundService;
  private vibrationService: AlertVibrationService;
  private visualService: AlertVisualService;
  private notificationService: NotificationHelper;
  
  constructor(context: common.UIAbilityContext) {
    this.soundService = new AlertSoundService(context);
    this.vibrationService = new AlertVibrationService(context);
    this.visualService = new AlertVisualService(context);
    this.notificationService = NotificationHelper.getInstance(context);
  }
  
  // 执行反馈
  public async executeFeedback(): Promise<void> {
    const preferences = this.getNotificationPreferences();
    
    if (preferences.soundEnabled) {
      this.soundService.playAlertSound();
    }
    
    if (preferences.vibrationEnabled) {
      this.vibrationService.startVibration();
    }
    
    if (preferences.visualEnabled) {
      this.visualService.startVisualAlert();
    }
    
    if (preferences.systemNotificationEnabled) {
      await this.notificationService.showNotification(
        1001,
        '噪音警报',
        `当前噪音超过阈值`,
        '请关注环境噪音水平'
      );
    }
  }
  
  // 停止反馈
  public stopFeedback(): void {
    this.soundService.stopAlertSound();
    this.vibrationService.stopVibration();
    this.visualService.stopVisualAlert();
    this.notificationService.cancelNotification(1001);
  }
}
```

### 2. 反馈服务实现

#### AlertSoundService.ets
```typescript
/**
 * 警报声音服务
 * 播放警报提示音
 */
export class AlertSoundService {
  private audioPlayer: media.AudioPlayer;
  private isPlaying: boolean = false;
  
  constructor(context: common.UIAbilityContext) {
    // 初始化音频播放器
  }
  
  public playAlertSound(): void {
    if (this.isPlaying) return;
    
    this.isPlaying = true;
    // 播放警报音效
  }
  
  public stopAlertSound(): void {
    this.isPlaying = false;
    // 停止播放
  }
}
```

#### AlertVibrationService.ets
```typescript
/**
 * 警报振动服务
 * 控制设备振动反馈
 */
export class AlertVibrationService {
  private vibrator: vibrator.Vibrator;
  private isVibrating: boolean = false;
  
  constructor(context: common.UIAbilityContext) {
    this.vibrator = vibrator.createVibrator();
  }
  
  public startVibration(): void {
    if (this.isVibrating) return;
    
    this.isVibrating = true;
    const vibrationEffect: vibrator.VibrateEffect = {
      type: 'time',
      duration: 1000
    };
    
    // 循环振动模式
    setInterval(() => {
      this.vibrator.vibrate(vibrationEffect);
    }, 2000);
  }
  
  public stopVibration(): void {
    this.isVibrating = false;
    this.vibrator.stop();
  }
}
```

#### AlertVisualService.ets
```typescript
/**
 * 警报视觉服务
 * 控制视觉反馈效果
 */
export class AlertVisualService {
  private visualState: VisualAlertState = VisualAlertState.NORMAL;
  
  public startVisualAlert(): void {
    this.visualState = VisualAlertState.ALERT;
    // 触发视觉变化事件
  }
  
  public stopVisualAlert(): void {
    this.visualState = VisualAlertState.NORMAL;
    // 恢复正常视觉状态
  }
  
  public getVisualState(): VisualAlertState {
    return this.visualState;
  }
}
```

### 3. 集成到现有组件

#### 修改DecibelMeter.ets
```typescript
// 在DecibelMeter类中添加
@Local private alertsManager: AlertsManager;

aboutToAppear() {
  // 初始化警报管理器
  this.alertsManager = AlertsManager.getInstance(getContext() as common.UIAbilityContext);
  
  // 其他现有代码...
}

// 在分贝值更新时检测警报
@Monitor('as.db')
onDecibelChange(monitor: IMonitor) {
  const currentDecibel = monitor.value<number>()?.now;
  if (currentDecibel !== undefined) {
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();
    const isEnabled = this.pk.noise_alarm_enabled;
    
    this.alertsManager.checkAlert(currentDecibel, threshold, isEnabled);
  }
}
```

#### 增强DecibelDisplayComponent.ets
```typescript
// 添加视觉反馈效果
@Builder
CurrentDecibel() {
  Stack({ alignContent: Alignment.Bottom }) {
    Column() {
      if (this.currentDecibel === 0) {
        Text('-')
          .fontSize(100)
          .textShadow({
            radius: 2,
            color: Color.White,
            offsetX: 0,
            offsetY: 0
          })
          .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }))
          .fontWeight(FontWeight.Bold)
          .fontColor(DecibelService.getDecibelColor(this.currentDecibel));
      } else {
        Text(this.currentDecibel.toString())
          .fontSize(100)
          .textShadow({
            radius: 2,
            color: Color.White,
            offsetX: 0,
            offsetY: 0
          })
          .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }))
          .fontWeight(FontWeight.Bold)
          .fontColor(DecibelService.getDecibelColor(this.currentDecibel))
          // 添加警报闪烁效果
          .backgroundColor(this.isNoiseAlarm ? 
            $r('sys.color.alert') : 
            Color.Transparent)
          .animation({
            duration: 500,
            iterations: -1,
            curve: Curve.EaseInOut
          });
      }
    }
    // 其他现有代码...
  }
}
```

### 4. 数据模型定义

#### AlertModels.ets
```typescript
// 警报状态枚举
export enum AlertState {
  IDLE = 'idle',
  ALERT = 'alert'
}

// 视觉警报状态
export enum VisualAlertState {
  NORMAL = 'normal',
  ALERT = 'alert'
}

// 警报记录
export interface AlertRecord {
  timestamp: number;
  decibel: number;
  threshold: number;
  duration: number;
}

// 通知偏好
export interface NotificationPreferences {
  soundEnabled: boolean;
  vibrationEnabled: boolean;
  visualEnabled: boolean;
  systemNotificationEnabled: boolean;
}
```

## 实施步骤

### 第一阶段：核心服务实现
1. 创建AlertsManager服务
2. 实现AlertFeedbackController
3. 添加声音、振动、视觉反馈服务

### 第二阶段：组件集成
1. 修改DecibelMeter集成警报检测
2. 增强DecibelDisplayComponent视觉反馈
3. 更新AlertsStatusIndicator实时状态

### 第三阶段：功能完善
1. 添加警报历史记录
2. 实现警报统计功能
3. 优化用户体验和性能

## 技术要点

### 性能优化
- 使用防抖机制避免频繁触发
- 合理设置反馈间隔时间
- 及时清理资源防止内存泄漏

### 用户体验
- 提供清晰的视觉反馈
- 避免过度打扰用户
- 支持自定义反馈强度

### 兼容性
- 适配不同设备能力
- 处理权限请求
- 优雅降级策略

## 测试计划

### 单元测试
- 警报触发逻辑测试
- 反馈服务功能测试
- 组件集成测试

### 集成测试
- 多模态反馈协调测试
- 性能压力测试
- 用户体验测试

### 验收标准
- 警报准确触发和清除
- 多模态反馈按偏好执行
- 系统稳定无崩溃
- 用户体验流畅自然