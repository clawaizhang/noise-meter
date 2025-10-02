import { PreferenceKeys } from '../../models/PreferenceKeys';
import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2, curves, PersistenceV2 } from '@kit.ArkUI';

// 导入新组件
import { AlertsStatusIndicator } from '../../components/alerts/AlertsStatusIndicator';
import { EnhancedThresholdManager } from '../../components/alerts/EnhancedThresholdManager';
import { NotificationPreferences } from '../../components/alerts/NotificationPreferences';
import { AcousticExplanationPanel } from '../../components/alerts/AcousticExplanationPanel';
import { DEFAULT_THRESHOLD_CONFIG, ThresholdConfig } from '../../models/ThresholdConfig';
import { ThresholdManager } from '../../services/ThresholdManager';

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
    // 初始化阈值管理器配置
    // 这里可以添加从持久化存储加载配置的逻辑
  }

  // 获取当前有效阈值（兼容原有逻辑）
  private getCurrentEffectiveThreshold(): number {
    return ThresholdManager.getCurrentEffectiveThreshold();
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

      EnhancedThresholdManager()

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
