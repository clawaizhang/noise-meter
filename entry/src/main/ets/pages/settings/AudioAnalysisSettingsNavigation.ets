import { AppStorageV2, curves, PersistenceV2, promptAction } from '@kit.ArkUI';
import { DecibelState } from '../../types/DecibelState';
import { getWeightingDescription, WeightingType } from '../../constants/WeightingConstants';
import { AudioAnalysisMode, AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';

@Extend(Image)
function itemIcon() {
  .width(DesignConstants.ICON_SIZE_MD)
  .height(DesignConstants.ICON_SIZE_MD)
  .fillColor($r('sys.color.font_primary'))
}

@Extend(Text)
function itemTitle() {
  .fontWeight(FontWeight.Medium)
}

@Extend(Text)
function itemDescription() {
  .fontColor($r('sys.color.font_secondary'))
  .fontSize(DesignConstants.FONT_SIZE_MD)
  .textAlign(TextAlign.Start)
  .alignSelf(ItemAlign.Start)
}

@Extend(Column)
function cardStyle() {
  .backgroundColor($r('sys.color.comp_background_secondary'))
  .justifyContent(FlexAlign.Start)
  .alignItems(HorizontalAlign.Start)
  .borderRadius(16)
  .padding(16)
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
    .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
    .combine(TransitionEffect.translate({ x: 0, y: 0 }).animation({ curve: curves.springMotion() })))
}

@Extend(Row)
function listItemRow() {
  .alignItems(VerticalAlign.Center)
  .justifyContent(FlexAlign.Start)
}

@Extend(Text)
function analysisDescription() {
  .fontColor($r('sys.color.font_secondary'))
  .fontSize(DesignConstants.FONT_SIZE_MD)
  .textAlign(TextAlign.Start)
  .alignSelf(ItemAlign.Start)
}

@Extend(Text)
function analysisDetail() {
  .fontColor($r('sys.color.font_secondary'))
  .fontSize(DesignConstants.FONT_SIZE_MD)
  .textAlign(TextAlign.Start)
  .alignSelf(ItemAlign.Start)
}

@ComponentV2
export struct AudioAnalysisSettings {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local analysisModeDescription: string = '';
  @Local analysisModeDetails: string[] = [];
  @Local isModeChangeEnabled: boolean = true;
  @Local remainingTime: number = 0;
  @Local isAutoCalibrating: boolean = false;
  @Local countdown: number = 0;
  @Local calibrationProgress: number = 0;
  @Local decibelState: DecibelState = AppStorageV2.connect(DecibelState, 'DecibelState', () => new DecibelState())!;
  @Local gridColumns: number = 1;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  private readonly COOLDOWN_DURATION: number = 500; // 0.5秒冷却时间

  // 工具方法
  private getWeightingIndex(type: WeightingType): number {
    switch (type) {
      case WeightingType.A:
        return 0;
      case WeightingType.C:
        return 1;
      case WeightingType.Z:
        return 2;
      default:
        return 0;
    }
  }

  private getWeightingType(index: number): WeightingType {
    switch (index) {
      case 0:
        return WeightingType.A;
      case 1:
        return WeightingType.C;
      case 2:
        return WeightingType.Z;
      default:
        return WeightingType.A;
    }
  }

  private getAnalysisModeIndex(mode: AudioAnalysisMode): number {
    switch (mode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        return 0;
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        return 1;
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        return 2;
      default:
        return 0;
    }
  }

  private getAnalysisModeFromIndex(index: number): AudioAnalysisMode {
    switch (index) {
      case 0:
        return AudioAnalysisMode.FAST_TIME_WEIGHTING;
      case 1:
        return AudioAnalysisMode.SLOW_TIME_WEIGHTING;
      case 2:
        return AudioAnalysisMode.IMPULSE_TIME_WEIGHTING;
      default:
        return AudioAnalysisMode.FAST_TIME_WEIGHTING;
    }
  }

  private getAnalysisModeDisplayName(mode: AudioAnalysisMode): string {
    switch (mode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        return '快速(F)';
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        return '慢速(S)';
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        return '脉冲(I)';
      default:
        return '快速(F)';
    }
  }

  private getAnalysisModeDescription(mode: AudioAnalysisMode): string {
    switch (mode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        return '时间常数200ms，适合测量快速变化的噪声';
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        return '时间常数500ms，适合测量稳态噪声';
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        return '时间常数35ms，适合测量脉冲噪声';
      default:
        return '时间常数200ms，适合测量快速变化的噪声';
    }
  }

  aboutToAppear() {
    this.updateAnalysisModeCache();
  }

  private updateAnalysisModeCache() {
    this.analysisModeDescription = this.getAnalysisModeDescription(this.pk.audio_analysis_mode);
    const config = AudioPresets.getConfig(this.pk.audio_analysis_mode);
    this.analysisModeDetails = [
      `FFT大小: ${config.fftSize}`,
      `频率分辨率: ${(44100 / config.fftSize).toFixed(1)}Hz`,
      `时间分辨率: ${(config.fftSize / 44100 * 1000).toFixed(1)}ms`,
      `更新间隔: ${config.updateInterval}ms`
    ];
  }

  private startAutoCalibration() {
    this.isAutoCalibrating = true;
    this.countdown = 3;

    // 5秒倒计时
    const countdownInterval = setInterval(() => {
      this.countdown -= 1;
      if (this.countdown <= 0) {
        clearInterval(countdownInterval);
        this.beginCalibration();
      }
    }, 1000);
  }

  private beginCalibration() {
    const calibrationDuration = 8; // 8秒校准
    this.calibrationProgress = 0;
    let totalDecibel = 0;
    let sampleCount = 0;

    // 开始校准
    const calibrationInterval = setInterval(() => {
      this.calibrationProgress += 1;
      totalDecibel += this.decibelState.currentDecibel;
      sampleCount += 1;

      if (this.calibrationProgress >= calibrationDuration) {
        clearInterval(calibrationInterval);
        this.finishCalibration(totalDecibel / sampleCount);
      }
    }, 1000);
  }

  private finishCalibration(averageDecibel: number) {
    this.isAutoCalibrating = false;
    const newCalibrationValue = 26 - averageDecibel; // 计算与26dB的差值
    this.pk.calibration_value = Math.round(newCalibrationValue * 10) / 10; // 保留1位小数


    promptAction.showToast({
      message: `自动校准完成，新校准值: ${this.pk.calibration_value}dB`,
      duration: 3000
    });
  }

  build() {
    GridRow({
      columns:
      1,
      breakpoints: { reference: BreakpointsReference.WindowSize }
    , gutter: 16
    }) {
      // 时间计权模式
      GridCol() {
        Column() {
          Row() {
            Row({ space: 8 }) {
              Image($r('app.media.ic_time_weighting'))
                .itemIcon()
              Text('时间计权模式')
                .itemTitle()
            }.layoutWeight(1)

            Row() {
              Text(this.remainingTime > 0 ? `${(this.remainingTime / 1000).toFixed(1)}秒` : '')
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('sys.color.font_secondary'))
                .margin({ right: DesignConstants.SPACING_XS })
              Select([
                { value: '快速(F)' },
                { value: '慢速(S)' },
                { value: '脉冲(I)' }
              ])
                .selected(this.getAnalysisModeIndex(this.pk.audio_analysis_mode))
                .value(this.getAnalysisModeDisplayName(this.pk.audio_analysis_mode))
                .onSelect((index: number) => {
                  if (!this.isModeChangeEnabled) {
                    return;
                  }

                  // 禁用切换
                  this.isModeChangeEnabled = false;
                  const mode = this.getAnalysisModeFromIndex(index);
                  this.pk.audio_analysis_mode = mode;
                  this.updateAnalysisModeCache();

                  // 启动冷却计时器
                  this.remainingTime = this.COOLDOWN_DURATION;
                  const interval = setInterval(() => {
                    this.remainingTime -= 100;
                    if (this.remainingTime <= 0) {
                      clearInterval(interval);
                      this.isModeChangeEnabled = true;
                      this.remainingTime = 0;
                    }
                  }, 100);
                })
                .enabled(this.isModeChangeEnabled)
            }
          }
          .listItemRow()

          Column() {
            Text(this.analysisModeDescription)
              .analysisDescription()
            ForEach(this.analysisModeDetails, (detail: string) => {
              Text(detail)
                .analysisDetail()
            })
          }.justifyContent(FlexAlign.Start)
        }
        .cardStyle()
      }

      // 分贝计权设置
      GridCol() {
        Column({ space: 8 }) {
          Row() {
            Row({ space: 8 }) {
              Image($r('app.media.ic_frequency_weighting'))
                .itemIcon()
              Text('频率加权')
                .itemTitle()
            }.layoutWeight(1)

            Select([
              { value: 'A计权' },
              { value: 'C计权' },
              { value: 'Z计权' }
            ])
              .selected(this.getWeightingIndex(this.pk.weighting_type))
              .value(this.pk.weighting_type + '计权')
              .onSelect((index: number) => {
                const weightingType = this.getWeightingType(index);
                this.pk.weighting_type = weightingType;
              })
          }
          .listItemRow()

          Text(getWeightingDescription(this.pk.weighting_type))
            .itemDescription()
        }
        .cardStyle()
      }

      // 声级校准设置
      GridCol() {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Row() {
              Image($r('app.media.ic_calibration'))
                .itemIcon()
              Text('声级校准')
                .itemTitle()
            }.layoutWeight(1)

            Text(`${this.pk.calibration_value}dB`)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_secondary'))
              .margin({ right: DesignConstants.SPACING_SM })
          }
          .listItemRow()

          Slider({
            value: this.pk.calibration_value,
            min: -30,
            max: 30,
            style: SliderStyle.InSet
          })
            .blockColor($r('sys.color.font_emphasize'))
            .trackColor($r('sys.color.background_secondary'))
            .selectedColor($r('sys.color.font_emphasize'))
            .showTips(true, `${this.decibelState.currentDecibel}dB`)
            .onChange((value: number) => {
              this.pk.calibration_value = value;
            })
            .margin({
              top: DesignConstants.SPACING_MD,
              bottom: DesignConstants.SPACING_MD
            })
            .height(24)
            .trackThickness(24)
            .blockSize({
              width: 24,
              height: 24
            })

          Text('手动校准麦克风灵敏度，确保测量精度')
            .itemDescription()
        }
        .cardStyle()

      }

      // 自动校准按钮
      GridCol() {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Row() {
              Image($r('app.media.ic_calibration'))
                .itemIcon()
              Text('自动校准')
                .itemTitle()
            }.layoutWeight(1)

            if (this.isAutoCalibrating) {
              Text(this.countdown > 0 ? `${this.countdown}秒后开始校准` :
                `校准中,请保持安静...${8 - this.calibrationProgress}秒`)
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('sys.color.font_secondary'))
                .margin({ right: DesignConstants.SPACING_SM })
            } else {
              Button('开始校准')
                .type(ButtonType.Normal)
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .backgroundColor($r('sys.color.background_emphasize'))
                .borderRadius(DesignConstants.BORDER_RADIUS_LG)
                .height(32)
                .onClick(async () => {
                  const result = await promptAction.showDialog({
                    title: '自动校准提示',
                    message: '请在非常安静的房间中进行自动校准，特别是夜间效果最佳',
                    buttons: [
                      {
                        text: '取消',
                        color: $r('app.color.text_disabled')
                      },
                      {
                        text: '确认',
                        color: $r('app.color.primary')
                      }
                    ]
                  });

                  // 根据用户选择处理
                  if (result.index === 1) { // 确认按钮
                    this.startAutoCalibration();
                  }
                })
            }
          }
          .listItemRow()

          Text('自动计算并设置校准值')
            .itemDescription()
        }
        .cardStyle()
      }
    }
    .padding(16)
    .backgroundColor($r('sys.color.background_primary'))
  }
}


@Builder
export function AudioAnalysisSettingsBuilder() {
  AudioAnalysisSettings()
}