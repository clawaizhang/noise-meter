/**
 * FFT分析器类
 * 提供FFT变换和频谱分析功能
 */
export class FFTAnalyzer {
  private readonly size: number;
  // 预计算的旋转因子
  private readonly twiddles: Float32Array;
  // 预计算的比特反转表
  private readonly bitReverse: Uint32Array;
  // 窗函数
  private readonly window: Float32Array;

  /**
   * 构造函数
   * @param size FFT大小，必须是2的幂
   */
  constructor(size: number = 2048) {
    if (!this.isPowerOf2(size)) {
      throw new Error('FFT size must be power of 2');
    }
    this.size = size;
    this.twiddles = new Float32Array(size * 2);
    this.bitReverse = new Uint32Array(size);
    this.window = new Float32Array(size);
    this.initialize();
  }

  /**
   * 检查是否为2的幂
   */
  private isPowerOf2(value: number): boolean {
    return (value & (value - 1)) === 0 && value !== 0;
  }

  /**
   * 初始化FFT计算所需的数据
   */
  private initialize(): void {
    // 初始化旋转因子
    for (let i = 0; i < this.size; i++) {
      const angle = -2 * Math.PI * i / this.size;
      this.twiddles[i * 2] = Math.cos(angle);
      this.twiddles[i * 2 + 1] = Math.sin(angle);
    }

    // 初始化比特反转表
    const bits = Math.log2(this.size);
    for (let i = 0; i < this.size; i++) {
      this.bitReverse[i] = this.reverseBits(i, bits);
    }

    // 初始化汉宁窗
    for (let i = 0; i < this.size; i++) {
      this.window[i] = 0.5 * (1 - Math.cos(2 * Math.PI * i / this.size));
    }
  }

  /**
   * 比特反转
   */
  private reverseBits(x: number, bits: number): number {
    let result = 0;
    for (let i = 0; i < bits; i++) {
      result = (result << 1) | (x & 1);
      x >>= 1;
    }
    return result;
  }

  /**
   * 执行FFT变换
   * @param input 输入数据
   * @returns 频谱数据
   */
  public transform(input: ArrayBuffer): Float32Array {
    // 将输入数据转换为Float32Array并应用窗函数
    const samples = new Int16Array(input);
    const real = new Float32Array(this.size);
    const imag = new Float32Array(this.size);
    const scale = 1.0 / 32768.0; // 将16位整数归一化到[-1,1]

    // 应用窗函数并归一化
    for (let i = 0; i < this.size && i < samples.length; i++) {
      real[i] = samples[i] * scale * this.window[i];
    }

    // 使用预计算的比特反转表重排数据
    for (let i = 0; i < this.size; i++) {
      const j = this.bitReverse[i];
      if (j > i) {
        const tempRe = real[i];
        real[i] = real[j];
        real[j] = tempRe;
      }
    }

    // 执行FFT
    for (let stage = 1; stage <= Math.log2(this.size); stage++) {
      const butterflySize = 1 << stage;
      const halfSize = butterflySize >> 1;

      for (let i = 0; i < this.size; i += butterflySize) {
        for (let j = 0; j < halfSize; j++) {
          const twiddle_re = this.twiddles[j * (this.size / butterflySize) * 2];
          const twiddle_im = this.twiddles[j * (this.size / butterflySize) * 2 + 1];

          const idx1 = i + j;
          const idx2 = i + j + halfSize;

          const re1 = real[idx1];
          const im1 = imag[idx1];
          const re2 = real[idx2];
          const im2 = imag[idx2];

          // 复数乘法
          const tr = re2 * twiddle_re - im2 * twiddle_im;
          const ti = re2 * twiddle_im + im2 * twiddle_re;

          real[idx2] = re1 - tr;
          imag[idx2] = im1 - ti;
          real[idx1] = re1 + tr;
          imag[idx1] = im1 + ti;
        }
      }
    }

    // 计算幅度谱
    const magnitude = new Float32Array(this.size / 2);
    for (let i = 0; i < this.size / 2; i++) {
      magnitude[i] = Math.sqrt(real[i] * real[i] + imag[i] * imag[i]);
    }

    return magnitude;
  }

  /**
   * 获取指定频率的幅值
   * @param spectrum 频谱数据
   * @param frequency 目标频率
   * @param sampleRate 采样率
   * @returns 幅值
   */
  public getAmplitudeAtFrequency(spectrum: Float32Array, frequency: number, sampleRate: number): number {
    const binSize = sampleRate / (2 * spectrum.length);
    const binIndex = Math.round(frequency / binSize);
    return binIndex < spectrum.length ? spectrum[binIndex] : 0;
  }

  /**
   * 获取指定频率范围的平均能量
   * @param spectrum 频谱数据
   * @param startFreq 起始频率
   * @param endFreq 结束频率
   * @param sampleRate 采样率
   * @returns 平均能量
   */
  public getFrequencyRangeEnergy(
    spectrum: Float32Array,
    startFreq: number,
    endFreq: number,
    sampleRate: number
  ): number {
    const binSize = sampleRate / (2 * spectrum.length);
    const startBin = Math.floor(startFreq / binSize);
    const endBin = Math.ceil(endFreq / binSize);

    let energy = 0;
    for (let i = startBin; i <= endBin && i < spectrum.length; i++) {
      energy += spectrum[i];
    }

    return energy / (endBin - startBin + 1);
  }
}