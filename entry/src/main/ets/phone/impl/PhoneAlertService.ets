import { IAlertService } from '../../core/interfaces/IAlertService';

/**
 * 手机端警报服务实现
 * 使用通知栏提醒（无振动）
 */
export class PhoneAlertService implements IAlertService {
  private threshold: number = 80;
  private isInAlert: boolean = false;
  private alertCallbacks: Array<(isAlerting: boolean) => void> = [];

  setThreshold(threshold: number): void {
    this.threshold = threshold;
  }

  getThreshold(): number {
    return this.threshold;
  }

  checkAlert(currentDecibel: number): boolean {
    const shouldAlert = currentDecibel >= this.threshold;
    
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
    this.sendNotification();
    this.alertCallbacks.forEach((cb) => cb(true));
  }

  stopAlert(): void {
    if (!this.isInAlert) return;
    this.isInAlert = false;
    this.cancelNotification();
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

  private sendNotification(): void {
    console.info('[PhoneAlertService] 发送噪音超标通知');
  }

  private cancelNotification(): void {
    console.info('[PhoneAlertService] 取消通知');
  }
}
