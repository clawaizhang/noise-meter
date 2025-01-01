import { AudioService } from '../../../library/ets/services/AudioService';
import { DecibelService } from '../services/DecibelService';
import { LocationService } from '../../../library/ets/services/LocationService';
import { DecibelRecord } from '../../../library/ets/models/DecibelRecord';
import { DecibelRecordService } from '../services/DecibelRecordService';
import { LocationDisplay } from '../../../library/ets/components/business/LocationDisplay'
import { DialogParams, DialogService } from '../../../library/ets/services/DialogService';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { DetailDialog } from '../../../library/ets/components/business/DetailDialog';
import { noiseMeterNavStack } from '../../MainPageInfo';

@Builder
function buildDialog(params: DialogParams) {
  DetailDialog({
    selectedRecord: params.selectedRecord,
    closeDialog: params.closeDialog
  })
}

@Component
export struct DecibelMeter {
  @State private currentDecibel: number = 0
  @State private minDecibel: number = 0
  @State private maxDecibel: number = 0
  @State private avgDecibel: number = 0
  @State private isRecording: boolean = false
  @State private showStats: boolean = false
  @State private recordingTime: number = 0
  @Consume(noiseMeterNavStack) navStack: NavPathStack
  private decibelService: DecibelService = new DecibelService()
  private audioService: AudioService = new AudioService(getContext() as common.UIAbilityContext)
  private locationService: LocationService = LocationService.getInstance()
  private recordService: DecibelRecordService = new DecibelRecordService(getContext() as common.UIAbilityContext)
  private dialogService: DialogService = new DialogService()
  private dbCount: number = 0
  private dbSum: number = 0
  private context?: common.UIAbilityContext
  private values: number[] = []
  private startTime: number = 0

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
        this.isRecording = true;
        this.startTime = new Date().getTime();
        this.recordingTime = 0;
        this.values = [];
        this.dbCount = 0;
        this.dbSum = 0;

        // 如果没有在采集音频，先启动采集
        if (!this.audioService.isAudioCapturing()) {
          await this.startAudioCapture();
        }

        // 开始处理音频数据
        this.audioService.startProcessing((buffer: ArrayBuffer) => {
          // 使用DecibelService计算分贝值
          const db = this.decibelService.calculateDecibel(buffer, buffer.byteLength);
          this.currentDecibel = Math.round(db);
          this.values.push(this.currentDecibel);
          this.updateStatistics(this.currentDecibel);
          // 更新计时器
          this.recordingTime = Math.floor((new Date().getTime() - this.startTime) / 1000);
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
        this.values = [];
        this.startTime = 0;
        this.recordingTime = 0;
      }
    }
  }

  private async stopRecording() {
    if (this.isRecording) {
      this.isRecording = false;
      // 只停止处理音频数据，不停止采集
      this.audioService.stopProcessing();

      try {
        // 获取缓存的位置信息
        const locationInfo = this.locationService.getCachedLocation();
        // 计算检测时长
        const duration = new Date().getTime() - this.startTime;

        // 创建并保存记录
        const record = new DecibelRecord(
          this.minDecibel,
          this.maxDecibel,
          this.avgDecibel,
          duration,
          [...this.values],
          locationInfo?.address// 使用可选链操作符获取地址
        );
        await this.recordService.saveRecord(record);

        // 显示详情弹窗
        this.dialogService.showDetailDialog(this.getUIContext(), wrapBuilder(buildDialog), record);

      } catch (error) {
        console.error('保存记录失败:', error);
      }
    }
  }

  private updateStatistics(value: number) {
    if (value > 0) {
      // 记录分贝值
      this.values.push(value);

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

          Stack() {
            Row() {
              if (this.isRecording) {
                Text(new Date(this.startTime).toLocaleTimeString('zh-CN', {
                  hour: '2-digit',
                  minute: '2-digit',
                  second: '2-digit',
                  hour12: false
                }))
                  .fontSize(14)
                  .fontColor('#666666')
              }
              Blank()
              if (this.isRecording) {
                Text(`${this.recordingTime}秒`)
                  .fontSize(14)
                  .fontColor('#666666')
              }
            }
            .width('100%')

            Text(this.decibelService.getDecibelLevel(this.currentDecibel))
              .fontSize(16)
              .fontColor('#666666')
          }
          .width('92%')
          .height(20)
          .margin({ top: 12, bottom: 20 })

          // 分割线
          Divider()
            .width('92%')
            .color('#E0E0E0')
            .margin({ top: 0, bottom: 16 })

          // 统计数据显示
          this.StatisticsRow()

        }
        .width('100%')
        .padding({
          top: 28,
          bottom: 28,
          left: 24,
          right: 24
        })
        .backgroundColor(Color.White)
        .borderRadius(24)
        .onClick(() => {
          const record = new DecibelRecord(
            this.minDecibel,
            this.maxDecibel,
            this.avgDecibel,
            this.startTime == 0 ? 0 : new Date().getTime() - this.startTime,
            [...this.values],
            this.locationService.getCachedLocation()?.address
          );
          this.dialogService.showDetailDialog(this.getUIContext(), wrapBuilder(buildDialog), record);
        })

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
          this.navStack.pushPathByName('DecibelHistory', null, true);
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
      .padding({
        left: 20,
        right: 20,
        top: 16,
        bottom: 16
      })
      .borderRadius(20)
      .backgroundColor(Color.White)
      .margin({
        top: 16,
        bottom: 16,
        left: 16,
        right: 16
      })
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
      .backgroundColor(this.isRecording ? '#666666' : '#2196F3')
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