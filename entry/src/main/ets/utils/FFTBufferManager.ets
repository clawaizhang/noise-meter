/**
 * 缓冲区状态信息接口
 */
export interface BufferStatus {
  fftSize: number;
  overlapSize: number;
  stepSize: number;
  availableSamples: number;
  bufferSize: number;
  utilization: number;
  canProcess: boolean;
}

/**
 * FFT缓冲区管理器 - 重构版本
 * 支持重叠处理和滑动窗口，确保音频数据的连续性
 */
export class FFTBufferManager {
  private ringBuffer: Int16Array;      // 环形缓冲区
  private windowBuffer: Int16Array;     // 窗口缓冲区（用于FFT处理）
  private writePosition: number = 0;    // 写入位置
  private availableSamples: number = 0; // 可用样本数
  private fftSize: number;              // FFT大小
  private overlapSize: number;          // 重叠大小
  private stepSize: number;             // 步进大小
  private bufferSize: number;            // 缓冲区总大小
  
  /**
   * 构造函数
   * @param fftSize FFT大小（必须是2的幂次方）
   * @param overlapRatio 重叠比例 (0-1)
   */
  constructor(fftSize: number, overlapRatio: number = 0.5) {
    this.fftSize = fftSize;
    this.overlapSize = Math.floor(fftSize * overlapRatio);
    this.stepSize = fftSize - this.overlapSize;
    
    // 环形缓冲区大小至少为FFT大小的2倍，确保有足够空间处理重叠
    this.bufferSize = Math.max(fftSize * 2, fftSize + this.stepSize * 4);
    
    this.ringBuffer = new Int16Array(this.bufferSize);
    this.windowBuffer = new Int16Array(fftSize);
    
    console.info(`[FFT缓冲区] 初始化: FFT大小=${fftSize}, 重叠=${overlapRatio}, 步进=${this.stepSize}, 缓冲区大小=${this.bufferSize}`);
  }
  
  /**
   * 添加音频数据到缓冲区
   * @param data 音频数据缓冲区
   * @returns 是否有足够数据进行FFT处理
   */
  addData(data: ArrayBuffer): boolean {
    if (!data || data.byteLength === 0) {
      console.warn('[FFT缓冲区] 接收到空数据');
      return false;
    }
    
    const newData = new Int16Array(data);
    const samplesToAdd = Math.min(newData.length, this.bufferSize - this.availableSamples);
    
    if (samplesToAdd === 0) {
      console.warn('[FFT缓冲区] 缓冲区已满，丢弃数据');
      return false;
    }
    
    // 将新数据写入环形缓冲区
    for (let i = 0; i < samplesToAdd; i++) {
      this.ringBuffer[this.writePosition] = newData[i];
      this.writePosition = (this.writePosition + 1) % this.bufferSize;
    }
    
    this.availableSamples += samplesToAdd;
    
    console.debug(`[FFT缓冲区] 数据添加: 新增=${samplesToAdd}样本, ` +
      `当前可用=${this.availableSamples}, 缓冲区使用=${(this.availableSamples / this.bufferSize * 100).toFixed(1)}%`);
    
    // 检查是否有足够数据进行FFT处理
    return this.availableSamples >= this.fftSize;
  }
  
  /**
   * 获取当前窗口数据进行FFT处理
   * @returns 窗口数据缓冲区
   */
  getWindow(): ArrayBuffer {
    if (this.availableSamples < this.fftSize) {
      console.warn(`[FFT缓冲区] 数据不足: ${this.availableSamples}/${this.fftSize}样本`);
    }
    
    // 计算读取位置（从可用数据的末尾开始，确保获取最新的数据）
    const readPosition = (this.writePosition - this.fftSize + this.bufferSize) % this.bufferSize;
    
    // 从环形缓冲区复制数据到窗口缓冲区
    for (let i = 0; i < this.fftSize; i++) {
      const sourcePos = (readPosition + i) % this.bufferSize;
      this.windowBuffer[i] = this.ringBuffer[sourcePos];
    }
    
    return this.windowBuffer.buffer;
  }
  
  /**
   * 移动窗口位置（处理完当前窗口后调用）
   * 移除步长大小的样本，保留重叠部分
   */
  advanceWindow(): void {
    if (this.availableSamples < this.stepSize) {
      console.warn(`[FFT缓冲区] 无法前进窗口，可用数据不足: ${this.availableSamples} < ${this.stepSize}`);
      return;
    }
    
    // 减少可用样本数（模拟移动窗口）
    this.availableSamples -= this.stepSize;
    
    console.debug(`[FFT缓冲区] 窗口前进: 步进=${this.stepSize}, 剩余可用=${this.availableSamples}`);
  }
  
  /**
   * 检查是否有足够数据进行下一次FFT处理
   * @returns 是否可以处理
   */
  canProcess(): boolean {
    return this.availableSamples >= this.fftSize;
  }
  
  /**
   * 重置缓冲区
   */
  reset(): void {
    this.writePosition = 0;
    this.availableSamples = 0;
    
    // 清空缓冲区
    this.ringBuffer.fill(0);
    this.windowBuffer.fill(0);
    
    console.info(`[FFT缓冲区] 重置: 清空所有数据`);
  }
  
  /**
   * 更新FFT大小和重叠比例
   * @param newFFTSize 新的FFT大小
   * @param newOverlapRatio 新的重叠比例
   */
  updateSettings(newFFTSize: number, newOverlapRatio: number): void {
    if (newFFTSize === this.fftSize && newOverlapRatio === this.overlapSize / this.fftSize) {
      console.debug(`[FFT缓冲区] 设置未变化: FFT=${newFFTSize}, 重叠=${newOverlapRatio}`);
      return;
    }
    
    console.info(`[FFT缓冲区] 更新设置: FFT=${this.fftSize}->${newFFTSize}, 重叠=${this.overlapSize / this.fftSize}->${newOverlapRatio}`);
    
    // 重新计算参数
    this.fftSize = newFFTSize;
    this.overlapSize = Math.floor(newFFTSize * newOverlapRatio);
    this.stepSize = newFFTSize - this.overlapSize;
    
    // 重新计算缓冲区大小
    const newBufferSize = Math.max(newFFTSize * 2, newFFTSize + this.stepSize * 4);
    
    // 如果新缓冲区更大，重新分配
    if (newBufferSize > this.bufferSize) {
      this.bufferSize = newBufferSize;
      this.ringBuffer = new Int16Array(this.bufferSize);
    }
    
    // 重新分配窗口缓冲区
    this.windowBuffer = new Int16Array(newFFTSize);
    
    // 重置状态
    this.reset();
    
    console.info(`[FFT缓冲区] 新设置: FFT大小=${this.fftSize}, 重叠=${this.overlapSize}, 步进=${this.stepSize}, 缓冲区大小=${this.bufferSize}`);
  }
  
  /**
   * 获取当前FFT大小
   * @returns FFT大小
   */
  getFFTSize(): number {
    return this.fftSize;
  }
  
  /**
   * 获取重叠大小
   * @returns 重叠大小
   */
  getOverlapSize(): number {
    return this.overlapSize;
  }
  
  /**
   * 获取步进大小
   * @returns 步进大小
   */
  getStepSize(): number {
    return this.stepSize;
  }
  
  /**
   * 获取重叠比例
   * @returns 重叠比例
   */
  getOverlapRatio(): number {
    return this.overlapSize / this.fftSize;
  }
  
  /**
   * 获取缓冲区使用率
   * @returns 使用率 (0-1)
   */
  getBufferUtilization(): number {
    return this.availableSamples / this.bufferSize;
  }
  
  /**
   * 获取可用样本数
   * @returns 可用样本数
   */
  getAvailableSamples(): number {
    return this.availableSamples;
  }
  
  /**
   * 检查缓冲区是否为空
   * @returns 是否为空
   */
  isEmpty(): boolean {
    return this.availableSamples === 0;
  }
  
  /**
   * 检查缓冲区是否已满
   * @returns 是否已满
   */
  isFull(): boolean {
    return this.availableSamples >= this.bufferSize;
  }
  
  /**
   * 获取缓冲区状态信息
   * @returns 状态信息对象
   */
  getStatus(): BufferStatus {
    return {
      fftSize: this.fftSize,
      overlapSize: this.overlapSize,
      stepSize: this.stepSize,
      availableSamples: this.availableSamples,
      bufferSize: this.bufferSize,
      utilization: this.getBufferUtilization(),
      canProcess: this.canProcess()
    };
  }
}