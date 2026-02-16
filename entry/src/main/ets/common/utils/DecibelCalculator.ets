import { DecibelStatistics } from '../../core/interfaces/IAudioService';

/**
 * 分贝计算器 - 通用工具
 */
export class DecibelCalculator {
  static calculate(buffer: ArrayBuffer, size: number, calibration: number = 0): number {
    const dataView = new DataView(buffer);
    const samples = size / 2;
    let sum = 0;
    
    for (let i = 0; i < samples; i++) {
      const sample = dataView.getInt16(i * 2, true) / 32768;
      sum += sample * sample;
    }

    const rms = Math.sqrt(sum / samples);
    let db = 20 * Math.log10(rms + 1e-10) + 94;
    db += calibration;
    
    return db < 30 ? 30 : Math.round(db);
  }

  static calculateStats(readings: number[]): DecibelStatistics {
    if (readings.length === 0) {
      return { min: 0, avg: 0, max: 0 };
    }
    const min = Math.min(...readings);
    const max = Math.max(...readings);
    const avg = readings.reduce((a, b) => a + b, 0) / readings.length;
    return { min: Math.round(min), avg: Math.round(avg), max: Math.round(max) };
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
    if (isCurrentlyAlert) {
      return decibel >= threshold - 5;
    } else {
      return decibel >= threshold;
    }
  }
}
