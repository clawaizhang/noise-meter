import audio from '@ohos.multimedia.audio';
import { PermissionUtil } from '@pura/harmony-utils';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { WavFileGenerator } from '../utils/WavFileGenerator';
import { PreferenceService, PreferenceValue } from './PreferenceService';
import { AudioAnalysisConfig, AudioAnalysisMode, AudioPresets, PREF_ANALYSIS_MODE } from '../common/AudioConfig';
import { FileService } from './FileService';
import { FrequencyWeighting } from '../utils/FrequencyWeighting';

/**
 * 音频服务类
 * 提供音频采集功能
 */

// 音频配置键名
const PREF_TARGET_SAMPLES = 'audio_target_samples';
const PREF_PROCESS_INTERVAL = 'audio_process_interval';
const DEFAULT_TARGET_SAMPLES = 8192;
const DEFAULT_PROCESS_INTERVAL = 50;

/**
 * 音频服务状态
 */
enum AudioServiceState {
  IDLE = 'IDLE',                     // 空闲状态
  STARTING = 'STARTING',             // 正在启动
  CAPTURING = 'CAPTURING',           // 采集中
  STOPPING = 'STOPPING',             // 正在停止
  SWITCHING_MODE = 'SWITCHING_MODE'  // 切换模式中
}

export class AudioService {
  private audioCapturerOptions: audio.AudioCapturerOptions = {
    streamInfo: {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
      channels: audio.AudioChannel.CHANNEL_1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
    },
    capturerInfo: {
      source: audio.SourceType.SOURCE_TYPE_MIC,
      capturerFlags: 0
    }
  };

  // 音频采集器实例
  private audioCapturer: audio.AudioCapturer | null = null;
  
  // 回调函数引用
  private readDataCallback: ((buffer: ArrayBuffer) => void) | null = null;
  
  // 状态标志
  private state: AudioServiceState = AudioServiceState.IDLE;
  private isProcessing: boolean = false;
  private isRecording: boolean = false;
  
  // 缓冲区相关
  private tempBuffer: ArrayBuffer | null = null;
  private overlapBuffer: ArrayBuffer | null = null;
  private tempBufferOffset: number = 0;
  private audioBuffers: ArrayBuffer[] = [];
  private lastProcessTime: number = 0;
  
  // 配置和回调
  private currentConfig = AudioPresets.getConfig(AudioAnalysisMode.BALANCED);
  private onAudioData: ((buffer: ArrayBuffer) => void) | null = null;

  private context: common.UIAbilityContext;
  private preferenceService: PreferenceService;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
    this.preferenceService = PreferenceService.getInstance();
    
    // 从首选项加载分析模式
    const savedMode: string = this.preferenceService.getString(PREF_ANALYSIS_MODE, AudioAnalysisMode.BALANCED);
    if (Object.values(AudioAnalysisMode).includes(savedMode as AudioAnalysisMode)) {
      this.currentConfig = AudioPresets.getConfig(savedMode as AudioAnalysisMode);
      console.info(`[音频采集] 加载配置: 模式=${savedMode}, FFT大小=${this.currentConfig.fftSize}, ` +
                  `处理间隔=${this.currentConfig.processInterval}ms, 重叠率=${this.currentConfig.overlap}`);
    } else {
      console.error(`[音频采集] 无效的保存模式: ${savedMode}，使用默认模式`);
      this.currentConfig = AudioPresets.getConfig(AudioAnalysisMode.BALANCED);
    }

    // 初始化频率计权分析器
    FrequencyWeighting.initializeAnalyzer(savedMode as AudioAnalysisMode);

    // 添加配置变更监听
    this.preferenceService.addChangeListener(PREF_ANALYSIS_MODE, (key: string, value: PreferenceValue) => {
      if (key === PREF_ANALYSIS_MODE && typeof value === 'string') {
        void this.handleModeChange(value);
      }
    });
  }

  /**
   * 检查麦克风权限
   * @private
   * @returns Promise<boolean>
   */
  private async checkMicrophonePermission(): Promise<boolean> {
    try {
      const hasPermission = await PermissionUtil.checkPermissions('ohos.permission.MICROPHONE');
      if (hasPermission) {
        return true;
      }

      const granted = await PermissionUtil.requestPermissions(['ohos.permission.MICROPHONE']);
      if (!granted) {
        // 用户拒绝了权限，显示提示对话框
        const result = await promptAction.showDialog({
          title: '需要录音权限',
          message: '检测噪音需要使用麦克风，是否去设置开启权限？',
          buttons: [
            { text: '取消', color: '#666666' },
            { text: '去设置', color: '#2196F3' }
          ]
        });

        if (result.index === 1) {
          // 用户点击了"去设置"
          await PermissionUtil.requestPermissionOnSettingEasy(['ohos.permission.MICROPHONE']);
          // 从设置页面返回后，重新检查权限
          const newPermissionStatus = await PermissionUtil.checkPermissions('ohos.permission.MICROPHONE');
          return newPermissionStatus;
        }
      }
      return granted;
    } catch (err) {
      console.error('Failed to check/request microphone permission:', err);
      return false;
    }
  }

  /**
   * 开始录音
   */
  startRecording(): void {
    this.isRecording = true;
    this.audioBuffers = []; // 清空之前的录音数据
  }

  /**
   * 停止录音
   */
  stopRecording(): void {
    this.isRecording = false;
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
      this.audioCapturer = await audio.createAudioCapturer(this.audioCapturerOptions);
      console.info('[音频采集] 音频采集器创建成功');

      // 开始读取音频数据
      await this.startReading();
      
      this.setState(AudioServiceState.CAPTURING);
      console.info('[音频采集] 音频采集已启动');
    } catch (err) {
      const errMsg = `启动音频采集失败: ${err instanceof Error ? err.message : String(err)}`;
      console.error(`[音频采集] ${errMsg}`);
      this.setState(AudioServiceState.IDLE);
      throw new Error(errMsg);
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
            this.processAudioData(buffer);
            
            // 如果正在录音，保存数据
            if (this.isRecording) {
              this.audioBuffers.push(buffer.slice(0));  // 创建副本以避免引用问题
            }
          }
        } catch (err) {
          console.error('[音频采集] 处理音频数据时出错:', err);
        }
      };

      // 使用具名函数以便后续移除监听器
      this.audioCapturer.on('readData', readDataCallback);
      
      // 保存回调引用
      this.readDataCallback = readDataCallback;

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
      // 先停止音频数据读取
      await this.audioCapturer.stop();
      console.info('[音频采集] 停止读取音频数据');
      
      // 移除readData事件监听器
      if (this.readDataCallback) {
        try {
          this.audioCapturer.off('readData', this.readDataCallback);
        } catch (err) {
          console.warn('[音频采集] 移除readData监听器时出错:', err);
        }
        this.readDataCallback = null;
      }
    } catch (err) {
      const errMsg = `停止音频数据读取失败: ${err instanceof Error ? err.message : String(err)}`;
      console.error(`[音频采集] ${errMsg}`);
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
    this.isProcessing = true;
    this.onAudioData = callback;
    this.lastProcessTime = Date.now();
  }

  /**
   * 停止处理音频数据
   */
  stopProcessing(): void {
    this.isProcessing = false;
    this.onAudioData = null;
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
    return this.isProcessing;
  }

  /**
   * 停止录音并获取WAV文件路径
   * @param fileService 文件服务实例
   * @returns Promise<string> 保存的WAV文件路径
   */
  async stopRecordingAndGetWavData(fileService: FileService): Promise<string> {
    try {
      // 停止录音
      this.stopRecording();

      console.info('开始生成WAV音频数据');
      // 生成WAV文件数据
      const audioData = WavFileGenerator.generateWavFile(
        this.audioBuffers,
        44100,  // 采样率
        1,     // 单声道
        16     // 16位采样
      );
      console.info('WAV音频数据大小:', audioData.byteLength);

      // 创建音频文件目录
      const audioDir = 'audio';
      try {
        await fileService.createDirectory(audioDir);
      } catch (error) {
        // 目录可能已存在，忽略错误
      }

      // 生成文件名并保存WAV文件
      const fileName = `audio_${new Date().getTime()}.wav`;
      const relativePath = `${audioDir}/${fileName}`;
      console.info('准备保存音频文件:', relativePath);
      const filePath = await fileService.saveFile(relativePath, audioData);
      console.info('音频文件保存成功:', filePath);

      // 清空录音缓存
      this.audioBuffers = [];

      return filePath;
    } catch (error) {
      console.error('停止录音并保存WAV文件失败:', error);
      throw new Error('停止录音并保存WAV文件失败：' + (error instanceof Error ? error.message : String(error)));
    }
  }

  /**
   * 处理音频分析模式变更
   */
  private handleModeChange(value: string): void {
    void Promise.resolve().then(async () => {
      try {
        // 如果不是空闲或采集状态，不允许切换模式
        if (this.state !== AudioServiceState.IDLE && 
            this.state !== AudioServiceState.CAPTURING) {
          console.info(`[音频采集] 当前状态 ${this.state} 不允许切换模式`);
          return;
        }

        // 验证并转换模式
        if (!Object.values(AudioAnalysisMode).includes(value as AudioAnalysisMode)) {
          throw new Error(`无效的音频分析模式: ${value}`);
        }
        const mode = value as AudioAnalysisMode;

        // 记录当前状态
        const wasCapturing = this.state === AudioServiceState.CAPTURING;
        
        if (wasCapturing) {
          this.setState(AudioServiceState.SWITCHING_MODE);
          
          // 先停止处理
          this.stopProcessing();
          
          // 停止采集
          await this.stopCapture();
        }
        
        // 更新配置
        this.currentConfig = AudioPresets.getConfig(mode);
        
        // 更新分析器配置
        FrequencyWeighting.updateAnalysisMode(mode);
        
        // 重置缓冲区
        this.resetBuffers();
        
        // 如果之前在采集，重新开始采集
        if (wasCapturing) {
          await this.startCapture();
        }
        
        console.info(`[音频采集] 模式已更新为: ${mode}`);
      } catch (err) {
        console.error(`[音频采集] 更新模式失败: ${err instanceof Error ? err.message : String(err)}`);
        // 确保状态重置
        this.setState(AudioServiceState.IDLE);
      }
    });
  }

  /**
   * 销毁服务
   */
  public destroy(): void {
    // 移除监听器
    this.preferenceService.removeChangeListener(PREF_ANALYSIS_MODE, this.handleModeChange);
    
    // 停止采集
    if (this.state === AudioServiceState.CAPTURING) {
      this.stopCapture();
    }
  }

  /**
   * 设置分析模式
   * @param mode 分析模式
   */
  public async setAnalysisMode(mode: AudioAnalysisMode): Promise<void> {
    // 保存到首选项
    await this.preferenceService.setString(PREF_ANALYSIS_MODE, mode);
    
    // 更新配置
    this.currentConfig = AudioPresets.getConfig(mode);
    
    // 重置缓冲区
    this.resetBuffers();
    
    console.info(`[音频采集] 切换到${mode}模式`);
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
      const currentTime = Date.now();
      
      // 处理实时音频数据
      if (this.isProcessing && 
          currentTime - this.lastProcessTime >= this.currentConfig.processInterval) {
        
        // 将数据复制到临时缓冲区
        if (!this.tempBuffer || this.tempBuffer.byteLength !== this.currentConfig.fftSize * 2) {
          console.info(`[音频采集] 创建新的临时缓冲区, 大小: ${this.currentConfig.fftSize * 2}`);
          this.tempBuffer = new ArrayBuffer(this.currentConfig.fftSize * 2); // 16位采样，每个样本2字节
        }
        
        const newData = new Int16Array(buffer);
        const tempView = new Int16Array(this.tempBuffer);
        
        // 处理重叠部分
        if (this.overlapBuffer) {
          const overlapView = new Int16Array(this.overlapBuffer);
          tempView.set(overlapView);
          this.tempBufferOffset = overlapView.length;
          console.debug('[音频采集] 处理重叠部分, 偏移量:', this.tempBufferOffset);
        } else {
          const overlapSize = Math.floor(this.currentConfig.fftSize * this.currentConfig.overlap);
          this.overlapBuffer = new ArrayBuffer(overlapSize * 2);
          this.tempBufferOffset = 0;
          console.debug('[音频采集] 创建新的重叠缓冲区, 大小:', overlapSize * 2);
        }
        
        // 计算需要的新样本数
        const neededSamples = this.currentConfig.fftSize - this.tempBufferOffset;
        const samplesToAdd = Math.min(newData.length, neededSamples);
        console.debug(`[音频采集] 需要的样本数: ${neededSamples}, 实际添加: ${samplesToAdd}`);

        // 复制新数据
        tempView.set(newData.subarray(0, samplesToAdd), this.tempBufferOffset);
        this.tempBufferOffset += samplesToAdd;
        
        // 如果积累了足够的样本，就处理并发送
        if (this.tempBufferOffset >= this.currentConfig.fftSize) {
          console.info(`[音频采集] 处理音频数据，样本数: ${this.currentConfig.fftSize}`);
          
          // 保存重叠部分
          const overlapView = new Int16Array(this.overlapBuffer);
          const overlapStart = this.currentConfig.fftSize - overlapView.length;
          overlapView.set(tempView.subarray(overlapStart));
          
          // 发送数据进行处理
          if (this.onAudioData) {
            console.debug('[音频采集] 发送数据进行处理');
            this.onAudioData(this.tempBuffer);
          }
          
          this.lastProcessTime = currentTime;
          this.tempBufferOffset = 0;
        }
      }
      
      // 存储录音数据
      if (this.isRecording) {
        this.audioBuffers.push(buffer.slice(0));
      }
    } catch (err) {
      console.error(`[音频采集] 处理数据失败: ${err instanceof Error ? err.message : String(err)}`);
      // 不抛出错误，继续处理下一帧
    }
  }

  /**
   * 重置缓冲区
   */
  private resetBuffers(): void {
    this.tempBuffer = null;
    this.overlapBuffer = null;
    this.tempBufferOffset = 0;
    this.lastProcessTime = 0;
    this.audioBuffers = [];
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

    // 保存到首选项
    await this.preferenceService.setNumber(PREF_TARGET_SAMPLES, targetSamples);
    await this.preferenceService.setNumber(PREF_PROCESS_INTERVAL, processInterval);
    
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
  }
}