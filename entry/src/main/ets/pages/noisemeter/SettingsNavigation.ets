import { navigationStack } from '../../constants/ProviderConstant';
import { curves, PersistenceV2 } from '@kit.ArkUI';
import { DialogHub } from '@hadss/dialoghub';
import { AudioAnalysisSettingsBuilder } from '../settings/AudioAnalysisSettingsNavigation';
import { AlertsSettingsBuilder } from '../settings/AlertsSettingsNavigation';
import { DataPrivacySettingsBuilder } from '../settings/DataPrivacySettingsNavigation';
import { DeviceSettingsBuilder } from '../settings/DeviceSettingsNavigation';
import { AboutSettingsBuilder } from '../settings/AboutSettingsNavigation';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DesignConstants } from '../../constants/DesignConstants';
import { AudioAnalysisMode, AudioPresets } from '../../common/AudioConfig';
import { getWeightingDescription, WeightingType } from '../../constants/WeightingConstants';

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
export struct Settings {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  @Local analysisModeDescription: string = '';
  @Local analysisModeDetails: string[] = [];
  @Local isModeChangeEnabled: boolean = true;
  @Local remainingTime: number = 0;

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

  // 导航到音频分析设置页面
  private navigateToAudioAnalysis = () => {
    DialogHub.getSheet()
      .setStyle({ title: { title: '声级校准' }, backgroundColor: $r('sys.color.background_secondary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('settingsId')
      .setContent(wrapBuilder(AudioAnalysisSettingsBuilder))
      .build()
      .show();
  }
  // 导航到警报与通知设置页面
  private navigateToAlerts = () => {
    DialogHub.getSheet()
      .setStyle({ title: { title: '警报与通知' }, backgroundColor: $r('sys.color.background_secondary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('settingsId')
      .setContent(wrapBuilder(AlertsSettingsBuilder))
      .build()
      .show();
  }
  // 导航到数据记录与隐私设置页面
  private navigateToDataPrivacy = () => {
    DialogHub.getSheet()
      .setStyle({ title: { title: '数据记录与隐私' }, backgroundColor: $r('sys.color.background_secondary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('settingsId')
      .setContent(wrapBuilder(DataPrivacySettingsBuilder))
      .build()
      .show();
  }
  // 导航到设备设置页面
  private navigateToDeviceSettings = () => {
    DialogHub.getSheet()
      .setStyle({ title: { title: '设备设置' }, backgroundColor: $r('sys.color.background_secondary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('settingsId')
      .setContent(wrapBuilder(DeviceSettingsBuilder))
      .build()
      .show();
  }
  // 导航到关于页面
  private navigateToAbout = () => {
    DialogHub.getSheet()
      .setStyle({ title: { title: '关于' }, backgroundColor: $r('sys.color.background_secondary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('settingsId')
      .setContent(wrapBuilder(AboutSettingsBuilder))
      .build()
      .show();
  }

  build() {
    GridRow({
      columns:
      {
        sm: 1,
        md: 2,
        lg: 2,
        xl: 3
      },
      breakpoints: { reference: BreakpointsReference.WindowSize }
    , gutter: 16
    }) {
      // 分贝计权设置
      GridCol() {
        Column({ space: 8 }) {
          Row() {
            Row({ space: 8 }) {
              Image($r('sys.media.ohos_ic_public_device_smartscreen'))
                .itemIcon()
              Text('显示模式')
                .itemTitle()
            }.layoutWeight(1)

            Select([
              { value: '跟随系统' },
              { value: '浅色' },
              { value: '深色' }
            ])
              .selected(this.getDisplayModeIndex(this.pk.display_mode))
              .value(this.getDisplayModeText(this.pk.display_mode))
              .onSelect((index: number) => {
                this.pk.display_mode = this.getDisplayMode(index);
              })
          }
          .listItemRow()
        }
        .cardStyle()
      }

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

      // 音频分析设置
      this.buildListItem({
        icon: $r('app.media.ic_audio_analysis'),
        title: '声级校准',
        desc: '声级校准、自动校准等设置',
        action: () => {
          this.navigateToAudioAnalysis();
        }
      })

      this.buildListItem({
        icon: $r('app.media.ic_alarm'),
        title: '警报与通知',
        desc: '噪音警报阈值和通知设置',
        action: () => {
          this.navigateToAlerts();
        }
      })

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
              Image($r('app.media.ic_meter'))
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

      GridCol() {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Row() {
              Image($r('app.media.ic_info'))
                .itemIcon()

              Text('小猫咪🐱')
                .itemTitle()
            }.layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.pk.cat_enabled })
              .selectedColor($r('app.color.toggle_active'))
              .switchPointColor($r('app.color.background_primary'))
              .onChange((isOn: boolean) => {
                this.pk.cat_enabled = isOn;
              })
          }
          .listItemRow()
          Text(this.pk.cat_enabled ? '和小猫咪🐱一起测分贝, 设备可能发热' : '小猫咪走啦')
            .itemDescription()
        }
        .cardStyle()
      }

      GridCol() {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Row() {
              Image($r('app.media.ic_mic'))
                .itemIcon()

              Text('自然音频')
                .itemTitle()
            }.layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.pk.nature_sound_enabled })
              .selectedColor($r('app.color.toggle_active'))
              .switchPointColor($r('app.color.background_primary'))
              .onChange((isOn: boolean) => {
                this.pk.nature_sound_enabled = isOn;
              })
          }
          .listItemRow()
          Text(this.pk.nature_sound_enabled ? '可以播放自然音频' : '自然音频已关闭')
            .itemDescription()
        }
        .cardStyle()
      }

      this.buildListItem({
        icon: $r('app.media.ic_info'),
        title: '关于',
        desc: '应用信息、隐私政策和技术支持',
        action: () => {
          this.navigateToAbout();
        }
      })
    }.padding(16).backgroundColor($r('sys.color.background_secondary'))
    .id
    ('settingsId'
    )
  }

  getDisplayModeIndex(displayMode: string): number {
    switch (displayMode) {
      case 'default':
        return 0;
      case 'light':
        return 1;
      case 'dark':
        return 2;
      default:
        return 0;
    }
  }

  getDisplayModeText(displayMode: string): string {
    switch (displayMode) {
      case 'default':
        return "跟随系统";
      case 'light':
        return "浅色";
      case 'dark':
        return "深色";
      default:
        return "跟随系统";
    }
  }

  getDisplayMode(index: number): string {
    switch (index) {
      case 0:
        return 'default';
      case 1:
        return 'light';
      case 2:
        return 'dark';
      default:
        return 'default';
    }
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