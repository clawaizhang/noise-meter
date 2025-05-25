/**
 * 参数调试指南
 参数  作用域  推荐值  调节效果
 vadThreshold  0.01~0.1  0.03~0.05  值越大越不容易误触发，但可能漏检轻声
 noiseReduceFactor  0.3~1.2  0.6~0.9  值越大降噪越强，但可能引起语音失真
 平滑系数(0.9/0.1)  代码内定  0.85~0.95  值越大噪声模型更新越慢
 * */
export class AudioEnhancer {
  // ========= 可调节参数 =========
  // 增益参数
  private totalGain: number = 18; // 总增益倍数
  private stageGains: number[] = [3, 2, 3]; // 分阶段增益

  // 动态压缩参数
  private compressThreshold: number = 0.3; // 压缩启动阈值（0-1）
  private compressRatio: number = 5; // 压缩强度

  // 噪声抑制参数
  private noiseGateThreshold: number = 0.02; // 噪声门限（0-1）
  private filterFactor: number = 0.2; // 低通滤波系数
  private notchFreq: number = 50; // 陷波频率(Hz)

  // ========= 内部状态 =========
  private prevSample: number = 0;
  private sampleRate: number = 16000; // 根据实际采样率设置

  // ========= 参数设置方法 =========
  setGainParams(totalGain: number, stages?: number[]): void {
    this.totalGain = totalGain;
    if (stages) {
      this.stageGains = stages;
    } else {
      // 新算法：分解为不超过3的因数
      this.stageGains = [];
      let remaining = totalGain;
      while (remaining > 3) {
        this.stageGains.push(3);
        remaining /= 3;
      }
      if (remaining > 1e-3) { // 避免浮点误差
        this.stageGains.push(remaining);
      }
    }
  }


  setNoiseParams(gate: number, filter: number, notch?: number): void {
    this.noiseGateThreshold = gate;
    this.filterFactor = filter;
    if (notch) {
      this.notchFreq = notch;
    }
  }

  // ========= 核心处理方法 =========
  // 修复3：优化处理流程顺序
  processAudio(buffer: ArrayBuffer): ArrayBuffer {
    const int16Array = new Int16Array(buffer);
    const floatArray = this.int16ToFloat32(int16Array);

    // 新处理顺序：
    this.applyStageGain(floatArray); // 先增益
    this.applyDynamicCompression(floatArray); // 后压缩
    this.applyNotchFilter(floatArray);
    this.applyNoiseReduction(floatArray);

    return this.float32ToInt16(floatArray).buffer;
  }

  // ========= 内部处理算法 =========
  private int16ToFloat32(input: Int16Array): Float32Array {
    const output = new Float32Array(input.length);
    for (let i = 0; i < input.length; i++) {
      output[i] = input[i] / 32768.0;
    }
    return output;
  }

  private float32ToInt16(input: Float32Array): Int16Array {
    const output = new Int16Array(input.length);
    for (let i = 0; i < input.length; i++) {
      const val = Math.max(-1.0, Math.min(1.0, input[i]));
      output[i] = Math.round(val * 32767);
    }
    return output;
  }

  private applyDynamicCompression(data: Float32Array): void {
    const threshold = this.compressThreshold;
    const ratio = this.compressRatio;

    for (let i = 0; i < data.length; i++) {
      const absVal = Math.abs(data[i]);
      if (absVal > threshold) {
        const over = absVal - threshold;
        data[i] = threshold + (over / ratio) * Math.sign(data[i]);
      }
    }
  }

  // 修复2：改进的增益处理算法
  private applyStageGain(data: Float32Array): void {
    let accumulatedGain = 1;

    this.stageGains.forEach(gain => {
      accumulatedGain *= gain;
      for (let i = 0; i < data.length; i++) {
        // 前置放大+后置限幅
        data[i] *= gain;
        // 最终统一限幅
        if (i === data.length - 1) { // 最后一级处理
          data[i] = Math.tanh(data[i] * 0.8) / 0.8;
        }
      }
    });

    // 增益补偿（应对限幅损失）
    const compensation = Math.sqrt(accumulatedGain);
    for (let i = 0; i < data.length; i++) {
      data[i] *= compensation;
    }
  }

  private applyNotchFilter(data: Float32Array): void {
    // 二阶IIR陷波滤波器
    const omega = 2 * Math.PI * this.notchFreq / this.sampleRate;
    const alpha = 1 / (1 + Math.tan(omega / 2));

    let prev1 = 0, prev2 = 0;
    for (let i = 0; i < data.length; i++) {
      const input = data[i];
      const output = alpha * (input + prev2) - 2 * alpha * prev1;
      data[i] = output;
      prev2 = prev1;
      prev1 = input;
    }
  }

  private applyNoiseReduction(data: Float32Array): void {
    let prev = 0;
    const gate = this.noiseGateThreshold;
    const factor = this.filterFactor;

    for (let i = 0; i < data.length; i++) {
      // 噪声门
      if (Math.abs(data[i]) < gate) {
        data[i] = 0;
      }
      // 一阶低通滤波
      data[i] = prev * (1 - factor) + data[i] * factor;
      prev = data[i];
    }
  }
}
