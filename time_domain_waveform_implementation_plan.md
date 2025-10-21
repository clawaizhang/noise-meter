# 时域波形图实现计划

## 项目概述
将当前的分贝仪表盘改造为显示多种实时声学分析图表，首先实现时域波形图。

## 当前架构分析

### 数据流
- **频谱图**：通过 `ak.uiDisplayState.displaySpectrumData` 获取FFT处理后的频谱数据
- **时域波形图**：需要从 `originAudioBuffers` 获取原始音频数据

### 关键文件
- [`UIDisplayState.ets`](entry/src/main/ets/models/UIDisplayState.ets) - UI显示状态管理
- [`AudioController.ets`](entry/src/main/ets/components/decibel-meter/AudioController.ets) - 音频数据处理
- [`SpectrumChartComponent.ets`](entry/src/main/ets/components/decibel-meter/SpectrumChartComponent.ets) - 频谱图组件
- [`DecibelMeter.ets`](entry/src/main/ets/components/decibel-meter/DecibelMeter.ets) - 主仪表盘组件

## 实现步骤

### 1. 在UIDisplayState中添加时域数据字段
**文件**: `entry/src/main/ets/models/UIDisplayState.ets`

```typescript
// 在UIDisplayState类中添加
@Trace displayTimeDomainData: number[] = [];
```

### 2. 在AudioController中同步时域数据
**文件**: `entry/src/main/ets/components/decibel-meter/AudioController.ets`

在音频处理回调中同步原始音频数据到UI状态：
```typescript
// 在startProcessing回调中添加时域数据同步
this.audioService.startProcessing((buffer: ArrayBuffer) => {
  // 现有频谱处理代码...
  
  // 新增时域数据处理
  const timeDomainData = this.processTimeDomainData(buffer);
  this.ak.uiDisplayState.displayTimeDomainData = timeDomainData;
});
```

### 3. 创建时域波形图绘制函数
**文件**: `entry/src/main/ets/components/decibel-meter/DrawTimeDomain.ets`

创建类似DrawSpectrum的绘制函数：
```typescript
export function drawTimeDomain(
  canvasContext: CanvasRenderingContext2D,
  canvasWidth: number,
  canvasHeight: number,
  timeDomainData: number[],
  sysResourceManager: resourceManager.ResourceManager
): void {
  // 绘制时域波形图的实现
}
```

### 4. 实现时域波形图组件
**文件**: `entry/src/main/ets/components/decibel-meter/TimeDomainChartComponent.ets`

创建类似SpectrumChartComponent的组件：
```typescript
@ComponentV2
export struct TimeDomainChartComponent {
  // 组件实现，监听displayTimeDomainData并调用drawTimeDomain
}
```

### 5. 修改主仪表盘布局
**文件**: `entry/src/main/ets/components/decibel-meter/DecibelMeter.ets`

在Grid布局中添加时域波形图组件：
```typescript
// 在频谱图组件后添加时域波形图
GridCol({
  span: {
    xs: 12,
    sm: 12,
    md: 6,
    lg: 6,
    xl: 6
  }
}) {
  TimeDomainChartComponent()
}
```

## 技术细节

### 时域数据处理
- 从原始音频缓冲区提取样本数据
- 归一化到[-1, 1]范围
- 降采样以适应Canvas绘制性能

### 绘制优化
- 使用Path2D进行批量绘制
- 实现平滑动画效果
- 响应式Canvas尺寸

### 性能考虑
- 限制数据点数量避免过度绘制
- 使用requestAnimationFrame进行动画
- 后台时暂停UI更新

## 测试计划
1. 验证时域数据同步正确性
2. 测试波形图绘制性能
3. 验证响应式布局
4. 测试内存使用情况

## 后续扩展
- 添加波形图缩放功能
- 实现多通道波形显示
- 添加波形录制和回放