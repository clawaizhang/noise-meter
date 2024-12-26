import { AudioService } from '../../services/AudioService';
import { DecibelService } from '../../services/DecibelService';

@Component
export struct DecibelMeter {
  @State private currentDecibel: number = 0
  @State private minDecibel: number = 0
  @State private maxDecibel: number = 0
  @State private avgDecibel: number = 0
  @State private isRecording: boolean = false
  private decibelService: DecibelService = new DecibelService()
  private audioService: AudioService = new AudioService()
  private dbCount: number = 0
  private dbSum: number = 0

  aboutToAppear() {
    // 初始化录音
    this.startRecording()
  }

  aboutToDisappear() {
    // 停止录音
    this.stopRecording()
  }

  private startRecording() {
    if (!this.isRecording) {
      this.isRecording = true
      this.audioService.startRecording((buffer: ArrayBuffer) => {
        // 使用DecibelService计算分贝值
        const db = this.decibelService.calculateDecibel(buffer, buffer.byteLength)
        this.currentDecibel = db
        this.updateStatistics(db)
      })
    }
  }

  private stopRecording() {
    if (this.isRecording) {
      this.isRecording = false
      this.audioService.stopRecording()
    }
  }

  private updateStatistics(value: number) {
    if (value > 0) {
      // 更新最小值
      if (this.minDecibel === 0 || value < this.minDecibel) {
        this.minDecibel = value
      }
      // 更新最大值
      if (value > this.maxDecibel) {
        this.maxDecibel = value
      }
      // 计算累计平均值
      this.dbSum += value
      this.dbCount++
      this.avgDecibel = this.dbSum / this.dbCount
    }
  }

  @Builder
  StatisticsRow() {
    Row() {
      Column() {
        Text('最小值')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 4 })
        Text(this.minDecibel.toFixed(1))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.decibelService.getDecibelColor(this.minDecibel))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text('平均值')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 4 })
        Text(this.avgDecibel.toFixed(1))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.decibelService.getDecibelColor(this.avgDecibel))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text('最大值')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 4 })
        Text(this.maxDecibel.toFixed(1))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.decibelService.getDecibelColor(this.maxDecibel))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .margin({ top: 16, bottom: 16 })
  }

  build() {
    Column() {
      // 分贝值显示
      Text(this.currentDecibel.toFixed(1))
        .fontSize(64)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.decibelService.getDecibelColor(this.currentDecibel))
        .margin({ top: 20, bottom: 8 })

      Text(this.decibelService.getDecibelLevel(this.currentDecibel))
        .fontSize(16)
        .fontColor('#666666')
        .margin({ bottom: 20 })

      // 统计数据显示
      this.StatisticsRow()

      // 开始/停止按钮
      Button(this.isRecording ? '停止' : '开始')
        .width(120)
        .height(40)
        .backgroundColor(this.isRecording ? '#FF4081' : '#4CAF50')
        .onClick(() => {
          if (this.isRecording) {
            this.stopRecording()
          } else {
            this.startRecording()
          }
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
} 