/**
 * 音频服务接口
 * 定义所有设备端都必须实现的音频能力
 */
export interface IAudioService {
  /**
   * 初始化音频服务
   */
  init(): Promise<boolean>;

  /**
   * 开始音频采集
   */
  start(): Promise<boolean>;

  /**
   * 停止音频采集
   */
  stop(): Promise<void>;

  /**
   * 释放资源
   */
  release(): Promise<void>;

  /**
   * 是否正在采集
   */
  isRecording(): boolean;

  /**
   * 获取当前分贝值
   */
  getCurrentDecibel(): number;

  /**
   * 设置数据更新回调
   */
  onDataUpdate(callback: (data: AudioData) => void): void;

  /**
   * 移除数据更新回调
   */
  offDataUpdate(callback: (data: AudioData) => void): void;
}

/**
 * 音频数据
 */
export interface AudioData {
  currentDecibel: number;
  minDecibel: number;
  avgDecibel: number;
  maxDecibel: number;
  timestamp: number;
}

/**
 * 分贝统计
 */
export interface DecibelStatistics {
  min: number;
  avg: number;
  max: number;
}
