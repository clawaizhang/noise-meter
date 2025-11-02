/**
 * 连续使用天数管理服务
 * 负责计算和管理用户的连续使用天数
 */

import { PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../models/PreferenceKeys';
import { ContinuousUsageData } from '../models/ContinuousUsageData';

interface UsageStatus {
  consecutiveDays: number;
  todayUsageSeconds: number;
  todayCompleted: boolean;
  lastUsageDate: string;
}

export class ContinuousUsageManager {
  private static instance: ContinuousUsageManager | null = null;
  private pk: PreferenceKeys;

  constructor(pk: PreferenceKeys) {
    this.pk = pk;
  }



  /**
   * 获取 ContinuousUsageManager 实例
   */
  public static getInstance(pk: PreferenceKeys): ContinuousUsageManager {
    if (!ContinuousUsageManager.instance) {
      ContinuousUsageManager.instance = new ContinuousUsageManager(pk);
    }
    return ContinuousUsageManager.instance;
  }

  /**
   * 检查并更新连续天数
   * @returns 更新后的连续天数
   */
  public checkAndUpdateConsecutiveDays(): number {
    const today = this.getTodayDateString();
    const usageData = this.pk.continuous_usage_data;

    // 如果是首次使用，初始化数据
    if (!usageData.lastUsageDate) {
      usageData.lastUsageDate = today;
      usageData.consecutiveDays = 1;
      usageData.resetTodayUsage();
      return 1;
    }

    // 检查是否断签
    if (this.checkIfBreakChain(usageData.lastUsageDate, today)) {
      // 断签，重置为1天
      usageData.consecutiveDays = 1;
      usageData.lastUsageDate = today;
      usageData.resetTodayUsage();
      return 1;
    }

    // 如果是连续使用，检查是否需要增加天数
    if (usageData.lastUsageDate !== today) {
      // 新的一天，增加连续天数
      usageData.consecutiveDays++;
      usageData.lastUsageDate = today;
      usageData.resetTodayUsage();
    }

    return usageData.consecutiveDays;
  }

  /**
   * 记录今日使用完成
   */
  public markTodayUsageCompleted(): void {
    this.pk.continuous_usage_data.markTodayCompleted();
  }

  /**
   * 获取连续天数
   * @returns 连续天数
   */
  public getConsecutiveDays(): number {
    return this.pk.continuous_usage_data.consecutiveDays;
  }

  /**
   * 获取今日使用秒数
   * @returns 使用秒数
   */
  public getTodayUsageSeconds(): number {
    return this.pk.continuous_usage_data.totalUsageSeconds;
  }

  /**
   * 更新今日使用秒数
   * @param seconds 使用秒数
   */
  public updateTodayUsageSeconds(seconds: number): void {
    this.pk.continuous_usage_data.updateUsageSeconds(seconds);
  }

  /**
   * 检查是否断签
   * @param lastDate 最后使用日期
   * @param currentDate 当前日期
   * @returns 是否断签
   */
  private checkIfBreakChain(lastDate: string, currentDate: string): boolean {
    try {
      const last = new Date(lastDate);
      const current = new Date(currentDate);
      const diffTime = current.getTime() - last.getTime();
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      // 如果相差超过1天，说明断签
      return diffDays > 1;
    } catch (error) {
      console.error('检查连续使用天数时发生错误:', error);
      // 日期解析失败，视为断签
      return true;
    }
  }

  /**
   * 获取今天日期字符串
   * @returns 日期字符串 "YYYY-MM-DD"
   */
  private getTodayDateString(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * 处理日期变化
   * @returns 前一天的连续天数，如果没有日期变化返回0
   */
  public handleDateChange(): number {
    const today = this.getTodayDateString();
    const usageData = this.pk.continuous_usage_data;

    // 如果最后使用日期不是今天，说明日期变化
    if (usageData.lastUsageDate !== today) {
      // 保存前一天的连续天数用于奖励计算
      const previousConsecutiveDays = usageData.consecutiveDays;

      // 更新连续天数
      const newConsecutiveDays = this.checkAndUpdateConsecutiveDays();

      console.info(`[连续使用] 日期变化处理: 前一天${previousConsecutiveDays}天，新连续${newConsecutiveDays}天`);

      // 返回前一天的连续天数用于奖励计算
      return previousConsecutiveDays;
    }

    return 0; // 没有日期变化
  }

  /**
   * 重置连续使用数据（用于测试或异常恢复）
   */
  public resetContinuousUsageData(): void {
    const today = this.getTodayDateString();
    this.pk.continuous_usage_data.lastUsageDate = today;
    this.pk.continuous_usage_data.consecutiveDays = 1;
    this.pk.continuous_usage_data.resetTodayUsage();
  }

  /**
   * 获取使用数据统计
   * @returns 使用数据统计
   */
  public getUsageStats(): UsageStatus {
    const usageData = this.pk.continuous_usage_data;
    return {
      consecutiveDays: usageData.consecutiveDays,
      todayUsageSeconds: usageData.totalUsageSeconds,
      todayCompleted: usageData.todayUsageCompleted,
      lastUsageDate: usageData.lastUsageDate
    };
  }
}