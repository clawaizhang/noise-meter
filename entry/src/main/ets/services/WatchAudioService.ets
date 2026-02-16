import hilog from '@ohos.hilog';
import { WatchAppKeys } from '../models/WatchAppKeys';
import { WatchPreferenceKeys } from '../models/WatchPreferenceKeys';
import { AudioCoreService, DecibelCalculator, NoiseLevelHelper } from 'shared';

const TAG = 'WatchAudioService';
const DOMAIN = 0x0000;

/**
 * 手表端音频服务
 * 基于共享模块 AudioCoreService 封装
 * 添加手表端特有的业务逻辑（振动提醒、统计等）
 */
export class WatchAudioService {
  private static instance: WatchAudioService | null = null;
  private audioCore: AudioCoreService;
  private isCapturing: boolean = false;

  // 统计数据
  private decibelReadings: number[] = [];
  private appKeys: WatchAppKeys;
  private pk: WatchPreferenceKeys;

  // 定时器
  private durationInterval: number | null = null;

  private constructor() {
    this.audioCore = AudioCoreService.getInstance();
    this.appKeys = WatchAppKeys.getInstance();
    this.pk = WatchPreferenceKeys.getInstance();
  }

  static getInstance(): WatchAudioService {
    if (!WatchAudioService.instance) {
      WatchAudioService.instance = new WatchAudioService();
    }
    return WatchAudioService.instance;
  }

  /**
   * 初始化
   */
  async init(): Promise<boolean> {
    return await this.audioCore.init();
  }

  /**
   * 开始采集
   */
  async start(): Promise<boolean> {
    if (this.isCapturing) {
      return true;
    }

    const started = await this.audioCore.start((buffer, size) => {
      this.processAudioData(buffer, size);
    });

    if (started) {
      this.isCapturing = true;
      this.decibelReadings = [];

      // 重置统计
      this.appKeys.currentDecibel = 0;
      this.appKeys.minDecibel = 0;
      this.appKeys.avgDecibel = 0;
      this.appKeys.maxDecibel = 0;
      this.appKeys.detectionDuration = 0;
      this.appKeys.isDetecting = true;

      // 启动定时器
      this.startTimers();

      hilog.info(DOMAIN, TAG, 'Audio capturing started');
      return true;
    }

    return false;
  }

  /**
   * 停止采集
   */
  async stop(): Promise<void> {
    if (!this.isCapturing) {
      return;
    }

    this.isCapturing = false;
    this.appKeys.isDetecting = false;

    // 停止定时器
    this.stopTimers();

    await this.audioCore.stop();

    hilog.info(DOMAIN, TAG, 'Audio capturing stopped');
  }

  /**
   * 处理音频数据
   */
  private processAudioData(buffer: ArrayBuffer, size: number): void {
    // 使用共享模块计算分贝值
    const decibel = DecibelCalculator.calculate(buffer, size, this.pk.calibrationValue);

    // 更新当前值
    this.appKeys.currentDecibel = decibel;

    // 添加到读数数组
    this.decibelReadings.push(decibel);

    // 更新统计（使用共享模块）
    this.updateStatistics();

    // 更新噪音等级描述（使用共享模块）
    this.updateNoiseLevel(decibel);

    // 检查阈值（使用共享模块）
    this.checkThreshold(decibel);
  }

  /**
   * 更新统计数据
   */
  private updateStatistics(): void {
    const stats = DecibelCalculator.calculateStats(this.decibelReadings);
    this.appKeys.minDecibel = stats.min;
    this.appKeys.avgDecibel = stats.avg;
    this.appKeys.maxDecibel = stats.max;
  }

  /**
   * 更新噪音等级描述
   */
  private updateNoiseLevel(decibel: number): void {
    const levelInfo = NoiseLevelHelper.getLevelInfo(decibel);
    this.appKeys.noiseLevelDescription = levelInfo.description;
    this.appKeys.noiseLevelColor = levelInfo.color;
  }

  /**
   * 检查阈值
   */
  private checkThreshold(decibel: number): void {
    const shouldAlert = NoiseLevelHelper.checkThreshold(
      decibel,
      this.pk.alertThreshold,
      this.appKeys.isAlertActive
    );
    this.appKeys.isAlertActive = shouldAlert;
  }

  /**
   * 启动定时器
   */
  private startTimers(): void {
    this.durationInterval = setInterval(() => {
      this.appKeys.detectionDuration++;
    }, 1000);
  }

  /**
   * 停止定时器
   */
  private stopTimers(): void {
    if (this.durationInterval) {
      clearInterval(this.durationInterval);
      this.durationInterval = null;
    }
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    await this.stop();
    await this.audioCore.release();
  }

  /**
   * 获取是否正在采集
   */
  isRecording(): boolean {
    return this.isCapturing;
  }
}
