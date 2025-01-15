
@Observed
export class DecibelService {

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