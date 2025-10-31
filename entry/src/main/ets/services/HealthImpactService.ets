/**
 * 统一健康影响服务
 * 集成现有服务，提供完整的健康影响评估和特殊噪音检测
 */

import { DecibelService } from './DecibelService';
import { ExposureStatisticsService } from './ExposureStatisticsService';
import { AlertService } from './AlertService';
import { HealthImpactData, HealthRiskLevel, SpecialNoiseDetection, SpecialNoiseType } from '../models/HealthImpactData';
import { NoiseExposureStandard } from '../constants/ExposureStandardConstants';
import { FFTAnalyzer } from '../utils/FFTAnalyzer';
import { FFTBufferManager } from '../utils/FFTBufferManager';
import { WindowType } from '../common/WindowType';
import { WeightingType } from '../constants/WeightingConstants';
import common from '@ohos.app.ability.common';

// 脉冲噪音检测配置
interface ImpulseNoiseConfig {
  gradientThreshold: number;      // 梯度变化阈值
  durationThreshold: number;      // 持续时间阈值（毫秒）
  intensityThreshold: number;     // 强度阈值
  minPeakDistance: number;        // 最小峰值距离（毫秒）
}

// 低频共振检测配置
interface LowFrequencyConfig {
  frequencyRange: [number, number]; // 频率范围 [min, max] Hz
  energyThreshold: number;          // 能量阈值
  durationThreshold: number;        // 持续时间阈值（毫秒）
  dominanceThreshold: number;       // 主导性阈值（百分比）
}

// 健康影响服务配置
interface HealthImpactConfig {
  impulseNoise: ImpulseNoiseConfig;
  lowFrequency: LowFrequencyConfig;
  updateInterval: number;           // 更新间隔（毫秒）
  fftSize: number;                  // FFT大小
}

// 默认配置
const DEFAULT_CONFIG: HealthImpactConfig = {
  impulseNoise: {
    gradientThreshold: 15.0,        // 15dB/秒的梯度变化
    durationThreshold: 100,         // 100毫秒
    intensityThreshold: 85,         // 85dB
    minPeakDistance: 500            // 500毫秒
  },
  lowFrequency: {
    frequencyRange: [20, 250],      // 20-250Hz低频范围
    energyThreshold: 70,            // 70dB能量阈值
    durationThreshold: 2000,        // 2秒持续时间
    dominanceThreshold: 30          // 30%主导性
  },
  updateInterval: 1000,             // 1秒更新间隔
  fftSize: 2048                     // 2048点FFT
};

// 历史数据记录
interface HistoricalData {
  timestamp: number;
  decibel: number;
  gradient: number;
}

export class HealthImpactService {
  private static instance: HealthImpactService | null = null;
  
  // 服务实例
  private decibelService: typeof DecibelService = DecibelService;
  private exposureService: ExposureStatisticsService = ExposureStatisticsService.getInstance();
  private alertService: AlertService | null = null;
  
  // 配置
  private config: HealthImpactConfig = DEFAULT_CONFIG;
  
  // FFT分析器
  private fftAnalyzer: FFTAnalyzer;
  private fftBufferManager: FFTBufferManager;
  
  // 历史数据
  private historicalData: HistoricalData[] = [];
  private maxHistorySize: number = 100;
  
  // 当前状态
  private currentHealthData: HealthImpactData = new HealthImpactData();
  private isInitialized: boolean = false;
  private updateTimer: number | null = null;
  
  // 上下文
  private context: common.Context | null = null;

  private constructor() {
    // 初始化FFT分析器
    this.fftAnalyzer = new FFTAnalyzer(
      this.config.fftSize,
      WindowType.HANNING,
      0.2,  // 平滑因子
      0.5   // 重叠率
    );
    
    // 初始化FFT缓冲区管理器
    this.fftBufferManager = new FFTBufferManager(this.config.fftSize);
    
    console.info('[HealthImpactService] 健康影响服务已创建');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): HealthImpactService {
    if (!HealthImpactService.instance) {
      HealthImpactService.instance = new HealthImpactService();
    }
    return HealthImpactService.instance;
  }

  /**
   * 初始化服务
   * @param context 应用上下文
   * @param alertService 警报服务实例
   */
  public async initialize(context: common.Context, alertService: AlertService): Promise<void> {
    if (this.isInitialized) {
      console.info('[HealthImpactService] 服务已初始化，跳过重复初始化');
      return;
    }

    this.context = context;
    this.alertService = alertService;
    
    // 初始化暴露统计服务
    this.exposureService.setContext(context);
    
    // 开始实时更新
    this.startRealTimeUpdates();
    
    this.isInitialized = true;
    console.info('[HealthImpactService] 健康影响服务初始化完成');
  }

  /**
   * 获取当前健康影响数据
   */
  public getCurrentHealthData(): HealthImpactData {
    return this.currentHealthData;
  }

  /**
   * 更新配置
   * @param newConfig 新配置
   */
  public updateConfig(newConfig: Partial<HealthImpactConfig>): void {
    this.config = { ...this.config, ...newConfig };
    
    // 更新FFT分析器大小
    if (newConfig.fftSize && newConfig.fftSize !== this.config.fftSize) {
      this.fftBufferManager.updateFFTSize(newConfig.fftSize);
    }
    
    console.info('[HealthImpactService] 配置已更新');
  }

  /**
   * 开始实时更新
   */
  private startRealTimeUpdates(): void {
    if (this.updateTimer) {
      clearInterval(this.updateTimer);
    }
    
    this.updateTimer = setInterval(() => {
      this.updateHealthData();
    }, this.config.updateInterval) as unknown as number;
    
    console.info(`[HealthImpactService] 开始实时更新，间隔: ${this.config.updateInterval}ms`);
  }

  /**
   * 停止实时更新
   */
  public stopRealTimeUpdates(): void {
    if (this.updateTimer) {
      clearInterval(this.updateTimer);
      this.updateTimer = null;
      console.info('[HealthImpactService] 实时更新已停止');
    }
  }

  /**
   * 更新健康数据
   */
  private async updateHealthData(): Promise<void> {
    try {
      // 获取当前分贝数据
      const currentDecibel = await this.getCurrentDecibel();
      
      // 获取暴露统计数据
      const exposurePercentage = await this.getExposurePercentage();
      
      // 检测特殊噪音
      const specialNoiseDetection = await this.detectSpecialNoise();
      
      // 更新健康影响数据
      this.currentHealthData.update(
        exposurePercentage,
        currentDecibel,
        specialNoiseDetection
      );
      
      console.debug(`[HealthImpactService] 健康数据已更新: 分贝=${currentDecibel.toFixed(1)}dB, ` +
        `暴露=${exposurePercentage.toFixed(1)}%, 风险=${this.currentHealthData.getRiskDescription()}`);
      
    } catch (error) {
      console.error('[HealthImpactService] 更新健康数据失败:', error);
    }
  }

  /**
   * 获取当前分贝值
   */
  private async getCurrentDecibel(): Promise<number> {
    try {
      // 从DecibelService获取基础统计数据
      const basicStats = await this.decibelService.getBasicStats();
      
      // 使用Leq值作为当前分贝值
      const currentDecibel = basicStats.leq || 0;
      
      // 记录历史数据用于梯度计算
      this.recordHistoricalData(currentDecibel);
      
      return currentDecibel;
    } catch (error) {
      console.error('[HealthImpactService] 获取当前分贝值失败:', error);
      return 0;
    }
  }

  /**
   * 获取暴露剂量百分比
   */
  private async getExposurePercentage(): Promise<number> {
    try {
      // 使用职业听力保护标准计算暴露剂量
      const exposureData = await this.exposureService.calculateTodayExposure(
        NoiseExposureStandard.WORKPLACE
      );
      
      return exposureData.exposurePercentage || 0;
    } catch (error) {
      console.error('[HealthImpactService] 获取暴露剂量失败:', error);
      return 0;
    }
  }

  /**
   * 记录历史数据
   * @param decibel 当前分贝值
   */
  private recordHistoricalData(decibel: number): void {
    const now = Date.now();
    
    // 计算梯度（如果历史数据足够）
    let gradient = 0;
    if (this.historicalData.length > 0) {
      const lastData = this.historicalData[this.historicalData.length - 1];
      const timeDiff = (now - lastData.timestamp) / 1000; // 转换为秒
      gradient = timeDiff > 0 ? (decibel - lastData.decibel) / timeDiff : 0;
    }
    
    // 添加新数据
    this.historicalData.push({
      timestamp: now,
      decibel: decibel,
      gradient: gradient
    });
    
    // 限制历史数据大小
    if (this.historicalData.length > this.maxHistorySize) {
      this.historicalData = this.historicalData.slice(-this.maxHistorySize);
    }
  }

  /**
   * 检测特殊噪音
   */
  private async detectSpecialNoise(): Promise<SpecialNoiseDetection> {
    // 优先检测脉冲噪音（基于梯度变化）
    const impulseDetection = this.detectImpulseNoise();
    if (impulseDetection.isValid()) {
      return impulseDetection;
    }
    
    // 然后检测低频共振（需要FFT数据）
    const lowFrequencyDetection = await this.detectLowFrequencyNoise();
    if (lowFrequencyDetection.isValid()) {
      return lowFrequencyDetection;
    }
    
    // 无特殊噪音
    return new SpecialNoiseDetection();
  }

  /**
   * 检测脉冲噪音
   */
  private detectImpulseNoise(): SpecialNoiseDetection {
    if (this.historicalData.length < 2) {
      return new SpecialNoiseDetection();
    }
    
    const recentData = this.historicalData.slice(-10); // 使用最近10个数据点
    
    // 查找梯度超过阈值的点
    let maxGradient = 0;
    let maxGradientIndex = -1;
    
    for (let i = 0; i < recentData.length; i++) {
      const gradient = Math.abs(recentData[i].gradient);
      if (gradient > maxGradient) {
        maxGradient = gradient;
        maxGradientIndex = i;
      }
    }
    
    // 检查是否超过阈值
    if (maxGradient > this.config.impulseNoise.gradientThreshold && 
        maxGradientIndex >= 0) {
      
      const impulseData = recentData[maxGradientIndex];
      const intensity = impulseData.decibel;
      
      // 检查强度阈值
      if (intensity >= this.config.impulseNoise.intensityThreshold) {
        
        // 计算强度（基于梯度和分贝值）
        const calculatedIntensity = Math.min(100, 
          (maxGradient / this.config.impulseNoise.gradientThreshold) * 50 + 
          (intensity / 120) * 50
        );
        
        console.info(`[HealthImpactService] 检测到脉冲噪音: ` +
          `梯度=${maxGradient.toFixed(1)}dB/s, 强度=${intensity.toFixed(1)}dB`);
        
        return new SpecialNoiseDetection(
          SpecialNoiseType.IMPULSE,
          calculatedIntensity,
          this.config.impulseNoise.durationThreshold,
          0 // 脉冲噪音无特定频率
        );
      }
    }
    
    return new SpecialNoiseDetection();
  }

  /**
   * 检测低频共振噪音
   */
  private async detectLowFrequencyNoise(): Promise<SpecialNoiseDetection> {
    // 检查是否有可用的FFT数据
    if (this.fftBufferManager.isEmpty()) {
      return new SpecialNoiseDetection();
    }
    
    try {
      // 获取FFT缓冲区数据
      const fftBuffer = this.fftBufferManager.getBuffer();
      
      // 执行FFT变换
      const spectrum = this.fftAnalyzer.transform(fftBuffer, WeightingType.A);
      
      // 分析低频能量
      const lowFreqEnergy = this.fftAnalyzer.getFrequencyRangeEnergy(
        spectrum,
        this.config.lowFrequency.frequencyRange[0],
        this.config.lowFrequency.frequencyRange[1]
      );
      
      // 分析全频段能量
      const totalEnergy = this.fftAnalyzer.getFrequencyRangeEnergy(
        spectrum,
        20, // 20Hz起始
        20000 // 20kHz结束
      );
      
      // 计算低频主导性
      const lowFreqDominance = lowFreqEnergy > -100 ? 
        Math.pow(10, (lowFreqEnergy - totalEnergy) / 10) * 100 : 0;
      
      // 检查是否满足低频共振条件
      if (lowFreqEnergy >= this.config.lowFrequency.energyThreshold &&
          lowFreqDominance >= this.config.lowFrequency.dominanceThreshold) {
        
        // 计算强度（基于能量和主导性）
        const intensity = Math.min(100,
          (lowFreqEnergy / 120) * 60 + 
          (lowFreqDominance / 100) * 40
        );
        
        // 计算主要频率（取低频范围中间值）
        const mainFrequency = (this.config.lowFrequency.frequencyRange[0] + 
          this.config.lowFrequency.frequencyRange[1]) / 2;
        
        console.info(`[HealthImpactService] 检测到低频共振: ` +
          `能量=${lowFreqEnergy.toFixed(1)}dB, 主导性=${lowFreqDominance.toFixed(1)}%`);
        
        return new SpecialNoiseDetection(
          SpecialNoiseType.LOW_FREQUENCY,
          intensity,
          this.config.lowFrequency.durationThreshold,
          mainFrequency
        );
      }
      
    } catch (error) {
      console.error('[HealthImpactService] 低频共振检测失败:', error);
    }
    
    return new SpecialNoiseDetection();
  }

  /**
   * 处理音频数据（用于FFT分析）
   * @param audioData 音频数据缓冲区
   */
  public processAudioData(audioData: ArrayBuffer): void {
    if (!this.isInitialized) {
      return;
    }
    
    try {
      // 添加到FFT缓冲区
      const isReady = this.fftBufferManager.addData(audioData);
      
      if (isReady) {
        // 缓冲区已满，可以触发特殊噪音检测
        // 检测将在下一次更新周期中进行
        console.debug('[HealthImpactService] FFT缓冲区已满，准备进行频谱分析');
      }
    } catch (error) {
      console.error('[HealthImpactService] 处理音频数据失败:', error);
    }
  }

  /**
   * 重置服务状态
   */
  public reset(): void {
    this.historicalData = [];
    this.fftBufferManager.reset();
    this.currentHealthData.reset();
    console.info('[HealthImpactService] 服务状态已重置');
  }

  /**
   * 销毁服务
   */
  public destroy(): void {
    this.stopRealTimeUpdates();
    this.reset();
    HealthImpactService.instance = null;
    this.isInitialized = false;
    console.info('[HealthImpactService] 服务已销毁');
  }

  /**
   * 检查服务是否已初始化
   */
  public isServiceInitialized(): boolean {
    return this.isInitialized;
  }

  /**
   * 获取服务状态信息
   */
  public getServiceStatus(): string {
    return `健康影响服务状态: ${this.isInitialized ? '运行中' : '未初始化'}, ` +
           `历史数据: ${this.historicalData.length}条, ` +
           `FFT缓冲区: ${this.fftBufferManager.getProgress().toFixed(1)}%`;
  }
}

// 导出默认实例
export const healthImpactService: HealthImpactService = HealthImpactService.getInstance();