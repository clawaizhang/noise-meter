/**
 * 警报服务接口
 * 定义噪音超标提醒能力
 */
export interface IAlertService {
  /**
   * 设置警报阈值
   */
  setThreshold(threshold: number): void;

  /**
   * 获取警报阈值
   */
  getThreshold(): number;

  /**
   * 检查当前分贝是否触发警报
   */
  checkAlert(currentDecibel: number): boolean;

  /**
   * 开始警报提醒
   */
  startAlert(): void;

  /**
   * 停止警报提醒
   */
  stopAlert(): void;

  /**
   * 是否正在警报中
   */
  isAlerting(): boolean;

  /**
   * 设置警报状态变化回调
   */
  onAlertChange(callback: (isAlerting: boolean) => void): void;

  /**
   * 移除警报状态变化回调
   */
  offAlertChange(callback: (isAlerting: boolean) => void): void;
}
