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

export class MembershipRewardService {
  private static instance: MembershipRewardService | null = null;
  private pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  /**
   * 获取 MembershipRewardService 实例
   */
  public static getInstance(): MembershipRewardService {
    if (!MembershipRewardService.instance) {
      MembershipRewardService.instance = new MembershipRewardService();
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
}