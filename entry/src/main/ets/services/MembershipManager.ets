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
  @Trace level: MembershipLevel;
  @Trace expiryDate: number; // 过期时间戳
  @Trace isTrial: boolean; // 是否试用期
  @Trace trialDays: number; // 试用天数
  @Trace purchaseDate: number; // 购买时间

  constructor(
    level: MembershipLevel = MembershipLevel.FREE,
    expiryDate: number = 0,
    isTrial: boolean = false,
    trialDays: number = 0,
    purchaseDate: number = 0
  ) {
    this.level = level;
    this.expiryDate = expiryDate;
    this.isTrial = isTrial;
    this.trialDays = trialDays;
    this.purchaseDate = purchaseDate;
  }

  can() {
    return (this.level === MembershipLevel.PRO || this.isTrial) && this.expiryDate > Date.now();
  }
}