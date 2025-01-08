import { PreferenceService } from '../../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';
import { WeightingType } from '../../../library/ets/constants/WeightingConstants';
import { FrequencyWeighting } from '../../../library/ets/utils/FrequencyWeighting';

@Observed
export class DecibelService {
  private readonly REF_VALUE: number = 32767.0;
  private readonly SMOOTH_FACTOR: number = 0.1;
  private lastDecibel: number = 0;
  private readonly preferenceService: PreferenceService = PreferenceService.getInstance();

  /**
   * 计算分贝值
   * @param buffer 音频数据
   * @param bytesRead 读取的字节数
   * @returns 分贝值
   */
  public calculateDecibel(buffer: ArrayBuffer, bytesRead: number): number {
    // 获取当前的计权类型
    const weightingType = this.preferenceService.getString(PreferenceKeyConstants.WEIGHTING, WeightingType.A) as WeightingType;
    
    // 使用频率计权计算
    let decibel = FrequencyWeighting.calculateWeightedDecibel(buffer, bytesRead, weightingType);
    
    // 应用平滑处理
    decibel = this.lastDecibel + this.SMOOTH_FACTOR * (decibel - this.lastDecibel);
    this.lastDecibel = decibel;
    
    // 限制分贝值范围在合理区间内
    return Math.max(0, Math.min(130, decibel));
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