import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DesignConstants } from '../../constants/DesignConstants';
import { ThresholdManager } from '../../services/ThresholdManager';
import { AlertService } from '../../services/AlertService';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { NotificationPreferences } from './NotificationPreferences';

@ComponentV2
export struct AlertsContent {
  // 通过AppKeys获取实时数据
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  // 警报服务
  private alertService: AlertService = AlertService.getInstance(getContext() as common.UIAbilityContext,this.pk);

  aboutToAppear(): void {
    // 组件加载时更新权限状态
    this.alertService.updateSystemPermissionStatus();
  }

  aboutToDisappear(): void {
    // 组件销毁时重置警报状态
    this.alertService.resetAlertState();
  }

  @Monitor('ak.uiDisplayState.displayDb')
  async onDbChange(monitor: IMonitor) {
    const currentDecibel = monitor.value<number>()?.now;
    if (currentDecibel !== undefined) {
      await this.checkAlertStatus(currentDecibel);
    }
  }

  // 检查警报状态
  private async checkAlertStatus(currentDecibel: number): Promise<void> {
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();
    const shouldAlert = currentDecibel >= threshold; // 只基于分贝值与阈值比较

    // 使用 DataProcessingState 中的警报状态
    const isAlarmActive = this.ak.dataProcessingState.alertState.isActive;

    if (shouldAlert && !isAlarmActive) {
      // 触发警报（总是触发，不受通知设置影响）
      await this.triggerAlarm(currentDecibel);
    } else if (!shouldAlert && isAlarmActive) {
      // 解除警报
      this.clearAlarm();
    } else if (!shouldAlert) {
      // 噪音恢复正常，重置警报状态
      this.alertService.resetAlertState();
    }
  }

  // 触发警报
  private async triggerAlarm(currentDecibel: number): Promise<void> {
    // 状态更新由 AlertService 处理
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();
    await this.alertService.triggerAlert(currentDecibel, threshold);
  }

  // 解除警报
  private clearAlarm(): void {
    // 状态更新由 AlertService 处理
    this.alertService.resetAlertState();
  }

  // 构建状态显示区
  @Builder
  private buildStatusDisplay() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 状态指示器
      Row({ space: DesignConstants.SPACING_SM }) {
        Circle({ width: 16, height: 16 })
          .fill(this.statusColor)

        Text(this.statusText)
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontColor(this.statusColor)
          .fontWeight(FontWeight.Bold)
      }

      // 当前分贝值（大字体显示）
      Text(`${this.ak.uiDisplayState.displayDb}dB`)
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.statusColor)

      // 阈值信息
      Text(`阈值: ${ThresholdManager.getCurrentEffectiveThreshold()}dB`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))

      // 警报持续时间（如果激活）
      if (this.ak.uiDisplayState.displayAlertState.isActive) {
        Text(`持续时间: ${this.ak.uiDisplayState.displayAlertState.formattedDuration}`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.alert'))
          .fontWeight(FontWeight.Medium)
      }
    }
    .padding(DesignConstants.SPACING_XL)
    .backgroundColor(this.statusBackground)
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .borderRadius(DesignConstants.BORDER_RADIUS_XL)
    .width('100%')

  }

  // 构建环境信息区
  @Builder
  private buildEnvironmentInfo() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('环境信息')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .alignSelf(ItemAlign.Start)
        .fontColor($r('sys.color.font_primary'))

      // 环境质量评级
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('环境质量:')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))

        Text(this.environmentQuality)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(this.environmentColor)
          .fontWeight(FontWeight.Medium)
      }

      // 专业建议
      Text(this.environmentSuggestion)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Start)
        .alignSelf(ItemAlign.Start)
        .lineHeight(18)
    }
    .padding(DesignConstants.SPACING_LG)
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  @Computed
  get statusColor(): Resource {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();

    if (currentDecibel >= threshold) {
      return $r('sys.color.warning'); // 红色
    } else if (currentDecibel >= threshold - 10) {
      return $r('sys.color.alert'); // 黄色
    } else {
      return $r('sys.color.confirm'); // 绿色
    }
  }

  // 辅助方法：获取状态文字
  @Computed
  get statusText(): string {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();

    if (currentDecibel >= threshold) {
      return '警报触发中';
    } else if (currentDecibel >= threshold - 10) {
      return '接近阈值';
    } else {
      return '环境安全';
    }
  }

  // 辅助方法：获取状态背景色
  @Computed
  get statusBackground(): Resource {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();

    if (currentDecibel >= threshold) {
      return $r('sys.color.warning');
    } else if (currentDecibel >= threshold - 10) {
      return $r('sys.color.alert');
    } else {
      return $r('sys.color.comp_background_secondary');
    }
  }

  // 辅助方法：获取环境质量评级
  @Computed
  get environmentQuality(): string {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();

    if (currentDecibel >= threshold) {
      return '危险';
    } else if (currentDecibel >= threshold - 10) {
      return '警告';
    } else if (currentDecibel >= threshold - 20) {
      return '良好';
    } else {
      return '优秀';
    }
  }

  // 辅助方法：获取环境质量颜色
  @Computed
  get environmentColor(): Resource {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();

    if (currentDecibel >= threshold) {
      return $r('sys.color.alert');
    } else if (currentDecibel >= threshold - 10) {
      return $r('sys.color.warning');
    } else if (currentDecibel >= threshold - 20) {
      return $r('sys.color.confirm');
    } else {
      return $r('sys.color.confirm');
    }
  }

  // 辅助方法：获取环境建议
  @Computed
  get environmentSuggestion(): string {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();

    if (currentDecibel >= threshold) {
      return '当前环境噪音过高，建议立即离开或采取防护措施。长期暴露可能对听力造成损害。';
    } else if (currentDecibel >= threshold - 10) {
      return '噪音水平接近警戒线，请注意防护。建议减少在此环境中的停留时间。';
    } else if (currentDecibel >= threshold - 20) {
      return '环境噪音在可接受范围内，建议保持关注。适合短期停留。';
    } else {
      return '环境噪音水平良好，适合长期停留。继续保持良好环境。';
    }
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 状态显示区（最突出）
      this.buildStatusDisplay()

      NotificationPreferences({
        systemNotificationEnabled: this.pk.system_notification_enabled,
        onSystemNotificationChange: (enabled: boolean) => {
          this.pk.system_notification_enabled = enabled;
        }
      })
      // 环境信息区
      this.buildEnvironmentInfo()
    }
    .width('90%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: DesignConstants.SPACING_XL })
    .backgroundColor($r('sys.color.background_secondary'))
  }
}