# 自定义音频分析模式实现计划

## 设计调整说明

根据用户反馈，对设计方案进行以下调整：

1. **移除保存功能**：配置修改后立即自动保存
2. **保留重置功能**：提供重置到默认值的按钮
3. **替换窗函数覆盖功能**：新的自定义模式完全替代原有的窗函数覆盖功能

## 实现步骤

### 1. 扩展AudioAnalysisMode枚举
```typescript
// 在AudioConfig.ets中添加
export enum AudioAnalysisMode {
  FAST_TIME_WEIGHTING = 'FAST_TIME_WEIGHTING',
  SLOW_TIME_WEIGHTING = 'SLOW_TIME_WEIGHTING', 
  IMPULSE_TIME_WEIGHTING = 'IMPULSE_TIME_WEIGHTING',
  CUSTOM_TIME_WEIGHTING = 'CUSTOM_TIME_WEIGHTING' // 新增自定义模式
}
```

### 2. 创建自定义配置存储管理
- 使用AppStorageV2存储自定义配置
- 提供默认的自定义配置值
- 实现配置的自动保存机制

### 3. 设计自定义配置UI组件
- 包含所有可配置参数的输入控件
- 实时显示技术参数
- 提供重置默认值按钮

### 4. 修改音频分析对话框
- 添加自定义模式开关
- 实现界面切换逻辑
- 集成自定义配置组件

### 5. 更新AudioPresets.getConfig方法
- 支持自定义模式配置
- 移除窗函数覆盖参数
- 确保向后兼容性

### 6. 更新并发计算函数
- 支持自定义模式参数
- 移除窗函数覆盖相关代码

### 7. 移除窗函数覆盖功能
- 删除PreferenceKeys中的窗函数覆盖设置项
- 删除相关的UI组件引用
- 清理相关代码

## 技术实现细节

### 自定义配置存储结构
```typescript
export interface CustomAudioConfig extends AudioAnalysisConfig {
  isEnabled: boolean; // 是否启用自定义模式
}

// 默认自定义配置
export const DEFAULT_CUSTOM_CONFIG: AudioAnalysisConfig = {
  fftSize: 2048,
  updateInterval: 200,
  smoothingFactor: 0.2,
  windowType: WindowType.HANNING,
  overlap: 0.4,
  bufferSize: 4096
};
```

### 界面切换逻辑
```typescript
// 自定义模式开关状态管理
@Local isCustomModeEnabled: boolean = false;

// 界面渲染逻辑
if (this.isCustomModeEnabled) {
  // 显示自定义配置界面
  this.buildCustomModeInterface();
} else {
  // 显示标准模式界面
  this.buildStandardModeInterface();
}
```

### 配置自动保存机制
```typescript
// 配置变化时自动保存
private handleConfigChange(config: AudioAnalysisConfig) {
  // 更新本地状态
  this.customConfig = config;
  
  // 自动保存到AppStorage
  AppStorageV2.setOrCreate('custom_audio_config', config);
  
  // 立即应用配置
  this.applyCustomConfig();
}
```

### 重置功能实现
```typescript
// 重置到默认值
private resetToDefault() {
  this.customConfig = { ...DEFAULT_CUSTOM_CONFIG };
  
  // 自动保存
  AppStorageV2.setOrCreate('custom_audio_config', this.customConfig);
  
  // 更新界面
  this.updateDisplay();
}
```

## 代码清理计划

### 需要移除的窗函数覆盖功能
1. **PreferenceKeys.ets**：
   - `window_function_override_enabled`
   - `window_function_override_type`

2. **AudioConfig.ets**：
   - `getConfig()`方法中的`overrideWindowType`参数
   - 相关的窗函数覆盖逻辑

3. **音频分析对话框**：
   - 窗函数设置区域
   - 相关的状态变量和逻辑

4. **并发计算函数**：
   - 窗函数覆盖参数传递

## 测试验证计划

### 功能测试
1. 自定义模式开关正常工作
2. 配置参数实时生效
3. 重置功能正常工作
4. 配置自动保存
5. 界面切换流畅

### 兼容性测试
1. 标准模式不受影响
2. 现有数据兼容
3. 性能表现正常

### 用户体验测试
1. 界面响应及时
2. 操作流程顺畅
3. 配置变化直观可见

## 风险评估与缓解

### 风险1：配置数据丢失
- **缓解**：使用AppStorageV2确保数据持久化
- **备份**：提供默认配置值

### 风险2：界面切换性能
- **缓解**：优化状态管理，避免不必要的重渲染
- **测试**：在不同设备上测试界面响应性

### 风险3：向后兼容性
- **缓解**：保持标准模式功能不变
- **测试**：验证现有功能不受影响

## 实施时间表

1. **第1阶段**：核心功能实现（2天）
   - 扩展枚举和配置存储
   - 创建自定义配置组件
   - 修改音频分析对话框

2. **第2阶段**：功能集成（1天）
   - 更新AudioPresets和并发计算函数
   - 实现配置自动保存

3. **第3阶段**：清理和测试（1天）
   - 移除窗函数覆盖功能
   - 功能测试和优化

这个实现计划确保了自定义音频分析模式的顺利开发，同时保持了系统的稳定性和用户体验。