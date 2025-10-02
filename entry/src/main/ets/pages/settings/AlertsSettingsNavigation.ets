import { PreferenceKeys } from '../../models/PreferenceKeys';
import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2, curves, PersistenceV2 } from '@kit.ArkUI';

// 导入新组件
import { AlertsStatusIndicator } from '../../components/alerts/AlertsStatusIndicator';
import { SmartThresholdPresets } from '../../components/alerts/SmartThresholdPresets';
import { TimeSchedulingPanel } from '../../components/alerts/TimeSchedulingPanel';
import { NotificationPreferences } from '../../components/alerts/NotificationPreferences';
import { AcousticExplanationPanel } from '../../components/alerts/AcousticExplanationPanel';

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

@Builder
export function AlertsSettingsBuilder() {
  AlertsSettings()
}

@ComponentV2
export struct AlertsSettings {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local as: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local gridColumns: number = 1;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    // 初始化时段调度阈值
    if (this.pk.daytime_alert_threshold === undefined) {
      this.pk.daytime_alert_threshold = 70;
    }
    if (this.pk.nighttime_alert_threshold === undefined) {
      this.pk.nighttime_alert_threshold = 50;
    }
  }

  // 获取当前有效阈值
  private getCurrentEffectiveThreshold(): number {
    if (!this.pk.alert_time_scheduling_enabled) {
      return this.pk.noise_threshold;
    }
    
    const currentHour = new Date().getHours();
    if (currentHour >= 6 && currentHour < 22) {
      return this.pk.daytime_alert_threshold;
    } else {
      return this.pk.nighttime_alert_threshold;
    }
  }

  // 处理阈值变化
  private onThresholdChange(value: number) {
    this.pk.noise_threshold = value;
  }

  // 处理预设变化
  private onPresetChange(preset: string) {
    this.pk.current_preset_threshold = preset;
  }

  // 处理时段调度启用状态变化
  private onTimeSchedulingEnabledChange(enabled: boolean) {
    this.pk.alert_time_scheduling_enabled = enabled;
  }

  // 处理白天阈值变化
  private onDaytimeThresholdChange(value: number) {
    this.pk.daytime_alert_threshold = value;
  }

  // 处理夜间阈值变化
  private onNighttimeThresholdChange(value: number) {
    this.pk.nighttime_alert_threshold = value;
  }

  // 处理声音通知变化
  private onSoundAlertChange(enabled: boolean) {
    this.pk.sound_alert_enabled = enabled;
  }

  // 处理振动通知变化
  private onVibrationAlertChange(enabled: boolean) {
    this.pk.vibration_alert_enabled = enabled;
  }

  // 处理视觉通知变化
  private onVisualAlertChange(enabled: boolean) {
    this.pk.visual_alert_enabled = enabled;
  }

  // 处理系统通知变化
  private onSystemNotificationChange(enabled: boolean) {
    this.pk.system_notification_enabled = enabled;
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 警报状态指示器
      AlertsStatusIndicator({
        currentDecibel: this.as.db,
        alertThreshold: this.getCurrentEffectiveThreshold(),
        isAlertEnabled: this.pk.noise_alarm_enabled
      })

      // 智能阈值预设
      SmartThresholdPresets({
        currentThreshold: this.pk.noise_threshold,
        currentPreset: this.pk.current_preset_threshold,
        onThresholdChange: (value: number) => {
          this.onThresholdChange(value);
        },
        onPresetChange: (preset: string) => {
          this.onPresetChange(preset);
        }
      })

      // 时段调度设置
      TimeSchedulingPanel({
        isEnabled: this.pk.alert_time_scheduling_enabled,
        daytimeThreshold: this.pk.daytime_alert_threshold,
        nighttimeThreshold: this.pk.nighttime_alert_threshold,
        onEnabledChange: (enabled: boolean) => {
          this.onTimeSchedulingEnabledChange(enabled);
        },
        onDaytimeThresholdChange: (value: number) => {
          this.onDaytimeThresholdChange(value);
        },
        onNighttimeThresholdChange: (value: number) => {
          this.onNighttimeThresholdChange(value);
        }
      })

      // 通知偏好设置
      NotificationPreferences({
        soundEnabled: this.pk.sound_alert_enabled,
        vibrationEnabled: this.pk.vibration_alert_enabled,
        visualEnabled: this.pk.visual_alert_enabled,
        systemNotificationEnabled: this.pk.system_notification_enabled,
        onSoundChange: (enabled: boolean) => {
          this.onSoundAlertChange(enabled);
        },
        onVibrationChange: (enabled: boolean) => {
          this.onVibrationAlertChange(enabled);
        },
        onVisualChange: (enabled: boolean) => {
          this.onVisualAlertChange(enabled);
        },
        onSystemNotificationChange: (enabled: boolean) => {
          this.onSystemNotificationChange(enabled);
        }
      })

      // 专业声学解释
      AcousticExplanationPanel()

      // 保留原有的基础设置（兼容性）
      Column({ space: DesignConstants.SPACING_MD }) {
        // 噪音阈值警报的开关
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Row() {
              Image($r('app.media.ic_alarm'))
                .itemIcon()

              Text('噪音警报')
                .itemTitle()
            }.layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.pk.noise_alarm_enabled })
              .onChange((isOn: boolean) => {
                this.pk.noise_alarm_enabled = isOn;
              })
          }
          .listItemRow()

          Text(this.pk.noise_alarm_enabled ? 
            '检测到噪音超过阈值时将触发警报' : 
            '系统不会发出噪音超标警报')
            .itemDescription()
        }
        .cardStyle()
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.background_secondary'))
  }
}
