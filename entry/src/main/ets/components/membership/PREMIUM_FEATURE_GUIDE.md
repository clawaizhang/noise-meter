# PremiumFeature 组件使用指南

## 概述

`PremiumFeature` 是一个用于实现会员功能分层的包装组件。它支持多种锁定模式，可以灵活地控制功能的免费/付费边界。

## 四种锁定模式

### 1. FULL_LOCK - 完全锁定（默认）
功能完全置灰，点击弹出升级提示。适用于核心付费功能。

```typescript
PremiumFeature({
  featureId: 'spectrum_customization',
  featureName: '频谱自定义',
  featureDesc: '自定义窗函数、采样率等专业设置',
  icon: $r('app.media.ic_audio_analysis'),
  lockMode: PremiumLockMode.FULL_LOCK
}) {
  // 免费版看到的内容（置灰）
  YourComponent()
}
.proContent(() => {
  // 专业版看到的内容
  YourProComponent()
})
```

### 2. SOFT_LIMIT - 软限制
功能可用但有限制（如数量、时间），超出限制后提示升级。适用于数据存储类功能。

```typescript
PremiumFeature({
  featureId: 'history_records',
  featureName: '历史记录',
  featureDesc: '查看检测历史',
  lockMode: PremiumLockMode.SOFT_LIMIT,
  limit: createFeatureLimit(
    LimitType.COUNT,    // 限制类型：次数
    3,                  // 免费限制：3条
    -1,                 // 专业版：无限制
    currentRecordCount, // 当前已使用
    '条'               // 单位
  )
}) {
  YourComponent()
}
```

### 3. COMPARISON - 对比模式
显示功能对比表，让用户了解差异，但不阻止使用。适用于设置页。

```typescript
PremiumFeature({
  featureId: 'frequency_weighting',
  featureName: '频率加权',
  lockMode: PremiumLockMode.COMPARISON,
  comparisonList: [
    createFeatureComparison('A计权', '✓ 可用', '✓ 可用', false),
    createFeatureComparison('C计权', '✗ 不可用', '✓ 可用', true),
  ]
}) {
  YourComponent()
}
```

### 4. BADGE_ONLY - 仅标签
仅显示VIP标签，不阻止使用。适用于轻度引导。

```typescript
PremiumFeature({
  featureId: 'auto_save',
  featureName: '自动保存',
  lockMode: PremiumLockMode.BADGE_ONLY,
  showTrialTip: false  // 不显示试用提示
}) {
  YourComponent()
}
```

## 功能分类建议

### 基础版免费功能

| 功能 | 说明 |
|------|------|
| 实时分贝检测 | 核心功能，必须免费 |
| 基础频谱显示 | 视觉效果，免费展示 |
| 手动校准 | 基础精度保障 |
| 峰值频率显示 | 基础分析功能 |
| 当日暴露统计 | 当日数据展示 |
| 位置服务 | 基础定位功能 |
| 参考标准 | 知识类内容 |

### 专业版付费功能

| 功能 | 锁定模式 | 说明 |
|------|----------|------|
| 历史记录查看 | SOFT_LIMIT | 免费3条，专业无限制 |
| 频谱自定义 | FULL_LOCK | FFT参数、窗函数等 |
| 频率加权切换 | COMPARISON | A/C/Z计权 |
| 时间加权切换 | COMPARISON | 快速/慢速/脉冲 |
| 自动保存 | FULL_LOCK 或 BADGE_ONLY | 自动定时保存 |
| 历史暴露分析 | SOFT_LIMIT | 当日免费，历史付费 |
| 智能自动校准 | FULL_LOCK | 自动计算校准值 |
| 音频录制回放 | FULL_LOCK | 保存音频文件 |

## 快速开始

### 1. 导入组件

```typescript
import { 
  PremiumFeature, 
  PremiumLockMode, 
  LimitType,
  createFeatureLimit,
  createFeatureComparison,
  CommonFeatureComparisons  // 预定义的对比配置
} from './PremiumFeature';
```

### 2. 基础使用

```typescript
PremiumFeature({
  featureId: 'unique_id',           // 唯一标识
  featureName: '功能名称',           // 显示在升级弹窗
  featureDesc: '功能描述',           // 显示在升级弹窗
  icon: $r('app.media.ic_vip'),     // 功能图标
  lockMode: PremiumLockMode.FULL_LOCK,
  showTrialTip: true,               // 是否显示试用提示
  trialDays: 7                      // 试用天数
}) {
  // 免费版内容
  YourComponent()
}
.proContent(() => {
  // 专业版内容（可选）
  YourProComponent()
})
.onUnlock(() => {
  // 用户升级成功回调
  console.info('用户已升级');
})
```

## 预定义的对比配置

组件提供了一些常用的功能对比配置：

```typescript
CommonFeatureComparisons.historyRecords      // 历史记录
CommonFeatureComparisons.measurementPrecision // 测量精度
CommonFeatureComparisons.exposureStats       // 暴露统计
CommonFeatureComparisons.dataManagement      // 数据管理
```

使用示例：

```typescript
PremiumFeature({
  featureId: 'data_management',
  featureName: '数据管理',
  lockMode: PremiumLockMode.COMPARISON,
  comparisonList: CommonFeatureComparisons.dataManagement
}) {
  // 内容
}
```

## 回调说明

| 回调 | 触发时机 | 用途 |
|------|----------|------|
| `onUpgradeClick` | 用户点击升级按钮 | 追踪转化 |
| `onUnlock` | 用户成功升级后 | 刷新数据/界面 |
| `onLimitReached` | 达到软限制上限 | 提示用户 |

## 注意事项

1. **featureId 必须唯一**：用于追踪和区分不同功能
2. **proContent 是可选的**：如果不提供，专业版和免费版显示相同内容
3. **软限制需要配合业务逻辑**：组件只负责UI展示，实际限制需要在业务层实现
4. **回调函数使用 Throttle**：避免重复触发

## 完整示例

参考 `PremiumFeatureExamples.ets` 文件，包含：
- 历史记录限制（软限制）
- 频谱自定义（完全锁定）
- 频率加权（对比模式）
- 暴露统计（软限制）
- 自动保存（仅标签）
- 测量精度设置页（综合示例）
