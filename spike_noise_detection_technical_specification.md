# 尖刺噪音检测模块技术方案

## 1. 项目概述

### 1.1 背景
基于现有噪音测量应用对长时间累积噪音的关注，用户发现安静环境下的突然尖刺噪音对人的影响更大。本方案设计一个专业的尖刺噪音检测模块，实时检测和分析突然的、短时间的尖刺噪音事件。

### 1.2 设计目标
- 实时检测尖刺噪音事件
- 准确识别尖刺噪音的声学特征
- 提供尖刺噪音的详细分析数据
- 无缝集成到现有系统架构
- 满足高性能实时处理需求

## 2. 尖刺噪音声学特征定义

### 2.1 声学特征参数

#### 2.1.1 核心参数
```typescript
interface SpikeNoiseCharacteristics {
  // 分贝变化率 (dB/s)
  decibelChangeRate: number;  // 建议阈值: ≥40 dB/s
  
  // 持续时间阈值 (ms)
  durationThreshold: number;  // 建议范围: 50-500ms
  
  // 峰值与背景对比 (dB)
  peakToBackgroundRatio: number;  // 建议阈值: ≥15 dB
  
  // 背景噪音水平 (dB)
  backgroundNoiseLevel: number;  // 动态计算
  
  // 频率特征
  frequencyRange: FrequencyRange;  // 主要能量分布
  
  // 时间特征
  attackTime: number;  // 上升时间
  decayTime: number;   // 衰减时间
}
```

#### 2.1.2 检测阈值配置
```typescript
interface SpikeDetectionThresholds {
  // 分贝变化率阈值
  minDecibelChangeRate: number;      // 最小变化率: 30 dB/s
  maxDecibelChangeRate: number;      // 最大变化率: 200 dB/s
  
  // 持续时间阈值
  minDuration: number;               // 最短持续时间: 20ms
  maxDuration: number;               // 最长持续时间: 1000ms
  
  // 峰值对比阈值
  minPeakToBackground: number;       // 最小峰值对比: 12 dB
  preferredPeakToBackground: number; // 推荐峰值对比: 20 dB
  
  // 背景噪音适应
  backgroundAdaptationWindow: number; // 背景计算窗口: 5秒
  backgroundUpdateRate: number;       // 背景更新率: 1Hz
}
```

## 3. 实时检测算法设计

### 3.1 算法架构

#### 3.1.1 多级检测流程
```
原始音频数据 → 预处理 → 特征提取 → 事件检测 → 分类验证 → 结果输出
```

#### 3.1.2 核心检测模块
```typescript
class SpikeNoiseDetector {
  private backgroundEstimator: BackgroundNoiseEstimator;
  private featureExtractor: SpikeFeatureExtractor;
  private eventClassifier: SpikeEventClassifier;
  private resultProcessor: DetectionResultProcessor;
  
  // 实时检测方法
  public detectSpike(
    audioBuffer: ArrayBuffer, 
    currentTime: number
  ): SpikeDetectionResult | null;
  
  // 批量处理方法
  public processAudioStream(
    audioStream: AudioStream, 
    callback: (result: SpikeDetectionResult) => void
  ): void;
}
```

### 3.2 特征提取算法

#### 3.2.1 时域特征
```typescript
interface TimeDomainFeatures {
  // 分贝变化特征
  currentDecibel: number;
  previousDecibel: number;
  decibelChangeRate: number;
  
  // 包络特征
  signalEnvelope: number[];
  attackSlope: number;
  decaySlope: number;
  
  // 统计特征
  signalVariance: number;
  peakToRmsRatio: number;
  crestFactor: number;
}
```

#### 3.2.2 频域特征
```typescript
interface FrequencyDomainFeatures {
  // 频谱特征
  spectrum: Float32Array;
  spectralCentroid: number;
  spectralSpread: number;
  spectralFlux: number;
  
  // 频带能量分布
  lowBandEnergy: number;    // 20-250Hz
  midBandEnergy: number;    // 250-2000Hz  
  highBandEnergy: number;   // 2000-20000Hz
  
  // 谐波特征
  harmonicity: number;
  inharmonicity: number;
}
```

### 3.3 事件检测逻辑

#### 3.3.1 状态机设计
```typescript
enum DetectionState {
  IDLE = 'IDLE',
  BACKGROUND_ESTIMATION = 'BACKGROUND_ESTIMATION',
  PEAK_DETECTION = 'PEAK_DETECTION',
  EVENT_VALIDATION = 'EVENT_VALIDATION',
  EVENT_TRACKING = 'EVENT_TRACKING'
}

class SpikeDetectionStateMachine {
  private currentState: DetectionState;
  private eventBuffer: SpikeEvent[];
  private backgroundModel: BackgroundNoiseModel;
  
  public processFrame(audioFrame: AudioFrame): void;
  public getActiveEvents(): SpikeEvent[];
  public reset(): void;
}
```

#### 3.3.2 检测逻辑流程
1. **背景噪音估计**
   - 使用滑动窗口计算背景噪音水平
   - 动态适应环境变化
   - 排除异常值影响

2. **峰值检测**
   - 实时监测分贝变化率
   - 识别潜在的尖刺事件
   - 应用多阈值验证

3. **事件验证**
   - 持续时间验证
   - 频率特征验证
   - 模式匹配验证

4. **结果分类**
   - 根据特征强度分类
   - 计算置信度分数
   - 生成详细报告

## 4. 系统架构集成方案

### 4.1 整体架构设计

#### 4.1.1 模块化架构
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  音频采集模块   │────│ 尖刺噪音检测模块 │────│   数据存储模块  │
│ AudioService    │    │ SpikeDetector    │    │ DecibelRecord   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  音频处理模块   │    │   事件通知模块   │    │   界面展示模块  │
│ AudioProcessor  │    │  AlertService    │    │      UI         │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

#### 4.1.2 数据流设计
```typescript
// 主要数据流接口
interface SpikeDetectionDataFlow {
  // 音频数据输入
  audioInput: AudioStreamData;
  
  // 实时处理
  realTimeProcessing: RealTimeProcessor;
  
  // 事件输出
  detectionEvents: SpikeEvent[];
  
  // 统计输出
  detectionStatistics: SpikeStatistics;
  
  // 通知输出
  alertNotifications: AlertMessage[];
}
```

### 4.2 与现有系统集成

#### 4.2.1 AudioService集成
```typescript
// 扩展AudioService支持尖刺检测
class EnhancedAudioService extends AudioService {
  private spikeDetector: SpikeNoiseDetector;
  
  // 注册尖刺检测回调
  public registerSpikeDetectionCallback(
    callback: (event: SpikeEvent) => void
  ): void;
  
  // 配置检测参数
  public configureSpikeDetection(config: SpikeConfig): void;
}
```

#### 4.2.2 AudioController集成
```typescript
// 扩展AudioController状态机
class EnhancedAudioController extends AudioController {
  private spikeDetectionManager: SpikeDetectionManager;
  
  // 尖刺检测状态管理
  public enableSpikeDetection(): void;
  public disableSpikeDetection(): void;
  public getSpikeDetectionStatus(): SpikeDetectionStatus;
}
```

## 5. 数据模型设计

### 5.1 核心数据模型

#### 5.1.1 尖刺事件模型
```typescript
@ObservedV2
class SpikeEvent {
  // 基础信息
  id: string;
  timestamp: number;
  duration: number;
  
  // 声学特征
  peakDecibel: number;
  backgroundDecibel: number;
  decibelChangeRate: number;
  
  // 频率特征
  dominantFrequency: number;
  frequencyBand: FrequencyBand;
  spectralCharacteristics: SpectralData;
  
  // 检测信息
  confidence: number;
  classification: SpikeClassification;
  triggerSource: TriggerSource;
  
  // 关联数据
  audioSegment?: ArrayBuffer;
  location?: string;
  metadata: EventMetadata;
}
```

#### 5.1.2 检测统计模型
```typescript
class SpikeStatistics {
  // 时间统计
  detectionPeriod: number;
  totalEvents: number;
  eventsPerMinute: number;
  
  // 强度统计
  averagePeakDecibel: number;
  maxPeakDecibel: number;
  intensityDistribution: DecibelDistribution;
  
  // 频率统计
  frequencyDistribution: FrequencyDistribution;
  timeOfDayPattern: TimePattern;
  
  // 性能统计
  detectionAccuracy: number;
  falsePositiveRate: number;
  processingLatency: number;
}
```

### 5.2 数据库设计

#### 5.2.1 新增数据表
```sql
-- 尖刺事件表
CREATE TABLE spike_events (
  id TEXT PRIMARY KEY,
  timestamp INTEGER NOT NULL,
  duration INTEGER NOT NULL,
  peak_decibel REAL NOT NULL,
  background_decibel REAL NOT NULL,
  decibel_change_rate REAL NOT NULL,
  dominant_frequency REAL,
  confidence REAL NOT NULL,
  classification TEXT NOT NULL,
  audio_segment_path TEXT,
  location TEXT,
  metadata TEXT
);

-- 检测统计表
CREATE TABLE spike_statistics (
  id TEXT PRIMARY KEY,
  start_time INTEGER NOT NULL,
  end_time INTEGER NOT NULL,
  total_events INTEGER NOT NULL,
  average_peak_decibel REAL NOT NULL,
  max_peak_decibel REAL NOT NULL,
  frequency_distribution TEXT,
  detection_accuracy REAL,
  created_at INTEGER NOT NULL
);
```

## 6. 性能指标和测试方法

### 6.1 性能指标

#### 6.1.1 实时性指标
```typescript
interface RealTimePerformance {
  // 处理延迟
  processingLatency: number;        // 目标: <50ms
  endToEndLatency: number;          // 目标: <100ms
  
  // 吞吐量
  framesPerSecond: number;          // 目标: ≥30fps
  eventsPerSecond: number;          // 目标: ≥10eps
  
  // 资源使用
  cpuUsage: number;                 // 目标: <15%
  memoryUsage: number;              // 目标: <50MB
}
```

#### 6.1.2 准确性指标
```typescript
interface AccuracyMetrics {
  // 检测准确性
  detectionRate: number;            // 目标: ≥95%
  falsePositiveRate: number;        // 目标: ≤5%
  falseNegativeRate: number;        // 目标: ≤3%
  
  // 分类准确性
  classificationAccuracy: number;   // 目标: ≥90%
  confidenceThreshold: number;      // 目标: ≥0.8
  
  // 时间准确性
  timingAccuracy: number;           // 目标: ±10ms
  durationAccuracy: number;         // 目标: ±5%
}
```

### 6.2 测试方法

#### 6.2.1 单元测试
```typescript
// 特征提取测试
describe('SpikeFeatureExtractor', () => {
  it('应该正确计算分贝变化率', () => {
    const extractor = new SpikeFeatureExtractor();
    const features = extractor.extractFeatures(testAudioBuffer);
    expect(features.decibelChangeRate).toBeCloseTo(45.2, 1);
  });
  
  it('应该准确识别尖刺事件', () => {
    const detector = new SpikeNoiseDetector();
    const result = detector.detectSpike(spikeAudioBuffer);
    expect(result.isSpike).toBe(true);
    expect(result.confidence).toBeGreaterThan(0.8);
  });
});
```

#### 6.2.2 集成测试
```typescript
// 系统集成测试
describe('SpikeDetectionIntegration', () => {
  it('应该与AudioService正确集成', async () => {
    const audioService = AudioService.getInstance();
    const spikeDetector = new SpikeNoiseDetector();
    
    await audioService.startRecording();
    const events = await spikeDetector.monitorStream(audioService.getStream());
    
    expect(events.length).toBeGreaterThan(0);
    expect(events[0].timestamp).toBeDefined();
  });
});
```

#### 6.2.3 性能测试
```typescript
// 性能基准测试
describe('SpikeDetectionPerformance', () => {
  it('应该满足实时处理要求', () => {
    const detector = new SpikeNoiseDetector();
    const startTime = performance.now();
    
    // 处理1分钟音频数据
    for (let i = 0; i < 1800; i++) { // 30fps × 60秒
      detector.processFrame(generateTestFrame());
    }
    
    const endTime = performance.now();
    const processingTime = endTime - startTime;
    
    expect(processingTime).toBeLessThan(60000); // 应在60秒内完成
    expect(detector.getStatistics().processingLatency).toBeLessThan(50);
  });
});
```

## 7. 实施计划

### 7.1 开发阶段

#### 7.1.1 第一阶段：核心算法开发（2周）
- 实现基础特征提取算法
- 开发尖刺事件检测逻辑
- 建立单元测试框架

#### 7.1.2 第二阶段：系统集成（1周）
- 集成到AudioService
- 实现数据存储功能
- 完成集成测试

#### 7.1.3 第三阶段：界面展示（1周）
- 开发尖刺事件展示界面
- 实现实时通知功能
- 用户测试和优化

### 7.2 部署策略

#### 7.2.1 渐进式部署
1. **内部测试阶段**：在开发环境验证核心功能
2. **有限用户测试**：选择小范围用户进行实际测试
3. **全面部署**：逐步推广到所有用户

#### 7.2.2 功能开关
```typescript
// 功能开关配置
interface FeatureFlags {
  spikeDetectionEnabled: boolean;
  advancedAnalysisEnabled: boolean;
  realTimeAlertsEnabled: boolean;
  dataCollectionEnabled: boolean;
}
```

## 8. 风险评估和缓解措施

### 8.1 技术风险

#### 8.1.1 性能风险
- **风险**：实时处理可能影响应用性能
- **缓解**：优化算法复杂度，使用增量计算

#### 8.1.2 准确性风险
- **风险**：误报或漏报尖刺事件
- **缓解**：多特征验证，自适应阈值调整

### 8.2 用户体验风险

#### 8.2.1 通知干扰
- **风险**：频繁的通知可能打扰用户
- **缓解**：智能通知策略，用户可配置

## 9. 结论

本技术方案提供了一个完整的尖刺噪音检测模块设计，包括：

1. **精确的声学特征定义**：基于声学原理定义尖刺噪音特征
2. **高效的实时检测算法**：多级检测流程确保准确性
3. **无缝的系统集成**：充分利用现有架构优势
4. **完善的数据管理**：结构化存储和分析数据
5. **严格的性能标准**：确保实时性和准确性

该方案将为用户提供专业的尖刺噪音检测能力，显著提升应用的使用价值。

---
**文档版本**: 1.0  
**创建日期**: 2025-10-31  
**最后更新**: 2025-10-31