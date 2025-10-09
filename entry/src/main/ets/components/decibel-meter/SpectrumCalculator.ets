import { SpectrumProcessResult, PathPoint } from './SpectrumTypes';


/**
 * 处理频谱数据并计算绘制坐标
 * @param rawSpectrum 原始频谱数据
 * @param canvasWidth 画布宽度
 * @param canvasHeight 画布高度
 * @param dbSteps 分贝步进值
 * @param frequencySteps 频率步进值
 * @param fftSize FFT大小
 * @param sampleRate 采样率
 * @returns 频谱处理结果
 */
@Concurrent
export function spectrumCalculatorProcess(
  rawSpectrum: Float32Array,
  canvasWidth: number,
  canvasHeight: number,
  dbSteps: number[],
  frequencySteps: number[],
  fftSize: number,
  sampleRate: number
): SpectrumProcessResult {
  console.info(`[频谱计算] 开始处理频谱数据，长度=${rawSpectrum.length}`);

  // 计算分贝范围
  const minDb: number = dbSteps[0];
  const maxDb: number = dbSteps[dbSteps.length - 1];
  const dbRange: number = maxDb - minDb;

  // 计算频率范围（对数坐标）
  const frequencyHigh: number = frequencySteps[frequencySteps.length - 1];
  const logMin: number = Math.log10(16);
  const logMax: number = Math.log10(frequencyHigh);
  const logRange: number = logMax - logMin;

  // 初始化变量
  const pathPoints: PathPoint[] = [];
  let maxValue: number = -Infinity;
  let peakFrequency: number = 0;
  let peakX: number = 0;
  let peakY: number = 0;

  // 标记是否找到第一个有效点
  let isFirstValidPoint: boolean = true;
  let lastX: number | null = null;
  let lastY: number | null = null;

  // 处理每个频率点
  for (let i = 0; i < fftSize; i++) {
    const centerFreq: number = (i * sampleRate) / (2 * fftSize);

    // 只显示16Hz以上的范围
    if (centerFreq < 16) {
      continue;
    }

    // 安全检查
    if (!rawSpectrum || i >= rawSpectrum.length) {
      continue;
    }

    // 计算对数坐标
    const logFreq: number = Math.log10(centerFreq);
    const x: number = ((logFreq - logMin) / logRange) * canvasWidth;

    // 计算Y坐标
    const value: number = Math.max(minDb, Math.min(maxDb, rawSpectrum[i]));
    const normalizedValue: number = (value - minDb) / dbRange;
    const y: number = canvasHeight * (1 - normalizedValue);

    // 检测峰值
    const absValue: number = Math.abs(rawSpectrum[i]);
    if (absValue > maxValue) {
      maxValue = absValue;
      peakFrequency = centerFreq;
      peakX = x;
      peakY = y;
    }

    // 转换为整数坐标
    const intX: number = Math.round(x);
    const intY: number = Math.round(y);

    // 检查是否为重复点
    const isDuplicatePoint: boolean = lastX !== null && lastY !== null &&
      intX === lastX && intY === lastY;

    // 只在找到第一个有效点或非重复点时添加
    if (isFirstValidPoint || !isDuplicatePoint) {
      pathPoints.push({ x, y });

      if (isFirstValidPoint) {
        isFirstValidPoint = false;
      }

      // 更新最后一个绘制点的坐标
      lastX = intX;
      lastY = intY;
    }
  }

  console.info(`[频谱计算] 处理完成: 路径点=${pathPoints.length}, 峰值频率=${peakFrequency.toFixed(1)}Hz`);

  const result: SpectrumProcessResult = {
    pathPoints,
    peakFrequency,
    peakValue: maxValue,
    peakX,
    peakY
  };

  return result;
}
