import vibrator from '@ohos.vibrator';
import hilog from '@ohos.hilog';

const TAG = 'VibrateService';
const DOMAIN = 0x0000;

/**
 * 振动服务 - 手表专用
 */
export class VibrateService {
  private static instance: VibrateService | null = null;
  private isVibrating: boolean = false;
  private intervalId: number | null = null;

  private constructor() {}

  static getInstance(): VibrateService {
    if (!VibrateService.instance) {
      VibrateService.instance = new VibrateService();
    }
    return VibrateService.instance;
  }

  vibrateShort(): void {
    vibrator.startVibration({ type: 'time', duration: 100 }, { id: 0, usage: 'alarm' })
      .catch(err => hilog.error(DOMAIN, TAG, `${JSON.stringify(err)}`));
  }

  vibrateLong(): void {
    vibrator.startVibration({ type: 'time', duration: 500 }, { id: 0, usage: 'alarm' })
      .catch(err => hilog.error(DOMAIN, TAG, `${JSON.stringify(err)}`));
  }

  startAlertVibration(): void {
    if (this.isVibrating) return;
    this.isVibrating = true;
    this.vibrateLong();
    this.intervalId = setInterval(() => {
      if (this.isVibrating) this.vibrateShort();
    }, 2000);
  }

  stopAlertVibration(): void {
    if (!this.isVibrating) return;
    this.isVibrating = false;
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    vibrator.stopVibration().catch(() => {});
  }
}
