// 导入音频处理模块
import audio from '@ohos.multimedia.audio'
// 导入错误处理模块
import { BusinessError } from '@ohos.base'

// 音频服务事件类型接口
interface AudioEventListener {
  onDBValueChange: (currentDB: number) => void; // 分贝值变化回调
  onError: (error: string) => void; // 错误回调
}

// 音频配置接口
interface AudioConfig {
  sampleRate: number; // 采样率
  channels: number; // 通道数
  sampleFormat: audio.AudioSampleFormat; // 采样格式
  bufferSize: number; // 缓冲区大小
}

/**
 * 音频服务类
 * 负责处理音频采集和分贝值计算的核心逻辑
 */
export class AudioService {
  private audioCapture: audio.AudioCapturer | null = null; // 音频捕获器实例
  private isRecording: boolean = false; // 录音状态
  private listener: AudioEventListener | null = null; // 事件监听器
  private readonly config: AudioConfig; // 音频配置

  constructor(config: AudioConfig) {
    this.config = config;
  }

  /**
   * 设置事件监听器
   * @param listener 监听器实例
   */
  public setListener(listener: AudioEventListener): void {
    this.listener = listener;
  }

  /**
   * 检查音频捕获器是否已初始化
   */
  public isInitialized(): boolean {
    return this.audioCapture !== null;
  }

  /**
   * 初始化音频捕获器
   */
  public async initAudioCapture(): Promise<void> {
    try {
      // 创建音频捕获器配置
      const capturerOptions: audio.AudioCapturerOptions = {
        streamInfo: {
          samplingRate: this.config.sampleRate,
          channels: this.config.channels,
          sampleFormat: this.config.sampleFormat,
          encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
        },
        capturerInfo: {
          source: audio.SourceType.SOURCE_TYPE_MIC,
          capturerFlags: 0
        }
      }

      // 创建音频捕获器
      this.audioCapture = await audio.createAudioCapturer(capturerOptions);

      // 添加数据读取事件监听
      this.audioCapture.on('readData', (buffer: ArrayBuffer): void => {
        if (buffer && buffer.byteLength > 0) {
          const db: number = this.calculateDB(buffer, buffer.byteLength);
          // 通知监听器分贝值变化
          this.listener?.onDBValueChange(db);
        }
      });
    } catch (err) {
      const error = err as BusinessError;
      console.error('初始化音频捕获器失败:', JSON.stringify(error));
      this.listener?.onError(`初始化音频捕获器失败: ${error.message}`);
    }
  }

  /**
   * 开始录音
   */
  public async startRecording(): Promise<void> {
    if (this.isRecording) {
      return;
    }

    try {
      // 每次开始录音前都重新初始化音频捕获器
      if (!this.audioCapture) {
        await this.initAudioCapture();
      }
      await this.audioCapture?.start();
      this.isRecording = true;
    } catch (err) {
      const error = err as BusinessError;
      console.error('启动音频捕获失败:', JSON.stringify(error));
      this.listener?.onError(`启动音频捕获失败: ${error.message}`);
    }
  }

  /**
   * 停止录音
   */
  public async stopRecording(): Promise<void> {
    if (!this.audioCapture || !this.isRecording) {
      return;
    }

    try {
      await this.audioCapture.stop();
      // 清除音频缓存
      await this.audioCapture.release();
      this.audioCapture = null;
      this.isRecording = false;
    } catch (err) {
      const error = err as BusinessError;
      console.error('停止音频捕获失败:', JSON.stringify(error));
      this.listener?.onError(`停止音频捕获失败: ${error.message}`);
    }
  }

  /**
   * 释放资源
   */
  public async release(): Promise<void> {
    if (this.audioCapture) {
      try {
        await this.stopRecording();
        this.audioCapture.off('readData');
        this.audioCapture = null;
      } catch (err) {
        const error = err as BusinessError;
        console.error('释放音频资源失败:', JSON.stringify(error));
        this.listener?.onError(`释放音频资源失败: ${error.message}`);
      }
    }
  }

  /**
   * 计算音频数据的分贝值
   * @param buffer 音频数据缓冲区
   * @param length 数据长度
   * @returns 计算得到的分贝值
   */
  private calculateDB(buffer: ArrayBuffer, length: number): number {
    // 将缓冲区数据转换为16位整数数组
    const samples: Int16Array = new Int16Array(buffer, 0, length / 2);
    let sum: number = 0;

    // 计算均方根（RMS）
    for (let i = 0; i < samples.length; i++) {
      sum += samples[i] * samples[i];
    }
    const rms: number = Math.sqrt(sum / samples.length);

    // 将RMS转换为分贝值（参考值：16位音频的最大值是32767）
    const db: number = 20 * Math.log10(rms / 32767);

    // 归一化到0-120分贝范围
    return Math.max(0, Math.min(120, Math.round(db + 120)));
  }

  /**
   * 获取当前录音状态
   */
  public isCurrentlyRecording(): boolean {
    return this.isRecording;
  }
}
