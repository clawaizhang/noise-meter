# 简化版噪音警报Tab实施计划

## 概述

基于您的需求，直接在现有的[`NoiseMeterNavigation.ets`](entry/src/main/ets/pages/noisemeter/NoiseMeterNavigation.ets:1)中添加一个新的"噪音警报"Tab，专注于核心警报功能，后续再逐步添加历史记录和趋势分析等高级功能。

## 实施步骤

### 1. 修改NoiseMeterNavigation.ets

在现有两个Tab的基础上，在最左侧新增一个"噪音警报"Tab：

```typescript
// 在build方法中修改Tabs部分
build() {
  NavDestination() {
    Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
      // 新增：噪音警报Tab
      TabContent() {
        this.AlertsContent()
      }
      .tabBar(this.TabBuilder('警报', $r('app.media.ic_alarm'), 0))

      // 原有：仪表盘Tab
      TabContent() {
        this.DashboardContent()
      }
      .tabBar(this.TabBuilder('仪表盘', $r('app.media.ic_meter'), 1))

      // 原有：我的Tab
      TabContent() {
        this.MyContent()
      }
      .tabBar(this.TabBuilder('我的', $r('app.media.ic_favorite'), 2))
    }
    .onChange((index: number) => {
      this.currentIndex = index;
    })
    .barMode(BarMode.Fixed)
    .barWidth('100%')
    .animationDuration(0)
  }
  // ... 其他代码保持不变
}
```

### 2. 更新Tab索引处理

修改onTabIndexChange方法，处理新的Tab索引：

```typescript
@Monitor('currentIndex')
onTabIndexChange(monitor: IMonitor) {
  const currentValue = monitor.value<number>()?.now;
  if (currentValue === 0) {
    this.title = '噪音警报';
    this.menuItems = this.alertsMenus;
  }
  if (currentValue === 1) {
    this.title = '仪表盘';
    this.menuItems = this.noiseMeterMenus;
  }
  if (currentValue === 2) {
    this.title = '我的';
    this.menuItems = [];
  }
}
```

### 3. 创建警报菜单项

添加警报页面的菜单项：

```typescript
private alertsMenus: Array<NavigationMenuItem> = [
  {
    value: '警报设置',
    icon: $r('app.media.ic_settings'),
    action: () => {
      this.navStack.pushPathByName('AlertsSettings', null);
    }
  }
]
```

### 4. 创建AlertsContent构建器

实现警报页面的主要内容：

```typescript
@Builder
AlertsContent() {
  Column({ space: DesignConstants.SPACING_LG }) {
    // 1. 实时警报状态卡片
    this.buildRealTimeAlertCard()
    
    // 2. 快速控制面板
    this.buildQuickControls()
    
    // 3. 当前环境信息
    this.buildEnvironmentInfo()
  }
  .id('alertsContentId')
  .justifyContent(FlexAlign.Start)
  .alignItems(HorizontalAlign.Center)
  .opacity(this.currentIndex === 0 ? 1 : 0)
  .scale({ x: this.currentIndex === 0 ? 1 : 0.95, y: this.currentIndex === 0 ? 1 : 0.95 })
  .animation({
    duration: 300,
    curve: Curve.EaseOut,
    delay: 0,
    iterations: 1,
    playMode: PlayMode.Normal
  })
}
```

### 5. 实现核心警报组件

#### 实时警报状态卡片
```typescript
@Builder
private buildRealTimeAlertCard() {
  Column({ space: DesignConstants.SPACING_MD }) {
    // 状态指示器
    Row({ space: DesignConstants.SPACING_SM }) {
      Circle({ width: 12, height: 12 })
        .fill(this.isAlarmActive ? $r('sys.color.alert') : $r('sys.color.confirm'))
      
      Text(this.isAlarmActive ? '警报触发中' : '环境安全')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontColor(this.isAlarmActive ? $r('sys.color.alert') : $r('sys.color.confirm'))
        .fontWeight(FontWeight.Bold)
    }
    
    // 当前数值显示
    Text(`${this.currentDecibel}dB`)
      .fontSize(48)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.isAlarmActive ? $r('sys.color.alert') : $r('sys.color.font_primary'))
    
    // 阈值信息
    Text(`阈值: ${this.currentThreshold}dB`)
      .fontSize(DesignConstants.FONT_SIZE_MD)
      .fontColor($r('sys.color.font_secondary'))
  }
  .padding(DesignConstants.SPACING_LG)
  .backgroundColor($r('sys.color.comp_background_primary'))
  .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  .width('90%')
}
```

#### 快速控制面板
```typescript
@Builder
private buildQuickControls() {
  Column({ space: DesignConstants.SPACING_MD }) {
    Text('快速控制')
      .fontSize(DesignConstants.FONT_SIZE_XL)
      .fontWeight(FontWeight.Bold)
      .alignSelf(ItemAlign.Start)
    
    GridRow({ columns: 2, gutter: { x: 12, y: 12 } }) {
      // 警报总开关
      GridCol({ span: 1 }) {
        this.buildControlCard(
          '警报开关',
          this.isAlarmEnabled,
          $r('app.media.ic_power_on'),
          (enabled) => this.toggleAlarmEnabled(enabled)
        )
      }
      
      // 声音反馈
      GridCol({ span: 1 }) {
        this.buildControlCard(
          '声音',
          this.soundEnabled,
          $r('app.media.ic_audio_analysis'),
          (enabled) => this.toggleSoundEnabled(enabled)
        )
      }
      
      // 振动反馈
      GridCol({ span: 1 }) {
        this.buildControlCard(
          '振动',
          this.vibrationEnabled,
          $r('app.media.ic_sensor'),
          (enabled) => this.toggleVibrationEnabled(enabled)
        )
      }
      
      // 通知反馈
      GridCol({ span: 1 }) {
        this.buildControlCard(
          '通知',
          this.notificationEnabled,
          $r('app.media.ic_notification'),
          (enabled) => this.toggleNotificationEnabled(enabled)
        )
      }
    }
  }
  .padding(DesignConstants.SPACING_LG)
  .backgroundColor($r('sys.color.comp_background_primary'))
  .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  .width('90%')
}

@Builder
private buildControlCard(title: string, enabled: boolean, icon: Resource, onToggle: (enabled: boolean) => void) {
  Column({ space: DesignConstants.SPACING_SM }) {
    Image(icon)
      .width(24)
      .height(24)
      .fillColor(enabled ? $r('sys.color.brand') : $r('sys.color.font_secondary'))
    
    Text(title)
      .fontSize(DesignConstants.FONT_SIZE_MD)
    
    Toggle({ type: ToggleType.Switch, isOn: enabled })
      .onChange(onToggle)
  }
  .padding(DesignConstants.SPACING_MD)
  .backgroundColor($r('sys.color.background_secondary'))
  .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  .width('100%')
  .alignItems(HorizontalAlign.Center)
}
```

#### 环境信息显示
```typescript
@Builder
private buildEnvironmentInfo() {
  Column({ space: DesignConstants.SPACING_MD }) {
    Text('环境信息')
      .fontSize(DesignConstants.FONT_SIZE_XL)
      .fontWeight(FontWeight.Bold)
      .alignSelf(ItemAlign.Start)
    
    // 环境质量评级
    Row({ space: DesignConstants.SPACING_SM }) {
      Text('环境质量:')
        .fontSize(DesignConstants.FONT_SIZE_MD)
      
      Text(this.getEnvironmentQuality())
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor(this.getEnvironmentColor())
        .fontWeight(FontWeight.Medium)
    }
    
    // 建议信息
    Text(this.getEnvironmentSuggestion())
      .fontSize(DesignConstants.FONT_SIZE_SM)
      .fontColor($r('sys.color.font_secondary'))
      .textAlign(TextAlign.Start)
  }
  .padding(DesignConstants.SPACING_LG)
  .backgroundColor($r('sys.color.comp_background_primary'))
  .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  .width('90%')
}
```

### 6. 添加必要的状态变量

在MainNoiseMeter类中添加警报相关的状态变量：

```typescript
@Local private isAlarmActive: boolean = false;
@Local private isAlarmEnabled: boolean = true;
@Local private soundEnabled: boolean = true;
@Local private vibrationEnabled: boolean = true;
@Local private notificationEnabled: boolean = true;
@Local private currentDecibel: number = 0;
@Local private currentThreshold: number = 70;

// 监听分贝值变化
@Monitor('as.db')
onDecibelValueChange(monitor: IMonitor) {
  const currentDecibel = monitor.value<number>()?.now;
  if (currentDecibel !== undefined) {
    this.currentDecibel = currentDecibel;
    this.updateAlertStatus();
  }
}

// 更新警报状态
private updateAlertStatus(): void {
  if (!this.isAlarmEnabled) {
    this.isAlarmActive = false;
    return;
  }
  
  const threshold = ThresholdManager.getCurrentEffectiveThreshold();
  this.currentThreshold = threshold;
  
  if (this.currentDecibel >= threshold) {
    this.isAlarmActive = true;
    this.triggerAlarmFeedback();
  } else {
    this.isAlarmActive = false;
    this.clearAlarmFeedback();
  }
}
```

### 7. 实现基础反馈功能

```typescript
// 触发警报反馈
private triggerAlarmFeedback(): void {
  if (this.soundEnabled) {
    this.playAlarmSound();
  }
  
  if (this.vibrationEnabled) {
    this.startVibration();
  }
  
  if (this.notificationEnabled) {
    this.showAlarmNotification();
  }
}

// 清除警报反馈
private clearAlarmFeedback(): void {
  this.stopAlarmSound();
  this.stopVibration();
  this.cancelAlarmNotification();
}

// 简单的声音反馈（使用系统提示）
private playAlarmSound(): void {
  promptAction.showToast({
    message: '噪音超过阈值',
    duration: 1000
  });
}

// 振动反馈
private startVibration(): void {
  // 使用系统振动API
  try {
    const vibrator = vibrator.createVibrator();
    const vibrationEffect: vibrator.VibrateEffect = {
      type: 'time',
      duration: 500
    };
    vibrator.vibrate(vibrationEffect);
  } catch (error) {
    console.warn('振动功能不可用');
  }
}

private stopVibration(): void {
  // 停止振动
}

// 系统通知
private showAlarmNotification(): void {
  const notificationHelper = NotificationHelper.getInstance(getContext() as common.UIAbilityContext);
  notificationHelper.showNotification(
    1001,
    '噪音警报',
    `当前噪音: ${this.currentDecibel}dB`,
    '请关注环境噪音水平'
  );
}

private cancelAlarmNotification(): void {
  const notificationHelper = NotificationHelper.getInstance(getContext() as common.UIAbilityContext);
  notificationHelper.cancelNotification(1001);
}
```

## 实施优势

### 1. 渐进式开发
- 先实现核心警报功能
- 后续逐步添加历史记录、趋势分析等
- 降低初始开发复杂度

### 2. 用户体验
- 专门的警报Tab便于用户快速访问
- 清晰的实时状态显示
- 简单的控制操作

### 3. 技术实现
- 复用现有架构和组件
- 最小化代码修改
- 易于维护和扩展

## 后续扩展计划

### 第一阶段（当前）
- 基础警报检测和反馈
- 简单的状态显示和控制

### 第二阶段
- 警报历史记录
- 基本的统计信息

### 第三阶段
- 趋势分析图表
- 高级设置选项

### 第四阶段
- 智能警报模式
- 健康建议功能

这个简化方案专注于核心功能，快速实现噪音警报的基本能力，为后续功能扩展奠定基础。