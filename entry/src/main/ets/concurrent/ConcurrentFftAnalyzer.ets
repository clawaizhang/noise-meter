import { WindowType } from '../common/WindowType';
import { WeightingType } from '../constants/WeightingConstants';
import { FFTAnalyzer } from '../utils/FFTAnalyzer';
import { SpectrumSmoothingManager } from '../utils/SpectrumSmoothingManager';

@Concurrent
export function concurrentCalculateSpectrum(buffer: ArrayBuffer,
  weightingType: WeightingType, calibrationGain: number, fftSize: number, windowType: WindowType,
  smoothingFactor: number, overlap: number, sampleRate: number = 44100, decimationEnabled: boolean = false,
  decimationFactor: number = 1, kaiserBeta: number = 6.0, gaussianSigma: number = 0.5,
  tukeyAlpha: number = 0.5, chebyshevAttenuation: number = 60.0, exponentialSmoothingFactor: number = 0.3): Float32Array {
  // 获取全局平滑管理器实例
  const smoothingManager = SpectrumSmoothingManager.getInstance();
  
  // 初始化FFT分析器（用于基础FFT计算，不使用内部平滑）
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
    chebyshevAttenuation,
    exponentialSmoothingFactor
  );
  
  // 执行FFT变换并获取频谱数据（transform方法内部已经应用了计权）
  fftAnalyzer.setSystemGain(calibrationGain);
  const rawSpectrum = fftAnalyzer.transform(buffer, weightingType);

  // 不再在此处应用平滑处理，由调用方（AudioController）统一进行平滑处理
  // 这避免了重复平滑的问题
  
  return rawSpectrum;
}