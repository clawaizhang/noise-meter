import { WeightingType } from '../constants/WeightingConstants';

/**
 * 峰值信息类
 */
export class PeakInfo {
  frequency: number = 0;
  amplitude: number = 0;
  stability: number = 0;
  
  constructor(frequency: number, amplitude: number, stability: number) {
    this.frequency = frequency;
    this.amplitude = amplitude;
    this.stability = stability;
  }
}

/**
 * 候选峰值信息类
 */
export class CandidatePeak {
  binIndex: number = 0;
  amplitude: number = 0;
  
  constructor(binIndex: number, amplitude: number) {
    this.binIndex = binIndex;
    this.amplitude = amplitude;
  }
}

/**
 * 频谱平滑管理器 - 单例模式
 * 负责管理频谱数据的平滑和峰值检测状态
 * 解决每次new FFTAnalyzer导致状态丢失的问题
 */
export class SpectrumSmoothingManager {
  private static instance: SpectrumSmoothingManager | null = null;
  
  // 平滑状态数据 - 使用Map支持多个配置并存
  private smoothingStates: Map<string, SmoothingState> = new Map();
  
  // 峰值稳定化相关属性
  private peakHistories: Map<string, Map<number, number[]>> = new Map();
  private readonly PEAK_HISTORY_SIZE: number = 10; // 历史峰值记录数量
  private readonly PEAK_STABILITY_THRESHOLD: number = 3; // 峰值稳定性阈值（Hz）
  private readonly PEAK_PERSISTENCE_THRESHOLD: number = 0.6; // 峰值持续性阈值（0-1）
  private readonly PEAK_AMPLITUDE_THRESHOLD: number = 5; // 峰值幅度阈值（dB）
  
  private constructor() {
    // 私有构造函数，确保单例
  }
  
  /**
   * 获取单例实例
   */
  public static getInstance(): SpectrumSmoothingManager {
    if (!SpectrumSmoothingManager.instance) {
      SpectrumSmoothingManager.instance = new SpectrumSmoothingManager();
    }
    return SpectrumSmoothingManager.instance;
  }
  
  /**
   * 生成配置的唯一键
   */
  public generateConfigKey(fftSize: number, smoothingFactor: number,
                          exponentialSmoothingFactor: number, weightingType: WeightingType): string {
    return `${fftSize}_${smoothingFactor}_${exponentialSmoothingFactor}_${weightingType}`;
  }
  
  /**
   * 获取或创建平滑状态
   */
  private getOrCreateSmoothingState(configKey: string, spectrumLength: number): SmoothingState {
    if (!this.smoothingStates.has(configKey)) {
      this.smoothingStates.set(configKey, {
        previousMagnitudes: null,
        previousExponentialSpectrum: null
      });
      
      // 初始化峰值历史
      if (!this.peakHistories.has(configKey)) {
        this.peakHistories.set(configKey, new Map());
      }
    }
    
    return this.smoothingStates.get(configKey)!;
  }
  
  /**
   * 应用频谱平滑
   * @param spectrum 当前频谱
   * @param fftSize FFT大小
   * @param smoothingFactor 平滑因子
   * @param exponentialSmoothingFactor 指数平滑因子
   * @param weightingType 计权类型
   * @param sampleRate 采样率
   * @returns 平滑后的频谱
   */
  public applySpectrumSmoothing(
    spectrum: Float32Array,
    fftSize: number,
    smoothingFactor: number,
    exponentialSmoothingFactor: number,
    weightingType: WeightingType,
    sampleRate: number = 44100
  ): Float32Array {
    const configKey = this.generateConfigKey(fftSize, smoothingFactor, exponentialSmoothingFactor, weightingType);
    const state = this.getOrCreateSmoothingState(configKey, spectrum.length);
    
    // 第一步：应用基础平滑
    let smoothedSpectrum = this.applyBasicSmoothing(spectrum, state, smoothingFactor, fftSize, sampleRate);
    
    // 第二步：应用指数平滑
    smoothedSpectrum = this.applyExponentialSmoothing(smoothedSpectrum, state, exponentialSmoothingFactor);
    
    return smoothedSpectrum;
  }
  
  /**
   * 应用基础平滑（分频段平滑）
   */
  private applyBasicSmoothing(
    spectrum: Float32Array,
    state: SmoothingState,
    smoothingFactor: number,
    fftSize: number,
    sampleRate: number
  ): Float32Array {
    if (!state.previousMagnitudes) {
      state.previousMagnitudes = spectrum.slice();
      return spectrum;
    }
    
    const freqResolution = sampleRate / fftSize;
    const result = new Float32Array(spectrum.length);
    
    for (let i = 0; i < spectrum.length; i++) {
      const frequency = i * freqResolution;
      // 调整平滑因子语义：值越大，平滑效果越强
      const adaptiveSmoothingFactor = this.getFrequencyBasedSmoothingFactor(frequency, smoothingFactor);
      
      // 修正平滑公式：值越大，更重视历史值（平滑效果越强）
      result[i] = (1 - adaptiveSmoothingFactor) * spectrum[i] +
                  adaptiveSmoothingFactor * state.previousMagnitudes[i];
    }
    
    state.previousMagnitudes.set(result);
    return result;
  }
  
  /**
   * 应用指数平滑
   */
  private applyExponentialSmoothing(
    spectrum: Float32Array,
    state: SmoothingState,
    exponentialSmoothingFactor: number
  ): Float32Array {
    if (!state.previousExponentialSpectrum || state.previousExponentialSpectrum.length !== spectrum.length) {
      state.previousExponentialSpectrum = new Float32Array(spectrum.length);
      state.previousExponentialSpectrum.set(spectrum);
      return spectrum;
    }
    
    const result = new Float32Array(spectrum.length);
    
    for (let i = 0; i < spectrum.length; i++) {
      // 修正指数平滑公式：值越大，更重视历史值（平滑效果越强）
      result[i] = (1 - exponentialSmoothingFactor) * spectrum[i] +
                  exponentialSmoothingFactor * state.previousExponentialSpectrum[i];
    }
    
    state.previousExponentialSpectrum.set(result);
    return result;
  }
  
  /**
   * 根据频率获取平滑因子
   */
  private getFrequencyBasedSmoothingFactor(frequency: number, baseSmoothingFactor: number): number {
    if (frequency < 250) {
      return Math.min(0.8, baseSmoothingFactor * 1.5);
    } else if (frequency < 2000) {
      return baseSmoothingFactor;
    } else if (frequency < 8000) {
      return Math.max(0.1, baseSmoothingFactor * 0.7);
    } else {
      return Math.max(0.05, baseSmoothingFactor * 0.5);
    }
  }
  
  /**
   * 检测稳定的峰值
   * @param spectrum 频谱数据
   * @param fftSize FFT大小
   * @param sampleRate 采样率
   * @param configKey 配置键
   * @returns 稳定峰值数组
   */
  public detectStablePeaks(
    spectrum: Float32Array,
    fftSize: number,
    sampleRate: number,
    configKey: string
  ): PeakInfo[] {
    const freqResolution = sampleRate / fftSize;
    const peaks: PeakInfo[] = [];
    
    // 更新峰值历史
    this.updatePeakHistory(spectrum, configKey);
    
    // 检测候选峰值
    const candidatePeaks = this.findCandidatePeaks(spectrum, freqResolution);
    
    // 评估每个候选峰值的稳定性
    for (const peak of candidatePeaks) {
      const stability = this.evaluatePeakStability(peak.binIndex, peak.amplitude, configKey);
      
      if (stability >= this.PEAK_PERSISTENCE_THRESHOLD && peak.amplitude > this.PEAK_AMPLITUDE_THRESHOLD) {
        const frequency = peak.binIndex * freqResolution;
        peaks.push(new PeakInfo(frequency, peak.amplitude, stability));
      }
    }
    
    // 按稳定性排序，优先显示最稳定的峰值
    peaks.sort((a, b) => b.stability - a.stability);
    
    return peaks;
  }
  
  /**
   * 更新峰值历史记录
   */
  private updatePeakHistory(spectrum: Float32Array, configKey: string): void {
    if (!this.peakHistories.has(configKey)) {
      this.peakHistories.set(configKey, new Map());
    }
    
    const history = this.peakHistories.get(configKey)!;
    
    for (let i = 0; i < spectrum.length; i++) {
      if (!history.has(i)) {
        history.set(i, []);
      }
      
      const binHistory = history.get(i)!;
      binHistory.push(spectrum[i]);
      
      // 保持历史记录大小
      if (binHistory.length > this.PEAK_HISTORY_SIZE) {
        binHistory.shift();
      }
    }
  }
  
  /**
   * 查找候选峰值
   */
  private findCandidatePeaks(spectrum: Float32Array, freqResolution: number): CandidatePeak[] {
    const candidates: CandidatePeak[] = [];
    const minPeakDistance = Math.max(1, Math.floor(this.PEAK_STABILITY_THRESHOLD / freqResolution));
    
    for (let i = 1; i < spectrum.length - 1; i++) {
      if (spectrum[i] > spectrum[i - 1] && spectrum[i] > spectrum[i + 1]) {
        let isFarEnough = true;
        for (const existing of candidates) {
          if (Math.abs(i - existing.binIndex) < minPeakDistance) {
            isFarEnough = false;
            if (spectrum[i] > existing.amplitude) {
              const index = candidates.indexOf(existing);
              candidates[index] = new CandidatePeak(i, spectrum[i]);
            }
            break;
          }
        }
        
        if (isFarEnough) {
          candidates.push(new CandidatePeak(i, spectrum[i]));
        }
      }
    }
    
    return candidates;
  }
  
  /**
   * 评估峰值的稳定性
   */
  private evaluatePeakStability(binIndex: number, currentAmplitude: number, configKey: string): number {
    const history = this.peakHistories.get(configKey);
    if (!history || !history.has(binIndex)) {
      return 0.5;
    }
    
    const binHistory = history.get(binIndex)!;
    if (binHistory.length < 3) {
      return 0.5;
    }
    
    // 计算幅度的方差
    const mean = binHistory.reduce((sum, val) => sum + val, 0) / binHistory.length;
    const variance = binHistory.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) / binHistory.length;
    const stdDev = Math.sqrt(variance);
    
    // 计算持续性
    let persistence = 0;
    const threshold = currentAmplitude * 0.7;
    for (const val of binHistory) {
      if (val > threshold) {
        persistence++;
      }
    }
    persistence = persistence / binHistory.length;
    
    // 综合稳定性评分
    const amplitudeStability = Math.max(0, 1 - stdDev / 10);
    const overallStability = amplitudeStability * 0.6 + persistence * 0.4;
    
    return Math.max(0, Math.min(1, overallStability));
  }
  
  /**
   * 重置指定配置的状态
   */
  public resetState(fftSize: number, smoothingFactor: number, 
                   exponentialSmoothingFactor: number, weightingType: WeightingType): void {
    const configKey = this.generateConfigKey(fftSize, smoothingFactor, exponentialSmoothingFactor, weightingType);
    this.smoothingStates.delete(configKey);
    this.peakHistories.delete(configKey);
  }
  
  /**
   * 重置所有状态
   */
  public resetAllStates(): void {
    this.smoothingStates.clear();
    this.peakHistories.clear();
  }
}

/**
 * 平滑状态接口
 */
interface SmoothingState {
  previousMagnitudes: Float32Array | null;
  previousExponentialSpectrum: Float32Array | null;
}