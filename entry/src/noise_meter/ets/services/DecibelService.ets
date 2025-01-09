import { PreferenceService } from '../../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';
import { WeightingType } from '../../../library/ets/constants/WeightingConstants';
import { FrequencyWeighting } from '../../../library/ets/utils/FrequencyWeighting';

@Observed
export class DecibelService {
  private readonly REF_VALUE: number = 32767.0;
  private readonly preferenceService: PreferenceService = PreferenceService.getInstance();

  /**
   * 计算分贝值
   * @param buffer 音频数据
   * @param bytesRead 读取的字节数
   * @returns 分贝值
   */
  public calculateDecibel(buffer: ArrayBuffer, bytesRead: number): number {
    console.debug('[DecibelService] 开始计算分贝值, 数据长度:', bytesRead);
    // 获取当前的计权类型
    const weightingType = this.preferenceService.getString(PreferenceKeyConstants.WEIGHTING, WeightingType.A) as WeightingType;
    console.debug('[DecibelService] 当前计权类型:', weightingType);
    
    // 使用频率计权计算
    const decibel = FrequencyWeighting.calculateWeightedDecibel(buffer, bytesRead, weightingType);
    console.debug('[DecibelService] 计算得到分贝值:', decibel);
    
    // 限制分贝值范围在合理区间内
    const result = Math.max(0, Math.min(130, decibel));
    console.debug('[DecibelService] 限制后的分贝值:', result);
    return result;
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