import audio from '@ohos.multimedia.audio';

interface AudioStreamInfo {
  samplingRate: audio.AudioSamplingRate;
  channels: audio.AudioChannel;
  sampleFormat: audio.AudioSampleFormat;
  encodingType: audio.AudioEncodingType;
}

interface AudioRendererInfo {
  content: audio.ContentType;
  usage: audio.StreamUsage;
  rendererFlags: number;
}

interface AudioRendererOptions {
  streamInfo: AudioStreamInfo;
  rendererInfo: AudioRendererInfo;
}

export class AudioPlayerService {
  private audioRenderer: audio.AudioRenderer | null = null;
  private isPlaying: boolean = false;

  async createRenderer(): Promise<void> {
    if (this.audioRenderer) {
      return;
    }

    const audioRendererOptions: AudioRendererOptions = {
      streamInfo: {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      },
      rendererInfo: {
        content: audio.ContentType.CONTENT_TYPE_SPEECH,
        usage: audio.StreamUsage.STREAM_USAGE_MEDIA,
        rendererFlags: 0
      }
    };

    try {
      this.audioRenderer = await audio.createAudioRenderer(audioRendererOptions);
      await this.audioRenderer.start();
    } catch (err) {
      console.error('创建音频渲染器失败:', err);
      throw new Error('创建音频渲染器失败');
    }
  }

  async playAudio(audioData: ArrayBuffer[]): Promise<void> {
    if (this.isPlaying) {
      return;
    }

    try {
      await this.createRenderer();
      this.isPlaying = true;

      for (const buffer of audioData) {
        if (!this.isPlaying) {
          break;
        }
        await this.audioRenderer?.write(buffer);
      }

      await this.stopPlaying();
    } catch (err) {
      console.error('播放音频失败:', err);
      this.stopPlaying();
      throw new Error('播放音频失败');
    }
  }

  async stopPlaying(): Promise<void> {
    this.isPlaying = false;
    if (this.audioRenderer) {
      try {
        await this.audioRenderer.stop();
        await this.audioRenderer.release();
        this.audioRenderer = null;
      } catch (err) {
        console.error('停止音频播放失败:', err);
        throw new Error('停止音频播放失败');
      }
    }
  }

  isAudioPlaying(): boolean {
    return this.isPlaying;
  }
} 