# 主页和仪表盘优化计划

## 优化目标
解决当前分配值在主页和仪表盘重复显示的问题，实现信息层级差异化。

## 具体优化方案

### 1. 主页优化（已完成分析）
- ✅ 功能卡片已实现差异化显示：
  - 仪表盘卡片：显示趋势变化（↗ +2.5dB）
  - 警报卡片：显示活跃警报状态
  - 影响卡片：显示暴露风险等级
  - 历史卡片：显示最近记录时间

### 2. 仪表盘优化（待实现）
- 弱化当前分贝值显示：
  - 字体大小：从64px改为48px
  - 文件位置：`entry/src/main/ets/components/decibel-meter/DecibelDisplayComponent.ets`
  - 修改位置：第192行 `fontSize(64)` 改为 `fontSize(48)`

### 3. 代码修改详情

#### 仪表盘分贝显示组件修改
```typescript
// 修改前：
Text(`${config.currentDecibel}dB`)
  .fontSize(64)
  .fontWeight(FontWeight.Bold)
  .fontColor($r('sys.color.alert'))

// 修改后：
Text(`${config.currentDecibel}dB`)
  .fontSize(48)  // 从64px改为48px
  .fontWeight(FontWeight.Bold)
  .fontColor($r('sys.color.alert'))
```

## 预期效果
- 主页：保持大字体分贝值作为核心监控指标
- 仪表盘：弱化当前分贝值，强化数据分析功能
- 消除信息重复，提升用户体验

## 下一步
需要切换到Code模式执行具体的代码修改。