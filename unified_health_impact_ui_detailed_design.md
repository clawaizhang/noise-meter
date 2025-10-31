# 统一健康影响UI详细设计方案

## 1. 合并后主界面布局设计

### 1.1 整体布局结构（具体尺寸和位置）

```
┌─────────────────────────────────────────────────────────┐
│                   状态栏区域 (高度: 56px)                   │
│  ┌─────────────┐ ┌─────────────────────────────────────┐ │
│  │   应用标题   │ │            会员状态标签               │ │
│  └─────────────┘ └─────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────┤
│             健康影响等级展示区 (高度: 140px)               │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  ┌─────────────────────────────────────────────────┐ │ │
│  │  │  当前健康风险等级: [优秀/良好/注意/警告/危险]      │ │ │
│  │  │  ██████████████████████░░░░ 65%                │ │ │
│  │  │  剩余安全时间: 3小时15分钟                      │ │ │
│  │  └─────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────┤
│             实时噪音监测区 (高度: 120px)                  │
│  ┌─────────────────────────────────────────────────────┐ │
│  │  ┌─────┐ ┌─────────────────────────────────────────┐ │ │
│  │  │图标 │ │                72 dB                    │ │ │
│  │  └─────┘ │           [正常交谈水平]                 │ │ │
│  │          └─────────────────────────────────────────┘ │ │
│  │  ┌─────────────────────────────────────────────────┐ │ │
│  │  │ 最小:45dB   平均:65dB   最大:85dB               │ │ │
│  │  └─────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────┤
│             特殊噪音检测区 (高度: 100px)                  │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐                   │
│  │脉冲噪音 │ │低频共振 │ │持续暴露 │                   │
│  │  ●正常  │ │  ●检测中 │ │  ●中风险 │                   │
│  │  强度:15%│ │  125Hz  │ │  2.5小时 │                   │
│  └─────────┘ └─────────┘ └─────────┘                   │
├─────────────────────────────────────────────────────────┤
│             快速操作卡片区 (高度: 120px)                  │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                       │
│  │历史趋势│ │警报设置│ │健康报告│ │场景建议│               │
│  │ 📊   │ │ 🔔   │ │ 📋   │ │ 💡   │                   │
│  └─────┘ └─────┘ └─────┘ └─────┘                       │
└─────────────────────────────────────────────────────────┘
```

### 1.2 屏幕适配规格

| 屏幕尺寸 | 健康影响区 | 实时监测区 | 特殊噪音区 | 操作卡片区 |
|---------|-----------|-----------|-----------|-----------|
| 小屏(360px) | 140px | 120px | 100px | 120px |
| 中屏(480px) | 160px | 140px | 120px | 140px |
| 大屏(600px+) | 180px | 160px | 140px | 160px |

## 2. 健康风险等级可视化方案

### 2.1 健康风险等级定义和颜色编码

```typescript
// 健康风险等级枚举
enum HealthRiskLevel {
  EXCELLENT = "优秀",      // 0-30% 暴露剂量 - 绿色
  GOOD = "良好",          // 31-60% 暴露剂量 - 蓝色  
  ATTENTION = "注意",      // 61-80% 暴露剂量 - 黄色
  WARNING = "警告",        // 81-100% 暴露剂量 - 橙色
  DANGER = "危险"         // >100% 暴露剂量 - 红色
}

// 颜色编码系统
const HealthRiskColors = {
  [HealthRiskLevel.EXCELLENT]: {
    primary: $r('sys.color.confirm'),      // 绿色
    secondary: $r('sys.color.confirm_container'), // 浅绿色
    text: $r('sys.color.font_emphasize')   // 强调文字
  },
  [HealthRiskLevel.GOOD]: {
    primary: $r('sys.color.safe'),         // 蓝色
    secondary: $r('sys.color.safe_container'), // 浅蓝色
    text: $r('sys.color.font_emphasize')
  },
  [HealthRiskLevel.ATTENTION]: {
    primary: $r('sys.color.warning'),      // 黄色
    secondary: $r('sys.color.warning_container'), // 浅黄色
    text: $r('sys.color.font_primary')
  },
  [HealthRiskLevel.WARNING]: {
    primary: $r('sys.color.alert'),        // 橙色
    secondary: $r('sys.color.alert_container'), // 浅橙色
    text: $r('sys.color.font_primary')
  },
  [HealthRiskLevel.DANGER]: {
    primary: $r('sys.color.danger'),       // 红色
    secondary: $r('sys.color.danger_container'), // 浅红色
    text: $r('sys.color.font_primary')
  }
};
```

### 2.2 暴露剂量进度环设计

```typescript
@ComponentV2
struct ExposureProgressRing {
  @Param percentage: number = 0;
  @Param riskLevel: HealthRiskLevel = HealthRiskLevel.EXCELLENT;
  
  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 背景环
      Circle({ width: 80, height: 80 })
        .stroke(HealthRiskColors[this.riskLevel].secondary)
        .strokeWidth(8)
        .fill(Color.Transparent)
      
      // 进度环
      Circle({ width: 80, height: 80 })
        .stroke(HealthRiskColors[this.riskLevel].primary)
        .strokeWidth(8)
        .fill(Color.Transparent)
        .strokeDashArray([this.percentage * 2.51, 251]) // 基于百分比计算
        .rotation({ x: 0, y: 0, z: 1, angle: -90 })
      
      // 中心文本
      Column({ space: 2 }) {
        Text(`${this.percentage}%`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(HealthRiskColors[this.riskLevel].text)
        Text('暴露')
          .fontSize(10)
          .fontColor($r('sys.color.font_secondary'))
      }
    }
    .width(100)
    .height(100)
  }
}
```

### 2.3 动画效果设计

```typescript
// 风险等级变化动画
const riskLevelAnimation = {
  duration: 500,
  curve: Curve.EaseInOut,
  delay: 0,
  iterations: 1,
  playMode: PlayMode.Normal
};

// 进度环填充动画  
const progressRingAnimation = {
  duration: 800,
  curve: Curve.Spring,
  delay: 100,
  iterations: 1,
  playMode: PlayMode.Normal
};
```

## 3. 特殊噪音检测UI组件设计

### 3.1 特殊噪音卡片组件规格

```typescript
// 特殊噪音类型定义
enum SpecialNoiseType {
  IMPULSE = "impulse",        // 脉冲噪音
  LOW_FREQUENCY = "low_frequency", // 低频共振
  CONTINUOUS = "continuous"   // 持续暴露
}

// 特殊噪音状态
enum SpecialNoiseStatus {
  NORMAL = "正常",
  DETECTING = "检测中", 
  WARNING = "警告",
  DANGER = "危险"
}

// 特殊噪音卡片数据模型
interface SpecialNoiseCard {
  type: SpecialNoiseType;
  status: SpecialNoiseStatus;
  intensity: number; // 0-100
  frequency?: string; // 共振频率
  duration?: string; // 持续时间
  healthImpact: string; // 健康影响描述
}
```

### 3.2 脉冲噪音卡片设计

```typescript
@ComponentV2
struct ImpulseNoiseCard {
  @Param cardData: SpecialNoiseCard;
  
  build() {
    Column({ space: 8 }) {
      // 标题行
      Row({ space: 6 }) {
        Image($r('app.media.ic_flashlight_bold'))
          .width(16)
          .height(16)
          .fillColor(this.getStatusColor())
        Text('脉冲噪音')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')
      
      // 状态指示
      Row({ space: 4 }) {
        Circle({ width: 8, height: 8 })
          .fill(this.getStatusColor())
        Text(this.cardData.status)
          .fontSize(12)
          .fontColor(this.getStatusColor())
      }
      
      // 强度进度条
      Column({ space: 4 }) {
        Text(`强度: ${this.cardData.intensity}%`)
          .fontSize(10)
          .fontColor($r('sys.color.font_secondary'))
        Progress({ value: this.cardData.intensity, total: 100 })
          .width('100%')
          .color(this.getIntensityColor())
          .backgroundColor($r('sys.color.background_tertiary'))
      }
    }
    .padding(12)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(12)
    .width('30%')
    .height(80)
  }
  
  private getStatusColor(): ResourceColor {
    switch (this.cardData.status) {
      case SpecialNoiseStatus.NORMAL: return $r('sys.color.confirm');
      case SpecialNoiseStatus.DETECTING: return $r('sys.color.warning');
      case SpecialNoiseStatus.WARNING: return $r('sys.color.alert');
      case SpecialNoiseStatus.DANGER: return $r('sys.color.danger');
      default: return $r('sys.color.font_secondary');
    }
  }
  
  private getIntensityColor(): ResourceColor {
    if (this.cardData.intensity < 30) return $r('sys.color.confirm');
    if (this.cardData.intensity < 60) return $r('sys.color.warning');
    return $r('sys.color.danger');
  }
}
```

### 3.3 低频共振卡片设计

```typescript
@ComponentV2
struct LowFrequencyNoiseCard {
  @Param cardData: SpecialNoiseCard;
  
  build() {
    Column({ space: 8 }) {
      // 标题行
      Row({ space: 6 }) {
        Image($r('app.media.ic_weighting'))
          .width(16)
          .height(16)
          .fillColor(this.getStatusColor())
        Text('低频共振')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')
      
      // 状态和频率
      Column({ space: 4 }) {
        Row({ space: 4 }) {
          Circle({ width: 8, height: 8 })
            .fill(this.getStatusColor())
          Text(this.cardData.status)
            .fontSize(12)
            .fontColor(this.getStatusColor())
        }
        Text(`频率: ${this.cardData.frequency}`)
          .fontSize(10)
          .fontColor($r('sys.color.font_secondary'))
      }
      
      // 舒适度指示
      Text(this.cardData.healthImpact)
        .fontSize(10)
        .fontColor($r('sys.color.font_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .padding(12)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(12)
    .width('30%')
    .height(80)
  }
  
  private getStatusColor(): ResourceColor {
    // 同脉冲噪音卡片
  }
}
```

## 4. 实时数据和长期趋势整合方案

### 4.1 实时数据展示组件

```typescript
@ComponentV2
struct RealTimeNoiseMonitor {
  @Local currentDecibel: number = 0;
  @Local minDecibel: number = 0;
  @Local avgDecibel: number = 0;
  @Local maxDecibel: number = 0;
  @Local noiseDescription: string = '';
  
  build() {
    Column({ space: 12 }) {
      // 主分贝显示
      Row({ space: 12 }) {
        Image($r('app.media.ic_mic'))
          .width(24)
          .height(24)
          .fillColor(this.getDecibelColor())
        Column({ space: 4 }) {
          Text(`${this.currentDecibel} dB`)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getDecibelColor())
          Text(this.noiseDescription)
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
        }
      }
      
      // 统计数据
      Row({ space: 16 }) {
        Column({ space: 2 }) {
          Text('最小')
            .fontSize(10)
            .fontColor($r('sys.color.font_tertiary'))
          Text(`${this.minDecibel}dB`)
            .fontSize(12)
            .fontColor($r('sys.color.font_primary'))
        }
        Column({ space: 2 }) {
          Text('平均')
            .fontSize(10)
            .fontColor($r('sys.color.font_tertiary'))
          Text(`${this.avgDecibel}dB`)
            .fontSize(12)
            .fontColor($r('sys.color.font_primary'))
        }
        Column({ space: 2 }) {
          Text('最大')
            .fontSize(10)
            .fontColor($r('sys.color.font_tertiary'))
          Text(`${this.maxDecibel}dB`)
            .fontSize(12)
            .fontColor($r('sys.color.font_primary'))
        }
      }
    }
    .padding(16)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .width('100%')
    .onClick(() => {
      // 跳转到详细实时数据页面
    })
  }
  
  private getDecibelColor(): ResourceColor {
    if (this.currentDecibel < 60) return $r('sys.color.confirm');
    if (this.currentDecibel < 80) return $r('sys.color.warning');
    if (this.currentDecibel < 100) return $r('sys.color.alert');
    return $r('sys.color.danger');
  }
}
```

### 4.2 长期趋势迷你图表

```typescript
@ComponentV2
struct MiniTrendChart {
  @Param trendData: number[]; // 最近6小时数据
  @Param timeRange: '6h' | '24h' | '7d' = '6h';
  
  build() {
    Column({ space: 8 }) {
      // 趋势标题
      Row({ space: 8 }) {
        Text('最近趋势')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
        Image(this.getTrendIcon())
          .width(16)
          .height(16)
          .fillColor(this.getTrendColor())
      }
      
      // 迷你折线图
      LineChart()
        .data(this.trendData)
        .width('100%')
        .height(40)
        .color(this.getTrendColor())
    }
    .padding(12)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(12)
    .width('48%')
    .onClick(() => {
      // 跳转到完整趋势页面
    })
  }
}
```

## 5. 快速操作卡片设计

### 5.1 操作卡片组件

```typescript
@ComponentV2
struct QuickActionCard {
  @Param title: string = '';
  @Param icon: Resource = $r('app.media.ic_info');
  @Param description: string = '';
  
  build() {
    Column({ space: 12 }) {
      Image(this.icon)
        .width(24)
        .height(24)
        .fillColor($r('sys.color.icon_emphasize'))
      Text(this.title)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)
      Text(this.description)
        .fontSize(10)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .padding(12)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(12)
    .width('23%')
    .height(80)
    .onClick(() => {
      this.handleCardClick();
    })
  }
  
  private handleCardClick(): void {
    switch (this.title) {
      case '历史趋势':
        // 导航到历史趋势页面
        break;
      case '警报设置':
        // 打开警报设置弹窗
        break;
      case '健康报告':
        // 生成并显示健康报告
        break;
      case '场景建议':
        // 显示场景化建议
        break;
    }
  }
}
```

## 6. 与现有代码组件的对应关系

### 6.1 组件映射表

| 新组件 | 对应现有组件 | 集成方式 |
|--------|-------------|----------|
| `HealthRiskDisplay` | `HomePageContent` | 替换主页内容 |
| `RealTimeNoiseMonitor` | `DecibelMeter` | 复用数据流，重新设计UI |
| `SpecialNoiseDetection` | 新增组件 | 全新开发 |
| `QuickActionCards` | `ActionPanel` | 重构和扩展 |
| `ExposureProgressRing` | `EnhancedExposureContent` | 提取和优化 |

### 6.2 数据服务集成

```typescript
// 统一健康影响数据模型
@ObservedV2
export class UnifiedHealthImpactData {
  @Trace healthRiskLevel: HealthRiskLevel = HealthRiskLevel.EXCELLENT;
  @Trace exposurePercentage: number = 0;
  @Trace remainingSafeTime: string = '';
  @Trace trend: 'improving' | 'stable' | 'deteriorating' = 'stable';
  
  @Trace impulseNoise: SpecialNoiseCard = new SpecialNoiseCard();
  @Trace lowFrequencyNoise: SpecialNoiseCard = new SpecialNoiseCard();
  @Trace continuousExposure: SpecialNoiseCard = new SpecialNoiseCard();
  
  @Trace currentDecibel: number = 0;
  @Trace decibelStats: { min: number, avg: number, max: number } = { min: 0, avg: 0, max: 0 };
  
  // 从现有服务更新数据
  updateFromServices(): void {
    // 从DecibelService获取实时数据
    const decibelService = DecibelService.getInstance();
    this.currentDecibel = decibelService.getCurrentDecibel();
    this.decibelStats = decibelService.getStats();
    
    // 从ExposureStatisticsService获取暴露数据
    const exposureService = ExposureStatisticsService.getInstance();
    this.exposurePercentage = exposureService.getExposurePercentage();
    this.healthRiskLevel = this.calculateRiskLevel(this.exposurePercentage);
    this.remainingSafeTime = exposureService.getRemainingSafeTime();
    
    // 从AlertService获取特殊噪音检测
    const alertService = AlertService.getInstance();
    this.impulseNoise = alertService.getImpulseNoiseData();
    this.lowFrequencyNoise = alertService.getLowFrequencyNoiseData();
  }
}
```

### 6.3 导航结构调整

```typescript
// 新的导航标签配置
const unifiedTabs = [
  {
    title: '健康影响',
    icon: $r('app.media.i_solar_radar_bold'),
    index: 0,
    component: UnifiedHealthImpactDashboard
  },
  {
    title: '仪表盘', 
    icon: $r('app.media.ic_meter'),
    index: 1,
    component: DashboardContent // 保留现有功能
  },
  {
    title: '分析',
    icon: $r('app.media.ic_atom'),
    index: 2, 
    component: ToolsContent // 重命名为分析
  },
  {
    title: '我的',
    icon: $r('app.media.ic_user'),
    index: 3,
    component: MyContentComponent
  }
];
```

## 7. 交互说明和用户体验

### 7.1 主要交互流程

1. **健康风险等级点击**：展开详细健康影响分析页面
2. **实时噪音区域点击**：切换加权方式或查看实时波形
3. **特殊噪音卡片点击**：查看该类型噪音的详细检测报告
4. **快速操作卡片点击**：直接跳转到相应功能页面
5. **进度环点击**：显示暴露剂量详细分解

### 7.2 状态反馈机制

- **视觉反馈**：点击时卡片轻微缩放和颜色变化
- **触觉反馈**：重要状态变化时震动提示
- **声音反馈**：风险等级升级时播放提示音
- **通知反馈**：紧急情况发送系统通知

### 7.3 无障碍访问支持

- 支持语音朗读健康风险状态
- 高对比度颜色模式
- 字体大小自适应
- 屏幕阅读器兼容

这个设计方案提供了具体、可实施的UI布局和组件规格，能够直接用于开发实现，同时确保与现有代码架构的无缝集成。