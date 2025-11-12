import { WindowType } from '../common/WindowType';
import { WeightingType } from '../constants/WeightingConstants';
import { WindowFunctionCache } from './WindowFunctionCache';

/**
 * 复数类型接口
 */
interface ComplexNumber {
  real: number;
  imag: number;
}

// 信号统计信息接口
interface SignalStats {
  maxAmp: number;
  minAmp: number;
  rms: number;
  isValid: boolean;
}

// 频谱统计信息接口
interface SpectrumStats {
  maxDb: number;
  minDb: number;
  avgDb: number;
  peakFreq: number;
  validSamples: number;
  totalSamples: number;
}

export class FFTAnalyzer {
  private readonly size: number;
  private readonly window: Float32Array;
  private sampleRate: number = 44100;
  private readonly REF_VALUE: number = 32767.0; // 16位音频的最大值
  private readonly MIN_DB: number = -120.0; // 最小分贝值
  private readonly REF_POWER: number = 2e-5; // 参考声压，20μPa
  private readonly smoothingFactor: number; // 平滑因子
  private readonly DEBUG: boolean = true; // 调试开关
  private readonly windowType: WindowType; // 窗函数类型
  private readonly overlap: number; // 重叠率
  private readonly WINDOW_CORRECTION: number; // 窗函数能量校正因子
  private readonly MIC_SENSITIVITY: number = -25; // 典型的手机麦克风灵敏度（dBV/Pa）
  private systemGain: number = 0; // 系统增益校正（dB）
  private decimationEnabled: boolean = false; // 是否启用降采样
  private decimationFactor: number = 1; // 降采样因子

  /**
   * 设置系统增益
   * @param gain 增益值（dB）
   */
  public setSystemGain(gain: number): void {
    this.systemGain = gain;
    if (this.DEBUG) {
      console.info(`系统增益已更新为: ${gain}dB`);
    }
  }

  // 缓存数组
  private cachedSamples: Int16Array | null = null;
  private cachedReal: Float32Array | null = null;
  private cachedImag: Float32Array | null = null;
  private previousMagnitudes: Float32Array | null = null;
  private cachedCosSin: Map<number, ComplexNumber> = new Map();

  /**
   * 构造函数
   * @param size FFT大小，必须是2的幂次方
   * @param windowType 窗函数类型
   * @param smoothingFactor 平滑因子
   */
  constructor(size: number = 2048, windowType: WindowType = WindowType.HANNING, smoothingFactor: number = 0.2,
    overlap: number = 0.5, sampleRate: number = 44100, decimationEnabled: boolean = false, decimationFactor: number = 1,
    kaiserBeta: number = 6.0, gaussianSigma: number = 0.5, tukeyAlpha: number = 0.5, chebyshevAttenuation: number = 60.0) {
    // 确保size是2的幂次方
    if (!this.isPowerOf2(size)) {
      throw new Error('FFT大小必须是2的幂');
    }
    if (size <= 0) {
      throw new Error('FFT大小必须大于0');
    }
    this.size = size;
    this.windowType = windowType;
    this.smoothingFactor = smoothingFactor;
    this.overlap = overlap;
    this.sampleRate = sampleRate;
    this.decimationEnabled = decimationEnabled;
    this.decimationFactor = decimationFactor;

    // 使用预缓存的窗函数和能量校正因子，传递窗函数参数
    const windowData = WindowFunctionCache.getWindowDataWithParams(size, windowType, kaiserBeta, gaussianSigma, tukeyAlpha, chebyshevAttenuation);
    this.window = windowData.window;
    this.WINDOW_CORRECTION = windowData.correction;
    
    // 在调试模式下验证计权公式
    if (this.DEBUG) {
      this.validateWeightingFormulas(WeightingType.A);
      this.validateWeightingFormulas(WeightingType.C);
      console.info(`[FFT分析器] 初始化: 采样率=${this.sampleRate}Hz, 降采样=${this.decimationEnabled}, 降采样因子=${this.decimationFactor}`);
      console.info(`[FFT分析器] 窗函数参数: KaiserBeta=${kaiserBeta}, GaussianSigma=${gaussianSigma}, TukeyAlpha=${tukeyAlpha}, ChebyshevAttenuation=${chebyshevAttenuation}`);
    }
  }

  /**
   * 应用降采样
   * @param samples 原始样本数据
   * @returns 降采样后的样本数据
   */
  private applyDecimation(samples: Int16Array): Int16Array {
    if (!this.decimationEnabled || this.decimationFactor <= 1) {
      return samples;
    }

    const decimatedLength = Math.floor(samples.length / this.decimationFactor);
    const decimatedSamples = new Int16Array(decimatedLength);

    // 使用简单的移动平均滤波作为抗混叠滤波器
    // 在实际应用中，更复杂的滤波器（如FIR或IIR）会更好
    const filterLength = Math.min(this.decimationFactor * 4, samples.length);
    
    for (let i = 0; i < decimatedLength; i++) {
      const sourceIndex = i * this.decimationFactor;
      
      // 计算移动平均值
      let sum = 0;
      let count = 0;
      const startIdx = Math.max(0, sourceIndex - Math.floor(filterLength / 2));
      const endIdx = Math.min(samples.length - 1, sourceIndex + Math.floor(filterLength / 2));
      
      for (let j = startIdx; j <= endIdx; j++) {
        sum += samples[j];
        count++;
      }
      
      // 使用平均值作为降采样后的值
      decimatedSamples[i] = Math.round(sum / count);
    }

    return decimatedSamples;
  }

  private isPowerOf2(value: number): boolean {
    return (value & (value - 1)) === 0 && value !== 0;
  }

  /**
   * 平滑频谱数据
   * @param magnitudes 当前幅度谱
   */
  private smoothMagnitudes(magnitudes: Float32Array): Float32Array {
    if (!this.previousMagnitudes) {
      this.previousMagnitudes = magnitudes.slice();
      return magnitudes;
    }

    // 使用分频段平滑，不同频段使用不同的平滑因子
    const sampleRate = this.decimationEnabled ?
      this.sampleRate / this.decimationFactor : this.sampleRate;
    const freqResolution = sampleRate / this.size;
    
    for (let i = 0; i < magnitudes.length; i++) {
      const frequency = i * freqResolution;
      const smoothingFactor = this.getFrequencyBasedSmoothingFactor(frequency);
      
      magnitudes[i] = smoothingFactor * magnitudes[i] +
        (1 - smoothingFactor) * this.previousMagnitudes[i];
    }

    // 更新上一帧数据
    this.previousMagnitudes.set(magnitudes);
    return magnitudes;
  }
  
  /**
   * 根据频率获取平滑因子
   * 低频使用较少平滑保持细节，高频使用较多平滑减少噪声
   * @param frequency 频率值
   * @returns 平滑因子
   */
  private getFrequencyBasedSmoothingFactor(frequency: number): number {
    // 基础平滑因子
    const baseSmoothingFactor = this.smoothingFactor;
    
    // 根据频率调整平滑因子
    if (frequency < 250) {
      // 低频段：使用较少平滑，保持细节
      return Math.min(0.8, baseSmoothingFactor * 1.5);
    } else if (frequency < 2000) {
      // 中频段：使用标准平滑
      return baseSmoothingFactor;
    } else if (frequency < 8000) {
      // 高频段：使用较多平滑，减少噪声
      return Math.max(0.1, baseSmoothingFactor * 0.7);
    } else {
      // 甚高频段：使用更多平滑，进一步减少噪声
      return Math.max(0.05, baseSmoothingFactor * 0.5);
    }
  }

  /**
   * 验证输入信号的有效性
   * @param samples 输入信号样本
   * @returns 信号统计信息
   */
  private validateSignal(samples: Int16Array): SignalStats {
    let maxAmp = -Infinity;
    let minAmp = Infinity;
    let sumSquares = 0;

    for (let i = 0; i < samples.length; i++) {
      const value = samples[i];
      maxAmp = Math.max(maxAmp, value);
      minAmp = Math.min(minAmp, value);
      sumSquares += value * value;
    }

    const rms = Math.sqrt(sumSquares / samples.length);
    const isValid = rms > 1.0; // RMS值需要大于1以确保信号有效

    if (this.DEBUG) {
      console.info(`信号统计: 最大值=${maxAmp}, 最小值=${minAmp}, RMS=${rms}, 有效=${isValid}`);
    }

    return {
      maxAmp,
      minAmp,
      rms,
      isValid
    };
  }

  /**
   * 执行FFT变换
   * @param input 输入数据缓冲区
   * @returns 频谱数据
   * @throws Error 当输入数据无效时抛出异常
   */
  public transform(input: ArrayBuffer, weightingType: WeightingType = WeightingType.A): Float32Array {
    if (this.DEBUG) {
      console.info(`开始FFT变换: 输入大小=${input.byteLength}字节`);
    }

    if (!input || input.byteLength === 0) {
      throw new Error('输入数据不能为空');
    }

    // 检查输入数据大小是否合理
    if (input.byteLength < 2) {
      throw new Error('输入数据太小，至少需要2字节');
    }

    if (this.DEBUG) {
      console.info(`当前计权类型: ${weightingType}`);
    }

    // 重用samples数组
    let samples = new Int16Array(input);
    
    // 应用降采样（如果启用）
    if (this.decimationEnabled && this.decimationFactor > 1) {
      samples = this.applyDecimation(samples);
      if (this.DEBUG) {
        console.info(`应用降采样: 原始样本数=${input.byteLength / 2}, 降采样后=${samples.length}, 降采样因子=${this.decimationFactor}`);
      }
    }
    
    if (!this.cachedSamples || this.cachedSamples.length !== samples.length) {
      this.cachedSamples = new Int16Array(samples.length);
    }
    this.cachedSamples.set(samples);

    // 验证输入信号
    const signalStats = this.validateSignal(this.cachedSamples);
    if (!signalStats.isValid) {
      if (this.DEBUG) {
        console.warn('输入信号可能无效，振幅过低');
      }
    }

    // 重用real/imag数组
    const real = new Float32Array(this.size);
    const imag = new Float32Array(this.size);

    // 应用窗函数并归一化
    const scale = 1.0 / this.REF_VALUE;
    const actualSamples = Math.min(this.size, this.cachedSamples.length);

    if (this.DEBUG) {
      console.info(`归一化比例: ${scale}, 窗函数修正: ${this.WINDOW_CORRECTION}, 实际样本数: ${actualSamples}`);
    }

    // 将输入数据复制到FFT缓冲区并应用窗函数
    // 优化：预计算窗函数缩放因子，避免重复计算
    const windowScale = this.window.length / actualSamples;
    
    for (let i = 0; i < actualSamples; i++) {
      // 使用预计算的缩放因子，避免重复除法运算
      const windowIndex = Math.floor(i * windowScale);
      // 确保索引不越界
      const safeWindowIndex = Math.min(windowIndex, this.window.length - 1);
      real[i] = this.cachedSamples[i] * scale * this.window[safeWindowIndex];
      imag[i] = 0;
    }

    // 对未使用的部分填充0
    for (let i = actualSamples; i < this.size; i++) {
      real[i] = 0;
      imag[i] = 0;
    }

    // 执行FFT
    this.fft(real, imag);

    // 计算频谱
    const spectrum = new Float32Array(this.size / 2); // 只需要一半的频率点（奈奎斯特定理）

    // 计算频率分辨率 - 使用实际采样率（考虑降采样）
    const effectiveSampleRate = this.decimationEnabled ?
      this.sampleRate / this.decimationFactor : this.sampleRate;
    const freqResolution = effectiveSampleRate / actualSamples; // 使用实际样本数计算分辨率
    if (this.DEBUG) {
      console.info(`FFT参数: 归一化因子=${1.0 / this.size}, 频率分辨率=${freqResolution}Hz, 有效采样率=${effectiveSampleRate}Hz`);
    }

    // 计算频谱
    for (let i = 0; i < spectrum.length; i++) {
      const frequency = i * freqResolution;
      const db = this.calculateDecibels(real[i], imag[i], frequency, weightingType);
      spectrum[i] = db;
    }

    return this.smoothMagnitudes(spectrum);
  }

  /**
   * 基础的FFT实现
   */
  private fft(real: Float32Array, imag: Float32Array): void {
    const n = real.length;

    // 确保缓存数组已初始化且大小正确
    this.initializeCacheArrays(n);

    // 初始化数据
    this.cachedReal!.set(real);
    this.cachedImag!.set(imag);

    // 位反转排序
    for (let i = 0; i < n; i++) {
      const j = this.reverseBits(i, Math.log2(n));
      if (j > i) {
        // 交换实部
        const tempReal = this.cachedReal![i];
        this.cachedReal![i] = this.cachedReal![j];
        this.cachedReal![j] = tempReal;
        // 交换虚部
        const tempImag = this.cachedImag![i];
        this.cachedImag![i] = this.cachedImag![j];
        this.cachedImag![j] = tempImag;
      }
    }

    // FFT计算
    for (let size = 2; size <= n; size *= 2) {
      const halfSize = size / 2;
      const angle = -2 * Math.PI / size;

      for (let i = 0; i < n; i += size) {
        for (let j = 0; j < halfSize; j++) {
          const k = i + j;
          const l = k + halfSize;

          // 获取或计算旋转因子 - 使用Map提高性能
          const key = angle * j;
          let cosSin = this.cachedCosSin.get(key);
          if (!cosSin) {
            cosSin = {
              real: Math.cos(key),
              imag: Math.sin(key)
            };
            this.cachedCosSin.set(key, cosSin);
          }

          // 蝶形运算
          const tr = this.cachedImag![l] * cosSin.real - this.cachedReal![l] * cosSin.imag;
          const ti = this.cachedReal![l] * cosSin.real + this.cachedImag![l] * cosSin.imag;

          // 更新结果
          this.cachedReal![l] = this.cachedReal![k] - tr;
          this.cachedImag![l] = this.cachedImag![k] - ti;
          this.cachedReal![k] = this.cachedReal![k] + tr;
          this.cachedImag![k] = this.cachedImag![k] + ti;
        }
      }
    }

    // 将缓存结果复制回原数组
    real.set(this.cachedReal!);
    imag.set(this.cachedImag!);
  }

  /**
   * 初始化缓存数组
   * @param size 数组大小
   * @private
   */
  private initializeCacheArrays(size: number): void {
    if (!this.cachedReal || this.cachedReal.length !== size) {
      this.cachedReal = new Float32Array(size);
    }
    if (!this.cachedImag || this.cachedImag.length !== size) {
      this.cachedImag = new Float32Array(size);
    }
  }

  private reverseBits(x: number, bits: number): number {
    let result = 0;
    for (let i = 0; i < bits; i++) {
      result = (result << 1) | (x & 1);
      x >>= 1;
    }
    return result;
  }

  /**
   * 获取指定频率的计权值
   * @param frequency 频率（Hz）
   * @param weightingType 计权类型
   * @returns 计权值
   */
  private getWeighting(frequency: number, weightingType: WeightingType): number {
    // 如果是Z计权，直接返回0dB（不进行频率计权）
    if (weightingType === WeightingType.Z) {
      return 0.0;
    }

    // A计权公式 - 返回dB值
    if (weightingType === WeightingType.A) {
      return this.calculateAWeighting(frequency);
    }

    // C计权公式 - 返回dB值
    if (weightingType === WeightingType.C) {
      return this.calculateCWeighting(frequency);
    }

    return 0.0; // 默认不进行计权
  }

  /**
   * 计算频谱的分贝值
   * @param re 实部
   * @param im 虚部
   * @param frequency 频率
   * @param weightingType 计权类型
   * @returns 分贝值
   */
  private calculateDecibels(re: number, im: number, frequency: number, weightingType: WeightingType): number {
    // 计算功率谱密度（考虑窗函数能量损失和FFT大小归一化）
    const power = (re * re + im * im) / (this.size * this.WINDOW_CORRECTION);

    // 计算分贝值（相对于参考声压）
    if (power <= 0) {
      return this.MIN_DB;
    }

    // 先计算未加权的分贝值
    let dbValue = 10.0 * Math.log10(power) + 93.98 - this.MIC_SENSITIVITY + this.systemGain;

    // 应用频率计权（getWeighting现在返回dB值）
    const weightingDb = this.getWeighting(frequency, weightingType);
    dbValue += weightingDb;

    // 确保不低于最小分贝值
    return Math.max(dbValue, this.MIN_DB);
  }


  /**
   * 获取指定频率范围内的能量
   * @param spectrum 频谱数据
   * @param startFreq 起始频率
   * @param endFreq 结束频率
   * @param sampleRate 采样率
   * @returns 频率范围内的能量值
   */
  public getFrequencyRangeEnergy(
    spectrum: Float32Array,
    startFreq: number,
    endFreq: number,
    sampleRate?: number
  ): number {
    if (!spectrum || spectrum.length === 0) {
      throw new Error('频谱数据不能为空');
    }

    if (startFreq < 0 || endFreq <= startFreq) {
      throw new Error('频率范围无效');
    }

    // 检查频率范围是否超出奈奎斯特频率
    const effectiveSampleRate = sampleRate || this.sampleRate;
    const nyquistFreq = effectiveSampleRate / 2;
    if (startFreq > nyquistFreq) {
      if (this.DEBUG) {
        console.warn(`起始频率${startFreq}Hz超过奈奎斯特频率${nyquistFreq}Hz`);
      }
      return this.MIN_DB;
    }

    const binSize = effectiveSampleRate / (2 * spectrum.length);
    const startBin = Math.max(0, Math.floor(startFreq / binSize));
    const endBin = Math.min(spectrum.length - 1, Math.ceil(endFreq / binSize));

    let totalEnergy = 0;
    let count = 0;

    for (let i = startBin; i <= endBin; i++) {
      // 跳过无效值
      if (isNaN(spectrum[i]) || spectrum[i] <= this.MIN_DB) {
        continue;
      }
      // 将分贝值转换回线性域进行平均
      totalEnergy += Math.pow(10, spectrum[i] / 10);
      count++;
    }

    // 将平均能量转换回分贝域
    return count > 0 ? 10 * Math.log10(totalEnergy / count) : this.MIN_DB;
  }

  /**
   * 获取频率分辨率
   */
  public getFrequencyResolution(): number {
    const effectiveSampleRate = this.decimationEnabled ?
      this.sampleRate / this.decimationFactor : this.sampleRate;
    return effectiveSampleRate / this.size;
  }

  /**
   * 获取时间分辨率（毫秒）
   */
  public getTimeResolution(): number {
    const effectiveSampleRate = this.decimationEnabled ?
      this.sampleRate / this.decimationFactor : this.sampleRate;
    return (this.size / effectiveSampleRate) * 1000;
  }

  /**
   * 重置分析器状态
   */
  public reset(): void {
    this.previousMagnitudes = null;
    this.cachedSamples = null;
    this.cachedCosSin.clear(); // 清理旋转因子缓存
    if (this.DEBUG) {
      console.info('FFT分析器状态已重置');
    }
  }

  public calculateAverageDb(weightedSpectrum: Float32Array): number {
    // 计算有效的分贝值平均值
    let sum: number = 0;
    let validCount: number = 0;

    for (let i = 0; i < weightedSpectrum.length; i++) {
      if (!isNaN(weightedSpectrum[i]) && weightedSpectrum[i] > this.MIN_DB) {
        sum += weightedSpectrum[i];
        validCount++;
      }
    }

    // 检查是否有足够的有效样本
    if (validCount < 1) {
      console.warn('[FFT分析] 有效样本数不足');
      return this.MIN_DB;
    }

    const averageDb = sum / validCount;
    console.info(`[FFT分析] 计算完成，平均分贝值: ${averageDb.toFixed(2)}`);

    return averageDb;
  }

  /**
   * 对频谱应用计权
   * @param spectrum 频谱数据
   * @param weightingType 计权类型
   * @returns 计权后的频谱
   */
  public applyWeighting(spectrum: Float32Array, weightingType: WeightingType): Float32Array {
    const weightedSpectrum = new Float32Array(spectrum.length);
    const freqResolution = this.getFrequencyResolution();

    for (let i = 0; i < spectrum.length; i++) {
      const frequency = i * freqResolution;
      let weightingFactor = 0;

      switch (weightingType) {
        case WeightingType.A:
          weightingFactor = this.calculateAWeighting(frequency);
          break;
        case WeightingType.C:
          weightingFactor = this.calculateCWeighting(frequency);
          break;
        case WeightingType.Z:
          weightingFactor = 0; // Z计权不做修正，0dB
          break;
        default:
          weightingFactor = 0;
      }

      weightedSpectrum[i] = spectrum[i] + weightingFactor;
    }

    return weightedSpectrum;
  }

  /**
   * 计算A计权修正值
   * @param frequency 频率
   * @returns 修正值（dB）
   */
  private calculateAWeighting(frequency: number): number {
    const f2 = frequency * frequency;
    const f4 = f2 * f2;

    const c1 = 12194.0 * 12194.0;
    const c2 = 20.6 * 20.6;
    const c3 = 107.7 * 107.7;
    const c4 = 737.9 * 737.9;

    const num = c1 * f4;
    const den = ((f2 + c2) * Math.sqrt((f2 + c3) * (f2 + c4)) * (f2 + c1));

    return 20.0 * Math.log10(num / den) + 2.0;
  }

  /**
   * 计算C计权修正值
   * @param frequency 频率
   * @returns 修正值（dB）
   */
  private calculateCWeighting(frequency: number): number {
    const f2 = frequency * frequency;

    const c1 = 12194.0 * 12194.0;
    const c2 = 20.6 * 20.6;

    const num = c1 * f2;
    const den = (f2 + c2) * (f2 + c1);

    return 20.0 * Math.log10(num / den) + 0.06;
  }

  /**
   * 验证计权公式的准确性（用于调试）
   * @param weightingType 计权类型
   */
  public validateWeightingFormulas(weightingType: WeightingType): void {
    if (!this.DEBUG) return;
    
    console.info(`验证${weightingType}计权公式准确性:`);
    
    // 测试标准频率点
    const testFrequencies = [31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000];
    const expectedA = [-39.4, -26.2, -16.1, -8.6, -3.2, 0, 1.2, 1.0, -1.1];
    const expectedC = [-3.0, -0.8, -0.2, 0, 0, 0, -0.2, -0.8, -3.0];
    
    testFrequencies.forEach((freq, index) => {
      let actualValue = 0;
      let expectedValue = 0;
      
      if (weightingType === WeightingType.A) {
        actualValue = this.calculateAWeighting(freq);
        expectedValue = expectedA[index];
      } else if (weightingType === WeightingType.C) {
        actualValue = this.calculateCWeighting(freq);
        expectedValue = expectedC[index];
      }
      
      const error = Math.abs(actualValue - expectedValue);
      const status = error < 0.5 ? '✓' : '✗';
      
      console.info(`${status} ${freq}Hz: 实际值=${actualValue.toFixed(2)}dB, 期望值=${expectedValue.toFixed(2)}dB, 误差=${error.toFixed(2)}dB`);
    });
  }
}
