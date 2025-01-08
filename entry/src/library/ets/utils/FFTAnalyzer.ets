import { WeightingType } from '../constants/WeightingConstants';
import { PreferenceService } from '../services/PreferenceService';
import { PreferenceKeyConstants } from '../constants/PreferenceKeyConstants';

/**
 * FFT分析器类
 * 提供FFT变换和频谱分析功能
 */

// 定义频率范围接口
interface FrequencyRange {
  startFreq: number;
  endFreq: number;
}

// 定义复数运算接口
interface Complex {
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

// 复数旋转因子接口
interface ComplexRotation {
  real: number;
  imag: number;
}

// FFT分析器配置接口
interface FFTConfig {
  size: number;
  sampleRate: number;
}

export class FFTAnalyzer {
  private readonly size: number;
  private readonly window: Float32Array;
  private static sampleRate: number = 44100;
  private readonly REF_VALUE: number = 32767.0;  // 16位音频的最大值
  private readonly WINDOW_CORRECTION: number = 0.375;  // 汉宁窗的能量修正因子
  private readonly MIN_DB: number = -60.0;  // 最小分贝值
  private readonly REF_POWER: number = 2e-5;  // 参考声压，20μPa
  private readonly SMOOTH_FACTOR: number = 0.2;  // 平滑因子
  private readonly DEBUG: boolean = true;  // 调试开关

  // 缓存数组
  private cachedSamples: Int16Array | null = null;
  private cachedReal: Float32Array | null = null;
  private cachedImag: Float32Array | null = null;
  private cachedMagnitude: Float32Array | null = null;
  private cachedCosSin: Map<number, ComplexRotation> = new Map();
  private lastMagnitude: Float32Array | null = null;

  /**
   * 构造函数
   * @param size FFT大小（必须是2的幂）
   * @throws Error 当size不是2的幂时抛出异常
   */
  constructor(size: number = 2048) {
    if (!this.isPowerOf2(size)) {
      throw new Error('FFT大小必须是2的幂');
    }
    if (size <= 0) {
      throw new Error('FFT大小必须大于0');
    }
    this.size = size;
    this.window = new Float32Array(size);
    
    // 初始化汉宁窗
    for (let i = 0; i < size; i++) {
      this.window[i] = 0.5 * (1 - Math.cos(2 * Math.PI * i / (size - 1)));
    }
  }

  private isPowerOf2(value: number): boolean {
    return (value & (value - 1)) === 0 && value !== 0;
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
    
    return { maxAmp, minAmp, rms, isValid };
  }

  /**
   * 执行FFT变换
   * @param input 输入数据缓冲区
   * @returns 频谱数据
   * @throws Error 当输入数据无效时抛出异常
   */
  public transform(input: ArrayBuffer): Float32Array {
    if (this.DEBUG) {
      console.info(`开始FFT变换: 输入大小=${input.byteLength}字节`);
    }

    if (!input || input.byteLength === 0) {
      throw new Error('输入数据不能为空');
    }

    // 从PreferenceService单例获取当前计权类型
    const preferenceService = PreferenceService.getInstance();
    const weightingType = preferenceService.getString(PreferenceKeyConstants.WEIGHTING, WeightingType.A) as WeightingType;
    if (this.DEBUG) {
      console.info(`当前计权类型: ${weightingType}`);
    }

    // 重用samples数组
    const samples = new Int16Array(input);
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
    const scale = 1.0 / this.REF_VALUE;  // 仅对采样值归一化，不考虑FFT大小
    if (this.DEBUG) {
      console.info(`归一化比例: ${scale}, 窗函数修正: ${this.WINDOW_CORRECTION}`);
    }

    // 将输入数据复制到FFT缓冲区并应用窗函数
    for (let i = 0; i < this.size && i < this.cachedSamples.length; i++) {
      real[i] = this.cachedSamples[i] * scale * this.window[i];
      imag[i] = 0;
    }

    // 执行FFT
    this.fft(real, imag);

    // 重用magnitude数组
    if (!this.cachedMagnitude || this.cachedMagnitude.length !== this.size / 2) {
      this.cachedMagnitude = new Float32Array(this.size / 2);
    }
    const magnitude = this.cachedMagnitude;

    // 计算功率谱
    const binSize = FFTAnalyzer.sampleRate / this.size;
    if (this.DEBUG) {
      console.info(`FFT参数: 归一化因子=${2.0 / this.size}, 频率分辨率=${binSize}Hz`);
    }

    // 计算频谱
    for (let i = 0; i < this.size / 2; i++) {
      const frequency = i * binSize;
      magnitude[i] = this.calculateDecibels(real[i], imag[i], frequency, weightingType);
    }

    // 分析频谱
    const spectrumStats = this.analyzeSpectrum(magnitude, binSize);
    
    // 应用平滑
    if (this.lastMagnitude) {
      const smoothFactor = this.SMOOTH_FACTOR;
      if (this.DEBUG) {
        console.info(`应用平滑: 因子=${smoothFactor}`);
      }
      
      const invSmoothFactor = 1.0 - smoothFactor;
      for (let i = 0; i < magnitude.length; i++) {
        magnitude[i] = magnitude[i] * smoothFactor + 
                      this.lastMagnitude[i] * invSmoothFactor;
      }
    }

    // 保存当前频谱用于下次平滑
    if (!this.lastMagnitude || this.lastMagnitude.length !== magnitude.length) {
      this.lastMagnitude = new Float32Array(magnitude.length);
    }
    this.lastMagnitude.set(magnitude);

    return magnitude;
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
          
          // 获取或计算旋转因子
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
          const tr = this.cachedReal![l] * cosSin.real - this.cachedImag![l] * cosSin.imag;
          const ti = this.cachedReal![l] * cosSin.imag + this.cachedImag![l] * cosSin.real;
          
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
    // 如果是Z计权，直接返回1.0（不进行频率计权）
    if (weightingType === WeightingType.Z) {
      return 1.0;
    }

    // A计权公式
    if (weightingType === WeightingType.A) {
      const f2 = frequency * frequency;
      const f4 = f2 * f2;
      const numerator = 12200.0 * 12200.0 * f4;
      const denominator = (f2 + 20.6 * 20.6) * Math.sqrt((f2 + 107.7 * 107.7) * (f2 + 737.9 * 737.9)) * (f2 + 12200.0 * 12200.0);
      return Math.sqrt(numerator / denominator);
    }

    // C计权公式
    if (weightingType === WeightingType.C) {
      const f2 = frequency * frequency;
      const numerator = 12200.0 * 12200.0 * f2;
      const denominator = (f2 + 20.6 * 20.6) * (f2 + 12200.0 * 12200.0);
      return Math.sqrt(numerator / denominator);
    }

    return 1.0;  // 默认不进行计权
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
    // 计算功率谱密度（考虑窗函数能量损失）
    const power = (re * re + im * im) / this.WINDOW_CORRECTION;
    
    // 应用频率计权（使用标准IEC 61672-1的计权公式）
    const weighting = this.getWeighting(frequency, weightingType);
    const weightedPower = power * weighting * weighting;
    
    // 计算分贝值（相对于参考声压）
    if (weightedPower <= 0) {
      return this.MIN_DB;
    }
    
    // 转换为声压级SPL（使用20μPa作为参考值）
    return 10.0 * Math.log10(weightedPower) + 93.98;  // 20*log10(1/20e-6) ≈ 93.98
  }

  /**
   * 分析频谱
   * @param spectrum 频谱数据
   * @param binSize 频率分辨率
   * @returns 频谱统计信息
   */
  private analyzeSpectrum(spectrum: Float32Array, binSize: number): SpectrumStats {
    let maxDb = -Infinity;
    let minDb = Infinity;
    let sumDb = 0;
    let peakFreq = 0;
    
    // 直接处理所有样本
    for (let i = 0; i < spectrum.length; i++) {
      const db = spectrum[i];
      if (db > maxDb) {
        maxDb = db;
        peakFreq = i * binSize;
      }
      if (db < minDb) {
        minDb = db;
      }
      sumDb += db;
    }

    const avgDb = sumDb / spectrum.length;

    if (this.DEBUG) {
      console.info(`频谱分析: 最大分贝=${maxDb.toFixed(2)}dB@${peakFreq.toFixed(1)}Hz, ` +
                  `最小分贝=${minDb.toFixed(2)}dB, 平均分贝=${avgDb.toFixed(2)}dB`);
    }
    
    return {
      maxDb: maxDb,
      minDb: minDb,
      avgDb: avgDb,
      peakFreq: peakFreq,
      validSamples: spectrum.length,  // 所有样本都是有效的
      totalSamples: spectrum.length
    };
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
    sampleRate: number = FFTAnalyzer.sampleRate
  ): number {
    if (!spectrum || spectrum.length === 0) {
      throw new Error('频谱数据不能为空');
    }

    if (startFreq < 0 || endFreq <= startFreq) {
      throw new Error('频率范围无效');
    }

    const binSize = sampleRate / (2 * spectrum.length);
    const startBin = Math.floor(startFreq / binSize);
    const endBin = Math.ceil(endFreq / binSize);
    
    let totalEnergy = 0;
    let count = 0;
    
    for (let i = startBin; i <= endBin && i < spectrum.length; i++) {
      // 将分贝值转换回线性域进行平均
      totalEnergy += Math.pow(10, spectrum[i] / 10);
      count++;
    }
    
    // 将平均能量转换回分贝域
    return count > 0 ? 10 * Math.log10(totalEnergy / count) : -100;
  }
}
