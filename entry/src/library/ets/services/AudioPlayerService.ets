import audio from '@ohos.multimedia.audio';

interface AudioStreamInfo {
  samplingRate: audio.AudioSamplingRate;
  channels: audio.AudioChannel;
  sampleFormat: audio.AudioSampleFormat;
  encodingType: audio.AudioEncodingType;
}

interface AudioRendererInfo {
  usage: audio.StreamUsage;
  rendererFlags: number;
}

interface AudioRendererOptions {
  streamInfo: AudioStreamInfo;
  rendererInfo: AudioRendererInfo;
}

export interface SerializedAudioData {
  data: number[];
}

export type AudioDataType = ArrayBuffer | SerializedAudioData;

export class AudioPlayerService {
  private audioRenderer: audio.AudioRenderer | null = null;
  private isPlaying: boolean = false;
  private shouldStop: boolean = false;
  private currentBuffer: ArrayBuffer | null = null;
  private currentPosition: number = 0;
  private resolveWrite: (() => void) | null = null;
  private rejectWrite: ((error: Error) => void) | null = null;

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
        usage: audio.StreamUsage.STREAM_USAGE_UNKNOWN,
        rendererFlags: 0
      }
    };

    try {
      this.audioRenderer = await audio.createAudioRenderer(audioRendererOptions);
      // 设置音量为最大
      await this.audioRenderer.setVolume(1.0);
      // 设置播放速度为正常
      await this.audioRenderer.setSpeed(1.0);

      // 设置writeData事件监听
      this.audioRenderer.on('writeData', this.handleWriteData.bind(this));

      // 启动渲染器
      await this.audioRenderer.start();
      console.info('音频渲染器创建并启动成功');
    } catch (err) {
      console.error('创建音频渲染器失败:', err);
      throw new Error('创建音频渲染器失败');
    }
  }

  private handleWriteData(length: number): void {
    if (!this.currentBuffer || !this.isPlaying) {
      return;
    }

    try {
      const remainingLength = this.currentBuffer.byteLength - this.currentPosition;
      if (remainingLength > 0) {
        const writeLength = Math.min(length, remainingLength);
        const chunk = this.currentBuffer.slice(this.currentPosition, this.currentPosition + writeLength);
        this.currentPosition += writeLength;

        if (this.currentPosition >= this.currentBuffer.byteLength) {
          // 当前缓冲区已写完
          this.currentBuffer = null;
          this.currentPosition = 0;
          if (this.resolveWrite) {
            this.resolveWrite();
            this.resolveWrite = null;
            this.rejectWrite = null;
          }
        }
      }
    } catch (error) {
      console.error('写入音频数据失败:', error);
      if (this.rejectWrite) {
        this.rejectWrite(new Error('写入音频数据失败'));
        this.resolveWrite = null;
        this.rejectWrite = null;
      }
    }
  }

  private async writeAudioData(data: ArrayBuffer): Promise<void> {
    if (!this.audioRenderer) {
      throw new Error('音频渲染器未初始化');
    }

    return new Promise<void>((resolve, reject) => {
      this.currentBuffer = data;
      this.currentPosition = 0;
      this.resolveWrite = resolve;
      this.rejectWrite = reject;
    });
  }

  private convertToArrayBuffer(data: AudioDataType): ArrayBuffer {
    if (data instanceof ArrayBuffer) {
      return data;
    }
    // 如果是从JSON反序列化的数据
    const serializedData = data as SerializedAudioData;
    if (serializedData && Array.isArray(serializedData.data)) {
      const uint8Array = new Uint8Array(serializedData.data);
      return uint8Array.buffer;
    }
    throw new Error('无法转换为ArrayBuffer');
  }

  async playAudio(audioData: AudioDataType[]): Promise<void> {
    if (this.isPlaying) {
      return;
    }

    if (!audioData || !Array.isArray(audioData) || audioData.length === 0) {
      console.error('无效的音频数据');
      throw new Error('无效的音频数据');
    }

    try {
      // 转换音频数据
      const buffers: ArrayBuffer[] = [];
      for (const data of audioData) {
        try {
          const buffer = this.convertToArrayBuffer(data);
          buffers.push(buffer);
        } catch (error) {
          console.error('转换音频数据失败:', error);
        }
      }

      if (buffers.length === 0) {
        throw new Error('没有有效的音频数据');
      }

      await this.createRenderer();
      this.isPlaying = true;
      this.shouldStop = false;

      // 合并所有音频数据
      const totalLength = buffers.reduce((acc, curr) => acc + curr.byteLength, 0);
      console.info('音频数据总长度:', totalLength);
      
      const mergedBuffer = new ArrayBuffer(totalLength);
      const uint8View = new Uint8Array(mergedBuffer);
      let offset = 0;
      
      for (const buffer of buffers) {
        console.info('处理音频数据片段, 长度:', buffer.byteLength);
        uint8View.set(new Uint8Array(buffer), offset);
        offset += buffer.byteLength;
      }

      // 写入并播放音频数据
      let position = 0;
      const bufferSize = 4096; // 使用固定的缓冲区大小
      while (position < totalLength && !this.shouldStop) {
        const chunk = mergedBuffer.slice(position, Math.min(position + bufferSize, totalLength));
        await this.writeAudioData(chunk);
        await this.audioRenderer!.drain();
        position += chunk.byteLength;
      }

      await this.stopPlaying();
    } catch (err) {
      console.error('播放音频失败:', err);
      await this.stopPlaying();
      throw new Error('播放音频失败');
    }
  }

  async stopPlaying(): Promise<void> {
    this.shouldStop = true;
    if (this.audioRenderer) {
      try {
        // 清理状态
        this.currentBuffer = null;
        this.currentPosition = 0;
        this.resolveWrite = null;
        this.rejectWrite = null;

        await this.audioRenderer.stop();
        await this.audioRenderer.release();
        this.audioRenderer = null;
      } catch (err) {
        console.error('停止音频播放失败:', err);
        throw new Error('停止音频播放失败');
      } finally {
        this.isPlaying = false;
      }
    } else {
      this.isPlaying = false;
    }
  }

  isAudioPlaying(): boolean {
    return this.isPlaying;
  }
} 