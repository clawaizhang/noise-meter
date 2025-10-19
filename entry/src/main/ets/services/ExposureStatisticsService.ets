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
  DecibelRangeConfigs,
  StandardConfig
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

// 标准验证结果接口
interface StandardValidationResult {
  leq: number;
  allowedTime: number;
  percentage: number;
}

export class ExposureStatisticsService {
  private static instance: ExposureStatisticsService | null = null;
  private relationalStoreService: RelationalStoreService = RelationalStoreService.getInstance();
  private decibelRecordService: DecibelRecordService | null = null;
  private context: common.Context | null = null;
  private calculationCache: Map<string, number> = new Map(); // 计算缓存，提升性能

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
   * 基于每一刻分贝值的精确计算
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

      // 基于每一刻分贝值的精确计算
      let totalDuration = 0;
      for (const record of todayRecords) {
        if (!record.decibelValues || record.decibelValues.length === 0) {
          continue;
        }

        const timeInterval = record.duration / record.decibelValues.length;
        
        // 遍历每一个分贝值进行精确计算
        for (const decibel of record.decibelValues) {
          const range = this.getDecibelRange(decibel);
          rangeStats.set(range, rangeStats.get(range)! + timeInterval);
          totalDuration += timeInterval;
        }
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
   * 基于专业声学标准的不同计算方法
   * 为每个标准实现专业的计算算法
   */
  private calculateExposurePercentage(records: DecibelRecord[], standard: NoiseExposureStandard): number {
    if (records.length === 0) {
      return 0;
    }

    // 根据不同的标准使用不同的专业计算算法
    switch (standard) {
      case NoiseExposureStandard.INDUSTRIAL:
        return this.calculateIndustrialExposure(records);
      case NoiseExposureStandard.ENVIRONMENTAL:
        return this.calculateEnvironmentalExposure(records);
      case NoiseExposureStandard.OCCUPATIONAL:
        return this.calculateOccupationalExposure(records);
      case NoiseExposureStandard.SOCIAL:
        return this.calculateSocialExposure(records);
      default:
        return this.calculateIndustrialExposure(records); // 默认使用工业企业标准
    }
  }

  /**
   * 工业企业标准计算 - 3分贝减半规则
   * 专业声学原理：能量加倍原则，每增加3分贝，声能量加倍，允许暴露时间减半
   * 基于每一刻分贝值的精确计算
   */
  private calculateIndustrialExposure(records: DecibelRecord[]): number {
    let totalExposureDose = 0;

    for (const record of records) {
      if (!record.decibelValues || record.decibelValues.length === 0) {
        continue;
      }

      const timeInterval = record.duration / record.decibelValues.length;
      
      // 遍历每一个分贝值进行精确计算
      for (const decibel of record.decibelValues) {
        // 3分贝减半规则：允许暴露时间 = 8小时 / 2^((分贝 - 85)/3)
        const allowedTimeSeconds = 8 * 60 * 60 / Math.pow(2, (decibel - 85) / 3);
        
        // 暴露剂量 = 时间间隔 / 允许暴露时间
        const exposureDose = timeInterval / allowedTimeSeconds;
        totalExposureDose += exposureDose;
      }
    }

    // 总暴露百分比 = 总暴露剂量 × 100%
    const exposurePercentage = totalExposureDose * 100;
    return Number(exposurePercentage.toFixed(2));
  }

  /**
   * 声环境标准计算 - 24小时等效声级
   * 专业声学原理：昼夜等效声级 (Ldn)，考虑夜间噪声的额外影响
   * 基于每一刻分贝值的精确计算
   */
  private calculateEnvironmentalExposure(records: DecibelRecord[]): number {
    let dayEnergy = 0;
    let nightEnergy = 0;
    let dayDuration = 0;
    let nightDuration = 0;

    for (const record of records) {
      if (!record.decibelValues || record.decibelValues.length === 0) {
        continue;
      }

      const timestamp = record.timestamp;
      const date = new Date(timestamp);
      const hour = date.getHours();
      
      // 判断白天(6:00-22:00)和夜间(22:00-6:00)
      const isDaytime = hour >= 6 && hour < 22;
      
      const timeInterval = record.duration / record.decibelValues.length;
      
      // 遍历每一个分贝值进行精确计算
      for (const decibel of record.decibelValues) {
        const energy = Math.pow(10, decibel / 10) * timeInterval;
        
        if (isDaytime) {
          dayEnergy += energy;
          dayDuration += timeInterval;
        } else {
          nightEnergy += energy;
          nightDuration += timeInterval;
        }
      }
    }

    // 计算24小时等效声级 Ldn
    // Ldn = 10 * log10[(15/24)*10^(Ld/10) + (9/24)*10^((Ln+10)/10)]
    const totalDuration = dayDuration + nightDuration;
    if (totalDuration === 0) {
      return 0;
    }

    const Ld = dayDuration > 0 ? 10 * Math.log10(dayEnergy / dayDuration) : 0;
    const Ln = nightDuration > 0 ? 10 * Math.log10(nightEnergy / nightDuration) : 0;
    
    // 夜间噪声加10分贝计算
    const Ldn = 10 * Math.log10(
      (15/24) * Math.pow(10, Ld/10) +
      (9/24) * Math.pow(10, (Ln + 10)/10)
    );

    // 修正：声环境标准基于等效声级与标准限值的比较
    // 符合GB 3096-2008标准要求
    const config = StandardConfigs[NoiseExposureStandard.ENVIRONMENTAL];
    const standardLimit = config.baseLimit; // 55dB - 2类功能区昼间标准
    
    // 暴露程度 = (实际声级 - 标准限值) / 标准限值 × 100%
    // 确保结果不小于0
    const exposurePercentage = Math.max(0, (Ldn - standardLimit) / standardLimit * 100);
    
    return Number(exposurePercentage.toFixed(2));
  }

  /**
   * 职业健康标准计算 - 累积暴露风险评估
   * 专业声学原理：基于分贝-时间加权计算的累积暴露量
   * 基于每一刻分贝值的精确计算
   */
  private calculateOccupationalExposure(records: DecibelRecord[]): number {
    let cumulativeExposure = 0;
    let totalDuration = 0;

    for (const record of records) {
      if (!record.decibelValues || record.decibelValues.length === 0) {
        continue;
      }

      const timeInterval = record.duration / record.decibelValues.length;
      
      // 遍历每一个分贝值进行精确计算
      for (const decibel of record.decibelValues) {
        // 累积暴露量 = Σ(10^(分贝/10) × 时间间隔)
        cumulativeExposure += Math.pow(10, decibel / 10) * timeInterval;
        totalDuration += timeInterval;
      }
    }

    if (totalDuration === 0) {
      return 0;
    }

    // 基准暴露量 = 10^(基准限值/10) × 基准时间(秒)
    const config = StandardConfigs[NoiseExposureStandard.OCCUPATIONAL];
    const baseDurationSeconds = config.baseDuration / 1000; // 毫秒转秒
    const baseExposure = Math.pow(10, config.baseLimit / 10) * baseDurationSeconds;

    // 暴露剂量 = 100% × (累积暴露量 / 基准暴露量)
    const exposurePercentage = (cumulativeExposure / baseExposure) * 100;
    
    return Number(exposurePercentage.toFixed(2));
  }

  /**
   * 社会生活标准计算 - 基于等效声级的暴露评估
   * 符合GB 22337-2008标准要求，基于等效声级与标准限值的比较
   * 基于每一刻分贝值的精确计算
   */
  private calculateSocialExposure(records: DecibelRecord[]): number {
    let totalEnergy = 0;
    let totalDuration = 0;

    for (const record of records) {
      if (!record.decibelValues || record.decibelValues.length === 0) {
        continue;
      }

      const timeInterval = record.duration / record.decibelValues.length;
      
      // 遍历每一个分贝值进行精确计算
      for (const decibel of record.decibelValues) {
        const energy = Math.pow(10, decibel / 10) * timeInterval;
        totalEnergy += energy;
        totalDuration += timeInterval;
      }
    }

    if (totalDuration === 0) {
      return 0;
    }

    // 计算等效声级
    const equivalentLevel = 10 * Math.log10(totalEnergy / totalDuration);

    // 修正：社会生活标准基于等效声级与标准限值的比较
    const config = StandardConfigs[NoiseExposureStandard.SOCIAL];
    const standardLimit = config.baseLimit; // 50dB - 生活区域合理标准
    
    // 暴露程度 = (实际声级 - 标准限值) / 标准限值 × 100%
    // 确保结果不小于0
    const exposurePercentage = Math.max(0, (equivalentLevel - standardLimit) / standardLimit * 100);
    
    return Number(exposurePercentage.toFixed(2));
  }

  /**
   * 计算剩余安全时间
   * 基于不同标准的专业计算逻辑
   * 只有基于能量累积的标准才计算剩余时间
   */
  private calculateRemainingSafeTime(exposurePercentage: number, standard: NoiseExposureStandard): string {
    if (exposurePercentage >= 100) {
      return '已超过安全限制';
    }

    // 只有基于能量累积的标准才计算剩余时间
    switch (standard) {
      case NoiseExposureStandard.INDUSTRIAL:
        return this.calculateIndustrialRemainingTime(exposurePercentage, StandardConfigs[standard]);
      case NoiseExposureStandard.OCCUPATIONAL:
        return this.calculateOccupationalRemainingTime(exposurePercentage, StandardConfigs[standard]);
      case NoiseExposureStandard.ENVIRONMENTAL:
      case NoiseExposureStandard.SOCIAL:
        // 环境质量标准不计算剩余安全时间
        return '不适用';
      default:
        return '不适用';
    }
  }

  /**
   * 工业企业标准剩余安全时间计算
   */
  private calculateIndustrialRemainingTime(exposurePercentage: number, config: StandardConfig): string {
    const remainingPercentage = 100 - exposurePercentage;
    const remainingEnergyRatio = remainingPercentage / 100;

    // 基于基准时间的剩余安全时间（分钟）
    const baseDurationMinutes = config.baseDuration / (60 * 1000); // 毫秒转分钟
    const remainingTime = baseDurationMinutes * remainingEnergyRatio;

    return this.formatRemainingTime(remainingTime);
  }


  /**
   * 职业健康标准剩余安全时间计算
   */
  private calculateOccupationalRemainingTime(exposurePercentage: number, config: StandardConfig): string {
    const remainingPercentage = 100 - exposurePercentage;
    const remainingEnergyRatio = remainingPercentage / 100;

    // 基于基准时间的剩余安全时间（分钟）
    const baseDurationMinutes = config.baseDuration / (60 * 1000); // 毫秒转分钟
    const remainingTime = baseDurationMinutes * remainingEnergyRatio;

    return this.formatRemainingTime(remainingTime);
  }


  /**
   * 格式化剩余时间显示
   */
  private formatRemainingTime(remainingTime: number): string {
    if (remainingTime >= 60) {
      const hours = Math.floor(remainingTime / 60);
      const minutes = Math.floor(remainingTime % 60);
      return `${hours}小时${minutes}分钟`;
    } else if (remainingTime > 1) {
      return `${Math.floor(remainingTime)}分钟`;
    } else {
      return '不足1分钟';
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

}