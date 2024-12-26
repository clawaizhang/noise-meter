import { DecibelService } from '../../services/DecibelService';
import { AudioService } from '../../services/AudioService';

/**
 * 分贝计组件
 */
@Component
export struct DecibelMeter {
  @State currentDecibel: number = 0;
  @State maxDecibel: number = 120;
  @State minDecibel: number = 0;
  @State isRecording: boolean = false;
  private decibelService: DecibelService = new DecibelService();
  private audioService: AudioService = new AudioService();

  aboutToDisappear() {
    if (this.isRecording) {
      this.stopRecording();
    }
  }

  private async startRecording() {
    try {
      await this.audioService.startRecording((buffer: ArrayBuffer) => {
        const decibel = this.decibelService.calculateDecibel(buffer, buffer.byteLength);
        this.currentDecibel = decibel;
      });
      this.isRecording = true;
    } catch (err) {
      console.error('启动录音失败:', err);
    }
  }

  private async stopRecording() {
    try {
      await this.audioService.stopRecording();
      this.isRecording = false;
    } catch (err) {
      console.error('停止录音失败:', err);
    }
  }

  build() {
    Column() {
      Text(this.currentDecibel.toFixed(1))
        .fontSize(64)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.decibelService.getDecibelColor(this.currentDecibel))
      
      Row() {
        Text('dB')
          .fontSize(20)
          .fontColor('#666666')
        Text(this.decibelService.getDecibelLevel(this.currentDecibel))
          .fontSize(16)
          .fontColor('#666666')
          .margin({ left: 8 })
      }
      .margin({ top: 8, bottom: 20 })

      Button(this.isRecording ? '停止' : '开始')
        .width(120)
        .height(40)
        .backgroundColor(this.isRecording ? '#F44336' : '#4CAF50')
        .onClick(() => {
          if (this.isRecording) {
            this.stopRecording();
          } else {
            this.startRecording();
          }
        })
    }
    .backgroundColor('#F5F5F5')
    .borderRadius(16)
    .width('100%')
    .padding(20)
  }
} 