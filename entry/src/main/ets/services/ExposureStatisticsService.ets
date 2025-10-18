/**
 * 噪音暴露统计服务
 * 纯粹的暴露统计，不包含警报次数、使用时长等无关数据
 */

import { DecibelRecord } from '../models/DecibelRecord';
import { ExposureData } from '../models/ExposureData';
import { RelationalStoreService } from './RelationalStoreService';
import { DecibelRecordService } from './DecibelRecordService';
import common from '@ohos.app.ability.common';
import { FilterConfig, TimeRangeFilter } from '../models/FilterConfig';

// 国家噪音暴露标准 (8小时工作制)
const DAILY_EXPOSURE_LIMIT = 85; // 85分贝，8小时
const EXPOSURE_DURATION_LIMIT = 8 * 60 * 60 * 1000; // 8小时，毫秒

// 定义峰值和平均值接口
interface PeakAndAverage {
  peak: number;
  average: number;
}

export class ExposureStatisticsService {
  private static instance: ExposureStatisticsService | null = null;
  private relationalStoreService: RelationalStoreService = RelationalStoreService.getInstance();
  private decibelRecordService: DecibelRecordService | null = null;
  private context: common.Context | null = null;

  private constructor() {}

  public static getInstance(): ExposureStatisticsService {
    if (!ExposureStatisticsService.instance) {
      ExposureStatisticsService.instance = new ExposureStatisticsService();
    }
    return ExposureStatisticsService.instance;
  }

  /**
   * 设置上下文，用于初始化DecibelRecordService
   */
  public setContext(context: common.Context): void {
    this.context = context;
    if (context) {
      this.decibelRecordService = new DecibelRecordService(context);
    }
  }

  /**
   * 计算今日噪音暴露数据
   * 纯粹的暴露统计，不包含其他无关数据
   */
  public async calculateTodayExposure(): Promise<ExposureData> {
    try {
      // 获取今日的噪音记录
      const todayRecords = await this.getTodayDecibelRecords();
      
      if (todayRecords.length === 0) {
        return new ExposureData(0, '8小时', 0, 0);
      }

      // 计算暴露剂量百分比
      const exposurePercentage = this.calculateExposurePercentage(todayRecords);
      
      // 计算剩余安全时间
      const remainingSafeTime = this.calculateRemainingSafeTime(exposurePercentage);
      
      // 计算今日峰值和平均值
      const peakAndAverage = this.calculatePeakAndAverage(todayRecords);

      return new ExposureData(
        exposurePercentage,
        remainingSafeTime,
        peakAndAverage.peak,
        peakAndAverage.average
      );
    } catch (error) {
      console.error('计算暴露数据失败:', error);
      return new ExposureData(0, '8小时', 0, 0);
    }
  }

  /**
   * 获取今日的噪音记录 - 使用专门的DecibelRecordService
   */
  private async getTodayDecibelRecords(): Promise<DecibelRecord[]> {
    if (!this.decibelRecordService) {
      console.error('DecibelRecordService未初始化，请先调用setContext方法');
      return [];
    }

    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000);

    try {
      // 创建时间范围过滤器
      const filters = new FilterConfig(true);
      filters.timeRange = new TimeRangeFilter(todayStart.getTime(), todayEnd.getTime());

      // 直接使用过滤查询获取今日记录
      const todayRecords = await this.decibelRecordService.getFilteredRecords(filters);
      
      console.info('获取到今日记录数量:', todayRecords.length);
      return todayRecords;
    } catch (error) {
      console.error('获取今日记录失败:', error);
      return [];
    }
  }

  /**
   * 计算暴露剂量百分比
   * 基于国家标准的等效连续A声级计算方法
   */
  private calculateExposurePercentage(records: DecibelRecord[]): number {
    if (records.length === 0) return 0;

    // 计算等效连续A声级 (Leq)
    let totalEnergy = 0;
    let totalDuration = 0;
    
    for (let i = 0; i < records.length - 1; i++) {
      const current = records[i];
      const next = records[i + 1];
      const duration = next.timestamp - current.timestamp;
      
      if (duration > 0) {
        // 使用能量平均法计算Leq
        const energy = Math.pow(10, current.avgDecibel / 10) * duration;
        totalEnergy += energy;
        totalDuration += duration;
      }
    }

    if (totalDuration === 0) return 0;

    const leq = 10 * Math.log10(totalEnergy / totalDuration);
    
    // 根据国家标准计算暴露剂量
    // 剂量 = 100% × (实际暴露时间 / 允许暴露时间)
    // 允许暴露时间根据85分贝标准计算
    const allowedExposureTime = this.calculateAllowedExposureTime(leq);
    const actualExposureTime = totalDuration;
    
    let exposurePercentage = (actualExposureTime / allowedExposureTime) * 100;
    
    // 限制在0-100%范围内
    return Math.min(Math.max(exposurePercentage, 0), 100);
  }

  /**
   * 计算允许暴露时间 (基于85分贝标准)
   * 每增加3分贝，允许暴露时间减半
   */
  private calculateAllowedExposureTime(leq: number): number {
    if (leq <= DAILY_EXPOSURE_LIMIT) {
      return EXPOSURE_DURATION_LIMIT;
    }
    
    const difference = leq - DAILY_EXPOSURE_LIMIT;
    const halvings = Math.floor(difference / 3);
    return EXPOSURE_DURATION_LIMIT / Math.pow(2, halvings);
  }

  /**
   * 计算剩余安全时间
   */
  private calculateRemainingSafeTime(exposurePercentage: number): string {
    if (exposurePercentage >= 100) {
      return $r('app.string.exposure_exceeded').toString();
    }
    
    const remainingPercentage = 100 - exposurePercentage;
    const remainingTimeMinutes = Math.floor((remainingPercentage / 100) * 8 * 60);
    
    if (remainingTimeMinutes >= 60) {
      const hours = Math.floor(remainingTimeMinutes / 60);
      const minutes = remainingTimeMinutes % 60;
      return `${hours}小时${minutes}分钟`;
    } else {
      return `${remainingTimeMinutes}分钟`;
    }
  }

  /**
   * 计算峰值和平均值
   */
  private calculatePeakAndAverage(records: DecibelRecord[]): PeakAndAverage {
    if (records.length === 0) {
      const result: PeakAndAverage = {
        peak: 0,
        average: 0
      };
      return result;
    }

    let peak = records[0].maxDecibel;
    let sum = 0;
    let count = 0;

    for (const record of records) {
      if (record.maxDecibel > peak) {
        peak = record.maxDecibel;
      }
      sum += record.avgDecibel;
      count++;
    }

    const average = Math.round(sum / count * 10) / 10; // 保留一位小数

    const result: PeakAndAverage = {
      peak: peak,
      average: average
    };
    return result;
  }

  /**
   * 获取暴露数据更新时间
   */
  public getLastUpdateTime(): number {
    return Date.now();
  }

  /**
   * 重置服务状态
   */
  public reset(): void {
    // 纯粹的统计服务，无需复杂重置逻辑
  }
}