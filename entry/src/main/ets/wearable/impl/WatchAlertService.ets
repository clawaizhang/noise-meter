import vibrator from '@ohos.vibrator';
import { IAlertService } from '../../core/interfaces/IAlertService';

/**
 * 手表端警报服务实现
 * 使用振动提醒
 */
export class WatchAlertService implements IAlertService {
  private threshold: number = 80;
  private isInAlert: boolean = false;
  private alertCallbacks: Array<(isAlerting: boolean) => void> = [];
  private vibrateInterval: number | null = null;

  setThreshold(threshold: number): void {
    this.threshold = threshold;
  }

  getThreshold(): number {
    return this.threshold;
  }

  checkAlert(currentDecibel: number): boolean {
    const shouldAlert = this.isInAlert 
      ? currentDecibel >= this.threshold - 5
      : currentDecibel >= this.threshold;
    
    if (shouldAlert && !this.isInAlert) {
      this.startAlert();
    } else if (!shouldAlert && this.isInAlert) {
      this.stopAlert();
    }
    
    return shouldAlert;
  }

  startAlert(): void {
    if (this.isInAlert) return;
    this.isInAlert = true;
    this.startVibrateAlert();
    this.alertCallbacks.forEach((cb) => cb(true));
  }

  stopAlert(): void {
    if (!this.isInAlert) return;
    this.isInAlert = false;
    this.stopVibrateAlert();
    this.alertCallbacks.forEach((cb) => cb(false));
  }

  isAlerting(): boolean {
    return this.isInAlert;
  }

  onAlertChange(callback: (isAlerting: boolean) => void): void {
    const index = this.alertCallbacks.indexOf(callback);
    if (index === -1) {
      this.alertCallbacks.push(callback);
    }
  }

  offAlertChange(callback: (isAlerting: boolean) => void): void {
    const index = this.alertCallbacks.indexOf(callback);
    if (index > -1) {
      this.alertCallbacks.splice(index, 1);
    }
  }

  private startVibrateAlert(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 500 }, { id: 0, usage: 'alarm' });
    } catch (e) {
      console.error('Vibrate failed');
    }
    
    this.vibrateInterval = setInterval(() => {
      try {
        vibrator.startVibration({ type: 'time', duration: 100 }, { id: 0, usage: 'alarm' });
      } catch (e) {
        console.error('Vibrate interval failed');
      }
    }, 2000);
  }

  private stopVibrateAlert(): void {
    if (this.vibrateInterval !== null) {
      clearInterval(this.vibrateInterval);
      this.vibrateInterval = null;
    }
    try {
      vibrator.stopVibration();
    } catch (e) {
      console.error('Stop vibrate failed');
    }
  }
}
