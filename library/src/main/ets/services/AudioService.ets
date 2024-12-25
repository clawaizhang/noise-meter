import audio from '@ohos.multimedia.audio';
import { PermissionUtil } from '@pura/harmony-utils';

/**
 * 音频服务类
 * 提供音频录制和分贝值计算功能
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
      
      // 启动音频捕获器
      await this.audioCapturer.start();
      this.isRecording = true;
      this.onDecibelChange = callback;
      this.startCalculatingDecibel();
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

  /**
   * 开始计算分贝值
   * @private
   */
  private startCalculatingDecibel(): void {
    if (!this.audioCapturer || !this.onDecibelChange) {
      return;
    }

    const bufferSize = 2048;

    const calculateDecibel = async () => {
      if (!this.isRecording || !this.audioCapturer || !this.onDecibelChange) {
        return;
      }

      try {
        const buffer = await this.audioCapturer.read(bufferSize, true);
        if (buffer && buffer.byteLength > 0) {
          const decibel = this.calculateDecibelFromBuffer(buffer, buffer.byteLength);
          this.onDecibelChange(decibel);
        }
        setTimeout(calculateDecibel, 100); // 每100ms计算一次
      } catch (err) {
        console.error('读取音频数据失败:', err instanceof Error ? err.message : String(err));
      }
    };

    calculateDecibel();
  }

  /**
   * 从音频数据计算分贝值
   * @param buffer - 音频数据缓冲区
   * @param bytesRead - 读取的字节数
   * @returns number - 分贝值
   * @private
   */
  private calculateDecibelFromBuffer(buffer: ArrayBuffer, bytesRead: number): number {
    const int16Array = new Int16Array(buffer, 0, bytesRead / 2);
    let sum = 0;
    
    // 计算均方根值
    for (let i = 0; i < int16Array.length; i++) {
      sum += int16Array[i] * int16Array[i];
    }
    const rms = Math.sqrt(sum / int16Array.length);
    
    // 将均方根值转换为分贝值
    // 参考值：16位音频的最大值为32767
    const decibel = 20 * Math.log10(rms / 32767);
    
    return Math.max(0, decibel); // 确保分贝值不为负
  }
} 