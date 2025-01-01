import audio from '@ohos.multimedia.audio';
import { BusinessError } from '@kit.BasicServicesKit';

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
  streamInfo: audio.AudioStreamInfo;
  rendererInfo: audio.AudioRendererInfo;
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

  private handleWriteData = (data: ArrayBuffer): audio.AudioDataCallbackResult => {
    if (!this.currentBuffer || !this.isPlaying || !this.audioRenderer) {
      console.info('音频播放终止: 缓冲区为空或播放器未就绪');
      this.stopPlaying().catch((err:BusinessError) => console.error('停止播放失败:', err));
      return audio.AudioDataCallbackResult.INVALID;
    }

    try {
      const remainingLength = this.currentBuffer.byteLength - this.currentPosition;
      if (remainingLength > 0) {
        // 确保不超过系统缓冲区大小
        const writeLength = Math.min(data.byteLength, remainingLength);
        
        // 从当前位置复制数据到系统缓冲区
        const sourceView = new Uint8Array(this.currentBuffer, this.currentPosition, writeLength);
        const targetView = new Uint8Array(data, 0, writeLength);
        targetView.set(sourceView);
        
        this.currentPosition += writeLength;
        console.info(`写入音频数据: ${writeLength} 字节, 剩余: ${remainingLength - writeLength} 字节`);

        if (this.currentPosition >= this.currentBuffer.byteLength) {
          console.info('音频播放完成');
          // 当前缓冲区已写完
          this.currentBuffer = null;
          this.currentPosition = 0;
          if (this.resolveWrite) {
            this.resolveWrite();
            this.resolveWrite = null;
            this.rejectWrite = null;
          }
          // 播放完成后停止播放器
          this.stopPlaying().catch((err:BusinessError) => console.error('停止播放失败:', err));
          return audio.AudioDataCallbackResult.INVALID;
        }

        return audio.AudioDataCallbackResult.VALID;
      }

      console.info('没有更多音频数据可写入');
      // 没有更多数据，停止播放
      this.stopPlaying().catch((err:BusinessError) => console.error('停止播放失败:', err));
      return audio.AudioDataCallbackResult.INVALID;
    } catch (error) {
      console.error('处理音频数据失败:', error.message);
      if (this.rejectWrite) {
        this.rejectWrite(error);
        this.resolveWrite = null;
        this.rejectWrite = null;
      }
      // 发生错误时停止播放
      this.stopPlaying().catch((err:BusinessError) => console.error('停止播放失败:', err));
      return audio.AudioDataCallbackResult.INVALID;
    }
  }

  async createRenderer(): Promise<void> {
    if (this.audioRenderer) {
      return;
    }

    try {
      // 1. 创建音频渲染器实例
      this.audioRenderer = await audio.createAudioRenderer({
        streamInfo: {
          samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_48000,
          channels: audio.AudioChannel.CHANNEL_2,
          sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_F32LE,
          encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        },
        rendererInfo: {
          usage: audio.StreamUsage.STREAM_USAGE_MEDIA,
          rendererFlags: 0
        }
      });
      
      // 2. 设置音频渲染器参数
      await this.audioRenderer.setVolume(1.0);
      await this.audioRenderer.setSpeed(1.0);
      
      // 3. 获取缓冲区大小
      const bufferSize = await this.audioRenderer.getBufferSize();
      console.info('音频渲染器缓冲区大小:', bufferSize);

      // 4. 设置writeData事件监听
      this.audioRenderer.on('writeData', this.handleWriteData);
      this.audioRenderer.on('stateChange', (state: audio.AudioState) => {
        console.info('音频渲染器状态变化:', state);
      });

      // 5. 启动渲染器
      await this.audioRenderer.start();
      console.info('音频渲染器创建并启动成功');
    } catch (err) {
      console.error('创建音频渲染器失败:', err);
      throw new Error('创建音频渲染器失败');
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

      // 设置当前缓冲区并等待播放完成
      return new Promise<void>((resolve, reject) => {
        this.currentBuffer = mergedBuffer;
        this.currentPosition = 0;
        this.resolveWrite = resolve;
        this.rejectWrite = reject;
      });
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