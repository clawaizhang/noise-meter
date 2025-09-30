# 频谱图组件重构计划

## 概述
将 DecibelMeter.ets 中的频谱图功能分离为独立的 SpectrumChartComponent 组件。

## 当前频谱图代码结构

### 主要组件部分
1. **SpectrumView** (第153-164行) - 频谱图容器
2. **SpectrumChart** (第166-215行) - Canvas频谱图表
3. **drawSpectrumLocal** (第465-470行) - 频谱绘制方法

### 依赖的属性
- `canvasWidth` / `canvasHeight` - Canvas尺寸
- `canvasContext` - Canvas上下文
- `fft_size` - FFT大小（计算属性）
- `sampleRate` - 采样率
- `isDisplayApp` - 显示状态控制
- `sysResourceManager` - 资源管理器

### 外部依赖
- `drawSpectrum` 函数（来自 DrawSpectrum.ets）
- `getDbSteps` / `getFrequencySteps` 函数
- `concurrentCalculateSpectrum` 函数
- `AppKeys` 和 `AppStorageV2` 用于峰值频率存储

## 新组件设计

### SpectrumChartComponent.ets 接口
```typescript
@ComponentV2
export struct SpectrumChartComponent {
  // 输入参数
  @Param spectrumData: Float32Array = new Float32Array()
  @Param fftSize: number = 1024
  @Param sampleRate: number = 44100
  @Param isDisplayApp: boolean = true
  @Param showTouShuButton: boolean = false
  
  // 本地状态
  @Local private canvasWidth: number = 0
  @Local private canvasHeight: number = 0
  @Local private canvasContext: CanvasRenderingContext2D
  
  // 依赖注入
  @Local private sysResourceManager: resourceManager.ResourceManager
  @Local private as: AppKeys = AppStorageV2.connect(AppKeys)!
  
  // 常量
  private readonly ASPECT_RATIO: number = 1.5
  private canvasSettings: RenderingContextSettings
}
```

### 需要导入的依赖
```typescript
import { AppStorageV2, curves, promptAction } from '@kit.ArkUI';
import display from '@ohos.display';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { drawSpectrum, getDbSteps, getFrequencySteps } from './DrawSpectrum';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
```

## 重构步骤

### 1. 创建 SpectrumChartComponent.ets
- 创建新文件：`entry/src/main/ets/components/decibel-meter/SpectrumChartComponent.ets`
- 复制所有频谱图相关代码
- 添加必要的导入语句
- 实现响应式Canvas尺寸计算

### 2. 从 DecibelMeter.ets 中移除频谱图代码
- 删除 `SpectrumView` @Builder
- 删除 `SpectrumChart` @Builder  
- 删除 `drawSpectrumLocal` 方法
- 删除相关的Canvas属性

### 3. 更新 DecibelMeter.ets 使用新组件
- 导入 SpectrumChartComponent
- 在 build() 方法中替换 SpectrumView() 调用
- 传递必要的参数：spectrumData, fftSize, sampleRate 等

### 4. 保留的功能
- ✅ 点击展开对话框功能
- ✅ 响应式布局
- ✅ 所有现有样式和动画
- ✅ 投诉按钮（可选显示）
- ✅ 峰值频率计算和显示

## 文件变更清单

### 需要创建的文件
- `entry/src/main/ets/components/decibel-meter/SpectrumChartComponent.ets`

### 需要修改的文件
- `entry/src/main/ets/components/decibel-meter/DecibelMeter.ets`

## 验证要点
1. 频谱图显示正常
2. 点击展开功能正常工作
3. 响应式布局正确
4. 峰值频率计算准确
5. 所有样式保持一致