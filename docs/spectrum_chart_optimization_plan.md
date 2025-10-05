# 频谱图优化计划

## 当前问题分析

### 当前实现
- **图表类型**：柱状图（8个频段）
- **数据点**：只有8个数据点
- **视觉效果**：不真实的频谱显示

### 目标要求
- **图表类型**：折线图
- **数据点**：模拟20Hz-20kHz的真实频谱（约20000个点）
- **频谱特性**：
  - 低频：平稳上升
  - 中频：达到峰值
  - 高频：逐渐下降
  - 连续性：平滑过渡，不能剧烈跳动

## 技术实现方案

### 1. 频谱数据生成算法

#### 对数频率分布
```typescript
// 生成对数分布的频率点（20Hz - 20kHz）
private generateLogFrequencies(count: number): number[] {
  const frequencies: number[] = [];
  const minFreq = 20;  // 20Hz
  const maxFreq = 20000; // 20kHz
  
  for (let i = 0; i < count; i++) {
    // 对数分布，更符合人耳感知
    const logMin = Math.log10(minFreq);
    const logMax = Math.log10(maxFreq);
    const logFreq = logMin + (logMax - logMin) * i / (count - 1);
    frequencies.push(Math.pow(10, logFreq));
  }
  return frequencies;
}
```

#### 频谱幅度模拟
```typescript
// 模拟真实频谱特性
private generateSpectrumAmplitude(frequency: number): number {
  // 低频区域（20Hz - 200Hz）：平稳上升
  if (frequency < 200) {
    return 0.2 + 0.3 * (frequency - 20) / 180;
  }
  
  // 中频区域（200Hz - 4000Hz）：达到峰值
  if (frequency < 4000) {
    const midRange = (frequency - 200) / 3800;
    return 0.5 + 0.4 * Math.sin(midRange * Math.PI);
  }
  
  // 高频区域（4000Hz - 20000Hz）：逐渐下降
  const highRange = (frequency - 4000) / 16000;
  return 0.9 - 0.7 * highRange;
}
```

### 2. 折线图绘制实现

#### 数据点采样优化
```typescript
// 由于20000个点太多，进行智能采样
private sampleSpectrumData(fullData: Float32Array, canvasWidth: number): Float32Array {
  const sampleCount = Math.min(canvasWidth, 1000); // 最多1000个点
  const sampledData = new Float32Array(sampleCount);
  const step = Math.floor(fullData.length / sampleCount);
  
  for (let i = 0; i < sampleCount; i++) {
    const start = i * step;
    const end = Math.min((i + 1) * step, fullData.length);
    
    // 取区间内的最大值，避免细节丢失
    let maxVal = 0;
    for (let j = start; j < end; j++) {
      maxVal = Math.max(maxVal, fullData[j]);
    }
    sampledData[i] = maxVal;
  }
  return sampledData;
}
```

#### 平滑曲线绘制
```typescript
// 使用贝塞尔曲线绘制平滑频谱
private drawSmoothSpectrum(canvas: CanvasRenderingContext2D, data: Float32Array): void {
  const width = canvas.width;
  const height = canvas.height;
  
  canvas.clearRect(0, 0, width, height);
  
  // 绘制背景网格
  this.drawSpectrumGrid(canvas, width, height);
  
  // 绘制频谱曲线
  canvas.beginPath();
  canvas.strokeStyle = '#007AFF';
  canvas.lineWidth = 2;
  
  const pointSpacing = width / (data.length - 1);
  
  for (let i = 0; i < data.length; i++) {
    const x = i * pointSpacing;
    const y = height - data[i] * height * 0.8;
    
    if (i === 0) {
      canvas.moveTo(x, y);
    } else {
      // 使用简单的线段连接，保持性能
      canvas.lineTo(x, y);
    }
  }
  
  canvas.stroke();
  
  // 添加渐变填充
  this.drawSpectrumFill(canvas, data, width, height);
}
```

### 3. 动画效果优化

#### 频谱动态变化
```typescript
// 模拟频谱的动态变化
private animateSpectrumVariation(baseData: Float32Array, time: number): Float32Array {
  const animatedData = new Float32Array(baseData.length);
  const timeFactor = time * 0.001;
  
  for (let i = 0; i < baseData.length; i++) {
    const freq = this.frequencies[i];
    
    // 低频缓慢变化
    const lowFreqMod = freq < 1000 ? Math.sin(timeFactor * 0.5 + i * 0.01) * 0.1 : 0;
    
    // 中频适度变化
    const midFreqMod = freq >= 1000 && freq < 8000 ? 
      Math.sin(timeFactor * 2 + i * 0.05) * 0.15 : 0;
    
    // 高频快速变化
    const highFreqMod = freq >= 8000 ? 
      Math.sin(timeFactor * 5 + i * 0.1) * 0.08 : 0;
    
    animatedData[i] = Math.max(0, Math.min(1, 
      baseData[i] + lowFreqMod + midFreqMod + highFreqMod
    ));
  }
  
  return animatedData;
}
```

## 实施步骤

### 1. 修改AdvancedFeaturesPage组件
- 替换当前的柱状图绘制逻辑
- 实现对数频率分布
- 添加频谱幅度模拟算法
- 优化数据点采样

### 2. 性能优化
- 使用智能采样减少绘制点数
- 优化动画帧率
- 添加缓存机制

### 3. 视觉效果增强
- 添加频谱填充渐变
- 优化网格和坐标轴
- 添加频率标注

## 预期效果

### 频谱特性
- **低频（20-200Hz）**：平稳上升，幅度0.2-0.5
- **中频（200-4000Hz）**：达到峰值0.5-0.9，有适度波动
- **高频（4000-20000Hz）**：逐渐下降至0.2-0.3

### 视觉表现
- **平滑曲线**：连续的折线，无剧烈跳动
- **真实感**：模拟真实音频频谱特性
- **动态效果**：不同频段有不同的变化速度
- **专业外观**：符合专业音频分析工具的标准

这个方案将把当前的简单柱状图升级为专业的频谱分析显示，更符合"专业噪音分析工具"的定位。