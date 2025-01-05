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
import { AudioRecordDisplay } from '../../../library/ets/components/business/AudioRecordDisplay';
import { BannerCard } from '../../../library/ets/components/business/BannerCard';
import { FileService } from '../../../library/ets/services/FileService';
import { noiseMeterNavStack } from '../constant/ProviderConstant';
import { promptAction } from '@kit.ArkUI';

@Builder
function buildDialog(params: DialogParams) {
  DetailDialog({
    selectedRecord: params.selectedRecord,
    closeDialog: params.closeDialog,
    context: params.context,
    fileService: params.fileService
  })
}

@ComponentV2
export struct DecibelMeter {
  @Local private currentDecibel: number = 0
  @Local private minDecibel: number = 0
  @Local private maxDecibel: number = 0
  @Local private avgDecibel: number = 0
  @Local private isRecording: boolean = false
  @Local private showStats: boolean = false
  @Local private recordingTime: number = 0
  @Local private isRecordEnabled: boolean = true
  @Consumer(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack()
  private decibelService: DecibelService = new DecibelService()
  private audioService: AudioService = new AudioService(getContext() as common.UIAbilityContext)
  private locationService: LocationService = LocationService.getInstance()
  private recordService: DecibelRecordService = new DecibelRecordService(getContext() as common.UIAbilityContext)
  private dialogService: DialogService = new DialogService()
  private fileService: FileService = new FileService(getContext() as common.Context)
  private dbCount: number = 0
  private dbSum: number = 0
  private context?: common.UIAbilityContext
  private values: number[] = []
  private startTime: number = 0
  private releaseTimer: number = -1
  private currentAudioFilePath?: string
  private currentRecord?: DecibelRecord

  aboutToAppear() {
    // 如果提供了外部context，重新初始化AudioService
    if (this.context) {
      this.audioService = new AudioService(this.context);
    }
  }

  aboutToDisappear() {
    // 清除定时器
    if (this.releaseTimer !== -1) {
      clearTimeout(this.releaseTimer);
      this.releaseTimer = -1;
    }
    // 停止所有音频相关操作
    this.audioService.stopProcessing();
    this.audioService.stopCapture();
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
    try {
      this.isRecording = true;
      this.startTime = new Date().getTime();
      this.recordingTime = 0;
      this.values = [];
      this.dbCount = 0;
      this.dbSum = 0;

      // 创建新的记录对象
      this.currentRecord = new DecibelRecord(
        0, // minDecibel
        0, // maxDecibel
        0, // avgDecibel
        0, // duration
        [], // decibelValues
        this.locationService.getCachedLocation()?.address, // location
        undefined // audioFilePath
      );

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

  private async stopRecording() {
    if (this.isRecording) {
      this.isRecording = false;
      console.info('停止录音 - 开始');

      try {
        // 获取缓存的位置信息
        const locationInfo = this.locationService.getCachedLocation();
        console.info('位置信息:', locationInfo);

        // 计算检测时长
        const duration = new Date().getTime() - this.startTime;
        console.info('检测时长:', duration);

        // 获取WAV格式的音频数据
        let audioData: ArrayBuffer | undefined;
        if (this.isRecordEnabled) {
          try {
            console.info('开始获取WAV音频数据');
            audioData = await this.audioService.stopCaptureAndGetWavData();
            console.info('WAV音频数据大小:', audioData.byteLength);

            // 创建音频文件目录
            const audioDir = 'audio';
            try {
              await this.fileService.createDirectory(audioDir);
            } catch (error) {
              // 目录可能已存在，忽略错误
            }

            // 生成文件名并保存WAV文件
            const fileName = `audio_${new Date().getTime()}.wav`;
            const relativePath = `${audioDir}/${fileName}`;
            console.info('准备保存音频文件:', relativePath);
            this.currentAudioFilePath = await this.fileService.saveFile(relativePath, audioData);
            console.info('音频文件保存成功:', this.currentAudioFilePath);
          } catch (error) {
            console.error('获取或保存WAV音频数据失败:', error);
          }
        }

        console.info('准备创建记录');
        // 更新记录对象
        if (this.currentRecord) {
          this.currentRecord.minDecibel = this.minDecibel;
          this.currentRecord.maxDecibel = this.maxDecibel;
          this.currentRecord.avgDecibel = this.avgDecibel;
          this.currentRecord.duration = duration;
          this.currentRecord.decibelValues = [...this.values];
          this.currentRecord.location = locationInfo?.address;
          this.currentRecord.audioFilePath = this.currentAudioFilePath;
        }
        console.info('记录更新成功:', this.currentRecord);

        if (!this.currentRecord) {
          throw new Error('记录对象不存在');
        }
        await this.recordService.saveRecord(this.currentRecord);
        console.info('记录保存成功');

        // 显示详情弹窗
        const appContext = getContext(this) as common.Context;
        if (!appContext) {
          console.error('Context is not available');
          return;
        }

        console.info('准备显示详情弹窗');
        this.dialogService.showDetailDialog(
          this.getUIContext(),
          wrapBuilder(buildDialog),
          this.currentRecord || null,
          appContext
        );
        console.info('详情弹窗显示成功');

        // 清除之前的定时器
        if (this.releaseTimer !== -1) {
          clearTimeout(this.releaseTimer);
        }
        // 30秒后释放音频流
        this.releaseTimer = setTimeout(async () => {
          if (!this.isRecording) { // 确保此时没有在录制
            await this.audioService.stopProcessing();
            await this.audioService.stopCapture();
          }
          this.releaseTimer = -1;
        }, 30000); // 30秒 = 30000毫秒

      } catch (error) {
        console.error('保存记录失败:', error);
        // 显示错误提示
        promptAction.showToast({
          message: '保存记录失败：' + (error instanceof Error ? error.message : String(error)),
          duration: 3000
        });
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
              .fontColor(this.decibelService.getDecibelColor(this.currentDecibel))
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
          if (this.currentRecord) {
            this.dialogService.showDetailDialog(
              this.getUIContext(),
              wrapBuilder(buildDialog),
              this.currentRecord || null,
              getContext(this) as common.Context
            );
          }
        })

        this.HistoryRecordButton()
      }
      .width('100%')
      .margin({ top: 16, left: 8, right: 8 })
      .backgroundColor(Color.White)
      .borderRadius(24)
      .shadow({ radius: 1, color: '#1A000000', offsetY: 2 })

      // 录音显示
      AudioRecordDisplay({
        isRecordEnabled: this.isRecordEnabled,
        onRecordEnabledChange: (isOn: boolean) => {
          this.isRecordEnabled = isOn;
        }
      })

      // 位置显示
      Column() {
        LocationDisplay()
      }
      .width('100%')
      .padding({
        left: 20,
        right: 20,
        top: 12,
        bottom: 16
      })
      .borderRadius(20)
      .backgroundColor(Color.White)
      .margin({
        top: 2,
        bottom: 16,
        left: 8,
        right: 8
      })
      .shadow({ radius: 1, color: '#1A000000', offsetY: 2 })

      this.StartStopButton()

      Row() {
        BannerCard({
          context: getContext(this) as common.Context,
          adId: 'testw6vs28auh3',
          onItemClick: () => {
            console.info('广告被点击了');
          }
        })
      }
      .height(57)
      .margin({ top: 12, bottom: 12 })
    }
    .width('100%')
    .padding({ top: 8, bottom: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  HistoryRecordButton() {
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

  @Builder
  StartStopButton() {
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
} 