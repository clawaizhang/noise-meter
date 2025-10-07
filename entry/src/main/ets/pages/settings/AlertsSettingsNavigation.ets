import { PreferenceKeys } from '../../models/PreferenceKeys';
import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2, curves, PersistenceV2, promptAction, EditableTitleBar, EditableLeftIconType } from '@kit.ArkUI';

// 导入新组件
import { AlertsStatusIndicator } from '../../components/alerts/AlertsStatusIndicator';
import { EnhancedThresholdManager } from '../../components/alerts/EnhancedThresholdManager';
import { NotificationPreferences } from '../../components/alerts/NotificationPreferences';
import { AcousticExplanationPanel } from '../../components/alerts/AcousticExplanationPanel';
import { ThresholdConfig } from '../../models/ThresholdConfig';

export interface AlertsSettingsProps {
  onSave: () => void;
  onClose: () => void;
}

@Builder
export function AlertsSettingsBuilder(props:AlertsSettingsProps) {
  AlertsSettings(props)
}

@ComponentV2
export struct AlertsSettings {
  @Event onSave: () => void;
  @Event onClose: () => void;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local gridColumns: number = 1;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  // 临时状态变量
  @Local private tempSystemNotificationEnabled: boolean = this.pk.system_notification_enabled;
  @Local private tempThresholdConfig: ThresholdConfig = ThresholdConfig.clone(this.pk.alarm_threshold);

  aboutToAppear() {
  }

  // 获取当前有效阈值（基于临时配置）
  private getCurrentEffectiveThreshold(): number {
    // 简化实现：返回临时配置的基础阈值
    return this.tempThresholdConfig.baseThreshold;
  }

  // 处理系统通知变化 - 只更新临时状态
  private onSystemNotificationChange(enabled: boolean) {
    this.tempSystemNotificationEnabled = enabled;
  }

  // 处理阈值配置变化 - 只更新临时状态
  private onThresholdConfigChange(config: ThresholdConfig) {
    ThresholdConfig.copyFrom(this.tempThresholdConfig,config);
  }

  // 处理确认操作
  private handleConfirm() {
    // 应用临时状态到持久化存储
    this.pk.system_notification_enabled = this.tempSystemNotificationEnabled;
    ThresholdConfig.copyFrom(this.tempThresholdConfig, this.pk.alarm_threshold);

    // 显示保存成功提示，显示具体的设置结果
    const thresholdValue = this.getCurrentEffectiveThreshold();
    const notificationMsg = this.tempSystemNotificationEnabled ? `警报通知已开启，阈值${thresholdValue}dB` : '警报通知已关闭';
    promptAction.showToast({
      message: notificationMsg,
      duration: 2000
    });

    // 关闭弹窗
    this.onSave();
  }

  build() {
    Column({ space: 0 }) {
      // 使用EditableTitleBar提供标准的编辑界面标题栏
      EditableTitleBar({
        leftIconStyle: EditableLeftIconType.Cancel,
        title: '警报与通知',
        isSaveIconRequired: true,
        onSave: () => {
          this.handleConfirm();
        },
        onCancel: () => {
          this.onClose();
        }
      })

      // 可滚动内容区域
      Scroll() {
        Column({ space: DesignConstants.SPACING_LG }) {
          // 警报状态指示器
          AlertsStatusIndicator({
            currentDecibel: this.ak.uiDisplayState.displayDb,
            alertThreshold: this.getCurrentEffectiveThreshold(),
            isAlertEnabled: this.tempSystemNotificationEnabled
          })


          // 系统通知设置
          NotificationPreferences({
            systemNotificationEnabled: this.tempSystemNotificationEnabled,
            onSystemNotificationChange: (enabled: boolean) => {
              this.onSystemNotificationChange(enabled);
            }
          })

          EnhancedThresholdManager({
            currentConfig: this.tempThresholdConfig,
            onConfigChange: (config: ThresholdConfig) => {
              this.onThresholdConfigChange(config);
            }
          })


          // 专业声学解释
          AcousticExplanationPanel()
        }
        .width('100%')
        .margin({ bottom: 72 })
        .padding(DesignConstants.SPACING_LG)
        .backgroundColor($r('sys.color.background_secondary'))
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Auto)
      .scrollable(ScrollDirection.Vertical)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
