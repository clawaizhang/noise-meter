import { AppStorageV2, promptAction } from '@kit.ArkUI';
import { DecibelState } from '../../types/DecibelState';
import { PreferenceService, PreferenceValue } from '../../services/PreferenceService';
import { getWeightingDescription, WeightingType } from '../../constants/WeightingConstants';
import { AudioAnalysisMode, AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeyConstants } from '../../constants/PreferenceKeyConstants';
import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';

@Extend(Image)
function itemIcon() {
  .width(DesignConstants.ICON_SIZE_MD)
  .height(DesignConstants.ICON_SIZE_MD)
  .margin({ right: DesignConstants.SPACING_MD })
}

@Extend(Text)
function itemTitle() {
  .fontWeight(FontWeight.Medium)
  .fontColor($r('app.color.text_primary'))
  .fontSize(DesignConstants.FONT_SIZE_LG)
}

@Extend(Text)
function itemDescription() {
  .fontColor($r('app.color.text_secondary'))
  .fontSize(DesignConstants.FONT_SIZE_MD)
  .textAlign(TextAlign.Start)

  .margin({ left: DesignConstants.SPACING_XL })
}

@Extend(Select)
function selectStyle() {
  .backgroundColor($r('app.color.background_secondary'))
  .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  .padding({
    left: DesignConstants.SPACING_MD,
    right: DesignConstants.SPACING_MD
  })
  .font({
    size: DesignConstants.FONT_SIZE_MD,
    weight: FontWeight.Normal,
    family: 'HarmonyHeiTi'
  })
  .selectedOptionFont({
    size: DesignConstants.FONT_SIZE_MD,
    weight: FontWeight.Normal,
    family: 'HarmonyHeiTi'
  })
  .optionFont({
    size: DesignConstants.FONT_SIZE_MD,
    weight: FontWeight.Normal,
    family: 'HarmonyHeiTi'
  })
}

@Extend(Column)
function cardStyle() {
  .backgroundColor($r('app.color.background_secondary'))
  .borderRadius(12)
  .shadow({
    radius: 8,
    color: $r('app.color.shadow_medium'),
    offsetX: 0,
    offsetY: 2
  })
  .padding({
    top: DesignConstants.SPACING_MD,
    bottom: DesignConstants.SPACING_MD,
    left: DesignConstants.SPACING_LG,
    right: DesignConstants.SPACING_LG
  })
  .margin({
    top: DesignConstants.SPACING_MD,
    bottom: DesignConstants.SPACING_MD,
    left: DesignConstants.SPACING_MD,
    right: DesignConstants.SPACING_MD
  })
}

@Extend(Column)
function listItemStyle() {

  .padding({
    left: DesignConstants.SPACING_LG,
    right: DesignConstants.SPACING_LG
  })
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(Row)
function listItemRow() {

  .height(56)
  .alignItems(VerticalAlign.Center)
}

@Extend(Text)
function detailText() {
  .fontColor($r('app.color.text_secondary'))
  .fontSize(DesignConstants.FONT_SIZE_MD)
  .margin({
    top: DesignConstants.SPACING_XS,
    left: DesignConstants.SPACING_XL
  })
}

@Extend(ListItem)
function dividerStyle() {

  .height(1)
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(ListItem)
function descriptionContainer() {
  .backgroundColor($r('app.color.background_secondary'))
  .padding({
    top: DesignConstants.SPACING_SM,
    bottom: DesignConstants.SPACING_MD
  })
}

@Extend(Text)
function analysisDescription() {
  .fontColor($r('app.color.text_secondary'))
  .fontSize(DesignConstants.FONT_SIZE_MD)
  .textAlign(TextAlign.Start)
}

@Extend(Text)
function analysisDetail() {
  .fontColor($r('app.color.text_secondary'))
  .fontSize(DesignConstants.FONT_SIZE_MD)
  .textAlign(TextAlign.Start)
  .margin({ top: DesignConstants.SPACING_SM })
}

@ComponentV2
export struct AudioAnalysisSettings {
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  @Local selectedWeighting: WeightingType = WeightingType.A;
  @Local selectedAnalysisMode: AudioAnalysisMode = AudioAnalysisMode.FAST_TIME_WEIGHTING;
  @Local analysisModeDescription: string = '';
  @Local analysisModeDetails: string[] = [];
  @Local isModeChangeEnabled: boolean = true;
  @Local remainingTime: number = 0;
  @Local calibrationValue: number = 0;
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
    this.selectedWeighting =
      (this.preferenceService.getString(PreferenceKeyConstants.WEIGHTING) || WeightingType.A) as WeightingType;
    this.selectedAnalysisMode = (this.preferenceService.getString(PreferenceKeyConstants.ANALYSIS_MODE) ||
    AudioAnalysisMode.FAST_TIME_WEIGHTING) as AudioAnalysisMode;
    this.calibrationValue = this.preferenceService.getNumber(PreferenceKeyConstants.CALIBRATION) || 0;

    this.preferenceService.addChangeListener(PreferenceKeyConstants.WEIGHTING,
      (key: string, value: PreferenceValue) => {
        this.selectedWeighting = value as WeightingType;
      })
  }

  private updateAnalysisModeCache() {
    this.analysisModeDescription = this.getAnalysisModeDescription(this.selectedAnalysisMode);
    const config = AudioPresets.getConfig(this.selectedAnalysisMode);
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
    this.calibrationValue = Math.round(newCalibrationValue * 10) / 10; // 保留1位小数
    void this.preferenceService.setNumber(PreferenceKeyConstants.CALIBRATION, this.calibrationValue);

    promptAction.showToast({
      message: `自动校准完成，新校准值: ${this.calibrationValue}dB`,
      duration: 3000
    });
  }

  build() {
    NavDestination() {
      List() {
        // 时间计权模式
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_time_weighting'))
                  .itemIcon()

                Text('时间计权模式')
                  .itemTitle()
              }

              Blank()

              Row() {
                Text(this.remainingTime > 0 ? `${(this.remainingTime / 1000).toFixed(1)}秒` : '')
                  .fontSize(DesignConstants.FONT_SIZE_MD)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ right: DesignConstants.SPACING_XS })

                Select([
                  { value: '快速(F)' },
                  { value: '慢速(S)' },
                  { value: '脉冲(I)' }
                ])
                  .selected(this.getAnalysisModeIndex(this.selectedAnalysisMode))
                  .value(this.getAnalysisModeDisplayName(this.selectedAnalysisMode))
                  .selectStyle()

                  .onSelect((index: number) => {
                    if (!this.isModeChangeEnabled) {
                      return;
                    }

                    // 禁用切换
                    this.isModeChangeEnabled = false;

                    const mode = this.getAnalysisModeFromIndex(index);
                    void this.preferenceService.setString(PreferenceKeyConstants.ANALYSIS_MODE, mode);
                    this.selectedAnalysisMode = mode;
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
          }
          .cardStyle()
        }

        ListItem() {
          Column() {
            Text(this.analysisModeDescription)
              .analysisDescription()
            ForEach(this.analysisModeDetails, (detail: string) => {
              Text(detail)
                .analysisDetail()
            })
          }

          .alignItems(HorizontalAlign.Start)
          .padding({ left: DesignConstants.SPACING_XL })
        }
        .descriptionContainer()

        // 分贝计权设置
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_frequency_weighting'))
                  .itemIcon()

                Text('频率加权')
                  .itemTitle()
              }

              Blank()

              Select([
                { value: 'A计权' },
                { value: 'C计权' },
                { value: 'Z计权' }
              ])
                .selected(this.getWeightingIndex(this.selectedWeighting))
                .value(this.selectedWeighting + '计权')
                .selectStyle()
                .onSelect((index: number) => {
                  const weightingType = this.getWeightingType(index);
                  void this.preferenceService.setString(PreferenceKeyConstants.WEIGHTING, weightingType);
                  this.selectedWeighting = weightingType;
                })
            }
            .listItemRow()
          }
          .cardStyle()
        }

        ListItem() {
          Text(getWeightingDescription(this.selectedWeighting))
            .itemDescription()
        }
        .descriptionContainer()

        // 声级校准设置
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_calibration'))
                  .itemIcon()

                Text('声级校准')
                  .itemTitle()
              }

              Blank()

              Text(`${this.calibrationValue}dB`)
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('app.color.text_secondary'))
                .margin({ right: DesignConstants.SPACING_SM })
            }
            .listItemRow()

            Slider({
              value: this.calibrationValue,
              min: -30,
              max: 30,
              style: SliderStyle.InSet
            })
              .blockColor($r('app.color.primary'))
              .trackColor($r('app.color.background_secondary'))
              .selectedColor($r('app.color.primary'))
              .showTips(true, `${this.decibelState.currentDecibel}dB`)
              .onChange((value: number) => {
                this.calibrationValue = value;
                void this.preferenceService.setNumber(PreferenceKeyConstants.CALIBRATION, value);
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
          }
          .cardStyle()
        }

        ListItem() {
          Text('手动校准麦克风灵敏度，确保测量精度')
            .itemDescription()
        }
        .descriptionContainer()

        // 自动校准按钮
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_calibration'))
                  .itemIcon()

                Text('自动校准')
                  .itemTitle()
              }

              Blank()

              if (this.isAutoCalibrating) {
                Text(this.countdown > 0 ? `${this.countdown}秒后开始校准` :
                  `校准中,请保持安静...${8 - this.calibrationProgress}秒`)
                  .fontSize(DesignConstants.FONT_SIZE_MD)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ right: DesignConstants.SPACING_SM })
              } else {
                Button('开始校准')
                  .type(ButtonType.Normal)
                  .fontSize(DesignConstants.FONT_SIZE_MD)
                  .backgroundColor($r('app.color.primary'))
                  .borderRadius(DesignConstants.BORDER_RADIUS_LG)
                  .height(32)
                  .width(90)
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
          }
          .cardStyle()
        }

        ListItem() {
          Text('自动计算并设置校准值')
            .itemDescription()
        }
        .descriptionContainer()
      }

      .layoutWeight(1)
      .backgroundColor('transparent')
    }

    .backgroundColor($r('app.color.background_tertiary')).title('音频分析设置')

  }
}


@Builder
export function AudioAnalysisSettingsBuilder() {
  AudioAnalysisSettings()
}