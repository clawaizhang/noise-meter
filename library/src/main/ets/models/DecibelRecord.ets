/**
 * 噪音检测历史记录
 */
export class DecibelRecord {
  id: string;  // 记录ID
  timestamp: number;  // 记录时间戳
  minDecibel: number;  // 最小分贝值
  maxDecibel: number;  // 最大分贝值
  avgDecibel: number;  // 平均分贝值
  duration: number;  // 检测持续时间（毫秒）
  location?: string;  // 检测位置（可选）
  values: number[];  // 每次检测的分贝值数组

  constructor(
    minDecibel: number,
    maxDecibel: number,
    avgDecibel: number,
    duration: number,
    values: number[],
    location?: string
  ) {
    this.id = new Date().getTime().toString();
    this.timestamp = new Date().getTime();
    this.minDecibel = minDecibel;
    this.maxDecibel = maxDecibel;
    this.avgDecibel = avgDecibel;
    this.duration = duration;
    this.values = values;
    this.location = location;
  }
} 