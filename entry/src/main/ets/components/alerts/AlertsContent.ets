import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DesignConstants } from '../../constants/DesignConstants';
import { ThresholdManager } from '../../services/ThresholdManager';
import { NotificationHelper } from '../../utils/NotificationHelper';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

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

  aboutToAppear(): void {
  }

  @Monitor('as.db')
  onDbChange(monitor:IMonitor){
    const currentDecibel = monitor.value<number>()?.now;
    if (currentDecibel !== undefined) {
      this.checkAlertStatus(currentDecibel);
    }
  }

  // 检查警报状态
  private checkAlertStatus(currentDecibel: number): void {
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();
    const shouldAlert = currentDecibel >= threshold && this.pk.noise_alarm_enabled;

    if (shouldAlert && !this.isAlarmActive) {
      // 触发警报
      this.triggerAlarm(currentDecibel);
    } else if (!shouldAlert && this.isAlarmActive) {
      // 解除警报
      this.clearAlarm();
    }
  }

  // 触发警报
  private triggerAlarm(currentDecibel: number): void {
    this.isAlarmActive = true;
    this.visualAlertState = 'alert';
    this.alertStartTime = Date.now();

    // 多模态反馈
    if (this.pk.sound_alert_enabled) {
      this.playAlertSound();
    }
    if (this.pk.vibration_alert_enabled) {
      this.triggerVibration();
    }
    if (this.pk.system_notification_enabled) {
      this.showSystemNotification(currentDecibel);
    }
  }

  // 解除警报
  private clearAlarm(): void {
    this.isAlarmActive = false;
    this.visualAlertState = 'normal';
    this.alertDuration = Date.now() - this.alertStartTime;
  }

  // 播放警报声音
  private playAlertSound(): void {
    // 使用系统音频服务播放警报音
    // 这里可以集成具体的音频播放逻辑
  }

  // 触发振动
  private triggerVibration(): void {
    // 使用系统振动服务
    // 这里可以集成具体的振动逻辑
  }

  // 显示系统通知
  private showSystemNotification(currentDecibel: number): void {
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();
    NotificationHelper.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext).showNotification(999_999,
      '噪音警报',
      `当前噪音水平 ${currentDecibel}dB 超过阈值 ${threshold}dB`,
      '请采取适当防护措施'
    );
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
    .borderRadius(DesignConstants.BORDER_RADIUS_XL)
    .width('90%')
    .animation({
      duration: 300,
      curve: Curve.EaseInOut
    })
  }

  // 构建快速控制区 - 优化布局
  @Builder
  private buildQuickControls() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题行：警报通知 + 总开关（右上角）
      Row() {
        Text('警报通知')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
        
        Blank()
        
        // 总开关 - 只保留开关
        Toggle({ type: ToggleType.Switch, isOn: this.pk.noise_alarm_enabled })
          .onChange((enabled: boolean) => {
            this.pk.noise_alarm_enabled = enabled;
          })
          .selectedColor($r('sys.color.brand'))
          .scale({ x: 1.1, y: 1.1 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      
      // 三个反馈项垂直排列
      Column({ space: DesignConstants.SPACING_SM }) {
        // 声音反馈
        this.buildFeedbackItem(
          '声音',
          this.pk.sound_alert_enabled,
          $r('app.media.ic_audio_analysis'),
          (enabled: boolean) => {
            this.pk.sound_alert_enabled = enabled;
          }
        )
        
        // 振动反馈
        this.buildFeedbackItem(
          '振动',
          this.pk.vibration_alert_enabled,
          $r('app.media.ic_sensor'),
          (enabled: boolean) => {
            this.pk.vibration_alert_enabled = enabled;
          }
        )
        
        // 通知反馈
        this.buildFeedbackItem(
          '通知',
          this.pk.system_notification_enabled,
          $r('app.media.ic_info'),
          (enabled: boolean) => {
            this.pk.system_notification_enabled = enabled;
          }
        )
      }
      .width('100%')
    }
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .width('90%')
  }

  // 构建反馈项 - 图标+文字+开关
  @Builder
  private buildFeedbackItem(title: string, enabled: boolean, icon: Resource, onToggle: (enabled: boolean) => void) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 图标
      Image(icon)
        .width(DesignConstants.ICON_SIZE_SM)
        .height(DesignConstants.ICON_SIZE_SM)
        .fillColor(enabled ? $r('sys.color.brand') : $r('sys.color.font_secondary'))
      
      // 文字
      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor(enabled ? $r('sys.color.font_primary') : $r('sys.color.font_secondary'))
        .fontWeight(FontWeight.Medium)
      
      Blank()
      
      // 开关
      Toggle({ type: ToggleType.Switch, isOn: enabled })
        .onChange(onToggle)
        .selectedColor($r('sys.color.brand'))
    }
    .width('100%')
    .padding({
      top: DesignConstants.SPACING_SM,
      bottom: DesignConstants.SPACING_SM,
      left: DesignConstants.SPACING_MD,
      right: DesignConstants.SPACING_MD
    })
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .alignItems(VerticalAlign.Center)
  }

  // 构建紧凑控制项 - 图标+开关（保留，可能在其他地方使用）
  @Builder
  private buildCompactControl(enabled: boolean, icon: Resource, onToggle: (enabled: boolean) => void, isMainSwitch: boolean = false) {
    Row({ space: DesignConstants.SPACING_SM }) {
      Image(icon)
        .width(isMainSwitch ? DesignConstants.ICON_SIZE_MD : DesignConstants.ICON_SIZE_SM)
        .height(isMainSwitch ? DesignConstants.ICON_SIZE_MD : DesignConstants.ICON_SIZE_SM)
        .fillColor(enabled ? $r('sys.color.brand') : $r('sys.color.font_secondary'))
      
      Toggle({ type: ToggleType.Switch, isOn: enabled })
        .onChange(onToggle)
        .selectedColor($r('sys.color.brand'))
        .scale({ x: isMainSwitch ? 1.1 : 0.9, y: isMainSwitch ? 1.1 : 0.9 })
    }
    .padding({
      top: DesignConstants.SPACING_SM,
      bottom: DesignConstants.SPACING_SM,
      left: isMainSwitch ? DesignConstants.SPACING_MD : DesignConstants.SPACING_SM,
      right: isMainSwitch ? DesignConstants.SPACING_MD : DesignConstants.SPACING_SM
    })
    .backgroundColor(isMainSwitch ? $r('sys.color.background_emphasize') : $r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .alignItems(VerticalAlign.Center)
  }

  // 构建控制卡片（保留原有方法，可能在其他地方使用）
  @Builder
  private buildControlCard(title: string, enabled: boolean, icon: Resource, onToggle: (enabled: boolean) => void) {
    Column({ space: DesignConstants.SPACING_SM }) {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(enabled ? $r('sys.color.brand') : $r('sys.color.font_secondary'))
      
      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor(enabled ? $r('sys.color.font_primary') : $r('sys.color.font_secondary'))
      
      Toggle({ type: ToggleType.Switch, isOn: enabled })
        .onChange(onToggle)
        .selectedColor($r('sys.color.brand'))
    }
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .width('100%')
    .alignItems(HorizontalAlign.Center)
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
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .width('90%')
  }

  // 辅助方法：获取状态颜色
  private getStatusColor(): Resource {
    const currentDecibel = this.as.db;
    const threshold = ThresholdManager.getCurrentEffectiveThreshold();
    
    if (currentDecibel >= threshold) {
      return $r('sys.color.alert'); // 红色
    } else if (currentDecibel >= threshold - 10) {
      return $r('sys.color.warning'); // 黄色
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
      return $r('sys.color.comp_background_warning_secondary');
    } else if (currentDecibel >= threshold - 10) {
      return $r('sys.color.comp_background_emphasize');
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
      
      // 快速控制区
      this.buildQuickControls()
      
      // 环境信息区
      this.buildEnvironmentInfo()
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: DesignConstants.SPACING_XL })
    .backgroundColor($r('sys.color.background_secondary'))
  }
}