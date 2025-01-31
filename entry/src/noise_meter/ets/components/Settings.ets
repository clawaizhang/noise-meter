import { AppStorageV2 } from '@kit.ArkUI';
import { PreferenceService, PreferenceValue } from '../../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';
import { CustomTitleBar } from '../../../library/ets/components/common/CustomTitleBar';
import { WeightingType, getWeightingDescription } from '../../../library/ets/constants/WeightingConstants';
import { AudioAnalysisMode, AudioPresets } from '../../../library/ets/common/AudioConfig';
import { DecibelState } from '../types/DecibelState';

@Extend(Image)
function itemIcon() {
  .width(24)
  .height(24)
  .margin({ right: 8 })
}

@Extend(Text)
function itemTitle() {
  .fontWeight(FontWeight.Medium)
  .fontColor('#000000')
  .fontSize(16)
}

@Extend(Text)
function itemDescription() {
  .fontColor('#666666')
  .fontSize(14)
  .textAlign(TextAlign.Start)
  .margin({ left: 48 })
}

@Extend(Select)
function selectStyle() {
  .backgroundColor(Color.White)
  .borderRadius(16)
  .padding({ left: 12, right: 12 })
  .font({ size: 16, weight: FontWeight.Normal, family: 'HarmonyHeiTi' })
  .selectedOptionFont({ size: 16, weight: FontWeight.Normal, family: 'HarmonyHeiTi' })
  .optionFont({ size: 16, weight: FontWeight.Normal, family: 'HarmonyHeiTi' })
}

@Extend(Column)
function listItemStyle() {
  .width('100%')
  .padding({ left: 16, right: 16 })
  .backgroundColor('#FFFFFF')
}

@Extend(Row)
function listItemRow() {
  .width('100%')
  .height(56)
  .alignItems(VerticalAlign.Center)
}

@Extend(Text)
function detailText() {
  .fontColor('#666666')
  .fontSize(14)
  .margin({ top: 4, left: 48 })
}

@Extend(Row)
function dividerStyle() {
  .width('100%')
  .height(1)
  .backgroundColor('#F5F5F5')
}

@Extend(ListItem)
function descriptionContainer() {
  .backgroundColor('#F5F5F5')
  .padding({ top: 8, bottom: 12 })
}

@Extend(Text)
function analysisDescription() {
  .fontColor('#666666')
  .fontSize(14)
  .textAlign(TextAlign.Start)
}

@Extend(Text)
function analysisDetail() {
  .fontColor('#666666')
  .fontSize(14)
  .textAlign(TextAlign.Start)
  .margin({ top: 8 })
}

@ComponentV2
export struct Settings {
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  @Local isLocationEnabled: boolean = true;
  @Local isRecordEnabled: boolean = true;
  @Local isKeepScreenOn: boolean = true;
  @Local selectedWeighting: WeightingType = WeightingType.A;
  @Local selectedAnalysisMode: AudioAnalysisMode = AudioAnalysisMode.FAST_TIME_WEIGHTING;
  @Local analysisModeDescription: string = '';
  @Local analysisModeDetails: string[] = [];
  @Local isModeChangeEnabled: boolean = true;
  @Local remainingTime: number = 0;
  @Local calibrationValue: number = 0;
  @Local decibelState: DecibelState = AppStorageV2.connect(DecibelState, 'DecibelState', () => new DecibelState())!;
  @Local isNoiseAlarmEnabled: boolean = true;
  @Local noiseThreshold: number = 80;
  @Local noiseAlarmDescription: string = ''; // 添加新的变量来存储噪音警报描述
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
    this.isLocationEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.LOCATION, true);
    this.isRecordEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.RECORD, true);
    this.isKeepScreenOn = this.preferenceService.getBoolean(PreferenceKeyConstants.KEEP_SCREEN_ON, true);
    this.selectedWeighting =
      (this.preferenceService.getString(PreferenceKeyConstants.WEIGHTING) || WeightingType.A) as WeightingType;
    this.selectedAnalysisMode = (this.preferenceService.getString(PreferenceKeyConstants.ANALYSIS_MODE) ||
    AudioAnalysisMode.FAST_TIME_WEIGHTING) as AudioAnalysisMode;
    this.calibrationValue = this.preferenceService.getNumber(PreferenceKeyConstants.CALIBRATION) || 0;
    this.isNoiseAlarmEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.NOISE_ALARM_ENABLED, true);
    this.noiseThreshold = this.preferenceService.getNumber(PreferenceKeyConstants.NOISE_THRESHOLD, 80);
    this.updateAnalysisModeCache();
    this.updateNoiseAlarmDescription(); // 初始化噪音警报描述
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

  private updateNoiseAlarmDescription() {
    this.noiseAlarmDescription = this.isNoiseAlarmEnabled ? '噪音警报已开启' : '噪音警报已关闭';
  }

  build() {
    Column() {
      CustomTitleBar({ title: '设置' })

      List() {
        // 音频分析模式设置
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
                  .fontSize(14)
                  .fontColor('#CCCCCC')
                  .margin({ right: -2 })

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
          .listItemStyle()
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
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 48 })
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
          .listItemStyle()
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
                .fontSize(14)
                .fontColor('#666666')
                .margin({ right: 8 })
            }
            .listItemRow()

            Slider({
              value: this.calibrationValue,
              min: -30,
              max: 30,
              style: SliderStyle.InSet
            })
              .blockColor('#0091FF')
              .trackColor('#F0F0F0')
              .selectedColor('#0091FF')
              .showTips(true, `${this.decibelState.currentDecibel}dB`)
              .onChange((value: number) => {
                this.calibrationValue = value;
                void this.preferenceService.setNumber(PreferenceKeyConstants.CALIBRATION, value);
              })
              .margin({ top: 12, bottom: 12 })
              .height(24)
              .trackThickness(24)
              .blockSize({ width: 24, height: 24 })
          }
          .listItemStyle()
        }

        ListItem() {
          Text('校准声级计，范围从-30dB到+30dB')
            .itemDescription()
        }
        .descriptionContainer()


        // 添加噪音阈值警报的开关
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_alarm'))// 确保资源名称正确
                  .itemIcon()

                Text('噪音警报')
                  .itemTitle()
              }

              Blank()

              Toggle({ type: ToggleType.Switch, isOn: this.isNoiseAlarmEnabled })
                .selectedColor('#0091FF')
                .switchPointColor('#FFFFFF')
                .onChange((isOn: boolean) => {
                  void this.preferenceService.setBoolean(PreferenceKeyConstants.NOISE_ALARM_ENABLED, isOn);
                  this.isNoiseAlarmEnabled = isOn;
                  this.updateNoiseAlarmDescription(); // 更新噪音警报描述
                })
            }
            .listItemRow()
          }
          .listItemStyle()
        }

        ListItem() {
          Text(this.noiseAlarmDescription)
            .itemDescription()
        }
        .descriptionContainer()

        // 添加噪音阈值的设置
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_threshold'))
                  .itemIcon()

                Text('噪音警报阈值')
                  .itemTitle()
              }

              Blank()

              Text(`${this.noiseThreshold}dB`)
                .fontSize(14)
                .fontColor('#666666')
                .margin({ right: 8 })
            }
            .listItemRow()

            Slider({
              value: this.noiseThreshold,
              min: 30,
              max: 120,
              style: SliderStyle.InSet
            })
              .blockColor('#0091FF')
              .trackColor('#F0F0F0')
              .selectedColor('#0091FF')
              .onChange((value: number) => {
                this.noiseThreshold = value;
                void this.preferenceService.setNumber(PreferenceKeyConstants.NOISE_THRESHOLD, value);
              })
              .margin({ top: 12, bottom: 12 })
              .height(24)
              .trackThickness(24)
              .blockSize({ width: 24, height: 24 })
          }
          .listItemStyle()
        }

        ListItem() {
          Text('设置触发噪音警报的阈值，范围从30dB到120dB')
            .itemDescription()
        }
        .descriptionContainer()

        // 位置开关
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_location'))
                  .itemIcon()

                Text('地理位置')
                  .itemTitle()
              }

              Blank()

              Toggle({ type: ToggleType.Switch, isOn: this.isLocationEnabled })
                .selectedColor('#0091FF')
                .switchPointColor('#FFFFFF')
                .onChange((isOn: boolean) => {
                  void this.preferenceService.setEnabled(PreferenceKeyConstants.LOCATION, isOn);
                  this.isLocationEnabled = isOn;
                })
            }
            .listItemRow()
          }
          .listItemStyle()
        }

        ListItem() {
          Text(this.isLocationEnabled ? '记录检测地点的位置信息' : '不会采集地理位置信息')
            .itemDescription()
        }
        .descriptionContainer()

        // 录音开关
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_mic'))
                  .itemIcon()

                Text('音频记录')
                  .itemTitle()
              }

              Blank()

              Toggle({ type: ToggleType.Switch, isOn: this.isRecordEnabled })
                .selectedColor('#0091FF')
                .switchPointColor('#FFFFFF')
                .onChange((isOn: boolean) => {
                  void this.preferenceService.setEnabled(PreferenceKeyConstants.RECORD, isOn);
                  this.isRecordEnabled = isOn;
                })
            }
            .listItemRow()
          }
          .listItemStyle()
        }

        ListItem() {
          Text(this.isRecordEnabled ? '保存原始音频数据用于后期分析' : '不会保存音频数据')
            .itemDescription()
        }
        .descriptionContainer()

        // 屏幕常亮设置
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_keep_screen_on'))
                  .itemIcon()

                Text('屏幕常亮')
                  .itemTitle()
              }

              Blank()

              Toggle({ type: ToggleType.Switch, isOn: this.isKeepScreenOn })
                .selectedColor('#0091FF')
                .switchPointColor('#FFFFFF')
                .onChange((isOn: boolean) => {
                  void this.preferenceService.setBoolean(PreferenceKeyConstants.KEEP_SCREEN_ON, isOn);
                  this.isKeepScreenOn = isOn;
                })
            }
            .listItemRow()
          }
          .listItemStyle()
        }

        ListItem() {
          Text(this.isKeepScreenOn ? '屏幕将保持常亮状态' : '屏幕会根据系统设置自动休眠')
            .itemDescription()
        }
        .descriptionContainer()
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
