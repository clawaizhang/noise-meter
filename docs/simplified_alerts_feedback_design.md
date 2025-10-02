# 简化版警报反馈实现方案

## 设计理念

基于现有PreferenceKeys系统，直接在DecibelMeter组件中实现警报反馈，避免过度工程化。

## 核心思路

### 1. 利用现有架构
- 直接使用PreferenceKeys存储警报设置
- 在DecibelMeter中实时检测阈值超限
- 利用现有NotificationHelper发送系统通知

### 2. 简化反馈实现
- **声音**: 使用系统提示音或简单音频播放
- **振动**: 直接调用系统振动API
- **视觉**: 在DecibelDisplayComponent中添加闪烁效果
- **系统通知**: 使用现有NotificationHelper

### 3. 重新设计DecibelMeter结构
- 简化组件层次
- 优化状态管理
- 提高响应性能

## 具体实现方案

### 1. 在DecibelMeter中集成警报检测

```typescript
// 在DecibelMeter类中添加警报检测逻辑
@Monitor('as.db')
onDecibelChange(monitor: IMonitor) {
  const currentDecibel = monitor.value<number>()?.now;
  if (currentDecibel !== undefined) {
    // 获取当前有效阈值
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();
    const isAlarmEnabled = this.pk.noise_alarm_enabled;
    
    // 检测警报触发
    if (isAlarmEnabled && currentDecibel >= threshold) {
      this.triggerAlarmFeedback(currentDecibel, threshold);
    } else {
      this.clearAlarmFeedback();
    }
  }
}

// 触发警报反馈
private triggerAlarmFeedback(currentDecibel: number, threshold: number): void {
  if (this.isAlarmActive) return;
  
  this.isAlarmActive = true;
  
  // 根据用户偏好执行相应反馈
  if (this.pk.sound_alert_enabled) {
    this.playAlarmSound();
  }
  
  if (this.pk.vibration_alert_enabled) {
    this.startVibration();
  }
  
  if (this.pk.visual_alert_enabled) {
    this.startVisualAlert();
  }
  
  if (this.pk.system_notification_enabled) {
    this.showAlarmNotification(currentDecibel, threshold);
  }
}

// 清除警报反馈
private clearAlarmFeedback(): void {
  if (!this.isAlarmActive) return;
  
  this.isAlarmActive = false;
  this.stopAlarmSound();
  this.stopVibration();
  this.stopVisualAlert();
}
```

### 2. 多模态反馈实现

#### 声音反馈
```typescript
private playAlarmSound(): void {
  // 使用系统提示音或简单音频
  promptAction.showToast({
    message: '噪音超过阈值',
    duration: 1000
  });
  
  // 或者使用AudioPlayerService播放简短警报音
  // this.audioPlayerService.playAlertSound();
}
```

#### 振动反馈
```typescript
private startVibration(): void {
  try {
    const vibrator = vibrator.createVibrator();
    const vibrationEffect: vibrator.VibrateEffect = {
      type: 'time',
      duration: 500
    };
    
    // 循环振动直到警报清除
    this.vibrationInterval = setInterval(() => {
      vibrator.vibrate(vibrationEffect);
    }, 2000);
  } catch (error) {
    console.error('振动功能不可用:', error);
  }
}

private stopVibration(): void {
  if (this.vibrationInterval) {
    clearInterval(this.vibrationInterval);
    this.vibrationInterval = undefined;
  }
}
```

#### 视觉反馈
```typescript
private startVisualAlert(): void {
  this.visualAlertState = VisualAlertState.ALERT;
}

private stopVisualAlert(): void {
  this.visualAlertState = VisualAlertState.NORMAL;
}
```

#### 系统通知
```typescript
private async showAlarmNotification(currentDecibel: number, threshold: number): Promise<void> {
  const notificationHelper = NotificationHelper.getInstance(getContext() as common.UIAbilityContext);
  await notificationHelper.showNotification(
    1001,
    '噪音警报',
    `当前噪音: ${currentDecibel}dB (阈值: ${threshold}dB)`,
    '请关注环境噪音水平'
  );
}
```

### 3. 重新设计DecibelMeter组件结构

#### 当前问题分析
- 组件层次过深
- 状态管理复杂
- 响应性能有待优化

#### 优化方案
```typescript
@ComponentV2
export struct SimplifiedDecibelMeter {
  // 核心状态
  @Local private currentDecibel: number = 0;
  @Local private isAlarmActive: boolean = false;
  @Local private visualAlertState: VisualAlertState = VisualAlertState.NORMAL;
  
  // 服务实例
  private audioService: AudioService;
  private notificationHelper: NotificationHelper;
  
  // 配置
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  
  build() {
    Column() {
      // 顶部状态栏
      this.buildStatusHeader()
      
      // 主显示区域
      this.buildMainDisplay()
      
      // 控制面板
      this.buildControlPanel()
      
      // 频谱图
      this.buildSpectrumChart()
    }
  }
  
  @Builder
  private buildMainDisplay() {
    Column() {
      // 分贝数值显示（带警报效果）
      Text(this.currentDecibel.toString())
        .fontSize(100)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getDisplayColor())
        .backgroundColor(this.isAlarmActive ? 
          $r('sys.color.alert') : 
          Color.Transparent)
        .animation({
          duration: 500,
          iterations: this.isAlarmActive ? -1 : 1,
          curve: Curve.EaseInOut
        })
      
      // 警报状态指示
      if (this.isAlarmActive) {
        Text('⚠️ 噪音超过阈值')
          .fontSize(16)
          .fontColor($r('sys.color.alert'))
          .margin({ top: 8 })
      }
    }
  }
  
  private getDisplayColor(): Resource {
    if (this.isAlarmActive) {
      return $r('sys.color.alert');
    }
    return DecibelService.getDecibelColor(this.currentDecibel);
  }
}
```

### 4. 视觉反馈增强

在DecibelDisplayComponent中添加警报视觉效果：

```typescript
@Builder
CurrentDecibel() {
  Stack({ alignContent: Alignment.Bottom }) {
    Column() {
      Text(this.currentDecibel.toString())
        .fontSize(100)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getAlertAwareColor())
        // 警报闪烁效果
        .backgroundColor(this.isNoiseAlarm ? 
          $r('sys.color.alert') : 
          Color.Transparent)
        .opacity(this.isNoiseAlarm ? 
          this.getBlinkOpacity() : 1)
        .animation({
          duration: 500,
          iterations: this.isNoiseAlarm ? -1 : 1,
          curve: Curve.EaseInOut
        })
    }
  }
}

private getAlertAwareColor(): Resource {
  return this.isNoiseAlarm ? 
    $r('sys.color.alert') : 
    DecibelService.getDecibelColor(this.currentDecibel);
}

private getBlinkOpacity(): number {
  // 实现闪烁效果：0.3 ~ 1.0 之间循环
  const time = Date.now() % 1000;
  return 0.3 + (Math.sin(time * Math.PI / 500) + 1) * 0.35;
}
```

### 5. 集成到现有系统

#### 修改AlertsStatusIndicator
```typescript
// 增强状态指示器，显示实时警报状态
@Builder
export struct EnhancedAlertsStatusIndicator {
  @Param @Require currentDecibel: number = 0;
  @Param @Require alertThreshold: number = 70;
  @Param @Require isAlertEnabled: boolean = true;
  @Param @Require isAlarmActive: boolean = false; // 新增参数
  
  build() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 外环 - 带警报状态
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: 100, height: 100 })
          .stroke(this.isAlarmActive ? 
            $r('sys.color.alert') : 
            this.getEnvironmentColor())
          .strokeWidth(8)
          .fill(Color.Transparent)
          .animation({
            duration: 300,
            curve: curves.springMotion()
          })
        
        // 其他现有代码...
      }
      
      // 状态描述
      Text(this.isAlarmActive ? 
        '警报触发中' : 
        this.getAlertStatusDescription())
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor(this.isAlarmActive ? 
          $r('sys.color.alert') : 
          this.getAlertStatusColor())
    }
  }
}
```

## 实施优势

### 1. 架构简洁
- 直接利用现有PreferenceKeys系统
- 避免创建复杂的新服务
- 代码维护成本低

### 2. 性能优化
- 实时检测，响应迅速
- 资源占用少
- 电池消耗低

### 3. 用户体验
- 反馈及时准确
- 可自定义通知方式
- 视觉反馈清晰

### 4. 扩展性
- 易于添加新的反馈类型
- 支持未来功能扩展
- 兼容现有系统

## 实施步骤

1. **第一阶段**: 在DecibelMeter中添加基础警报检测
2. **第二阶段**: 实现多模态反馈功能
3. **第三阶段**: 优化视觉反馈效果
4. **第四阶段**: 测试和性能优化

这个简化方案避免了过度工程化，直接利用现有系统，实现成本低且效果明显。