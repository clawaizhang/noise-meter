/**
 * 分贝计算服务
 * 提供音频数据到分贝值的转换功能
 */
export class DecibelService {
  private readonly REF_VALUE: number = 32767.0;  // 16位音频的最大值
  private readonly MIN_DB: number = -90.0;       // 最小分贝值
  private readonly SMOOTH_FACTOR: number = 0.2;  // 平滑因子
  private lastDecibel: number = 0;               // 上一次的分贝值

  /**
   * 从音频数据计算分贝值
   * @param buffer - 音频数据缓冲区
   * @param bytesRead - 读取的字节数
   * @returns number - 分贝值
   */
  calculateDecibel(buffer: ArrayBuffer, bytesRead: number): number {
    const int16Array = new Int16Array(buffer, 0, bytesRead / 2);
    let sum = 0;
    let maxAbs = 0;
    
    // 计算均方根值和最大绝对值
    for (let i = 0; i < int16Array.length; i++) {
      const value = Math.abs(int16Array[i]);
      sum += value * value;
      maxAbs = Math.max(maxAbs, value);
    }

    // 使用均方根值和最大值的组合
    const rms = Math.sqrt(sum / int16Array.length);
    const combined = Math.max(rms, maxAbs * 0.7);  // 使用RMS和峰值的组合
    
    // 计算分贝值
    let decibel = 20 * Math.log10(combined / this.REF_VALUE);
    
    // 限制最小值
    decibel = Math.max(this.MIN_DB, decibel);
    
    // 应用平滑处理
    decibel = this.lastDecibel + this.SMOOTH_FACTOR * (decibel - this.lastDecibel);
    this.lastDecibel = decibel;

    // 归一化到0-120范围
    decibel = Math.max(0, Math.min(120, decibel + 90));

    console.info(`原始分贝值: ${decibel}, RMS: ${rms}, 最大值: ${maxAbs}`);
    
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
    if (value < 60) return '#4CAF50';  // 安全
    if (value < 90) return '#FFC107';  // 警告
    if (value < 100) return '#FF9800'; // 危险
    return '#F44336';                  // 极度危险
  }
} 