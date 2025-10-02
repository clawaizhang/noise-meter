# 警报反馈集成实现指南

## 概述

本指南详细说明如何在现有噪音计应用中集成多模态警报反馈功能，包括具体的代码修改步骤和实现细节。

## 核心修改点

### 1. 修改DecibelMeter.ets

在现有的[`DecibelMeter.ets`](entry/src/main/ets/components/decibel-meter/DecibelMeter.ets:1)中添加警报检测和反馈逻辑。

#### 添加状态变量
```typescript
// 在DecibelMeter类中添加以下状态变量
@Local private isAlarmActive: boolean = false;
@Local private visualAlertState: VisualAlertState = VisualAlertState.NORMAL;
private vibrationInterval?: number;
```

#### 添加警报检测方法
```typescript
// 在DecibelMeter类中添加以下方法

// 分贝值变化监听
@Monitor('as.db')
onDecibelChange(monitor: IMonitor) {
  const currentDecibel = monitor.value<number>()?.now;
  if (currentDecibel !== undefined) {
    this.handleDecibelChange(currentDecibel);
  }
}

// 处理分贝值变化
private handleDecibelChange(currentDecibel: number): void {
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

// 触发警报反馈
private triggerAlarmFeedback(currentDecibel: number, threshold: number): void {
  if (this.isAlarmActive) return;
  
  this.isAlarmActive = true;
  console.info(`[Alerts] 警报触发: ${currentDecibel}dB >= ${threshold}dB`);
  
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
  console.info('[Alerts] 警报清除');
  
  this.stopAlarmSound();
  this.stopVibration();
  this.stopVisualAlert();
}
```

#### 实现多模态反馈方法
```typescript
// 声音反馈
private playAlarmSound(): void {
  // 使用系统提示音
  promptAction.showToast({
    message: '噪音超过阈值',
    duration: 1000
  });
  
  // 或者使用现有的AudioPlayerService
  // const audioPlayer = AudioPlayerService.getInstance(getContext() as common.UIAbilityContext);
  // audioPlayer.playAlertSound();
}

// 振动反馈
private startVibration(): void {
  try {
    // 检查振动器是否可用
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
    console.warn('振动功能不可用:', error);
  }
}

private stopVibration(): void {
  if (this.vibrationInterval) {
    clearInterval(this.vibrationInterval);
    this.vibrationInterval = undefined;
  }
}

// 视觉反馈
private startVisualAlert(): void {
  this.visualAlertState = VisualAlertState.ALERT;
}

private stopVisualAlert(): void {
  this.visualAlertState = VisualAlertState.NORMAL;
}

// 系统通知
private async showAlarmNotification(currentDecibel: number, threshold: number): Promise<void> {
  try {
    const notificationHelper = NotificationHelper.getInstance(getContext() as common.UIAbilityContext);
    await notificationHelper.showNotification(
      1001,
      '噪音警报',
      `当前噪音: ${currentDecibel}dB (阈值: ${threshold}dB)`,
      '请关注环境噪音水平'
    );
  } catch (error) {
    console.error('发送系统通知失败:', error);
  }
}
```

#### 清理资源
```typescript
aboutToDisappear() {
  // 清理现有资源...
  
  // 新增：清理警报相关资源
  this.clearAlarmFeedback();
  
  // 清理RxJS资源
  this.audioBufferSubject.complete();
  this.stopDurationMonitoring();
  
  this.audioService.stopProcessing();
  this.audioService.stopCapture();
}
```

### 2. 修改DecibelDisplayComponent.ets

在[`DecibelDisplayComponent.ets`](entry/src/main/ets/components/decibel-meter/DecibelDisplayComponent.ets:1)中添加视觉反馈效果。

#### 添加状态参数
```typescript
// 在组件参数中添加警报状态
@Param @Require isNoiseAlarm: boolean = false;
```

#### 修改CurrentDecibel构建器
```typescript
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
          .fontColor(this.getAlertAwareColor(0));
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
          .fontColor(this.getAlertAwareColor(this.currentDecibel))
          // 添加警报闪烁效果
          .backgroundColor(this.isNoiseAlarm ? 
            $r('sys.color.alert') : 
            Color.Transparent)
          .opacity(this.isNoiseAlarm ? 
            this.getBlinkOpacity() : 1)
          .animation({
            duration: 500,
            iterations: this.isNoiseAlarm ? -1 : 1,
            curve: Curve.EaseInOut
          });
      }
    }
    .backgroundColor('#00000000')
    .margin({ bottom: -20, right: -20 })
    .id('currentDbComp')
    .onClick(() => {
      DialogHub.getPopup()
        .setTextContent('当前分贝值')
        .setComponentTargetId('currentDbComp')
        .setStyle({
          radius: $r('sys.float.chip_small_radius'),
          maskColor: '#00000000',
        })
        .setConfig({
          dialogPosition: {
            preferPlacement: Placement.Top
          },
          dialogBehavior: { isModal: true, autoDismiss: true }
        })
        .build()
        .show();
    })
    .alignItems(HorizontalAlign.Center);
  }
}

// 获取带警报状态的颜色
private getAlertAwareColor(decibel: number): Resource {
  return this.isNoiseAlarm ? 
    $r('sys.color.alert') : 
    DecibelService.getDecibelColor(decibel);
}

// 获取闪烁透明度
private getBlinkOpacity(): number {
  // 实现闪烁效果：0.3 ~ 1.0 之间循环
  const time = Date.now() % 1000;
  return 0.3 + (Math.sin(time * Math.PI / 500) + 1) * 0.35;
}
```

#### 修改build方法
```typescript
build() {
  Column() {
    // 噪音场景参考和升级校准信息
    Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      this.noiseDescriptions()
      this.noiseCalibration()
    }
    .margin({
      bottom: 12,
      left: 16,
      right: 16,
      top: 12
    })

    // 分贝显示卡片 - 添加警报边框效果
    Row({ space: 8 }) {
      this.averageMin()
      this.CurrentDecibel()
      this.max()
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Bottom)
    .borderColor(this.isNoiseAlarm ? 
      $r('sys.color.alert') : 
      Color.Transparent)
    .borderWidth(this.isNoiseAlarm ? 2 : 0)
    .borderRadius(8)
    .animation({
      duration: 300,
      curve: Curve.EaseInOut
    })
  }
  .justifyContent(FlexAlign.Center)
}
```

### 3. 修改DecibelMeter中的DecibelDisplayComponent使用

在[`DecibelMeter.ets`](entry/src/main/ets/components/decibel-meter/DecibelMeter.ets:1)中更新DecibelDisplayComponent的使用：

```typescript
// 使用新的DecibelDisplayComponent
DecibelDisplayComponent({
  audioBuffer: this.currentAudioBuffer,
  audioAnalysisMode: this.pk.audio_analysis_mode,
  weightingType: this.pk.weighting_type,
  calibrationValue: this.pk.calibration_value,
  noiseThreshold: this.pk.noise_threshold,
  noiseAlarmEnabled: this.pk.noise_alarm_enabled,
  isNoiseAlarm: this.isAlarmActive, // 新增参数
  minMaxAvg: (min, max, avg) => {
    this.minDecibel = min;
    this.maxDecibel = max;
    this.avgDecibel = avg;
  },
  decibelValue: (decibel, weightingType) => {
    // 收集分贝值和加权类型到数组中
    this.values.push(decibel);
    this.weightingTypes.push(weightingType);
  }
})
```

### 4. 增强AlertsStatusIndicator

在[`AlertsStatusIndicator.ets`](entry/src/main/ets/components/alerts/AlertsStatusIndicator.ets:1)中添加实时警报状态显示：

```typescript
// 添加新的参数
@Param @Require isAlarmActive: boolean = false;

// 修改build方法中的状态描述
private getAlertStatusDescription(): string {
  if (this.isAlarmActive) {
    return '警报触发中';
  }
  
  if (!this.isAlertEnabled) {
    return '警报已关闭';
  }
  
  if (this.currentDecibel >= this.alertThreshold) {
    return '警报触发中';
  } else if (this.currentDecibel >= this.alertThreshold - 10) {
    return '接近警报阈值';
  } else {
    return '环境安全';
  }
}

// 修改警报状态颜色
private getAlertStatusColor(): Resource {
  if (this.isAlarmActive) {
    return $r('sys.color.alert');
  }
  
  if (!this.isAlertEnabled) {
    return $r('sys.color.font_secondary');
  }
  
  if (this.currentDecibel >= this.alertThreshold) {
    return $r('sys.color.alert');
  } else if (this.currentDecibel >= this.alertThreshold - 10) {
    return $r('sys.color.warning');
  } else {
    return $r('sys.color.confirm');
  }
}
```

### 5. 在AlertsSettingsNavigation中更新AlertsStatusIndicator

在[`AlertsSettingsNavigation.ets`](entry/src/main/ets/pages/settings/AlertsSettingsNavigation.ets:1)中更新AlertsStatusIndicator的使用：

```typescript
// 警报状态指示器
AlertsStatusIndicator({
  currentDecibel: this.as.db,
  alertThreshold: this.getCurrentEffectiveThreshold(),
  isAlertEnabled: this.pk.noise_alarm_enabled,
  isAlarmActive: this.isAlarmActive // 新增参数，需要从DecibelMeter传递
})
```

## 新增数据类型定义

创建新的类型定义文件或在现有文件中添加：

### AlertTypes.ets
```typescript
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
```

## 实施步骤

### 第一阶段：基础集成
1. 修改DecibelMeter添加警报检测逻辑
2. 更新DecibelDisplayComponent添加视觉反馈
3. 测试基础警报触发功能

### 第二阶段：多模态反馈
1. 实现声音反馈
2. 实现振动反馈  
3. 完善系统通知
4. 测试各反馈方式

### 第三阶段：状态同步
1. 更新AlertsStatusIndicator显示实时状态
2. 确保各组件状态同步
3. 性能优化和bug修复

### 第四阶段：用户体验优化
1. 调整反馈强度和频率
2. 添加用户设置验证
3. 完善错误处理

## 注意事项

1. **权限处理**: 确保应用有振动和通知权限
2. **性能考虑**: 避免频繁触发导致性能问题
3. **用户体验**: 反馈强度要适中，避免过度打扰
4. **错误处理**: 各反馈方式要有降级策略
5. **测试**: 在各种场景下测试警报功能

这个集成方案充分利用了现有架构，实现成本低且效果明显。