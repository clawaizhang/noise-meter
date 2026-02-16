import vibrator from '@ohos.vibrator';
import hilog from '@ohos.hilog';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'VibrateService';
const DOMAIN = 0x0000;

/**
 * 振动服务
 * 用于噪音超标提醒
 */
export class VibrateService {
  private static instance: VibrateService | null = null;
  private isVibrating: boolean = false;
  private vibrateInterval: number | null = null;

  private constructor() {}

  static getInstance(): VibrateService {
    if (!VibrateService.instance) {
      VibrateService.instance = new VibrateService();
    }
    return VibrateService.instance;
  }

  /**
   * 短振动（提示）
   */
  vibrateShort(): void {
    try {
      vibrator.startVibration({
        type: 'time',
        duration: 100
      }, {
        id: 0,
        usage: 'alarm'
      }).then(() => {
        hilog.debug(DOMAIN, TAG, 'Short vibration started');
      }).catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, `Failed to vibrate: ${JSON.stringify(err)}`);
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Error in vibrateShort: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 长振动（警告）
   */
  vibrateLong(): void {
    try {
      vibrator.startVibration({
        type: 'time',
        duration: 500
      }, {
        id: 0,
        usage: 'alarm'
      }).then(() => {
        hilog.debug(DOMAIN, TAG, 'Long vibration started');
      }).catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, `Failed to vibrate: ${JSON.stringify(err)}`);
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Error in vibrateLong: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 开始持续振动提醒
   */
  startAlertVibration(): void {
    if (this.isVibrating) {
      return;
    }

    this.isVibrating = true;

    // 立即振动一次
    this.vibrateLong();

    // 每2秒振动一次
    this.vibrateInterval = setInterval(() => {
      if (this.isVibrating) {
        this.vibrateShort();
      }
    }, 2000);

    hilog.info(DOMAIN, TAG, 'Alert vibration started');
  }

  /**
   * 停止持续振动
   */
  stopAlertVibration(): void {
    if (!this.isVibrating) {
      return;
    }

    this.isVibrating = false;

    if (this.vibrateInterval) {
      clearInterval(this.vibrateInterval);
      this.vibrateInterval = null;
    }

    // 停止当前振动
    try {
      vibrator.stopVibration().then(() => {
        hilog.debug(DOMAIN, TAG, 'Vibration stopped');
      }).catch((err: BusinessError) => {
        hilog.error(DOMAIN, TAG, `Failed to stop vibration: ${JSON.stringify(err)}`);
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Error in stopVibration: ${JSON.stringify(err)}`);
    }

    hilog.info(DOMAIN, TAG, 'Alert vibration stopped');
  }

  /**
   * 是否在振动中
   */
  isAlertVibrating(): boolean {
    return this.isVibrating;
  }
}
