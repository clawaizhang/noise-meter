/**
 * 警报中心内容组件（三区域重构版）
 * 
 * 功能模块：
 * 1. 实时状态区 - 简洁展示当前分贝和警报状态
 * 2. 场景建议区 - 根据预设和分贝状态提供个性化建议（核心）
 * 3. 今日统计区 - 简化的警报历史和统计数据
 */

import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DesignConstants } from '../../constants/DesignConstants';
import { AlertService } from '../../services/AlertService';
import { AlertHistoryService } from '../../services/AlertHistoryService';
import { 
  AlertRecord, 
  AlertSummary, 
  AlertSeverity,
  AlertType 
} from '../../models/AlertRecord';
import { AppStorageV2, PersistenceV2, curves, promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { PresetType } from '../../models/ThresholdConfig';
import { AlertStateMachine } from '../../utils/AlertStateMachine';
import { AlertEvent, AlertStatus } from '../../constants/AlertsConstants';
import { DialogHub, type InfSheet } from '@hadss/dialoghub';
import { AlertsSettingsBuilder, AlertsSettingsProps } from '../../pages/settings/AlertsSettingsNavigation';
import { AlertHistoryNavigationBuilder } from '../../pages/alerts/AlertHistoryNavigation';
import { Throttle } from '../../utils/Debounce';
import { 
  getScenarioGuidance, 
  DecibelZone,
  ScenarioGuidance,
  SCENARIO_GUIDANCE_MAP
} from '../../constants/ScenarioGuidanceConstants';

@ComponentV2
export struct AlertsContent {
  // ========== 状态管理 ==========
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  
  // 服务实例
  private alertService: AlertService = AlertService.getInstance(getContext() as common.UIAbilityContext, this.pk);
  private alertHistoryService: AlertHistoryService = AlertHistoryService.getInstance();
  private stateMachine: AlertStateMachine = new AlertStateMachine();
  
  // UI状态
  @Local private pulseAnimation: number = 0;
  @Local private isAlertActive: boolean = false;
  @Local private pulseInterval: number = 0;
  
  // 数据状态
  @Local private alertHistory: AlertRecord[] = [];
  @Local private alertSummary: AlertSummary = new AlertSummary();
  @Local private isLoading: boolean = true;
  @Local private activeAlertId: string = '';
  @Local private todayAlertCount: number = 0;
  @Local private todayAlertDuration: string = '--';
  @Local private todayPeakDecibel: string = '--';
  
  // 刷新控制器
  private refreshTimer: number = 0;

  // 防抖相关状态 - 简化版：直接根据当前分贝显示，不防抖
  // 防抖导致用户体验问题（不切换），去掉防抖，直接实时显示
  private zoneCheckTimer: number = 0;

  // ========== 计算属性 ==========

  // 移除了防抖监控，直接实时计算

  // ========== 生命周期 ==========
  
  async aboutToAppear(): Promise<void> {
    await this.alertHistoryService.initialize();
    this.alertService.updateSystemPermissionStatus();
    this.stateMachine.handleEvent(AlertEvent.START_MONITORING);
    await this.loadAlertData();
    this.startPulseAnimation();
    this.startRefreshTimer();
    
    // 防抖机制已移除，直接实时显示
  }

  aboutToDisappear(): void {
    this.finalizeActiveAlert();
    this.alertService.resetAlertState();
    this.stateMachine.handleEvent(AlertEvent.STOP_MONITORING);
    this.stateMachine.destroy();
    this.stopPulseAnimation();
    this.stopRefreshTimer();
    
    // 清理定时器（如果有）
    if (this.zoneCheckTimer !== 0) {
      clearInterval(this.zoneCheckTimer);
      this.zoneCheckTimer = 0;
    }
  }

  // ========== 数据加载 ==========
  
  private async loadAlertData(): Promise<void> {
    this.isLoading = true;
    try {
      const records = await this.alertHistoryService.getRecentAlerts(5);
      const summary = await this.alertHistoryService.getTodaySummary();
      this.alertHistory = records;
      this.alertSummary = summary;
      this.updateStatsFromSummary(summary);
    } catch (error) {
      console.error('[AlertsContent] 加载警报数据失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  private async refreshData(): Promise<void> {
    try {
      const activeSession = this.alertHistoryService.getActiveSession();
      if (activeSession) {
        this.activeAlertId = activeSession.id;
      }
      const summary = await this.alertHistoryService.getTodaySummary();
      this.alertSummary = summary;
      this.updateStatsFromSummary(summary);
    } catch (error) {
      console.error('[AlertsContent] 刷新数据失败:', error);
    }
  }

  private updateStatsFromSummary(summary: AlertSummary): void {
    this.todayAlertCount = summary.todayCount;
    this.todayAlertDuration = summary.todayCount > 0 
      ? summary.getFormattedTodayDuration() 
      : '--';
    this.todayPeakDecibel = summary.peakDecibel > 0 
      ? `${summary.peakDecibel.toFixed(0)}dB` 
      : '--';
  }

  private startRefreshTimer(): void {
    this.refreshTimer = setInterval(() => {
      this.refreshData();
    }, 5000);
  }

  private stopRefreshTimer(): void {
    if (this.refreshTimer !== 0) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = 0;
    }
  }

  // ========== 场景建议计算（实时，无防抖） ==========

  @Computed
  get currentGuidance(): ScenarioGuidance {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;
    const preset = this.pk.alarm_threshold.currentPreset;
    
    // 直接实时计算当前区间
    let zone = DecibelZone.BELOW;
    if (currentDecibel >= threshold) {
      zone = DecibelZone.ABOVE;
    } else if (currentDecibel >= threshold - 10) {
      zone = DecibelZone.WARNING;
    }
    
    return SCENARIO_GUIDANCE_MAP[preset]?.[zone] || 
           SCENARIO_GUIDANCE_MAP[PresetType.CUSTOM][zone];
  }

  // ========== 导航方法 ==========

  private navigateToHistoryPage(): void {
    let historyDialog: InfSheet = DialogHub.getSheet()
      .setStyle({
        title: { title: '警报历史记录' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(AlertHistoryNavigationBuilder))
      .build();
    historyDialog.show();
  }

  private openSettingsDialog(): void {
    let settingsDialog = DialogHub.getSheet()
      .setStyle({
        showClose: false,
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(AlertsSettingsBuilder), {
        onSave: () => {
          settingsDialog.dismiss();
          this.loadAlertData();
        },
        onClose: () => {
          settingsDialog.dismiss();
        }
      } as AlertsSettingsProps)
      .build();
    settingsDialog.show();
  }

  // ========== 警报事件处理 ==========

  @Monitor('ak.uiDisplayState.displayDb')
  async onDbChange(monitor: IMonitor) {
    const currentDecibel = monitor.value<number>()?.now;
    if (currentDecibel !== undefined && this.ak.isDisplayApp) {
      if (this.alertHistoryService.hasActiveSession()) {
        this.alertHistoryService.updateActiveSession(currentDecibel);
      }
      const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;
      const transitionOccurred = this.stateMachine.handleEvent(
        AlertEvent.NOISE_LEVEL_CHANGED,
        { currentDecibel: currentDecibel, threshold: threshold }
      );

      if (transitionOccurred) {
        await this.updateAlertState(currentDecibel);
      }
    }
  }

  private async updateAlertState(currentDecibel: number): Promise<void> {
    const currentState = this.stateMachine.CurrentState;
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;

    if (currentState === AlertStatus.ALERT_ACTIVE || 
        currentState === AlertStatus.ALERT_PERSISTENT ||
        currentState === AlertStatus.ALERT_ESCALATED) {
      await this.handleAlertStart(currentDecibel, threshold);
    } else if (currentState === AlertStatus.MONITORING ||
               currentState === AlertStatus.WARNING) {
      await this.handleAlertStateEnd(currentDecibel);
    } else if (currentState === AlertStatus.IDLE ||
               currentState === AlertStatus.MUTED) {
      this.alertService.resetAlertState();
    }
  }

  private async handleAlertStart(currentDecibel: number, threshold: number): Promise<void> {
    await this.alertService.triggerAlert(currentDecibel, threshold);
    if (!this.alertHistoryService.hasActiveSession()) {
      const sessionId = await this.alertHistoryService.startAlertSession(
        threshold,
        currentDecibel,
        AlertType.THRESHOLD_BREACH
      );
      if (sessionId !== '') {
        this.activeAlertId = sessionId;
      }
    }
  }

  private async handleAlertStateEnd(currentDecibel: number): Promise<void> {
    this.alertService.resetAlertState();
    if (this.alertHistoryService.hasActiveSession()) {
      const record = await this.alertHistoryService.endAlertSession(currentDecibel);
      if (record !== null) {
        const newHistory: AlertRecord[] = [record, ...this.alertHistory].slice(0, 5);
        this.alertHistory = newHistory;
        this.alertSummary = await this.alertHistoryService.getTodaySummary();
      }
      this.activeAlertId = '';
    }
  }

  private async finalizeActiveAlert(): Promise<void> {
    if (this.alertHistoryService.hasActiveSession()) {
      const currentDb = this.ak.uiDisplayState.displayDb;
      await this.handleAlertStateEnd(currentDb);
    }
  }

  private startPulseAnimation(): void {
    this.pulseInterval = setInterval(() => {
      this.isAlertActive = this.stateMachine.AlertActive;
      this.pulseAnimation = Date.now();
    }, 500) as number;
  }

  private stopPulseAnimation(): void {
    if (this.pulseInterval !== 0) {
      clearInterval(this.pulseInterval);
      this.pulseInterval = 0;
    }
  }

  // ========== 1. 实时状态区（精简版） ==========

  @Builder
  private buildStatusDisplay() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 顶部：分贝数值 + 状态标签
      Row({ space: DesignConstants.SPACING_LG }) {
        // 左侧：大分贝数值
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(`${this.ak.uiDisplayState.displayDb}`)
            .fontSize(64)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.statusColor)
            .animation({ duration: 400, curve: curves.springMotion(0.5, 0.8) })
          
          Text('dB')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 右侧：状态标签 + 持续时间 + 预设信息
        Column({ space: DesignConstants.SPACING_SM }) {
          // 状态标签
          Row({ space: DesignConstants.SPACING_SM }) {
            Text(this.statusIcon)
              .fontSize(DesignConstants.FONT_SIZE_XL)
            Text(this.statusText)
              .fontSize(DesignConstants.FONT_SIZE_LG)
              .fontColor(this.statusColor)
              .fontWeight(FontWeight.Bold)
          }
          .padding({ top: 8, bottom: 8, left: 12, right: 12 })
          .backgroundColor(this.getBadgeBackgroundColor())
          .borderRadius(DesignConstants.BORDER_RADIUS_LG)

          // 警报持续时间（固定高度占位，避免抖动）
          Row() {
            if (this.stateMachine.AlertActive) {
              Row({ space: DesignConstants.SPACING_XS }) {
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
          }
          .height(20) // 固定高度

          // 与阈值差距
          Text(this.differenceText)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor(this.statusColor)
            .fontWeight(FontWeight.Medium)
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .padding({ top: DesignConstants.SPACING_LG, bottom: DesignConstants.SPACING_MD })

      // 进度条
      this.buildThresholdProgressBar()
    }
    .padding({ 
      left: DesignConstants.SPACING_LG, 
      right: DesignConstants.SPACING_LG, 
      top: DesignConstants.SPACING_LG, 
      bottom: DesignConstants.SPACING_LG 
    })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_XL)
    .width('100%')
  }

  @Builder
  private buildThresholdProgressBar() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(6)
          .backgroundColor($r('sys.color.comp_divider'))
          .borderRadius(DesignConstants.BORDER_RADIUS_FULL)

        Row()
          .width(`${this.progressRatio * 100}%`)
          .height(6)
          .backgroundColor(this.statusColor)
          .borderRadius(DesignConstants.BORDER_RADIUS_FULL)
          .animation({ duration: 300 })

        // 阈值标记线
        Row()
          .width(3)
          .height(12)
          .backgroundColor(Color.White)
          .borderRadius(1)
          .offset({ x: `${this.thresholdRatio * 100}%`, y: -3 })
          .shadow({ radius: 2, color: 'rgba(0,0,0,0.2)', offsetX: 0, offsetY: 1 })
      }
      .width('100%')
      .height(12)

      Row() {
        Text(`${this.MIN_DB}dB`)
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))

        Blank()

        Text(`阈值 ${this.pk.alarm_threshold.currentEffectiveThreshold}dB`)
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_secondary'))

        Blank()

        Text(`${this.MAX_DB}dB`)
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .width('100%')
    }
  }

  // ========== 2. 场景建议区（核心） ==========

  @Builder
  private buildScenarioGuidance() {
    // 左侧状态色条 + 内容区域的布局
    Row() {
      // 左侧状态色条（subtle 的状态表达）- 使用Align.Top配合layoutWeight让色条随内容高度
      Column()
        .width(4)
        .backgroundColor(this.guidanceColor)
        .borderRadius({ topLeft: 12, bottomLeft: 12 })

      // 内容区域
      Column({ space: DesignConstants.SPACING_SM }) {
        // 标题行
        Row({ space: DesignConstants.SPACING_SM }) {
          Text(this.currentGuidance.icon)
            .fontSize(24)
          
          Text(this.currentGuidance.title)
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
            .layoutWeight(1)

          // 设置入口
          Button() {
            Image($r('app.media.ic_settings'))
              .width(20)
              .height(20)
              .fillColor($r('sys.color.font_secondary'))
          }
          .type(ButtonType.Circle)
          .backgroundColor($r('sys.color.background_secondary'))
          .width(36)
          .height(36)
          .onClick(() => {
            Throttle.click(() => this.openSettingsDialog());
          })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 预设信息（阈值说明）
        Row({ space: DesignConstants.SPACING_XS }) {
          Text(this.getPresetIcon(this.pk.alarm_threshold.currentPreset))
            .fontSize(14)
          Text(`当前使用【${this.getPresetName(this.pk.alarm_threshold.currentPreset)}】预设 · 阈值 ${this.pk.alarm_threshold.currentEffectiveThreshold}dB`)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')

        // 描述 - 固定2行高度
        Text(this.currentGuidance.description)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .width('100%')
          .height(48) // 固定高度：2行
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 建议内容 - 固定高度
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('💡')
            .fontSize(18)
          Text(this.currentGuidance.suggestion)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .height(72) // 固定高度
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .alignItems(VerticalAlign.Top)

        // 参考标准 - 固定高度占位
        Row() {
          if (this.currentGuidance.reference) {
            Text(this.currentGuidance.reference)
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_tertiary'))
              .fontStyle(FontStyle.Italic)
          }
        }
        .width('100%')
        .height(18)
      }
      .padding({
        left: DesignConstants.SPACING_LG,
        right: DesignConstants.SPACING_LG,
        top: DesignConstants.SPACING_MD,
        bottom: DesignConstants.SPACING_MD
      })
      .layoutWeight(1)
    }
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  // ========== 3. 今日统计区（简化版） ==========

  @Builder
  private buildTodayStats() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题行
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_history'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.brand'))

        Text('今日概况')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        if (this.alertSummary.totalCount > 0) {
          Button() {
            Row({ space: DesignConstants.SPACING_XS }) {
              Text(`${this.alertSummary.totalCount} 条记录`)
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.brand'))
              Text('→')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.brand'))
            }
          }
          .type(ButtonType.Normal)
          .backgroundColor('transparent')
          .padding({ left: DesignConstants.SPACING_SM, right: DesignConstants.SPACING_SM })
          .height(32)
          .onClick(() => this.navigateToHistoryPage())
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Divider()
        .strokeWidth(1)
        .color($r('sys.color.comp_divider'))

      // 统计数据
      Row() {
        // 警报次数
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(`${this.todayAlertCount}次`)
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
          Text('警报次数')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 分隔线
        Column()
          .width(1)
          .height(40)
          .backgroundColor($r('sys.color.comp_divider'))

        // 累计时长
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(this.todayAlertDuration)
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
          Text('累计时长')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 分隔线
        Column()
          .width(1)
          .height(40)
          .backgroundColor($r('sys.color.comp_divider'))

        // 最高峰值
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(this.todayPeakDecibel)
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
          Text('最高峰值')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height(80)
      .backgroundColor($r('sys.color.background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .margin({ top: DesignConstants.SPACING_MD, bottom: DesignConstants.SPACING_MD })

      // 最近记录（最多3条）
      if (this.alertHistory.length > 0) {
        this.buildRecentAlertList()
      } else if (!this.isLoading) {
        // 空状态
        Column({ space: DesignConstants.SPACING_SM }) {
          Text('✅')
            .fontSize(32)
          Text('今日环境良好')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.confirm'))
          Text('暂无警报记录，继续保持！')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .padding({ top: DesignConstants.SPACING_LG, bottom: DesignConstants.SPACING_LG })
        .alignItems(HorizontalAlign.Center)
      }

      if (this.isLoading) {
        LoadingProgress()
          .width(24)
          .height(24)
          .alignSelf(ItemAlign.Center)
      }
    }
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .width('100%')
  }


  @Builder
  private buildRecentAlertList() {
    Column({ space: DesignConstants.SPACING_SM }) {
      ForEach(this.alertHistory.slice(0, 3), (record: AlertRecord, index: number) => {
        Row({ space: DesignConstants.SPACING_SM }) {
          // 严重程度指示点
          Circle()
            .width(8)
            .height(8)
            .fill(AlertRecord.getSeverityColor(record.severity))

          // 时间
          Text(record.getFormattedStartTime())
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
            .layoutWeight(1)

          // 峰值
          Text(`${record.peakDecibel.toFixed(0)}dB`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor(AlertRecord.getSeverityColor(record.severity))
            .fontWeight(FontWeight.Medium)

          // 时长
          Text(record.getFormattedDuration)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .padding(DesignConstants.SPACING_SM)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      }, (record: AlertRecord) => record.id)
    }
    .width('100%')
  }

  // ========== 辅助计算方法 ==========

  private readonly MIN_DB = 30;
  private readonly MAX_DB = 85;

  @Computed
  get progressRatio(): number {
    const db = this.ak.uiDisplayState.displayDb;
    const ratio = (db - this.MIN_DB) / (this.MAX_DB - this.MIN_DB);
    return Math.max(0, Math.min(1, ratio));
  }

  @Computed
  get thresholdRatio(): number {
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;
    const ratio = (threshold - this.MIN_DB) / (this.MAX_DB - this.MIN_DB);
    return Math.max(0, Math.min(1, ratio));
  }

  @Computed
  get statusColor(): Resource {
    const currentState = this.stateMachine.CurrentState;
    if (currentState === AlertStatus.ALERT_ACTIVE ||
        currentState === AlertStatus.ALERT_PERSISTENT ||
        currentState === AlertStatus.ALERT_ESCALATED) {
      return $r('sys.color.alert');
    } else if (currentState === AlertStatus.WARNING) {
      return $r('sys.color.warning');
    }
    return $r('sys.color.confirm');
  }

  @Computed
  get guidanceColor(): Resource {
    // 实时计算颜色
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;
    
    if (currentDecibel >= threshold) {
      return $r('sys.color.alert');
    } else if (currentDecibel >= threshold - 10) {
      return $r('sys.color.warning');
    }
    return $r('sys.color.confirm');
  }

  @Computed
  get statusText(): string {
    const currentState = this.stateMachine.CurrentState;
    if (currentState === AlertStatus.ALERT_ACTIVE) return '警报中';
    if (currentState === AlertStatus.ALERT_PERSISTENT) return '持续警报';
    if (currentState === AlertStatus.ALERT_ESCALATED) return '警报升级';
    if (currentState === AlertStatus.WARNING) return '接近阈值';
    return '环境安全';
  }

  private get statusIcon(): string {
    const currentState = this.stateMachine.CurrentState;
    if (currentState === AlertStatus.ALERT_ACTIVE ||
        currentState === AlertStatus.ALERT_PERSISTENT ||
        currentState === AlertStatus.ALERT_ESCALATED) {
      return '🚨';
    } else if (currentState === AlertStatus.WARNING) {
      return '⚠️';
    }
    return '✅';
  }

  private getBadgeBackgroundColor(): string {
    const currentState = this.stateMachine.CurrentState;
    if (currentState === AlertStatus.ALERT_ACTIVE ||
        currentState === AlertStatus.ALERT_PERSISTENT ||
        currentState === AlertStatus.ALERT_ESCALATED) {
      return 'rgba(244, 67, 54, 0.12)';
    } else if (currentState === AlertStatus.WARNING) {
      return 'rgba(255, 152, 0, 0.12)';
    }
    return 'rgba(76, 175, 80, 0.12)';
  }

  @Computed
  get differenceText(): string {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;
    const difference = Math.abs(currentDecibel - threshold);

    if (currentDecibel > threshold) {
      return `+${difference.toFixed(1)}dB`;
    } else if (currentDecibel < threshold) {
      return `-${difference.toFixed(1)}dB`;
    }
    return '等于阈值';
  }

  private getPresetIcon(presetType: PresetType): string {
    switch (presetType) {
      case PresetType.QUIET_ENVIRONMENT: return '🌙';
      case PresetType.GENERAL_ENVIRONMENT: return '🏢';
      case PresetType.NOISY_ENVIRONMENT: return '🛣️';
      case PresetType.DANGEROUS_ENVIRONMENT: return '⚠️';
      default: return '⚙️';
    }
  }

  private getPresetShortName(presetType: PresetType): string {
    switch (presetType) {
      case PresetType.QUIET_ENVIRONMENT: return '安静';
      case PresetType.GENERAL_ENVIRONMENT: return '办公';
      case PresetType.NOISY_ENVIRONMENT: return '嘈杂';
      case PresetType.DANGEROUS_ENVIRONMENT: return '危险';
      default: return '自定义';
    }
  }

  private getPresetName(presetType: PresetType): string {
    switch (presetType) {
      case PresetType.QUIET_ENVIRONMENT: return '安静环境';
      case PresetType.GENERAL_ENVIRONMENT: return '一般环境';
      case PresetType.NOISY_ENVIRONMENT: return '嘈杂环境';
      case PresetType.DANGEROUS_ENVIRONMENT: return '危险环境';
      default: return '自定义';
    }
  }

  // ========== 主构建方法 ==========
  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {
        // 区域1：实时状态
        this.buildStatusDisplay()
        
        // 区域2：场景建议（核心）
        this.buildScenarioGuidance()
        
        // 区域3：今日统计
        this.buildTodayStats()
      }
      .width('100%')
      .padding({ left: DesignConstants.SPACING_LG, right: DesignConstants.SPACING_LG, bottom: DesignConstants.SPACING_XL })
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

// Export builder for DialogHub
@Builder
export function AlertsContentBuilder() {
  AlertsContent()
}
