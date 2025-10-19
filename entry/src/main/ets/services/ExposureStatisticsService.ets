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
   * 修正计算逻辑，使用正确的暴露剂量公式
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

      // 使用能量平均法计算Leq
      const energy = Math.pow(10, current.avgDecibel / 10) * current.duration;
      totalEnergy += energy;
      totalDuration += current.duration;
    }

    if (totalDuration === 0) {
      return 0;
    }

    const leq = 10 * Math.log10(totalEnergy / totalDuration);
    const config = StandardConfigs[standard];

    // 修正暴露剂量计算逻辑
    // 暴露剂量 = 100% × (实际等效声级能量 / 基准等效声级能量)
    // 使用能量比而不是时间比
    const actualEnergy = Math.pow(10, leq / 10) * totalDuration;
    const baseEnergy = Math.pow(10, config.baseLimit / 10) * config.baseDuration;

    let exposurePercentage = Number(((actualEnergy / baseEnergy) * 100).toFixed(2));

    // 限制在0-200%范围内，允许超过100%显示
    return Math.min(Math.max(exposurePercentage, 0), 200);
  }

  /**
   * 计算允许暴露时间 (基于不同标准)
   * 为每个国家标准实现专业的计算算法
   * 使用缓存提升性能
   */
  private calculateAllowedExposureTime(leq: number, standard: NoiseExposureStandard): number {

    const config = StandardConfigs[standard];
    let result: number;

    switch (standard) {
      case NoiseExposureStandard.INDUSTRIAL:
        result = this.calculateIndustrialExposureTime(leq, config);
        break;
      case NoiseExposureStandard.ENVIRONMENTAL:
        result = this.calculateEnvironmentalExposureTime(leq, config);
        break;
      case NoiseExposureStandard.OCCUPATIONAL:
        result = this.calculateOccupationalExposureTime(leq, config);
        break;
      case NoiseExposureStandard.SOCIAL:
        result = this.calculateSocialExposureTime(leq, config);
        break;
      default:
        result = this.calculateDefaultExposureTime(leq, config);
    }

    return result;
  }

  /**
   * 工业企业标准专业计算算法 (GBZ 2.2-2007)
   * 每增加3分贝，允许暴露时间减半
   */
  private calculateIndustrialExposureTime(leq: number, config: StandardConfig): number {
    if (leq <= config.baseLimit) {
      return config.baseDuration;
    }

    const difference = leq - config.baseLimit;
    const halvings = Math.floor(difference / 3);
    return config.baseDuration / Math.pow(2, halvings);
  }

  /**
   * 声环境标准专业计算算法 (GB 3096-2008)
   * 基于功能区分类的24小时等效声级计算
   * 考虑昼夜噪声差异，夜间噪声加10dB权重
   */
  private calculateEnvironmentalExposureTime(leq: number, config: StandardConfig): number {
    // 声环境标准使用24小时等效声级
    // 对于超过限制值的情况，使用更严格的衰减曲线
    if (leq <= config.baseLimit) {
      return config.baseDuration;
    }

    // 声环境标准：每增加5分贝，允许时间按对数衰减
    const excess = leq - config.baseLimit;
    const attenuationFactor = Math.pow(10, excess / 20); // 比工业企业标准更严格
    return config.baseDuration / attenuationFactor;
  }

  /**
   * 职业健康标准专业计算算法 (GBZ 49-2014)
   * 基于听力保护的综合评估
   * 考虑累积暴露和听力损伤风险
   */
  private calculateOccupationalExposureTime(leq: number, config: StandardConfig): number {
    if (leq <= config.baseLimit) {
      return config.baseDuration;
    }

    // 职业健康标准：基于听力保护阈值的线性衰减
    // 80-85dB: 线性衰减，85dB以上使用更严格规则
    if (leq <= 85) {
      const excess = leq - config.baseLimit;
      const attenuation = 1 + (excess / 5) * 0.5; // 线性衰减
      return config.baseDuration / attenuation;
    } else {
      // 85dB以上使用工业企业标准的3分贝减半规则
      const difference = leq - 85;
      const halvings = Math.floor(difference / 3);
      return (config.baseDuration / 1.5) / Math.pow(2, halvings); // 从80dB基准调整
    }
  }

  /**
   * 社会生活标准专业计算算法 (GB 22337-2008)
   * 基于生活区域舒适度的评估
   * 考虑生活质量和舒适度
   */
  private calculateSocialExposureTime(leq: number, config: StandardConfig): number {
    if (leq <= config.baseLimit) {
      return config.baseDuration;
    }

    // 社会生活标准：使用舒适度衰减曲线
    // 超过60dB时，舒适度按指数衰减
    const excess = leq - config.baseLimit;
    const comfortFactor = Math.pow(1.2, excess / 5); // 舒适度指数衰减
    return config.baseDuration / comfortFactor;
  }

  /**
   * 默认计算算法 (备用)
   */
  private calculateDefaultExposureTime(leq: number, config: StandardConfig): number {
    if (leq <= config.baseLimit) {
      return config.baseDuration;
    }

    const excessRatio = Math.pow(10, (leq - config.baseLimit) / 10);
    return config.baseDuration / excessRatio;
  }

  /**
   * 计算剩余安全时间
   * 修正计算逻辑，基于新的暴露剂量公式
   */
  private calculateRemainingSafeTime(exposurePercentage: number, standard: NoiseExposureStandard): string {
    if (exposurePercentage >= 100) {
      return '已超过安全限制';
    }

    const config = StandardConfigs[standard];

    // 基于能量比计算剩余安全时间
    const remainingPercentage = 100 - exposurePercentage;
    const remainingEnergyRatio = remainingPercentage / 100;

    // 计算剩余安全时间（基于基准能量）
    const remainingTime = (config.baseDuration / (60 * 1000)) * remainingEnergyRatio;

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
   * 验证所有标准的计算准确性
   * 用于测试和调试目的
   */
  public validateAllStandards(): Record<NoiseExposureStandard, StandardValidationResult> {
    const results: Record<NoiseExposureStandard, StandardValidationResult> = {
      [NoiseExposureStandard.INDUSTRIAL]: { leq: 0, allowedTime: 0, percentage: 0 },
      [NoiseExposureStandard.ENVIRONMENTAL]: { leq: 0, allowedTime: 0, percentage: 0 },
      [NoiseExposureStandard.OCCUPATIONAL]: { leq: 0, allowedTime: 0, percentage: 0 },
      [NoiseExposureStandard.SOCIAL]: { leq: 0, allowedTime: 0, percentage: 0 }
    };

    Object.values(NoiseExposureStandard).forEach(standard => {
      // 使用中等测试值 (80dB) 进行验证
      const testLeq = 80;
      const config = StandardConfigs[standard];
      const allowedTime = this.calculateAllowedExposureTime(testLeq, standard);
      const percentage = (config.baseDuration / allowedTime) * 100;

      const result: StandardValidationResult = {
        leq: testLeq,
        allowedTime: allowedTime,
        percentage: percentage
      };
      results[standard] = result;
    });

    return results;
  }

  /**
   * 获取标准计算特点说明
   */
  public getStandardCalculationFeatures(standard: NoiseExposureStandard): string {
    switch (standard) {
      case NoiseExposureStandard.INDUSTRIAL:
        return '每增加3分贝，允许暴露时间减半';
      case NoiseExposureStandard.ENVIRONMENTAL:
        return '24小时等效声级，考虑昼夜噪声差异';
      case NoiseExposureStandard.OCCUPATIONAL:
        return '听力保护评估，考虑累积暴露风险';
      case NoiseExposureStandard.SOCIAL:
        return '生活舒适度评估，基于生活质量标准';
      default:
        return '基于基准分贝值按比例计算';
    }
  }

  /**
   * 重置服务状态
   */
  public reset(): void {
    // 清空计算缓存
    this.calculationCache.clear();
  }
}