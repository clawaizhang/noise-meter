import { AudioService } from '../../services/AudioService';
import { DecibelService } from '../../services/DecibelService';
import { LocationDisplay } from './LocationDisplay'

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
        this.currentDecibel = Math.round(db)
        this.updateStatistics(this.currentDecibel)
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
      this.avgDecibel = Math.round(this.dbSum / this.dbCount)
    }
  }

  @Builder
  StatisticsRow() {
    Row() {
      Column() {
        Text('最小值')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 8 })
        Row() {
          Text(this.minDecibel.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.decibelService.getDecibelColor(this.minDecibel))
          Text(' 分贝')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ left: 4 })
            .alignSelf(ItemAlign.End)
            .margin({ bottom: 4 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Divider()
        .width(1)
        .height(44)
        .backgroundColor('#E0E0E0')
        .margin({ left: 12, right: 12 })

      Column() {
        Text('平均值')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 8 })
        Row() {
          Text(this.avgDecibel.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.decibelService.getDecibelColor(this.avgDecibel))
          Text(' 分贝')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ left: 4 })
            .alignSelf(ItemAlign.End)
            .margin({ bottom: 4 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Divider()
        .width(1)
        .height(44)
        .backgroundColor('#E0E0E0')
        .margin({ left: 12, right: 12 })

      Column() {
        Text('最大值')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 8 })
        Row() {
          Text(this.maxDecibel.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.decibelService.getDecibelColor(this.maxDecibel))
          Text(' 分贝')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ left: 4 })
            .alignSelf(ItemAlign.End)
            .margin({ bottom: 4 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .margin({ top: 16 })
  }

  build() {
    Column() {
      // 分贝显示卡片
      Column() {
        // 分贝值显示
        Row() {
          Text(this.currentDecibel.toString())
            .fontSize(72)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.decibelService.getDecibelColor(this.currentDecibel))
          Text(' 分贝')
            .fontSize(20)
            .fontColor('#666666')
            .margin({ left: 8 })
            .alignSelf(ItemAlign.End)
            .margin({ bottom: 20 })
        }
        .margin({ top: 12 })

        Text(this.decibelService.getDecibelLevel(this.currentDecibel))
          .fontSize(16)
          .fontColor('#666666')
          .margin({ top: 12, bottom: 20 })

        // 分割线
        if (this.currentDecibel > 0) {
          Divider()
            .width('92%')
            .color('#E0E0E0')
            .margin({ top: 12, bottom: 16 })

          // 统计数据显示
          this.StatisticsRow()
        }
      }
      .width('100%')
      .padding({ top: 28, bottom: 28, left: 24, right: 24 })
      .backgroundColor(Color.White)
      .borderRadius(24)
      .margin({ top: 16, left: 16, right: 16 })
      .shadow({ radius: 20, color: '#1A000000', offsetY: 4 })

      // 位置显示
      Column() {
        LocationDisplay()
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .borderRadius(20)
      .backgroundColor(Color.White)
      .margin({ top: 16, bottom: 16, left: 16, right: 16 })
      .shadow({ radius: 12, color: '#1A000000', offsetY: 2 })

      // 开始/停止按钮
      Button({
        type: ButtonType.Capsule,
        stateEffect: true
      }) {
        Row() {
          if (this.isRecording) {
            Image($r('app.media.ic_stop'))
              .width(24)
              .height(24)
              .margin({ right: 8 })
              .fillColor(Color.White)
          }
          Text(this.isRecording ? '停止检测' : '开始检测')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
        }
      }
      .width('100%')
      .height(56)
      .margin({ top: 0, left: 16, right: 16 })
      .backgroundColor(this.isRecording ? '#FF4081' : '#2196F3')
      .onClick(() => {
        if (this.isRecording) {
          this.stopRecording()
        } else {
          this.startRecording()
        }
      })
    }
    .width('100%')
    .padding({ top: 8, bottom: 16 })
    .alignItems(HorizontalAlign.Center)
  }
} 