/**
 * 窗函数类型
 */
export enum WindowType {
  HANNING = 'HANNING', // 汉宁窗
  BLACKMAN = 'BLACKMAN', // 布莱克曼窗
  HAMMING = 'HAMMING', // 汉明窗
  BARTLETT = 'BARTLETT', // 巴特利特窗
  KAISER = 'KAISER', // 凯泽窗
  FLATTOP = 'FLATTOP', // 平顶窗
  TRIANGULAR = 'TRIANGULAR', // 三角窗
  WELCH = 'WELCH', // 韦尔奇窗
  SINE = 'SINE', // 正弦窗
  GAUSSIAN = 'GAUSSIAN', // 高斯窗
  TUKEY = 'TUKEY', // 图基窗
  CHEBYSHEV = 'CHEBYSHEV' // 切比雪夫窗
}
