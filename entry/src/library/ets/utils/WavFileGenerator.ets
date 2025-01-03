import buffer from '@ohos.buffer';

/**
 * WAV文件生成器
 * 用于将PCM音频数据转换为WAV格式
 */
export class WavFileGenerator {
  /**
   * 将字符串写入DataView
   */
  private static writeString(view: DataView, offset: number, str: string): void {
    for (let i = 0; i < str.length; i++) {
      view.setUint8(offset + i, str.charCodeAt(i));
    }
  }

  /**
   * 生成WAV文件数据
   * @param audioData PCM音频数据
   * @param sampleRate 采样率
   * @param channels 声道数
   * @param bitsPerSample 采样位数
   * @returns WAV文件数据
   */
  static generateWavFile(
    audioData: ArrayBuffer[],
    sampleRate: number = 44100,
    channels: number = 2,
    bitsPerSample: number = 16
  ): ArrayBuffer {
    // 计算音频数据总长度
    const totalAudioLength = audioData.reduce((sum, data) => sum + data.byteLength, 0);
    
    // WAV文件头长度为44字节
    const headerLength = 44;
    // 计算WAV文件总长度
    const totalLength = totalAudioLength + headerLength;
    
    // 创建WAV文件缓冲区
    const wavBuffer = new ArrayBuffer(totalLength);
    const view = new DataView(wavBuffer);
    
    // 写入WAV文件头
    // RIFF chunk descriptor
    WavFileGenerator.writeString(view, 0, 'RIFF'); // ChunkID
    view.setUint32(4, totalLength - 8, true); // ChunkSize
    WavFileGenerator.writeString(view, 8, 'WAVE'); // Format
    
    // fmt sub-chunk
    WavFileGenerator.writeString(view, 12, 'fmt '); // Subchunk1ID
    view.setUint32(16, 16, true); // Subchunk1Size (16 for PCM)
    view.setUint16(20, 1, true); // AudioFormat (1 for PCM)
    view.setUint16(22, channels, true); // NumChannels
    view.setUint32(24, sampleRate, true); // SampleRate
    view.setUint32(28, sampleRate * channels * (bitsPerSample / 8), true); // ByteRate
    view.setUint16(32, channels * (bitsPerSample / 8), true); // BlockAlign
    view.setUint16(34, bitsPerSample, true); // BitsPerSample
    
    // data sub-chunk
    WavFileGenerator.writeString(view, 36, 'data'); // Subchunk2ID
    view.setUint32(40, totalAudioLength, true); // Subchunk2Size
    
    // 写入音频数据
    let offset = 44;
    for (const data of audioData) {
      new Uint8Array(wavBuffer).set(new Uint8Array(data), offset);
      offset += data.byteLength;
    }
    
    return wavBuffer;
  }
} 