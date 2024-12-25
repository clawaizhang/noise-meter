import audio from '@ohos.multimedia.audio';
import { PermissionUtil } from '@pura/harmony-utils';
import { DecibelService } from './DecibelService';

/**
 * 音频服务类
 * 提供音频录制功能
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
  private isRecording: boolean = false;
  private onDecibelChange: ((decibel: number) => void) | null = null;
  private decibelService: DecibelService = new DecibelService();

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
      return granted;
    } catch (err) {
      console.error('Failed to check/request microphone permission:', err);
      return false;
    }
  }

  /**
   * 开始录音并计算分贝值
   * @param callback - 分贝值变化回调
   * @returns Promise<void>
   */
  async startRecording(callback: (decibel: number) => void): Promise<void> {
    if (this.isRecording) {
      throw new Error('已经在录音中');
    }

    // 检查麦克风权限
    const hasPermission = await this.checkMicrophonePermission();
    if (!hasPermission) {
      throw new Error('没有麦克风权限');
    }

    try {
      // 创建音频捕获器
      this.audioCapturer = await audio.createAudioCapturer(this.audioCapturerOptions);
      
      // 设置readData事件监听
      this.audioCapturer.on('readData', (buffer: ArrayBuffer) => {
        if (buffer && buffer.byteLength > 0 && this.onDecibelChange) {
          const decibel = this.decibelService.calculateDecibel(buffer, buffer.byteLength);
          this.onDecibelChange(decibel);
        }
      });

      // 启动音频捕获器
      await this.audioCapturer.start();
      this.isRecording = true;
      this.onDecibelChange = callback;
    } catch (err) {
      const error = new Error('启动录音失败：' + (err instanceof Error ? err.message : String(err)));
      console.error(error.message);
      throw error;
    }
  }

  /**
   * 停止录音
   * @returns Promise<void>
   */
  async stopRecording(): Promise<void> {
    if (!this.isRecording || !this.audioCapturer) {
      return;
    }

    try {
      // 移除readData事件监听
      this.audioCapturer.off('readData');
      
      await this.audioCapturer.stop();
      await this.audioCapturer.release();
      this.audioCapturer = null;
      this.isRecording = false;
      this.onDecibelChange = null;
    } catch (err) {
      const error = new Error('停止录音失败：' + (err instanceof Error ? err.message : String(err)));
      console.error(error.message);
      throw error;
    }
  }
} 