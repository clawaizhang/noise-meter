import { AudioAnalysisConfig, AudioAnalysisMode, AudioPresets, WindowType } from '../common/AudioConfig';
import { WeightingType } from '../constants/WeightingConstants';
import { FFTAnalyzer } from '../utils/FFTAnalyzer';
import { FFTAnalyzerSessionPool } from '../utils/FFTAnalyzerSessionPool';

// 定义返回类型接口
export interface SpectrumResult {
  spectrum: Float32Array;
  sessionId: string;
}

@Concurrent
export function concurrentCalculateSpectrum(buffer: ArrayBuffer,
  weightingType: WeightingType, calibrationGain: number, fftSize: number, windowType: WindowType,
  smoothingFactor: number, overlap: number): SpectrumResult {
  
  // 使用FFTAnalyzerSessionPool创建会话
  const sessionPool = FFTAnalyzerSessionPool.getInstance();
  const analyzerSession = sessionPool.createSession(fftSize, windowType, smoothingFactor, overlap);
  const analyzer = analyzerSession.analyzer;
  const sessionId = analyzerSession.sessionId;

  try {
    // 执行FFT变换并获取频谱数据
    analyzer.setSystemGain(calibrationGain);
    const spectrum = analyzer.transform(buffer, weightingType);

    // 应用计权
    const weightedSpectrum = analyzer.applyWeighting(spectrum, weightingType);
    
    return {
      spectrum: weightedSpectrum,
      sessionId
    };
  } catch (error) {
    // 发生错误时释放会话
    sessionPool.releaseSession(sessionId);
    throw new Error(`Error calculating spectrum: ${error}`);
  }
}