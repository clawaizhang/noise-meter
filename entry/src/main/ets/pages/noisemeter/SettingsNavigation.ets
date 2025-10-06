import { navigationStack } from '../../constants/ProviderConstant';
import { curves, PersistenceV2, promptAction } from '@kit.ArkUI';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { DialogStyleManager } from '../../utils/DialogStyleManager';
import { AudioAnalysisSettingsBuilder } from '../settings/AudioAnalysisSettingsNavigation';
import { AlertsSettingsBuilder } from '../settings/AlertsSettingsNavigation';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DesignConstants } from '../../constants/DesignConstants';
import { AudioAnalysisMode, AudioPresets } from '../../common/AudioConfig';
import { getWeightingDescription, WeightingType } from '../../constants/WeightingConstants';
import {
  TimeWeightingDialogBuilder,
  TimeWeightingDialogParams,
} from '../../components/time-weighting/TimeWeightingDialog';
import {
  FrequencyWeightingDialogBuilder,
  FrequencyWeightingDialogParams,
} from '../../components/frequency-weighting/FrequencyWeightingDialog';
import {
  AutoSaveDialogParams,
  AutoSaveSettings,
  AutoSaveSettingsDialogBuilder,
} from '../../components/auto-save/AutoSaveSettingsDialog';
import { ThresholdManager } from '../../services/ThresholdManager';
import { PremiumFeature } from '../../components/membership/PremiumFeature';

@Builder
export function SettingsBuilder() {
  Settings()
}

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

@Extend(Column)
function cardStyle() {
  .backgroundColor($r('sys.color.comp_background_primary'))
  .justifyContent(FlexAlign.Start)
  .alignItems(HorizontalAlign.Start)
  .borderRadius(16)
  .padding(16)
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
    .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
    .combine(TransitionEffect.translate({ x: -150, y: 0 }).animation({ curve: curves.springMotion() })))
}

@Extend(Row)
function listItemRow() {
  .alignItems(VerticalAlign.Center)
  .justifyContent(FlexAlign.Start)
}

@Extend(Text)
function itemDescription() {
  .fontColor($r('sys.color.font_secondary'))
  .fontSize(DesignConstants.FONT_SIZE_MD)
  .textAlign(TextAlign.Start)
  .alignSelf(ItemAlign.Start)
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

interface ListItemParam {
  icon: Resource;
  title: string;
  desc: string;
  action: () => void;
}

@ComponentV2
struct Settings {
  // DialogHub实例缓存
  private audioAnalysisDialog: InfSheet | null = null;
  private alertsDialog: InfSheet | null = null;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  @Local analysisModeDescription: string = '';
  @Local analysisModeDetails: string[] = [];
  @Local remainingTime: number = 0;
  private readonly COOLDOWN_DURATION: number = 500; // 0.5秒冷却时间

  // 获取声级校准显示值（右侧显示）
  private getCalibrationDisplayValue(): string {
    const value = this.pk.calibration_value;
    if (value === 0) {
      return "0 dB";
    } else if (value > 0) {
      return `+${value.toFixed(1)} dB`;
    } else {
      return `${value.toFixed(1)} dB`;
    }
  }

  // 获取声级校准描述（下方显示）
  private getCalibrationDescription(): string {
    const value = this.pk.calibration_value;
    if (value === 0) {
      return "当前校准值为0，未进行校准调整";
    } else if (value > 0) {
      return `当前校准值增加${value.toFixed(1)}dB，用于增益调整`;
    } else {
      return `当前校准值减少${Math.abs(value).toFixed(1)}dB，用于衰减调整`;
    }
  }

  // 获取警报与通知显示值（右侧显示）
  private getAlertsDisplayValue(): string {
    return this.pk.system_notification_enabled ? "开启" : "关闭";
  }

  // 获取警报与通知描述（下方显示）
  private getAlertsDescription(): string {
    const enabled = this.pk.system_notification_enabled;
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();
    const timePeriod = ThresholdManager.getCurrentTimePeriod();

    if (!enabled) {
      return "警报通知已关闭，不会发送任何通知";
    } else {
      return `当噪音超过${threshold}dB时发送${timePeriod}警报通知`;
    }
  }

  // 获取自动保存显示值（右侧显示）
  private getAutoSaveDisplayValue(): string {
    return this.pk.auto_save_enabled ? "开启" : "关闭";
  }

  // 获取自动保存描述（下方显示）
  private getAutoSaveDescription(): string {
    const enabled = this.pk.auto_save_enabled;
    const interval = this.pk.auto_save_interval;

    if (!enabled) {
      return "自动保存已关闭，需要手动保存数据";
    } else {
      return `系统会每隔${interval}分钟自动保存一次测量数据`;
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
        return '自定义模式';
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
        return `时间常数${this.pk.custom_audio_config.updateInterval}ms`;
    }
  }

  aboutToAppear() {
    this.updateAnalysisModeCache(this.pk.custom_audio_config_enabled ? AudioAnalysisMode.CUSTOM_TIME_WEIGHTING :
    this.pk.audio_analysis_mode);
  }

  private updateAnalysisModeCache(selectedMode: AudioAnalysisMode) {
    this.analysisModeDescription = this.getAnalysisModeDescription(selectedMode);
    const config = AudioPresets.getConfig(selectedMode);
    this.analysisModeDetails[0] = `FFT大小: ${config.fftSize}`;
    this.analysisModeDetails[1] = `频率分辨率: ${(44100 / config.fftSize).toFixed(1)}Hz`;
    this.analysisModeDetails[2] = `时间分辨率: ${(config.fftSize / 44100 * 1000).toFixed(1)}ms`;
    this.analysisModeDetails[3] = `更新间隔: ${config.updateInterval}ms`;
  }

  // 导航到音频分析设置页面
  private navigateToAudioAnalysis = () => {
    if (!this.audioAnalysisDialog) {
      this.audioAnalysisDialog = DialogHub.getSheet()
        .setStyle({ title: { title: '声级校准' }, backgroundColor: $r('sys.color.background_secondary') })
        .setConfig({ scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT, enableOutsideInteractive: true })
        .setComponentTargetId('mainId')
        .setContent(wrapBuilder(AudioAnalysisSettingsBuilder))
        .build();

      // 注册Dialog到样式管理器
      DialogStyleManager.registerDialog(this.audioAnalysisDialog);
    }
    this.audioAnalysisDialog.show();
  }
  // 导航到警报与通知设置页面
  private navigateToAlerts = () => {
    if (!this.alertsDialog) {
      this.alertsDialog = DialogHub.getSheet()
        .setStyle({ title: { title: '警报与通知' }, backgroundColor: $r('sys.color.background_secondary') })
        .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS, enableOutsideInteractive: true })
        .setComponentTargetId('mainId')
        .setContent(wrapBuilder(AlertsSettingsBuilder))
        .build();

      // 注册Dialog到样式管理器
      DialogStyleManager.registerDialog(this.alertsDialog);
    }
    this.alertsDialog.show();
  }
  // 打开音频分析模式选择弹框
  private openTimeWeightingDialog = () => {
    let timeWeightingDialog: InfSheet;
    let param: TimeWeightingDialogParams = {
      currentMode: this.pk.audio_analysis_mode,
      onSettingsApplied: (selectedMode: AudioAnalysisMode) => {
        // 即时生效：立即应用新设置
        this.handleTimeWeightingModeChange(selectedMode);
      },
      onClose: () => {
        timeWeightingDialog?.dismiss();
      }
    }
    timeWeightingDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS, enableOutsideInteractive: true })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(TimeWeightingDialogBuilder), param)
      .build();

    timeWeightingDialog.show();
  }
  // 打开频率加权模式选择弹框
  private openFrequencyWeightingDialog = () => {
    let frequencyWeightingDialog: InfSheet;
    let param: FrequencyWeightingDialogParams = {
      currentWeighting: this.pk.weighting_type,
      onSettingsApplied: (selectedWeighting: WeightingType) => {
        // 即时生效：立即应用新设置
        this.pk.weighting_type = selectedWeighting;
      },
      onClose: () => {
        frequencyWeightingDialog?.dismiss();
      }
    }
    frequencyWeightingDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS, enableOutsideInteractive: true })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(FrequencyWeightingDialogBuilder), param)
      .build();

    frequencyWeightingDialog.show();
  }
  // 打开自动保存设置弹框
  private openAutoSaveDialog = () => {
    let autoSaveDialog: InfSheet;
    let param: AutoSaveDialogParams = {
      onClose: () => {
        autoSaveDialog?.dismiss();
      },
      onSettingsApplied: (settings: AutoSaveSettings) => {
        // 应用设置并显示统一提示
        this.applyAutoSaveSettings(settings);
      }
    }
    autoSaveDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS, enableOutsideInteractive: true })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(AutoSaveSettingsDialogBuilder), param)
      .build();

    autoSaveDialog.show();
  }

  // 应用自动保存设置
  private applyAutoSaveSettings(settings: AutoSaveSettings) {
    const pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

    // 更新持久化存储
    pk.auto_save_enabled = settings.enabled;
    pk.auto_save_interval = settings.interval;

    // 显示统一提示
    if (settings.enabled) {
      promptAction.showToast({
        message: `自动保存已启用：每${settings.interval}分钟保存`,
        duration: 2000
      });
    } else {
      promptAction.showToast({
        message: '自动保存已禁用',
        duration: 2000
      });
    }
  }

  // 处理音频分析模式变化
  private handleTimeWeightingModeChange(selectedMode: AudioAnalysisMode) {

    this.pk.audio_analysis_mode = selectedMode;
    this.updateAnalysisModeCache(selectedMode);

    // 启动冷却计时器
    this.remainingTime = this.COOLDOWN_DURATION;
    const interval = setInterval(() => {
      this.remainingTime -= 100;
      if (this.remainingTime <= 0) {
        clearInterval(interval);
        this.remainingTime = 0;
      }
    }, 100);
  }

  build() {
    GridRow({
      columns:
      1,
      breakpoints: { reference: BreakpointsReference.WindowSize }
    , gutter: 16
    }) {

      // 音频分析模式
      GridCol() {
        Column() {
          Row() {
            Row({ space: 8 }) {
              Image($r('app.media.ic_time_weighting'))
                .itemIcon()
              Text('音频分析模式')
                .itemTitle()
            }.layoutWeight(1)

            Row() {
              Text(this.remainingTime > 0 ? `${(this.remainingTime / 1000).toFixed(1)}秒` : '')
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('sys.color.font_secondary'))
                .margin({ right: DesignConstants.SPACING_XS })

              // 点击区域，触发弹框选择
              Row({ space: DesignConstants.SPACING_XS }) {
                Text(this.getAnalysisModeDisplayName(this.pk.audio_analysis_mode))
                  .fontSize(DesignConstants.FONT_SIZE_MD)
                  .fontColor($r('sys.color.font_primary'))
                  .fontWeight(FontWeight.Medium)

                Image($r('sys.media.ohos_ic_public_arrow_right'))
                  .width(DesignConstants.ICON_SIZE_SM)
                  .height(DesignConstants.ICON_SIZE_SM)
                  .fillColor($r('sys.color.font_secondary'))
              }
              .padding({
                left: DesignConstants.SPACING_MD,
                right: DesignConstants.SPACING_MD,
                top: DesignConstants.SPACING_SM,
                bottom: DesignConstants.SPACING_SM
              })
              .backgroundColor($r('sys.color.comp_background_primary'))
              .borderRadius(DesignConstants.BORDER_RADIUS_SM)
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
        }.onClick(() => {
          this.openTimeWeightingDialog();
        })
        .cardStyle()
      }

      // 频率加权设置
      GridCol() {
        Column() {
          Row() {
            Row({ space: 8 }) {
              Image($r('app.media.ic_frequency_weighting'))
                .itemIcon()
              Text('频率加权')
                .itemTitle()
            }.layoutWeight(1)

            // 点击区域，触发弹框选择
            Row({ space: DesignConstants.SPACING_XS }) {
              Text(this.pk.weighting_type + '计权')
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Medium)

              Image($r('sys.media.ohos_ic_public_arrow_right'))
                .width(DesignConstants.ICON_SIZE_SM)
                .height(DesignConstants.ICON_SIZE_SM)
                .fillColor($r('sys.color.font_secondary'))
            }
            .padding({
              left: DesignConstants.SPACING_MD,
              right: DesignConstants.SPACING_MD,
              top: DesignConstants.SPACING_SM,
              bottom: DesignConstants.SPACING_SM
            })
            .backgroundColor($r('sys.color.comp_background_primary'))
            .borderRadius(DesignConstants.BORDER_RADIUS_SM)
          }
          .listItemRow()

          Text(getWeightingDescription(this.pk.weighting_type))
            .itemDescription()
        }.onClick(() => {
          this.openFrequencyWeightingDialog();
        })
        .cardStyle()
      }

      // 声级校准设置
      GridCol() {
        Column() {
          Row() {
            Row({ space: 8 }) {
              Image($r('app.media.ic_audio_analysis'))
                .itemIcon()
              Text('声级校准')
                .itemTitle()
            }.layoutWeight(1)

            // 点击区域，触发弹框选择
            Row({ space: DesignConstants.SPACING_XS }) {
              Text(this.getCalibrationDisplayValue())
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Medium)

              Image($r('sys.media.ohos_ic_public_arrow_right'))
                .width(DesignConstants.ICON_SIZE_SM)
                .height(DesignConstants.ICON_SIZE_SM)
                .fillColor($r('sys.color.font_secondary'))
            }
            .padding({
              left: DesignConstants.SPACING_MD,
              right: DesignConstants.SPACING_MD,
              top: DesignConstants.SPACING_SM,
              bottom: DesignConstants.SPACING_SM
            })
            .backgroundColor($r('sys.color.comp_background_primary'))
            .borderRadius(DesignConstants.BORDER_RADIUS_SM)
          }
          .listItemRow()

          Text(this.getCalibrationDescription())
            .itemDescription()
        }.onClick(() => {
          this.navigateToAudioAnalysis();
        })
        .cardStyle()
      }

      // 警报与通知设置
      GridCol() {
        Column() {
          Row() {
            Row({ space: 8 }) {
              Image($r('app.media.ic_alarm'))
                .itemIcon()
              Text('警报与通知')
                .itemTitle()
            }.layoutWeight(1)

            // 点击区域，触发弹框选择
            Row({ space: DesignConstants.SPACING_XS }) {
              Text(this.getAlertsDisplayValue())
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Medium)

              Image($r('sys.media.ohos_ic_public_arrow_right'))
                .width(DesignConstants.ICON_SIZE_SM)
                .height(DesignConstants.ICON_SIZE_SM)
                .fillColor($r('sys.color.font_secondary'))
            }
            .padding({
              left: DesignConstants.SPACING_MD,
              right: DesignConstants.SPACING_MD,
              top: DesignConstants.SPACING_SM,
              bottom: DesignConstants.SPACING_SM
            })
            .backgroundColor($r('sys.color.comp_background_primary'))
            .borderRadius(DesignConstants.BORDER_RADIUS_SM)
          }
          .listItemRow()

          Text(this.getAlertsDescription())
            .itemDescription()
        }.onClick(() => {
          this.navigateToAlerts();
        })
        .cardStyle()
      }

      // 自动保存设置
      GridCol() {
        PremiumFeature({ featureName: '自动保存', featureDesc: '自动保存功能将自动保存您的录音' }) {
          Column() {
            Row() {
              Row({ space: 8 }) {
                Image($r('app.media.ic_save'))
                  .itemIcon()
                Text('自动保存')
                  .itemTitle()
              }.layoutWeight(1)

              // 点击区域，触发弹框选择
              Row({ space: DesignConstants.SPACING_XS }) {
                Text(this.getAutoSaveDisplayValue())
                  .fontSize(DesignConstants.FONT_SIZE_MD)
                  .fontColor($r('sys.color.font_primary'))
                  .fontWeight(FontWeight.Medium)

                Image($r('sys.media.ohos_ic_public_arrow_right'))
                  .width(DesignConstants.ICON_SIZE_SM)
                  .height(DesignConstants.ICON_SIZE_SM)
                  .fillColor($r('sys.color.font_secondary'))
              }
              .padding({
                left: DesignConstants.SPACING_MD,
                right: DesignConstants.SPACING_MD,
                top: DesignConstants.SPACING_SM,
                bottom: DesignConstants.SPACING_SM
              })
              .backgroundColor($r('sys.color.comp_background_primary'))
              .borderRadius(DesignConstants.BORDER_RADIUS_SM)
            }
            .listItemRow()

            Text(this.getAutoSaveDescription())
              .itemDescription()
          }.onClick(() => {
            this.openAutoSaveDialog();
          })
          .cardStyle()
        }
      }


      // this.buildListItem({
      //   icon: $r('app.media.ic_security'),
      //   title: '数据记录与隐私',
      //   desc: '地理位置、音频记录等隐私设置',
      //   action: () => {
      //     this.navigateToDataPrivacy();
      //   }
      // })

      // this.buildListItem({
      //   icon: $r('app.media.ic_settings'),
      //   title: '设备设置',
      //   desc: '屏幕常亮、后台运行等设备设置',
      //   action: () => {
      //     this.navigateToDeviceSettings();
      //   }
      // })

      // 位置开关
      GridCol() {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Row() {
              Image($r('app.media.ic_location'))
                .itemIcon()

              Text('地理位置')
                .itemTitle()
            }.layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.pk.location_enabled })
              .selectedColor($r('app.color.toggle_active'))
              .switchPointColor($r('app.color.background_primary'))
              .onChange((isOn: boolean) => {
                this.pk.location_enabled = isOn;
              })
          }
          .listItemRow()

          Text(this.pk.location_enabled ? '记录检测地点的位置信息' : '不会采集地理位置信息')
            .itemDescription()
        }
        .cardStyle()
      }

      // 录音开关
      GridCol() {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Row() {
              Image($r('app.media.ic_mic'))
                .itemIcon()

              Text('音频记录')
                .itemTitle()
            }.layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.pk.record_enabled })
              .selectedColor($r('app.color.toggle_active'))
              .switchPointColor($r('app.color.background_primary'))
              .onChange((isOn: boolean) => {
                this.pk.record_enabled = isOn;
              })
          }
          .listItemRow()

          Text(this.pk.record_enabled ? '保存原始音频数据用于后期分析' : '不会保存音频数据')
            .itemDescription()
        }
        .cardStyle()
      }

      // 后台运行设置
      GridCol() {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Row() {
              Image($r('app.media.ic_running'))
                .itemIcon()

              Text($r('app.string.background_running'))
                .itemTitle()
            }.layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.pk.background_running })
              .selectedColor($r('app.color.toggle_active'))
              .switchPointColor($r('app.color.background_primary'))
              .onChange((isOn: boolean) => {
                this.pk.background_running = isOn;
              })
          }
          .listItemRow()

          Text(this.pk.background_running ? $r('app.string.background_running_desc_on') :
          $r('app.string.background_running_desc_off'))
            .itemDescription()
        }
        .cardStyle()
      }

    }.padding(16).backgroundColor($r('sys.color.background_secondary'))
    .id
    ('settingsId'
    )
  }

  @
  Builder
  buildListItem(param:
    ListItemParam
  ) {
    GridCol({ span: 1 }) {
      Column({ space: 8 }) {
        Row() {
          Row() {
            Image(param.icon)
              .height(20)
              .width(20)
              .fillColor($r('sys.color.font_primary'));
            Text(param.title);
          }.layoutWeight(1);

          Image($r('app.media.ic_arrow_right'))
            .fillColor($r('sys.color.font_primary'))
            .height(24)
            .width(24);
        }.justifyContent(FlexAlign.End);

        Text(param.desc)
          .fontSize(14)
          .fontColor($r('sys.color.font_secondary'));
      }.alignItems(HorizontalAlign.Start);
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .onClick(param.action)
    .padding(16)
    .borderRadius(16)
    .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
      .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
      .combine(TransitionEffect.translate({ x: -150, y: 0 }).animation({ curve: curves.springMotion() })))
  }
}