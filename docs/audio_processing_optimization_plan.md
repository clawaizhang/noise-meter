# 音频处理优化技术方案

## 问题分析

当前音频处理流水线存在以下核心问题：

### 1. 重复的FFT分析器创建
- 每次音频回调都创建新的FFT分析器实例
- 导致大量对象创建和垃圾回收压力

### 2. 内存拷贝开销
- 频繁使用 `buffer.slice(0)` 进行内存拷贝
- 缺乏缓冲区重用机制

### 3. 计算分离
- 频谱计算和分贝计算分离，导致重复FFT计算
- 缺乏任务节流机制

## 优化方案

### 1. FFT分析器池化

#### 1.1 创建FFT分析器池

```typescript
// FFT分析器池管理类
export class FFTAnalyzerPool {
  private static instance: FFTAnalyzerPool;
  private analyzers: Map<string, FFTAnalyzer> = new Map();
  private configCache: Map<string, any> = new Map();
  
  static getInstance(): FFTAnalyzerPool {
    if (!FFTAnalyzerPool.instance) {
      FFTAnalyzerPool.instance = new FFTAnalyzerPool();
    }
    return FFTAnalyzerPool.instance;
  }
  
  getAnalyzer(config: AudioConfig): FFTAnalyzer {
    const key = this.generateConfigKey(config);
    
    if (!this.analyzers.has(key)) {
      const analyzer = new FFTAnalyzer(
        config.fftSize,
        config.windowType,
        config.smoothingFactor,
        config.overlap
      );
      this.analyzers.set(key, analyzer);
      console.info(`[FFT池] 创建新的分析器: ${key}`);
    }
    
    return this.analyzers.get(key)!;
  }
  
  private generateConfigKey(config: AudioConfig): string {
    return `${config.fftSize}_${config.windowType}_${config.smoothingFactor}_${config.overlap}`;
  }
  
  clearUnusedAnalyzers(): void {
    // 可以定期清理长时间未使用的分析器
    const now = Date.now();
    // 实现清理逻辑
  }
}
```

#### 1.2 优化后的音频处理回调

```typescript
// 优化后的音频处理逻辑
private async processAudioData(buffer: ArrayBuffer): Promise<void> {
  try {
    const config = AudioPresets.getConfig(this.pk.audio_analysis_mode);
    const analyzer = FFTAnalyzerPool.getInstance().getAnalyzer(config);
    
    // 使用并发任务计算频谱和分贝值
    const result = await taskpool.execute<[ArrayBuffer, WeightingType, number], AudioProcessingResult>(
      optimizedConcurrentCalculate,
      buffer,  // 不再进行内存拷贝
      this.pk.weighting_type,
      this.pk.calibration_value
    );
    
    // 更新UI状态
    this.onSpectrumData(result.spectrum);
    this.currentDecibel = result.decibel;
    
    // 其他处理逻辑...
    
  } catch (error) {
    console.error('[音频处理] 处理失败:', error);
  }
}
```

### 2. 内存管理优化

#### 2.1 环形缓冲区实现

```typescript
// 环形缓冲区类
export class CircularBuffer<T> {
  private buffer: T[];
  private head: number = 0;
  private tail: number = 0;
  private size: number;
  private count: number = 0;
  
  constructor(size: number) {
    this.size = size;
    this.buffer = new Array(size);
  }
  
  push(item: T): void {
    this.buffer[this.head] = item;
    this.head = (this.head + 1) % this.size;
    
    if (this.count < this.size) {
      this.count++;
    } else {
      this.tail = (this.tail + 1) % this.size;
    }
  }
  
  getItems(): T[] {
    const items: T[] = [];
    for (let i = 0; i < this.count; i++) {
      const index = (this.tail + i) % this.size;
      items.push(this.buffer[index]);
    }
    return items;
  }
  
  clear(): void {
    this.head = 0;
    this.tail = 0;
    this.count = 0;
  }
  
  getCount(): number {
    return this.count;
  }
}
```

#### 2.2 优化数据存储

```typescript
// 在AudioController中使用环形缓冲区
private timedValues: CircularBuffer<TimedDecibelValue> = new CircularBuffer(1000); // 限制1000个数据点
private timedAudioBuffers: CircularBuffer<TimedAudioBuffer> = new CircularBuffer(100); // 限制100个音频缓冲区
```

### 3. 并发任务优化

#### 3.1 优化的并发计算函数

```typescript
@Concurrent
export function optimizedConcurrentCalculate(
  buffer: ArrayBuffer,
  weightingType: WeightingType, 
  calibrationGain: number
): AudioProcessingResult {
  // 复用FFT分析器
  const config = getCurrentAudioConfig();
  const analyzer = getCachedFFTAnalyzer(config);
  
  // 一次性计算频谱和分贝值
  analyzer.setSystemGain(calibrationGain);
  const spectrum = analyzer.transform(buffer, weightingType);
  const weightedSpectrum = analyzer.applyWeighting(spectrum, weightingType);
  const decibel = analyzer.calculateAverageDb(weightedSpectrum);
  
  return {
    spectrum: weightedSpectrum,
    decibel: Math.round(decibel)
  };
}

interface AudioProcessingResult {
  spectrum: Float32Array;
  decibel: number;
}
```

### 4. 任务节流机制

#### 4.1 音频处理节流器

```typescript
// 音频处理节流器
export class AudioProcessingThrottler {
  private lastProcessTime: number = 0;
  private minInterval: number = 50; // 最小处理间隔50ms (20fps)
  private pendingProcess: (() => void) | null = null;
  
  constructor(private minIntervalMs: number = 50) {
    this.minInterval = minIntervalMs;
  }
  
  scheduleProcess(processFn: () => void): void {
    const now = Date.now();
    const elapsed = now - this.lastProcessTime;
    
    if (elapsed >= this.minInterval) {
      // 立即执行
      processFn();
      this.lastProcessTime = now;
      this.pendingProcess = null;
    } else {
      // 节流，保存最新的处理请求
      this.pendingProcess = processFn;
      
      // 设置延迟执行
      const delay = this.minInterval - elapsed;
      setTimeout(() => {
        if (this.pendingProcess) {
          this.pendingProcess();
          this.lastProcessTime = Date.now();
          this.pendingProcess = null;
        }
      }, delay);
    }
  }
}
```

#### 4.2 在AudioController中使用节流器

```typescript
private audioThrottler: AudioProcessingThrottler = new AudioProcessingThrottler(50);

// 优化后的音频处理回调
this.audioService.startProcessing((buffer: ArrayBuffer) => {
  this.audioThrottler.scheduleProcess(() => {
    this.processAudioData(buffer);
  });
});
```

### 5. 性能监控

#### 5.1 音频处理性能监控

```typescript
// 性能监控类
export class AudioPerformanceMonitor {
  private processTimes: number[] = [];
  private maxSamples: number = 100;
  
  recordProcessTime(startTime: number): void {
    const processTime = Date.now() - startTime;
    this.processTimes.push(processTime);
    
    // 保持最近100个样本
    if (this.processTimes.length > this.maxSamples) {
      this.processTimes.shift();
    }
  }
  
  getAverageProcessTime(): number {
    if (this.processTimes.length === 0) return 0;
    const sum = this.processTimes.reduce((a, b) => a + b, 0);
    return sum / this.processTimes.length;
  }
  
  getMaxProcessTime(): number {
    return Math.max(...this.processTimes);
  }
  
  isPerformanceDegraded(threshold: number = 100): boolean {
    return this.getAverageProcessTime() > threshold;
  }
}
```

## 实施步骤

### 第一阶段：核心优化（1-2天）
1. 实现FFT分析器池化
2. 添加环形缓冲区
3. 实现任务节流机制

### 第二阶段：性能监控（1天）
1. 添加性能监控
2. 实现预警机制
3. 测试优化效果

### 第三阶段：进一步优化（可选）
1. 零拷贝缓冲区优化
2. 更精细的任务调度
3. 内存使用优化

## 预期性能改进

### 量化指标
- **CPU使用率：** 预计降低40-60%
- **内存使用：** 减少50%以上的内存分配
- **响应时间：** 音频处理延迟降低70%
- **垃圾回收：** GC压力显著降低

### 用户体验改进
- 应用响应更流畅
- 减少卡顿和冻结
- 电池续航改善

## 风险评估

### 技术风险
- **兼容性问题：** 需要确保与现有音频配置兼容
- **性能回归：** 需要充分的性能测试

### 缓解措施
1. **渐进式部署** - 先在小范围测试
2. **性能基准测试** - 建立性能测试基准
3. **回滚机制** - 准备快速回滚方案

## 测试计划

### 性能测试
1. **CPU使用率测试** - 监控优化前后的CPU使用率
2. **内存使用测试** - 监控内存分配和泄漏
3. **响应时间测试** - 测量音频处理延迟
4. **压力测试** - 长时间运行测试稳定性

### 功能测试
1. **音频质量测试** - 确保音频处理质量不受影响
2. **配置兼容性测试** - 测试不同音频配置
3. **边界条件测试** - 测试极端情况下的表现

## 结论

通过系统性的优化，可以显著改善音频处理性能，解决当前应用的主要性能瓶颈。建议按照本方案分阶段实施，优先解决最严重的性能问题。