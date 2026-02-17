import { PreferenceKeys } from '../models/PreferenceKeys';

export interface DayReward {
  days: number;
  reward: number;
}

export interface RewardInfo {
  todayReward: number;
  tomorrowReward: number;
  nextMilestone: DayReward | null;
}

export class MembershipRewardService {
  
  static readonly LOCAL_REWARD_DISABLED: boolean = true;
  
  private static instance: MembershipRewardService;
  private pk: PreferenceKeys;

  private constructor(pk: PreferenceKeys) {
    this.pk = pk;
  }

  static getInstance(pk: PreferenceKeys): MembershipRewardService {
    if (!MembershipRewardService.instance) {
      MembershipRewardService.instance = new MembershipRewardService(pk);
    }
    return MembershipRewardService.instance;
  }

  applyMembershipReward(consecutiveDays: number): void {
    if (MembershipRewardService.LOCAL_REWARD_DISABLED) {
      console.info('[会员奖励] 本地赠送已暂停');
      return;
    }
  }

  grantVipDays(days: number): void {
    if (MembershipRewardService.LOCAL_REWARD_DISABLED) {
      console.info('[会员奖励] 功能已升级');
      return;
    }
  }

  getCurrentRewardInfo(consecutiveDays: number): RewardInfo {
    if (MembershipRewardService.LOCAL_REWARD_DISABLED) {
      return { todayReward: 0, tomorrowReward: 0, nextMilestone: null };
    }
    return { todayReward: 0, tomorrowReward: 0, nextMilestone: null };
  }

  isBenefitActivityValid(): boolean {
    return false;
  }
}
