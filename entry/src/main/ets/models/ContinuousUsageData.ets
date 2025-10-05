/**
 * 连续使用数据类
 * 必须使用@ObservedV2注解，内部属性使用@Trace注解
 * 这样才能确保UI响应式更新
 */

@ObservedV2
export class ContinuousUsageData {
  @Trace lastUsageDate: string = '';
  @Trace consecutiveDays: number = 0;
  @Trace todayUsageCompleted: boolean = false;
  @Trace totalUsageSeconds: number = 0;
  
  constructor(
    lastUsageDate: string = '',
    consecutiveDays: number = 0,
    todayUsageCompleted: boolean = false,
    totalUsageSeconds: number = 0
  ) {
    this.lastUsageDate = lastUsageDate;
    this.consecutiveDays = consecutiveDays;
    this.todayUsageCompleted = todayUsageCompleted;
    this.totalUsageSeconds = totalUsageSeconds;
  }
  
  /**
   * 重置今日使用数据（每天重置）
   */
  public resetTodayUsage(): void {
    this.todayUsageCompleted = false;
    this.totalUsageSeconds = 0;
  }
  
  /**
   * 更新使用秒数
   * @param seconds 当前使用秒数
   */
  public updateUsageSeconds(seconds: number): void {
    this.totalUsageSeconds = seconds;
  }
  
  /**
   * 标记今日使用完成
   */
  public markTodayCompleted(): void {
    this.todayUsageCompleted = true;
  }
  
  /**
   * 检查今日是否已完成使用
   * @returns 是否已完成
   */
  public isTodayCompleted(): boolean {
    return this.todayUsageCompleted;
  }
  
  /**
   * 获取今日使用进度百分比
   * @param totalSeconds 总需要秒数
   * @returns 进度百分比 (0-100)
   */
  public getProgressPercent(totalSeconds: number = 60): number {
    return Math.min(100, Math.round((this.totalUsageSeconds / totalSeconds) * 100));
  }
  
  /**
   * 获取剩余秒数
   * @param totalSeconds 总需要秒数
   * @returns 剩余秒数
   */
  public getRemainingSeconds(totalSeconds: number = 60): number {
    return Math.max(0, totalSeconds - this.totalUsageSeconds);
  }
}