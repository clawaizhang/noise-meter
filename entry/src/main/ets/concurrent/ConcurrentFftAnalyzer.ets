import { AudioAnalysisMode, AudioPresets, WindowType } from '../common/AudioConfig';
import { WeightingType } from '../constants/WeightingConstants';
import { FFTAnalyzer } from '../utils/FFTAnalyzer';

@Concurrent
export function concurrentCalculateSpectrum(savedMode: string, buffer: ArrayBuffer,
  weightingType: WeightingType, calibrationGain: number): Float32Array {
  // 初始化权分析器
  const config = AudioPresets.getConfig(savedMode as AudioAnalysisMode);
  let fftAnalyzer = new FFTAnalyzer(
    config.fftSize,
    config.windowType,
    config.smoothingFactor,
    config.overlap
  );

  // 执行FFT变换并获取频谱数据
  fftAnalyzer.setSystemGain(calibrationGain);
  const spectrum = fftAnalyzer.transform(buffer, weightingType);

  // 应用计权
  return fftAnalyzer.applyWeighting(spectrum, weightingType);
}