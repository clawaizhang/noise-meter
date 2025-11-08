# 峰值计算改进计划

## 当前问题分析

1. **精度限制**：当前实现只找到离散FFT点中的最大值，频率精度受限于FFT频率分辨率
2. **无亚频率级精度**：没有使用抛物线插值或重心法等亚频率级精度算法
3. **单一峰值检测**：只能检测一个峰值，无法处理多峰值场景
4. **无峰值验证**：缺乏对峰值有效性的验证机制

## 改进方案

### 1. AudioConfig 配置扩展

在 `AudioAnalysisConfig` 类中添加以下配置选项：

```typescript
@Trace
usePeakInterpolation: boolean = true; // 是否使用峰值插值
@Trace
peakInterpolationMethod: PeakInterpolationMethod = PeakInterpolationMethod.PARABOLIC; // 插值方法
@Trace
maxPeakCount: number = 3; // 最大峰值检测数量
@Trace
minPeakDistance: number = 10; // 最小峰值间隔
@Trace
minPeakHeight: number = -60; // 最小峰值高度(dB)
```

添加枚举：
```typescript
export enum PeakInterpolationMethod {
  NONE = 'none',           // 不使用插值
  PARABOLIC = 'parabolic', // 抛物线插值
  CENTROID = 'centroid'    // 重心法
}
```

### 2. SpectrumDataProcessor 扩展

#### 2.1 抛物线插值方法
```typescript
static parabolicInterpolation(
  spectrumData: Float32Array,
  peakIndex: number,
  fftSize: number,
  sampleRate: number
): { frequency: number, amplitude: number }
```

#### 2.2 重心法
```typescript
static centroidMethod(
  spectrumData: Float32Array,
  peakIndex: number,
  windowSize: number = 3,
  fftSize: number,
  sampleRate: number
): { frequency: number, amplitude: number }
```

#### 2.3 改进的峰值检测方法
```typescript
static findPeakFrequency(
  spectrumData: Float32Array,
  fftSize: number,
  sampleRate: number,
  minFreq: number = SpectrumDataProcessor.MIN_FREQUENCY,
  maxFreq: number = SpectrumDataProcessor.MAX_FREQUENCY,
  useInterpolation: boolean = true,
  interpolationMethod: PeakInterpolationMethod = PeakInterpolationMethod.PARABOLIC
): PeakInfo | null
```

#### 2.4 多峰值检测
```typescript
static findMultiplePeaks(
  spectrumData: Float32Array,
  fftSize: number,
  sampleRate: number,
  peakCount: number = 3,
  minPeakDistance: number = 10,
  minPeakHeight: number = -60,
  useInterpolation: boolean = true,
  interpolationMethod: PeakInterpolationMethod = PeakInterpolationMethod.PARABOLIC
): PeakInfo[]
```

### 3. FFTAnalyzer 改进

改进 `analyzeSpectrum` 方法支持插值：

```typescript
private analyzeSpectrum(
  spectrum: Float32Array, 
  binSize: number, 
  useInterpolation: boolean = true,
  interpolationMethod: PeakInterpolationMethod = PeakInterpolationMethod.PARABOLIC
): SpectrumStats
```

### 4. 实施步骤

1. **修改 AudioConfig.ets**
   - 添加峰值插值相关配置选项
   - 更新预设配置
   - 更新 clone 方法

2. **修改 SpectrumDataProcessor.ets**
   - 实现抛物线插值方法
   - 实现重心法
   - 改进 findPeakFrequency 方法
   - 添加多峰值检测功能

3. **修改 FFTAnalyzer.ets**
   - 改进 analyzeSpectrum 方法
   - 添加插值方法选择逻辑

4. **更新调用方**
   - 更新 AudioController.ets 中的调用
   - 更新频谱图组件中的调用
   - 确保配置传递正确

5. **性能监控和测试**
   - 添加性能监控
   - 创建测试用例验证精度改进

## 预期效果

1. **频率精度提升**：从当前的FFT频率分辨率级别（约21.5Hz@2048FFT@44.1kHz）提升到亚频率级精度（可达1Hz以下）
2. **多峰值检测**：能够同时检测多个峰值，适用于复杂声学场景
3. **算法选择**：提供多种插值算法选择，适应不同应用场景
4. **配置灵活性**：通过配置选项控制是否启用高精度算法

## 性能考虑

1. **抛物线插值**：计算量极小，仅需3个点，适合实时处理
2. **重心法**：计算量适中，抗噪性好，适合噪声环境
3. **多峰值检测**：计算量随峰值数量增加，可通过配置控制

## 测试验证

1. **单频信号测试**：使用已知频率的正弦波验证频率精度
2. **多频信号测试**：验证多峰值检测能力
3. **噪声环境测试**：验证算法在噪声环境下的稳定性
4. **性能测试**：确保实时性要求得到满足