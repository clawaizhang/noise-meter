import audio from '@ohos.multimedia.audio';
import { PermissionUtil } from '@pura/harmony-utils';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { WavFileGenerator } from '../utils/WavFileGenerator';

/**
 * 音频服务类
 * 提供音频采集功能
 */

interface AudioStreamInfo {
  samplingRate: audio.AudioSamplingRate;
  channels: audio.AudioChannel;
  sampleFormat: audio.AudioSampleFormat;
  encodingType: audio.AudioEncodingType;
}

interface AudioCapturerInfo {
  source: audio.SourceType;
  capturerFlags: number;
}

interface AudioCapturerOptions {
  streamInfo: AudioStreamInfo;
  capturerInfo: AudioCapturerInfo;
}

export class AudioService {
  private audioCapturerOptions: AudioCapturerOptions = {
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
  private isStoppingCapture: boolean = false;
  private onAudioData: ((buffer: ArrayBuffer) => void) | null = null;
  private context: common.UIAbilityContext;
  private lastProcessTime: number = 0;
  private readonly PROCESS_INTERVAL: number = 500; // 处理间隔，单位毫秒
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

      // 创建音频捕获器
      this.audioCapturer = await audio.createAudioCapturer(this.audioCapturerOptions);
      console.info('音频捕获器创建成功');

      // 设置readData事件监听
      this.audioCapturer.on('readData', (buffer: ArrayBuffer) => {
        if (!this.isCapturing || this.isStoppingCapture) {
          return;
        }
        
        // 存储录音数据
        if (buffer && buffer.byteLength > 0) {
          this.audioBuffers.push(buffer.slice(0));
        }
        
        if (this.isProcessing) {
          const currentTime = Date.now();
          if (currentTime - this.lastProcessTime >= this.PROCESS_INTERVAL) {
            if (buffer && buffer.byteLength > 0 && this.onAudioData) {
              this.onAudioData(buffer);
            }
            this.lastProcessTime = currentTime;
          }
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
        44100, // 采样率与audioCapturerOptions中的设置保持一致
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
  getAudioConfig(): AudioStreamInfo {
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
} 