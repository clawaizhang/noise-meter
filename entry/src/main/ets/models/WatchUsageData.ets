/**
 * 手表端使用数据类
 * 使用 @ObservedV2 和 @Trace 实现 PersistenceV2 持久化
 * 管理非会员的每日使用限制：3次，每次60秒
 */

@ObservedV2
export class WatchUsageData {
  // 今日已使用次数
  @Trace usedTimes: number = 0;
  
  // 当前正在进行的检测剩余秒数
  @Trace remainingSeconds: number = 60;
  
  // 当前使用日期（格式：YYYY-MM-DD）
  @Trace currentDate: string = '';

  constructor() {
    this.currentDate = this.getTodayString();
  }

  private getTodayString(): string {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
  }

  /**
   * 检查是否需要重置（跨天了）
   */
  needReset(): boolean {
    return this.currentDate !== this.getTodayString();
  }

  /**
   * 重置今日数据
   */
  reset(): void {
    this.usedTimes = 0;
    this.remainingSeconds = 60;
    this.currentDate = this.getTodayString();
  }

  /**
   * 获取今日剩余次数
   */
  getRemainingTimes(): number {
    const maxTimes = 3;
    return Math.max(0, maxTimes - this.usedTimes);
  }

  /**
   * 是否还有剩余次数
   */
  hasRemainingTimes(): boolean {
    return this.getRemainingTimes() > 0;
  }

  /**
   * 开始一次新的检测会话
   */
  startSession(): void {
    this.remainingSeconds = 60;
  }

  /**
   * 结束当前检测会话（时间到）
   */
  endSession(): void {
    this.usedTimes++;
    this.remainingSeconds = 0;
  }

  /**
   * 倒计时 tick
   */
  tick(): void {
    if (this.remainingSeconds > 0) {
      this.remainingSeconds--;
    }
  }

  /**
   * 重置倒计时（用于重新开始）
   */
  resetCountdown(): void {
    this.remainingSeconds = 60;
  }
}
