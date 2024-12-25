/**
 * 分贝计算服务
 * 提供音频数据到分贝值的转换功能
 */
export class DecibelService {
  /**
   * 从音频数据计算分贝值
   * @param buffer - 音频数据缓冲区
   * @param bytesRead - 读取的字节数
   * @returns number - 分贝值
   */
  calculateDecibel(buffer: ArrayBuffer, bytesRead: number): number {
    const int16Array = new Int16Array(buffer, 0, bytesRead / 2);
    let sum = 0;
    
    // 计算均方根值
    for (let i = 0; i < int16Array.length; i++) {
      sum += int16Array[i] * int16Array[i];
    }
    const rms = Math.sqrt(sum / int16Array.length);
    
    // 将均方根值转换为分贝值
    // 参考值：16位音频的最大值为32767
    const decibel = 20 * Math.log10(rms / 32767);
    
    return Math.max(0, decibel); // 确保分贝值不为负
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
    if (value < 60) return '#4CAF50';  // 安全
    if (value < 90) return '#FFC107';  // 警告
    if (value < 100) return '#FF9800'; // 危险
    return '#F44336';                  // 极度危险
  }
} 