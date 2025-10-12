/**
 * 会员等级枚举
 */
export enum MembershipLevel {
  FREE = 'free', // 免费用户
  PRO = 'pro' // 专业会员
}

/**
 * 会员状态类
 */
@ObservedV2
export class MembershipStatus {
  @Trace level: MembershipLevel = MembershipLevel.FREE;
  @Trace expiryDate: number = 0; // 过期时间戳
  @Trace isTrial: boolean = false; // 是否试用期
  @Trace trialDays: number = 0; // 试用天数
  @Trace purchaseDate: number = 0; // 购买时间
  @Trace can: boolean = false;

  @Monitor('level','isTrial','expiryDate')
  onDataChange(monitor: IMonitor) {
    this.can = (this.level === MembershipLevel.PRO || this.isTrial) && this.expiryDate > Date.now();
  }
}