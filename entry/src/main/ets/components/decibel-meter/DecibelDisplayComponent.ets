import { DecibelService } from '../../services/DecibelService';
import { StatisticsService } from '../../services/StatisticsService';
import { AudioAnalysisMode, AudioPresets } from '../../common/AudioConfig';
import { WeightingType } from '../../constants/WeightingConstants';
import { concurrentCalculateSpectrum } from '../../concurrent/ConcurrentFftAnalyzer';
import { FFTAnalyzer } from '../../utils/FFTAnalyzer';
import { taskpool } from '@kit.ArkTS';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { resourceManager } from '@kit.LocalizationKit';
import { NoiseDescriptionDialogBuilder } from '../../pages/noisemeter/NoiseDescriptionDialogNavigation';
import { image } from '@kit.ImageKit';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2, curves } from '@kit.ArkUI';
import { from, interval, take, takeUntil, timer, Subject, Subscription, map, filter, switchMap, tap, delay, catchError, of } from 'rxjs';

@ComponentV2
export struct DecibelDisplayComponent {
  // 输入参数
  @Param @Require audioBuffer: ArrayBuffer = new ArrayBuffer(0);
  @Param @Require audioAnalysisMode: AudioAnalysisMode = AudioAnalysisMode.FAST_TIME_WEIGHTING;
  @Param @Require weightingType: WeightingType = WeightingType.A;
  @Param @Require calibrationValue: number = 0;
  @Param @Require noiseThreshold: number = 80;
  @Param @Require noiseAlarmEnabled: boolean = true;
  @Event minMaxAvg: (min: number, max: number, avg: number) => void;
  @Event decibelValue: (decibel: number, weightingType: WeightingType) => void;
  
  // 内部状态
  @Local private currentDecibel: number = 0;
  @Local private minDecibel: number = 0;
  @Local private maxDecibel: number = 0;
  @Local private avgDecibel: number = 0;
  @Local private isNoiseAlarm: boolean = false;
  @Local private showAvgInsteadOfMin: boolean = true;

  // 服务实例
  private statisticsService: StatisticsService = new StatisticsService();
  private statisticsSubscription?: Subscription;
  private alarmSubscription?: Subscription;
  
  @Local as: AppKeys = AppStorageV2.connect(AppKeys)!;
  sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();

  @Computed
  get fft_size() {
    return AudioPresets.getConfig(this.audioAnalysisMode).fftSize;
  }

  @Monitor('audioAnalysisMode')
  onAudioAnalysisModeChange(monitor: IMonitor) {
    const newMode = monitor.value<AudioAnalysisMode>()?.now;
    if (newMode) {
      this.statisticsService.setAudioAnalysisMode(newMode);
    }
  }

  @Monitor('noiseThreshold', 'noiseAlarmEnabled')
  onAlarmConfigChange(monitor: IMonitor) {
    const newThreshold = monitor.value<number>('noiseThreshold')?.now;
    const newEnabled = monitor.value<boolean>('noiseAlarmEnabled')?.now;
    if (newThreshold !== undefined && newEnabled !== undefined) {
      this.statisticsService.setAlarmConfig(newThreshold, newEnabled);
    }
  }

  aboutToAppear() {
    // 配置统计服务
    this.statisticsService.setAudioAnalysisMode(this.audioAnalysisMode);
    this.statisticsService.setAlarmConfig(this.noiseThreshold, this.noiseAlarmEnabled);
    
    // 启动统计服务
    this.statisticsService.start();
    
    // 订阅统计状态变化
    this.statisticsSubscription = this.statisticsService.statisticsState$.subscribe(state => {
      this.minDecibel = state.minDecibel;
      this.maxDecibel = state.maxDecibel;
      this.avgDecibel = state.avgDecibel;
      this.minMaxAvg(this.minDecibel, this.maxDecibel, this.avgDecibel);
      console.info('[DecibelDisplay] 统计状态更新:', state);
    });
    
    // 订阅报警状态变化
    this.alarmSubscription = this.statisticsService.alarmState$.subscribe(state => {
      this.isNoiseAlarm = state.isNoiseAlarm;
    });
  }

  aboutToDisappear() {
    // 清理RxJS资源
    this.statisticsService.stop();
    if (this.statisticsSubscription) {
      this.statisticsSubscription.unsubscribe();
      this.statisticsSubscription = undefined;
    }
    if (this.alarmSubscription) {
      this.alarmSubscription.unsubscribe();
      this.alarmSubscription = undefined;
    }
  }

  @Monitor('audioBuffer', 'audioAnalysisMode', 'weightingType', 'calibrationValue')
  async onAudioDataChange(monitor: IMonitor) {
    const audioBuffer = monitor.value<ArrayBuffer>('audioBuffer')?.now;
    const audioAnalysisMode = monitor.value<AudioAnalysisMode>('audioAnalysisMode')?.now;
    const weightingType = monitor.value<WeightingType>('weightingType')?.now;
    const calibrationValue = monitor.value<number>('calibrationValue')?.now;

    // 处理配置参数变化
    if (audioAnalysisMode !== undefined) {
      this.statisticsService.setAudioAnalysisMode(audioAnalysisMode);
    }

    if (audioBuffer && audioBuffer.byteLength > 0 && this.as.isDisplayApp) {
      try {
        const spectrum = await taskpool.execute<[string, ArrayBuffer, WeightingType, number], Float32Array>(
          concurrentCalculateSpectrum,
          audioAnalysisMode || this.audioAnalysisMode,
          audioBuffer,
          weightingType || this.weightingType,
          calibrationValue || this.calibrationValue
        );

        const config = AudioPresets.getConfig(audioAnalysisMode || this.audioAnalysisMode);
        const db: number = new FFTAnalyzer(
          config.fftSize,
          config.windowType,
          config.smoothingFactor,
          config.overlap
        ).calculateAverageDb(spectrum);

        let decibel = Math.round(db);
        this.currentDecibel = decibel;
        this.as.db = decibel;

        // 触发事件通知父组件有新的分贝值
        this.decibelValue(decibel, weightingType || this.weightingType);
        
        // 使用统计服务更新统计信息
        this.statisticsService.updateDecibelValue(decibel);
      } catch (error) {
        console.error('[DecibelDisplay] 分贝计算失败:', error);
      }
    }
  }

  @Builder
  noiseCalibration() {
    Row({ space: 4 }) {
      Text('声级校准:')
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'));

      Text(`${this.calibrationValue} ${this.weightingType === WeightingType.A ? 'dB(A)' :
        this.weightingType === WeightingType.C ? 'dB(C)' : 'dB'}`)
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
        .fillColor(DecibelService.getDecibelColor(this.currentDecibel));

      Text(DecibelService.getDecibelDescription(this.currentDecibel))
        .fontSize(12)
        .fontColor(DecibelService.getDecibelColor(this.currentDecibel))
        .fontWeight(FontWeight.Medium);
    }
    .padding(8)
    .borderRadius(8)
    .border({
      width: 1,
      color: DecibelService.getDecibelColor(this.currentDecibel)
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
        if (this.currentDecibel === 0) {
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
            .fontColor(DecibelService.getDecibelColor(this.currentDecibel));
        } else {
          Text(this.currentDecibel.toString())
            .fontSize(100)
            .textShadow({
              radius: 2,
              color: Color.White,
              offsetX: 0,
              offsetY: 0
            })
            .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }))
            .fontWeight(FontWeight.Bold)
            .fontColor(DecibelService.getDecibelColor(this.currentDecibel));
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

  build() {
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
      .borderColor(this.isNoiseAlarm ? DecibelService.getDecibelColor(this.currentDecibel) : Color.Transparent)
    }
    .justifyContent(FlexAlign.Center)
  }
}