import vibrator from '@ohos.vibrator';
import hilog from '@ohos.hilog';
import { 
  IAudioService, 
  AudioData, 
  DecibelStatistics 
} from '../../core/interfaces/IAudioService';
import { AudioCoreService } from '../../common/services/AudioCoreService';
import { DecibelCalculator } from '../../common/utils/DecibelCalculator';

const TAG = 'WatchAudioService';
const DOMAIN = 0x0000;

/**
 * 手表端音频服务实现
 * 精简功能，省电优化，支持振动反馈
 */
export class WatchAudioService implements IAudioService {
  private audioCore: AudioCoreService;
  private isCapturing: boolean = false;
  private decibelReadings: number[] = [];
  private currentDecibel: number = 0;
  private dataCallbacks: Array<(data: AudioData) => void> = [];
  private calibrationValue: number = 0;
  private durationInterval: number | null = null;
  private detectionDuration: number = 0;

  constructor() {
    this.audioCore = AudioCoreService.getInstance();
  }

  /**
   * 设置校准值
   */
  setCalibration(value: number): void {
    this.calibrationValue = value;
    hilog.info(DOMAIN, TAG, `Calibration set to ${value}dB`);
  }

  /**
   * 获取当前校准值
   */
  getCalibration(): number {
    return this.calibrationValue;
  }

  async init(): Promise<boolean> {
    hilog.info(DOMAIN, TAG, 'Initializing watch audio service');
    return await this.audioCore.init();
  }

  async start(): Promise<boolean> {
    if (this.isCapturing) return true;

    const started = await this.audioCore.start((buffer, size) => {
      this.processAudioData(buffer, size);
    });

    if (started) {
      this.isCapturing = true;
      this.decibelReadings = [];
      this.currentDecibel = 0;
      this.detectionDuration = 0;
      this.startDurationTimer();
      this.vibrateStart();
      hilog.info(DOMAIN, TAG, 'Watch audio service started');
      return true;
    }
    return false;
  }

  async stop(): Promise<void> {
    if (!this.isCapturing) return;
    this.isCapturing = false;
    this.stopDurationTimer();
    await this.audioCore.stop();
    this.vibrateStop();
    hilog.info(DOMAIN, TAG, 'Watch audio service stopped');
  }

  async release(): Promise<void> {
    await this.stop();
    await this.audioCore.release();
  }

  isRecording(): boolean {
    return this.isCapturing;
  }

  getCurrentDecibel(): number {
    return this.currentDecibel;
  }

  getStatistics(): DecibelStatistics {
    return DecibelCalculator.calculateStats(this.decibelReadings);
  }

  onDataUpdate(callback: (data: AudioData) => void): void {
    const index = this.dataCallbacks.indexOf(callback);
    if (index === -1) {
      this.dataCallbacks.push(callback);
    }
  }

  offDataUpdate(callback: (data: AudioData) => void): void {
    const index = this.dataCallbacks.indexOf(callback);
    if (index > -1) {
      this.dataCallbacks.splice(index, 1);
    }
  }

  getDetectionDuration(): number {
    return this.detectionDuration;
  }

  markRecord(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 50 }, { id: 0, usage: 'alarm' });
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Vibrate failed');
    }
    hilog.info(DOMAIN, TAG, `Marked record at ${this.currentDecibel}dB`);
  }

  private processAudioData(buffer: ArrayBuffer, size: number): void {
    const db = DecibelCalculator.calculate(buffer, size, this.calibrationValue);
    this.currentDecibel = db;
    this.decibelReadings.push(db);

    if (this.decibelReadings.length > 1000) {
      this.decibelReadings = this.decibelReadings.slice(-500);
    }

    const stats = this.getStatistics();
    const data: AudioData = {
      currentDecibel: db,
      minDecibel: stats.min,
      avgDecibel: stats.avg,
      maxDecibel: stats.max,
      timestamp: Date.now()
    };
    
    this.dataCallbacks.forEach((cb) => cb(data));
  }

  private startDurationTimer(): void {
    this.durationInterval = setInterval(() => {
      this.detectionDuration++;
    }, 1000);
  }

  private stopDurationTimer(): void {
    if (this.durationInterval !== null) {
      clearInterval(this.durationInterval);
      this.durationInterval = null;
    }
  }

  private vibrateStart(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 100 }, { id: 0, usage: 'alarm' });
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Vibrate start failed');
    }
  }

  private vibrateStop(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 200 }, { id: 0, usage: 'alarm' });
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'Vibrate stop failed');
    }
  }
}
