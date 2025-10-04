import { FFTBufferManager } from './FFTBufferManager';
import { AudioAnalysisConfig } from '../common/AudioConfig';

/**
 * 音频流处理器
 * 使用RxJS风格的流式处理管理音频数据流
 */
export class AudioStreamProcessor {
  private fftBufferManager: FFTBufferManager;
  private currentConfig: AudioAnalysisConfig;
  private isProcessing: boolean = false;
  private audioDataCallback: ((buffer: ArrayBuffer) => void) | null = null;
  private lastProcessTime: number = 0;
  
  /**
   * 构造函数
   * @param config 音频分析配置
   */
  constructor(config: AudioAnalysisConfig) {
    this.currentConfig = config;
    this.fftBufferManager = new FFTBufferManager(config.fftSize);
    console.info(`[音频流处理器] 初始化: FFT大小=${config.fftSize}, 更新间隔=${config.updateInterval}ms`);
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
    this.audioDataCallback = callback;
    this.lastProcessTime = Date.now();
    
    console.info('[音频流处理器] 开始处理音频数据');
  }
  
  /**
   * 停止处理音频数据
   */
  stopProcessing(): void {
    this.isProcessing = false;
    this.audioDataCallback = null;
    this.fftBufferManager.reset();
    
    console.info('[音频流处理器] 停止处理音频数据');
  }
  
  /**
   * 处理原始音频数据
   * @param buffer 音频数据缓冲区
   */
  processAudioData(buffer: ArrayBuffer): void {
    if (!this.isProcessing || !this.audioDataCallback) {
      console.debug('[音频流处理器] 未在处理状态，忽略数据');
      return;
    }
    
    try {
      const currentTime = Date.now();
      
      // 检查处理间隔
      if (currentTime - this.lastProcessTime < this.currentConfig.updateInterval) {
        console.debug(`[音频流处理器] 处理间隔未到: ${currentTime - this.lastProcessTime}ms < ${this.currentConfig.updateInterval}ms`);
        return;
      }
      
      // 累积数据到FFT缓冲区
      const isReady = this.fftBufferManager.addData(buffer);
      
      if (isReady) {
        console.info(`[音频流处理器] 数据块就绪，开始处理: ${this.fftBufferManager.getFFTSize()}样本`);
        
        // 获取完整的缓冲区数据
        const fullBuffer = this.fftBufferManager.getBuffer();
        
        // 调用回调函数
        if (this.audioDataCallback) {
          console.debug(`[音频流处理器] 发送数据到回调: ${fullBuffer.byteLength}字节`);
          this.audioDataCallback(fullBuffer);
        }
        
        // 更新时间戳
        this.lastProcessTime = currentTime;
        
        // 重置缓冲区
        this.fftBufferManager.reset();
        
        console.debug(`[音频流处理器] 处理完成，重置缓冲区`);
      } else {
        console.debug(`[音频流处理器] 数据累积中: ${this.fftBufferManager.getProgress().toFixed(1)}%`);
      }
      
    } catch (error) {
      console.error(`[音频流处理器] 处理音频数据时出错: ${error instanceof Error ? error.message : String(error)}`);
      // 出错时重置缓冲区
      this.fftBufferManager.reset();
    }
  }
  
  /**
   * 更新配置
   * @param config 新的音频分析配置
   */
  updateConfig(config: AudioAnalysisConfig): void {
    console.info(`[音频流处理器] 更新配置: FFT大小=${config.fftSize}, 更新间隔=${config.updateInterval}ms`);
    
    this.currentConfig = config;
    this.fftBufferManager.updateFFTSize(config.fftSize);
    
    // 重置处理时间，避免配置变更导致的处理间隔问题
    this.lastProcessTime = Date.now();
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
   * 重置处理器状态
   */
  reset(): void {
    this.fftBufferManager.reset();
    this.lastProcessTime = 0;
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