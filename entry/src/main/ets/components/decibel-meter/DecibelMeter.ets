import { DecibelRecordService } from '../../services/DecibelRecordService';
import common from '@ohos.app.ability.common';
import { navigationStack } from '../../constants/ProviderConstant';
import { AppStorageV2, curves, LevelMode, PersistenceV2, promptAction } from '@kit.ArkUI';
import display from '@ohos.display';
import { taskpool } from '@kit.ArkTS';
import { concurrentCalculateSpectrum } from '../../concurrent/ConcurrentFftAnalyzer';
import { secondsToHoursMinutesSecondsWithDecimal } from '../../utils/TimeUtils';
import { ActionPanel } from './ActionPanel';
import { SpectrumChartComponent } from './SpectrumChartComponent';
import { DecibelDisplayComponent } from './DecibelDisplayComponent';
import { DisplayManager } from '../../../../main/ets/utils/DisplayManager';
import { AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DecibelRecord } from '../../models/DecibelRecord';
import { AudioService } from '../../services/AudioService';
import { LocationInfo } from '../../services/LocationService';
import { LocationDisplay } from '../business/LocationDisplay';
import { WeightingType } from '../../constants/WeightingConstants';
import { BusinessError } from '@kit.BasicServicesKit';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { resourceManager } from '@kit.LocalizationKit';
import { image } from '@kit.ImageKit';
import { AppKeys } from '../../models/AppKeys';
import { PermissionService } from '../../services/PermissionService';
import { catchError, delay, filter, from, map, of, Subject, Subscription, switchMap, take, tap } from 'rxjs';

@ComponentV2
export struct DecibelMeter {
  @Param @Require meterOn: boolean = true;
  @Local private isRecording: boolean = false
  @Local private recordingTime: number = 0
  @Local private isDisplayApp: boolean = true
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local startTime: number = 0
  @Local breakPoint: string = '';
  @Local dScale: number = 1; // 页面缩放比例
  @Local translateX: number = 0; // X轴位移
  @Local translateY: number = 0; // Y轴位移
  @Local dOpacity: number = 1; // 页面透明度
  @Local dWidthHeight: string = ''; // 页面透明度
  @Local bgImage: image.PixelMap | undefined = undefined; // 页面透明度
  @Local as: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private currentSpectrum: Float32Array = new Float32Array(); // 当前频谱数据
  @Local private currentAudioBuffer: ArrayBuffer = new ArrayBuffer(0); // 当前音频缓冲区
  @Local private currentLocation: LocationInfo | null = null; // 当前位置信息，从LocationDisplay接收
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  private audioService: AudioService = AudioService.getInstance(getContext() as common.UIAbilityContext)
  private recordService: DecibelRecordService = new DecibelRecordService(getContext() as common.UIAbilityContext)
  private values: number[] = []
  private weightingTypes: WeightingType[] = []
  private currentRecord?: DecibelRecord
  noiseInfoDialog: InfSheet | undefined
  sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  private readonly sampleRate: number = 44100 // 采样率
  private audioBufferSubject = new Subject<void>();
  private durationCheckSubscription?: Subscription;
  private minDecibel: number = 0;
  private maxDecibel: number = 0;
  private avgDecibel: number = 0;

  @Computed
  get fft_size() {
    return AudioPresets.getConfig(this.pk.audio_analysis_mode).fftSize;
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

  aboutToDisappear() {

    // 清理RxJS资源
    this.audioBufferSubject.complete();
    this.stopDurationMonitoring();

    this.audioService.stopProcessing();
    this.audioService.stopCapture();
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

    } catch (error) {
      console.error('[FREQ_TRACE][Screen] 初始化失败:', error);
    }

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
      if (this.pk.record_enabled) {
        this.audioService.startRecording();
      }

      // 启动时长监控
      this.startDurationMonitoring();

      // 开始处理音频数据
      this.audioService.startProcessing((buffer: ArrayBuffer) => {
        // 发出事件通知有新的音频数据到达
        this.audioBufferSubject.next();

        // 更新音频缓冲区数据，供显示组件使用
        this.currentAudioBuffer = buffer.slice(0);

        // 计算频谱数据（用于频谱图显示）
        taskpool.execute<[string, ArrayBuffer,
          WeightingType, number], Float32Array>(concurrentCalculateSpectrum, this.pk.audio_analysis_mode,
          buffer, this.pk.weighting_type, this.pk.calibration_value).then(spectrum => {
          if (this.as.isDisplayApp) {
            this.currentSpectrum = spectrum; // 更新频谱数据
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

  private resetData() {
    // 重置状态
    this.as.db = 0;
    this.values = [];
    this.startTime = new Date().getTime();
    this.recordingTime = 0;
    this.currentAudioBuffer = new ArrayBuffer(0);

    // 重置 weightingTypes 数组
    this.weightingTypes = [];
  }

  private startDurationMonitoring(): void {
    // 停止之前的监控（如果存在）
    this.stopDurationMonitoring();

    this.durationCheckSubscription = this.audioBufferSubject.pipe(
      // 每次音频数据到达时检查时长
      map(() => new Date().getTime() - this.startTime),
      filter(duration => duration > this.MAX_RECORDING_DURATION),
      take(1),
      tap(() => console.info('[自动保存] 达到60分钟录音限制，自动保存并开始新录音')),
      switchMap(() => from(this.stopRecording('自动保存')).pipe(
        catchError((error: BusinessError) => {
          console.error('[自动保存] 停止录音失败:', error);
          return of(null);
        })
      )),
      delay(100),
      tap(() => {
        try {
          this.startRecording();
        } catch (error) {
          console.error('[自动保存] 重新开始录音失败:', error);
        }
      })
    ).subscribe({
      error: (error: BusinessError) => {
        console.error('[自动保存] RxJS监控流错误:', error);
        setTimeout(() => {
          try {
            this.startRecording();
          } catch (e) {
            console.error('[自动保存] 错误恢复失败:', e);
          }
        }, 100);
      }
    });
  }

  private stopDurationMonitoring(): void {
    if (this.durationCheckSubscription) {
      this.durationCheckSubscription.unsubscribe();
      this.durationCheckSubscription = undefined;
    }
  }

  private async stopRecording(comments: string): Promise<void> {
    if (this.isRecording) {
      this.isRecording = false;
      console.info("[FREQ_TRACE][Recording] 停止检测 - 开始");

      // 停止时长监控
      this.stopDurationMonitoring();

      // 如果是自动保存，不显示保存提示
      const isAutoSave = new Date().getTime() - this.startTime >= this.MAX_RECORDING_DURATION;

      try {
        let locationInfo: LocationInfo | null = null;

        if (this.pk.location_enabled) {
          locationInfo = this.currentLocation;
          console.info('[FREQ_TRACE][Location] 位置信息:', locationInfo);
        } else {
          console.info('[FREQ_TRACE][Location] 位置服务已关闭，不保存位置信息');
        }

        // 计算检测时长
        const duration: number = new Date().getTime() - this.startTime;
        console.info('[FREQ_TRACE][Duration] 检测时长:', duration);

        // 停止处理音频数据
        this.audioService.stopProcessing();

        // 如果启用了录音功能，获取并保存音频文件
        let currentAudioFilePath: string = '';

        if (this.pk.record_enabled) {
          try {
            currentAudioFilePath = await this.audioService.stopRecordingAndGetWavData();
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

  }

  build() {
    Stack() {
      GridRow({ columns: 12, breakpoints: { reference: BreakpointsReference.WindowSize }, gutter: 16 }) {

        GridCol({
          span: {
            xs: 12,
            sm: 12,
            md: 5,
          }
        }) {
          // 权限提示组件 - 显示在顶部
          if (!this.as.microphonePermissionGranted) {
            this.smartPermissionPrompt()
          }

        }

        GridCol({
          span: {
            xs: 12,
            sm: 12,
            md: 5,
          }
        }) {
          Column({ space: 8 }) {

            // 使用新的分贝显示组件
            DecibelDisplayComponent({
              audioBuffer: this.currentAudioBuffer,
              audioAnalysisMode: this.pk.audio_analysis_mode,
              weightingType: this.pk.weighting_type,
              calibrationValue: this.pk.calibration_value,
              noiseThreshold: this.pk.noise_threshold,
              noiseAlarmEnabled: this.pk.noise_alarm_enabled,
              minMaxAvg: (min, max, avg) => {
                this.minDecibel = min;
                this.maxDecibel = max;
                this.avgDecibel = avg;
              },
              decibelValue: (decibel, weightingType) => {
                // 收集分贝值和加权类型到数组中
                this.values.push(decibel);
                this.weightingTypes.push(weightingType);
              }
            })

            Text(`${secondsToHoursMinutesSecondsWithDecimal(this.MAX_RECORDING_DURATION -
            this.recordingTime)} 后自动保存`).fontSize(14)

            // 位置显示
            LocationDisplay({
              onLocationUpdate: (locationInfo: LocationInfo | null) => {
                // 更新本地位置状态
                this.currentLocation = locationInfo;
                console.info('[FREQ_TRACE][Location] 位置更新事件接收:', locationInfo);
              }
            })

            if (["md", "lg", "xl", "xxl"].includes(this.breakPoint)) {
              this.actionPanel()
            }
          }
        }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)

        // 频谱图
        GridCol({
          span: {
            xs: 12,
            sm: 12,
            md: 5,
          }
        }) {
          SpectrumChartComponent({
            spectrumData: this.currentSpectrum,
            fftSize: this.fft_size,
            sampleRate: this.sampleRate,
          })
        }

        GridCol({
          span: {
            xs: 12,
            sm: 12,
            md: 0,
          }
        }) {
          this.actionPanel()
        }.visibility(["md", "lg", "xl", "xxl"].includes(this.breakPoint) ? Visibility.Hidden : Visibility.Visible)

      }
      .padding({ top: 16, bottom: 16 })
      .id('mainNoiseMeterDisplayId')
      .onBreakpointChange(breakPoints => {
        // 断点信息现在由 AppStorage 统一管理，这里不再需要处理
        console.info(`[CAT_ANIMATION] GridRow 断点变化: ${breakPoints}`);
      })

      Column()
        .width(this.dWidthHeight)
        .height(this.dWidthHeight)
        .backgroundImage(this.bgImage)
        .scale({ x: this.dScale, y: this.dScale })
        .translate({ x: this.translateX, y: this.translateY })
    }
  }

  @Builder
  smartPermissionPrompt() {
    Row() {
      Image($r('app.media.ic_mic'))
        .width(20)
        .height(20)
        .margin({ right: 8 })

      Column() {
        Text('需要麦克风权限才能检测噪音')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_warning'))

        if (!this.pk.microphone_permission_requested) {
          Text('点击按钮授权')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .margin({ top: 2 })
        } else {
          Text('请在系统设置中开启麦克风权限')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      if (!this.pk.microphone_permission_requested) {
        Button('授权')
          .fontSize(12)
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .onClick(async () => {
            const permissionService = PermissionService.getInstance();
            await permissionService.requestMicrophonePermission();
          })
      } else {
        Button('去设置')
          .fontSize(12)
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .onClick(async () => {
            const permissionService = PermissionService.getInstance();
            await permissionService.openPermissionSettings();
          })
      }
    }
    .padding(12)
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_warning_secondary'))
    .borderRadius(8)
    .margin({ top: 8, left: 16, right: 16 })
  }

  @Builder
  actionPanel() {
    ActionPanel({
      weightingType: this.pk.weighting_type,
      onReset: () => {
        this.audioService.resetData();
        this.resetData();
      },
      onSave: (comments) => {
        this.bgImage = this.getUIContext().getComponentSnapshot().getSync('mainNoiseMeterDisplayId');
        this.stopRecording(comments);
        this.startCollapseAnimation();
      }
    })
  }

  // 启动折叠动画
  startCollapseAnimation() {
    // 获取屏幕尺寸
    const displayClass = display.getDefaultDisplaySync();
    this.dWidthHeight = '100%';
    // 页面内容动画
    this.getUIContext().animateTo({
      duration: 800,
      curve: curves.cubicBezier(0.4, 0.0, 0.2, 1.0),
      onFinish: () => {
        this.dScale = 1;
        this.translateX = 0;
        this.translateY = 0;
        this.bgImage = undefined;
        this.dWidthHeight = '';
        DialogHub.getToast()
          .setTextContent('已保存')
          .setAnimation({
            dialogAnimation: TransitionEffect.scale({ x: 0, y: 0 })
              .combine(TransitionEffect.OPACITY)
              .animation({
                curve: curves.springMotion()
              })
          })
          .setConfig({
            dialogBehavior: { levelMode: LevelMode.EMBEDDED },
            dialogPosition: {
              offset: {
                dx: this.getUIContext().px2vp(displayClass.width) / 2 - 85,
                dy: -this.getUIContext().px2vp(displayClass.height) / 2 + 120
              }
            }
          })
          .build()
          .show();
      }
    }, () => {
      this.dScale = 0.05;
      this.translateX = this.getUIContext().px2vp(displayClass.width) / 2 - 80;
      this.translateY = -this.getUIContext().px2vp(displayClass.height) / 2 + 20;
    });

  }
}
