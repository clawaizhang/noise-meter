import { AudioService } from '../../../../library/ets/services/AudioService';
import { DecibelService } from '../../services/DecibelService';
import { LocationService } from '../../../../library/ets/services/LocationService';
import { DecibelRecord } from '../../../../library/ets/models/DecibelRecord';
import { DecibelRecordService } from '../../services/DecibelRecordService';
import { LocationDisplay } from '../../../../library/ets/components/business/LocationDisplay'
import common from '@ohos.app.ability.common';
import { FileService } from '../../../../library/ets/services/FileService';
import { noiseMeterNavStack } from '../../constant/ProviderConstant';
import { promptAction } from '@kit.ArkUI';
import {
  PreferenceService,
  PreferenceChangeListener,
  PreferenceValue
} from '../../../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../../../library/ets/constants/PreferenceKeyConstants';
import type { BusinessError } from '@ohos.base';
import display from '@ohos.display';
import { AudioAnalysisMode, AudioPresets, PREF_ANALYSIS_MODE } from '../../../../library/ets/common/AudioConfig';
import { FFTAnalyzer } from '../../../../library/ets/utils/FFTAnalyzer'; // 导入 FFTAnalyzer
import { WeightingType } from '../../../../library/ets/constants/WeightingConstants';
import { taskpool } from '@kit.ArkTS';
import { concurrentCalculateSpectrum } from '../../concurrent/ConcurrentFftAnalyzer';
import { secondsToHoursMinutesSeconds } from '../../util/TimeUtils';
import { DecibelMeterResetSaveButton } from './ResetSaveButtonBuilder';
import { CalibrationIndicator } from './CalibrationIndicator';
import { drawSpectrum, getDbSteps, getFrequencySteps } from './DrawSpectrum';

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
  @Local private canvasWidth: number = 0 // Canvas宽度
  @Local private canvasHeight: number = 0 // Canvas高度
  @Local private calibrationGain: number = 0 // gain
  @Local private weightingType: WeightingType = WeightingType.A // 当前FFT大小
  @Local private currentMode: AudioAnalysisMode = AudioAnalysisMode.BALANCED // 当前FFT大小
  @Local private currentFftSize: number = 2048 // 当前FFT大小
  @Consumer(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack()
  private decibelService: DecibelService = new DecibelService()
  private audioService: AudioService = AudioService.getInstance(getContext() as common.UIAbilityContext)
  private locationService: LocationService = LocationService.getInstance()
  private recordService: DecibelRecordService = new DecibelRecordService(getContext() as common.UIAbilityContext)
  private fileService: FileService = new FileService(getContext() as common.Context)
  private preferenceService: PreferenceService = PreferenceService.getInstance()
  private dbCount: number = 0
  private dbSum: number = 0
  private values: number[] = []
  private startTime: number = 0
  private releaseTimer: number = -1
  private currentRecord?: DecibelRecord
  private recordListener?: PreferenceChangeListener
  // Canvas相关属性

  private readonly ASPECT_RATIO: number = 1.5 // 宽高比改为3:2
  private readonly SIDE_MARGIN: number = 16 // 左右边距各16vp
  private readonly sampleRate: number = 44100 // 采样率
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true) // Canvas设置
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings) // Canvas上下文

  // 计算Canvas尺寸
  private async calculateCanvasDimensions(): Promise<void> {
    try {
      // 获取屏幕信息
      // 获取实际可用区域
      const availableArea = await display.getDefaultDisplaySync().getAvailableArea();
      // 先把可用区域的像素转换为vp
      const availableWidthVp = px2vp(availableArea.width);
      // 然后用vp单位进行计算
      this.canvasWidth = availableWidthVp - (this.SIDE_MARGIN * 2);
      this.canvasHeight = this.canvasWidth / this.ASPECT_RATIO;
    } catch (error) {
      console.error('[FREQ_TRACE][显示设备信息] 计算Canvas尺寸失败:', error);
    }
  }

  @Builder
  private SpectrumView() {
    Column() {
      // Canvas频谱显示
      Canvas(this.canvasContext)
        .width(this.canvasWidth)
        .height(this.canvasHeight)
        .backgroundColor('#000000')
        .borderRadius(12)
        .onAreaChange((oldArea: Area, newArea: Area) => {
          console.info(`[FREQ_TRACE][Canvas] Canvas区域变化: 旧尺寸=${oldArea.width}x${oldArea.height}, 新尺寸=${newArea.width}x${newArea.height}`);
          this.canvasWidth = newArea.width as number;
          this.canvasHeight = newArea.height as number;
          console.info(`[FREQ_TRACE][Canvas] 更新后的Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}, 宽高比: ${(this.canvasWidth /
          this.canvasHeight).toFixed(2)}`);
        })
        .onReady(() => {
          // 初始化完成后开始绘制
          // 创建一个空的 Float32Array 用于初始化显示
          const emptySpectrum: Float32Array = new Float32Array(this.currentFftSize * 2); // 每个点用2字节表示
          this.drawSpectrumLocal(emptySpectrum);
        })
    }
  }

  aboutToDisappear() {
    // 原有的清理代码
    if (this.recordListener) {
      this.preferenceService.removeChangeListener(PreferenceKeyConstants.RECORD, this.recordListener);
    }
    if (this.releaseTimer !== -1) {
      clearTimeout(this.releaseTimer);
      this.releaseTimer = -1;
    }
    this.audioService.stopProcessing();
    this.audioService.stopCapture();
  }

  async aboutToAppear() {
    try {
      // 获取当前的增益
      this.calibrationGain =
        this.preferenceService.getNumber(PreferenceKeyConstants.CALIBRATION, 0);
      this.preferenceService.addChangeListener(PreferenceKeyConstants.CALIBRATION,
        (key: string, value: PreferenceValue) => {
          if (key === PreferenceKeyConstants.CALIBRATION && typeof value === 'number') {
            this.calibrationGain = value;
          }
        })
      // 获取当前的计权类型
      this.weightingType =
        this.preferenceService.getString(PreferenceKeyConstants.WEIGHTING, WeightingType.A) as WeightingType;
      console.debug('[DecibelService] 当前计权类型:', this.weightingType);
      this.preferenceService.addChangeListener(PreferenceKeyConstants.WEIGHTING,
        (key: string, value: PreferenceValue) => {
          if (key === PreferenceKeyConstants.WEIGHTING && typeof value === 'string') {
            this.weightingType = value as WeightingType;
          }
        })
      //获取fftSize
      // 获取当前分析模式和FFT大小
      this.currentMode = this.preferenceService.getString(PREF_ANALYSIS_MODE, 'default') as AudioAnalysisMode;
      this.currentFftSize = AudioPresets.getConfig(this.currentMode).fftSize;
      console.info(`[FREQ_TRACE][FFT] 当前模式: ${this.currentMode}, FFT大小: ${this.currentFftSize}`);
      this.preferenceService.addChangeListener(PREF_ANALYSIS_MODE, (key: string, value: PreferenceValue) => {
        if (key === PREF_ANALYSIS_MODE && typeof value === 'string') {
          this.currentMode = value as AudioAnalysisMode;
          this.currentFftSize = AudioPresets.getConfig(this.currentMode).fftSize;
        }
      })
      // 获取屏幕信息并初始化Canvas尺寸
      await this.calculateCanvasDimensions();
      console.info(`[FREQ_TRACE][Screen] aboutToAppear - 初始化后的Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}`);
    } catch (error) {
      console.error('[FREQ_TRACE][Screen] 初始化失败:', error);
    }

    // 原有的初始化代码
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
      console.info('[FREQ_TRACE][Audio] 音频采集启动成功');
      // 直接开始检测
      this.startRecording();
    }).catch((error: BusinessError) => {
      console.error('[FREQ_TRACE][Audio] 音频采集启动失败:', error);
    });
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
        undefined// audioFilePath
      );

      // 如果启用了录音功能，开始录音
      if (this.isRecordEnabled) {
        this.audioService.startRecording();
      }

      // 开始处理音频数据
      this.audioService.startProcessing((buffer: ArrayBuffer) => {
        taskpool.execute<[string, ArrayBuffer,
          WeightingType, number], Float32Array>(concurrentCalculateSpectrum, this.currentMode,
          buffer, this.weightingType, this.calibrationGain).then(spectrum => {
          const config = AudioPresets.getConfig(this.currentMode as AudioAnalysisMode);
          const db: number = new FFTAnalyzer(config.fftSize, config.windowType, config.smoothingFactor,
            config.overlap).calculateAverageDb(spectrum);
          this.currentDecibel = Math.round(db);
          this.values.push(this.currentDecibel);
          this.updateStatistics(this.currentDecibel);
          this.drawSpectrumLocal(spectrum);
        })
      });
    } catch (error) {
      // 如果启动失败，重置状态
      this.isRecording = false;
      this.resetData();
    }
  }

  private drawSpectrumLocal(spectrum: Float32Array) {
    let isLowFreqMode = this.currentMode === AudioAnalysisMode.LOW_FREQUENCY;
    console.info(`[频谱绘制] 当前模式=${isLowFreqMode ? '低频' : '全频'}`);
    // 分贝网格点生成
    const dbSteps: number[] = getDbSteps(isLowFreqMode);
    const frequencySteps: number[] = getFrequencySteps(isLowFreqMode);
    drawSpectrum(this.canvasContext, this.canvasWidth, this.canvasHeight, spectrum, dbSteps, frequencySteps,
      this.currentFftSize, this.sampleRate);
    // 更新计时器
    this.recordingTime = Math.floor((new Date().getTime() - this.startTime) / 1000);
  }

  private resetData() {
    // 重置状态
    this.currentDecibel = 0;
    this.minDecibel = 0;
    this.maxDecibel = 0;
    this.avgDecibel = 0;
    this.dbCount = 0;
    this.dbSum = 0;
    this.values = [];
    this.startTime = new Date().getTime();
    this.recordingTime = 0;
  }

  private async stopRecording() {
    if (this.isRecording) {
      this.isRecording = false;
      console.info("[FREQ_TRACE][Recording] 停止检测 - 开始");

      try {
        // 获取缓存的位置信息
        const locationInfo = this.locationService.getCachedLocation();
        console.info('[FREQ_TRACE][Location] 位置信息:', locationInfo);

        // 计算检测时长
        const duration: number = new Date().getTime() - this.startTime;
        console.info('[FREQ_TRACE][Duration] 检测时长:', duration);

        // 停止处理音频数据
        this.audioService.stopProcessing();

        // 如果启用了录音功能，获取并保存音频文件
        let currentAudioFilePath: string = '';
        if (this.isRecordEnabled) {
          try {
            currentAudioFilePath = await this.audioService.stopRecordingAndGetWavData(this.fileService);
          } catch (error) {
            console.error('[FREQ_TRACE][Audio] 获取或保存WAV音频数据失败:', error);
          }
        }

        console.info('[FREQ_TRACE][Record] 准备创建记录');
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
          console.info('[FREQ_TRACE][Record] 记录保存成功');

          // 显示详情对话框
          this.navStack.pushDestinationByName('DetailDialog', {
            selectedRecord: this.currentRecord,
            context: getContext(this),
            fileService: this.fileService
          });
        }

        // 重置状态
        this.resetData();

        // 自动开始新的检测
        setTimeout(() => {
          this.startRecording();
        }, 500); // 延迟500ms后开始新的检测

      } catch (error) {
        console.error('[FREQ_TRACE][Record] 保存记录失败:', error);
        // 显示错误提示
        promptAction.showToast({
          message: '保存记录失败：' + (error instanceof Error ? error.message : String(error)),
          duration: 3000
        });
        // 即使保存失败也开始新的检测
        setTimeout(() => {
          this.startRecording();
        }, 500);
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

  build() {
    Column() {
      // 频谱显示
      this.SpectrumView()

      // 分贝显示卡片
      Stack({ alignContent: Alignment.TopEnd }) {
        Column() {
          // 分贝值显示
          Row() {
            Column() {
              Text('最小')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ bottom: 4 })
              Text(this.minDecibel === 0 ? '-' : this.minDecibel.toString())
                .fontSize(32)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.decibelService.getDecibelColor(this.minDecibel))
            }
            .alignItems(HorizontalAlign.Center)
            .margin({ right: 32 })

            Column() {
              Text(this.currentDecibel === 0 ? '-' : this.currentDecibel.toString())
                .fontSize(80)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.decibelService.getDecibelColor(this.currentDecibel))
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
                  Text(' | ')
                    .fontSize(14)
                    .fontColor('#666666')
                  Text(secondsToHoursMinutesSeconds(this.recordingTime))
                    .fontSize(14)
                    .fontColor('#666666')
                  Text(' | ')
                    .fontSize(14)
                    .fontColor('#666666')
                }
                Text(this.decibelService.getDecibelLevel(this.currentDecibel))
                  .fontSize(14)
                  .fontColor(this.decibelService.getDecibelColor(this.currentDecibel))
              }
              .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text('最大')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ bottom: 4 })
              Text(this.maxDecibel === 0 ? '-' : this.maxDecibel.toString())
                .fontSize(32)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.decibelService.getDecibelColor(this.maxDecibel))
            }
            .alignItems(HorizontalAlign.Center)
            .margin({ left: 32 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .margin({ top: 20, bottom: 20 })
        }
        .width('100%')
        .padding({
          top: 20,
          bottom: 20,
          left: 16,
          right: 16
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

        // 新增的校准指示器
        CalibrationIndicator(this.calibrationGain)
      }
      .width('100%')
      .margin({ left: 8, right: 8, top: 24 })
      .backgroundColor(Color.White)
      .borderRadius(12)
      .shadow({ radius: 2, color: '#1A000000', offsetY: 2 })

      // 位置显示
      Row() {
        LocationDisplay()
      }
      .width('92%')
      .margin({ top: 16, bottom: 16 })

      DecibelMeterResetSaveButton(() => {
        // 重置音频数据和统计信息
        this.audioService.resetData();
        this.resetData();
      }, () => {
        this.stopRecording();
      });
    }
    .width('100%')
    .padding({ top: 8, bottom: 16 })
    .alignItems(HorizontalAlign.Center)
  }
}
