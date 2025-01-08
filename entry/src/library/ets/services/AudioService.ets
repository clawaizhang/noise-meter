import audio from '@ohos.multimedia.audio';
import { PermissionUtil } from '@pura/harmony-utils';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { WavFileGenerator } from '../utils/WavFileGenerator';
import { FileService } from '../services/FileService';

/**
 * 音频服务类
 * 提供音频采集功能
 */

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

  private audioCapturer: audio.AudioCapturer | null = null;
  private isCapturing: boolean = false;  // 是否正在采集音频
  private isProcessing: boolean = false; // 是否正在处理音频数据
  private isRecording: boolean = false;  // 是否正在录音
  private isStoppingCapture: boolean = false;
  private onAudioData: ((buffer: ArrayBuffer) => void) | null = null;
  private context: common.UIAbilityContext;
  private lastProcessTime: number = 0;
  private readonly PROCESS_INTERVAL: number = 20; // 减少处理间隔到20毫秒
  private bufferSize: number = 2048; // 实际缓冲区大小，将在创建音频捕获器时更新
  private audioBuffers: ArrayBuffer[] = []; // 存储录音数据

  constructor(context: common.UIAbilityContext) {
    this.context = context;
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
  async startCapture(): Promise<void> {
    if (this.isCapturing || this.isStoppingCapture) {
      return;
    }

    // 检查麦克风权限
    const hasPermission = await this.checkMicrophonePermission();
    if (!hasPermission) {
      throw new Error('没有麦克风权限');
    }

    try {
      // 清空之前的录音数据
      this.audioBuffers = [];
      this.isRecording = false;

      // 创建音频捕获器
      this.audioCapturer = await audio.createAudioCapturer(this.audioCapturerOptions);
      console.info('[音频采集] 音频捕获器创建成功');
      
      // 获取并保存实际的缓冲区大小
      this.bufferSize = await this.audioCapturer.getBufferSize();
      console.info(`[音频采集] 当前缓冲区大小: ${this.bufferSize}`);

      // 设置readData事件监听
      this.audioCapturer.on('readData', (buffer: ArrayBuffer) => {
        if (!this.isCapturing || this.isStoppingCapture) {
          return;
        }
        
        if (buffer && buffer.byteLength > 0) {
          const currentTime = Date.now();
          // 处理实时音频数据
          if (this.isProcessing && this.onAudioData && 
              currentTime - this.lastProcessTime >= this.PROCESS_INTERVAL) {
            // 检查buffer是否有效
            if (buffer.byteLength === this.bufferSize) {
              console.info(`[音频采集] 处理音频数据，buffer大小: ${buffer.byteLength}`);
              const view = new Int16Array(buffer);
              const maxValue = Math.max(...Array.from(view).map(Math.abs));
              console.info(`[音频采集] 最大采样值: ${maxValue}`);
              this.onAudioData(buffer);
              this.lastProcessTime = currentTime;
            } else {
              console.info(`[音频采集] buffer大小不匹配: ${buffer.byteLength}, 期望: ${this.bufferSize}`);
            }
          }
          // 只在录音时才存储数据
          if (this.isRecording) {
            this.audioBuffers.push(buffer.slice(0));
          }
        } else {
          console.info('[音频采集] 收到空buffer或大小为0');
        }
      });

      // 启动音频捕获器
      await this.audioCapturer.start();
      console.info('音频捕获器启动成功');

      this.isCapturing = true;
    } catch (err) {
      const error = new Error('启动音频采集失败：' + (err instanceof Error ? err.message : String(err)));
      console.error(error.message);
      throw error;
    }
  }

  /**
   * 停止音频采集并获取WAV格式的录音数据
   * @returns Promise<ArrayBuffer> WAV格式的录音数据
   */
  async stopCaptureAndGetWavData(): Promise<ArrayBuffer> {
    if (!this.isCapturing || !this.audioCapturer || this.isStoppingCapture) {
      throw new Error('没有正在进行的录音');
    }

    try {
      this.isStoppingCapture = true;
      this.isCapturing = false;
      this.isProcessing = false;
      this.onAudioData = null;

      // 移除readData事件监听
      this.audioCapturer.off('readData');
      
      // 使用Promise.all并行执行停止和释放操作
      await Promise.all([
        this.audioCapturer.stop(),
        this.audioCapturer.release()
      ]);
      
      this.audioCapturer = null;

      // 生成WAV文件数据
      const wavData = WavFileGenerator.generateWavFile(
        this.audioBuffers,
        44100,  // 采样率改为44100Hz，与录音配置一致
        1,     // 单声道
        16     // 16位采样
      );

      // 清空缓存的音频数据
      this.audioBuffers = [];

      return wavData;
    } catch (err) {
      const error = new Error('停止音频采集失败：' + (err instanceof Error ? err.message : String(err)));
      console.error(error.message);
      throw error;
    } finally {
      this.isStoppingCapture = false;
    }
  }

  /**
   * 停止音频采集
   * @returns Promise<void>
   */
  async stopCapture(): Promise<void> {
    if (!this.isCapturing || !this.audioCapturer || this.isStoppingCapture) {
      return;
    }

    try {
      this.isStoppingCapture = true;
      this.isCapturing = false;
      this.isProcessing = false;
      this.onAudioData = null;

      // 移除readData事件监听
      this.audioCapturer.off('readData');
      
      // 使用Promise.all并行执行停止和释放操作
      await Promise.all([
        this.audioCapturer.stop(),
        this.audioCapturer.release()
      ]);
      
      this.audioCapturer = null;
      // 清空缓存的音频数据
      this.audioBuffers = [];
    } catch (err) {
      const error = new Error('停止音频采集失败：' + (err instanceof Error ? err.message : String(err)));
      console.error(error.message);
      throw error;
    } finally {
      this.isStoppingCapture = false;
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
    return this.isCapturing;
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
        1,      // 单声道
        16      // 16位采样
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
} 