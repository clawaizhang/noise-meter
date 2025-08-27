import { DecibelService } from '../../services/DecibelService';
import { DecibelRecordService } from '../../services/DecibelRecordService';
import common from '@ohos.app.ability.common';
import { navigationStack } from '../../constants/ProviderConstant';
import { AppStorageV2, promptAction, window } from '@kit.ArkUI';
import display from '@ohos.display';
import { taskpool } from '@kit.ArkTS';
import { concurrentCalculateSpectrum } from '../../concurrent/ConcurrentFftAnalyzer';
import {
  formatStartTime,
  secondsToHoursMinutesSeconds,
  secondsToHoursMinutesSecondsWithDecimal
} from '../../utils/TimeUtils';
import { ActionPanel } from './ActionPanel';
import { VerticalActionPanel } from './VerticalActionPanel';
import { CalibrationIndicator } from './CalibrationIndicator';
import { drawSpectrum, getDbSteps, getFrequencySteps } from './DrawSpectrum';
import { DecibelState } from '../../types/DecibelState';
import { DisplayManager } from '../../../../main/ets/utils/DisplayManager';
import { AudioAnalysisMode, PREF_ANALYSIS_MODE, AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeyConstants } from '../../constants/PreferenceKeyConstants';
import { DecibelRecord } from '../../models/DecibelRecord';
import { AudioService } from '../../services/AudioService';
import { FileService } from '../../services/FileService';
import { LocationService, LocationInfo } from '../../services/LocationService';
import { PreferenceService, PreferenceChangeListener, PreferenceValue } from '../../services/PreferenceService';
import { FFTAnalyzer } from '../../utils/FFTAnalyzer';
import { LocationDisplay } from '../business/LocationDisplay';
import { WeightingType } from '../../constants/WeightingConstants';
import { ResponsiveLayout, Breakpoint, LayoutMode, type WindowChangeListener } from '../../utils/ResponsiveLayout';

// 响应式数值接口定义
interface ResponsiveNumberValues {
  xsmall: number;
  small: number;
  medium: number;
  large: number;
  xlarge: number;
}

// 响应式字符串接口定义
interface ResponsiveStringValues {
  xsmall: string;
  small: string;
  medium: string;
  large: string;
  xlarge: string;
}

@ComponentV2
export struct DecibelMeter {
  // 新增方法：根据分贝值获取对应颜色
  private getDecibelColor(decibel: number): Resource {
    if (decibel >= 85) {
      return $r('app.color.decibel_unbearable');
    }
    if (decibel >= 75) {
      return $r('app.color.decibel_very_noisy');
    }
    if (decibel >= 65) {
      return $r('app.color.decibel_noisy');
    }
    if (decibel >= 55) {
      return $r('app.color.decibel_normal');
    }
    if (decibel >= 45) {
      return $r('app.color.decibel_quiet');
    }
    return $r('app.color.decibel_very_quiet');
  }

  @Param @Require meterOn: boolean = true;
  @Local private decibelState: DecibelState =
    AppStorageV2.connect(DecibelState, 'DecibelState', () => new DecibelState())!;
  @Local private minDecibel: number = 0
  @Local private maxDecibel: number = 0
  @Local private avgDecibel: number = 0
  @Local private showAvgInsteadOfMin: boolean = false
  @Local private isRecording: boolean = false
  @Local private showStats: boolean = false
  @Local private recordingTime: number = 0
  @Local private isRecordEnabled: boolean = false
  @Local private isUILocked: boolean = false // 新增UI锁定状态
  @Local private isLocationEnabled: boolean = false // 位置服务状态
  @Local private canvasWidth: number = 0 // Canvas宽度
  @Local private canvasHeight: number = 0 // Canvas高度
  @Local private calibrationGain: number = 0 // gain
  @Local private weightingType: WeightingType = WeightingType.A // 当前FFT大小
  @Local private currentMode: AudioAnalysisMode = AudioAnalysisMode.FAST_TIME_WEIGHTING // 当前模式
  @Local private currentFftSize: number = 2048 // 当前FFT大小
  @Local private noiseAlarmEnabled: boolean = true; // 是否启用噪音阈值警报
  @Local private noiseThreshold: number = 80; // 设置噪音阈值为80分贝
  @Local private isNoiseAlarm: boolean = false // 是否触发噪音报警
  @Local private isDisplayApp: boolean = true
  @Local startTime: number = 0
  @Local private responsiveLayout: ResponsiveLayout = ResponsiveLayout.getInstance()
  @Local private currentBreakpoint: Breakpoint = Breakpoint.XS
  @Local private currentLayoutMode: LayoutMode = LayoutMode.XSMALL
  @Local private isLandscape: boolean = false // 新增：横屏状态
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  private audioService: AudioService = AudioService.getInstance(getContext() as common.UIAbilityContext)
  private locationService: LocationService = LocationService.getInstance()
  private recordService: DecibelRecordService = new DecibelRecordService(getContext() as common.UIAbilityContext)
  private fileService: FileService = new FileService(getContext() as common.Context)
  private preferenceService: PreferenceService = PreferenceService.getInstance()
  private dbCount: number = 0
  private dbSum: number = 0
  private values: number[] = []
  private weightingTypes: WeightingType[] = []
  private releaseTimer: number = -1
  private currentRecord?: DecibelRecord
  private recordListener?: PreferenceChangeListener
  private responsiveListener?: WindowChangeListener
  // Canvas相关属性

  private ASPECT_RATIO: number = 1.5 // 宽高比改为3:2
  private foldStatus: display.FoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
  private readonly SIDE_MARGIN: number = 16 // 左右边距各16vp
  private readonly sampleRate: number = 44100 // 采样率
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true) // Canvas设置
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings) // Canvas上下文
  private noiseAlarmTimer: number = -1 // 定时器ID用于控制闪烁

  // 更新响应式布局状态
  private updateResponsiveLayout(width: number): void {
    this.currentBreakpoint = this.responsiveLayout.getBreakpoint(width);
    this.currentLayoutMode = this.responsiveLayout.getLayoutMode(this.currentBreakpoint);
    console.info(`[FREQ_TRACE][Responsive] 断点: ${this.currentBreakpoint}, 布局模式: ${this.currentLayoutMode}`);
  }

  // 计算Canvas尺寸（响应式版本）
  private async calculateCanvasDimensions(): Promise<void> {
    try {
      // 获取屏幕信息
      let callback: Callback<display.FoldStatus> = (foldStatus: display.FoldStatus) => {
        this.foldStatus = foldStatus;
      };
      try {
        display.on('foldStatusChange', callback);
      } catch (exception) {
        console.error('Failed to register callback. Code: ' + JSON.stringify(exception));
      }

      // 获取实际可用区域
      const availableArea = await display.getDefaultDisplaySync().getAvailableArea();
      this.foldStatus = display.getFoldStatus();
      const availableWidth = availableArea.width < availableArea.height ? availableArea.width : availableArea.height;
      const availableHeight = availableArea.width < availableArea.height ? availableArea.height : availableArea.width;

      // 更新响应式布局状态
      const availableWidthVp = px2vp(availableWidth);
      const availableHeightVp = px2vp(availableHeight);
      this.updateResponsiveLayout(availableWidthVp);

      // 使用响应式边距
      const responsiveMargin = this.responsiveLayout.getResponsiveValue<number>({
        xsmall: 16,
        small: 20,
        medium: 24,
        large: 28,
        xlarge: 32
      } as ResponsiveNumberValues);

      if (this.isLandscape) {
        // 横屏模式：频谱图占据屏幕大部分高度
        // 计算可用高度（减去边距）
        const availableHeightWithMargin = availableHeightVp - (responsiveMargin as number * 2);
        
        // 横屏模式下频谱图高度应该更大，接近屏幕高度
        this.canvasHeight = availableHeightWithMargin * 0.8; // 占据80%的可用高度
        
        // 根据宽高比计算宽度
        const aspectRatio = 1.5; // 横屏模式下使用更合适的宽高比
        this.canvasWidth = this.canvasHeight * aspectRatio;
        
        // 确保宽度不超过可用宽度
        const maxWidth = availableWidthVp - (responsiveMargin as number * 2);
        if (this.canvasWidth > maxWidth) {
          this.canvasWidth = maxWidth;
          this.canvasHeight = this.canvasWidth / aspectRatio;
        }
      } else {
        // 竖屏模式：保持原有宽高比计算
        this.canvasWidth = availableWidthVp - (responsiveMargin as number * 2);
        
        // 根据布局模式调整宽高比
        switch (this.currentLayoutMode) {
          case LayoutMode.XSMALL:
            this.ASPECT_RATIO = 1.2; // 小屏幕使用更紧凑的比例
            break;
          case LayoutMode.SMALL:
            this.ASPECT_RATIO = 1.5;
            break;
          case LayoutMode.MEDIUM:
            this.ASPECT_RATIO = 1.8;
            break;
          case LayoutMode.LARGE:
            this.ASPECT_RATIO = 2.0;
            break;
          case LayoutMode.XLARGE:
            this.ASPECT_RATIO = 2.2; // 大屏幕使用更宽的比例
            break;
        }
        this.canvasHeight = this.canvasWidth / this.ASPECT_RATIO;
      }

      console.info(`[FREQ_TRACE][Canvas] 响应式Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}, 横屏: ${this.isLandscape}`);
    } catch (error) {
      console.error('[FREQ_TRACE][显示设备信息] 计算Canvas尺寸失败:', error);
    }
  }

  @Monitor('meterOn')
  async onTabIndexChange(monitor: IMonitor) {
    const lastValue = monitor.value<boolean>()?.before;
    const currentValue = monitor.value<boolean>()?.now;
    if (!lastValue && currentValue) {
      // 启动音频采集，带重试机制
      const maxRetries = 3;
      const retryInterval = 1000; // 1秒
      let retryCount = 0;

      while (true) {
        try {
          await this.audioService.startCapture();
          console.info('[FREQ_TRACE][Audio] 音频采集启动成功');
          // 直接开始检测
          this.startRecording();
          break; // 成功则退出循环
        } catch (error) {
          retryCount++;
          console.error(`[FREQ_TRACE][Audio] 音频采集启动失败，重试次数：${retryCount}/${maxRetries}`, error);
          await new Promise<void>(resolve => setTimeout(resolve, retryInterval));
          if (retryCount > maxRetries) {
            // 达到最大重试次数，提示用户
            promptAction.showToast({
              message: error.message,
              duration: 1000
            });
          }
        }
      }
    } else {
      if (lastValue && !currentValue) {
        // 停止音频采集
        this.audioService.stopCapture();
        this.resetData();
      }
    }
  }

  @Builder
  private SpectrumView() {
    Column() {
      // Canvas频谱显示
      Stack({ alignContent: Alignment.TopEnd }) {
        Canvas(this.canvasContext)
          .width(this.canvasWidth)
          .height(this.canvasHeight)
          .backgroundColor($r('app.color.background_primary'))
          .borderRadius(12)
          .shadow({
            radius: 8,
            color: $r('app.color.shadow_medium'),
            offsetX: 2,
            offsetY: 2
          })
          .border({
            width: 1,
            color: $r('app.color.divider_primary')
          })
          .onAreaChange((oldArea: Area, newArea: Area) => {
            console.info(`[FREQ_TRACE][Canvas] Canvas区域变化: 旧尺寸=${oldArea.width}x${oldArea.height}, 新尺寸=${newArea.width}x${newArea.height}`);
            this.canvasWidth = newArea.width as number;
            this.canvasHeight = newArea.height as number;
            console.info(`[FREQ_TRACE][Canvas] 更新后的Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}, 宽高比: ${(this.canvasWidth /
            this.canvasHeight).toFixed(2)}`);
          })
          .onReady(() => {
            // 初始化完成后开始绘制
            const emptySpectrum: Float32Array = new Float32Array(this.currentFftSize * 2);
            if (this.isDisplayApp) {
              this.drawSpectrumLocal(emptySpectrum);
            }
            this.recordingTime = new Date().getTime() - this.startTime;
          })

        // 优化信息标签显示（响应式版本）
        Row() {
          Image($r('app.media.ic_info'))
            .width(this.responsiveLayout.getResponsiveValue<number>({
              xsmall: 12,
              small: 14,
              medium: 16,
              large: 18,
              xlarge: 20
            } as ResponsiveNumberValues))
            .height(this.responsiveLayout.getResponsiveValue<number>({
              xsmall: 12,
              small: 14,
              medium: 16,
              large: 18,
              xlarge: 20
            } as ResponsiveNumberValues))
            .margin({
              right: this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 4,
                small: 5,
                medium: 6,
                large: 7,
                xlarge: 8
              } as ResponsiveNumberValues)
            })
            .fillColor(this.getDecibelColor(this.decibelState.currentDecibel))

          Text(DecibelService.getDecibelDescription(this.decibelState.currentDecibel))
            .fontSize(this.responsiveLayout.getResponsiveValue<number>({
              xsmall: 12,
              small: 13,
              medium: 14,
              large: 15,
              xlarge: 16
            } as ResponsiveNumberValues))
            .fontColor(this.getDecibelColor(this.decibelState.currentDecibel))
            .fontWeight(FontWeight.Medium)
        }
        .padding(this.responsiveLayout.getResponsiveValue<number>({
          xsmall: 6,
          small: 7,
          medium: 8,
          large: 9,
          xlarge: 10
        } as ResponsiveNumberValues))
        .backgroundColor($r('app.color.transparent_white_90'))
        .borderRadius(8)
        .border({
          width: 1,
          color: this.getDecibelColor(this.decibelState.currentDecibel)
        })
        .position({ x: '5%', y: '3%' })
        .onClick(() => {
          this.navStack.pushDestinationByName('NoiseDescriptionDialog', null);
        })

        // 校准指示器
        CalibrationIndicator({ gain: this.calibrationGain, weightingType: this.weightingType })

      }
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

    // 移除ResponsiveLayout的监听器
    if (this.responsiveListener) {
      this.responsiveLayout.removeChangeListener(this.responsiveListener);
    }
  }

  async aboutToAppear() {
    try {
      let displayManager: DisplayManager = DisplayManager.getInstance();
      displayManager.onDisplay(() => {
        this.isDisplayApp = true;
      });
      displayManager.onHidden(() => {
        this.isDisplayApp = false;
      });

      // 使用ResponsiveLayout的统一监听系统
      this.responsiveListener =
        (width: number, height: number, breakpoint: Breakpoint, layoutMode: LayoutMode, isLandscape: boolean) => {
          this.updateResponsiveLayout(width);
          this.isLandscape = isLandscape; // 更新横屏状态
          // 重新计算Canvas尺寸
          this.calculateCanvasDimensions().then(() => {
            console.info(`[FREQ_TRACE][Responsive] 窗口尺寸变化: ${width}x${height}, 横屏: ${isLandscape}, 重新计算Canvas尺寸`);
          });
        };
      this.responsiveLayout.addChangeListener(this.responsiveListener);

      // 初始化位置服务状态
      this.isLocationEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.LOCATION, true);
      if (!this.isLocationEnabled) {
        this.locationService.clearCache();
      } else {
        // 初始化位置信息
        this.locationService.requestSingleLocation();
      }
      this.preferenceService.addChangeListener(PreferenceKeyConstants.LOCATION,
        (key: string, value: PreferenceValue) => {
          if (key === PreferenceKeyConstants.LOCATION && typeof value === 'boolean') {
            this.isLocationEnabled = value;
            if (!value) {
              this.locationService.clearCache();
            } else {
              this.locationService.requestSingleLocation();
            }
          }
        });

      // 获取当前的增益
      this.calibrationGain =
        this.preferenceService.getNumber(PreferenceKeyConstants.CALIBRATION, 0);
      this.preferenceService.addChangeListener(PreferenceKeyConstants.CALIBRATION,
        (key: string, value: PreferenceValue) => {
          if (key === PreferenceKeyConstants.CALIBRATION && typeof value === 'number') {
            this.calibrationGain = value;
          }
        });
      // 获取当前的计权类型
      this.weightingType =
        this.preferenceService.getString(PreferenceKeyConstants.WEIGHTING, WeightingType.A) as WeightingType;
      console.debug('[DecibelService] 当前计权类型:', this.weightingType);
      this.preferenceService.addChangeListener(PreferenceKeyConstants.WEIGHTING,
        (key: string, value: PreferenceValue) => {
          if (key === PreferenceKeyConstants.WEIGHTING && typeof value === 'string') {
            this.weightingType = value as WeightingType;
          }
        });
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
      });
      // 获取屏幕信息并初始化Canvas尺寸
      await this.calculateCanvasDimensions();

      // 初始化横屏状态
      const screenInfo = this.responsiveLayout.getCurrentScreenInfo();
      this.isLandscape = screenInfo.isLandscape;

      console.info(`[FREQ_TRACE][Screen] aboutToAppear - 初始化后的Canvas尺寸: ${this.canvasWidth}x${this.canvasHeight}, 横屏: ${this.isLandscape}`);

      // 读取噪音阈值警报的开关和阈值设置
      this.noiseAlarmEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.NOISE_ALARM_ENABLED, true);
      this.noiseThreshold = this.preferenceService.getNumber(PreferenceKeyConstants.NOISE_THRESHOLD, 80);
      this.preferenceService.addChangeListener(PreferenceKeyConstants.NOISE_ALARM_ENABLED,
        (key: string, value: PreferenceValue) => {
          if (key === PreferenceKeyConstants.NOISE_ALARM_ENABLED && typeof value === 'boolean') {
            this.noiseAlarmEnabled = value;
          }
        });
      this.preferenceService.addChangeListener(PreferenceKeyConstants.NOISE_THRESHOLD,
        (key: string, value: PreferenceValue) => {
          if (key === PreferenceKeyConstants.NOISE_THRESHOLD && typeof value === 'number') {
            this.noiseThreshold = value;
          }
        });

    } catch (error) {
      console.error('[FREQ_TRACE][Screen] 初始化失败:', error);
    }

    // 原有的初始化代码
    // 获取录音开关状态
    this.isRecordEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.RECORD, true);

    // 监听录音开关状态变化
    this.recordListener = (key: string, value: PreferenceValue): void => {
      if (key === PreferenceKeyConstants.RECORD) {
        this.isRecordEnabled = value as boolean;
      }
    };
    this.preferenceService.addChangeListener(PreferenceKeyConstants.RECORD, this.recordListener);

    // 启动音频采集，带重试机制
    const maxRetries = 3;
    const retryInterval = 1000; // 1秒
    let retryCount = 0;

    while (true) {
      try {
        await this.audioService.startCapture();
        console.info('[FREQ_TRACE][Audio] 音频采集启动成功');
        // 直接开始检测
        this.startRecording();
        break; // 成功则退出循环
      } catch (error) {
        retryCount++;
        console.error(`[FREQ_TRACE][Audio] 音频采集启动失败，重试次数：${retryCount}/${maxRetries}`, error);
        await new Promise<void>(resolve => setTimeout(resolve, retryInterval));
        if (retryCount > maxRetries) {
          // 达到最大重试次数，提示用户
          promptAction.showToast({
            message: error.message,
            duration: 1000
          });
        }
      }
    }
  }

  // 最大录音时长1小时(毫秒)
  private readonly MAX_RECORDING_DURATION: number = 60 * 60_000;

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
        undefined, // location
        undefined// audioFilePath
      );

      // 初始化 weightingTypes 数组
      this.weightingTypes = [];

      // 如果启用了录音功能，开始录音
      if (this.isRecordEnabled) {
        this.audioService.startRecording();
      }

      // 开始处理音频数据
      this.audioService.startProcessing((buffer: ArrayBuffer) => {
        // 检查录音时长是否超过限制
        const currentDuration = new Date().getTime() - this.startTime;
        if (currentDuration > this.MAX_RECORDING_DURATION) {
          console.info('[自动保存] 达到5分钟录音限制，自动保存并开始新录音');
          this.stopRecording('自动保存').then(() => {
            // 延迟100ms确保完全停止后再开始新录音
            setTimeout(() => {
              this.startRecording();
            }, 100);
          });
          return;
        }

        taskpool.execute<[string, ArrayBuffer,
          WeightingType, number], Float32Array>(concurrentCalculateSpectrum, this.currentMode,
          buffer, this.weightingType, this.calibrationGain).then(spectrum => {
          const config = AudioPresets.getConfig(this.currentMode as AudioAnalysisMode);
          const db: number = new FFTAnalyzer(config.fftSize, config.windowType, config.smoothingFactor,
            config.overlap).calculateAverageDb(spectrum);

          let decibel = Math.round(db);
          this.values.push(decibel);
          this.weightingTypes.push(this.weightingType)
          if (!this.isUILocked && this.isDisplayApp) {
            this.decibelState.currentDecibel = decibel;
            this.updateStatistics(this.decibelState.currentDecibel);
            this.drawSpectrumLocal(spectrum);
          }
          // 更新计时器（毫秒级）
          this.recordingTime = new Date().getTime() - this.startTime;
        })
      });
    } catch (error) {
      // 如果启动失败，重置状态
      this.isRecording = false;
      this.resetData();
    }
  }

  private drawSpectrumLocal(spectrum: Float32Array) {
    const dbSteps: number[] = getDbSteps();
    const frequencySteps: number[] = getFrequencySteps();
    drawSpectrum(this.canvasContext, this.canvasWidth, this.canvasHeight, spectrum, dbSteps, frequencySteps,
      this.currentFftSize, this.sampleRate, this.getDecibelColor(this.decibelState.currentDecibel));
  }

  private resetData() {
    // 重置状态
    this.decibelState.currentDecibel = 0;
    this.minDecibel = 0;
    this.maxDecibel = 0;
    this.avgDecibel = 0;
    this.dbCount = 0;
    this.dbSum = 0;
    this.values = [];
    this.startTime = new Date().getTime();
    this.recordingTime = 0;

    // 重置 weightingTypes 数组
    this.weightingTypes = [];
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
      if (this.dbCount <= 5 && this.currentMode == AudioAnalysisMode.FAST_TIME_WEIGHTING) {
        this.maxDecibel = this.minDecibel;
        this.values.shift();
        this.values.unshift(this.minDecibel);
      }
      if (this.dbCount <= 10 && this.currentMode == AudioAnalysisMode.IMPULSE_TIME_WEIGHTING) {
        this.maxDecibel = this.minDecibel;
        this.values.shift();
        this.values.unshift(this.minDecibel);
      }
      // 更新平均值
      this.dbSum += value;
      this.dbCount++;
      this.avgDecibel = Math.round(this.dbSum / this.dbCount);

      // 判断是否超过噪音阈值
      if (value > this.noiseThreshold && this.noiseAlarmEnabled) {
        if (this.noiseAlarmTimer === -1) {
          this.noiseAlarmTimer = setInterval(() => {
            this.isNoiseAlarm = !this.isNoiseAlarm;
          }, 300); // 每300毫秒切换一次
        }
      } else {
        clearInterval(this.noiseAlarmTimer);
        this.noiseAlarmTimer = -1;
        this.isNoiseAlarm = false;
      }
    }
  }

  private async stopRecording(comments: string): Promise<void> {
    if (this.isRecording) {
      this.isRecording = false;
      console.info("[FREQ_TRACE][Recording] 停止检测 - 开始");

      // 如果是自动保存，不显示保存提示
      const isAutoSave = new Date().getTime() - this.startTime >= this.MAX_RECORDING_DURATION;

      try {
        let locationInfo: LocationInfo | null = null;

        if (this.isLocationEnabled) {
          locationInfo = this.locationService.getCachedLocation();
          console.info('[FREQ_TRACE][Location] 位置信息:', locationInfo);
        } else {
          // 位置服务关闭时清除缓存
          this.locationService.clearCache();
          console.info('[FREQ_TRACE][Location] 位置服务已关闭，不保存位置信息');
        }

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
          this.currentRecord.weightingTypes = [...this.weightingTypes];
          this.currentRecord.audioFilePath = currentAudioFilePath;
          this.currentRecord.location = locationInfo?.address;
          this.currentRecord.comment = comments;

          // 保存记录
          await this.recordService.saveRecord(this.currentRecord);
          console.info('[FREQ_TRACE][Record] 记录保存成功');

          // 显示详情对话框
          if (isAutoSave) {
            promptAction.showToast({
              message: '自动保存记录成功',
              duration: 3000
            });
          } else {
            this.navStack.pushDestinationByName('DetailDialog', {
              selectedRecord: this.currentRecord,
              context: getContext(this),
              fileService: this.fileService
            });
          }

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

    // 清除闪烁定时器
    if (this.noiseAlarmTimer !== -1) {
      clearInterval(this.noiseAlarmTimer);
      this.noiseAlarmTimer = -1;
      this.isNoiseAlarm = false;
    }
  }

  @Builder
  private LandscapeLayout() {
    Row() {
      // 左侧：频谱图
      Column() {
        this.SpectrumView()
      }
      .width('50%')
      .height('100%')
      .justifyContent(FlexAlign.Center)

      // 中间：分贝显示和位置信息
      Column() {
        // 分贝显示卡片
        Row() {
          Column() {
            Text(this.showAvgInsteadOfMin ? '平均' : '最小')
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 10,
                small: 12,
                medium: 14,
                large: 16,
                xlarge: 18
              } as ResponsiveNumberValues))
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 4 })
            Text(this.showAvgInsteadOfMin ?
              (this.avgDecibel === 0 ? '-' : this.avgDecibel.toString()) :
              (this.minDecibel === 0 ? '-' : this.minDecibel.toString()))
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 24,
                small: 28,
                medium: 32,
                large: 36,
                xlarge: 40
              } as ResponsiveNumberValues))
              .fontWeight(FontWeight.Medium)
              .fontColor(DecibelService.getDecibelColor(
                this.showAvgInsteadOfMin ? this.avgDecibel : this.minDecibel))
              .onClick(() => {
                this.showAvgInsteadOfMin = !this.showAvgInsteadOfMin;
              })
          }
          .alignItems(HorizontalAlign.Center)
          .margin({
            right: this.responsiveLayout.getResponsiveValue<number>({
              xsmall: 8,
              small: 12,
              medium: 16,
              large: 20,
              xlarge: 24
            } as ResponsiveNumberValues)
          })

          Column() {
            Text(this.decibelState.currentDecibel === 0 ? '-' : this.decibelState.currentDecibel.toString())
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 60,
                small: 70,
                medium: 80,
                large: 90,
                xlarge: 100
              } as ResponsiveNumberValues))
              .fontWeight(FontWeight.Bold)
              .fontColor(DecibelService.getDecibelColor(this.decibelState.currentDecibel))
          }
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text('最大')
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 10,
                small: 12,
                medium: 14,
                large: 16,
                xlarge: 18
              } as ResponsiveNumberValues))
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 4 })
            Text(this.maxDecibel === 0 ? '-' : this.maxDecibel.toString())
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 24,
                small: 28,
                medium: 32,
                large: 36,
                xlarge: 40
              } as ResponsiveNumberValues))
              .fontWeight(FontWeight.Medium)
              .fontColor(DecibelService.getDecibelColor(this.maxDecibel))
          }
          .alignItems(HorizontalAlign.Center)
          .margin({
            left: this.responsiveLayout.getResponsiveValue<number>({
              xsmall: 8,
              small: 12,
              medium: 16,
              large: 20,
              xlarge: 24
            } as ResponsiveNumberValues)
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({
          bottom: this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 3,
            small: 4,
            medium: 5,
            large: 6,
            xlarge: 7
          } as ResponsiveNumberValues), top: this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 6,
            small: 8,
            medium: 10,
            large: 12,
            xlarge: 14
          } as ResponsiveNumberValues)
        })
        .borderColor(this.isNoiseAlarm ? DecibelService.getDecibelColor(this.decibelState.currentDecibel) :
        Color.Transparent)

        Row() {
          if (this.isRecording) {
            Text(`${secondsToHoursMinutesSecondsWithDecimal(this.MAX_RECORDING_DURATION -
            this.recordingTime)} 后自动保存`)
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 12,
                small: 14,
                medium: 16,
                large: 18,
                xlarge: 20
              } as ResponsiveNumberValues))
              .fontColor($r('app.color.text_secondary'))
            Text(' | ')
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 12,
                small: 14,
                medium: 16,
                large: 18,
                xlarge: 20
              } as ResponsiveNumberValues))
              .fontColor($r('app.color.text_secondary'))
          }
          Row() {
            Image($r('app.media.ic_info'))
              .width(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 10,
                small: 12,
                medium: 14,
                large: 16,
                xlarge: 18
              } as ResponsiveNumberValues))
              .height(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 10,
                small: 12,
                medium: 14,
                large: 16,
                xlarge: 18
              } as ResponsiveNumberValues))
              .margin({ right: 4 })
              .fillColor(DecibelService.getDecibelColor(this.decibelState.currentDecibel))

            Text(DecibelService.getDecibelLevel(this.decibelState.currentDecibel))
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 12,
                small: 14,
                medium: 16,
                large: 18,
                xlarge: 20
              } as ResponsiveNumberValues))
              .fontColor(DecibelService.getDecibelColor(this.decibelState.currentDecibel))
          }
          .onClick(() => {
            this.navStack.pushPathByName("NoiseLevelDialog", null);
          })
        }

        // 位置显示
        Row() {
          LocationDisplay()
        }
        .width(this.responsiveLayout.getResponsiveValue<string>({
          xsmall: '88%',
          small: '90%',
          medium: '92%',
          large: '94%',
          xlarge: '96%'
        } as ResponsiveStringValues))
        .margin({
          top: this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 8,
            small: 10,
            medium: 12,
            large: 14,
            xlarge: 16
          } as ResponsiveNumberValues),
          bottom: this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 8,
            small: 10,
            medium: 12,
            large: 14,
            xlarge: 16
          } as ResponsiveNumberValues)
        })
      }
      .width('38%')  // 恢复中间区域宽度
      .height('100%')
      .justifyContent(FlexAlign.Center)

      // 右侧：操作按钮 - 横屏模式下使用竖排一列布局
      Column() {
        VerticalActionPanel({
          isUILocked: this.isUILocked,
          weightingType: this.weightingType,
          onReset: () => {
            this.audioService.resetData();
            this.resetData();
          },
          onSave: (comments) => {
            this.stopRecording(comments);
          },
          lockToggle: () => {
            if (this.isUILocked) {
              promptAction.showToast({
                message: '已解锁',
                duration: 2000
              });
            } else {
              promptAction.showToast({
                message: '已锁定,持续检测中...',
                duration: 2000
              });
            }
            this.isUILocked = !this.isUILocked;
          },
          // 修改：将onToggleWeighting的参数类型改为WeightingType
          onToggleWeighting: (weightingType: WeightingType) => {
            this.weightingType = weightingType;
            // 弹出提示框显示当前频率加权方式
            promptAction.showToast({
              bottom: '53%',
              message: `频率加权: ${this.weightingType} 计权`,
              duration: 2000
            });
            this.preferenceService.setString(PreferenceKeyConstants.WEIGHTING, this.weightingType);
          }
        })
      }
      .width('12%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  build() {
    // 根据横屏状态选择布局
    if (this.isLandscape) {
      this.LandscapeLayout()
    } else {
      Column() {
        // 频谱显示
        this.SpectrumView()

        // 分贝显示卡片
        Row() {
          Column() {
            Text(this.showAvgInsteadOfMin ? '平均' : '最小')
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 10,
                small: 12,
                medium: 14,
                large: 16,
                xlarge: 18
              } as ResponsiveNumberValues))
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 4 })
            Text(this.showAvgInsteadOfMin ?
              (this.avgDecibel === 0 ? '-' : this.avgDecibel.toString()) :
              (this.minDecibel === 0 ? '-' : this.minDecibel.toString()))
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 24,
                small: 28,
                medium: 32,
                large: 36,
                xlarge: 40
              } as ResponsiveNumberValues))
              .fontWeight(FontWeight.Medium)
              .fontColor(DecibelService.getDecibelColor(
                this.showAvgInsteadOfMin ? this.avgDecibel : this.minDecibel))
              .onClick(() => {
                this.showAvgInsteadOfMin = !this.showAvgInsteadOfMin;
              })
          }
          .alignItems(HorizontalAlign.Center)
          .margin({
            right: this.responsiveLayout.getResponsiveValue<number>({
              xsmall: 8,
              small: 12,
              medium: 16,
              large: 20,
              xlarge: 24
            } as ResponsiveNumberValues)
          })

          Column() {
            Text(this.decibelState.currentDecibel === 0 ? '-' : this.decibelState.currentDecibel.toString())
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 60,
                small: 70,
                medium: 80,
                large: 90,
                xlarge: 100
              } as ResponsiveNumberValues))
              .fontWeight(FontWeight.Bold)
              .fontColor(DecibelService.getDecibelColor(this.decibelState.currentDecibel))
          }
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text('最大')
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 10,
                small: 12,
                medium: 14,
                large: 16,
                xlarge: 18
              } as ResponsiveNumberValues))
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 4 })
            Text(this.maxDecibel === 0 ? '-' : this.maxDecibel.toString())
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 24,
                small: 28,
                medium: 32,
                large: 36,
                xlarge: 40
              } as ResponsiveNumberValues))
              .fontWeight(FontWeight.Medium)
              .fontColor(DecibelService.getDecibelColor(this.maxDecibel))
          }
          .alignItems(HorizontalAlign.Center)
          .margin({
            left: this.responsiveLayout.getResponsiveValue<number>({
              xsmall: 8,
              small: 12,
              medium: 16,
              large: 20,
              xlarge: 24
            } as ResponsiveNumberValues)
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({
          bottom: this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 3,
            small: 4,
            medium: 5,
            large: 6,
            xlarge: 7
          } as ResponsiveNumberValues), top: this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 6,
            small: 8,
            medium: 10,
            large: 12,
            xlarge: 14
          } as ResponsiveNumberValues)
        })
        .borderColor(this.isNoiseAlarm ? DecibelService.getDecibelColor(this.decibelState.currentDecibel) :
        Color.Transparent)

        Row() {
          if (this.isRecording) {
            Text(`${secondsToHoursMinutesSecondsWithDecimal(this.MAX_RECORDING_DURATION -
            this.recordingTime)} 后自动保存`)
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 12,
                small: 14,
                medium: 16,
                large: 18,
                xlarge: 20
              } as ResponsiveNumberValues))
              .fontColor($r('app.color.text_secondary'))
            Text(' | ')
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 12,
                small: 14,
                medium: 16,
                large: 18,
                xlarge: 20
              } as ResponsiveNumberValues))
              .fontColor($r('app.color.text_secondary'))
          }
          Row() {
            Image($r('app.media.ic_info'))
              .width(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 10,
                small: 12,
                medium: 14,
                large: 16,
                xlarge: 18
              } as ResponsiveNumberValues))
              .height(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 10,
                small: 12,
                medium: 14,
                large: 16,
                xlarge: 18
              } as ResponsiveNumberValues))
              .margin({ right: 4 })
              .fillColor(DecibelService.getDecibelColor(this.decibelState.currentDecibel))

            Text(DecibelService.getDecibelLevel(this.decibelState.currentDecibel))
              .fontSize(this.responsiveLayout.getResponsiveValue<number>({
                xsmall: 12,
                small: 14,
                medium: 16,
                large: 18,
                xlarge: 20
              } as ResponsiveNumberValues))
              .fontColor(DecibelService.getDecibelColor(this.decibelState.currentDecibel))
          }
          .onClick(() => {
            this.navStack.pushPathByName("NoiseLevelDialog", null);
          })
        }

        // 位置显示
        Row() {
          LocationDisplay()
        }
        .width(this.responsiveLayout.getResponsiveValue<string>({
          xsmall: '88%',
          small: '90%',
          medium: '92%',
          large: '94%',
          xlarge: '96%'
        } as ResponsiveStringValues))
        .margin({
          top: this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 8,
            small: 10,
            medium: 12,
            large: 14,
            xlarge: 16
          } as ResponsiveNumberValues),
          bottom: this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 8,
            small: 10,
            medium: 12,
            large: 14,
            xlarge: 16
          } as ResponsiveNumberValues)
        })

        ActionPanel({
          isUILocked: this.isUILocked,
          weightingType: this.weightingType,
          onReset: () => {
            this.audioService.resetData();
            this.resetData();
          },
          onSave: (comments) => {
            this.stopRecording(comments);
          },
          lockToggle: () => {
            if (this.isUILocked) {
              promptAction.showToast({
                message: '已解锁',
                duration: 2000
              });
            } else {
              promptAction.showToast({
                message: '已锁定,持续检测中...',
                duration: 2000
              });
            }
            this.isUILocked = !this.isUILocked;
          },
          // 修改：将onToggleWeighting的参数类型改为WeightingType
          onToggleWeighting: (weightingType: WeightingType) => {
            this.weightingType = weightingType;
            // 弹出提示框显示当前频率加权方式
            promptAction.showToast({
              bottom: '53%',
              message: `频率加权: ${this.weightingType} 计权`,
              duration: 2000
            });
            this.preferenceService.setString(PreferenceKeyConstants.WEIGHTING, this.weightingType);
          }
        })
      }
      .width('100%')
      .padding({
        top: this.responsiveLayout.getResponsiveValue<number>({
          xsmall: 8,
          small: 10,
          medium: 12,
          large: 14,
          xlarge: 16
        } as ResponsiveNumberValues),
        bottom: this.responsiveLayout.getResponsiveValue<number>({
          xsmall: 8,
          small: 10,
          medium: 12,
          large: 14,
          xlarge: 16
        } as ResponsiveNumberValues)
      })
      .alignItems(HorizontalAlign.Center)
    }
  }
}