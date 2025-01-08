import { PreferenceService } from '../../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';
import { WeightingType } from '../../../library/ets/constants/WeightingConstants';
import { FrequencyWeighting } from '../../../library/ets/utils/FrequencyWeighting';

/**
 * 分贝计算服务
 * 提供音频数据到分贝值的转换功能
 */
export class DecibelService {
  private readonly MIN_DB: number = -90.0;       // 最小分贝值
  private readonly SMOOTH_FACTOR: number = 0.6;  // 平滑因子，增大以减少衰减
  private lastDecibel: number = 0;               // 上一次的分贝值
  private preferenceService: PreferenceService = PreferenceService.getInstance();

  /**
   * 从音频数据计算分贝值
   * @param buffer - 音频数据缓冲区
   * @param bytesRead - 读取的字节数
   * @returns number - 分贝值
   */
  calculateDecibel(buffer: ArrayBuffer, bytesRead: number): number {
    // 获取当前的计权类型
    const weightingType = this.preferenceService.getString(PreferenceKeyConstants.WEIGHTING, WeightingType.A);

    // 使用频率计权工具计算分贝值
    let decibel = FrequencyWeighting.calculateWeightedDecibel(buffer, bytesRead, weightingType as WeightingType);
    
    // 限制最小值
    decibel = Math.max(this.MIN_DB, decibel);
    
    // 应用平滑处理
    if (Math.abs(decibel - this.lastDecibel) > 10) {
      // 如果变化太大，快速响应
      this.lastDecibel = decibel;
    } else {
      // 正常平滑处理
      this.lastDecibel = this.lastDecibel + this.SMOOTH_FACTOR * (decibel - this.lastDecibel);
    }
    decibel = this.lastDecibel;

    // 归一化到0-120范围
    decibel = Math.max(0, Math.min(120, decibel + 90));

    console.info(`计权类型: ${weightingType}, 分贝值: ${decibel}`);
    
    return Math.round(decibel);
  }

  /**
   * 获取分贝级别描述
   * @param value - 分贝值
   * @returns string - 级别描述
   */
  getDecibelLevel(value: number): string {
    if (value < 30) return '安静';
    if (value < 60) return '正常';
    if (value < 90) return '嘈杂';
    if (value < 100) return '危险';
    return '极度危险';
  }

  /**
   * 获取分贝值对应的颜色
   * @param value - 分贝值
   * @returns string - 颜色值（十六进制）
   */
  getDecibelColor(value: number): string {
    if (value < 30) return '#3EA665';  // 安静 - 更亮的绿色
    if (value < 60) return '#4CAF50';  // 正常 - 绿色
    if (value < 90) return '#FFC107';  // 嘈杂 - 黄色
    if (value < 100) return '#FF9800'; // 危险 - 橙色
    return '#F44336';                  // 极度危险 - 红色
  }
} 