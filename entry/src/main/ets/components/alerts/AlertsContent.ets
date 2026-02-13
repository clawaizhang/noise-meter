import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DesignConstants } from '../../constants/DesignConstants';
import { AlertService } from '../../services/AlertService';
import { AppStorageV2, PersistenceV2, curves } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { PresetType } from '../../models/ThresholdConfig';
import { AlertStateMachine } from '../../utils/AlertStateMachine';
import { AlertEvent, AlertStatus } from '../../constants/AlertsConstants';
import { DialogHub, type InfSheet } from '@hadss/dialoghub';
import { AlertsSettingsBuilder, AlertsSettingsProps } from '../../pages/settings/AlertsSettingsNavigation';
import { Throttle } from '../../utils/Debounce';

// 阴影样式接口
interface ShadowStyle {
  radius: number;
  color: Resource | Color | string;
  offsetX: number;
  offsetY: number;
}

// 警报记录数据模型
interface AlertRecord {
  id: string;
  timestamp: number;
  duration: number; // 秒
  peakDecibel: number;
  threshold: number;
  location?: string;
}

@ComponentV2
export struct AlertsContent {
  // 通过AppKeys获取实时数据
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  // 警报服务
  private alertService: AlertService = AlertService.getInstance(getContext() as common.UIAbilityContext, this.pk);
  // 状态机
  private stateMachine: AlertStateMachine = new AlertStateMachine();
  // 警报历史记录（模拟数据，实际应从服务获取）
  @Local private alertHistory: AlertRecord[] = [];
  // 动画相关状态
  @Local private pulseAnimation: number = 0;  // 脉冲动画值
  @Local private isAlertActive: boolean = false; // 是否处于警报状态
  private pulseInterval?: number;  // 脉冲动画定时器

  aboutToAppear(): void {
    // 组件加载时更新权限状态
    this.alertService.updateSystemPermissionStatus();
    // 启动状态机监控
    this.stateMachine.handleEvent(AlertEvent.START_MONITORING);
    // 加载警报历史
    this.loadAlertHistory();
    // 启动脉冲动画
    this.startPulseAnimation();
  }

  aboutToDisappear(): void {
    // 组件销毁时重置警报状态
    this.alertService.resetAlertState();
    // 停止状态机监控
    this.stateMachine.handleEvent(AlertEvent.STOP_MONITORING);
    this.stateMachine.destroy();
    // 停止脉冲动画
    this.stopPulseAnimation();
  }

  // 启动脉冲动画（警报状态下）
  private startPulseAnimation(): void {
    this.pulseInterval = setInterval(() => {
      this.isAlertActive = this.stateMachine.AlertActive;
      this.pulseAnimation = Date.now();
    }, 500); // 每500ms更新一次
  }

  // 停止脉冲动画
  private stopPulseAnimation(): void {
    if (this.pulseInterval) {
      clearInterval(this.pulseInterval);
      this.pulseInterval = undefined;
    }
  }

  // 加载警报历史（模拟数据）
  private loadAlertHistory(): void {
    // TODO: 从实际的数据服务加载
    // 这里使用模拟数据展示UI效果
    const now = Date.now();
    this.alertHistory = [
      {
        id: '1',
        timestamp: now - 3600000, // 1小时前
        duration: 72,
        peakDecibel: 82,
        threshold: 55,
        location: '北京市朝阳区'
      },
      {
        id: '2',
        timestamp: now - 7200000, // 2小时前
        duration: 45,
        peakDecibel: 78,
        threshold: 55,
        location: '北京市海淀区'
      }
    ];
  }

  @Monitor('ak.uiDisplayState.displayDb')
  async onDbChange(monitor: IMonitor) {
    const currentDecibel = monitor.value<number>()?.now;
    if (currentDecibel !== undefined && this.ak.isDisplayApp) {
      // 使用状态机处理状态转换
      const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;
      const transitionOccurred = this.stateMachine.handleEvent(
        AlertEvent.NOISE_LEVEL_CHANGED,
        { currentDecibel, threshold }
      );

      if (transitionOccurred) {
        await this.updateAlertState();
      }
    }
  }

  // 更新警报状态（基于状态机）
  private async updateAlertState(): Promise<void> {
    const currentState = this.stateMachine.CurrentState;
    const context = this.stateMachine.getContext();
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;

    switch (currentState) {
      case AlertStatus.ALERT_ACTIVE:
      case AlertStatus.ALERT_PERSISTENT:
      case AlertStatus.ALERT_ESCALATED:
        // 触发警报通知 - 使用警报触发时的实际分贝值，修复分贝值不一致问题
        let triggerDecibel = this.stateMachine.AlertTriggerDecibel;
        // 安全措施：如果触发分贝值不可用，使用当前上下文中的值
        if (triggerDecibel <= 0) {
          triggerDecibel = context.currentDecibel;
          console.warn(`[AlertsContent] 警报触发分贝值不可用，使用上下文值: ${triggerDecibel}dB`);
        }

        // 双重检查：确保当前分贝值确实超过阈值才触发警报
        if (triggerDecibel >= threshold) {
          await this.triggerAlarm(triggerDecibel);
        } else {
          console.warn(`[AlertsContent] 警报状态异常：状态=${currentState}，但分贝值=${triggerDecibel}dB < 阈值=${threshold}dB，跳过警报触发`);
        }
        break;
      case AlertStatus.MONITORING:
      case AlertStatus.WARNING:
        // 解除警报通知
        this.clearAlarm();
        break;
      case AlertStatus.IDLE:
      case AlertStatus.MUTED:
        // 重置警报通知状态
        this.alertService.resetAlertState();
        break;
    }
  }

  // 触发警报
  private async triggerAlarm(currentDecibel: number): Promise<void> {
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;
    await this.alertService.triggerAlert(currentDecibel, threshold);
  }

  // 解除警报
  private clearAlarm(): void {
    this.alertService.resetAlertState();
  }

  // ========== 1. 实时状态区（优化版） ==========
  @Builder
  private buildStatusDisplay() {
    Column({ space: 0 }) {
      // 主内容区（固定高度，避免布局抖动）
      Row({ space: DesignConstants.SPACING_LG }) {
        // 左侧：超大字号分贝值
        this.buildDecibelDisplay()

        // 右侧：状态徽章
        this.buildStatusBadge()
      }
      .width('100%')
      .height(120) // 固定高度
      .padding({
        top: DesignConstants.SPACING_XL,
        bottom: DesignConstants.SPACING_LG,
        left: DesignConstants.SPACING_XL,
        right: DesignConstants.SPACING_XL
      })
      .justifyContent(FlexAlign.SpaceBetween)

      // 底部：阈值进度条
      this.buildThresholdProgressBar()
    }
    // 使用中性背景，不随状态变色，保持专业稳定的视觉感受
    .backgroundColor($r('sys.color.comp_background_primary'))
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .borderRadius(DesignConstants.BORDER_RADIUS_XL)
    .width('100%')
    .height(200) // 固定卡片总高度
  }

  // 分贝值显示（左侧大字号）
  @Builder
  private buildDecibelDisplay() {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(`${this.ak.uiDisplayState.displayDb}`)
        .fontSize(56)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.statusColor)
        // 数值变化动画
        .animation({
          duration: 400,
          curve: curves.springMotion(0.5, 0.8)
        })

      Text('dB')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
    }
    .alignItems(HorizontalAlign.Start)
  }

  // 状态徽章（右侧）
  @Builder
  private buildStatusBadge() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 状态图标和文字
      Row({ space: DesignConstants.SPACING_SM }) {
        // 状态图标
        Text(this.getStatusIcon())
          .fontSize(DesignConstants.FONT_SIZE_XL)

        Text(this.statusText)
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontColor(this.statusColor)
          .fontWeight(FontWeight.Bold)
      }
      .padding({
        top: DesignConstants.SPACING_SM,
        bottom: DesignConstants.SPACING_SM,
        left: DesignConstants.SPACING_MD,
        right: DesignConstants.SPACING_MD
      })
      .backgroundColor(this.getBadgeBackgroundColor())
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      // 警报状态下的边框（静态，无脉冲）
      .border({
        width: this.isAlertActive ? 2 : 0,
        color: this.statusColor,
        style: BorderStyle.Solid
      })

      // 差值显示
      Text(this.getDifferenceText())
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor(this.statusColor)
        .fontWeight(FontWeight.Medium)

      // 持续时间（固定高度区域，避免布局跳动）
      Row({ space: DesignConstants.SPACING_XS }) {
        if (this.stateMachine.AlertActive) {
          Image($r('app.media.ic_alarm'))
            .width(14)
            .height(14)
            .fillColor($r('sys.color.alert'))

          Text(this.stateMachine.FormattedAlertDuration)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.alert'))
            .fontWeight(FontWeight.Medium)
        }
      }
      .height(24) // 固定高度
      .justifyContent(FlexAlign.Center)
    }
    .height(100) // 固定整体高度
    .alignItems(HorizontalAlign.End)
    .justifyContent(FlexAlign.Center)
  }

  // 阈值进度条
  @Builder
  private buildThresholdProgressBar() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 进度条轨道
      Stack({ alignContent: Alignment.Start }) {
        // 背景轨道（渐变：绿→黄→红）
        Row()
          .width('100%')
          .height(8)
          .backgroundColor($r('sys.color.comp_divider'))
          .borderRadius(DesignConstants.BORDER_RADIUS_FULL)

        // 渐变填充层
        Row()
          .width('100%')
          .height(8)
          .backgroundColor(this.getProgressGradient())
          .borderRadius(DesignConstants.BORDER_RADIUS_FULL)
          .opacity(0.3)

        // 当前位置指示器（发光圆点）
        // 使用 offset 替代 position，避免布局抖动
        Row()
          .width(16)
          .height(16)
          .backgroundColor(this.statusColor)
          .borderRadius(DesignConstants.BORDER_RADIUS_FULL)
          .shadow({
            radius: 6,
            color: this.statusColor,
            offsetX: 0,
            offsetY: 0
          })
          .offset({
            x: this.getProgressPositionRatio() * 100 + '%',
            y: -4
          })
        // 移除缩放动画，避免抖动问题

        // 阈值线标记
        Row()
          .width(3)
          .height(12)
          .backgroundColor(Color.White)
          .borderRadius(1)
          .offset({
            x: this.getThresholdLineRatio() * 100 + '%',
            y: -2
          })
          .shadow({
            radius: 2,
            color: 'rgba(0, 0, 0, 0.2)',
            offsetX: 0,
            offsetY: 1
          })
      }
      .width('100%')
      .height(16)
      .padding({ left: 8, right: 8 })

      // 阈值标记文字
      Row() {
        Text(`30dB`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_tertiary'))

        Blank()

        Text(`警报阈值 ${this.pk.alarm_threshold.currentEffectiveThreshold}dB`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .fontWeight(FontWeight.Medium)

        Blank()

        Text(`85dB`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .width('100%')
      .padding({ left: DesignConstants.SPACING_SM, right: DesignConstants.SPACING_SM })
    }
    .width('100%')
    .padding({
      left: DesignConstants.SPACING_LG,
      right: DesignConstants.SPACING_LG,
      bottom: DesignConstants.SPACING_LG
    })
  }

  // ========== 2. 设置摘要区（方案A：极简卡片） ==========
  @Builder
  private buildSettingsSummary() {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧：预设图标
      Text(this.getPresetIcon(this.pk.alarm_threshold.currentPreset))
        .fontSize(28)

      // 中间：核心信息
      Column({ space: DesignConstants.SPACING_XS }) {
        // 第一行：预设名称 + 阈值
        Row({ space: DesignConstants.SPACING_SM }) {
          Text(this.getPresetShortName(this.pk.alarm_threshold.currentPreset))
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))

          Text(`${this.pk.alarm_threshold.currentEffectiveThreshold}dB`)
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.brand'))

          Blank()
        }
        .width('100%')

        // 第二行：次要信息（时段调度 + 通知状态）
        Text(this.getSettingsSubtitle())
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 右侧：箭头
      Image($r('app.media.ic_arrow_right'))
        .width(20)
        .height(20)
        .fillColor($r('sys.color.font_tertiary'))
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .onClick(() => {
      Throttle.click(() => {
        this.openSettingsDialog();
      });
    })
  }

  // 打开设置弹窗
  private openSettingsDialog(): void {
    // 关闭当前警报中心弹窗
    // 由于DialogHub的管理方式，我们需要通过回调来处理
    // 这里直接打开设置弹窗，层级会覆盖
    let settingsDialog = DialogHub.getSheet()
      .setStyle({
        // 不设置标题，使用组件内部的 EditableTitleBar
        // showClose: false 隐藏DialogHub默认的关闭按钮，避免与EditableTitleBar的按钮重叠
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(AlertsSettingsBuilder), {
        onSave: () => {
          settingsDialog.dismiss();
          // 保存成功后刷新当前显示
          this.loadAlertHistory();
        },
        onClose: () => {
          settingsDialog.dismiss();
        }
      } as AlertsSettingsProps)
      .build();
    settingsDialog.show();
  }

  // ========== 3. 警报历史区（新增） ==========
  @Builder
  private buildAlertHistory() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题行
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_history'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.brand'))

        Text('警报历史')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        // 今日统计
        Text(`今日${this.todayAlertCount}次`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 分割线
      Divider()
        .strokeWidth(1)
        .color($r('sys.color.comp_divider'))
        .width('100%')

      // 统计摘要
      Row({ space: DesignConstants.SPACING_MD }) {
        this.buildHistoryStatItem('今日警报', `${this.todayAlertCount}次`)
        this.buildHistoryStatItem('累计时长', this.todayAlertDuration)
        this.buildHistoryStatItem('最高峰值', `${this.todayPeakDecibel}dB`)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      // 历史记录列表
      if (this.alertHistory.length > 0) {
        Column({ space: DesignConstants.SPACING_SM }) {
          ForEach(this.alertHistory.slice(0, 3), (record: AlertRecord, index: number) => {
            this.buildAlertHistoryItem(record, index)
          }, (record: AlertRecord) => record.id)
        }
        .width('100%')
        .margin({ top: DesignConstants.SPACING_SM })

        if (this.alertHistory.length > 3) {
          Text(`还有 ${this.alertHistory.length - 3} 条记录`)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .alignSelf(ItemAlign.Center)
            .margin({ top: DesignConstants.SPACING_SM })
        }
      } else {
        // 空状态
        Column({ space: DesignConstants.SPACING_SM }) {
          Image($r('app.media.ic_history'))
            .width(48)
            .height(48)
            .fillColor($r('sys.color.font_tertiary'))
            .opacity(0.5)

          Text('今日暂无警报记录')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))

          Text('环境良好，继续保持！')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_tertiary'))
        }
        .width('100%')
        .padding(DesignConstants.SPACING_XL)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .width('100%')
  }

  @Builder
  private buildHistoryStatItem(label: string, value: string) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(value)
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
      Text(label)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildAlertHistoryItem(record: AlertRecord, index: number) {
    Row({ space: DesignConstants.SPACING_SM }) {
      // 时间线指示器
      Column({ space: 0 }) {
        Circle()
          .width(8)
          .height(8)
          .fill($r('sys.color.alert'))
        if (index < this.alertHistory.slice(0, 3).length - 1) {
          Column()
            .width(2)
            .height(40)
            .backgroundColor($r('sys.color.comp_divider'))
        }
      }
      .width(16)
      .alignItems(HorizontalAlign.Center)

      // 记录内容
      Column({ space: DesignConstants.SPACING_XS }) {
        Row({ space: DesignConstants.SPACING_SM }) {
          Text(this.formatTime(record.timestamp))
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))

          Blank()

          Text(`峰值 ${record.peakDecibel}dB`)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.alert'))
        }
        .width('100%')

        Text(`持续 ${this.formatDuration(record.duration)} · 阈值 ${record.threshold}dB`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))

        if (record.location) {
          Text(record.location)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_tertiary'))
        }
      }
      .layoutWeight(1)
      .padding(DesignConstants.SPACING_SM)
      .backgroundColor($r('sys.color.background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  // ========== 4. 环境洞察区（扩展） ==========
  @Builder
  private buildEnvironmentInsight() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题行
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_info'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.brand'))

        Text('环境洞察')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 分割线
      Divider()
        .strokeWidth(1)
        .color($r('sys.color.comp_divider'))
        .width('100%')

      // 环境质量评级卡片
      Row({ space: DesignConstants.SPACING_MD }) {
        // 左侧：评级
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(this.environmentQuality)
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.environmentColor)
          Text('环境质量')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width(80)
        .alignItems(HorizontalAlign.Center)

        // 右侧：详情
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(this.currentStatusDescription)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Medium)
            .width('100%')

          Text(this.impactDescription)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .width('100%')
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)

      // 建议措施
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('💡 建议措施')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        Text(this.suggestionAction)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .width('100%')
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    }
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .width('100%')
  }

  // ========== 计算属性 ==========

  @Computed
  get statusColor(): Resource {
    const currentState = this.stateMachine.CurrentState;

    switch (currentState) {
      case AlertStatus.ALERT_ACTIVE:
      case AlertStatus.ALERT_PERSISTENT:
      case AlertStatus.ALERT_ESCALATED:
        return $r('sys.color.alert');
      case AlertStatus.WARNING:
        return $r('sys.color.warning');
      case AlertStatus.MONITORING:
        return $r('sys.color.confirm');
      case AlertStatus.IDLE:
      case AlertStatus.MUTED:
      default:
        return $r('sys.color.font_secondary');
    }
  }

  @Computed
  get statusText(): string {
    const currentState = this.stateMachine.CurrentState;

    switch (currentState) {
      case AlertStatus.ALERT_ACTIVE:
        return '警报触发中';
      case AlertStatus.ALERT_PERSISTENT:
        return '警报持续中';
      case AlertStatus.ALERT_ESCALATED:
        return '警报升级';
      case AlertStatus.WARNING:
        return '接近阈值';
      case AlertStatus.MONITORING:
        return '环境安全';
      case AlertStatus.IDLE:
        return '空闲状态';
      case AlertStatus.MUTED:
        return '静音状态';
      default:
        return '未知状态';
    }
  }

  @Computed
  get statusBackground(): Resource {
    const currentState = this.stateMachine.CurrentState;

    switch (currentState) {
      case AlertStatus.ALERT_ACTIVE:
      case AlertStatus.ALERT_PERSISTENT:
      case AlertStatus.ALERT_ESCALATED:
        return $r('sys.color.warning');
      case AlertStatus.WARNING:
        return $r('sys.color.alert');
      case AlertStatus.MONITORING:
        return $r('sys.color.comp_background_secondary');
      case AlertStatus.IDLE:
      case AlertStatus.MUTED:
      default:
        return $r('sys.color.comp_background_primary');
    }
  }

  @Computed
  get environmentQuality(): string {
    const currentState = this.stateMachine.CurrentState;

    switch (currentState) {
      case AlertStatus.ALERT_ACTIVE:
      case AlertStatus.ALERT_PERSISTENT:
      case AlertStatus.ALERT_ESCALATED:
        return '危险';
      case AlertStatus.WARNING:
        return '警告';
      case AlertStatus.MONITORING:
        return '良好';
      case AlertStatus.IDLE:
      case AlertStatus.MUTED:
      default:
        return '优秀';
    }
  }

  @Computed
  get environmentColor(): Resource {
    const currentState = this.stateMachine.CurrentState;

    switch (currentState) {
      case AlertStatus.ALERT_ACTIVE:
      case AlertStatus.ALERT_PERSISTENT:
      case AlertStatus.ALERT_ESCALATED:
        return $r('sys.color.alert');
      case AlertStatus.WARNING:
        return $r('sys.color.warning');
      case AlertStatus.MONITORING:
        return $r('sys.color.confirm');
      case AlertStatus.IDLE:
      case AlertStatus.MUTED:
      default:
        return $r('sys.color.confirm');
    }
  }

  // 今日警报次数
  @Computed
  get todayAlertCount(): number {
    return this.alertHistory.length;
  }

  // 今日警报累计时长
  @Computed
  get todayAlertDuration(): string {
    const totalSeconds = this.alertHistory.reduce((sum, record) => sum + record.duration, 0);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    if (minutes > 0) {
      return `${minutes}分${seconds}秒`;
    }
    return `${seconds}秒`;
  }

  // 今日峰值
  @Computed
  get todayPeakDecibel(): number {
    if (this.alertHistory.length === 0) return 0;
    return Math.max(...this.alertHistory.map(r => r.peakDecibel));
  }

  // ========== 辅助方法 ==========

  private getComparisonSymbol(): string {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;

    if (currentDecibel > threshold) {
      return '>';
    } else if (currentDecibel < threshold) {
      return '<';
    } else {
      return '=';
    }
  }

  private getDifferenceText(): string {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;
    const difference = Math.abs(currentDecibel - threshold);

    if (currentDecibel > threshold) {
      return `超过阈值 ${difference}dB`;
    } else if (currentDecibel < threshold) {
      return `低于阈值 ${difference}dB`;
    } else {
      return '等于阈值';
    }
  }

  private getPresetDisplayName(presetType: PresetType): string {
    switch (presetType) {
      case PresetType.QUIET_ENVIRONMENT:
        return '🌙 安静环境';
      case PresetType.GENERAL_ENVIRONMENT:
        return '🏢 一般环境';
      case PresetType.NOISY_ENVIRONMENT:
        return '🛣️ 嘈杂环境';
      case PresetType.DANGEROUS_ENVIRONMENT:
        return '⚠️ 危险环境';
      default:
        return '⚙️ 自定义';
    }
  }

  // 获取预设图标（用于极简卡片）
  private getPresetIcon(presetType: PresetType): string {
    switch (presetType) {
      case PresetType.QUIET_ENVIRONMENT:
        return '🌙';
      case PresetType.GENERAL_ENVIRONMENT:
        return '🏢';
      case PresetType.NOISY_ENVIRONMENT:
        return '🛣️';
      case PresetType.DANGEROUS_ENVIRONMENT:
        return '⚠️';
      default:
        return '⚙️';
    }
  }

  // 获取预设短名称（用于极简卡片）
  private getPresetShortName(presetType: PresetType): string {
    switch (presetType) {
      case PresetType.QUIET_ENVIRONMENT:
        return '安静环境';
      case PresetType.GENERAL_ENVIRONMENT:
        return '一般环境';
      case PresetType.NOISY_ENVIRONMENT:
        return '嘈杂环境';
      case PresetType.DANGEROUS_ENVIRONMENT:
        return '危险环境';
      default:
        return '自定义';
    }
  }

  // 获取设置卡片副标题
  private getSettingsSubtitle(): string {
    const parts: string[] = [];
    
    // 时段调度
    if (this.pk.alarm_threshold.timeSchedulingEnabled) {
      parts.push(`时段调度 ${this.pk.alarm_threshold.daytimeThreshold}/${this.pk.alarm_threshold.nighttimeThreshold}dB`);
    } else {
      parts.push('全天统一');
    }
    
    // 通知状态
    parts.push(this.pk.system_notification_enabled ? '通知已开启' : '通知已关闭');
    
    return parts.join(' · ');
  }

  @Computed
  get currentStatusDescription(): string {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;

    if (currentDecibel >= threshold) {
      const difference = currentDecibel - threshold;
      return `已超过阈值 ${difference}dB`;
    } else if (currentDecibel >= threshold - 10) {
      const difference = threshold - currentDecibel;
      return `接近阈值，仅差 ${difference}dB`;
    } else {
      return '处于安全范围内';
    }
  }

  @Computed
  get impactDescription(): string {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;

    if (currentDecibel >= threshold) {
      return '长期暴露可能影响健康，建议采取措施';
    } else if (currentDecibel >= threshold - 10) {
      return '需要注意环境变化';
    } else if (currentDecibel >= 70) {
      return '环境噪音中等，适合一般活动';
    } else {
      return '环境良好，适合专注和休息';
    }
  }

  @Computed
  get suggestionAction(): string {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;

    if (currentDecibel >= threshold) {
      return '建议寻找更安静的环境，或减少暴露时间';
    } else if (currentDecibel >= threshold - 10) {
      return '建议关注环境变化，准备应对措施';
    } else if (currentDecibel >= 70) {
      return '如需专注，建议佩戴降噪耳机';
    } else {
      return '当前环境适合工作和学习，继续保持';
    }
  }

  // ========== 新增：UI 辅助方法 ==========

  // 获取状态图标
  private getStatusIcon(): string {
    const currentState = this.stateMachine.CurrentState;

    switch (currentState) {
      case AlertStatus.ALERT_ACTIVE:
      case AlertStatus.ALERT_PERSISTENT:
      case AlertStatus.ALERT_ESCALATED:
        return '🚨';
      case AlertStatus.WARNING:
        return '⚠️';
      case AlertStatus.MONITORING:
        return '✅';
      case AlertStatus.IDLE:
        return '⏸️';
      case AlertStatus.MUTED:
        return '🔕';
      default:
        return '●';
    }
  }

  // 获取徽章背景色
  private getBadgeBackgroundColor(): Resource | string {
    const currentState = this.stateMachine.CurrentState;

    switch (currentState) {
      case AlertStatus.ALERT_ACTIVE:
      case AlertStatus.ALERT_PERSISTENT:
      case AlertStatus.ALERT_ESCALATED:
        return 'rgba(244, 67, 54, 0.1)';
      case AlertStatus.WARNING:
        return 'rgba(255, 152, 0, 0.1)';
      case AlertStatus.MONITORING:
        return 'rgba(76, 175, 80, 0.1)';
      default:
        return $r('sys.color.comp_background_secondary');
    }
  }

  // 获取脉冲透明度（用于警报动画）
  private getPulseOpacity(): number {
    if (!this.isAlertActive) {
      return 1;
    }
    // 基于时间计算脉冲值：0.6 → 1.0 → 0.6
    const time = this.pulseAnimation % 1000;
    if (time < 500) {
      return 0.6 + (time / 500) * 0.4;
    } else {
      return 1.0 - ((time - 500) / 500) * 0.4;
    }
  }

  // 获取卡片阴影（警报状态下更强烈）
  private getCardShadow(): ShadowStyle {
    if (this.isAlertActive) {
      return {
        radius: 12,
        color: this.statusColor,
        offsetX: 0,
        offsetY: 4
      };
    }
    return {
      radius: 8,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 2
    };
  }

  // 获取进度条位置（基于当前分贝值在30-85dB范围内的位置）
  // 返回 0-1 之间的小数，用于 offset 计算
  private getProgressPositionRatio(): number {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const minDb = 30;
    const maxDb = 85;
    const range = maxDb - minDb;

    // 计算比例（限制在0-1）
    let ratio = (currentDecibel - minDb) / range;
    ratio = Math.max(0, Math.min(1, ratio));
    return ratio;
  }

  // 获取阈值线在进度条上的位置比例
  private getThresholdLineRatio(): number {
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;
    const minDb = 30;
    const maxDb = 85;
    const range = maxDb - minDb;

    let ratio = (threshold - minDb) / range;
    ratio = Math.max(0, Math.min(1, ratio));
    return ratio;
  }

  // 获取进度渐变（根据分贝值返回不同颜色）
  private getProgressGradient(): Resource {
    const currentDecibel = this.ak.uiDisplayState.displayDb;

    if (currentDecibel >= this.pk.alarm_threshold.currentEffectiveThreshold) {
      return $r('sys.color.alert'); // 红色
    } else if (currentDecibel >= this.pk.alarm_threshold.currentEffectiveThreshold - 10) {
      return $r('sys.color.warning'); // 橙色
    } else {
      return $r('sys.color.confirm'); // 绿色
    }
  }

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  private formatDuration(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    if (mins > 0) {
      return `${mins}分${secs}秒`;
    }
    return `${secs}秒`;
  }

  // ========== 主构建方法 ==========
  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {
        // 1. 实时状态区（最突出）
        this.buildStatusDisplay()

        // 2. 设置摘要区（新增）
        this.buildSettingsSummary()

        // 3. 警报历史区（新增）
        this.buildAlertHistory()

        // 4. 环境洞察区（扩展）
        this.buildEnvironmentInsight()
      }
      .width('100%')
      .padding({ bottom: DesignConstants.SPACING_XL })
    }
    .align(Alignment.Top)
    .width('100%')
    .height('100%')
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .padding({ top: DesignConstants.SPACING_XL })
    .backgroundColor($r('sys.color.background_secondary'))
  }
}


