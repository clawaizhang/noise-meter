/**
 * 会员管理器
 * 管理应用会员状态和权限控制
 */

import { PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../models/PreferenceKeys';

/**
 * 会员等级枚举
 */
export enum MembershipLevel {
  FREE = 'free',      // 免费用户
  PRO = 'pro'         // 专业会员
}

/**
 * 会员状态类
 */
@ObservedV2
export class MembershipStatus {
  @Trace level: MembershipLevel;
  @Trace expiryDate: number;     // 过期时间戳
  @Trace isTrial: boolean;       // 是否试用期
  @Trace trialDays: number;      // 试用天数
  @Trace purchaseDate: number;   // 购买时间

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
}

/**
 * 会员管理器类
 */
@ObservedV2
export class MembershipManager {
  private static instance: MembershipManager;
  
  // 当前会员状态
  @Trace
  private currentMembership: MembershipStatus = new MembershipStatus();

  // 首选项连接
  private pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  private constructor() {
    // 从首选项加载会员状态
    this.loadMembershipStatus();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): MembershipManager {
    if (!MembershipManager.instance) {
      MembershipManager.instance = new MembershipManager();
    }
    return MembershipManager.instance;
  }

  /**
   * 检查是否是专业会员
   */
  public static isProMember(): boolean {
    const instance = MembershipManager.getInstance();
    return instance.currentMembership.level === MembershipLevel.PRO || 
           instance.currentMembership.isTrial;
  }

  /**
   * 检查会员功能权限
   */
  public static hasProFeature(): boolean {
    return MembershipManager.isProMember();
  }

  /**
   * 升级到专业版
   */
  public static async upgradeToPro(): Promise<void> {
    const instance = MembershipManager.getInstance();
    
    // 模拟支付成功后的状态更新
    instance.currentMembership = new MembershipStatus(
      MembershipLevel.PRO,
      Date.now() + 30 * 24 * 60 * 60 * 1000, // 30天
      false,
      0,
      Date.now()
    );
    
    // 保存到首选项
    await instance.saveMembershipStatus();
    
    console.info('[会员管理] 已升级到专业版');
  }

  /**
   * 开始试用
   */
  public static startTrial(days: number = 7): void {
    const instance = MembershipManager.getInstance();
    
    instance.currentMembership = new MembershipStatus(
      MembershipLevel.FREE,
      Date.now() + days * 24 * 60 * 60 * 1000,
      true,
      days,
      0
    );
    
    instance.saveMembershipStatus();
    console.info(`[会员管理] 开始${days}天试用`);
  }

  /**
   * 检查会员状态
   */
  public static checkMembershipStatus(): void {
    const instance = MembershipManager.getInstance();
    
    // 检查是否过期
    if (instance.currentMembership.expiryDate > 0 && 
        Date.now() > instance.currentMembership.expiryDate) {
      // 会员过期，降级到免费版
      instance.currentMembership = new MembershipStatus();
      instance.saveMembershipStatus();
      console.info('[会员管理] 会员已过期，降级到免费版');
    }
  }

  /**
   * 获取会员状态
   */
  public static getMembershipStatus(): MembershipStatus {
    return MembershipManager.getInstance().currentMembership;
  }

  /**
   * 从首选项加载会员状态
   */
  private loadMembershipStatus(): void {
    try {
      // 这里可以从首选项加载实际的会员状态
      // 目前使用默认的免费状态
      this.currentMembership = new MembershipStatus();
    } catch (error) {
      console.error('[会员管理] 加载会员状态失败:', error);
    }
  }

  /**
   * 保存会员状态到首选项
   */
  private async saveMembershipStatus(): Promise<void> {
    try {
      // 这里可以将会员状态保存到首选项
      // 目前仅保存到内存中
      console.info('[会员管理] 会员状态已更新');
    } catch (error) {
      console.error('[会员管理] 保存会员状态失败:', error);
    }
  }
}