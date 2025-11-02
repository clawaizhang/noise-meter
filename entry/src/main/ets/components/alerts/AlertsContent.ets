import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DesignConstants } from '../../constants/DesignConstants';
import { AlertService } from '../../services/AlertService';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { NotificationPreferences } from './NotificationPreferences';
import { PresetType } from '../../models/ThresholdConfig';
import { AlertStateMachine } from '../../utils/AlertStateMachine';
import { AlertEvent, AlertStatus } from '../../constants/AlertsConstants';

@ComponentV2
export struct AlertsContent {
  // 通过AppKeys获取实时数据
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  // 警报服务
  private alertService: AlertService = AlertService.getInstance(getContext() as common.UIAbilityContext,this.pk);
  // 状态机
  private stateMachine: AlertStateMachine = new AlertStateMachine();

  aboutToAppear(): void {
    // 组件加载时更新权限状态
    this.alertService.updateSystemPermissionStatus();
    // 启动状态机监控
    this.stateMachine.handleEvent(AlertEvent.START_MONITORING);
  }

  aboutToDisappear(): void {
    // 组件销毁时重置警报状态
    this.alertService.resetAlertState();
    // 停止状态机监控
    this.stateMachine.handleEvent(AlertEvent.STOP_MONITORING);
    this.stateMachine.destroy();
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
          // 不触发警报
          // await this.triggerAlarm(triggerDecibel);
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
    // 状态更新由状态机处理，AlertService 只负责通知
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;
    await this.alertService.triggerAlert(currentDecibel, threshold);
  }

  // 解除警报
  private clearAlarm(): void {
    // 状态更新由状态机处理，AlertService 只负责重置通知状态
    this.alertService.resetAlertState();
  }

  // 构建状态显示区
  @Builder
  private buildStatusDisplay() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 状态指示器 - 强化显示
      Row({ space: DesignConstants.SPACING_SM }) {
        Circle({ width: 20, height: 20 })
          .fill(this.statusColor)
          .shadow({
            radius: 8,
            color: this.statusColor,
            offsetX: 0,
            offsetY: 2
          })

        Text(this.statusText)
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontColor(this.statusColor)
          .fontWeight(FontWeight.Bold)
      }

      // 分贝值与阈值对比显示
      Row({ space: DesignConstants.SPACING_LG }) {
        // 当前分贝值
        Column({ space: DesignConstants.SPACING_XS }) {
          Text('当前')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
          Text(`${this.ak.uiDisplayState.displayDb}dB`)
            .fontSize(48)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.statusColor)
        }

        // 对比符号
        Text(this.getComparisonSymbol())
          .fontSize(32)
          .fontColor($r('sys.color.font_secondary'))
          .fontWeight(FontWeight.Bold)

        // 阈值
        Column({ space: DesignConstants.SPACING_XS }) {
          Text('阈值')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
          Text(`${this.pk.alarm_threshold.currentEffectiveThreshold}dB`)
            .fontSize(48)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
        }
      }

      // 差值显示
      Text(this.getDifferenceText())
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontColor(this.statusColor)
        .fontWeight(FontWeight.Medium)

      // 警报持续时间（如果激活）
      if (this.stateMachine.AlertActive) {
        Row({ space: DesignConstants.SPACING_SM }) {
          Image($r('app.media.ic_alarm'))
            .width(16)
            .height(16)
            .fillColor($r('sys.color.alert'))
          Text(`持续时间: ${this.stateMachine.FormattedAlertDuration}`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.alert'))
            .fontWeight(FontWeight.Medium)
        }
      }
    }
    .padding(DesignConstants.SPACING_XL)
    .backgroundColor(this.statusBackground)
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .borderRadius(DesignConstants.BORDER_RADIUS_XL)
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

        Text(this.environmentQuality)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(this.environmentColor)
          .fontWeight(FontWeight.Medium)
      }

      // 三条分列描述
      Column({ space: DesignConstants.SPACING_XS }) {
        // 当前状态描述
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('•')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
          Text(this.currentStatusDescription)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .textAlign(TextAlign.Start)
        }
        .alignSelf(ItemAlign.Start)

        // 影响描述
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('•')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
          Text(this.impactDescription)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .textAlign(TextAlign.Start)
        }
        .alignSelf(ItemAlign.Start)

        // 建议措施
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('•')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
          Text(this.suggestionAction)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .textAlign(TextAlign.Start)
        }
        .alignSelf(ItemAlign.Start)
      }
      .alignSelf(ItemAlign.Start)
      .width('100%')
    }
    .padding(DesignConstants.SPACING_LG)
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  @Computed
  get statusColor(): Resource {
    const currentState = this.stateMachine.CurrentState;
    
    switch (currentState) {
      case AlertStatus.ALERT_ACTIVE:
      case AlertStatus.ALERT_PERSISTENT:
      case AlertStatus.ALERT_ESCALATED:
        return $r('sys.color.alert'); // 红色
      case AlertStatus.WARNING:
        return $r('sys.color.warning'); // 黄色
      case AlertStatus.MONITORING:
        return $r('sys.color.confirm'); // 绿色
      case AlertStatus.IDLE:
      case AlertStatus.MUTED:
      default:
        return $r('sys.color.font_secondary'); // 灰色
    }
  }

  // 辅助方法：获取状态文字
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

  // 辅助方法：获取状态背景色
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

  // 辅助方法：获取环境质量评级（基于状态机状态）
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

  // 辅助方法：获取环境质量颜色（基于状态机状态）
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

  // 辅助方法：获取当前状态描述
  @Computed
  get currentStatusDescription(): string {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;
    const presetType = this.pk.alarm_threshold.currentPreset;
    const presetName = this.getPresetDisplayName(presetType);

    if (currentDecibel >= threshold) {
      const difference = currentDecibel - threshold;
      return `超过${presetName}阈值${difference}dB`;
    } else if (currentDecibel >= threshold - 10) {
      const difference = threshold - currentDecibel;
      return `接近${presetName}阈值，仅差${difference}dB`;
    } else if (currentDecibel >= threshold - 20) {
      const difference = threshold - currentDecibel;
      return `在${presetName}安全范围内，距离阈值${difference}dB`;
    } else {
      const difference = threshold - currentDecibel;
      return `远低于${presetName}阈值${difference}dB`;
    }
  }

  // 辅助方法：获取影响描述
  @Computed
  get impactDescription(): string {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;
    const presetType = this.pk.alarm_threshold.currentPreset;

    if (currentDecibel >= threshold) {
      switch (presetType) {
        case PresetType.QUIET_ENVIRONMENT:
          return '可能影响专注度和休息质量';
        case PresetType.GENERAL_ENVIRONMENT:
          return '可能影响工作效率和舒适度';
        case PresetType.NOISY_ENVIRONMENT:
          return '长期暴露可能引起不适';
        case PresetType.DANGEROUS_ENVIRONMENT:
          return '长期暴露可能对听力造成损害';
        default:
          if (threshold <= 50) return '可能影响安静活动的质量';
          else if (threshold <= 70) return '可能影响日常活动的舒适度';
          else return '长期暴露可能对听力造成影响';
      }
    } else if (currentDecibel >= threshold - 10) {
      switch (presetType) {
        case PresetType.QUIET_ENVIRONMENT:
          return '可能轻微影响安静环境';
        case PresetType.GENERAL_ENVIRONMENT:
          return '可能轻微影响工作学习环境';
        case PresetType.NOISY_ENVIRONMENT:
          return '可能引起轻微不适';
        case PresetType.DANGEROUS_ENVIRONMENT:
          return '需要保持警惕';
        default:
          return '需要适当关注环境变化';
      }
    } else if (currentDecibel >= threshold - 20) {
      switch (presetType) {
        case PresetType.QUIET_ENVIRONMENT:
          return '适合专注和休息的环境';
        case PresetType.GENERAL_ENVIRONMENT:
          return '适合日常工作和学习活动';
        case PresetType.NOISY_ENVIRONMENT:
          return '适合短期停留的嘈杂环境';
        case PresetType.DANGEROUS_ENVIRONMENT:
          return '环境相对安全，建议保持防护意识';
        default:
          return '适合相应环境的活动';
      }
    } else {
      switch (presetType) {
        case PresetType.QUIET_ENVIRONMENT:
          return '理想的安静环境';
        case PresetType.GENERAL_ENVIRONMENT:
          return '舒适的工作学习环境';
        case PresetType.NOISY_ENVIRONMENT:
          return '环境相对安静';
        case PresetType.DANGEROUS_ENVIRONMENT:
          return '环境相对安全';
        default:
          return '理想的环境状态';
      }
    }
  }

  // 辅助方法：获取建议措施
  @Computed
  get suggestionAction(): string {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;
    const presetType = this.pk.alarm_threshold.currentPreset;

    if (currentDecibel >= threshold) {
      switch (presetType) {
        case PresetType.QUIET_ENVIRONMENT:
          return '建议寻找更安静的环境';
        case PresetType.GENERAL_ENVIRONMENT:
          return '建议适当调整环境';
        case PresetType.NOISY_ENVIRONMENT:
          return '建议减少停留时间';
        case PresetType.DANGEROUS_ENVIRONMENT:
          return '建议立即采取防护措施';
        default:
          if (threshold <= 50) return '建议寻找更安静的环境';
          else if (threshold <= 70) return '建议适当调整环境';
          else return '请注意防护';
      }
    } else if (currentDecibel >= threshold - 10) {
      switch (presetType) {
        case PresetType.QUIET_ENVIRONMENT:
          return '建议保持关注环境变化';
        case PresetType.GENERAL_ENVIRONMENT:
          return '建议适当关注环境变化';
        case PresetType.NOISY_ENVIRONMENT:
          return '建议注意环境变化';
        case PresetType.DANGEROUS_ENVIRONMENT:
          return '建议准备必要的防护措施';
        default:
          return '建议保持关注环境变化';
      }
    } else if (currentDecibel >= threshold - 20) {
      switch (presetType) {
        case PresetType.QUIET_ENVIRONMENT:
          return '适合需要专注和休息的活动';
        case PresetType.GENERAL_ENVIRONMENT:
          return '适合日常工作和学习活动';
        case PresetType.NOISY_ENVIRONMENT:
          return '适合短期停留';
        case PresetType.DANGEROUS_ENVIRONMENT:
          return '建议保持适当防护意识';
        default:
          return '适合相应环境的活动';
      }
    } else {
      switch (presetType) {
        case PresetType.QUIET_ENVIRONMENT:
          return '适合深度专注和优质休息';
        case PresetType.GENERAL_ENVIRONMENT:
          return '继续保持良好环境';
        case PresetType.NOISY_ENVIRONMENT:
          return '适合较长时间停留';
        case PresetType.DANGEROUS_ENVIRONMENT:
          return '建议保持基本防护意识';
        default:
          return '继续保持良好环境';
      }
    }
  }

  // 辅助方法：获取对比符号
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

  // 辅助方法：获取差值文本
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

  // 辅助方法：获取预设类型显示名称
  private getPresetDisplayName(presetType: PresetType): string {
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
        return '您设置';
    }
  }

  // 辅助方法：获取环境建议（基于用户阈值和阈值类型）
  @Computed
  get environmentSuggestion(): string {
    const currentDecibel = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.currentEffectiveThreshold;
    const presetType = this.pk.alarm_threshold.currentPreset;

    // 根据阈值类型和当前分贝值生成智能建议
    if (currentDecibel >= threshold) {
      return this.getExceedThresholdSuggestion(presetType, currentDecibel, threshold);
    } else if (currentDecibel >= threshold - 10) {
      return this.getNearThresholdSuggestion(presetType, currentDecibel, threshold);
    } else if (currentDecibel >= threshold - 20) {
      return this.getSafeThresholdSuggestion(presetType, currentDecibel, threshold);
    } else {
      return this.getExcellentThresholdSuggestion(presetType, currentDecibel, threshold);
    }
  }

  // 超过阈值的建议
  private getExceedThresholdSuggestion(presetType: PresetType, currentDecibel: number, threshold: number): string {
    const difference = currentDecibel - threshold;
    
    switch (presetType) {
      case PresetType.QUIET_ENVIRONMENT:
        return `当前环境噪音超过您设置的安静环境阈值${difference}dB。这可能会影响您的专注度和休息质量，建议寻找更安静的环境。`;
      case PresetType.GENERAL_ENVIRONMENT:
        return `当前环境噪音超过您设置的一般环境阈值${difference}dB。这可能会影响工作效率和舒适度，建议适当调整环境。`;
      case PresetType.NOISY_ENVIRONMENT:
        return `当前环境噪音超过您设置的嘈杂环境阈值${difference}dB。长期暴露可能引起不适，建议减少停留时间。`;
      case PresetType.DANGEROUS_ENVIRONMENT:
        return `当前环境噪音超过您设置的危险环境阈值${difference}dB。长期暴露可能对听力造成损害，建议立即采取防护措施。`;
      default:
        if (threshold <= 50) {
          return `当前环境噪音超过您设置的阈值${difference}dB。这可能会影响安静活动的质量。`;
        } else if (threshold <= 70) {
          return `当前环境噪音超过您设置的阈值${difference}dB。这可能会影响日常活动的舒适度。`;
        } else {
          return `当前环境噪音超过您设置的阈值${difference}dB。长期暴露可能对听力造成影响，请注意防护。`;
        }
    }
  }

  // 接近阈值的建议
  private getNearThresholdSuggestion(presetType: PresetType, currentDecibel: number, threshold: number): string {
    const difference = threshold - currentDecibel;
    
    switch (presetType) {
      case PresetType.QUIET_ENVIRONMENT:
        return `噪音水平接近您设置的安静环境阈值，仅差${difference}dB。建议保持关注，避免噪音进一步升高影响安静环境。`;
      case PresetType.GENERAL_ENVIRONMENT:
        return `噪音水平接近您设置的一般环境阈值，仅差${difference}dB。建议适当关注环境变化，确保工作学习环境舒适。`;
      case PresetType.NOISY_ENVIRONMENT:
        return `噪音水平接近您设置的嘈杂环境阈值，仅差${difference}dB。建议注意环境变化，避免长时间处于嘈杂环境。`;
      case PresetType.DANGEROUS_ENVIRONMENT:
        return `噪音水平接近您设置的危险环境阈值，仅差${difference}dB。请保持警惕，准备必要的听力防护措施。`;
      default:
        return `噪音水平接近您设置的阈值，仅差${difference}dB。建议保持关注环境变化。`;
    }
  }

  // 安全范围内的建议
  private getSafeThresholdSuggestion(presetType: PresetType, currentDecibel: number, threshold: number): string {
    const difference = threshold - currentDecibel;
    
    switch (presetType) {
      case PresetType.QUIET_ENVIRONMENT:
        return `环境噪音在安静环境的安全范围内，距离阈值还有${difference}dB。适合需要专注和休息的环境。`;
      case PresetType.GENERAL_ENVIRONMENT:
        return `环境噪音在一般环境的安全范围内，距离阈值还有${difference}dB。适合日常工作和学习活动。`;
      case PresetType.NOISY_ENVIRONMENT:
        return `环境噪音在嘈杂环境的安全范围内，距离阈值还有${difference}dB。适合短期停留的嘈杂环境。`;
      case PresetType.DANGEROUS_ENVIRONMENT:
        return `环境噪音在危险环境的安全范围内，距离阈值还有${difference}dB。但仍建议保持适当防护意识。`;
      default:
        return `环境噪音在安全范围内，距离您设置的阈值还有${difference}dB。适合相应环境的活动。`;
    }
  }

  // 优秀环境的建议
  private getExcellentThresholdSuggestion(presetType: PresetType, currentDecibel: number, threshold: number): string {
    const difference = threshold - currentDecibel;
    
    switch (presetType) {
      case PresetType.QUIET_ENVIRONMENT:
        return `环境噪音水平优秀，远低于安静环境阈值${difference}dB。这是理想的安静环境，适合深度专注和优质休息。`;
      case PresetType.GENERAL_ENVIRONMENT:
        return `环境噪音水平优秀，远低于一般环境阈值${difference}dB。这是舒适的工作学习环境，继续保持。`;
      case PresetType.NOISY_ENVIRONMENT:
        return `环境噪音水平优秀，远低于嘈杂环境阈值${difference}dB。环境相对安静，适合较长时间停留。`;
      case PresetType.DANGEROUS_ENVIRONMENT:
        return `环境噪音水平优秀，远低于危险环境阈值${difference}dB。环境相对安全，但仍建议保持基本防护意识。`;
      default:
        return `环境噪音水平优秀，远低于您设置的阈值${difference}dB。这是理想的环境状态，继续保持。`;
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