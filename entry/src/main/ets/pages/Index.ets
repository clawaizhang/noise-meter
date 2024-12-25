import prompt from '@ohos.prompt';
import {
  DecibelMeter,
  StatisticsView,
  AudioService,
  type StatisticsDataPoint
} from '@ohos/library';

@Entry
@Component
struct Index {
  @State currentDecibel: number = 0;
  @State isRecording: boolean = false;
  @State decibelHistory: Array<StatisticsDataPoint> = [];
  private audioService = new AudioService();

  build() {
    Column() {
      Text('噪音检测')
        .fontSize(28)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 30, bottom: 20 })

      DecibelMeter({
        currentDecibel: this.currentDecibel,
        maxDecibel: 120,
        minDecibel: 0
      })
      .margin({ top: 50 })

      Button(this.isRecording ? '停止' : '开始')
        .width(150)
        .height(50)
        .backgroundColor(this.isRecording ? '#FF0000' : '#007DFF')
        .margin({ top: 30 })
        .onClick(() => {
          if (this.isRecording) {
            this.stopRecording();
          } else {
            this.startRecording();
          }
        })

      StatisticsView({
        title: '噪音历史',
        data: this.decibelHistory
      })
      .margin({ top: 50 })
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }

  private async startRecording() {
    try {
      await this.audioService.startRecording((decibel: number) => {
        this.currentDecibel = decibel;
        // 记录历史数据
        this.decibelHistory.push({
          timestamp: Date.now(),
          value: decibel
        });
        // 只保留最近30秒的数据
        if (this.decibelHistory.length > 300) { // 300个数据点，每100ms一个点
          this.decibelHistory.shift();
        }
      });
      this.isRecording = true;
    } catch (error) {
      console.error('Failed to start recording:', error);
      prompt.showToast({
        message: '启动录音失败：' + error.message
      });
    }
  }

  private async stopRecording() {
    try {
      await this.audioService.stopRecording();
      this.isRecording = false;
    } catch (error) {
      console.error('Failed to stop recording:', error);
      prompt.showToast({
        message: '停止录音失败：' + error.message
      });
    }
  }

  aboutToDisappear() {
    // 确保在页面销毁时停止录音
    if (this.isRecording) {
      this.stopRecording();
    }
  }
}