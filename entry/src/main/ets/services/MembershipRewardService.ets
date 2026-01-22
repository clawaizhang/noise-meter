/**
 * 会员赠送服务
 * 负责根据连续使用天数计算和赠送会员
 */

import { PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../models/PreferenceKeys';
import { MembershipLevel } from './MembershipManager';

// 里程碑奖励规则
const MILESTONE_REWARDS: Record<number, number> = {
  1: 1, // 连续1天 → 1天
  2: 2, // 连续2天 → 2天
  3: 5, // 连续3天 → 5天
  4: 3, // 连续4天 → 3天
  5: 4, // 连续5天 → 4天
  6: 5, // 连续6天 → 5天
  7: 10, // 连续7天 → 10天
  8: 5, // 连续8天 → 5天
  9: 6, // 连续9天 → 6天
  10: 15, // 连续10天 → 15天
  15: 30, // 连续15天 → 30天
  30: 60  // 连续30天 → 60天
};

@ObservedV2
export class DayReward {
  @Trace
  days: number;
  @Trace
  reward: number;

  constructor(days: number, reward: number) {
    this.days = days;
    this.reward = reward;
  }
}

interface ConsecutiveRewards {
  todayReward: number;
  tomorrowReward: number;
  nextMilestone: DayReward | null;
}

/**
 * 福利活动签到结果接口
 */
export interface BenefitSignResult {
  success: boolean;
  day: number;
  baseReward: number;
  bonusReward: number;
  totalRewardDays: number;
  isCompleted: boolean;
}

/**
 * 随机加成配置接口
 */
export interface BonusProbabilityConfig {
  max: number;
  probability: number;
}

export class MembershipRewardService {
  private static instance: MembershipRewardService | null = null;
  private pk: PreferenceKeys;

  constructor(pk: PreferenceKeys) {
    this.pk = pk;
  }



  /**
   * 获取 MembershipRewardService 实例
   */
  public static getInstance(pk: PreferenceKeys): MembershipRewardService {
    if (!MembershipRewardService.instance) {
      MembershipRewardService.instance = new MembershipRewardService(pk);
    }
    return MembershipRewardService.instance;
  }

  /**
   * 计算应赠送会员天数
   * @param consecutiveDays 连续天数
   * @returns 应赠送天数
   */
  public calculateRewardDays(consecutiveDays: number): number {
    // 如果连续天数在里程碑中，返回对应的奖励天数
    if (MILESTONE_REWARDS[consecutiveDays]) {
      return MILESTONE_REWARDS[consecutiveDays];
    }

    // 如果不在里程碑中，使用基础规则：连续天数 = 赠送天数
    // 但不超过最近里程碑的奖励
    return this.getBaseRewardDays(consecutiveDays);
  }

  /**
   * 应用会员奖励
   * @param consecutiveDays 连续天数
   */
  public applyMembershipReward(consecutiveDays: number): void {
    // 检查用户是否已同意会员奖励协议
    if (!this.pk.has_agreed_membership_reward) {
      console.info('[会员奖励] 用户未同意会员奖励协议，暂不赠送会员');
      return;
    }

    const rewardDays = this.calculateRewardDays(consecutiveDays);
    const membership = this.pk.member_ship;

    // 计算新的过期时间
    const now = Date.now();
    const oneDayMs = 24 * 60 * 60 * 1000;

    if (membership.level === MembershipLevel.PRO && membership.expiryDate > now) {
      // 如果已经是专业会员且未过期，延长过期时间
      membership.expiryDate += rewardDays * oneDayMs;
    } else {
      // 如果是免费用户或会员已过期，设置新的过期时间
      membership.level = MembershipLevel.PRO;
      membership.expiryDate = now + rewardDays * oneDayMs;
      membership.isTrial = false;
      membership.trialDays = 0;
      membership.purchaseDate = now;
    }

    console.info(`[会员奖励] 连续使用${consecutiveDays}天，获得${rewardDays}天会员，到期时间: ${new Date(membership.expiryDate).toLocaleDateString()}`);
  }

  /**
   * 获取明日奖励预告
   * @param consecutiveDays 当前连续天数
   * @returns 明日将获得的奖励天数
   */
  public getTomorrowRewardPreview(consecutiveDays: number): number {
    const tomorrowDays = consecutiveDays + 1;
    return this.calculateRewardDays(tomorrowDays);
  }

  /**
   * 获取下一个里程碑
   * @param consecutiveDays 当前连续天数
   * @returns 下一个里程碑信息，如果没有返回null
   */
  public getNextMilestone(consecutiveDays: number): DayReward | null {
    const milestoneDays = Object.keys(MILESTONE_REWARDS)
      .map(Number)
      .filter(days => days > consecutiveDays)
      .sort((a, b) => a - b);

    if (milestoneDays.length > 0) {
      const nextDays = milestoneDays[0];
      return new DayReward(nextDays, MILESTONE_REWARDS[nextDays]);
    }

    return null;
  }

  /**
   * 获取当前连续天数对应的奖励信息
   * @param consecutiveDays 连续天数
   * @returns 奖励信息
   */
  public getCurrentRewardInfo(consecutiveDays: number): ConsecutiveRewards {
    return {
      todayReward: this.calculateRewardDays(consecutiveDays),
      tomorrowReward: this.getTomorrowRewardPreview(consecutiveDays),
      nextMilestone: this.getNextMilestone(consecutiveDays)
    };
  }

  /**
   * 获取基础奖励天数（用于不在里程碑中的天数）
   * @param consecutiveDays 连续天数
   * @returns 基础奖励天数
   */
  private getBaseRewardDays(consecutiveDays: number): number {
    // 找到最近的里程碑
    const milestoneDays = Object.keys(MILESTONE_REWARDS)
      .map(Number)
      .filter(days => days < consecutiveDays)
      .sort((a, b) => b - a);

    if (milestoneDays.length > 0) {
      const lastMilestoneDays = milestoneDays[0];
      const lastMilestoneReward = MILESTONE_REWARDS[lastMilestoneDays];

      // 基础规则：连续天数 = 赠送天数，但不超过最近里程碑的奖励
      return Math.min(consecutiveDays, lastMilestoneReward);
    }

    // 如果没有里程碑，使用连续天数
    return consecutiveDays;
  }

  /**
   * 获取所有里程碑信息
   * @returns 所有里程碑信息
   */
  public getAllMilestones(): Array<DayReward> {
    return Object.keys(MILESTONE_REWARDS)
      .map(Number)
      .sort((a, b) => a - b)
      .map(days => {
        let dayReward: DayReward = new DayReward(days, MILESTONE_REWARDS[days])
        return dayReward;
      });
  }

  /**
   * 检查是否达到里程碑
   * @param consecutiveDays 连续天数
   * @returns 是否达到里程碑
   */
  public isMilestoneReached(consecutiveDays: number): boolean {
    return MILESTONE_REWARDS[consecutiveDays] !== undefined;
  }

  /**
   * 获取里程碑奖励描述
   * @param consecutiveDays 连续天数
   * @returns 里程碑描述，如果不是里程碑返回null
   */
  public getMilestoneDescription(consecutiveDays: number): string | null {
    if (this.isMilestoneReached(consecutiveDays)) {
      const rewardDays = MILESTONE_REWARDS[consecutiveDays];
      return `连续${consecutiveDays}天里程碑奖励：${rewardDays}天会员`;
    }
    return null;
  }

  // ==================== 福利活动相关方法 ====================

  // 每日基础奖励配置（7天）
  private readonly DAILY_BASE_REWARDS: Record<number, number> = {
    1: 25,
    2: 25,
    3: 25,
    4: 25,
    5: 25,
    6: 25,
    7: 30
  };

  // 随机加成范围
  private readonly BONUS_MIN: number = 0;
  private readonly BONUS_MAX: number = 130;

  // 随机加成概率配置
  private readonly BONUS_PROBABILITIES: BonusProbabilityConfig[] = [
    { max: 0, probability: 0.10 },      // 0天：10%
    { max: 30, probability: 0.30 },    // 1-30天：30%
    { max: 60, probability: 0.25 },    // 31-60天：25%
    { max: 90, probability: 0.20 },    // 61-90天：20%
    { max: 130, probability: 0.15 }    // 91-130天：15%
  ];

  /**
   * 初始化福利活动
   * 给予用户福利活动资格
   */
  public initBenefitActivity(): void {
    const benefitData = this.pk.benefit_activity_data;
    const now = Date.now();
    const thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;

    benefitData.hasBenefitActivity = true;
    benefitData.activityStartDate = now;
    benefitData.activityExpiryDate = now + thirtyDaysMs;

    console.info(`[福利活动] 初始化福利活动，过期时间: ${new Date(benefitData.activityExpiryDate).toLocaleDateString()}`);
  }

  /**
   * 检查福利活动是否有效
   * @returns 是否有效
   */
  public isBenefitActivityValid(): boolean {
    const benefitData = this.pk.benefit_activity_data;
    const now = Date.now();

    // 检查是否有资格
    if (!benefitData.hasBenefitActivity) {
      return false;
    }

    // 检查是否已完成
    if (benefitData.benefitActivityCompleted) {
      return false;
    }

    // 检查是否过期
    if (now > benefitData.activityExpiryDate) {
      return false;
    }

    return true;
  }

  /**
   * 执行福利活动签到
   * @returns 签到结果
   */
  public signBenefitActivity(): BenefitSignResult {
    const benefitData = this.pk.benefit_activity_data;

    // 检查活动是否有效
    if (!this.isBenefitActivityValid()) {
      throw new Error('活动已过期或已完成');
    }

    // 检查今日是否已签到
    if (this.isTodaySignedForBenefit()) {
      throw new Error('今日已签到');
    }

    // 检查是否连续签到
    const isContinuous = this.isContinuousSignForBenefit();
    if (!isContinuous) {
      // 连续签到中断，重置
      this.resetBenefitStreak();
    }

    // 增加连续天数
    benefitData.currentStreak++;

    // 获取今日基础奖励
    const baseReward = this.getBenefitDailyBaseReward(benefitData.currentStreak);

    // 计算随机加成
    const bonusReward = this.calculateBonusReward();

    // 记录签到日期
    benefitData.signDates.push(Date.now());
    benefitData.lastSignDate = Date.now();

    // 更新今日签到获得的天数
    benefitData.todayReward = baseReward + bonusReward;

    // 更新累计奖励
    benefitData.totalRewardDays += baseReward + bonusReward;

    // 检查是否完成7天签到
    if (benefitData.currentStreak >= 7) {
      benefitData.benefitActivityCompleted = true;
    }

    // 应用奖励
    this.applyBenefitReward(baseReward + bonusReward);

    return {
      success: true,
      day: benefitData.currentStreak,
      baseReward: baseReward,
      bonusReward: bonusReward,
      totalRewardDays: benefitData.totalRewardDays,
      isCompleted: benefitData.benefitActivityCompleted
    };
  }

  /**
   * 获取每日基础奖励
   * @param day 天数
   * @returns 基础奖励天数
   */
  private getBenefitDailyBaseReward(day: number): number {
    if (day <= 7) {
      return this.DAILY_BASE_REWARDS[day];
    }
    // 超过7天，按第7天计算
    return this.DAILY_BASE_REWARDS[7];
  }

  /**
   * 计算随机加成奖励
   * @returns 加成天数
   */
  private calculateBonusReward(): number {
    const random = Math.random();

    // 根据概率确定加成范围
    let cumulative = 0;
    let minBonus = 0;
    let maxBonus = 0;

    for (const config of this.BONUS_PROBABILITIES) {
      cumulative += config.probability;
      if (random <= cumulative) {
        if (config.max === 0) {
          return 0;
        }
        minBonus = (config.max === 30) ? 1 : (config.max === 60) ? 31 : (config.max === 90) ? 61 : 91;
        maxBonus = config.max;
        break;
      }
    }

    // 如果没有匹配到，返回最小加成
    if (maxBonus === 0) {
      return 0;
    }

    // 在范围内随机生成加成
    return Math.floor(Math.random() * (maxBonus - minBonus + 1)) + minBonus;
  }

  /**
   * 检查今日是否已签到
   * @returns 是否已签到
   */
  public isTodaySignedForBenefit(): boolean {
    const benefitData = this.pk.benefit_activity_data;
    const today = this.getTodayStart();
    return benefitData.signDates.some(date => date >= today);
  }

  /**
   * 检查是否连续签到
   * @returns 是否连续
   */
  private isContinuousSignForBenefit(): boolean {
    const benefitData = this.pk.benefit_activity_data;
    if (benefitData.lastSignDate === 0) {
      return true;
    }

    const yesterday = this.getTodayStart() - 24 * 60 * 60 * 1000;
    return benefitData.lastSignDate >= yesterday;
  }

  /**
   * 重置连续签到
   */
  private resetBenefitStreak(): void {
    const benefitData = this.pk.benefit_activity_data;
    benefitData.currentStreak = 0;
    benefitData.signDates = [];
  }

  /**
   * 应用福利奖励
   * @param rewardDays 奖励天数
   */
  private applyBenefitReward(rewardDays: number): void {
    const membership = this.pk.member_ship;
    const now = Date.now();
    const oneDayMs = 24 * 60 * 60 * 1000;

    if (membership.level === MembershipLevel.PRO && membership.expiryDate > now) {
      // 如果已经是专业会员且未过期，延长过期时间
      membership.expiryDate += rewardDays * oneDayMs;
    } else {
      // 如果是免费用户或会员已过期，设置新的过期时间
      membership.level = MembershipLevel.PRO;
      membership.expiryDate = now + rewardDays * oneDayMs;
      membership.isTrial = false;
      membership.trialDays = 0;
      membership.purchaseDate = now;
    }

    console.info(`[福利活动] 获得${rewardDays}天会员，到期时间: ${new Date(membership.expiryDate).toLocaleDateString()}`);
  }

  /**
   * 获取今日开始时间戳
   * @returns 时间戳
   */
  private getTodayStart(): number {
    const now = new Date();
    now.setHours(0, 0, 0, 0);
    return now.getTime();
  }
}