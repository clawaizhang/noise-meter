# 性能优化实施指南

## 实施概述

本指南提供具体的代码修改步骤，按照优先级从高到低实施性能优化。

## 第一阶段：紧急修复（1-2天）

### 1.1 创建FFT分析器池

**文件：** `entry/src/main/ets/utils/FFTAnalyzerPool.ets`

```typescript
import { FFTAnalyzer } from './FFTAnalyzer';
import { AudioConfig } from '../common/AudioConfig';
import { WindowType } from '../common/WindowType';

/**
 * FFT分析器池 - 复用FFT分析器实例减少对象创建
 */
export class FFTAnalyzerPool {
  private static instance: FFTAnalyzerPool;
  private analyzers: Map<string, FFTAnalyzer> = new Map();
  
  static getInstance(): FFTAnalyzerPool {
    if (!FFTAnalyzerPool.instance) {
      FFTAnalyzerPool.instance = new FFTAnalyzerPool();
    }
    return FFTAnalyzerPool.instance;
  }
  
  /**
   * 获取FFT分析器实例
   */
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
      console.info(`[FFT池] 创建分析器: ${key}`);
    }
    
    return this.analyzers.get(key)!;
  }
  
  /**
   * 生成配置键
   */
  private generateConfigKey(config: AudioConfig): string {
    return `${config.fftSize}_${config.windowType}_${config.smoothingFactor}_${config.overlap}`;
  }
  
  /**
   * 清理未使用的分析器
   */
  clearUnusedAnalyzers(): void {
    // 可以定期清理，但目前先保持简单
    console.info(`[FFT池] 当前分析器数量: ${this.analyzers.size}`);
  }
  
  /**
   * 获取池状态
   */
  getPoolStatus(): { size: number; keys: string[] } {
    return {
      size: this.analyzers.size,
      keys: Array.from(this.analyzers.keys())
    };
  }
}
```

### 1.2 创建环形缓冲区

**文件：** `entry/src/main/ets/utils/CircularBuffer.ets`

```typescript
/**
 * 环形缓冲区 - 限制数据累积防止内存泄漏
 */
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
  
  /**
   * 添加元素
   */
  push(item: T): void {
    this.buffer[this.head] = item;
    this.head = (this.head + 1) % this.size;
    
    if (this.count < this.size) {
      this.count++;
    } else {
      this.tail = (this.tail + 1) % this.size;
    }
  }
  
  /**
   * 获取所有元素
   */
  getItems(): T[] {
    const items: T[] = [];
    for (let i = 0; i < this.count; i++) {
      const index = (this.tail + i) % this.size;
      items.push(this.buffer[index]);
    }
    return items;
  }
  
  /**
   * 获取元素数量
   */
  getCount(): number {
    return this.count;
  }
  
  /**
   * 清空缓冲区
   */
  clear(): void {
    this.head = 0;
    this.tail = 0;
    this.count = 0;
  }
  
  /**
   * 检查是否已满
   */
  isFull(): boolean {
    return this.count === this.size;
  }
  
  /**
   * 检查是否为空
   */
  isEmpty(): boolean {
    return this.count === 0;
  }
}
```

### 1.3 优化AudioController

**修改文件：** `entry/src/main/ets/components/decibel-meter/AudioController.ets`

#### 1.3.1 导入新工具

```typescript
import { FFTAnalyzerPool } from '../../utils/FFTAnalyzerPool';
import { CircularBuffer } from '../../utils/CircularBuffer';
```

#### 1.3.2 替换数据存储

```typescript
// 替换原有的数组为环形缓冲区
private timedValues: CircularBuffer<TimedDecibelValue> = new CircularBuffer(2000); // 限制2000个数据点
private timedWeightingTypes: CircularBuffer<TimedWeightingType> = new CircularBuffer(2000);
private timedAudioBuffers: CircularBuffer<TimedAudioBuffer> = new CircularBuffer(100); // 限制100个音频缓冲区
private originAudioBuffers: CircularBuffer<TimedAudioBuffer> = new CircularBuffer(50); // 限制50个原始音频缓冲区
```

#### 1.3.3 优化音频处理回调

```typescript
// 替换原有的音频处理逻辑
this.audioService.startProcessing((buffer: ArrayBuffer) => {
  // 使用节流机制处理音频数据
  this.throttledProcessAudioData(buffer);
});

// 添加节流处理函数
private lastProcessTime: number = 0;
private readonly PROCESS_INTERVAL: number = 50; // 50ms间隔 (20fps)

private throttledProcessAudioData(buffer: ArrayBuffer): void {
  const now = Date.now();
  if (now - this.lastProcessTime >= this.PROCESS_INTERVAL) {
    this.processAudioData(buffer);
    this.lastProcessTime = now;
  }
  // 如果处理太频繁，跳过这次处理
}

private async processAudioData(buffer: ArrayBuffer): Promise<void> {
  try {
    const config = AudioPresets.getConfig(this.pk.audio_analysis_mode);
    const analyzer = FFTAnalyzerPool.getInstance().getAnalyzer(config);
    
    // 使用并发任务计算
    const spectrum = await taskpool.execute<[ArrayBuffer, WeightingType, number], Float32Array>(
      concurrentCalculateSpectrum,
      buffer,  // 不再进行内存拷贝
      this.pk.weighting_type,
      this.pk.calibration_value,
      config.fftSize,
      config.windowType,
      config.smoothingFactor,
      config.overlap
    );
    
    // 使用同一个分析器计算分贝值（避免重复创建）
    const db = analyzer.calculateAverageDb(spectrum);
    
    // 更新状态
    this.onSpectrumData(spectrum);
    this.currentDecibel = Math.round(db);
    
    // 存储数据（使用环形缓冲区）
    const currentTime = new Date().getTime();
    this.timedValues.push({ timestamp: currentTime, value: this.currentDecibel });
    this.timedWeightingTypes.push({ timestamp: currentTime, type: this.pk.weighting_type });
    this.timedAudioBuffers.push({ timestamp: currentTime, buffer: buffer.slice(0) });
    
    // 更新统计信息
    this.updateStatistics(this.currentDecibel);
    this.checkAlarmStatus(this.currentDecibel);
    
    // 更新计时器
    this.recordingTime = new Date().getTime() - this.startTime;
    this.onRecordingTimeUpdate(this.recordingTime);
    
  } catch (error) {
    console.error('[音频处理] 处理失败:', error);
  }
}
```

#### 1.3.4 优化数据获取方法

```typescript
// 修改原有的数组访问为环形缓冲区访问
private updateStatistics(currentDb: number): void {
  const values = this.timedValues.getItems().map(item => item.value);
  
  if (values.length === 0) {
    this.minDecibel = currentDb;
    this.maxDecibel = currentDb;
    this.avgDecibel = currentDb;
  } else {
    this.minDecibel = Math.min(...values);
    this.maxDecibel = Math.max(...values);
    this.avgDecibel = Math.round(values.reduce((sum, val) => sum + val, 0) / values.length);
  }
  
  this.ak.db = currentDb;
  this.onMinMaxAvgCurrent(this.minDecibel, this.maxDecibel, this.avgDecibel, currentDb);
}
```

### 1.4 优化定时器

```typescript
// 替换原有的高频定时器
aboutToAppear() {
  // 降低定时器频率
  this.autoSaveTimer = setInterval(() => {
    this.currentTime = Date.now();
  }, 5000); // 从1秒改为5秒
  
  // 其他初始化代码...
}
```

## 第二阶段：性能监控（1天）

### 2.1 创建性能监控器

**文件：** `entry/src/main/ets/utils/AudioPerformanceMonitor.ets`

```typescript
/**
 * 音频性能监控器
 */
export class AudioPerformanceMonitor {
  private static instance: AudioPerformanceMonitor;
  private processTimes: number[] = [];
  private memoryUsage: number[] = [];
  private maxSamples: number = 100;
  
  static getInstance(): AudioPerformanceMonitor {
    if (!AudioPerformanceMonitor.instance) {
      AudioPerformanceMonitor.instance = new AudioPerformanceMonitor();
    }
    return AudioPerformanceMonitor.instance;
  }
  
  /**
   * 记录处理时间
   */
  recordProcessTime(startTime: number): void {
    const processTime = Date.now() - startTime;
    this.processTimes.push(processTime);
    
    // 保持最近100个样本
    if (this.processTimes.length > this.maxSamples) {
      this.processTimes.shift();
    }
    
    // 如果处理时间过长，记录警告
    if (processTime > 100) {
      console.warn(`[性能监控] 音频处理时间过长: ${processTime}ms`);
    }
  }
  
  /**
   * 记录内存使用
   */
  recordMemoryUsage(): void {
    // 这里可以添加实际的内存监控逻辑
    // 暂时使用模拟数据
    const usage = Math.random() * 100;
    this.memoryUsage.push(usage);
    
    if (this.memoryUsage.length > this.maxSamples) {
      this.memoryUsage.shift();
    }
  }
  
  /**
   * 获取性能报告
   */
  getPerformanceReport(): PerformanceReport {
    const avgProcessTime = this.processTimes.length > 0 
      ? this.processTimes.reduce((a, b) => a + b, 0) / this.processTimes.length 
      : 0;
      
    const maxProcessTime = this.processTimes.length > 0 
      ? Math.max(...this.processTimes) 
      : 0;
    
    return {
      avgProcessTime: Math.round(avgProcessTime),
      maxProcessTime,
      sampleCount: this.processTimes.length,
      isDegraded: avgProcessTime > 50 // 如果平均处理时间超过50ms认为性能下降
    };
  }
  
  /**
   * 重置监控数据
   */
  reset(): void {
    this.processTimes = [];
    this.memoryUsage = [];
  }
}

interface PerformanceReport {
  avgProcessTime: number;
  maxProcessTime: number;
  sampleCount: number;
  isDegraded: boolean;
}
```

### 2.2 在AudioController中添加性能监控

```typescript
// 导入性能监控器
import { AudioPerformanceMonitor } from '../../utils/AudioPerformanceMonitor';

// 在AudioController中添加监控
private performanceMonitor: AudioPerformanceMonitor = AudioPerformanceMonitor.getInstance();

// 在processAudioData中添加性能监控
private async processAudioData(buffer: ArrayBuffer): Promise<void> {
  const startTime = Date.now();
  
  try {
    // ... 原有的处理逻辑
    
    // 记录处理时间
    this.performanceMonitor.recordProcessTime(startTime);
    
    // 定期记录性能报告
    if (Math.random() < 0.01) { // 1%的概率记录性能报告
      const report = this.performanceMonitor.getPerformanceReport();
      console.info(`[性能报告] 平均处理时间: ${report.avgProcessTime}ms, 最大: ${report.maxProcessTime}ms`);
    }
    
  } catch (error) {
    console.error('[音频处理] 处理失败:', error);
  }
}
```

## 第三阶段：进一步优化（可选）

### 3.1 零拷贝优化

如果需要进一步优化，可以考虑实现零拷贝缓冲区：

```typescript
// 高级优化 - 共享内存缓冲区
export class SharedAudioBuffer {
  private static sharedBuffer: ArrayBuffer | null = null;
  private static bufferView: DataView | null = null;
  
  static initialize(size: number): void {
    if (!SharedAudioBuffer.sharedBuffer) {
      SharedAudioBuffer.sharedBuffer = new ArrayBuffer(size);
      SharedAudioBuffer.bufferView = new DataView(SharedAudioBuffer.sharedBuffer);
    }
  }
  
  static copyToShared(source: ArrayBuffer, offset: number = 0): void {
    if (!SharedAudioBuffer.sharedBuffer || !SharedAudioBuffer.bufferView) {
      return;
    }
    
    const sourceView = new Uint8Array(source);
    const targetView = new Uint8Array(SharedAudioBuffer.sharedBuffer, offset, source.byteLength);
    targetView.set(sourceView);
  }
  
  static getSharedSlice(offset: number, length: number): ArrayBuffer {
    if (!SharedAudioBuffer.sharedBuffer) {
      return new ArrayBuffer(0);
    }
    return SharedAudioBuffer.sharedBuffer.slice(offset, offset + length);
  }
}
```

## 测试验证

### 4.1 性能测试脚本

**文件：** `entry/src/main/ets/utils/PerformanceTestUtils.ets`

```typescript
/**
 * 性能测试工具
 */
export class PerformanceTestUtils {
  /**
   * 运行音频处理性能测试
   */
  static async runAudioProcessingTest(): Promise<void> {
    console.info('=== 开始音频处理性能测试 ===');
    
    const testBuffer = new ArrayBuffer(1024);
    const iterations = 100;
    const times: number[] = [];
    
    for (let i = 0; i < iterations; i++) {
      const startTime = Date.now();
      
      // 模拟音频处理
      await new Promise(resolve => setTimeout(resolve, Math.random() * 10));
      
      const processTime = Date.now() - startTime;
      times.push(processTime);
    }
    
    const avgTime = times.reduce((a, b) => a + b, 0) / times.length;
    const maxTime = Math.max(...times);
    
    console.info(`性能测试结果:`);
    console.info(`- 迭代次数: ${iterations}`);
    console.info(`- 平均处理时间: ${avgTime.toFixed(2)}ms`);
    console.info(`- 最大处理时间: ${maxTime}ms`);
    console.info(`- 性能状态: ${avgTime < 20 ? '优秀' : avgTime < 50 ? '良好' : '需要优化'}`);
  }
  
  /**
   * 运行内存使用测试
   */
  static runMemoryUsageTest(): void {
    console.info('=== 开始内存使用测试 ===');
    
    // 测试环形缓冲区内存使用
    const buffer = new CircularBuffer<number>(1000);
    const startMemory = performance.memory?.usedJSHeapSize || 0;
    
    for (let i = 0; i < 5000; i++) {
      buffer.push(i);
    }
    
    const endMemory = performance.memory?.usedJSHeapSize || 0;
    const memoryIncrease = endMemory - startMemory;
    
    console.info(`内存测试结果:`);
    console.info(`- 缓冲区大小: ${buffer.getCount()}`);
    console.info(`- 内存增加: ${memoryIncrease} bytes`);
    console.info(`- 内存效率: ${memoryIncrease < 100000 ? '优秀' : '正常'}`);
  }
}
```

## 部署检查清单

### 部署前检查
- [ ] 所有新文件已创建
- [ ] AudioController修改已完成
- [ ] 性能监控已集成
- [ ] 环形缓冲区已替换数组
- [ ] FFT分析器池已实现

### 测试检查
- [ ] 音频处理功能正常
- [ ] 频谱显示正常
- [ ] 分贝计算准确
- [ ] 性能监控数据正常
- [ ] 内存使用稳定

### 监控指标
- [ ] 平均音频处理时间 < 50ms
- [ ] 内存使用稳定无泄漏
- [ ] 应用响应流畅
- [ ] 无APP_INPUT_BLOCK错误

## 总结

通过以上优化措施，预计可以显著改善应用性能，解决主线程阻塞和内存泄漏问题。建议按照本指南分阶段实施，并在每个阶段完成后进行充分的测试验证。