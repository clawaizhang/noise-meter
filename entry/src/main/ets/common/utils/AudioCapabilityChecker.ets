import audio from '@ohos.multimedia.audio';
import deviceInfo from '@ohos.deviceInfo';

/**
 * 音频能力检测工具
 */
export class AudioCapabilityChecker {
  /**
   * 检测设备是否支持音频采集
   */
  static async isAudioCaptureSupported(): Promise<boolean> {
    try {
      // 尝试创建一个临时的音频采集器
      const audioStreamInfo: audio.AudioStreamInfo = {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      };

      const audioCapturerInfo: audio.AudioCapturerInfo = {
        source: audio.SourceType.SOURCE_TYPE_VOICE_RECOGNITION,
        capturerFlags: 0
      };

      const audioCapturerOptions: audio.AudioCapturerOptions = {
        streamInfo: audioStreamInfo,
        capturerInfo: audioCapturerInfo
      };

      const tempCapturer = await audio.createAudioCapturer(audioCapturerOptions);
      await tempCapturer.release();
      return true;
    } catch (err) {
      console.error('[AudioCapabilityChecker] 音频采集不支持:', JSON.stringify(err));
      return false;
    }
  }

  /**
   * 获取设备类型
   */
  static getDeviceType(): string {
    return deviceInfo.deviceType;
  }

  /**
   * 是否是手表
   */
  static isWearable(): boolean {
    return deviceInfo.deviceType === 'wearable';
  }

  /**
   * 检测是否支持振动
   */
  static isVibrateSupported(): boolean {
    try {
      import('@ohos.vibrator');
      return true;
    } catch {
      return false;
    }
  }
}
