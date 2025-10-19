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
import {
  NoiseExposureStandard,
  DecibelRange,
  StandardConfigs,
  DecibelRangeConfigs
} from '../constants/ExposureStandardConstants';

// 定义峰值和平均值接口
interface PeakAndAverage {
  peak: number;
  average: number;
}

// 分贝区间统计数据
interface DecibelRangeStats {
  range: DecibelRange;
  duration: string;
  percentage: number;
}

// 多标准暴露数据
interface MultiStandardExposureData {
  standard: NoiseExposureStandard;
  exposurePercentage: number;
  remainingSafeTime: string;
  complianceStatus: 'safe' | 'warning' | 'danger';
}

export class ExposureStatisticsService {
  private static instance: ExposureStatisticsService | null = null;
  private relationalStoreService: RelationalStoreService = RelationalStoreService.getInstance();
  private decibelRecordService: DecibelRecordService | null = null;
  private context: common.Context | null = null;

  private constructor() {
  }

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
  public async calculateTodayExposure(standard: NoiseExposureStandard = NoiseExposureStandard.INDUSTRIAL): Promise<ExposureData> {
    try {
      // 获取今日的噪音记录
      const todayRecords = await this.getTodayDecibelRecords();

      if (todayRecords.length === 0) {
        const config = StandardConfigs[standard];
        const defaultTime = config.baseDuration >= 24 * 60 * 60 * 1000 ? '24小时' : '8小时';
        return new ExposureData(0, defaultTime, 0, 0);
      }

      // 计算暴露剂量百分比
      const exposurePercentage = this.calculateExposurePercentage(todayRecords, standard);

      // 计算剩余安全时间
      const remainingSafeTime = this.calculateRemainingSafeTime(exposurePercentage, standard);

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
      const config = StandardConfigs[standard];
      const defaultTime = config.baseDuration >= 24 * 60 * 60 * 1000 ? '24小时' : '8小时';
      return new ExposureData(0, defaultTime, 0, 0);
    }
  }


  /**
   * 计算分贝区间统计数据
   */
  public async calculateDecibelRangeStats(): Promise<DecibelRangeStats[]> {
    try {
      const todayRecords = await this.getTodayDecibelRecords();

      if (todayRecords.length === 0) {
        return this.getEmptyDecibelRangeStats();
      }

      // 初始化区间统计
      const rangeStats: Map<DecibelRange, number> = new Map();
      Object.values(DecibelRange).forEach(range => {
        rangeStats.set(range, 0);
      });

      // 计算每个记录的时间分布 - 直接使用duration字段
      let totalDuration = 0;
      for (const record of todayRecords) {
        const range = this.getDecibelRange(record.avgDecibel);
        const duration = record.duration; // 直接使用记录的持续时间（单位：秒）
        rangeStats.set(range, rangeStats.get(range)! + duration);
        totalDuration += duration;
      }

      // 转换为百分比
      const results: DecibelRangeStats[] = [];
      for (const entry of rangeStats.entries()) {
        const range = entry[0];
        const duration = entry[1];
        const percentage = totalDuration > 0 ? (duration / totalDuration) * 100 : 0;
        results.push({
          range: range,
          duration: this.formatDuration(duration),
          percentage: Math.round(percentage * 10) / 10 // 保留一位小数
        });
      }

      return results;
    } catch (error) {
      console.error('计算分贝区间统计失败:', error);
      return this.getEmptyDecibelRangeStats();
    }
  }

  /**
   * 格式化持续时间
   */
  private formatDuration(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    if (minutes < 60) {
      return `${minutes}分钟`;
    }
    const hours = Math.floor(minutes / 60);
    const remainingMinutes = minutes % 60;
    return `${hours}小时${remainingMinutes}分钟`;
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
  private calculateExposurePercentage(records: DecibelRecord[], standard: NoiseExposureStandard): number {
    if (records.length === 0) {
      return 0;
    }

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

    if (totalDuration === 0) {
      return 0;
    }

    const leq = 10 * Math.log10(totalEnergy / totalDuration);

    // 根据国家标准计算暴露剂量
    // 剂量 = 100% × (实际暴露时间 / 允许暴露时间)
    const allowedExposureTime = this.calculateAllowedExposureTime(leq, standard);
    const actualExposureTime = totalDuration;

    let exposurePercentage = (actualExposureTime / allowedExposureTime) * 100;

    // 限制在0-100%范围内
    return Math.min(Math.max(exposurePercentage, 0), 100);
  }

  /**
   * 计算允许暴露时间 (基于不同标准)
   * 工业企业标准：每增加3分贝，允许暴露时间减半
   * 其他标准：基于基础限制值计算
   */
  private calculateAllowedExposureTime(leq: number, standard: NoiseExposureStandard): number {
    const config = StandardConfigs[standard];

    if (standard === NoiseExposureStandard.INDUSTRIAL) {
      // 工业企业标准：每增加3分贝，时间减半
      if (leq <= config.baseLimit) {
        return config.baseDuration;
      }

      const difference = leq - config.baseLimit;
      const halvings = Math.floor(difference / 3);
      return config.baseDuration / Math.pow(2, halvings);
    } else {
      // 其他标准：基于基础限制值计算
      if (leq <= config.baseLimit) {
        return config.baseDuration;
      }

      // 对于超过限制值的情况，按比例减少允许时间
      const excessRatio = Math.pow(10, (leq - config.baseLimit) / 10);
      return config.baseDuration / excessRatio;
    }
  }

  /**
   * 计算剩余安全时间
   */
  private calculateRemainingSafeTime(exposurePercentage: number, standard: NoiseExposureStandard): string {
    if (exposurePercentage >= 100) {
      return $r('app.string.exposure_exceeded').toString();
    }

    const config = StandardConfigs[standard];
    const remainingPercentage = 100 - exposurePercentage;
    const totalMinutes = (config.baseDuration / (60 * 1000)) * (remainingPercentage / 100);

    if (totalMinutes >= 60) {
      const hours = Math.floor(totalMinutes / 60);
      const minutes = Math.floor(totalMinutes % 60);
      return `${hours}小时${minutes}分钟`;
    } else {
      return `${Math.floor(totalMinutes)}分钟`;
    }
  }

  /**
   * 获取分贝区间
   */
  private getDecibelRange(decibel: number): DecibelRange {
    if (decibel < 50) {
      return DecibelRange.VERY_QUIET;
    }
    if (decibel < 60) {
      return DecibelRange.QUIET;
    }
    if (decibel < 70) {
      return DecibelRange.MODERATE;
    }
    if (decibel < 80) {
      return DecibelRange.NOISY;
    }
    if (decibel < 85) {
      return DecibelRange.HIGH;
    }
    if (decibel < 90) {
      return DecibelRange.VERY_HIGH;
    }
    return DecibelRange.EXTREME;
  }

  /**
   * 获取合规状态
   */
  private getComplianceStatus(exposurePercentage: number): 'safe' | 'warning' | 'danger' {
    if (exposurePercentage < 30) {
      return 'safe';
    }
    if (exposurePercentage < 80) {
      return 'warning';
    }
    return 'danger';
  }


  /**
   * 获取空的分贝区间统计数据
   */
  private getEmptyDecibelRangeStats(): DecibelRangeStats[] {
    return Object.values(DecibelRange).map(range => {
      let data: DecibelRangeStats = {
        range: range,
        duration: '0分钟',
        percentage: 0
      };
      return data;
    });
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