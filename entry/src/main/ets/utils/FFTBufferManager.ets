/**
 * FFT缓冲区管理器
 * 专门负责音频数据的累积和管理，为FFT处理提供固定大小的数据块
 */
export class FFTBufferManager {
  private buffer: ArrayBuffer;
  private offset: number = 0;
  private fftSize: number;
  private bufferSize: number;
  
  /**
   * 构造函数
   * @param fftSize FFT大小（必须是2的幂次方）
   */
  constructor(fftSize: number) {
    this.fftSize = fftSize;
    this.bufferSize = fftSize * 2; // 16位采样，每个样本2字节
    this.buffer = new ArrayBuffer(this.bufferSize);
    console.info(`[FFT缓冲区] 初始化: FFT大小=${fftSize}, 缓冲区大小=${this.bufferSize}字节`);
  }
  
  /**
   * 添加音频数据到缓冲区
   * @param data 音频数据缓冲区
   * @returns 是否达到FFT大小，可以开始处理
   */
  addData(data: ArrayBuffer): boolean {
    if (!data || data.byteLength === 0) {
      console.warn('[FFT缓冲区] 接收到空数据');
      return false;
    }
    
    const newData = new Int16Array(data);
    const bufferView = new Int16Array(this.buffer);
    
    const availableSpace = this.fftSize - this.offset;
    const samplesToAdd = Math.min(newData.length, availableSpace);
    
    if (samplesToAdd > 0) {
      bufferView.set(newData.subarray(0, samplesToAdd), this.offset);
      this.offset += samplesToAdd;
      
      console.debug(`[FFT缓冲区] 数据累积: 新增=${samplesToAdd}样本, ` +
        `当前累积=${this.offset}, 目标=${this.fftSize}, ` +
        `进度=${((this.offset / this.fftSize) * 100).toFixed(1)}%`);
    }
    
    // 只有当样本数精确等于FFT大小时才返回true
    const isReady = this.offset === this.fftSize;
    
    if (isReady) {
      console.info(`[FFT缓冲区] 数据块已就绪: ${this.fftSize}样本`);
    }
    
    return isReady;
  }
  
  /**
   * 获取当前缓冲区数据
   * @returns 完整的缓冲区数据
   */
  getBuffer(): ArrayBuffer {
    if (this.offset !== this.fftSize) {
      console.warn(`[FFT缓冲区] 缓冲区未满: ${this.offset}/${this.fftSize}样本`);
    }
    return this.buffer;
  }
  
  /**
   * 重置缓冲区
   */
  reset(): void {
    const oldOffset = this.offset;
    this.offset = 0;
    console.info(`[FFT缓冲区] 重置: 清空${oldOffset}样本`);
  }
  
  /**
   * 更新FFT大小
   * @param newFFTSize 新的FFT大小
   */
  updateFFTSize(newFFTSize: number): void {
    if (newFFTSize === this.fftSize) {
      console.debug(`[FFT缓冲区] FFT大小未变化: ${newFFTSize}`);
      return;
    }
    
    console.info(`[FFT缓冲区] 更新FFT大小: ${this.fftSize} -> ${newFFTSize}`);
    
    this.fftSize = newFFTSize;
    this.bufferSize = newFFTSize * 2;
    this.buffer = new ArrayBuffer(this.bufferSize);
    this.offset = 0;
    
    console.info(`[FFT缓冲区] 新缓冲区大小: ${this.bufferSize}字节`);
  }
  
  /**
   * 获取当前累积的样本数
   * @returns 当前累积样本数
   */
  getCurrentOffset(): number {
    return this.offset;
  }
  
  /**
   * 获取FFT大小
   * @returns FFT大小
   */
  getFFTSize(): number {
    return this.fftSize;
  }
  
  /**
   * 获取缓冲区大小（字节）
   * @returns 缓冲区大小
   */
  getBufferSize(): number {
    return this.bufferSize;
  }
  
  /**
   * 检查缓冲区是否为空
   * @returns 是否为空
   */
  isEmpty(): boolean {
    return this.offset === 0;
  }
  
  /**
   * 检查缓冲区是否已满
   * @returns 是否已满
   */
  isFull(): boolean {
    return this.offset === this.fftSize;
  }
  
  /**
   * 获取累积进度百分比
   * @returns 进度百分比 (0-100)
   */
  getProgress(): number {
    return (this.offset / this.fftSize) * 100;
  }
}