import { DecibelMeter, StatisticsView, LocationDisplay, StatisticsDataPoint, LocationStyle, AudioService, DecibelService } from '@ohos/library';
import prompt from '@ohos.prompt';

@Entry
@Component
struct Index {
  @State currentDecibel: number = 0;
  @State isRecording: boolean = false;
  private audioService = new AudioService();
  private decibelService = new DecibelService();

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
      prompt.showToast({
        message: '启动录音失败：' + (err instanceof Error ? err.message : String(err)),
        duration: 3000
      });
    }
  }

  private async stopRecording() {
    try {
      await this.audioService.stopRecording();
      this.isRecording = false;
    } catch (err) {
      prompt.showToast({
        message: '停止录音失败：' + (err instanceof Error ? err.message : String(err)),
        duration: 3000
      });
    }
  }

  @Builder
  DecibelMeterBuilder() {
    Column() {
      DecibelMeter()
    }
    .width('90%')
    .margin({ bottom: 20 })
  }

  @Builder
  StatisticsViewBuilder() {
    Column() {
      StatisticsView({
        title: '噪音历史',
        data: [
          { timestamp: Date.now(), value: 30 },
          { timestamp: Date.now(), value: 60 },
          { timestamp: Date.now(), value: 90 },
          { timestamp: Date.now(), value: 100 }
        ] as StatisticsDataPoint[],
        chartBackgroundColor: '#FFFFFF',
        chartLineColor: '#007DFF',
        chartWidth: '90%',
        chartHeight: 200
      })
    }
  }

  @Builder
  LocationDisplayBuilder() {
    Column() {
      LocationDisplay()
    }
    .width('90%')
    .height(100)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  build() {
    Column() {
      Row() {
        Text('噪音检测')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 20, bottom: 20 })

      this.DecibelMeterBuilder()
      this.StatisticsViewBuilder()
      this.LocationDisplayBuilder()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}