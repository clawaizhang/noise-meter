import { AudioService } from '../../services/AudioService';
import { DecibelService } from '../../services/DecibelService';
import { LocationDisplay } from './LocationDisplay'
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import animator from '@ohos.animator';

@Component
export struct DecibelMeter {
  @State private currentDecibel: number = 0
  @State private minDecibel: number = 0
  @State private maxDecibel: number = 0
  @State private avgDecibel: number = 0
  @State private isRecording: boolean = false
  @State private showStats: boolean = false
  private decibelService: DecibelService = new DecibelService()
  private audioService: AudioService = new AudioService(getContext() as common.UIAbilityContext)
  private dbCount: number = 0
  private dbSum: number = 0
  private context?: common.UIAbilityContext

  aboutToAppear() {
    // 如果提供了外部context，重新初始化AudioService
    if (this.context) {
      this.audioService = new AudioService(this.context);
    }
  }

  aboutToDisappear() {
    // 停止音频采集
    this.stopAudioCapture();
  }

  private async startAudioCapture() {
    try {
      await this.audioService.startCapture();
    } catch (error) {
      console.error('启动音频采集失败:', error);
      // 重置录音状态
      this.isRecording = false;
    }
  }

  private async stopAudioCapture() {
    try {
      await this.audioService.stopCapture();
    } catch (error) {
      console.error('停止音频采集失败:', error);
    }
  }

  private async startRecording() {
    if (!this.isRecording) {
      try {
        // 重置计数器，但不重置显示的值
        this.dbCount = 0;
        this.dbSum = 0;

        this.isRecording = true;
        // 如果没有在采集音频，先启动采集
        if (!this.audioService.isAudioCapturing()) {
          await this.startAudioCapture();
        }
        
        // 开始处理音频数据
        this.audioService.startProcessing((buffer: ArrayBuffer) => {
          // 使用DecibelService计算分贝值
          const db = this.decibelService.calculateDecibel(buffer, buffer.byteLength);
          this.currentDecibel = Math.round(db);
          this.updateStatistics(this.currentDecibel);
        });
      } catch (error) {
        // 如果启动失败（包括权限问题），重置状态
        this.isRecording = false;
        this.currentDecibel = 0;
        this.minDecibel = 0;
        this.maxDecibel = 0;
        this.avgDecibel = 0;
        this.dbCount = 0;
        this.dbSum = 0;
      }
    }
  }

  private stopRecording() {
    if (this.isRecording) {
      this.isRecording = false;
      // 只停止处理音频数据，不停止采集
      this.audioService.stopProcessing();
      // 保留最后的分贝值显示，不重置数据
    }
  }

  private updateStatistics(value: number) {
    if (value > 0) {
      if (this.dbCount === 0) {
        // 第一次检测到的值作为初始值
        this.minDecibel = value;
        this.maxDecibel = value;
        this.avgDecibel = value;
        // 延迟显示统计区域，添加动画效果
        animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
          this.showStats = true;
        })
      } else {
        // 更新最小值
        if (value < this.minDecibel) {
          this.minDecibel = value;
        }
        // 更新最大值
        if (value > this.maxDecibel) {
          this.maxDecibel = value;
        }
      }
      // 更新平均值
      this.dbSum += value;
      this.dbCount++;
      this.avgDecibel = Math.round(this.dbSum / this.dbCount);
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
    .opacity(this.showStats ? 1 : 0)
    .scale({ x: this.showStats ? 1 : 0.9, y: this.showStats ? 1 : 0.9 })
    .animation({
      duration: 300,
      curve: Curve.EaseOut,
      delay: 100,
      iterations: 1,
      playMode: PlayMode.Normal
    })
  }

  build() {
    Column() {
      // 分贝显示卡片
      Stack({ alignContent: Alignment.TopEnd }) {
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
              .opacity(this.showStats ? 1 : 0)
              .animation({
                duration: 300,
                curve: Curve.EaseOut,
                delay: 0,
                iterations: 1,
                playMode: PlayMode.Normal
              })

            // 统计数据显示
            this.StatisticsRow()
          }
        }
        .width('100%')
        .padding({ top: 28, bottom: 28, left: 24, right: 24 })
        .backgroundColor(Color.White)
        .borderRadius(24)

        // 历史记录按钮
        Button() {
          Image($r('app.media.ic_history'))
            .width(24)
            .height(24)
            .fillColor('#2196F3')
        }
        .type(ButtonType.Circle)
        .width(40)
        .height(40)
        .margin({ top: 16, right: 16 })
        .backgroundColor('#F5F5F5')
        .onClick(() => {
          router.pushUrl({
            url: 'pages/DecibelHistory'
          })
        })
      }
      .width('100%')
      .margin({ top: 16, left: 16, right: 16 })
      .backgroundColor(Color.White)
      .borderRadius(24)
      .shadow({ radius: 1, color: '#1A000000', offsetY: 2 })

      // 位置显示
      Column() {
        LocationDisplay()
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .borderRadius(20)
      .backgroundColor(Color.White)
      .margin({ top: 16, bottom: 16, left: 16, right: 16 })
      .shadow({ radius: 1, color: '#1A000000', offsetY: 2 })

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
          // 直接停止检测，保持统计数据显示
          this.stopRecording();
        } else {
          this.startRecording();
        }
      })
    }
    .width('100%')
    .padding({ top: 8, bottom: 16 })
    .alignItems(HorizontalAlign.Center)
  }
} 