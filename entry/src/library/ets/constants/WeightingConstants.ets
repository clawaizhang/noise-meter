/**
 * 分贝计权类型
 */
export enum WeightingType {
  A = 'A',
  C = 'C',
  Z = 'Z'
}

/**
 * 获取分贝计权描述
 * @param type 计权类型
 */
export function getWeightingDescription(type: WeightingType): string {
  switch (type) {
    case WeightingType.A:
      return '模拟人耳对声音的感知,适合评估环境噪声';
    case WeightingType.C:
      return '对低频响应更好,适合评估高声压级噪声';
    case WeightingType.Z:
      return '零频率计权,适合声学分析和研究';
    default:
      return '';
  }
} 