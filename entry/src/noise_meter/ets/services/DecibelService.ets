@Observed
export class DecibelService {

  /**
   * 获取分贝级别描述
   * @param value - 分贝值
   * @returns string - 级别描述
   */
  getDecibelLevel(value: number): string {
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
  getDecibelColor(value: number): string {
    if (value < 20) return '#3EA665';  // 非常安静 - 绿色
    if (value < 40) return '#4CAF50';  // 安静 - 浅绿色
    if (value < 60) return '#FFC107';  // 一般 - 黄色
    if (value < 80) return '#FF9800';  // 吵闹 - 橙色
    if (value < 100) return '#F44336'; // 非常吵闹 - 红色
    return '#8B0000';                 // 难以忍受 - 深红色
  }
}