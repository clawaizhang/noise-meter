import { WindowType } from '../common/WindowType';
import { WeightingType } from '../constants/WeightingConstants';
import { FFTAnalyzer } from '../utils/FFTAnalyzer';

@Concurrent
export function concurrentCalculateSpectrum(buffer: ArrayBuffer,
  weightingType: WeightingType, calibrationGain: number, fftSize: number, windowType: WindowType,
  smoothingFactor: number, overlap: number, sampleRate: number = 44100, decimationEnabled: boolean = false,
  decimationFactor: number = 1, kaiserBeta: number = 6.0, gaussianSigma: number = 0.5,
  tukeyAlpha: number = 0.5, chebyshevAttenuation: number = 60.0): Float32Array {
  // 初始化权分析器
  let fftAnalyzer = new FFTAnalyzer(
    fftSize,
    windowType,
    smoothingFactor,
    overlap,
    sampleRate,
    decimationEnabled,
    decimationFactor,
    kaiserBeta,
    gaussianSigma,
    tukeyAlpha,
    chebyshevAttenuation
  );
  // 执行FFT变换并获取频谱数据（transform方法内部已经应用了计权）
  fftAnalyzer.setSystemGain(calibrationGain);
  const spectrum = fftAnalyzer.transform(buffer, weightingType);

  // 直接返回频谱，无需再次应用计权（transform方法已经处理了计权）
  return spectrum;
}