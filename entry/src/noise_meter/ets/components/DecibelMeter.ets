import { AudioService } from '../../../library/ets/services/AudioService';
import { DecibelService } from '../services/DecibelService';
import { LocationService } from '../../../library/ets/services/LocationService';
import { DecibelRecord } from '../../../library/ets/models/DecibelRecord';
import { DecibelRecordService } from '../services/DecibelRecordService';
import { LocationDisplay } from '../../../library/ets/components/business/LocationDisplay'
import common from '@ohos.app.ability.common';
import { BannerCard } from '../../../library/ets/components/business/BannerCard';
import { FileService } from '../../../library/ets/services/FileService';
import { noiseMeterNavStack } from '../constant/ProviderConstant';
import { promptAction } from '@kit.ArkUI';
import { PreferenceService, PreferenceChangeListener, PreferenceValue } from '../../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';
import { FrequencyWeighting } from '../../../library/ets/utils/FrequencyWeighting';
import type { BusinessError } from '@ohos.base';

@ComponentV2
export struct DecibelMeter {
  @Local private currentDecibel: number = 0
  @Local private minDecibel: number = 0
  @Local private maxDecibel: number = 0
  @Local private avgDecibel: number = 0
  @Local private isRecording: boolean = false
  @Local private showStats: boolean = false
  @Local private recordingTime: number = 0
  @Local private isRecordEnabled: boolean = false
  @Local private displayBars: Array<number> = new Array(64).fill(2)
  @Local private debugText: string = ''
  private spectrumData: Float32Array = new Float32Array(1024)
  @Consumer(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack()
  private decibelService: DecibelService = new DecibelService()
  private audioService: AudioService = new AudioService(getContext() as common.UIAbilityContext)
  private locationService: LocationService = LocationService.getInstance()
  private recordService: DecibelRecordService = new DecibelRecordService(getContext() as common.UIAbilityContext)
  private fileService: FileService = new FileService(getContext() as common.Context)
  private preferenceService: PreferenceService = PreferenceService.getInstance()
  private dbCount: number = 0
  private dbSum: number = 0
  private context?: common.UIAbilityContext
  private values: number[] = []
  private startTime: number = 0
  private releaseTimer: number = -1
  private currentRecord?: DecibelRecord
  private recordListener?: PreferenceChangeListener

  aboutToAppear() {
    // 如果提供了外部context，重新初始化AudioService
    if (this.context) {
      this.audioService = new AudioService(this.context);
    }
    // 获取录音开关状态
    this.isRecordEnabled = this.preferenceService.isEnabled(PreferenceKeyConstants.RECORD);

    // 监听录音开关状态变化
    this.recordListener = (key: string, value: PreferenceValue): void => {
      if (key === PreferenceKeyConstants.RECORD) {
        this.isRecordEnabled = value as boolean;
      }
    };
    this.preferenceService.addChangeListener(PreferenceKeyConstants.RECORD, this.recordListener);

    // 启动音频采集
    this.audioService.startCapture().then(() => {
      console.info('[DecibelMeter] 音频采集启动成功');
      this.startAnalyzing();
    }).catch((error: BusinessError) => {
      console.error('[DecibelMeter] 音频采集启动失败:', error);
    });
  }

  aboutToDisappear() {
    // 移除监听器
    if (this.recordListener) {
      this.preferenceService.removeChangeListener(PreferenceKeyConstants.RECORD, this.recordListener);
    }
    // 清除定时器
    if (this.releaseTimer !== -1) {
      clearTimeout(this.releaseTimer);
      this.releaseTimer = -1;
    }
    // 停止所有音频相关操作
    this.audioService.stopProcessing();
    this.audioService.stopCapture();
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

      // 如果启用了录音功能，开始录音
      if (this.isRecordEnabled) {
        this.audioService.startRecording();
      }

      // 开始处理音频数据，记录分贝值
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
      // 如果启动失败，重置状态
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
      console.info('停止检测 - 开始');

      try {
        // 获取缓存的位置信息
        const locationInfo = this.locationService.getCachedLocation();
        console.info('位置信息:', locationInfo);
        
        // 计算检测时长
        const duration = new Date().getTime() - this.startTime;
        console.info('检测时长:', duration);

        // 停止处理音频数据
        this.audioService.stopProcessing();

        // 如果启用了录音功能，获取并保存音频文件
        let currentAudioFilePath = '';
        if (this.isRecordEnabled) {
          try {
            currentAudioFilePath = await this.audioService.stopRecordingAndGetWavData(this.fileService);
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
          this.currentRecord.audioFilePath = currentAudioFilePath;

          // 保存记录
          await this.recordService.saveRecord(this.currentRecord);
          console.info('记录保存成功');

          // 显示详情对话框
          this.navStack.pushDestinationByName('DetailDialog', {
            selectedRecord: this.currentRecord,
            context: getContext(this),
            fileService: this.fileService
          });
        }

        // 重置状态
        this.currentDecibel = 0;
        this.minDecibel = 0;
        this.maxDecibel = 0;
        this.avgDecibel = 0;
        this.dbCount = 0;
        this.dbSum = 0;
        this.values = [];
        this.startTime = 0;
        this.recordingTime = 0;
        this.showStats = false;

        // 重新开始分析音频数据
        this.startAnalyzing();

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

  @Builder
  private SpectrumView() {
    Column() {
      // 频谱显示
      Row() {
        ForEach(this.displayBars, (height: number, index: number) => {
          Column() {
            Column()
              .width('100%')
              .height(`${height}%`)
              .backgroundColor('#2196F3')
              .borderRadius(1)
              .animation({
                duration: 50,
                curve: Curve.Linear
              })
          }
          .width('1.2%')  // 64个频谱条，每个占总宽度的1.2%
          .height('100%')
          .justifyContent(FlexAlign.End)
        }, (item: number) => item.toString() + new Date().getTime())
      }
      .width('100%')
      .height(120)
      .backgroundColor('#000000')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(12)
      .justifyContent(FlexAlign.SpaceBetween)
      
      // 频率刻度
      Row() {
        ForEach([0, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000], (freq: number) => {
          Text(freq === 0 ? '0' : freq >= 1000 ? `${freq/1000}k` : freq.toString())
            .fontSize(10)
            .fontColor('#999999')
            .textAlign(TextAlign.Center)
            .width('10%')
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 4 })
      
      // 调试信息显示
      Text(this.debugText)
        .fontSize(12)
        .fontColor('#666666')
        .backgroundColor('#F5F5F5')
        .padding(8)
        .margin({ top: 8 })
        .borderRadius(8)
        .textAlign(TextAlign.Start)
        .width('100%')
        .maxLines(5)
    }
  }

  build() {
    Column() {
      // 频谱显示
      this.SpectrumView()

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
            this.navStack.pushDestinationByName('DetailDialog', {
              selectedRecord: this.currentRecord,
              context: getContext(this),
              fileService: this.fileService
            });
          }
        })
      }
      .width('100%')
      .margin({ left: 8, right: 8 })
      .backgroundColor(Color.White)
      .borderRadius(24)
      .shadow({ radius: 1, color: '#1A000000', offsetY: 2 })

      // 位置显示
      Row() {
        LocationDisplay()
      }
      .width('92%')
      .margin({ top: 16, bottom: 16 })

      this.StartStopButton()
    }
    .width('100%')
    .padding({ top: 8, bottom: 16 })
    .alignItems(HorizontalAlign.Center)
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

  private startAnalyzing() {
    console.info('[startAnalyzing] 开始音频分析');
    this.audioService.startProcessing((buffer: ArrayBuffer) => {
      // 计算分贝值
      const db = this.decibelService.calculateDecibel(buffer, buffer.byteLength);
      
      if (db > 0) {
        this.currentDecibel = Math.round(db);
      } else {
        this.currentDecibel = 0;
      }
      
      // 获取频谱数据
      const rawSpectrum = FrequencyWeighting.getSpectrumData(buffer);
      
      // 设置显示参数
      const maxDisplayDb = 90;    // 最大显示分贝值
      const minDisplayDb = 20;    // 最小显示分贝值
      const displayRange = maxDisplayDb - minDisplayDb;
      const maxHeight = 100;      // 最大高度百分比
      const minHeight = 2;        // 最小高度百分比
      const heightRange = maxHeight - minHeight;
      
      // 定义频率点
      const sampleRate = 44100;   // 采样率
      const fftSize = this.audioService.getCurrentFFTSize();  // 通过公共方法获取 FFT 大小
      const minFreq = 20;         // 最小频率 20Hz
      const maxFreq = 20000;      // 最大频率 20kHz
      
      // 计算频谱高度
      const newDisplayBars = new Array<number>(64);
      let maxValue = -Infinity;
      let maxIndex = -1;
      let peakFreq = 0;
      
      // 对每个频率点计算对应的能量
      for (let i = 0; i < 64; i++) {
        // 使用对数分布计算当前频率
        const freq = minFreq * Math.pow(maxFreq / minFreq, i / 63);  // 20Hz到20kHz的对数分布
        // 计算对应的FFT bin索引
        const binIndex = Math.floor(freq * fftSize / sampleRate);
        
        // 获取邻近bin的平均值
        let sum = 0;
        let count = 0;
        const binWidth = 3;  // 考虑邻近的bin数量
        
        for (let j = -binWidth; j <= binWidth; j++) {
          const index = Math.min(rawSpectrum.length - 1, Math.max(0, binIndex + j));
          const value = rawSpectrum[index];
          if (isFinite(value)) {
            sum += value;
            count++;
            // 记录最大值
            if (value > maxValue) {
              maxValue = value;
              maxIndex = index;
              peakFreq = freq;
            }
          }
        }
        
        // 计算平均值并映射到显示高度
        if (count > 0) {
          const avgDb = sum / count;
          if (avgDb > minDisplayDb) {
            const dbValue = Math.min(maxDisplayDb, Math.max(minDisplayDb, avgDb));
            const normalizedValue = (dbValue - minDisplayDb) / displayRange;
            newDisplayBars[i] = minHeight + heightRange * normalizedValue;
          } else {
            // 对于低于最小分贝值的频段，添加小的随机波动
            newDisplayBars[i] = minHeight + Math.random() * 2;
          }
        } else {
          // 对于无效数据的频段，添加小的随机波动
          newDisplayBars[i] = minHeight + Math.random() * 2;
        }
      }
      
      // 更新显示数据
      for (let i = 0; i < 64; i++) {
        this.displayBars[i] = newDisplayBars[i];
      }
      
      // 更新调试信息
      const debugInfo = `当前分贝: ${this.currentDecibel}dB\n` +
        `最大频率: ${peakFreq.toFixed(1)}Hz (${maxValue.toFixed(1)}dB)\n` +
        `频谱范围: ${minDisplayDb}dB ~ ${maxDisplayDb}dB\n` +
        `高度范围: ${minHeight}% ~ ${maxHeight}%\n` +
        `FFT大小: ${fftSize}, 频谱长度: ${rawSpectrum.length}`;
      
      this.debugText = debugInfo;
    });
  }
} 