import { AudioPresets, AudioAnalysisMode } from '../../../library/ets/common/AudioConfig';
import { WeightingType } from '../../../library/ets/constants/WeightingConstants';
import { FFTAnalyzer } from '../../../library/ets/utils/FFTAnalyzer';

@Concurrent
export function concurrentCalculateSpectrum(savedMode: string, buffer: ArrayBuffer,
  weightingType: WeightingType,calibrationGain:number): Float32Array {
  console.info(`[频谱分析] 开始处理音频数据: 数据大小=${buffer.byteLength}字节`);
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
  console.info(`[频谱分析] FFT变换完成: 频谱长度=${spectrum.length}`);
  console.info(`[频谱分析] 原始频谱样本: ${spectrum[0]}, ${spectrum[1]}, ${spectrum[2]}, ${spectrum[3]}, ${spectrum[4]}`);

  // 应用计权
  const weightedSpectrum = fftAnalyzer.applyWeighting(spectrum, weightingType);
  console.info(`[频谱分析] 计权后频谱样本: ${weightedSpectrum[0]}, ${weightedSpectrum[1]}, ${weightedSpectrum[2]}, ${weightedSpectrum[3]}, ${weightedSpectrum[4]}`);

  const filteredSpectrum = new Float32Array(weightedSpectrum.length);
  for (let i = 0; i < weightedSpectrum.length; i++) {
    filteredSpectrum[i] = weightedSpectrum[i];
  }
  return filteredSpectrum;
}