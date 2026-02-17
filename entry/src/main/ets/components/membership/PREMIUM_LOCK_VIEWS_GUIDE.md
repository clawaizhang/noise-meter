# 专业版锁定视图组件使用指南

## 概述

新的 `PremiumLockViews` 提供三种独立实现的锁定UI方案，不再使用统一的弹框，而是根据场景选择最合适的展示方式。

## 三种场景组件

### 1. SettingLockView - 设置页开关（底部卡片式）

**适用场景**：
- 自动保存设置
- 音频录制设置
- 各类功能开关

**效果预览**：
```
┌─────────────────────────────────┐
│  数据管理                        │
│  ┌─────────────────────────┐   │
│  │ 启用自动保存      [开关] │ ← 置灰预览 │
│  │ 保存间隔        5分钟    │            │
│  └─────────────────────────┘            │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░             │
│  ┌─────────────────────────┐            │
│  │ 🔒 自动保存   [PRO]      │ ← 底部卡片 │
│  │ 按设定时间自动保存...     │            │
│  │ [🎁7天试用] [☁️云端同步] │            │
│  │                         │            │
│  │   [🔓 0.01元立即试用]    │            │
│  └─────────────────────────┘            │
└─────────────────────────────────┘
```

**使用示例**：
```typescript
import { SettingLockView, isProMember } from '../membership/PremiumLockViews';

// 在build中判断
if (isProMember()) {
  // 专业版：正常显示
  Toggle({...})
} else {
  // 免费版：锁定显示
  SettingLockView({
    params: {
      featureId: 'auto_save',
      featureName: '自动保存',
      featureDesc: '按设定时间自动保存检测数据',
      benefitTags: [
        { icon: '🎁', text: '7天免费试用' },
        { icon: '☁️', text: '云端同步' }
      ],
      trialPrice: '0.01元立即试用',
      onUpgrade: () => {
        // 升级成功回调
      }
    }
  }) {
    // 置灰的内容预览
    Column() {
      // 放禁用状态的UI预览
    }
  }
}
```

---

### 2. TabLockView - Tab选择器（角标式）

**适用场景**：
- 频率加权选择（C计权、Z计权）
- 时间加权选择（慢速、脉冲）
- 任何Tab切换场景

**效果预览**：
```
┌─────────────────────────────────┐
│ [ A计权 ] [   C计权   ] [   Z计权   ] │
│            ↑ 悬浮提示             │
│            💎 解锁C计权 ›          │
└─────────────────────────────────┘
```

**使用示例**：
```typescript
import { TabLockView, isProMember } from '../membership/PremiumLockViews';

// 构建Tab时判断
@Builder
buildWeightingTab(weighting: WeightingType, displayName: string, isPremium: boolean) {
  if (isPremium && !isProMember()) {
    // 专业功能且非会员
    TabLockView({
      params: {
        featureId: `weighting_${weighting}`,
        featureName: displayName,
        featureDesc: '专业频率加权模式',
        unlockText: `解锁${displayName}`,
        onUpgrade: () => {
          // 升级后自动选中
        }
      }
    }) {
      // Tab内容（会置灰显示）
      Text(displayName)
    }
  } else {
    // 正常显示
    Text(displayName)
  }
}
```

---

### 3. FullScreenLockView - 核心功能（全屏引导式）

**适用场景**：
- 自动校准
- 频谱分析
- 任何核心付费功能

**效果预览**：
```
┌─────────────────────────────────┐
│  ▓▓░░▓▓▓░░▓▓▓▓░░▓░░           │ ← 模糊背景
│  ▓▓▓░▓▓▓▓░▓▓▓▓▓░▓▓░           │
│                                 │
│     ┌─────────────────┐        │
│     │       💎        │        │
│     │   智能自动校准   │        │
│     │  解锁高级功能   │        │
│     │                 │        │
│     │ 🎯 环境智能检测 │        │
│     │ 📊 实时噪声分析 │        │
│     │ ⚡ 一键自动校准 │        │
│     │                 │        │
│     │ [🎁 0.01元试用] │        │
│     └─────────────────┘        │
└─────────────────────────────────┘
```

**使用示例**：
```typescript
import { FullScreenLockView, isProMember } from '../membership/PremiumLockViews';

if (isProMember()) {
  // 专业版：正常功能
  this.buildMainButton()
} else {
  // 免费版：全屏锁定
  FullScreenLockView({
    params: {
      featureId: 'auto_calibration',
      featureName: '智能自动校准',
      featureDesc: '智能分析环境噪声，自动计算最佳校准值',
      previewItems: [
        { icon: '🎯', title: '环境智能检测', desc: '自动判断当前环境是否适合校准' },
        { icon: '📊', title: '实时噪声分析', desc: '实时监测环境噪声水平' },
        { icon: '⚡', title: '一键自动校准', desc: '无需手动计算，一键完成校准' }
      ],
      trialDays: 7,
      onUpgrade: () => {
        // 升级回调
      }
    }
  }) {
    // 背景预览内容（可选）
    Column() {
      // 功能预览UI
    }
  }
}
```

---

### 4. ListItemLockView - 列表项锁定（简洁角标式）

**适用场景**：
- 历史记录列表
- 任何列表项数量限制

**使用示例**：
```typescript
import { ListItemLockView } from '../membership/PremiumLockViews';

// 超过免费额度时
if (index >= 3 && !isProMember()) {
  ListItemLockView({
    params: {
      featureName: '记录',
      lockedCount: 47,
      totalCount: 50,
      onUpgrade: () => {}
    }
  }) {
    // 锁定项的占位内容
    Text('更多记录...')
  }
}
```

---

### 5. ProBadgeOnly - 仅显示PRO标签

**适用场景**：
- 仅作标记，不阻止使用
- 配合其他逻辑使用

**使用示例**：
```typescript
import { ProBadgeOnly } from '../membership/PremiumLockViews';

Row() {
  Text('高级功能')
  ProBadgeOnly({ size: 'small' })
}
```

---

## 已替换的文件

| 文件 | 原组件 | 新组件 | 场景 |
|------|--------|--------|------|
| AutoSaveSettingsDialog.ets | PremiumFeature | SettingLockView | 设置页开关 |
| FrequencyWeightingDialog.ets | PremiumFeature | TabLockView | Tab选择器 |
| ImprovedAutoCalibration.ets | PremiumFeature | FullScreenLockView | 核心功能 |

---

## 需要替换的其他文件

请按照以下模式替换剩余文件：

1. **TimeWeightingDialog.ets** - 使用 TabLockView
2. **EnhancedExposureContent.ets** - 根据场景选择 SettingLockView 或 FullScreenLockView
3. **DataAndAlertsContent.ets** - 使用 SettingLockView
4. **MeasurementPrecisionContent.ets** - 使用 TabLockView
5. **EnhancedThresholdManager.ets** - 使用 SettingLockView
6. **ExposureSummaryCard.ets** - 使用 ListItemLockView

---

## 迁移步骤

1. **修改 import**
   ```typescript
   // 旧
   import { PremiumFeature } from '../membership/PremiumFeature';
   
   // 新
   import { SettingLockView, isProMember } from '../membership/PremiumLockViews';
   ```

2. **添加条件判断**
   ```typescript
   if (isProMember()) {
     // 正常功能
   } else {
     // 锁定显示
   }
   ```

3. **选择合适的组件**
   - 设置类 → SettingLockView
   - Tab选择 → TabLockView
   - 核心功能 → FullScreenLockView
   - 列表限制 → ListItemLockView

---

## 优势对比

| 特性 | 旧 PremiumFeature | 新 PremiumLockViews |
|------|-------------------|---------------------|
| 交互方式 | 点击弹窗 | 直接引导 |
| 信息展示 | 弹窗内展示 | 场景内展示 |
| 视觉层次 | 统一处理 | 按场景优化 |
| 转化率 | 较低 | 更高 |
| 代码复杂度 | 封装复杂 | 简单直接 |

