import { AppStorageV2, promptAction } from '@kit.ArkUI';
import { DecibelState } from '../types/DecibelState';
import { privacyManager } from '@kit.StoreKit';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { PreferenceService, PreferenceValue } from '../services/PreferenceService';
import { getWeightingDescription, WeightingType } from '../constants/WeightingConstants';
import { AudioAnalysisMode, AudioPresets } from '../common/AudioConfig';
import { PreferenceKeyConstants } from '../constants/PreferenceKeyConstants';

@Extend(Image)
function itemIcon() {
  .width(24)
  .height(24)
  .margin({ right: 8 })
}

@Extend(Text)
function itemTitle() {
  .fontWeight(FontWeight.Medium)
  .fontColor($r('app.color.text_primary'))
  .fontSize(16)
}

@Extend(Text)
function itemDescription() {
  .fontColor($r('app.color.text_secondary'))
  .fontSize(14)
  .textAlign(TextAlign.Start)
  .width( '100%')
  .margin({ left: 48 })
}

@Extend(Select)
function selectStyle() {
  .backgroundColor($r('app.color.background_secondary'))
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
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(Row)
function listItemRow() {
  .width('100%')
  .height(56)
  .alignItems(VerticalAlign.Center)
}

@Extend(Text)
function detailText() {
  .fontColor($r('app.color.text_secondary'))
  .fontSize(14)
  .margin({ top: 4, left: 48 })
}

@Extend(ListItem)
function dividerStyle() {
  .width('100%')
  .height(1)
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(ListItem)
function descriptionContainer() {
  .backgroundColor($r('app.color.background_secondary'))
  .padding({ top: 8, bottom: 12 })
}

@Extend(Text)
function analysisDescription() {
  .fontColor($r('app.color.text_secondary'))
  .fontSize(14)
  .textAlign(TextAlign.Start)
}

@Extend(Text)
function analysisDetail() {
  .fontColor($r('app.color.text_secondary'))
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
  @Local isAutoCalibrating: boolean = false;
  @Local countdown: number = 0;
  @Local calibrationProgress: number = 0;
  @Local decibelState: DecibelState = AppStorageV2.connect(DecibelState, 'DecibelState', () => new DecibelState())!;
  @Local isNoiseAlarmEnabled: boolean = true;
  @Local noiseThreshold: number = 80;
  @Local noiseAlarmDescription: string = ''; // 添加新的变量来存储噪音警报描述
  @Local isBackgroundRunning: boolean = false; // 后台运行开关状态
  private readonly COOLDOWN_DURATION: number = 500; // 0.5秒冷却时间
  // 新增状态变量来控制每个 AccordionItem 的展开和收起状态
  @Local isAudioAnalysisExpanded: boolean = false;
  @Local isAlertsAndNotificationsExpanded: boolean = false;
  @Local isDataRecordingAndPrivacyExpanded: boolean = false;
  @Local isDeviceSettingsExpanded: boolean = false;
  @Local isAboutExpanded: boolean = false;

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
    this.isBackgroundRunning = this.preferenceService.getBoolean(PreferenceKeyConstants.BACKGROUND_RUNNING, false);
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
    this.noiseAlarmDescription = this.isNoiseAlarmEnabled
      ? '检测到噪音超过阈值时将触发警报'
      : '系统不会发出噪音超标警报';
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
    Column() {

      List() {
        // 音频分析设置
        ListItem() {
          Column() {
            Row() {
              Text('音频分析设置')
                .itemTitle()
              Blank()
            }
            .listItemRow()
          }
          .listItemStyle()
        }.onClick(() => {
          animateTo({
            duration: 300,
            onFinish: () => {
              console.info('animation end');
            }
          }, () => {
            this.isAudioAnalysisExpanded = !this.isAudioAnalysisExpanded;
            this.isAlertsAndNotificationsExpanded = false;
            this.isDataRecordingAndPrivacyExpanded = false;
            this.isDeviceSettingsExpanded = false;
            this.isAboutExpanded = false;
          })
        })

        ListItem() {
        }.dividerStyle() // 添加分隔符

        if (this.isAudioAnalysisExpanded) {
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
                    .fontSize(14)
                    .fontColor($r('app.color.text_secondary'))
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
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ right: 8 })
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
                .margin({ top: 12, bottom: 12 })
                .height(24)
                .trackThickness(24)
                .blockSize({ width: 24, height: 24 })
            }
            .listItemStyle()
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
                  Text(this.countdown > 0 ? `${this.countdown}秒后开始校准` : `校准中,请保持安静...${8 - this.calibrationProgress}秒`)
                    .fontSize(14)
                    .fontColor($r('app.color.text_secondary'))
                    .margin({ right: 8 })
                } else {
                  Button('开始校准')
                    .type(ButtonType.Normal)
                    .fontSize(14)
                    .backgroundColor($r('app.color.primary'))
                    .borderRadius(16)
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
            .listItemStyle()
          }

          ListItem() {
            Text('自动计算并设置校准值')
              .itemDescription()
          }
          .descriptionContainer()
        }

        // 警报与通知
        ListItem() {
          Column() {
            Row() {
              Text('警报与通知')
                .itemTitle()
              Blank()
            }
            .listItemRow()
          }
          .listItemStyle()
        }.onClick(() => {
          animateTo({
            duration: 300,
            onFinish: () => {
              console.info('animation end');
            }
          }, () => {
            this.isAudioAnalysisExpanded = false;
            this.isAlertsAndNotificationsExpanded = !this.isAlertsAndNotificationsExpanded;
            this.isDataRecordingAndPrivacyExpanded = false;
            this.isDeviceSettingsExpanded = false;
            this.isAboutExpanded = false;
          })
        })

        ListItem() {
        }.dividerStyle() // 添加分隔符

        if (this.isAlertsAndNotificationsExpanded) {
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
                  .selectedColor($r('app.color.primary'))
                  .switchPointColor($r('app.color.background_primary'))
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
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ right: 8 })
              }
              .listItemRow()

              Slider({
                value: this.noiseThreshold,
                min: 30,
                max: 120,
                style: SliderStyle.InSet
              })
                .blockColor($r('app.color.primary'))
                .trackColor($r('app.color.background_secondary'))
                .selectedColor($r('app.color.primary'))
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
            Text('环境噪音超过设定阈值时，系统将发出警报提示')
              .itemDescription()
          }
          .descriptionContainer()
        }

        // 数据记录与隐私
        ListItem() {
          Column() {
            Row() {
              Text('数据记录与隐私')
                .itemTitle()
              Blank()
            }
            .listItemRow()
          }
          .listItemStyle()
        }.onClick(() => {
          animateTo({
            duration: 300,
            onFinish: () => {
              console.info('animation end');
            }
          }, () => {
            this.isAudioAnalysisExpanded = false;
            this.isAlertsAndNotificationsExpanded = false;
            this.isDataRecordingAndPrivacyExpanded = !this.isDataRecordingAndPrivacyExpanded;
            this.isDeviceSettingsExpanded = false;
            this.isAboutExpanded = false;
          })
        })

        ListItem() {
        }.dividerStyle() // 添加分隔符

        if (this.isDataRecordingAndPrivacyExpanded) {
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
                  .selectedColor($r('app.color.toggle_active'))
                  .switchPointColor($r('app.color.background_primary'))
                  .onChange((isOn: boolean) => {
                    void this.preferenceService.setBoolean(PreferenceKeyConstants.LOCATION, isOn);
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
                  .selectedColor($r('app.color.toggle_active'))
                  .switchPointColor($r('app.color.background_primary'))
                  .onChange((isOn: boolean) => {
                    void this.preferenceService.setBoolean(PreferenceKeyConstants.RECORD, isOn);
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
        }

        // 设备设置
        ListItem() {
          Column() {
            Row() {
              Text('设备设置')
                .itemTitle()
              Blank()
            }
            .listItemRow()
          }
          .listItemStyle()
        }.onClick(() => {
          animateTo({
            duration: 300,
            onFinish: () => {
              console.info('animation end');
            }
          }, () => {
            this.isAudioAnalysisExpanded = false;
            this.isAlertsAndNotificationsExpanded = false;
            this.isDataRecordingAndPrivacyExpanded = false;
            this.isDeviceSettingsExpanded = !this.isDeviceSettingsExpanded;
            this.isAboutExpanded = false;
          })
        })

        if (this.isDeviceSettingsExpanded) {
          // 后台运行设置
          ListItem() {
            Column() {
              Row() {
                Row() {
                  Image($r('app.media.ic_meter'))
                    .itemIcon()

                  Text($r('app.string.background_running'))
                    .itemTitle()
                }

                Blank()

                Toggle({ type: ToggleType.Switch, isOn: this.isBackgroundRunning })
                  .selectedColor($r('app.color.toggle_active'))
                  .switchPointColor($r('app.color.background_primary'))
                  .onChange((isOn: boolean) => {
                    void this.preferenceService.setBoolean(PreferenceKeyConstants.BACKGROUND_RUNNING, isOn);
                    this.isBackgroundRunning = isOn;
                  })
              }
              .listItemRow()
            }
            .listItemStyle()
          }

          ListItem() {
            Text(this.isBackgroundRunning ? $r('app.string.background_running_desc_on') : $r('app.string.background_running_desc_off'))
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
                  .selectedColor($r('app.color.toggle_active'))
                  .switchPointColor($r('app.color.background_primary'))
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

        // 关于
        ListItem() {
          Column() {
            Row() {
              Text('关于')
                .itemTitle()
              Blank()
            }
            .listItemRow()
          }
          .listItemStyle()
        }.onClick(() => {
          animateTo({
            duration: 300,
            onFinish: () => {
              console.info('animation end');
            }
          }, () => {
            this.isAudioAnalysisExpanded = false;
            this.isAlertsAndNotificationsExpanded = false;
            this.isDataRecordingAndPrivacyExpanded = false;
            this.isDeviceSettingsExpanded = false;
            this.isAboutExpanded = !this.isAboutExpanded;
          })
        })

        ListItem() {
        }.dividerStyle() // 添加分隔符

        if (this.isAboutExpanded) {
          // 隐私政策
          ListItem() {
            Column() {
              Row() {
                Row() {
                  Image($r('app.media.ic_info'))
                    .itemIcon()

                  Text('隐私政策')
                    .itemTitle()
                }

                Blank()
              }
              .listItemRow()
            }
            .listItemStyle()
          }.onClick(async () => {
            // 这里添加打开隐私政策的逻辑
            const uiContext = getContext(this) as common.UIAbilityContext;
            await privacyManager.requestAppPrivacyConsent(uiContext);
          })

          ListItem() {
            Text('查看应用的隐私政策')
              .itemDescription()
          }
          .descriptionContainer()
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.background_tertiary'))
      .margin({ top: 12 })

      // 给作者留言按钮
      Button('给作者留言')
        .width('90%')
        .height(40)
        .margin({ bottom: 30, top: 12 })
        .backgroundColor($r('app.color.toggle_active'))
        .onClick(() => {
          const context = getContext(this) as common.UIAbilityContext;
          const want: Want = {
            action: 'ohos.want.action.appdetail',
            uri: 'store://appgallery.huawei.com/app/detail?id=yu.zhang.myapplication.noise_meter&action=write-review'
          };
          context.startAbility(want).then(() => {
            console.info('Succeeded in starting Ability successfully.');
          }).catch((err:BusinessError) => {
            console.error(`Failed to start ability. Code: ${err.code}, message: ${err.message}`);
          });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_tertiary'))
  }
}