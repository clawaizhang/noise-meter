# 噪音警报专用页面设计方案

## 概述

基于您的建议，在现有两个Tab（仪表盘、我的）的基础上，在最左侧新增一个"噪音警报"Tab，专门用于展示和管理噪音警报相关功能。

## 页面结构设计

### 1. 导航结构调整

当前导航结构：
- 📊 仪表盘 (Dashboard)
- 👤 我的 (Profile)

建议新增导航结构：
- 🚨 噪音警报 (Alerts) ← 新增
- 📊 仪表盘 (Dashboard)  
- 👤 我的 (Profile)

### 2. 警报页面功能模块

#### 页面布局
```typescript
// AlertsMainPage.ets
@ComponentV2
export struct AlertsMainPage {
  build() {
    Column() {
      // 1. 实时警报状态卡片
      this.buildRealTimeAlertCard()
      
      // 2. 快速设置面板
      this.buildQuickSettingsPanel()
      
      // 3. 警报历史与统计
      this.buildHistoryAndStatistics()
      
      // 4. 警报趋势分析
      this.buildTrendAnalysis()
    }
  }
}
```

## 详细功能设计

### 1. 实时警报状态卡片

显示当前警报状态和关键信息：

```typescript
@Builder
private buildRealTimeAlertCard() {
  Column({ space: DesignConstants.SPACING_MD }) {
    // 标题和状态指示
    Row({ space: DesignConstants.SPACING_SM }) {
      Image($r('app.media.ic_alarm'))
        .width(24)
        .height(24)
        .fillColor(this.isAlarmActive ? $r('sys.color.alert') : $r('sys.color.font_primary'))
      
      Text('噪音警报')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
      
      // 状态指示器
      Circle({ width: 12, height: 12 })
        .fill(this.isAlarmActive ? $r('sys.color.alert') : $r('sys.color.confirm'))
        .margin({ left: 8 })
    }
    
    // 当前状态信息
    if (this.isAlarmActive) {
      Column({ space: DesignConstants.SPACING_XS }) {
        Text('🚨 警报触发中')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontColor($r('sys.color.alert'))
          .fontWeight(FontWeight.Bold)
        
        Text(`当前噪音: ${this.currentDecibel}dB | 阈值: ${this.currentThreshold}dB`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
        
        Text(`持续时间: ${this.formatDuration(this.alertDuration)}`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
    } else {
      Column({ space: DesignConstants.SPACING_XS }) {
        Text('✅ 环境安全')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontColor($r('sys.color.confirm'))
          .fontWeight(FontWeight.Bold)
        
        Text(`当前噪音: ${this.currentDecibel}dB | 阈值: ${this.currentThreshold}dB`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
        
        Text('噪音水平在安全范围内')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
    }
    
    // 环境质量评级
    this.buildEnvironmentQualityRating()
  }
  .padding(DesignConstants.SPACING_LG)
  .backgroundColor($r('sys.color.comp_background_primary'))
  .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  .shadow(DesignConstants.SHADOW_SM)
}
```

### 2. 快速设置面板

提供一键式警报控制：

```typescript
@Builder
private buildQuickSettingsPanel() {
  Column({ space: DesignConstants.SPACING_MD }) {
    Text('快速设置')
      .fontSize(DesignConstants.FONT_SIZE_XL)
      .fontWeight(FontWeight.Bold)
      .alignSelf(ItemAlign.Start)
    
    GridRow({ columns: 2, gutter: { x: 12, y: 12 } }) {
      // 警报总开关
      GridCol({ span: 1 }) {
        this.buildQuickSettingCard(
          '警报开关',
          this.isAlarmEnabled,
          $r('app.media.ic_power_on'),
          (enabled) => this.toggleAlarmEnabled(enabled)
        )
      }
      
      // 声音反馈
      GridCol({ span: 1 }) {
        this.buildQuickSettingCard(
          '声音提示',
          this.soundEnabled,
          $r('app.media.ic_audio_analysis'),
          (enabled) => this.toggleSoundEnabled(enabled)
        )
      }
      
      // 振动反馈
      GridCol({ span: 1 }) {
        this.buildQuickSettingCard(
          '振动提示',
          this.vibrationEnabled,
          $r('app.media.ic_sensor'),
          (enabled) => this.toggleVibrationEnabled(enabled)
        )
      }
      
      // 系统通知
      GridCol({ span: 1 }) {
        this.buildQuickSettingCard(
          '系统通知',
          this.systemNotificationEnabled,
          $r('app.media.ic_notification'),
          (enabled) => this.toggleSystemNotificationEnabled(enabled)
        )
      }
    }
  }
  .padding(DesignConstants.SPACING_LG)
  .backgroundColor($r('sys.color.comp_background_primary'))
  .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  .shadow(DesignConstants.SHADOW_SM)
}

@Builder
private buildQuickSettingCard(
  title: string, 
  enabled: boolean, 
  icon: Resource, 
  onToggle: (enabled: boolean) => void
) {
  Column({ space: DesignConstants.SPACING_SM }) {
    Image(icon)
      .width(32)
      .height(32)
      .fillColor(enabled ? $r('sys.color.brand') : $r('sys.color.font_secondary'))
    
    Text(title)
      .fontSize(DesignConstants.FONT_SIZE_MD)
      .fontColor(enabled ? $r('sys.color.font_primary') : $r('sys.color.font_secondary'))
    
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

### 3. 警报历史与统计

展示最近的警报记录和统计信息：

```typescript
@Builder
private buildHistoryAndStatistics() {
  Column({ space: DesignConstants.SPACING_MD }) {
    // 标题和更多按钮
    Row({ space: DesignConstants.SPACING_SM }) {
      Text('警报历史')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
      
      Button('查看全部', { type: ButtonType.Capsule, stateEffect: true })
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .onClick(() => this.navigateToFullHistory())
    }
    
    // 统计概览
    GridRow({ columns: 3, gutter: { x: 8, y: 8 } }) {
      GridCol({ span: 1 }) {
        this.buildStatCard('今日警报', this.todayAlerts.toString(), '次')
      }
      GridCol({ span: 1 }) {
        this.buildStatCard('本周警报', this.weekAlerts.toString(), '次')
      }
      GridCol({ span: 1 }) {
        this.buildStatCard('最高分贝', `${this.peakDecibel}`, 'dB')
      }
    }
    
    // 最近警报列表
    Column({ space: DesignConstants.SPACING_SM }) {
      ForEach(this.recentAlerts, (alert: AlertRecord) => {
        this.buildAlertHistoryItem(alert)
      })
    }
  }
  .padding(DesignConstants.SPACING_LG)
  .backgroundColor($r('sys.color.comp_background_primary'))
  .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  .shadow(DesignConstants.SHADOW_SM)
}

@Builder
private buildAlertHistoryItem(alert: AlertRecord) {
  Row({ space: DesignConstants.SPACING_SM }) {
    Circle({ width: 8, height: 8 })
      .fill($r('sys.color.alert'))
    
    Column({ space: 2 }) {
      Text(`${alert.peakDecibel}dB`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
      
      Text(this.formatTime(alert.timestamp))
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
    }
    .layoutWeight(1)
    
    Text(this.formatDuration(alert.duration))
      .fontSize(DesignConstants.FONT_SIZE_SM)
      .fontColor($r('sys.color.font_secondary'))
  }
  .padding(DesignConstants.SPACING_MD)
  .backgroundColor($r('sys.color.background_secondary'))
  .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  .width('100%')
}
```

### 4. 警报趋势分析

使用图表展示警报趋势：

```typescript
@Builder
private buildTrendAnalysis() {
  Column({ space: DesignConstants.SPACING_MD }) {
    Text('警报趋势')
      .fontSize(DesignConstants.FONT_SIZE_XL)
      .fontWeight(FontWeight.Bold)
      .alignSelf(ItemAlign.Start)
    
    // 时间范围选择器
    Row({ space: DesignConstants.SPACING_SM }) {
      ForEach(['今日', '本周', '本月'], (period: string) => {
        Button(period, { 
          type: this.selectedPeriod === period ? 
            ButtonType.Normal : ButtonType.Capsule 
        })
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .onClick(() => this.selectPeriod(period))
      })
    }
    
    // 趋势图表
    this.buildTrendChart()
    
    // 趋势分析结论
    Column({ space: DesignConstants.SPACING_XS }) {
      Text('趋势分析')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
      
      Text(this.getTrendAnalysisText())
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
    }
  }
  .padding(DesignConstants.SPACING_LG)
  .backgroundColor($r('sys.color.comp_background_primary'))
  .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  .shadow(DesignConstants.SHADOW_SM)
}
```

## 集成到现有导航系统

### 1. 修改主页面配置

在[`main_pages.json`](entry/src/main/resources/base/profile/main_pages.json:1)中添加新的Tab：

```json
{
  "src": [
    "pages/alerts/AlertsMainPage",
    "pages/noisemeter/NoiseMeterNavigation", 
    "pages/Index"
  ],
  "window": {
    "designWidth": 720,
    "autoDesignWidth": false
  }
}
```

### 2. 更新路由映射

在[`route_map.json`](entry/src/main/resources/base/profile/route_map.json:1)中添加路由：

```json
{
  "route": {
    "AlertsMainPage": "pages/alerts/AlertsMainPage"
  }
}
```

### 3. 修改底部导航栏

在现有的底部导航组件中添加新的Tab项：

```typescript
// 在底部导航组件中添加
Tabs() {
  TabContent() {
    AlertsMainPage()
  }
  .tabBar('🚨', '警报')
  
  TabContent() {
    NoiseMeterNavigation()
  }
  .tabBar('📊', '仪表盘')
  
  TabContent() {
    Index()
  }
  .tabBar('👤', '我的')
}
```

## 页面交互设计

### 1. 实时数据更新

```typescript
// 监听分贝值变化
@Monitor('as.db')
onDecibelChange(monitor: IMonitor) {
  const currentDecibel = monitor.value<number>()?.now;
  if (currentDecibel !== undefined) {
    this.currentDecibel = currentDecibel;
    this.updateAlertStatus();
  }
}

// 更新警报状态
private updateAlertStatus(): void {
  const threshold = ThresholdManager.getCurrentEffectiveThreshold();
  const isAlarmEnabled = this.pk.noise_alarm_enabled;
  
  if (isAlarmEnabled && this.currentDecibel >= threshold) {
    if (!this.isAlarmActive) {
      this.startAlarm();
    }
    this.alertDuration = Date.now() - this.alertStartTime;
  } else {
    if (this.isAlarmActive) {
      this.stopAlarm();
    }
  }
}
```

### 2. 快捷操作

```typescript
// 一键静音
private muteAlarm(): void {
  this.isAlarmActive = false;
  this.stopAllFeedback();
  
  // 临时静音一段时间
  this.muteUntil = Date.now() + 30 * 60 * 1000; // 30分钟
}

// 快速调整阈值
private quickAdjustThreshold(adjustment: number): void {
  const newThreshold = this.currentThreshold + adjustment;
  if (newThreshold >= 30 && newThreshold <= 120) {
    ThresholdManager.setBaseThreshold(newThreshold);
    this.currentThreshold = newThreshold;
  }
}
```

## 用户体验优化

### 1. 视觉层次
- 使用颜色编码区分警报状态
- 重要的信息使用更大的字体和醒目的颜色
- 提供清晰的视觉反馈

### 2. 交互反馈
- 操作后立即显示状态变化
- 提供撤销操作的选项
- 重要的设置变更需要确认

### 3. 可访问性
- 支持屏幕阅读器
- 提供高对比度模式
- 支持键盘导航

## 实施优势

1. **集中管理**: 所有警报相关功能集中在一个页面
2. **快速访问**: 用户可以直接查看警报状态和历史
3. **直观操作**: 提供一键式设置和调整
4. **数据驱动**: 基于历史数据提供趋势分析
5. **用户体验**: 专门设计的界面提供更好的使用体验

这个专用警报页面将大大提升用户对噪音警报功能的使用便利性和管理效率。