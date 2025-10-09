/**
 * 频谱处理结果接口
 */
export interface SpectrumProcessResult {
  pathPoints: PathPoint[];           // 频谱线坐标点数组
  peakFrequency: number;             // 峰值频率（Hz）
  peakValue: number;                 // 峰值分贝值
  peakX: number;                     // 峰值X坐标
  peakY: number;                     // 峰值Y坐标
}

/**
 * 坐标点接口
 */
export interface PathPoint {
  x: number;                         // X坐标
  y: number;                         // Y坐标
}

/**
 * 坐标映射接口
 */
export interface CoordinateMapping {
  frequency: number;                 // 频率值（Hz）
  x: number;                         // X坐标
  y: number;                         // Y坐标
  value: number;                     // 分贝值
}

/**
 * 频谱统计信息接口
 */
export interface SpectrumStats {
  maxDb: number;                     // 最大分贝值
  minDb: number;                     // 最小分贝值
  avgDb: number;                     // 平均分贝值
  peakFreq: number;                  // 峰值频率
  validSamples: number;              // 有效样本数
  totalSamples: number;              // 总样本数
}