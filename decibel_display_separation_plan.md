# 分贝显示组件分离计划

## 项目概述
将 [`DecibelMeter.ets`](entry/src/main/ets/components/decibel-meter/DecibelMeter.ets) 中的分贝值显示和录音功能分离，创建独立的 [`DecibelDisplayComponent.ets`](entry/src/main/ets/components/decibel-meter/DecibelDisplayComponent.ets) 组件。

## 当前架构问题
- [`DecibelMeter`](entry/src/main/ets/components/decibel-meter/DecibelMeter.ets) 组件职责过多
- 录音逻辑和显示逻辑耦合紧密
- 难以复用分贝显示功能

## 分离方案

### 1. 新组件设计

#### DecibelDisplayComponent.ets
```typescript
@ComponentV2
export struct DecibelDisplayComponent {
  // 输入参数
  @Prop audioBuffer: ArrayBuffer = new ArrayBuffer(0)
  @Prop audioAnalysisMode: AudioAnalysisMode = AudioAnalysisMode.FAST_TIME_WEIGHTING
  @Prop weightingType: WeightingType = WeightingType.A
  @Prop calibrationValue: number = 0
  @Prop noiseThreshold: number = 80
  @Prop noiseAlarmEnabled: boolean = true
  @Prop isDisplayApp: boolean = true
  
  // 内部状态
  @Local private currentDecibel: number = 0
  @Local private minDecibel: number = 0
  @Local private maxDecibel: number = 0
  @Local private avgDecibel: number = 0
  @Local private isNoiseAlarm: boolean = false
  @Local private showAvgInsteadOfMin: boolean = true
  
  // 服务实例
  private statisticsService: StatisticsService = new StatisticsService()
  private statisticsSubscription?: Subscription
  private alarmSubscription?: Subscription
  
  // 构建器方法
  @Builder CurrentDecibel() { /* 当前分贝显示 */ }
  @Builder averageMin() { /* 平均/最小值显示 */ }
  @Builder max() { /* 最大值显示 */ }
  @Builder noiseDescriptions() { /* 噪音描述 */ }
  @Builder noiseCalibration() { /* 校准信息 */ }
}
```

### 2. 重构步骤

#### 步骤1：创建新组件
- 创建 [`DecibelDisplayComponent.ets`](entry/src/main/ets/components/decibel-meter/DecibelDisplayComponent.ets)
- 复制相关构建器方法
- 实现分贝计算和统计逻辑

#### 步骤2：重构 DecibelMeter
- 移除分贝显示相关的状态变量
- 移除统计服务订阅逻辑
- 移除相关的构建器方法
- 更新 build() 方法使用新组件

#### 步骤3：数据流调整
- 主组件传递音频缓冲区到显示组件
- 显示组件独立处理统计计算
- 保持报警功能正常工作

### 3. 文件依赖关系

#### 需要导入的模块：
- `../../services/StatisticsService.ets`
- `../../utils/FFTAnalyzer.ets`
- `../../concurrent/ConcurrentFftAnalyzer.ets`
- `../../common/AudioConfig.ets`
- `../../constants/WeightingConstants.ets`
- `../../services/DecibelService.ets`

### 4. 接口设计

#### 输入参数接口：
```typescript
interface DecibelDisplayConfig {
  audioAnalysisMode: AudioAnalysisMode
  weightingType: WeightingType
  calibrationValue: number
  noiseThreshold: number
  noiseAlarmEnabled: boolean
  isDisplayApp: boolean
}
```

### 5. 迁移清单

#### 从 DecibelMeter 迁移到 DecibelDisplayComponent：
- [ ] `CurrentDecibel()` 构建器
- [ ] `averageMin()` 构建器
- [ ] `max()` 构建器
- [ ] `noiseDescriptions()` 构建器
- [ ] `noiseCalibration()` 构建器
- [ ] 统计状态变量
- [ ] 统计服务订阅逻辑
- [ ] 分贝计算逻辑

#### 保留在 DecibelMeter：
- [ ] 录音功能
- [ ] 音频服务管理
- [ ] 位置服务
- [ ] 记录保存
- [ ] 手电筒控制
- [ ] 操作面板

## 预期收益
1. **更好的代码组织**：职责分离，单一职责原则
2. **更高的可复用性**：分贝显示组件可在其他地方使用
3. **更易维护**：修改显示逻辑不影响录音功能
4. **更好的测试性**：可以独立测试分贝显示功能

## 风险与缓解
- **风险**：数据流中断导致显示不更新
- **缓解**：确保音频缓冲区正确传递
- **风险**：统计计算不一致
- **缓解**：充分测试统计功能

## 下一步
切换到 Code 模式实现具体代码修改。