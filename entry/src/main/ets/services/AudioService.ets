import audio from '@ohos.multimedia.audio';
import common from '@ohos.app.ability.common';
import { WavFileGenerator } from '../utils/WavFileGenerator';
import { AudioAnalysisMode, AudioPresets } from '../common/AudioConfig';
import { FileUtils } from '../utils/FileUtils';
import { PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../models/PreferenceKeys';
import { PermissionService } from './PermissionService';
import { AudioStreamProcessor } from '../utils/AudioStreamProcessor';

/**
 * 音频服务类
 * 提供音频采集功能
 */

/**
 * 音频服务状态
 */
export enum AudioServiceState {
  IDLE = 'IDLE', // 空闲状态
  STARTING = 'STARTING', // 正在启动
  CAPTURING = 'CAPTURING', // 采集中
  STOPPING = 'STOPPING', // 正在停止
  SWITCHING_MODE = 'SWITCHING_MODE' // 切换模式中
}

export class AudioService {
  private static instance: AudioService | null = null;
  private pk: PreferenceKeys;

  /**
   * 获取 AudioService 实例
   */
  public static getInstance(pk: PreferenceKeys): AudioService {
    if (!AudioService.instance) {
      AudioService.instance = new AudioService(pk);
    }
    return AudioService.instance;
  }

  private audioCapturerOptions: audio.AudioCapturerOptions = {
    streamInfo: {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
      channels: audio.AudioChannel.CHANNEL_1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
    },
    capturerInfo: {
      // source: audio.SourceType.SOURCE_TYPE_UNPROCESSED,
      source: audio.SourceType.SOURCE_TYPE_VOICE_RECOGNITION,
      capturerFlags: 0
    }
  };
  // 音频采集器实例
  private audioCapturer: audio.AudioCapturer | null = null;
  // 回调函数引用
  private readDataCallback: ((buffer: ArrayBuffer) => void) | null = null;
  private stateChangeCallback: ((info: audio.AudioCapturerChangeInfo) => void) | null = null;
  // 状态标志
  private state: AudioServiceState = AudioServiceState.IDLE;
  // 配置和回调
  private currentConfig = AudioPresets.getConfig(AudioAnalysisMode.FAST_TIME_WEIGHTING);
  // 状态变更回调类型
  private stateChangeCallbacks: ((state: AudioServiceState) => void)[] = [];
  // 音频流处理器
  private audioStreamProcessor: AudioStreamProcessor;
  private originAudioDataCallBack: ((buffer: ArrayBuffer) => void) | null = null;

  constructor(pk: PreferenceKeys) {
    // 初始化默认配置
    this.currentConfig = AudioPresets.FAST_TIME_WEIGHTING;
    this.pk = pk;
    
    // 初始化音频流处理器
    this.audioStreamProcessor = new AudioStreamProcessor(this.currentConfig);
    
    console.info(`[音频采集] 初始化默认配置`);
  }

  /**
   * 初始化配置（从外部调用）
   * 应该在组件初始化后调用
   */
  public initializeConfig(): void {
    // 从首选项加载分析模式
    this.currentConfig = AudioPresets.getConfig(this.pk.audio_analysis_mode!);
    
    // 应用采样率配置到音频采集器
    this.applySampleRateConfig();
    
    // 更新音频流处理器配置
    this.audioStreamProcessor.updateConfig(this.currentConfig);
    
    console.info(`[音频采集] 加载配置: 模式=${this.pk.audio_analysis_mode!}, FFT大小=${this.currentConfig.fftSize}, ` +
      `处理间隔=${this.currentConfig.updateInterval}ms, 重叠率=${this.currentConfig.overlap}, ` +
      `采样率=${this.currentConfig.sampleRate}Hz, 降采样=${this.currentConfig.decimationEnabled}, ` +
      `降采样因子=${this.currentConfig.decimationFactor}`);
  }

  registerOriginAudioDataCallBack(callback: (buffer: ArrayBuffer) => void){
    this.originAudioDataCallBack = callback;
  }

  /**
   * 检查麦克风权限
   * @private
   * @returns Promise<boolean>
   */
  private async checkMicrophonePermission(): Promise<boolean> {
    try {
      const permissionService = PermissionService.getInstance();
      return await permissionService.checkAndUpdateMicrophonePermission();
    } catch (err) {
      console.error('检查麦克风权限失败:', err);
      return false;
    }
  }

  /**
   * 开始音频采集
   * @returns Promise<void>
   */
  public async startCapture(): Promise<void> {
    if (this.state !== AudioServiceState.IDLE) {
      console.info(`[音频采集] 当前状态 ${this.state} 不允许启动采集`);
      return;
    }

    try {
      this.setState(AudioServiceState.STARTING);

      // 检查权限
      console.info('[音频采集] 开始检查麦克风权限');
      const hasPermission = await this.checkMicrophonePermission();
      if (!hasPermission) {
        console.error('[音频采集] 没有麦克风权限');
        throw new Error('没有麦克风权限');
      }

      // 创建音频采集器
      console.info('[音频采集] 开始创建音频采集器');
      console.info(`[音频采集] 采集器配置: 采样率=${this.audioCapturerOptions.streamInfo.samplingRate}, ` +
        `通道数=${this.audioCapturerOptions.streamInfo.channels}, ` +
        `缓冲区大小=${this.currentConfig.bufferSize}`);
      this.audioCapturer = await audio.createAudioCapturer(this.audioCapturerOptions);
      console.info('[音频采集] 音频采集器创建成功');
      this.audioCapturer.on('audioInterrupt', async (interruptEvent: audio.InterruptEvent) => {
        this.state = AudioServiceState.IDLE;
        const maxRetries = 3;
        const retryInterval = 1000; // 1秒
        let retryCount = 0;
        while (true) {
          try {
            await this.startCapture();
            console.info('[FREQ_TRACE][Audio] 音频采集启动成功');
            break; // 成功则退出循环
          } catch (error) {
            retryCount++;
            console.error(`[FREQ_TRACE][Audio] 音频采集启动失败，重试次数：${retryCount}/${maxRetries}`, error);
            await new Promise<void>(resolve => setTimeout(resolve, retryInterval));
          }
        }
      })
      // 开始读取音频数据
      await this.startReading();

      this.setState(AudioServiceState.CAPTURING);
      console.info('[音频采集] 音频采集已启动');
    } catch (err) {
      const errMsg = `启动音频采集失败: ${String(err)}`;
      console.error(`[音频采集] ${errMsg}`);
      this.setState(AudioServiceState.IDLE);

      // 检查是否是资源占用错误
      throw err as Error;
    }
  }

  /**
   * 开始读取音频数据
   * @private
   */
  private async startReading(): Promise<void> {
    console.info('[音频采集] startReading 开始');
    if (!this.audioCapturer || this.state !== AudioServiceState.STARTING) {
      console.error('[音频采集] 音频采集器未初始化或状态错误');
      throw new Error('音频采集器未初始化或状态错误');
    }

    try {
      console.info('[音频采集] 准备注册 readData 事件监听器');
      // 注册readData事件监听器
      const readDataCallback = (buffer: ArrayBuffer) => {
        try {
          if (this.state !== AudioServiceState.CAPTURING) {
            return;
          }
          // 处理音频数据
          if (buffer && buffer.byteLength > 0) {
            console.info(`[音频采集] 收到音频数据: 大小=${buffer.byteLength}字节, 样本数=${buffer.byteLength / 2}`);
            this.processAudioData(buffer);
          }
        } catch (err) {
          console.error('[音频采集] 处理音频数据时出错:', err);
        }
      };

      // 注册音频采集器变更监听器
      const stateChangeCallback = (info: audio.AudioCapturerChangeInfo) => {
        console.info(`[音频采集] 音频采集器状态变更: ${JSON.stringify(info)}`);
      };

      // 使用具名函数以便后续移除监听器
      this.audioCapturer.on('readData', readDataCallback);
      this.audioCapturer.on('audioCapturerChange', stateChangeCallback);

      // 保存回调引用
      this.readDataCallback = readDataCallback;
      this.stateChangeCallback = stateChangeCallback;

      // 启动音频数据读取
      console.info('[音频采集] 准备启动音频采集器');
      await this.audioCapturer.start();
      console.info('[音频采集] 开始读取音频数据');
    } catch (err) {
      const errMsg = `启动音频数据读取失败: ${err instanceof Error ? err.message : String(err)}`;
      console.error(`[音频采集] ${errMsg}`);
      throw new Error(errMsg);
    }
  }

  /**
   * 停止读取音频数据
   * @private
   */
  private async stopReading(): Promise<void> {
    if (!this.audioCapturer) {
      return;
    }

    try {
      // 移除事件监听器
      if (this.readDataCallback) {
        this.audioCapturer.off('readData', this.readDataCallback);
        this.readDataCallback = null;
      }
      if (this.stateChangeCallback) {
        this.audioCapturer.off('audioCapturerChange', this.stateChangeCallback);
        this.stateChangeCallback = null;
      }

      // 停止音频采集器
      await this.audioCapturer.stop();
      console.info('[音频采集] 停止读取音频数据');
    } catch (err) {
      console.error('[音频采集] 停止音频数据读取时出错:', err);
    }
  }

  /**
   * 暂停采集音频（停止采集但保留数据）
   */
  public async pauseCapture(): Promise<void> {
    if (this.state !== AudioServiceState.CAPTURING) {
      console.info(`[音频采集] 当前状态 ${this.state} 不需要暂停采集`);
      return;
    }

    try {
      this.setState(AudioServiceState.STOPPING);

      // 停止处理音频数据（但不重置缓冲区）
      // this.stopProcessing();

      // 停止读取音频数据
      // await this.stopReading();

      // 释放音频采集器
      if (this.audioCapturer) {
        try {
          await this.audioCapturer.release();
        } catch (err) {
          console.warn('[音频采集] 释放音频采集器时出错:', err);
        }
      }

      // 注意：这里不重置缓冲区，保留数据
      // this.resetBuffers();

      this.setState(AudioServiceState.IDLE);
      console.info('[音频采集] 音频采集已暂停（数据保留）');
    } catch (err) {
      const errMsg = `暂停音频采集失败: ${err instanceof Error ? err.message : String(err)}`;
      console.error(`[音频采集] ${errMsg}`);
      // 即使出错也要重置状态
      this.setState(AudioServiceState.IDLE);
      throw new Error(errMsg);
    }
  }

  /**
   * 停止采集音频
   */
  public async stopCapture(): Promise<void> {
    if (this.state !== AudioServiceState.CAPTURING &&
      this.state !== AudioServiceState.SWITCHING_MODE) {
      console.info(`[音频采集] 当前状态 ${this.state} 不需要停止采集`);
      return;
    }

    try {
      this.setState(AudioServiceState.STOPPING);

      // 停止处理
      this.stopProcessing();

      // 停止读取音频数据
      await this.stopReading();

      // 释放音频采集器
      if (this.audioCapturer) {
        try {
          await this.audioCapturer.release();
        } catch (err) {
          console.warn('[音频采集] 释放音频采集器时出错:', err);
        }
        this.audioCapturer = null;
      }

      // 重置缓冲区
      this.resetBuffers();

      this.setState(AudioServiceState.IDLE);
      console.info('[音频采集] 音频采集已停止');
    } catch (err) {
      const errMsg = `停止音频采集失败: ${err instanceof Error ? err.message : String(err)}`;
      console.error(`[音频采集] ${errMsg}`);
      // 即使出错也要重置状态
      this.setState(AudioServiceState.IDLE);
      throw new Error(errMsg);
    }
  }

  /**
   * 开始处理音频数据
   * @param callback - 音频数据回调
   */
  startProcessing(callback: (buffer: ArrayBuffer) => void): void {
    this.audioStreamProcessor.startProcessing(callback);
  }

  /**
   * 停止处理音频数据
   */
  stopProcessing(): void {
    this.audioStreamProcessor.stopProcessing();
  }

  /**
   * 获取音频配置
   * @returns AudioStreamInfo
   */
  getAudioConfig(): audio.AudioStreamInfo {
    return this.audioCapturerOptions.streamInfo;
  }

  /**
   * 是否正在采集音频
   */
  isAudioCapturing(): boolean {
    return this.state === AudioServiceState.CAPTURING;
  }

  /**
   * 是否正在处理音频数据
   */
  isAudioProcessing(): boolean {
    return this.audioStreamProcessor.isProcessingAudio();
  }

  /**
   * 停止录音并获取WAV文件路径
   * @param audioBuffers 音频缓冲区数组（可选，如果不提供则使用内部存储的缓冲区）
   * @returns Promise<string> 保存的WAV文件路径
   */
  async stopRecordingAndGetWavData(audioBuffers: ArrayBuffer[]): Promise<string> {
    try {

      console.info('开始生成WAV音频数据');
      // 使用传入的音频缓冲区或内部存储的缓冲区
      console.info(`生成WAV文件，使用${audioBuffers.length}个音频缓冲区`);
      
      // 生成WAV文件数据
      const audioData = WavFileGenerator.generateWavFile(
        audioBuffers,
        44100, // 采样率
        1, // 单声道
        16     // 16位采样
      );
      console.info('WAV音频数据大小:', audioData.byteLength);

      // 创建音频文件目录
      const audioDir = 'audio';
      try {
        await FileUtils.createDirectory(audioDir);
      } catch (error) {
        // 目录可能已存在，忽略错误
      }

      // 生成文件名并保存WAV文件
      const fileName = `audio_${new Date().getTime()}.wav`;
      const relativePath = `${audioDir}/${fileName}`;
      console.info('准备保存音频文件:', relativePath);
      const filePath = await FileUtils.saveFile(relativePath, audioData);
      console.info('音频文件保存成功:', filePath);

      return filePath;
    } catch (error) {
      console.error('停止录音并保存WAV文件失败:', error);
      throw new Error('停止录音并保存WAV文件失败：' + (error instanceof Error ? error.message : String(error)));
    }
  }

  /**
   * 处理音频分析模式变更
   */
  handleModeChange(value: AudioAnalysisMode): void {
    void Promise.resolve().then(async () => {
      try {
        // 验证并转换模式
        if (!Object.values(AudioAnalysisMode).includes(value)) {
          throw new Error(`无效的音频分析模式: ${value}`);
        }
        const mode = value as AudioAnalysisMode;

        // 更新配置
        this.currentConfig = AudioPresets.getConfig(mode);
        this.applySampleRateConfig();
        this.audioStreamProcessor.updateConfig(this.currentConfig);

        console.info(`[音频采集] 模式已更新为: ${mode}, 采样率=${this.currentConfig.sampleRate}Hz`);
      } catch (err) {
        console.error(`[音频采集] 更新模式失败: ${err instanceof Error ? err.message : String(err)}`);
      }
    });
  }

  /**
   * 应用采样率配置
   */
  private applySampleRateConfig(): void {
    // 根据采样率设置音频采集器参数
    switch (this.currentConfig.sampleRate) {
      case 8000:
        this.audioCapturerOptions.streamInfo.samplingRate = audio.AudioSamplingRate.SAMPLE_RATE_8000;
        break;
      case 11025:
        this.audioCapturerOptions.streamInfo.samplingRate = audio.AudioSamplingRate.SAMPLE_RATE_11025;
        break;
      case 16000:
        this.audioCapturerOptions.streamInfo.samplingRate = audio.AudioSamplingRate.SAMPLE_RATE_16000;
        break;
      case 22050:
        this.audioCapturerOptions.streamInfo.samplingRate = audio.AudioSamplingRate.SAMPLE_RATE_22050;
        break;
      case 44100:
        this.audioCapturerOptions.streamInfo.samplingRate = audio.AudioSamplingRate.SAMPLE_RATE_44100;
        break;
      case 48000:
        this.audioCapturerOptions.streamInfo.samplingRate = audio.AudioSamplingRate.SAMPLE_RATE_48000;
        break;
      default:
        console.warn(`[音频采集] 不支持的采样率: ${this.currentConfig.sampleRate}, 使用默认44100Hz`);
        this.audioCapturerOptions.streamInfo.samplingRate = audio.AudioSamplingRate.SAMPLE_RATE_44100;
        this.currentConfig.sampleRate = 44100;
        break;
    }

    // 计算有效采样率（考虑降采样）
    const effectiveSampleRate = this.currentConfig.decimationEnabled ?
      this.currentConfig.sampleRate / this.currentConfig.decimationFactor :
      this.currentConfig.sampleRate;

    console.info(`[音频采集] 采样率配置已应用: 原始采样率=${this.currentConfig.sampleRate}Hz, ` +
      `有效采样率=${effectiveSampleRate}Hz, 降采样启用=${this.currentConfig.decimationEnabled}, ` +
      `降采样因子=${this.currentConfig.decimationFactor}`);
  }

  /**
   * 应用采样率设置变更
   */
  public async applySampleRateSettings(sampleRate: number, decimationEnabled: boolean, decimationFactor: number): Promise<void> {
    const wasCapturing = this.state === AudioServiceState.CAPTURING;
    
    // 如果正在采集，先停止
    if (wasCapturing) {
      await this.stopCapture();
    }
    
    // 更新配置
    this.currentConfig.sampleRate = sampleRate;
    this.currentConfig.decimationEnabled = decimationEnabled;
    this.currentConfig.decimationFactor = decimationFactor;

    // 应用采样率配置到音频采集器
    this.applySampleRateConfig();

    // 更新音频流处理器配置
    this.audioStreamProcessor.updateConfig(this.currentConfig);

    console.info(`[音频采集] 采样率设置已应用: ${sampleRate}Hz, 降采样=${decimationEnabled}, 降采样因子=${decimationFactor}`);
    
    // 如果之前在采集，重新开始采集
    if (wasCapturing) {
      try {
        await this.startCapture();
        console.info(`[音频采集] 采样率更新后重新开始采集成功`);
      } catch (error) {
        console.error(`[音频采集] 采样率更新后重新开始采集失败:`, error);
        throw new Error(`采样率更新后重新开始采集失败: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }

  /**
   * 销毁服务
   */
  public destroy(): void {

    // 停止采集
    if (this.state === AudioServiceState.CAPTURING) {
      this.stopCapture();
    }
    
    // 销毁音频流处理器
    this.audioStreamProcessor.destroy();
  }

  /**
   * 设置分析模式
   * @param mode 分析模式
   */
  public async setAnalysisMode(mode: AudioAnalysisMode): Promise<void> {

    // 更新配置
    this.currentConfig = AudioPresets.getConfig(mode);
    this.audioStreamProcessor.updateConfig(this.currentConfig);

    console.info(`[音频采集] 切换到${mode}模式`);
  }

  /**
   * 重置音频相关数据
   * 清空缓存、重置状态
   */
  public resetData(): void {
    try {
      // 重置缓冲区
      this.resetBuffers();
      console.info('[音频采集] 音频数据已重置');
    } catch (error) {
      console.error('[音频采集] 重置音频数据失败', error);
    }
  }

  /**
   * 处理音频数据
   * @param buffer 音频数据缓冲区
   */
  private processAudioData(buffer: ArrayBuffer): void {
    if (this.state !== AudioServiceState.CAPTURING) {
      return;
    }

    try {
      if (this.originAudioDataCallBack) {
        this.originAudioDataCallBack(buffer.slice(0));
      }
      // 使用音频流处理器处理数据
      this.audioStreamProcessor.processAudioData(buffer);
    } catch (err) {
      console.error(`[音频采集] 处理数据失败: ${err instanceof Error ? err.message : String(err)}`);
      // 不抛出错误，继续处理下一帧
    }
  }

  /**
   * 重置缓冲区
   */
  private resetBuffers(): void {
    console.info(`[音频采集] 重置缓冲区开始`);
    this.audioStreamProcessor.reset();
  }

  /**
   * 更新音频处理配置
   * @param targetSamples 目标样本数
   * @param processInterval 处理间隔（毫秒）
   */
  public async updateConfig(targetSamples: number, processInterval: number): Promise<void> {
    // 验证参数
    if (targetSamples < 1024 || targetSamples > 16384) {
      throw new Error('目标样本数必须在1024到16384之间');
    }
    if (processInterval < 20 || processInterval > 200) {
      throw new Error('处理间隔必须在20到200毫秒之间');
    }

    console.info(`[音频采集] 更新配置: 目标样本数=${targetSamples}, 处理间隔=${processInterval}ms`);
  }

  /**
   * 获取当前FFT大小
   * @returns FFT大小
   */
  public getCurrentFFTSize(): number {
    return this.currentConfig.fftSize;
  }

  /**
   * 设置服务状态
   */
  private setState(newState: AudioServiceState): void {
    const oldState = this.state;
    this.state = newState;
    console.info(`[音频采集] 状态变更: ${oldState} -> ${newState}`);

    // 通知所有监听器
    this.stateChangeCallbacks.forEach(callback => {
      try {
        callback(newState);
      } catch (err) {
        console.error('[音频采集] 状态变更回调执行失败:', err);
      }
    });
  }

  /**
   * 添加状态变更监听
   */
  public addStateChangeListener(callback: (state: AudioServiceState) => void): void {
    this.stateChangeCallbacks.push(callback);
  }

  /**
   * 移除状态变更监听
   */
  public removeStateChangeListener(callback: (state: AudioServiceState) => void): void {
    const index = this.stateChangeCallbacks.indexOf(callback);
    if (index > -1) {
      this.stateChangeCallbacks.splice(index, 1);
    }
  }
}