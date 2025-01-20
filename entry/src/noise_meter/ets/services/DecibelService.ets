export interface NoiseLevel {
  range: string;
  level: string;
  color: string;
  description: string;
}

@Observed
export class DecibelService {
  public getNoiseLevels(): NoiseLevel[] {
    return [
      {
        range: '100+ dB',
        level: this.getDecibelLevel(110),
        color: this.getDecibelColor(110),
        description: this.getDecibelDescription(110)
      },
      {
        range: '80-100 dB',
        level: this.getDecibelLevel(90),
        color: this.getDecibelColor(90),
        description: this.getDecibelDescription(90)
      },
      {
        range: '60-80 dB',
        level: this.getDecibelLevel(70),
        color: this.getDecibelColor(70),
        description: this.getDecibelDescription(70)
      },
      {
        range: '40-60 dB',
        level: this.getDecibelLevel(50),
        color: this.getDecibelColor(50),
        description: this.getDecibelDescription(50)
      },
      {
        range: '20-40 dB',
        level: this.getDecibelLevel(30),
        color: this.getDecibelColor(30),
        description: this.getDecibelDescription(30)
      },
      {
        range: '0-20 dB',
        level: this.getDecibelLevel(10),
        color: this.getDecibelColor(10),
        description: this.getDecibelDescription(10)
      }
    ];
  }

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

  /**
   * 获取分贝值对应的具体描述
   * @param value - 分贝值
   * @returns string - 具体描述
   */
  getDecibelDescription(value: number): string {
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
}