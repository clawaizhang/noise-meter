/**
 * 福利活动数据模型
 * 用于存储7天签到领福利活动的相关数据
 */

@ObservedV2
export class BenefitActivityData {
  /**
   * 是否有福利活动资格
   */
  @Trace
  hasBenefitActivity: boolean = false;

  /**
   * 是否已完成活动
   */
  @Trace
  benefitActivityCompleted: boolean = false;

  /**
   * 当前连续签到天数
   */
  @Trace
  currentStreak: number = 0;

  /**
   * 累计奖励天数
   */
  @Trace
  totalRewardDays: number = 0;

  /**
   * 今日签到获得的天数
   */
  @Trace
  todayReward: number = 0;

  /**
   * 上次签到日期
   */
  @Trace
  lastSignDate: number = 0;

  /**
   * 签到日期列表
   */
  @Trace
  signDates: number[] = [];

  /**
   * 活动开始日期
   */
  @Trace
  activityStartDate: number = 0;

  /**
   * 活动过期日期
   */
  @Trace
  activityExpiryDate: number = 0;

  /**
   * 重置活动数据
   */
  public reset(): void {
    this.hasBenefitActivity = false;
    this.benefitActivityCompleted = false;
    this.currentStreak = 0;
    this.totalRewardDays = 0;
    this.todayReward = 0;
    this.lastSignDate = 0;
    this.signDates = [];
    this.activityStartDate = 0;
    this.activityExpiryDate = 0;
  }
}
