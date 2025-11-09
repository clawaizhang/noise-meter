import { FFTBufferManager, BufferStatus } from './FFTBufferManager';
import { AudioAnalysisConfig, AudioPresets, AudioAnalysisMode } from '../common/AudioConfig';

/**
 * 音频流处理器 - 重构版本
 * 支持连续音频处理和重叠FFT分析
 */
export class AudioStreamProcessor {
  private fftBufferManager: FFTBufferManager;
  private currentConfig: AudioAnalysisConfig;
  private isProcessing: boolean = false;
  private calculateAudioDataCallBack: ((buffer: ArrayBuffer) => void) | null = null;
  private lastProcessTime: number = 0;
  private processingTimer: number | null = null; // 用于定时处理的计时器
  
  /**
   * 构造函数
   * @param config 音频分析配置
   */
  constructor(config: AudioAnalysisConfig) {
    this.currentConfig = config;
    // 使用重叠比例初始化缓冲区管理器
    this.fftBufferManager = new FFTBufferManager(config.fftSize, config.overlap);
    console.info(`[音频流处理器] 初始化: FFT大小=${config.fftSize}, 更新间隔=${config.updateInterval}ms, 重叠=${config.overlap}`);
  }
  
  /**
   * 开始处理音频数据
   * @param callback 音频数据回调函数
   */
  startProcessing(callback: (buffer: ArrayBuffer) => void): void {
    if (this.isProcessing) {
      console.warn('[音频流处理器] 已经在处理中');
      return;
    }
    
    this.isProcessing = true;
    this.calculateAudioDataCallBack = callback;
    this.lastProcessTime = Date.now();
    
    // 启动定时处理
    this.startProcessingTimer();
    
    console.info('[音频流处理器] 开始处理音频数据');
  }
  
  /**
   * 停止处理音频数据
   */
  stopProcessing(): void {
    this.isProcessing = false;
    this.calculateAudioDataCallBack = null;
    
    // 停止定时处理
    this.stopProcessingTimer();
    
    // 重置缓冲区
    this.fftBufferManager.reset();
    
    console.info('[音频流处理器] 停止处理音频数据');
  }
  
  /**
   * 启动定时处理
   */
  private startProcessingTimer(): void {
    this.stopProcessingTimer(); // 确保没有重复的定时器
    
    // 使用setInterval进行定期处理检查
    this.processingTimer = setInterval(() => {
      this.checkAndProcessData();
    }, this.currentConfig.updateInterval);
  }
  
  /**
   * 停止定时处理
   */
  private stopProcessingTimer(): void {
    if (this.processingTimer !== null) {
      clearInterval(this.processingTimer);
      this.processingTimer = null;
    }
  }
  
  /**
   * 检查并处理数据
   */
  private checkAndProcessData(): void {
    if (!this.isProcessing || !this.calculateAudioDataCallBack) {
      return;
    }
    
    // 检查是否有足够数据进行处理
    if (!this.fftBufferManager.canProcess()) {
      return;
    }
    
    try {
      // 获取窗口数据
      const windowData = this.fftBufferManager.getWindow();
      
      console.debug(`[音频流处理器] 处理窗口数据: ${windowData.byteLength}字节`);
      
      // 调用回调函数处理数据
      this.calculateAudioDataCallBack(windowData);
      
      // 前进窗口位置（保留重叠部分）
      this.fftBufferManager.advanceWindow();
      
      // 更新时间戳
      this.lastProcessTime = Date.now();
      
      // 输出缓冲区状态
      const status = this.fftBufferManager.getStatus();
      console.debug(`[音频流处理器] 处理完成，缓冲区状态: ` +
        `可用=${status.availableSamples}, 利用率=${(status.utilization * 100).toFixed(1)}%`);
      
    } catch (error) {
      console.error(`[音频流处理器] 处理音频数据时出错: ${error instanceof Error ? error.message : String(error)}`);
      // 出错时重置缓冲区
      this.fftBufferManager.reset();
    }
  }
  
  /**
   * 处理原始音频数据
   * @param buffer 音频数据缓冲区
   */
  processAudioData(buffer: ArrayBuffer): void {
    if (!this.isProcessing) {
      console.debug('[音频流处理器] 未在处理状态，忽略数据');
      return;
    }
    
    try {
      // 添加数据到缓冲区
      const wasEmpty = this.fftBufferManager.isEmpty();
      this.fftBufferManager.addData(buffer);
      
      // 如果缓冲区之前为空，现在有数据，立即尝试处理
      if (wasEmpty && this.fftBufferManager.canProcess()) {
        this.checkAndProcessData();
      }
      
    } catch (error) {
      console.error(`[音频流处理器] 添加音频数据时出错: ${error instanceof Error ? error.message : String(error)}`);
      // 出错时重置缓冲区
      this.fftBufferManager.reset();
    }
  }
  
  /**
   * 更新配置
   * @param config 新的音频分析配置
   */
  updateConfig(config: AudioAnalysisConfig): void {
    console.info(`[音频流处理器] 更新配置: FFT大小=${config.fftSize}, 更新间隔=${config.updateInterval}ms, 窗函数类型=${config.windowType}, 重叠=${config.overlap}`);
    
    // 检查是否只是窗函数变更
    const isOnlyWindowFunctionChange =
      this.currentConfig.fftSize === config.fftSize &&
      this.currentConfig.updateInterval === config.updateInterval &&
      this.currentConfig.overlap === config.overlap &&
      this.currentConfig.windowType !== config.windowType;
    
    // 如果只是窗函数变更，不需要重置处理流程
    if (isOnlyWindowFunctionChange) {
      console.info(`[音频流处理器] 仅更新窗函数类型，不中断处理流程`);
      this.currentConfig = config;
      // 重启定时器以应用新的更新间隔（如果有变化）
      if (this.isProcessing) {
        this.startProcessingTimer();
      }
      return;
    }
    
    // 保存处理状态
    const wasProcessing = this.isProcessing;
    
    // 如果正在处理，先停止
    if (wasProcessing) {
      this.stopProcessing();
    }
    
    // 更新配置
    this.currentConfig = config;
    
    // 更新缓冲区管理器设置
    this.fftBufferManager.updateSettings(config.fftSize, config.overlap);
    
    // 如果之前在处理，重新开始
    if (wasProcessing && this.calculateAudioDataCallBack) {
      this.startProcessing(this.calculateAudioDataCallBack);
    }
    
    // 重置处理时间，避免配置变更导致的处理间隔问题
    this.lastProcessTime = Date.now();
  }
  
  /**
   * 从持久化存储更新窗函数配置
   * 这个方法允许在不中断音频处理的情况下更新窗函数设置
   */
  updateWindowFunctionFromPreferences(): void {
    // 从AudioPresets获取最新配置（包含最新的窗函数设置）
    const updatedConfig = AudioPresets.getConfig(AudioAnalysisMode.CUSTOM_TIME_WEIGHTING);
    
    // 检查窗函数是否有变化
    if (updatedConfig.windowType !== this.currentConfig.windowType ||
        updatedConfig.kaiserBeta !== this.currentConfig.kaiserBeta ||
        updatedConfig.gaussianSigma !== this.currentConfig.gaussianSigma ||
        updatedConfig.tukeyAlpha !== this.currentConfig.tukeyAlpha ||
        updatedConfig.chebyshevAttenuation !== this.currentConfig.chebyshevAttenuation) {
      
      console.info(`[音频流处理器] 从持久化存储更新窗函数配置: ` +
        `类型=${updatedConfig.windowType}, KaiserBeta=${updatedConfig.kaiserBeta}, ` +
        `GaussianSigma=${updatedConfig.gaussianSigma}, TukeyAlpha=${updatedConfig.tukeyAlpha}, ` +
        `ChebyshevAttenuation=${updatedConfig.chebyshevAttenuation}`);
      
      // 只更新窗函数相关配置，保持其他配置不变
      const newConfig = this.currentConfig.clone();
      newConfig.windowType = updatedConfig.windowType;
      newConfig.kaiserBeta = updatedConfig.kaiserBeta;
      newConfig.gaussianSigma = updatedConfig.gaussianSigma;
      newConfig.tukeyAlpha = updatedConfig.tukeyAlpha;
      newConfig.chebyshevAttenuation = updatedConfig.chebyshevAttenuation;
      
      // 使用优化的更新方法，只更新窗函数而不中断处理
      this.updateConfig(newConfig);
    }
  }
  
  /**
   * 获取当前配置
   * @returns 当前音频分析配置
   */
  getCurrentConfig(): AudioAnalysisConfig {
    return this.currentConfig;
  }
  
  /**
   * 获取FFT缓冲区管理器
   * @returns FFT缓冲区管理器实例
   */
  getFFTBufferManager(): FFTBufferManager {
    return this.fftBufferManager;
  }
  
  /**
   * 检查是否正在处理
   * @returns 是否正在处理
   */
  isProcessingAudio(): boolean {
    return this.isProcessing;
  }
  
  /**
   * 获取缓冲区状态
   * @returns 缓冲区状态信息
   */
  getBufferStatus(): BufferStatus {
    return this.fftBufferManager.getStatus();
  }
  
  /**
   * 强制处理当前可用数据
   * 即使未达到更新间隔也进行处理
   */
  forceProcess(): void {
    if (this.isProcessing && this.fftBufferManager.canProcess()) {
      this.checkAndProcessData();
    }
  }
  
  /**
   * 重置处理器状态
   */
  reset(): void {
    this.fftBufferManager.reset();
    this.lastProcessTime = Date.now();
    console.info('[音频流处理器] 状态已重置');
  }
  
  /**
   * 销毁处理器
   */
  destroy(): void {
    this.stopProcessing();
    console.info('[音频流处理器] 已销毁');
  }
}