import { WindowType } from '../common/WindowType';
import { WeightingType } from '../constants/WeightingConstants';
import { FFTAnalyzer } from '../utils/FFTAnalyzer';

@Concurrent
export function concurrentCalculateSpectrum(buffer: ArrayBuffer,
  weightingType: WeightingType, calibrationGain: number, fftSize: number, windowType: WindowType,
  smoothingFactor: number, overlap: number): Float32Array {
  // 初始化权分析器
  let fftAnalyzer = new FFTAnalyzer(
    fftSize,
    windowType,
    smoothingFactor,
    overlap
  );
  // 执行FFT变换并获取频谱数据
  fftAnalyzer.setSystemGain(calibrationGain);
  const spectrum = fftAnalyzer.transform(buffer, weightingType);

  // 应用计权
  return fftAnalyzer.applyWeighting(spectrum, weightingType);
}