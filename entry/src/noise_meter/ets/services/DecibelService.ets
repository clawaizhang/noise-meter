import { BasicStats, HealthStats } from "../types/NoiseStats";

export interface NoiseLevel {
  range: string;
  level: string;
  color: string;
  description: string;
}

export interface NoiseLevelDescription {
  minDecibel: number;
  maxDecibel: number;
  basicDescription: string;
  detailedDescription: string;
}

@Observed
export class DecibelService {
  static leqData: number[] = []

  /**
   * 计算Leq值
   * @param samples - 采样数据数组
   * @returns number - 计算得到的Leq值
   */
  static calculateLeq(samples: number[]): number {
    if (samples.length === 0) return 0
    const sum = samples.reduce((a, v) => a + v ** 2, 0)
    return 10 * Math.log10(sum / samples.length)
  }

  public static getNoiseLevels(): NoiseLevel[] {
    return [
      {
        range: '100+ dB',
        level: DecibelService.getDecibelLevel(110),
        color: DecibelService.getDecibelColor(110),
        description: DecibelService.getDecibelDescription(110)
      },
      {
        range: '80-100 dB',
        level: DecibelService.getDecibelLevel(90),
        color: DecibelService.getDecibelColor(90),
        description: DecibelService.getDecibelDescription(90)
      },
      {
        range: '60-80 dB',
        level: DecibelService.getDecibelLevel(70),
        color: DecibelService.getDecibelColor(70),
        description: DecibelService.getDecibelDescription(70)
      },
      {
        range: '40-60 dB',
        level: DecibelService.getDecibelLevel(50),
        color: DecibelService.getDecibelColor(50),
        description: DecibelService.getDecibelDescription(50)
      },
      {
        range: '20-40 dB',
        level: DecibelService.getDecibelLevel(30),
        color: DecibelService.getDecibelColor(30),
        description: DecibelService.getDecibelDescription(30)
      },
      {
        range: '0-20 dB',
        level: DecibelService.getDecibelLevel(10),
        color: DecibelService.getDecibelColor(10),
        description: DecibelService.getDecibelDescription(10)
      }
    ];
  }

  /**
   * 获取分贝级别描述
   * @param value - 分贝值
   * @returns string - 级别描述
   */
  static getDecibelLevel(value: number): string {
    if (value < 20) return '非常安静';
    if (value < 40) return '安静';
    if (value < 60) return '一般';
    if (value < 80) return '吵闹';
    if (value < 100) return '非常吵闹';
    return '难以忍受';
  }

  /**
   * 获取分贝值对应的颜色
   * @param value - 分贝值
   * @returns string - 颜色值（十六进制）
   */
  static getDecibelColor(value: number): string {
    if (value < 20) return '#3EA665';  // 非常安静 - 绿色
    if (value < 40) return '#4CAF50';  // 安静 - 浅绿色
    if (value < 60) return '#FFC107';  // 一般 - 黄色
    if (value < 80) return '#FF9800';  // 吵闹 - 橙色
    if (value < 100) return '#F44336'; // 非常吵闹 - 红色
    return '#8B0000';                 // 难以忍受 - 深红色
  }

  /**
   * 获取分贝值对应的具体描述
   * @param value - 分贝值
   * @returns string - 具体描述
   */
  static getDecibelDescription(value: number): string {
    if (value < 10) return '几乎无声';
    if (value < 20) return '安静的录音室';
    if (value < 30) return '耳语声';
    if (value < 40) return '安静的图书馆';
    if (value < 50) return '安静的办公室';
    if (value < 60) return '普通对话';
    if (value < 70) return '繁忙的餐厅';
    if (value < 80) return '繁忙的街道';
    if (value < 90) return '重型卡车';
    if (value < 100) return '地铁列车';
    if (value < 110) return '摇滚音乐会';
    return '喷气发动机';
  }

  static getDetailedDecibelDescription(value: number): string {
    if (value < 10) return '人类听觉阈值下限，几乎完全无声的环境，如隔音室或太空舱内';
    if (value < 20) return '极其安静的环境，适合录制高质量音频，如专业录音棚';
    if (value < 30) return '适合私人交谈的安静环境，如深夜的卧室或图书馆的安静角落';
    if (value < 40) return '适合专注学习的安静环境，如图书馆或安静的办公室';
    if (value < 50) return '适合日常工作的环境，如普通办公室或安静的咖啡厅';
    if (value < 60) return '正常交流音量，如普通对话或小型会议';
    if (value < 70) return '可能影响交流的嘈杂环境，如繁忙的餐厅或商场';
    if (value < 80) return '长期暴露可能影响听力的环境，如繁忙的城市街道或地铁站';
    if (value < 90) return '需要采取听力保护措施的环境，如建筑工地或重型机械附近';
    if (value < 100) return '短期暴露即可能损伤听力的环境，如地铁列车内部或摇滚音乐会前排';
    if (value < 110) return '需要专业听力保护的环境，如飞机引擎附近或大型演唱会现场';
    return '立即损伤听力的危险水平，如喷气发动机附近或爆炸现场';
  }

  /**
   * 获取健康统计数据
   */
  static async getHealthStats(): Promise<HealthStats> {
    const leqValues = DecibelService.leqData;
    const dailyDose = DecibelService.calculateDailyDose(leqValues);
    const weeklyAvg = DecibelService.calculateWeeklyAverage(leqValues);
    const peakEvents = DecibelService.countPeakEvents(leqValues);

    return {
      dailyDose,
      weeklyAvg,
      peakEvents
    };
  }

  private static calculateDailyDose(leqValues: number[]): number {
    if (leqValues.length === 0) return 0;
    const avgLeq = leqValues.reduce((a, b) => a + b, 0) / leqValues.length;
    return Math.min(avgLeq / 85 * 100, 100); // 85dB为安全阈值
  }

  private static calculateWeeklyAverage(leqValues: number[]): number {
    if (leqValues.length === 0) return 0;
    return leqValues.reduce((a, b) => a + b, 0) / leqValues.length;
  }

  private static countPeakEvents(leqValues: number[]): number {
    return leqValues.filter(v => v > 85).length;
  }

  /**
   * 获取基础声学统计数据
   */
  static async getBasicStats(): Promise<BasicStats> {
    const leqValues = DecibelService.leqData;
    const stats: BasicStats = {
      leq: DecibelService.calculateLeq(leqValues),
      lmax: Math.max(...leqValues),
      lmin: Math.min(...leqValues),
      l10: DecibelService.calculatePercentile(leqValues, 0.1),
      l50: DecibelService.calculatePercentile(leqValues, 0.5),
      l90: DecibelService.calculatePercentile(leqValues, 0.9),
      lpeak: undefined
    };

    return stats;
  }

  private static calculatePercentile(values: number[], percentile: number): number {
    if (values.length === 0) return 0;
    const sorted = [...values].sort((a, b) => a - b);
    const index = Math.floor(sorted.length * percentile);
    return sorted[index];
  }
}