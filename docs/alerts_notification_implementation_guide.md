# 警报通知系统实现指南

## 概述

基于HarmonyOS的notificationManager模块，实现用户友好的噪音警报系统，避免传统警报的刺耳和频繁问题。

## 核心设计原则

1. **柔和提醒**：使用系统默认的柔和提示音
2. **短促震动**：200毫秒单次震动
3. **智能频率**：避免重复警报骚扰用户
4. **渐进间隔**：连续警报时自动延长间隔

## 技术实现方案

### 1. 使用notificationManager设置通知声音和振动

```typescript
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 创建通知渠道（如果需要自定义声音和振动）
async function createAlertNotificationSlot(): Promise<void> {
  try {
    // 创建服务提醒类型的通知渠道
    await notificationManager.addSlot(notificationManager.SlotType.SERVICE_INFORMATION);
  } catch (error) {
    const err = error as BusinessError;
    console.error(`创建通知渠道失败: ${err.code}, ${err.message}`);
  }
}

// 发布带有声音和振动的通知
async function publishAlertNotification(
  currentDecibel: number, 
  threshold: number
): Promise<void> {
  try {
    const notificationRequest: notificationManager.NotificationRequest = {
      id: 999998, // 使用固定ID避免重复
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: "噪音警报",
          text: `当前噪音 ${currentDecibel}dB 超过阈值 ${threshold}dB`,
          additionalText: "请采取适当防护措施"
        }
      },
      // 设置通知行为
      deliveryTime: new Date().getTime(),
      // 设置声音和振动
      soundEnabled: true,  // 启用声音
      vibrationEnabled: true, // 启用振动
      // 使用系统默认提示音和震动模式
    };

    await notificationManager.publish(notificationRequest);
    console.info('警报通知发布成功');
  } catch (error) {
    const err = error as BusinessError;
    console.error(`发布通知失败: ${err.code}, ${err.message}`);
  }
}
```

### 2. 智能频率控制机制

```typescript
class AlertFrequencyController {
  private lastAlertTime: number = 0;
  private alertCount: number = 0;
  private readonly BASE_SILENT_PERIOD = 30000; // 30秒基础静默期
  private readonly PROGRESSIVE_INTERVALS = [30000, 60000, 120000, 300000]; // 渐进间隔

  // 检查是否可以触发警报
  canTriggerAlert(): boolean {
    const now = Date.now();
    
    if (this.lastAlertTime === 0) {
      return true;
    }

    const elapsed = now - this.lastAlertTime;
    const currentInterval = this.getCurrentInterval();
    
    return elapsed >= currentInterval;
  }

  // 获取当前警报间隔
  private getCurrentInterval(): number {
    const index = Math.min(this.alertCount, this.PROGRESSIVE_INTERVALS.length - 1);
    return this.PROGRESSIVE_INTERVALS[index];
  }

  // 记录警报触发
  recordAlert(): void {
    this.lastAlertTime = Date.now();
    this.alertCount++;
  }

  // 重置警报状态
  reset(): void {
    this.alertCount = 0;
  }
}
```

### 3. 完整的AlertService实现

```typescript
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

export class AlertService {
  private static instance: AlertService;
  private context: common.UIAbilityContext;
  private frequencyController: AlertFrequencyController;
  
  private constructor(context: common.UIAbilityContext) {
    this.context = context;
    this.frequencyController = new AlertFrequencyController();
    this.initializeNotificationSlot();
  }

  public static getInstance(context: common.UIAbilityContext): AlertService {
    if (!AlertService.instance) {
      AlertService.instance = new AlertService(context);
    }
    return AlertService.instance;
  }

  // 初始化通知渠道
  private async initializeNotificationSlot(): Promise<void> {
    try {
      // 确保有服务提醒类型的通知渠道
      await notificationManager.addSlot(notificationManager.SlotType.SERVICE_INFORMATION);
    } catch (error) {
      // 渠道可能已存在，忽略错误
    }
  }

  // 触发多模态警报
  public async triggerAlert(currentDecibel: number, threshold: number): Promise<void> {
    // 检查频率控制
    if (!this.frequencyController.canTriggerAlert()) {
      console.info('警报在静默期内，忽略触发');
      return;
    }

    try {
      // 发布通知（包含声音和振动）
      await this.publishAlertNotification(currentDecibel, threshold);
      
      // 记录警报触发
      this.frequencyController.recordAlert();
      
      console.info(`警报触发成功: ${currentDecibel}dB > ${threshold}dB`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`触发警报失败: ${err.code}, ${err.message}`);
    }
  }

  // 发布带有声音和振动的通知
  private async publishAlertNotification(
    currentDecibel: number, 
    threshold: number
  ): Promise<void> {
    const notificationRequest: notificationManager.NotificationRequest = {
      id: 999998,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: "噪音警报",
          text: `当前噪音 ${currentDecibel}dB 超过阈值 ${threshold}dB`,
          additionalText: "请采取适当防护措施"
        }
      },
      deliveryTime: new Date().getTime(),
      soundEnabled: true,    // 启用系统默认提示音
      vibrationEnabled: true, // 启用系统默认震动
      // 使用系统默认设置，避免过于刺激
    };

    await notificationManager.publish(notificationRequest);
  }

  // 重置警报状态
  public resetAlertState(): void {
    this.frequencyController.reset();
  }
}
```

### 4. 集成到AlertsContent组件

```typescript
// 在AlertsContent.ets中集成AlertService
import { AlertService } from '../../services/AlertService';

@ComponentV2
export struct AlertsContent {
  // ... 现有代码
  
  private alertService: AlertService = AlertService.getInstance(getContext() as common.UIAbilityContext);

  // 触发警报时调用
  private async triggerAlarm(currentDecibel: number): Promise<void> {
    this.isAlarmActive = true;
    this.visualAlertState = 'alert';
    this.alertStartTime = Date.now();

    // 使用AlertService触发警报
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();
    await this.alertService.triggerAlert(currentDecibel, threshold);
  }

  // 解除警报时重置状态
  private clearAlarm(): void {
    this.isAlarmActive = false;
    this.visualAlertState = 'normal';
    this.alertDuration = Date.now() - this.alertStartTime;
    this.alertService.resetAlertState();
  }
}
```

## 用户体验优化

### 1. 声音设置
- 使用系统默认提示音，避免自定义刺耳声音
- 通知会自动播放声音，无需额外处理
- 用户可以在系统设置中调整音量

### 2. 振动设置  
- 使用系统默认震动模式
- 通知会自动触发震动，无需额外处理
- 用户可以在系统设置中关闭震动

### 3. 频率控制
- **基础静默期**：30秒内不重复触发
- **渐进间隔**：30s → 60s → 120s → 300s
- **智能重置**：噪音恢复正常后重置状态

## 权限配置

在`module.json5`中添加振动权限：

```json
{
  "name": "ohos.permission.VIBRATE",
  "reason": "$string:vibrate_permission_reason",
  "usedScene": {
    "abilities": ["EntryAbility"],
    "when": "always"
  }
}
```

在`string.json`中添加权限说明：

```json
{
  "name": "vibrate_permission_reason",
  "value": "需要振动权限来提供警报震动反馈"
}
```

## 测试要点

1. **功能测试**：验证警报触发、声音播放、震动触发
2. **频率测试**：验证静默期和渐进间隔机制
3. **用户体验**：确保警报不会过于频繁或刺激
4. **权限测试**：验证振动权限正常工作

## 总结

通过使用HarmonyOS的notificationManager模块，我们可以实现一个用户友好的警报系统：

- ✅ **柔和声音**：使用系统默认提示音
- ✅ **短促震动**：使用系统默认震动模式  
- ✅ **智能频率**：避免重复警报骚扰用户
- ✅ **易于实现**：无需复杂的音频和振动处理
- ✅ **用户可控**：用户可以在系统设置中调整

这个方案既保证了警报的有效性，又避免了传统警报的刺耳和频繁问题。