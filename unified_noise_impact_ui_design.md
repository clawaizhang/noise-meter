# 统一噪音影响评估系统UI设计方案

## 1. 设计概述

### 1.1 设计理念
- **统一度量标准**：以"噪音对人的健康影响"为核心度量标准
- **整合警报与影响**：将传统分贝阈值警报与健康影响评估整合为统一系统
- **特殊噪音关注**：重点检测和显示突发性脉冲噪音和低频共振噪音
- **用户健康导向**：所有UI元素都服务于用户健康保护目标

### 1.2 设计原则
- **清晰直观**：健康影响等级一目了然
- **实时反馈**：即时显示噪音对健康的潜在影响
- **预防为主**：在健康风险发生前提供预警
- **个性化**：基于用户场景和环境提供针对性建议

## 2. 主仪表盘界面设计

### 2.1 整体布局结构
```
┌─────────────────────────────────────────┐
│             状态栏 (标题+会员状态)         │
├─────────────────────────────────────────┤
│          健康影响等级展示区               │
│  ┌─────────────────────────────────────┐ │
│  │ 当前健康风险等级: [优秀/良好/注意/警告] │ │
│  │ 暴露剂量: ████████░░ 65%           │ │
│  │ 剩余安全时间: 3小时15分钟           │ │
│  └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│          实时噪音监测区                 │
│  ┌─────────────────────────────────────┐ │
│  │            72 dB                    │ │
│  │           [噪音描述]                 │ │
│  │ 最小:45dB 平均:65dB 最大:85dB       │ │
│  └─────────────────────────────────────┘ │
├─────────────────────────────────────────┤
│          特殊噪音检测区                 │
│  ┌───────┐ ┌───────┐ ┌───────┐         │
│  │脉冲噪音│ │低频共振│ │持续暴露│       │
│  │ 正常  │ │ 检测中 │ │ 中风险 │       │
│  └───────┘ └───────┘ └───────┘       │
├─────────────────────────────────────────┤
│          快速操作卡片区                 │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐       │
│  │历史趋势│ │警报设置│ │健康报告│ │场景建议│ │
│  └─────┘ └─────┘ └─────┘ └─────┘       │
└─────────────────────────────────────────┘
```

### 2.2 健康影响等级展示区

#### 健康风险等级定义
```typescript
enum HealthRiskLevel {
  EXCELLENT = "优秀",      // 0-30% 暴露剂量
  GOOD = "良好",          // 31-60% 暴露剂量  
  ATTENTION = "注意",      // 61-80% 暴露剂量
  WARNING = "警告",        // 81-100% 暴露剂量
  DANGER = "危险"         // >100% 暴露剂量
}
```

#### 颜色编码系统
```typescript
const HealthRiskColors = {
  [HealthRiskLevel.EXCELLENT]: $r('sys.color.confirm'),     // 绿色
  [HealthRiskLevel.GOOD]: $r('sys.color.safe'),            // 蓝色
  [HealthRiskLevel.ATTENTION]: $r('sys.color.warning'),    // 黄色
  [HealthRiskLevel.WARNING]: $r('sys.color.alert'),        // 橙色
  [HealthRiskLevel.DANGER]: $r('sys.color.danger')         // 红色
};
```

## 3. 特殊噪音检测组件设计

### 3.1 脉冲噪音检测
- **检测算法**：基于时域信号的突变检测
- **显示指标**：脉冲强度、发生频率、持续时间
- **健康影响**：瞬时听力损伤风险评估

### 3.2 低频共振噪音检测  
- **检测算法**：频谱分析低频段能量集中
- **显示指标**：共振频率、强度、舒适度影响
- **健康影响**：长期暴露的身体不适评估

### 3.3 特殊噪音状态卡片
```typescript
interface SpecialNoiseCard {
  type: 'impulse' | 'low_frequency' | 'continuous';
  status: 'normal' | 'detecting' | 'warning' | 'danger';
  intensity: number; // 0-100
  frequency: string; // 发生频率描述
  healthImpact: string; // 健康影响描述
}
```

## 4. 健康影响可视化方案

### 4.1 暴露剂量进度环
- **视觉形式**：环形进度条，颜色随风险等级变化
- **数据展示**：当前暴露百分比和剩余安全时间
- **交互功能**：点击查看详细暴露分析

### 4.2 健康风险等级指示器
- **多级显示**：从优秀到危险的5级风险指示
- **颜色渐变**：平滑的颜色过渡反映风险变化
- **动画效果**：风险等级变化时的平滑过渡动画

### 4.3 实时趋势指示器
- **趋势箭头**：显示健康风险的上升/下降趋势
- **变化速率**：显示风险变化的速度
- **预测提示**：基于当前趋势预测未来风险

## 5. 历史趋势和报告界面

### 5.1 暴露历史时间线
- **日视图**：24小时暴露剂量变化
- **周视图**：7天健康风险趋势
- **月视图**：长期暴露模式分析

### 5.2 健康报告生成
- **自动报告**：每日/每周健康影响总结
- **风险分析**：识别高风险时间段和场景
- **改善建议**：基于数据分析的个性化建议

### 5.3 场景分析
- **位置关联**：噪音暴露与地理位置的关联分析
- **时间模式**：识别重复出现的风险模式
- **行为建议**：基于分析结果的避峰建议

## 6. 用户交互流程设计

### 6.1 状态转换逻辑
```
正常状态 → 注意状态 → 警告状态 → 危险状态
    ↓          ↓          ↓          ↓
常规监测   轻度提醒   中度警报   紧急干预
```

### 6.2 警报升级机制
- **Level 1**：视觉提示（颜色变化）
- **Level 2**：声音提醒（轻柔提示音）
- **Level 3**：震动警报（强烈提醒）
- **Level 4**：紧急通知（系统级通知）

### 6.3 用户反馈循环
- **即时反馈**：操作立即得到视觉确认
- **状态同步**：所有界面保持状态一致性
- **学习适应**：系统根据用户习惯优化提醒时机

## 7. 技术实现建议

### 7.1 新组件设计

#### UnifiedImpactDashboard.ets
```typescript
@ComponentV2
export struct UnifiedImpactDashboard {
  @Local currentHealthRisk: HealthRiskLevel = HealthRiskLevel.EXCELLENT;
  @Local exposurePercentage: number = 0;
  @Local specialNoises: SpecialNoiseCard[] = [];
  
  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 健康影响等级展示
      HealthRiskDisplay({
        riskLevel: this.currentHealthRisk,
        exposurePercentage: this.exposurePercentage
      })
      
      // 实时噪音监测
      RealTimeNoiseMonitor()
      
      // 特殊噪音检测
      SpecialNoiseDetection({ noises: this.specialNoises })
      
      // 快速操作卡片
      QuickActionCards()
    }
  }
}
```

#### HealthRiskDisplay.ets
```typescript
@ComponentV2
export struct HealthRiskDisplay {
  @Param riskLevel: HealthRiskLevel;
  @Param exposurePercentage: number;
  
  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 风险等级标签
      Text(`当前健康风险等级: ${this.riskLevel}`)
        .fontColor(HealthRiskColors[this.riskLevel])
        .fontSize(DesignConstants.FONT_SIZE_XL)
      
      // 暴露剂量进度环
      ExposureProgressRing({
        percentage: this.exposurePercentage,
        color: HealthRiskColors[this.riskLevel]
      })
      
      // 剩余安全时间
      Text(`剩余安全时间: ${this.calculateSafeTime()}`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
    }
  }
}
```

### 7.2 数据模型扩展

#### HealthImpactData.ets
```typescript
@ObservedV2
export class HealthImpactData {
  @Trace healthRiskLevel: HealthRiskLevel = HealthRiskLevel.EXCELLENT;
  @Trace exposurePercentage: number = 0;
  @Trace remainingSafeTime: string = '';
  @Trace trend: 'improving' | 'stable' | 'deteriorating' = 'stable';
  
  @Trace impulseNoise: SpecialNoiseMetric = new SpecialNoiseMetric();
  @Trace lowFrequencyNoise: SpecialNoiseMetric = new SpecialNoiseMetric();
  
  updateFromExposureData(exposureData: ExposureData): void {
    this.exposurePercentage = exposureData.exposurePercentage;
    this.healthRiskLevel = this.calculateRiskLevel(exposureData.exposurePercentage);
    this.remainingSafeTime = exposureData.remainingSafeTime;
  }
}
```

### 7.3 集成现有架构

#### 与现有组件的关系
- **继承HomePageContent**：作为主仪表盘的增强版本
- **扩展ExposureData**：在暴露统计基础上增加健康影响维度
- **整合AlertService**：将传统警报升级为健康风险警报
- **复用统计图表**：增强健康趋势可视化

## 8. 移动端适配优化

### 8.1 响应式布局
- **小屏幕**：垂直堆叠，重点显示健康风险等级
- **中屏幕**：两栏布局，平衡信息密度和可读性
- **大屏幕**：三栏布局，充分利用屏幕空间

### 8.2 触摸交互优化
- **手势支持**：滑动手势切换时间视图
- **触觉反馈**：风险等级变化时的震动反馈
- **无障碍访问**：支持语音提示和放大显示

### 8.3 性能考虑
- **数据懒加载**：历史数据按需加载
- **动画优化**：使用硬件加速的CSS动画
- **内存管理**：及时清理不再使用的数据缓存

## 9. 实施路线图

### Phase 1: 核心功能 (2周)
- 实现健康影响等级展示组件
- 集成现有暴露统计服务
- 设计统一颜色编码系统

### Phase 2: 特殊噪音检测 (3周)  
- 开发脉冲噪音检测算法
- 实现低频共振噪音识别
- 创建特殊噪音状态卡片

### Phase 3: 高级功能 (2周)
- 实现历史趋势分析
- 开发健康报告生成
- 优化用户交互流程

### Phase 4: 优化完善 (1周)
- 移动端适配优化
- 性能调优和测试
- 用户反馈收集和改进

## 10. 成功指标

### 用户体验指标
- 健康风险认知度提升
- 警报误报率降低
- 用户满意度提高

### 技术性能指标  
- 界面响应时间 < 100ms
- 特殊噪音检测准确率 > 90%
- 电池消耗增加 < 5%

这个设计方案将现有的分贝监测系统升级为以健康影响为核心的综合评估系统，为用户提供更直观、更有价值的噪音健康保护服务。