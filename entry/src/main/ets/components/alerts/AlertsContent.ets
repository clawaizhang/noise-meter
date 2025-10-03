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
  @Local private as: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  // 警报状态
  @Local private isAlarmActive: boolean = false;
  @Local private visualAlertState: string = 'normal';
  @Local private alertStartTime: number = 0;
  @Local private alertDuration: number = 0;
  // 警报服务
  private alertService: AlertService = AlertService.getInstance(getContext() as common.UIAbilityContext);

  aboutToAppear(): void {
    // 组件加载时更新权限状态
    this.alertService.updateSystemPermissionStatus();
  }

  aboutToDisappear(): void {
    // 组件销毁时重置警报状态
    this.alertService.resetAlertState();
  }

  @Monitor('as.db')
  async onDbChange(monitor: IMonitor) {
    const currentDecibel = monitor.value<number>()?.now;
    if (currentDecibel !== undefined) {
      await this.checkAlertStatus(currentDecibel);
    }
  }

  // 检查警报状态
  private async checkAlertStatus(currentDecibel: number): Promise<void> {
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();
    const shouldAlert = currentDecibel >= threshold && this.pk.system_notification_enabled;

    if (shouldAlert && !this.isAlarmActive) {
      // 触发警报
      await this.triggerAlarm(currentDecibel);
    } else if (!shouldAlert && this.isAlarmActive) {
      // 解除警报
      this.clearAlarm();
    } else if (!shouldAlert) {
      // 噪音恢复正常，重置警报状态
      this.alertService.resetAlertState();
    }
  }

  // 触发警报
  private async triggerAlarm(currentDecibel: number): Promise<void> {
    this.isAlarmActive = true;
    this.visualAlertState = 'alert';
    this.alertStartTime = Date.now();

    // 使用AlertService触发系统通知
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();

    // 如果系统通知启用，则触发警报
    if (this.pk.system_notification_enabled) {
      await this.alertService.triggerAlert(currentDecibel, threshold);
    }
  }

  // 解除警报
  private clearAlarm(): void {
    this.isAlarmActive = false;
    this.visualAlertState = 'normal';
    this.alertDuration = Date.now() - this.alertStartTime;
  }

  // 构建状态显示区
  @Builder
  private buildStatusDisplay() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 状态指示器
      Row({ space: DesignConstants.SPACING_SM }) {
        Circle({ width: 16, height: 16 })
          .fill(this.getStatusColor())
          .animation({
            duration: this.isAlarmActive ? 500 : 0,
            curve: Curve.EaseInOut,
            iterations: this.isAlarmActive ? -1 : 1,
            playMode: PlayMode.Alternate
          })

        Text(this.getStatusText())
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontColor(this.getStatusColor())
          .fontWeight(FontWeight.Bold)
      }

      // 当前分贝值（大字体显示）
      Text(`${this.as.db}dB`)
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getStatusColor())
        .animation({
          duration: 300,
          curve: Curve.EaseInOut
        })

      // 阈值信息
      Text(`阈值: ${ThresholdManager.getCurrentEffectiveThreshold()}dB`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))

      // 警报持续时间（如果激活）
      if (this.isAlarmActive) {
        Text(`持续时间: ${this.formatDuration(Date.now() - this.alertStartTime)}`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.alert'))
          .fontWeight(FontWeight.Medium)
      }
    }
    .padding(DesignConstants.SPACING_XL)
    .backgroundColor(this.getStatusBackground())
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .borderRadius(DesignConstants.BORDER_RADIUS_XL)
    .width('100%')
    .animation({
      duration: 300,
      curve: Curve.EaseInOut
    })
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

        Text(this.getEnvironmentQuality())
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(this.getEnvironmentColor())
          .fontWeight(FontWeight.Medium)
      }

      // 专业建议
      Text(this.getEnvironmentSuggestion())
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

  // 辅助方法：获取状态颜色
  private getStatusColor(): Resource {
    const currentDecibel = this.as.db;
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
  private getStatusText(): string {
    const currentDecibel = this.as.db;
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
  private getStatusBackground(): Resource {
    const currentDecibel = this.as.db;
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();

    if (currentDecibel >= threshold) {
      return $r('sys.color.warning');
    } else if (currentDecibel >= threshold - 10) {
      return $r('sys.color.alert');
    } else {
      return $r('sys.color.comp_background_secondary');
    }
  }

  // 辅助方法：格式化持续时间
  private formatDuration(duration: number): string {
    const seconds = Math.floor(duration / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);

    if (hours > 0) {
      return `${hours}小时${minutes % 60}分钟`;
    } else if (minutes > 0) {
      return `${minutes}分钟${seconds % 60}秒`;
    } else {
      return `${seconds}秒`;
    }
  }

  // 辅助方法：获取环境质量评级
  private getEnvironmentQuality(): string {
    const currentDecibel = this.as.db;
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
  private getEnvironmentColor(): Resource {
    const currentDecibel = this.as.db;
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
  private getEnvironmentSuggestion(): string {
    const currentDecibel = this.as.db;
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