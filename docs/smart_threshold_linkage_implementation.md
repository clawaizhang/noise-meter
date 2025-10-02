# 智能阈值联动实现方案

## 问题分析

当前时段调度与智能预设之间存在数据孤岛问题：
- 智能预设只修改 `noise_threshold` 字段
- 时段调度使用独立的 `daytime_alert_threshold` 和 `nighttime_alert_threshold` 字段
- 两个系统之间没有数据同步机制

## 声学原理依据

基于GB3096-2008声环境质量标准和人体生理节律：
- 白天（6:00-22:00）：人体活动状态，噪声耐受度较高
- 夜间（22:00-6:00）：人体休息状态，噪声敏感度显著提高
- 夜间噪声限值比白天严格10-15dB是国际通用标准

## 智能联动算法设计

### 阈值映射关系

| 预设类型 | 基准阈值 | 昼夜差值 | 白天阈值 | 夜间阈值 | 声学依据 |
|---------|---------|---------|---------|---------|---------|
| 安静环境 | 40dB | 5dB | 45dB | 35dB | 睡眠环境需要更严格保护 |
| 一般环境 | 55dB | 10dB | 65dB | 45dB | 符合GB3096标准差值 |
| 嘈杂环境 | 70dB | 15dB | 85dB | 55dB | 保护听力健康 |
| 危险环境 | 85dB | 20dB | 105dB | 65dB | 防止听力损伤 |
| 自定义 | 用户设置 | 用户设置 | 用户设置 | 用户设置 | 完全用户控制 |

### 算法逻辑

```typescript
// 智能差值计算函数
function calculateTimeSchedulingThresholds(baseThreshold: number): { daytime: number, nighttime: number } {
  let difference = 0;
  
  // 基于基准阈值智能计算差值
  if (baseThreshold <= 40) {
    difference = 5;  // 安静环境：差值较小
  } else if (baseThreshold <= 55) {
    difference = 10; // 一般环境：标准差值
  } else if (baseThreshold <= 70) {
    difference = 15; // 嘈杂环境：较大差值
  } else {
    difference = 20; // 危险环境：最大差值
  }
  
  return {
    daytime: baseThreshold + difference,
    nighttime: baseThreshold - difference
  };
}
```

## 技术实现方案

### 1. 修改 AlertsConstants.ets

在现有常量基础上添加智能联动配置：

```typescript
// 智能联动配置
export const SMART_LINKAGE_CONFIG = {
  ENABLED: true,
  PRESET_THRESHOLD_DIFFERENCES: {
    'quiet_environment': 5,    // 安静环境差值
    'general_environment': 10, // 一般环境差值
    'noisy_environment': 15,   // 嘈杂环境差值
    'dangerous_environment': 20 // 危险环境差值
  }
};

// 预设映射表
export const PRESET_MAPPING: Record<string, string> = {
  'quiet_environment': '安静环境',
  'general_environment': '一般环境', 
  'noisy_environment': '嘈杂环境',
  'dangerous_environment': '危险环境',
  'custom': '自定义'
};
```

### 2. 更新 SmartThresholdPresets.ets

在预设选择时自动计算并更新时段调度阈值：

```typescript
// 在 onPresetChange 方法中添加联动逻辑
private onPresetSelected(preset: PresetThreshold) {
  // 更新主阈值
  this.onPresetChange(preset.name.toLowerCase().replace(' ', '_'));
  this.onThresholdChange(preset.value);
  
  // 智能联动：自动计算时段调度阈值
  if (SMART_LINKAGE_CONFIG.ENABLED) {
    const thresholds = this.calculateTimeSchedulingThresholds(preset.value);
    this.onDaytimeThresholdChange(thresholds.daytime);
    this.onNighttimeThresholdChange(thresholds.nighttime);
  }
}

// 计算时段调度阈值
private calculateTimeSchedulingThresholds(baseThreshold: number): { daytime: number, nighttime: number } {
  // 实现上述算法逻辑
}
```

### 3. 更新 AlertsSettingsNavigation.ets

在组件中添加联动状态管理和回调函数：

```typescript
// 添加联动状态
@Local private isSmartLinkageEnabled: boolean = true;

// 处理预设变化的增强方法
private onPresetChangeWithLinkage(preset: string) {
  this.pk.current_preset_threshold = preset;
  
  // 如果是预设模式且联动启用，自动计算时段调度阈值
  if (preset !== 'custom' && this.isSmartLinkageEnabled) {
    const baseThreshold = this.getPresetBaseThreshold(preset);
    const thresholds = this.calculateTimeSchedulingThresholds(baseThreshold);
    
    this.pk.daytime_alert_threshold = thresholds.daytime;
    this.pk.nighttime_alert_threshold = thresholds.nighttime;
  }
}

// 获取预设基准阈值
private getPresetBaseThreshold(preset: string): number {
  const presetMap = {
    'quiet_environment': 40,
    'general_environment': 55,
    'noisy_environment': 70,
    'dangerous_environment': 85
  };
  return presetMap[preset] || this.pk.noise_threshold;
}
```

## 用户体验设计

### 联动状态指示

在时段调度面板中添加智能联动状态指示：

```
[智能联动] 时段调度阈值已根据"安静环境"预设自动调整
白天: 45dB | 夜间: 35dB
```

### 手动覆盖选项

提供用户手动覆盖智能联动的选项：
- 时段调度阈值被手动修改时，自动禁用智能联动
- 提供"恢复智能联动"按钮

## 测试验证方案

### 功能测试用例

1. **预设选择联动测试**
   - 选择"安静环境"预设 → 验证时段调度自动调整为45dB/35dB
   - 选择"危险环境"预设 → 验证时段调度自动调整为105dB/65dB

2. **手动覆盖测试**
   - 手动修改白天阈值 → 验证智能联动自动禁用
   - 点击"恢复智能联动" → 验证阈值恢复预设计算值

3. **自定义模式测试**
   - 选择自定义模式 → 验证时段调度保持用户设置
   - 切换回预设模式 → 验证重新启用智能联动

### 声学合理性验证

- 验证所有计算阈值符合声学安全标准
- 夜间阈值不超过55dB（睡眠环境上限）
- 白天阈值不超过120dB（听力损伤风险阈值）

## 实施优先级

1. **高优先级**：基础智能联动功能
2. **中优先级**：联动状态指示和手动覆盖
3. **低优先级**：高级联动配置选项

## 风险评估

- **风险**：用户可能不期望自动修改时段调度阈值
- **缓解**：提供清晰的联动状态指示和手动覆盖选项
- **回滚**：保留手动修改功能，确保用户完全控制