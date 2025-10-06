# 双管线架构重构清单

## 需要重构的状态变量和组件

### 1. 音频控制的状态变量（需要分离）

#### 1.1 实时分贝值 (db)
- **当前位置**：`AudioController.ets:399` - `this.ak.db = currentDb;`
- **影响组件**：
  - `DecibelDisplayComponent.ets` - 主分贝显示
  - `AlertsContent.ets` - 警报状态显示
  - `AudioAnalysisSettingsNavigation.ets` - 校准界面
  - `AlertsSettingsNavigation.ets` - 警报设置界面
  - `NoiseStandardDialogNavigation.ets` - 噪音标准对话框
  - `NoiseDescriptionDialogNavigation.ets` - 噪音描述对话框

#### 1.2 频谱数据 (spectrumData)
- **当前位置**：`DecibelMeter.ets:60` - `this.as.spectrumData = spectrum;`
- **影响组件**：
  - `SpectrumChartComponent.ets` - 频谱图显示
  - `DrawSpectrum.ets` - 频谱绘制

#### 1.3 峰值频率 (peakFreq)
- **当前位置**：`DrawSpectrum.ets:269` - `AppStorageV2.connect(AppKeys)!.peakFreq = peakFreq;`
- **影响组件**：
  - 频谱分析相关组件

### 2. 需要重构的组件清单

#### 2.1 核心显示组件
- [ ] `DecibelDisplayComponent.ets` - 主分贝显示
- [ ] `SpectrumChartComponent.ets` - 频谱图
- [ ] `DrawSpectrum.ets` - 频谱绘制

#### 2.2 设置界面组件
- [ ] `AudioAnalysisSettingsNavigation.ets` - 音频分析设置
- [ ] `AlertsSettingsNavigation.ets` - 警报设置
- [ ] `AlertsContent.ets` - 警报内容

#### 2.3 对话框组件
- [ ] `NoiseStandardDialogNavigation.ets` - 噪音标准
- [ ] `NoiseDescriptionDialogNavigation.ets` - 噪音描述

### 3. 状态模型重构清单

#### 3.1 创建新的状态模型
- [ ] `DataProcessingState.ets` - 数据处理状态
- [ ] `UIDisplayState.ets` - UI显示状态
- [ ] `StatisticsData.ets` - 统计数据对象

#### 3.2 更新AppScope配置
- [ ] 在`AppScope/app.json5`中注册新状态模型

### 4. AudioController重构清单

#### 4.1 状态变量分离
- [ ] 添加`DataProcessingState`和`UIDisplayState`引用
- [ ] 修改`updateStatistics`方法，分离数据处理和UI更新
- [ ] 添加后台检测逻辑

#### 4.2 生命周期控制
- [ ] 添加`pauseUIUpdates()`方法
- [ ] 添加`resumeUIUpdates()`方法
- [ ] 添加`isBackground`状态检测

### 5. 组件绑定重构清单

#### 5.1 状态绑定更新
- [ ] 将所有`@Local as: AppKeys = AppStorageV2.connect(AppKeys)!`改为`@Local uiState: UIDisplayState = AppStorageV2.connect(UIDisplayState)!`
- [ ] 更新所有状态变量引用：
  - `as.db` → `uiState.displayDb`
  - `as.spectrumData` → `uiState.displaySpectrumData`
  - `as.peakFreq` → `uiState.displayPeakFreq`

#### 5.2 监听器更新
- [ ] 更新所有`@Monitor('as.db')`为`@Monitor('uiState.displayDb')`
- [ ] 更新所有`@Monitor('as.spectrumData')`为`@Monitor('uiState.displaySpectrumData')`

### 6. 生命周期管理重构清单

#### 6.1 EntryAbility更新
- [ ] 在`onBackground()`中调用`AudioControllerService.getInstance().pauseUIUpdates()`
- [ ] 在`onForeground()`中调用`AudioControllerService.getInstance().resumeUIUpdates()`

#### 6.2 Index.ets更新
- [ ] 更新显示状态管理逻辑

### 7. 测试和验证清单

#### 7.1 功能测试
- [ ] 测试前后台切换功能
- [ ] 验证数据统计连续性
- [ ] 验证UI更新正确性

#### 7.2 性能测试
- [ ] 测试后台内存使用
- [ ] 测试应用恢复速度
- [ ] 验证无UI刷新事件积压

### 8. 一次性迁移策略

#### 8.1 准备阶段
1. 创建功能分支：`feature/dual-pipeline-refactor`
2. 备份当前稳定版本
3. 创建详细的迁移计划

#### 8.2 实施阶段（一次性完成）
1. 创建新的状态模型（DataProcessingState、UIDisplayState、StatisticsData）
2. 改造AudioController，实现双管线逻辑
3. 更新所有8个核心组件，绑定到UIDisplayState
4. 更新EntryAbility生命周期管理
5. 删除不再使用的AppKeys相关代码

#### 8.3 测试验证阶段
1. 全面功能测试
2. 性能测试（前后台切换）
3. 问题修复和优化

### 9. 风险控制措施

#### 9.1 Git版本控制
- [ ] 在重构前创建功能分支
- [ ] 每个重构步骤都提交清晰的commit
- [ ] 出现问题时可快速回滚到重构前状态

#### 9.2 监控机制
- [ ] 添加详细的迁移日志
- [ ] 监控状态同步状态
- [ ] 监控UI更新频率

### 10. 预期重构效果

#### 10.1 性能提升
- 后台无UI刷新事件积压
- 应用恢复速度提升
- 内存使用优化

#### 10.2 功能保持
- 数据统计连续性
- UI显示正确性
- 用户体验一致性

这个重构清单涵盖了所有需要重构的地方，确保双管线架构能够完整实施并解决后台UI刷新事件积压的问题。