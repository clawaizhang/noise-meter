import hilog from '@ohos.hilog';
import { AudioCoreService } from '../../common/services/AudioCoreService';
import { DecibelCalculator, NoiseLevelHelper } from '../../common/utils/DecibelCalculator';
import { WatchAppKeys } from '../../models/WatchAppKeys';
import { WatchPreferenceKeys } from '../../models/WatchPreferenceKeys';

const TAG = 'WatchAudioService';
const DOMAIN = 0x0000;

/**
 * 手表端音频服务
 */
export class WatchAudioService {
  private static instance: WatchAudioService | null = null;
  private audioCore: AudioCoreService;
  private isCapturing: boolean = false;
  private decibelReadings: number[] = [];
  private appKeys: WatchAppKeys;
  private pk: WatchPreferenceKeys;
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

  async init(): Promise<boolean> {
    return await this.audioCore.init();
  }

  async start(): Promise<boolean> {
    if (this.isCapturing) return true;

    const started = await this.audioCore.start((buffer, size) => {
      this.processData(buffer, size);
    });

    if (started) {
      this.isCapturing = true;
      this.decibelReadings = [];
      this.resetStats();
      this.startTimers();
      hilog.info(DOMAIN, TAG, 'Started');
      return true;
    }
    return false;
  }

  async stop(): Promise<void> {
    if (!this.isCapturing) return;
    this.isCapturing = false;
    this.appKeys.isDetecting = false;
    this.stopTimers();
    await this.audioCore.stop();
  }

  async release(): Promise<void> {
    await this.stop();
    await this.audioCore.release();
  }

  private processData(buffer: ArrayBuffer, size: number): void {
    const db = DecibelCalculator.calculate(buffer, size, this.pk.calibrationValue);
    this.appKeys.currentDecibel = db;
    this.decibelReadings.push(db);
    this.updateStats();
    this.updateLevel(db);
    this.checkThreshold(db);
  }

  private resetStats(): void {
    this.appKeys.currentDecibel = 0;
    this.appKeys.minDecibel = 0;
    this.appKeys.avgDecibel = 0;
    this.appKeys.maxDecibel = 0;
    this.appKeys.detectionDuration = 0;
    this.appKeys.isDetecting = true;
  }

  private updateStats(): void {
    const stats = DecibelCalculator.calculateStats(this.decibelReadings);
    this.appKeys.minDecibel = stats.min;
    this.appKeys.avgDecibel = stats.avg;
    this.appKeys.maxDecibel = stats.max;
  }

  private updateLevel(db: number): void {
    const info = NoiseLevelHelper.getLevelInfo(db);
    this.appKeys.noiseLevelDescription = info.description;
    this.appKeys.noiseLevelColor = info.color;
  }

  private checkThreshold(db: number): void {
    this.appKeys.isAlertActive = NoiseLevelHelper.checkThreshold(
      db, this.pk.alertThreshold, this.appKeys.isAlertActive
    );
  }

  private startTimers(): void {
    this.durationInterval = setInterval(() => {
      this.appKeys.detectionDuration++;
    }, 1000);
  }

  private stopTimers(): void {
    if (this.durationInterval) {
      clearInterval(this.durationInterval);
      this.durationInterval = null;
    }
  }

  isRecording(): boolean {
    return this.isCapturing;
  }
}
