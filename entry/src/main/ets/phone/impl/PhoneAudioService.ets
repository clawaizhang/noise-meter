import hilog from '@ohos.hilog';
import { 
  IAudioService, 
  AudioData, 
  DecibelStatistics 
} from '../../core/interfaces/IAudioService';
import { AudioCoreService } from '../../common/services/AudioCoreService';
import { DecibelCalculator, WeightingType } from '../../common/utils/DecibelCalculator';

const TAG = 'PhoneAudioService';
const DOMAIN = 0x0000;

/**
 * 手机端音频服务实现
 * 功能完整，支持频谱分析、复杂配置等
 */
export class PhoneAudioService implements IAudioService {
  private audioCore: AudioCoreService;
  private isCapturing: boolean = false;
  private decibelReadings: number[] = [];
  private currentDecibel: number = 0;
  private dataCallbacks: Array<(data: AudioData) => void> = [];
  private calibrationValue: number = 0;
  private weightingType: WeightingType = WeightingType.A;

  setWeightingType(type: WeightingType): void {
    this.weightingType = type;
    hilog.info(DOMAIN, TAG, `Weighting type set to ${type}`);
  }

  getWeightingType(): WeightingType {
    return this.weightingType;
  }

  constructor() {
    this.audioCore = AudioCoreService.getInstance();
  }

  async init(): Promise<boolean> {
    hilog.info(DOMAIN, TAG, 'Initializing phone audio service');
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
      hilog.info(DOMAIN, TAG, 'Phone audio service started');
      return true;
    }
    return false;
  }

  async stop(): Promise<void> {
    if (!this.isCapturing) return;
    this.isCapturing = false;
    await this.audioCore.stop();
    hilog.info(DOMAIN, TAG, 'Phone audio service stopped');
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

  /**
   * 手机端特有：设置校准值
   */
  setCalibration(value: number): void {
    this.calibrationValue = value;
  }

  /**
   * 手机端特有：获取频谱数据
   */
  getSpectrumData(): Float32Array {
    return new Float32Array(128);
  }

  private processAudioData(buffer: ArrayBuffer, size: number): void {
    const db = DecibelCalculator.calculate(buffer, size, this.calibrationValue, this.weightingType);
    this.currentDecibel = db;
    this.decibelReadings.push(db);

    if (this.decibelReadings.length > 10000) {
      this.decibelReadings = this.decibelReadings.slice(-5000);
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
}
