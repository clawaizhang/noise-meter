import audio from '@ohos.multimedia.audio';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import { FileService } from './FileService';

/**
 * 音频播放服务
 */
export class AudioPlayerService {
  private context: common.Context;
  private audioRenderer?: audio.AudioRenderer;
  private fileService: FileService;
  private isPlaying: boolean = false;

  constructor(context: common.Context) {
    this.context = context;
    this.fileService = new FileService(context);
  }

  /**
   * 播放音频文件
   * @param audioFilePath - 音频文件路径
   */
  async playAudioFile(audioFilePath: string): Promise<void> {
    try {
      if (this.isPlaying) {
        await this.stop();
      }

      // 读取音频文件
      const audioBuffer = await this.fileService.readFile(audioFilePath);

      // 创建音频渲染器选项
      const audioRendererOptions: audio.AudioRendererOptions = {
        streamInfo: {
          samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
          channels: audio.AudioChannel.CHANNEL_2,
          sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
          encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        },
        rendererInfo: {
          usage: audio.StreamUsage.STREAM_USAGE_UNKNOWN,
          rendererFlags: 0
        }
      };

      // 创建音频渲染器
      this.audioRenderer = await audio.createAudioRenderer(audioRendererOptions);
      
      // 开始渲染
      await this.audioRenderer.start();
      this.isPlaying = true;

      // 写入音频数据
      const bytesWritten = await this.audioRenderer.write(audioBuffer);
      if (bytesWritten <= 0) {
        throw new Error('写入音频数据失败');
      }

      // 等待播放完成
      await this.audioRenderer.drain();
      
      // 停止播放
      await this.stop();
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`播放音频失败: ${businessError.message}`);
      throw new Error(`播放音频失败: ${businessError.message}`);
    }
  }

  /**
   * 停止播放
   */
  async stop(): Promise<void> {
    if (this.audioRenderer && this.isPlaying) {
      try {
        await this.audioRenderer.stop();
        await this.audioRenderer.release();
        this.audioRenderer = undefined;
        this.isPlaying = false;
      } catch (error) {
        const businessError = error as BusinessError;
        console.error(`停止播放失败: ${businessError.message}`);
        throw new Error(`停止播放失败: ${businessError.message}`);
      }
    }
  }

  /**
   * 检查是否正在播放
   */
  isCurrentlyPlaying(): boolean {
    return this.isPlaying;
  }
} 