import { DecibelStatistics } from '../../core/interfaces/IAudioService';

/**
 * 频率计权类型
 */
export enum WeightingType {
  A = 'A',  // A计权 - 模拟人耳感知
  C = 'C',  // C计权 - 适合高峰值
  Z = 'Z'   // Z计权 - 平坦响应
}

/**
 * A计权滤波器系数
 */
class AWeightingCoeffs {
  b0: number = 0.25574113;
  b1: number = -0.51148225;
  b2: number = 0.25574113;
  a1: number = -1.73490888;
  a2: number = 0.76600649;
}

/**
 * 滤波器状态
 */
class FilterState {
  x1: number = 0;
  x2: number = 0;
  y1: number = 0;
  y2: number = 0;
}

/**
 * 分贝计算器 - 支持频率计权
 */
export class DecibelCalculator {
  private static coeffs: AWeightingCoeffs = new AWeightingCoeffs();
  private static filterState: FilterState = new FilterState();

  /**
   * 重置滤波器状态
   */
  static resetFilter(): void {
    DecibelCalculator.filterState = new FilterState();
  }

  /**
   * A计权滤波 - 单样本处理
   * 使用双二阶IIR滤波器模拟A计权曲线
   */
  private static applyAWeighting(sample: number): number {
    const state: FilterState = DecibelCalculator.filterState;
    const c: AWeightingCoeffs = DecibelCalculator.coeffs;
    
    // 差分方程: y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]
    const y: number = c.b0 * sample + c.b1 * state.x1 + c.b2 * state.x2 - c.a1 * state.y1 - c.a2 * state.y2;
    
    // 更新状态
    state.x2 = state.x1;
    state.x1 = sample;
    state.y2 = state.y1;
    state.y1 = y;
    
    return y;
  }

  /**
   * 计算分贝 - 支持频率计权
   * @param buffer PCM音频数据
   * @param size 数据大小
   * @param calibration 校准值
   * @param weighting 频率计权类型
   */
  static calculate(
    buffer: ArrayBuffer, 
    size: number, 
    calibration: number,
    weighting: WeightingType
  ): number {
    const dataView: DataView = new DataView(buffer);
    const samples: number = size / 2;
    let sum: number = 0;
    
    for (let i: number = 0; i < samples; i++) {
      // 读取16位PCM样本并归一化到 [-1, 1]
      const rawSample: number = dataView.getInt16(i * 2, true) / 32768;
      
      // 应用频率计权
      let weightedSample: number;
      if (weighting === WeightingType.A) {
        weightedSample = DecibelCalculator.applyAWeighting(rawSample);
      } else if (weighting === WeightingType.C) {
        // C计权：轻微低频衰减（简化处理，用增益补偿）
        weightedSample = rawSample * 1.02;
      } else {
        weightedSample = rawSample;
      }
      
      sum = sum + weightedSample * weightedSample;
    }

    // 计算RMS
    const rms: number = Math.sqrt(sum / samples);
    
    // 转换为分贝
    // 参考声压级 94dB 对应满量程 RMS
    let db: number = 20 * Math.log10(rms + 1e-10) + 94;
    
    // A计权需要额外补偿（滤波器衰减）
    if (weighting === WeightingType.A) {
      db = db + 2.0;
    }
    
    // 应用校准值
    db = db + calibration;
    
    // 限制范围并返回整数
    if (db < 30) {
      return 30;
    }
    return Math.round(db);
  }

  /**
   * 批量计算统计信息
   */
  static calculateStats(readings: number[]): DecibelStatistics {
    if (readings.length === 0) {
      return { min: 0, avg: 0, max: 0 };
    }
    const min: number = Math.min(...readings);
    const max: number = Math.max(...readings);
    const avg: number = readings.reduce((a: number, b: number) => a + b, 0) / readings.length;
    return { min: Math.round(min), avg: Math.round(avg), max: Math.round(max) };
  }
  
  /**
   * 计算LEQ（等效连续声级）- 更准确的平均方法
   * 使用能量平均而非算术平均
   */
  static calculateLeq(readings: number[]): number {
    if (readings.length === 0) {
      return 0;
    }
    
    // 将dB转回能量域求平均
    let energySum: number = 0;
    for (let i: number = 0; i < readings.length; i++) {
      energySum = energySum + Math.pow(10, readings[i] / 10);
    }
    
    // 转回dB
    const avgEnergy: number = energySum / readings.length;
    return Math.round(10 * Math.log10(avgEnergy));
  }

  /**
   * 获取计权类型显示名称
   */
  static getWeightingDisplayName(weighting: WeightingType): string {
    if (weighting === WeightingType.A) {
      return 'A';
    } else if (weighting === WeightingType.C) {
      return 'C';
    } else {
      return 'Z';
    }
  }
  
  /**
   * 获取计权类型描述
   */
  static getWeightingDescription(weighting: WeightingType): string {
    if (weighting === WeightingType.A) {
      return 'A计权 - 模拟人耳感知';
    } else if (weighting === WeightingType.C) {
      return 'C计权 - 适合峰值噪音';
    } else {
      return 'Z计权 - 平坦频率响应';
    }
  }
}

/**
 * 噪音等级信息
 */
export interface NoiseLevelInfo {
  description: string;
  color: string;
}

/**
 * 噪音等级辅助类
 */
export class NoiseLevelHelper {
  static getLevelInfo(decibel: number): NoiseLevelInfo {
    if (decibel < 40) {
      return { description: '安静', color: '#4CAF50' };
    } else if (decibel < 60) {
      return { description: '正常', color: '#8BC34A' };
    } else if (decibel < 80) {
      return { description: '吵闹', color: '#FFC107' };
    } else if (decibel < 100) {
      return { description: '危险', color: '#FF9800' };
    } else {
      return { description: '极危险', color: '#F44336' };
    }
  }

  static checkThreshold(decibel: number, threshold: number, isCurrentlyAlert: boolean): boolean {
    // 添加5dB的滞后，避免在阈值附近频繁触发
    if (isCurrentlyAlert) {
      return decibel >= threshold - 5;
    } else {
      return decibel >= threshold;
    }
  }
  
  /**
   * 获取健康建议
   */
  static getHealthAdvice(decibel: number): string {
    if (decibel < 80) {
      return '长期处于此环境安全';
    } else if (decibel < 85) {
      return '每天不宜超过5.5小时';
    } else if (decibel < 90) {
      return '每天不宜超过1.75小时';
    } else if (decibel < 95) {
      return '每天不宜超过30分钟';
    } else if (decibel < 100) {
      return '每天不宜超过10分钟';
    } else {
      return '避免长时间暴露，建议佩戴防护';
    }
  }
}
