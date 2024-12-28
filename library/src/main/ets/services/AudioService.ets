import audio from '@ohos.multimedia.audio';
import { PermissionUtil } from '@pura/harmony-utils';
import common from '@ohos.app.ability.common';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import promptAction from '@ohos.promptAction';

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
  private isRecording: boolean = false;
  private isStoppingRecording: boolean = false;
  private onAudioData: ((buffer: ArrayBuffer) => void) | null = null;
  private context: common.UIAbilityContext;
  private lastProcessTime: number = 0;
  private readonly PROCESS_INTERVAL: number = 500; // 处理间隔，单位毫秒

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
   * @param callback - 音频数据回调
   * @returns Promise<void>
   */
  async startRecording(callback: (buffer: ArrayBuffer) => void): Promise<void> {
    if (this.isRecording || this.isStoppingRecording) {
      throw new Error('已经在录音中或正在停止录音');
    }

    // 检查麦克风权限
    const hasPermission = await this.checkMicrophonePermission();
    if (!hasPermission) {
      throw new Error('没有麦克风权限');
    }

    try {
      // 创建音频捕获器
      this.audioCapturer = await audio.createAudioCapturer(this.audioCapturerOptions);
      console.info('音频捕获器创建成功');

      // 设置readData事件监听
      this.audioCapturer.on('readData', (buffer: ArrayBuffer) => {
        if (!this.isRecording || this.isStoppingRecording) {
          return;
        }
        
        const currentTime = Date.now();
        if (currentTime - this.lastProcessTime >= this.PROCESS_INTERVAL) {
          if (buffer && buffer.byteLength > 0 && this.onAudioData) {
            this.onAudioData(buffer);
          }
          this.lastProcessTime = currentTime;
        }
      });

      // 启动音频捕获器
      await this.audioCapturer.start();
      console.info('音频捕获器启动成功');

      this.isRecording = true;
      this.onAudioData = callback;
      this.lastProcessTime = Date.now();
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
    if (!this.isRecording || !this.audioCapturer || this.isStoppingRecording) {
      return;
    }

    try {
      this.isStoppingRecording = true;
      this.isRecording = false;
      this.onAudioData = null;

      // 移除readData事件监听
      this.audioCapturer.off('readData');
      
      // 使用Promise.all并行执行停止和释放操作
      await Promise.all([
        this.audioCapturer.stop(),
        this.audioCapturer.release()
      ]);
      
      this.audioCapturer = null;
    } catch (err) {
      const error = new Error('停止录音失败：' + (err instanceof Error ? err.message : String(err)));
      console.error(error.message);
      throw error;
    } finally {
      this.isStoppingRecording = false;
    }
  }

  /**
   * 获取音频配置
   * @returns AudioStreamInfo
   */
  getAudioConfig(): AudioStreamInfo {
    return this.audioCapturerOptions.streamInfo;
  }
} 