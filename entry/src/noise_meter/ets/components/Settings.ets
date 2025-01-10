import { PreferenceService } from '../../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';
import { CustomTitleBar } from '../../../library/ets/components/common/CustomTitleBar';
import { WeightingType, getWeightingDescription } from '../../../library/ets/constants/WeightingConstants';
import { AudioAnalysisMode, AudioPresets } from '../../../library/ets/common/AudioConfig';

@Extend(Image) function itemIcon() {
  .width(24)
  .height(24)
  .fillColor('#666666')
  .margin({ right: 8 })
}

@Extend(Text) function itemTitle() {
  .fontWeight(FontWeight.Medium)
  .fontColor('#000000')
  .fontSize(16)
}

@Extend(Text) function itemDescription() {
  .fontColor('#666666')
  .fontSize(14)
  .textAlign(TextAlign.Start)
  .margin({ left: 48 })
}

@Extend(Select) function selectStyle() {
  .backgroundColor(Color.White)
  .borderRadius(16)
  .padding({ left: 12, right: 12 })
  .font({ size: 16, weight: FontWeight.Normal, family: 'HarmonyHeiTi' })
  .selectedOptionFont({ size: 16, weight: FontWeight.Normal, family: 'HarmonyHeiTi' })
  .optionFont({ size: 16, weight: FontWeight.Normal, family: 'HarmonyHeiTi' })
}

@Extend(Column) function listItemStyle() {
  .width('100%')
  .padding({ left: 16, right: 16 })
  .backgroundColor('#FFFFFF')
}

@Extend(Row) function listItemRow() {
  .width('100%')
  .height(56)
  .alignItems(VerticalAlign.Center)
}

@Extend(Text) function detailText() {
  .fontColor('#666666')
  .fontSize(14)
  .margin({ top: 4, left: 48 })
}

@Extend(Row) function dividerStyle() {
  .width('100%')
  .height(1)
  .backgroundColor('#F5F5F5')
}

@Extend(ListItem) function descriptionContainer() {
  .backgroundColor('#F5F5F5')
  .padding({ top: 8, bottom: 12 })
}

@Extend(Text) function analysisDescription() {
  .fontColor('#666666')
  .fontSize(14)
  .textAlign(TextAlign.Start)
}

@Extend(Text) function analysisDetail() {
  .fontColor('#666666')
  .fontSize(14)
  .textAlign(TextAlign.Start)
  .margin({ top: 8 })
}

@ComponentV2
export struct Settings {
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  @Local isLocationEnabled: boolean = false;
  @Local isRecordEnabled: boolean = false;
  @Local selectedWeighting: WeightingType = WeightingType.A;
  @Local selectedAnalysisMode: AudioAnalysisMode = AudioAnalysisMode.BALANCED;

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
      case AudioAnalysisMode.FAST_RESPONSE:
        return 0;
      case AudioAnalysisMode.BALANCED:
        return 1;
      case AudioAnalysisMode.PRECISE:
        return 2;
      case AudioAnalysisMode.LOW_FREQUENCY:
        return 3;
      default:
        return 1;
    }
  }

  private getAnalysisModeFromIndex(index: number): AudioAnalysisMode {
    switch (index) {
      case 0:
        return AudioAnalysisMode.FAST_RESPONSE;
      case 1:
        return AudioAnalysisMode.BALANCED;
      case 2:
        return AudioAnalysisMode.PRECISE;
      case 3:
        return AudioAnalysisMode.LOW_FREQUENCY;
      default:
        return AudioAnalysisMode.BALANCED;
    }
  }

  private getAnalysisModeDisplayName(mode: AudioAnalysisMode): string {
    switch (mode) {
      case AudioAnalysisMode.FAST_RESPONSE:
        return '快速响应';
      case AudioAnalysisMode.BALANCED:
        return '平衡模式';
      case AudioAnalysisMode.PRECISE:
        return '精确分析';
      case AudioAnalysisMode.LOW_FREQUENCY:
        return '低频分析';
      default:
        return '平衡模式';
    }
  }

  private getAnalysisModeDescription(mode: AudioAnalysisMode): string {
    switch (mode) {
      case AudioAnalysisMode.FAST_RESPONSE:
        return '适合测量突发性噪声，响应速度快';
      case AudioAnalysisMode.BALANCED:
        return '日常使用的推荐模式，兼顾速度和准确性';
      case AudioAnalysisMode.PRECISE:
        return '适合专业分析，提供更精确的频率数据';
      case AudioAnalysisMode.LOW_FREQUENCY:
        return '专注于低频噪音，如机械设备和交通噪音';
      default:
        return '日常使用的推荐模式，兼顾速度和准确性';
    }
  }

  aboutToAppear() {
    this.isLocationEnabled = this.preferenceService.isEnabled(PreferenceKeyConstants.LOCATION);
    this.isRecordEnabled = this.preferenceService.isEnabled(PreferenceKeyConstants.RECORD);
    this.selectedWeighting = (this.preferenceService.getString(PreferenceKeyConstants.WEIGHTING) || WeightingType.A) as WeightingType;
    this.selectedAnalysisMode = (this.preferenceService.getString(PreferenceKeyConstants.ANALYSIS_MODE) || AudioAnalysisMode.BALANCED) as AudioAnalysisMode;
  }

  @Builder
  private buildDivider() {
    Row()
      .dividerStyle()
  }

  @Builder
  private buildDescription(text: ResourceStr | string) {
    Text(text)
      .itemDescription()
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
                Image($r('app.media.ic_audio_analysis'))
                  .itemIcon()

                Text('音频分析模式')
                  .itemTitle()
              }

              Blank()

              Select([
                { value: '快速响应' },
                { value: '平衡模式' },
                { value: '精确分析' },
                { value: '低频分析' }
              ])
                .selected(this.getAnalysisModeIndex(this.selectedAnalysisMode))
                .value(this.getAnalysisModeDisplayName(this.selectedAnalysisMode))
                .selectStyle()
                .onSelect((index: number) => {
                  const mode = this.getAnalysisModeFromIndex(index);
                  void this.preferenceService.setString(PreferenceKeyConstants.ANALYSIS_MODE, mode);
                  this.selectedAnalysisMode = mode;
                })
            }
            .listItemRow()
          }
          .listItemStyle()
        }

        ListItem() {
          Column() {
            Text(this.getAnalysisModeDescription(this.selectedAnalysisMode))
              .analysisDescription()
            Text(`FFT大小: ${AudioPresets.getConfig(this.selectedAnalysisMode).fftSize}`)
              .analysisDetail()
            Text(`处理间隔: ${AudioPresets.getConfig(this.selectedAnalysisMode).processInterval}ms`)
              .analysisDetail()
            Text(`频率分辨率: ${(44100 / AudioPresets.getConfig(this.selectedAnalysisMode).fftSize).toFixed(1)}Hz`)
              .analysisDetail()
            Text(`时间分辨率: ${(AudioPresets.getConfig(this.selectedAnalysisMode).fftSize / 44100 * 1000).toFixed(1)}ms`)
              .analysisDetail()
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
                Image($r('app.media.ic_weighting'))
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
          Text(this.isLocationEnabled ? '记录测量地点的经纬度坐标' : '不会采集位置信息')
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
          Text(this.isRecordEnabled ? '保存原始音频数据用于后期分析' : '仅记录分析结果')
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