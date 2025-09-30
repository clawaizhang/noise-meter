import { DecibelService } from '../../services/DecibelService';
import { DecibelRecordService } from '../../services/DecibelRecordService';
import common from '@ohos.app.ability.common';
import { navigationStack } from '../../constants/ProviderConstant';
import { AppStorageV2, curves, LevelMode, PersistenceV2, promptAction, window } from '@kit.ArkUI';
import display from '@ohos.display';
import { taskpool } from '@kit.ArkTS';
import { concurrentCalculateSpectrum } from '../../concurrent/ConcurrentFftAnalyzer';
import {
  formatStartTime,
  secondsToHoursMinutesSeconds,
  secondsToHoursMinutesSecondsWithDecimal
} from '../../utils/TimeUtils';
import { ActionPanel } from './ActionPanel';
import { SpectrumChartComponent } from './SpectrumChartComponent';
import { DisplayManager } from '../../../../main/ets/utils/DisplayManager';
import { AudioAnalysisMode, AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DecibelRecord } from '../../models/DecibelRecord';
import { AudioService } from '../../services/AudioService';
import { FileUtils } from '../../utils/FileUtils';
import { LocationService, LocationInfo } from '../../services/LocationService';
import { FFTAnalyzer } from '../../utils/FFTAnalyzer';
import { LocationDisplay } from '../business/LocationDisplay';
import { WeightingType } from '../../constants/WeightingConstants';
import { call } from '@kit.TelephonyKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { camera } from '@kit.CameraKit';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { resourceManager } from '@kit.LocalizationKit';
import { NoiseDescriptionDialogBuilder } from '../../pages/noisemeter/NoiseDescriptionDialogNavigation';
import { image } from '@kit.ImageKit';
import { AppKeys } from '../../models/AppKeys';

@ComponentV2
export struct DecibelMeter {
  @Param @Require meterOn: boolean = true;
  @Local private minDecibel: number = 0
  @Local private maxDecibel: number = 0
  @Local private avgDecibel: number = 0
  @Local private showAvgInsteadOfMin: boolean = true
  @Local private isRecording: boolean = false
  @Local private recordingTime: number = 0
  @Local private torchOn: boolean = false
  @Local private isNoiseAlarm: boolean = false // 是否触发噪音报警
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
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  private audioService: AudioService = AudioService.getInstance(getContext() as common.UIAbilityContext)
  private locationService: LocationService = LocationService.getInstance()
  private recordService: DecibelRecordService = new DecibelRecordService(getContext() as common.UIAbilityContext)
  private dbCount: number = 0
  private dbSum: number = 0
  private values: number[] = []
  private weightingTypes: WeightingType[] = []
  private releaseTimer: number = -1
  private currentRecord?: DecibelRecord
  noiseInfoDialog: InfSheet | undefined
  sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  private readonly sampleRate: number = 44100 // 采样率
  private noiseAlarmTimer: number = -1 // 定时器ID用于控制闪烁


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


  @Builder
  noiseCalibration() {
    Row({ space: 4 }) {
      Text('声级校准:')
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'));

      Text(`${this.pk.calibration_value} ${this.pk.weighting_type === WeightingType.A ? 'dB(A)' :
        this.pk.weighting_type === WeightingType.C ? 'dB(C)' : 'dB'}`)
        .fontSize(12)
        .fontColor('sys.color.font_secondary');
    }
    .opacity(0.7)
  }

  @Builder
  noiseDescriptions() {
    Row() {
      Image($r('app.media.ic_info'))
        .width(12)
        .height(12)
        .fillColor(DecibelService.getDecibelColor(this.as.db));

      Text(DecibelService.getDecibelDescription(this.as.db))
        .fontSize(12)
        .fontColor(DecibelService.getDecibelColor(this.as.db))
        .fontWeight(FontWeight.Medium);
    }
    .padding(8)
    .borderRadius(8)
    .border({
      width: 1,
      color: DecibelService.getDecibelColor(this.as.db)
    })
    .id('noiseDescriptionButtonId')
    .onClick(() => {
      let dialog = DialogHub.getSheet()
        .setContent(wrapBuilder(NoiseDescriptionDialogBuilder), this.as)
        .setStyle({ backgroundColor: $r('sys.color.background_secondary'), showClose: false })
        .setConfig({ enableOutsideInteractive: false, scrollSizeMode: ScrollSizeMode.CONTINUOUS })
        .setComponentTargetId('noiseDescriptionButtonId')
        .build();
      dialog.show();
      setInterval(() => {
        dialog.updateContent(this.as);
      }, 100)
    })
  }


  @Monitor('pk.location_enabled')
  onLocationEnabledChange(monitor: IMonitor) {
    const beforeEnabled = monitor.value<boolean>()?.before;
    const newEnabled = monitor.value<boolean>()?.now;
    if (newEnabled !== beforeEnabled) {
      const newEnabled = monitor.value<boolean>()?.now;
      if (!newEnabled) {
        this.locationService.clearCache();
      } else {
        this.locationService.requestSingleLocation();
      }
    }
  }

  aboutToDisappear() {
    if (this.releaseTimer !== -1) {
      clearTimeout(this.releaseTimer);
      this.releaseTimer = -1;
    }
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
      if (!this.pk.location_enabled) {
        this.locationService.clearCache();
      } else {
        // 初始化位置信息
        this.locationService.requestSingleLocation();
      }

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
      if (this.pk.record_enabled) {
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
          WeightingType, number], Float32Array>(concurrentCalculateSpectrum, this.pk.audio_analysis_mode,
          buffer, this.pk.weighting_type, this.pk.calibration_value).then(spectrum => {
          const config = AudioPresets.getConfig(this.pk.audio_analysis_mode);
          const db: number = new FFTAnalyzer(config.fftSize, config.windowType, config.smoothingFactor,
            config.overlap).calculateAverageDb(spectrum);

          let decibel = Math.round(db);
          this.values.push(decibel);
          this.weightingTypes.push(this.pk.weighting_type)
          if (this.isDisplayApp) {
            this.as.db = decibel;
            this.updateStatistics(this.as.db);
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
      if (this.dbCount <= 5 && this.pk.audio_analysis_mode == AudioAnalysisMode.FAST_TIME_WEIGHTING) {
        this.maxDecibel = this.minDecibel;
        this.values.shift();
        this.values.unshift(this.minDecibel);
      }
      if (this.dbCount <= 10 && this.pk.audio_analysis_mode == AudioAnalysisMode.IMPULSE_TIME_WEIGHTING) {
        this.maxDecibel = this.minDecibel;
        this.values.shift();
        this.values.unshift(this.minDecibel);
      }
      // 更新平均值
      this.dbSum += value;
      this.dbCount++;
      this.avgDecibel = Math.round(this.dbSum / this.dbCount);

      if (value > this.pk.noise_threshold && this.pk.noise_alarm_enabled) {
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

        if (this.pk.location_enabled) {
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

    // 清除闪烁定时器
    if (this.noiseAlarmTimer !== -1) {
      clearInterval(this.noiseAlarmTimer);
      this.noiseAlarmTimer = -1;
      this.isNoiseAlarm = false;
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
          Column() {
            Stack() {
              // 分贝显示和位置信息
              Column() {
                // 噪音场景参考和升级校准信息
                Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
                  this.noiseDescriptions()
                  this.noiseCalibration()
                }
                .margin({
                  bottom: 12,
                  left: 16,
                  right: 16,
                  top: 12
                })

                // 分贝显示卡片
                Row({ space: 8 }) {
                  this.averageMin()

                  this.CurrentDecibel()

                  this.max()
                }

                .justifyContent(FlexAlign.Center)
                .alignItems(VerticalAlign.Bottom)
                .borderColor(this.isNoiseAlarm ? DecibelService.getDecibelColor(this.as.db) :
                Color.Transparent)

                Text(`${secondsToHoursMinutesSecondsWithDecimal(this.MAX_RECORDING_DURATION -
                this.recordingTime)} 后自动保存`).fontSize(14)

                // 位置显示
                Row() {
                  LocationDisplay()
                }
              }.justifyContent(FlexAlign.Center)
            }
            .clip(true)

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
            isDisplayApp: this.isDisplayApp
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
  actionPanel() {
    ActionPanel({
      isTorchOn: this.torchOn,
      weightingType: this.pk.weighting_type,
      onReset: () => {
        this.audioService.resetData();
        this.resetData();
      },
      onSave: (comments) => {
        this.bgImage = this.getUIContext().getComponentSnapshot().getSync('mainNoiseMeterDisplayId');
        this.stopRecording(comments);
        this.startCollapseAnimation();
      },
      torchToggle: () => {
        this.toggleTorch();
      },
      // 修改：将onToggleWeighting的参数类型改为WeightingType
      onToggleWeighting: (weightingType: WeightingType) => {
        this.pk.weighting_type = weightingType;
        // 弹出提示框显示当前频率加权方式
        promptAction.showToast({
          message: `已切换为: ${weightingType} 计权`,
          duration: 2000
        });
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

  @Builder
  max() {
    Column() {
      Text('最大')

        .margin({ bottom: 4 });
      Text(this.maxDecibel === 0 ? '-' : this.maxDecibel.toString())
        .fontSize(32)
        .fontWeight(FontWeight.Medium)
        .fontColor(DecibelService.getDecibelColor(this.maxDecibel))
        .animation({ curve: Curve.EaseOut });
    }
    .alignItems(HorizontalAlign.Center)
    .margin({
      left: 16
    })
  }

  @Builder
  averageMin() {
    Column() {
      Text(this.showAvgInsteadOfMin ? '平均' : '最小')

      Text(this.showAvgInsteadOfMin ?
        (this.avgDecibel === 0 ? '-' : this.avgDecibel.toString()) :
        (this.minDecibel === 0 ? '-' : this.minDecibel.toString()))
        .fontSize(32)
        .fontWeight(FontWeight.Medium)
        .fontColor(DecibelService.getDecibelColor(
          this.showAvgInsteadOfMin ? this.avgDecibel : this.minDecibel))
        .onClick(() => {
          this.showAvgInsteadOfMin = !this.showAvgInsteadOfMin;
        });
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  CurrentDecibel() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        if (this.as.db === 0) {
          Text('-')
            .fontSize(100)
            .textShadow({
              radius: 2,
              color: Color.White,
              offsetX: 0,
              offsetY: 0
            })
            .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }))
            .fontWeight(FontWeight.Bold)
            .fontColor(DecibelService.getDecibelColor(this.as.db));
        } else {
          Text(this.as.db.toString())
            .fontSize(100)
            .textShadow({
              radius: 2,
              color: Color.White,
              offsetX: 0,
              offsetY: 0
            })
            .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }))
            .fontWeight(FontWeight.Bold)
            .fontColor(DecibelService.getDecibelColor(this.as.db));
        }

      }
      .backgroundColor('#00000000')
      .margin({ bottom: -20, right: -20 })
      .id('currentDbComp')
      .onClick(() => {
        DialogHub.getPopup()
          .setTextContent('当前分贝值')
          .setComponentTargetId('currentDbComp')
          .setStyle({
            radius: $r('sys.float.chip_small_radius'),
            maskColor: '#00000000',
          })
          .setConfig({
            dialogPosition: {
              preferPlacement: Placement.Top
            },
            dialogBehavior: { isModal: true, autoDismiss: true }
          })
          .build()
          .show();
      })
      .alignItems(HorizontalAlign.Center);
    }
  }

  private toggleTorch() {
    let cameraManager: camera.CameraManager = camera.getCameraManager(getContext(this));
    if (cameraManager.isTorchSupported()) {
      cameraManager.setTorchMode(this.torchOn ? camera.TorchMode.OFF : camera.TorchMode.ON);
      promptAction.showToast({ message: '手电筒已' + (this.torchOn ? '关闭' : '打开') });
      this.torchOn = !this.torchOn;
    }
  }
}
