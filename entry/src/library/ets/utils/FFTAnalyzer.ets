
/**
 * FFT分析器类
 * 提供FFT变换和频谱分析功能
 */
export class FFTAnalyzer {
  private readonly size: number;
  private readonly window: Float32Array;
  private static sampleRate: number = 44100;
  private readonly REF_VALUE: number = 32767.0;  // 16位音频的最大值
  private lastMagnitude: Float32Array | null = null;
  private readonly SMOOTH_FACTOR: number = 0.2;  // 平滑因子

  /**
   * 设置音频参数
   * @param sampleRate 采样率
   */
  public static setAudioParams(sampleRate: number): void {
    FFTAnalyzer.sampleRate = sampleRate;
  }

  constructor(size: number = 2048) {
    if (!this.isPowerOf2(size)) {
      throw new Error('FFT size must be power of 2');
    }
    this.size = size;
    this.window = new Float32Array(size);
    this.initializeWindow();
  }

  private isPowerOf2(value: number): boolean {
    return (value & (value - 1)) === 0 && value !== 0;
  }

  /**
   * 初始化汉宁窗
   */
  private initializeWindow(): void {
    // 使用汉宁窗
    for (let i = 0; i < this.size; i++) {
      this.window[i] = 0.5 * (1 - Math.cos(2 * Math.PI * i / this.size));
    }
  }

  /**
   * 执行FFT变换
   * @param input 输入数据
   * @returns 频谱数据
   */
  public transform(input: ArrayBuffer): Float32Array {
    const samples = new Int16Array(input);
    const real = new Float32Array(this.size);
    const imag = new Float32Array(this.size);

    // 应用窗函数并归一化
    const scale = 1.0 / this.REF_VALUE;  // 归一化到[-1,1]
    for (let i = 0; i < this.size && i < samples.length; i++) {
      real[i] = samples[i] * scale * this.window[i];
      imag[i] = 0;
    }

    // 执行FFT
    this.fft(real, imag);

    // 计算功率谱
    const magnitude = new Float32Array(this.size / 2);
    const normalizationFactor = 2.0 / this.size;  // 考虑FFT的能量缩放和单边谱

    for (let i = 0; i < this.size / 2; i++) {
      const re = real[i] * normalizationFactor;
      const im = imag[i] * normalizationFactor;
      const power = re * re + im * im;
      
      // 转换为分贝值
      magnitude[i] = 10 * Math.log10(Math.max(power, 1e-12));
    }

    // 应用指数平均
    if (this.lastMagnitude) {
      for (let i = 0; i < magnitude.length; i++) {
        magnitude[i] = this.lastMagnitude[i] + 
          this.SMOOTH_FACTOR * (magnitude[i] - this.lastMagnitude[i]);
      }
    }
    this.lastMagnitude = magnitude.slice();

    return magnitude;
  }

  /**
   * 基础的FFT实现
   */
  private fft(real: Float32Array, imag: Float32Array): void {
    const n = real.length;

    // 比特反转排序
    for (let i = 0; i < n; i++) {
      const j = this.reverseBits(i, Math.log2(n));
      if (j > i) {
        // 交换实部
        const tempRe = real[i];
        real[i] = real[j];
        real[j] = tempRe;
        // 交换虚部
        const tempIm = imag[i];
        imag[i] = imag[j];
        imag[j] = tempIm;
      }
    }

    // FFT计算
    for (let size = 2; size <= n; size *= 2) {
      const halfsize = size / 2;
      const angle = -2 * Math.PI / size;

      // 对每个蝶形单元
      for (let i = 0; i < n; i += size) {
        for (let j = 0; j < halfsize; j++) {
          const k = i + j;
          const l = k + halfsize;
          
          // 计算旋转因子
          const cos = Math.cos(angle * j);
          const sin = Math.sin(angle * j);
          
          // 蝶形运算
          const tr = real[l] * cos - imag[l] * sin;
          const ti = real[l] * sin + imag[l] * cos;
          
          real[l] = real[k] - tr;
          imag[l] = imag[k] - ti;
          real[k] = real[k] + tr;
          imag[k] = imag[k] + ti;
        }
      }
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

  public getAmplitudeAtFrequency(spectrum: Float32Array, frequency: number, sampleRate: number): number {
    const binSize = sampleRate / (2 * spectrum.length);
    const binIndex = Math.round(frequency / binSize);
    if (binIndex >= spectrum.length) {
      return 0;
    }
    return spectrum[binIndex];
  }

  public getFrequencyRangeEnergy(
    spectrum: Float32Array,
    startFreq: number,
    endFreq: number,
    sampleRate: number
  ): number {
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