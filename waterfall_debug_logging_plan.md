# 瀑布图调试日志方案

## 问题描述
瀑布图绘制出现白色屏幕闪烁，无法正常显示频谱数据。

## 关键问题点分析

### 1. 数据流问题
- 频谱数据可能没有正确传递到绘制函数
- WaterfallData.spectrumHistory可能为空或数据格式不正确
- 数据更新监听可能失效

### 2. Canvas和渲染器问题
- Canvas上下文可能未正确初始化
- ImageData渲染器初始化失败
- 像素数据设置失败

### 3. 并行计算问题
- taskpool执行可能失败
- 颜色映射生成失败
- 帧数据处理返回空结果

### 4. 颜色映射问题
- 颜色映射配置不正确
- 透明度设置问题
- 颜色值计算错误

## 调试日志添加方案

### 1. DrawWaterfall.ets 关键日志点

#### 主绘制函数 (drawWaterfall)
```typescript
// 在函数开始处添加详细日志
console.info(`[瀑布图调试] 开始绘制，画布尺寸: ${canvasWidth}x${canvasHeight}`);
console.info(`[瀑布图调试] 数据帧数: ${waterfallData.spectrumHistory.length}`);
console.info(`[瀑布图调试] 颜色映射配置:`, JSON.stringify(waterfallData.colorMap));

// 检查数据有效性
if (waterfallData.spectrumHistory.length > 0) {
  const firstFrame = waterfallData.spectrumHistory[0];
  console.info(`[瀑布图调试] 第一帧数据长度: ${firstFrame.length}`);
  console.info(`[瀑布图调试] 第一帧数据范围: ${Math.min(...firstFrame)} ~ ${Math.max(...firstFrame)}`);
}
```

#### ImageData渲染器初始化
```typescript
// 在initialize方法中添加日志
console.info(`[ImageData调试] 初始化渲染器，尺寸: ${width}x${height}`);
console.info(`[ImageData调试] ImageData创建状态: ${this.imageData ? '成功' : '失败'}`);
console.info(`[ImageData调试] 数据缓冲区状态: ${this.data ? '成功' : '失败'}`);
```

#### 并行计算流程
```typescript
// 在drawWaterfallDataWithParallel中添加日志
console.info(`[并行计算调试] 开始并行处理 ${spectrumHistory.length} 帧数据`);
console.info(`[并行计算调试] 颜色映射参数: type=${colorMapConfig.colorMapType}, minDb=${colorMapConfig.minDb}, maxDb=${colorMapConfig.maxDb}`);

// 检查并行计算结果
console.info(`[并行计算调试] 处理后的帧数: ${processedFrames?.length || 0}`);
if (processedFrames && processedFrames.length > 0) {
  console.info(`[并行计算调试] 第一处理帧包含 ${processedFrames[0].bins?.length || 0} 个bin`);
}
```

#### 像素绘制流程
```typescript
// 在drawProcessedFrames中添加日志
console.info(`[像素绘制调试] 开始绘制 ${processedFrames.length} 个处理帧`);
console.info(`[像素绘制调试] ImageData渲染器状态: ${imageDataRenderer ? '已初始化' : '未初始化'}`);

let totalPixels = 0;
for (const frame of processedFrames) {
  if (frame && frame.bins) {
    totalPixels += frame.bins.length;
  }
}
console.info(`[像素绘制调试] 总像素数: ${totalPixels}`);
```

### 2. WaterfallData.ets 数据流日志

#### 数据添加流程
```typescript
// 在addSpectrumFrame中添加日志
console.info(`[数据流调试] 添加频谱帧，原始长度: ${spectrum.length}`);
console.info(`[数据流调试] 数据有效性: ${this.isValidSpectrum(spectrum) ? '有效' : '无效'}`);
console.info(`[数据流调试] 处理后长度: ${processedSpectrum.length}`);
console.info(`[数据流调试] 压缩比例: ${currentCompressionRatio}`);
console.info(`[数据流调试] 添加后历史大小: ${newHistory.length}`);
```

### 3. WaterfallChartComponent.ets 组件日志

#### 绘制函数
```typescript
// 在drawWaterfallChart中添加日志
console.info(`[组件调试] 开始绘制瀑布图`);
console.info(`[组件调试] 数据状态: ${waterfallData.spectrumHistory.length > 0 ? '有数据' : '无数据'}`);
console.info(`[组件调试] 绘制间隔: ${now - this.lastDrawTime}ms`);
console.info(`[组件调试] 绘制配置:`, JSON.stringify(drawConfig));
```

### 4. 错误处理和性能监控

#### 错误处理日志
```typescript
// 在catch块中添加详细错误信息
console.error(`[错误调试] 绘制失败:`, error);
console.error(`[错误调试] 错误堆栈:`, (error as Error).stack);
console.error(`[错误调试] 错误类型:`, typeof error);
```

#### 性能监控日志
```typescript
// 添加性能计时
const startTime = Date.now();
// ... 绘制代码 ...
const endTime = Date.now();
console.info(`[性能调试] 绘制耗时: ${endTime - startTime}ms`);
```

## 实施步骤

1. **切换到Code模式**来修改源代码文件
2. **按照上述方案添加调试日志**
3. **运行应用并观察控制台输出**
4. **根据日志定位具体问题**
5. **修复发现的问题**
6. **移除或注释掉调试日志**

## 预期问题定位

通过添加这些日志，我们可以定位：

- 数据是否正常传递
- 哪个环节出现失败
- 性能瓶颈在哪里
- 具体的错误原因

## 下一步行动

请切换到Code模式来实施这些调试日志的添加。