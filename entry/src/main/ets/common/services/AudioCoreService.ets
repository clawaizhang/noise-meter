import audio from '@ohos.multimedia.audio';
import hilog from '@ohos.hilog';

const TAG = 'AudioCoreService';
const DOMAIN = 0x0000;

/**
 * 音频核心服务 - 通用
 * 直接使用和手机端相同的配置
 */
export class AudioCoreService {
  private static instance: AudioCoreService | null = null;
  private audioCapturer: audio.AudioCapturer | null = null;
  private isCapturing: boolean = false;
  private onDataCallback: ((buffer: ArrayBuffer, size: number) => void) | null = null;

  // 使用和手机端完全一致的配置
  private audioCapturerOptions: audio.AudioCapturerOptions = {
    streamInfo: {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
      channels: audio.AudioChannel.CHANNEL_1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
    },
    capturerInfo: {
      source: audio.SourceType.SOURCE_TYPE_VOICE_RECOGNITION,
      capturerFlags: 0
    }
  };

  private constructor() {}

  static getInstance(): AudioCoreService {
    if (!AudioCoreService.instance) {
      AudioCoreService.instance = new AudioCoreService();
    }
    return AudioCoreService.instance;
  }

  async init(): Promise<boolean> {
    try {
      hilog.info(DOMAIN, TAG, 'Creating audio capturer with standard config...');
      this.audioCapturer = await audio.createAudioCapturer(this.audioCapturerOptions);
      hilog.info(DOMAIN, TAG, 'Audio capturer created successfully');
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to create audio capturer: ${JSON.stringify(err)}`);
      return false;
    }
  }

  async start(onData: (buffer: ArrayBuffer, size: number) => void): Promise<boolean> {
    if (this.isCapturing) {
      return true;
    }
    
    if (!this.audioCapturer) {
      const ok = await this.init();
      if (!ok) return false;
    }

    try {
      this.onDataCallback = onData;
      
      // 注册readData事件监听 - 和手机端方式一致
      this.audioCapturer!.on('readData', (buffer: ArrayBuffer) => {
        if (this.onDataCallback && this.isCapturing) {
          this.onDataCallback(buffer, buffer.byteLength);
        }
      });
      
      // 启动采集
      await this.audioCapturer!.start();
      this.isCapturing = true;
      
      hilog.info(DOMAIN, TAG, 'Audio capturing started');
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Failed to start: ${JSON.stringify(err)}`);
      return false;
    }
  }

  async stop(): Promise<void> {
    if (!this.isCapturing) return;
    
    this.isCapturing = false;
    
    if (this.audioCapturer) {
      try {
        await this.audioCapturer.stop();
        // 移除监听
        this.audioCapturer.off('readData');
      } catch (err) {
        hilog.error(DOMAIN, TAG, `Error stopping: ${JSON.stringify(err)}`);
      }
    }
  }

  async release(): Promise<void> {
    await this.stop();
    if (this.audioCapturer) {
      try {
        await this.audioCapturer.release();
      } catch (err) {
        hilog.error(DOMAIN, TAG, `Error releasing: ${JSON.stringify(err)}`);
      }
      this.audioCapturer = null;
    }
  }
}
