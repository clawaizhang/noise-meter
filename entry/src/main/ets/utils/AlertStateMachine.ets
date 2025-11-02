/**
 * 警报状态机
 * 负责管理警报状态的转换和验证
 */
import { AlertStatus, AlertEvent, StateMachineConfig, DEFAULT_STATE_MACHINE_CONFIG, AlertStateContext, StateTransition } from '../constants/AlertsConstants';
import { SecondTimerService } from '../services/SecondTimerService';

// 噪音水平数据类型
interface NoiseLevelData {
  currentDecibel: number;
  threshold: number;
}

@ObservedV2
export class AlertStateMachine {
  @Trace
  private currentState: AlertStatus = AlertStatus.IDLE;
  private context: AlertStateContext;
  private config: StateMachineConfig;
  private stateHistory: StateTransition[] = [];
  private lastTransitionTime: number = Date.now();
  private debounceTimer: number = 0;
  
  // 警报持续时间管理
  private alertStartTime: number = 0;
  private alertDuration: number = 0;
  @Trace
  private currentTime: number = 0;
  
  // 警报触发时的实际分贝值记录 - 修复分贝值不一致问题
  private alertTriggerDecibel: number = 0;

  // 秒定时器服务
  private secondTimerService: SecondTimerService = SecondTimerService.getInstance();
  private secondTickHandler: (() => void) | null = null;
  
  // 状态转换表
  private transitionTable: Map<AlertStatus, Map<AlertEvent, AlertStatus>> = new Map();
  
  constructor(config?: Partial<StateMachineConfig>) {
    this.context = this.createDefaultContext();
    this.config = this.mergeConfig(DEFAULT_STATE_MACHINE_CONFIG, config);
    this.initializeTransitionTable();
    this.initializeSecondTimer();
  }
  
  /**
   * 创建默认上下文
   */
  private createDefaultContext(): AlertStateContext {
    return {
      currentDecibel: 0,
      threshold: 0,
      startTime: Date.now(),
      duration: 0,
      previousState: AlertStatus.IDLE,
      stateHistory: []
    };
  }
  
  /**
   * 初始化秒定时器
   */
  private initializeSecondTimer(): void {
    this.secondTickHandler = () => {
      this.currentTime = Date.now() + 1000;
    };
    
    // 订阅秒事件
    this.secondTimerService.subscribe(this.secondTickHandler);
    
  }


  /**
   * 初始化状态转换表
   */
  private initializeTransitionTable(): void {
    this.transitionTable = new Map();
    
    // IDLE 状态转换
    const idleTransitions = new Map<AlertEvent, AlertStatus>();
    idleTransitions.set(AlertEvent.START_MONITORING, AlertStatus.MONITORING);
    this.transitionTable.set(AlertStatus.IDLE, idleTransitions);
    
    // MONITORING 状态转换
    const monitoringTransitions = new Map<AlertEvent, AlertStatus>();
    monitoringTransitions.set(AlertEvent.STOP_MONITORING, AlertStatus.IDLE);
    monitoringTransitions.set(AlertEvent.MUTE_ALERTS, AlertStatus.MUTED);
    monitoringTransitions.set(AlertEvent.NOISE_LEVEL_CHANGED, AlertStatus.MONITORING); // 自转换
    this.transitionTable.set(AlertStatus.MONITORING, monitoringTransitions);
    
    // WARNING 状态转换
    const warningTransitions = new Map<AlertEvent, AlertStatus>();
    warningTransitions.set(AlertEvent.STOP_MONITORING, AlertStatus.IDLE);
    warningTransitions.set(AlertEvent.MUTE_ALERTS, AlertStatus.MUTED);
    warningTransitions.set(AlertEvent.NOISE_LEVEL_CHANGED, AlertStatus.WARNING); // 自转换
    this.transitionTable.set(AlertStatus.WARNING, warningTransitions);
    
    // ALERT_ACTIVE 状态转换
    const alertActiveTransitions = new Map<AlertEvent, AlertStatus>();
    alertActiveTransitions.set(AlertEvent.STOP_MONITORING, AlertStatus.IDLE);
    alertActiveTransitions.set(AlertEvent.MUTE_ALERTS, AlertStatus.MUTED);
    alertActiveTransitions.set(AlertEvent.NOISE_LEVEL_CHANGED, AlertStatus.ALERT_ACTIVE); // 自转换
    this.transitionTable.set(AlertStatus.ALERT_ACTIVE, alertActiveTransitions);
    
    // ALERT_PERSISTENT 状态转换
    const alertPersistentTransitions = new Map<AlertEvent, AlertStatus>();
    alertPersistentTransitions.set(AlertEvent.STOP_MONITORING, AlertStatus.IDLE);
    alertPersistentTransitions.set(AlertEvent.MUTE_ALERTS, AlertStatus.MUTED);
    alertPersistentTransitions.set(AlertEvent.NOISE_LEVEL_CHANGED, AlertStatus.ALERT_PERSISTENT); // 自转换
    this.transitionTable.set(AlertStatus.ALERT_PERSISTENT, alertPersistentTransitions);
    
    // ALERT_ESCALATED 状态转换
    const alertEscalatedTransitions = new Map<AlertEvent, AlertStatus>();
    alertEscalatedTransitions.set(AlertEvent.STOP_MONITORING, AlertStatus.IDLE);
    alertEscalatedTransitions.set(AlertEvent.MUTE_ALERTS, AlertStatus.MUTED);
    alertEscalatedTransitions.set(AlertEvent.NOISE_LEVEL_CHANGED, AlertStatus.ALERT_ESCALATED); // 自转换
    this.transitionTable.set(AlertStatus.ALERT_ESCALATED, alertEscalatedTransitions);
    
    // MUTED 状态转换
    const mutedTransitions = new Map<AlertEvent, AlertStatus>();
    mutedTransitions.set(AlertEvent.UNMUTE_ALERTS, AlertStatus.MONITORING);
    mutedTransitions.set(AlertEvent.STOP_MONITORING, AlertStatus.IDLE);
    this.transitionTable.set(AlertStatus.MUTED, mutedTransitions);
  }
  
  /**
   * 处理事件
   */
  public handleEvent(event: AlertEvent, data?: NoiseLevelData): boolean {
    // 防抖处理
    if (this.shouldDebounce(event)) {
      return false;
    }
    
    // 检查状态转换
    if (!this.canTransition(event)) {
      return false;
    }
    
    // 根据事件类型确定目标状态
    let targetState: AlertStatus | null = null;
    
    if (event === AlertEvent.NOISE_LEVEL_CHANGED && data) {
      targetState = this.calculateStateFromNoiseLevel(data.currentDecibel, data.threshold);
    } else {
      targetState = this.transitionTable.get(this.currentState)?.get(event) || null;
    }
    
    if (targetState && targetState !== this.currentState) {
      return this.performTransition(targetState, event, data);
    }
    
    return false;
  }
  
  /**
   * 根据噪音水平计算目标状态
   */
  private calculateStateFromNoiseLevel(currentDecibel: number, threshold: number): AlertStatus {
    const context = this.context;
    context.currentDecibel = currentDecibel;
    context.threshold = threshold;
    context.duration = Date.now() - context.startTime;
    
    // 检查是否超过阈值
    if (currentDecibel >= threshold + this.config.escalationThresholdOffset) {
      // 记录警报触发时的实际分贝值
      this.alertTriggerDecibel = currentDecibel;
      return AlertStatus.ALERT_ESCALATED;
    } else if (currentDecibel >= threshold) {
      // 记录警报触发时的实际分贝值
      this.alertTriggerDecibel = currentDecibel;
      // 检查是否应该升级到持续警报
      if (this.isAlertState(this.currentState) &&
          context.duration >= this.config.persistentAlertDuration) {
        return AlertStatus.ALERT_PERSISTENT;
      }
      return AlertStatus.ALERT_ACTIVE;
    } else if (currentDecibel >= threshold - this.config.warningThresholdOffset) {
      // 当分贝值低于阈值时，清除警报触发记录
      this.alertTriggerDecibel = 0;
      return AlertStatus.WARNING;
    } else {
      // 当分贝值远低于阈值时，清除警报触发记录
      this.alertTriggerDecibel = 0;
      return AlertStatus.MONITORING;
    }
  }
  
  /**
   * 检查是否需要防抖
   */
  private shouldDebounce(event: AlertEvent): boolean {
    if (event !== AlertEvent.NOISE_LEVEL_CHANGED) {
      return false;
    }
    
    const now = Date.now();
    if (now - this.lastTransitionTime < this.config.debounceTime) {
      return true;
    }
    
    return false;
  }
  
  /**
   * 检查状态转换是否允许
   */
  private canTransition(event: AlertEvent): boolean {
    const transitions = this.transitionTable.get(this.currentState);
    if (!transitions) {
      return false;
    }
    
    // 允许自转换（状态不变但更新上下文）
    if (event === AlertEvent.NOISE_LEVEL_CHANGED) {
      return true;
    }
    
    return transitions.has(event);
  }
  
  /**
   * 执行状态转换
   */
  private performTransition(toState: AlertStatus, event: AlertEvent, data?: NoiseLevelData): boolean {
    const fromState = this.currentState;
    const timestamp = Date.now();
    
    // 更新警报持续时间管理
    this.updateAlertDurationManagement(fromState, toState, timestamp);
    
    // 更新上下文
    this.context.previousState = fromState;
    this.context.startTime = timestamp;
    
    // 记录状态转换
    const transition: StateTransition = {
      from: fromState,
      to: toState,
      event: event,
      timestamp: timestamp,
      context: this.cloneContext(this.context)
    };
    
    this.stateHistory.push(transition);
    this.currentState = toState;
    this.lastTransitionTime = timestamp;
    
    // 限制历史记录长度
    if (this.stateHistory.length > 100) {
      this.stateHistory = this.stateHistory.slice(-50);
    }
    
    console.log(`状态转换: ${fromState} -> ${toState}, 事件: ${event}`);
    return true;
  }
  
  /**
   * 更新警报持续时间管理
   * 修复：只在真正进入/退出警报状态时才更新持续时间
   */
  private updateAlertDurationManagement(fromState: AlertStatus, toState: AlertStatus, timestamp: number): void {
    const wasInAlert = this.isAlertState(fromState);
    const isInAlert = this.isAlertState(toState);
    
    if (!wasInAlert && isInAlert) {
      // 首次进入警报状态，设置开始时间
      this.alertStartTime = timestamp;
      this.alertDuration = 0;
    } else if (wasInAlert && !isInAlert) {
      // 完全退出警报状态，保存持续时间
      this.alertDuration = timestamp - this.alertStartTime;
      this.alertStartTime = 0;
    }
    // 在警报状态之间切换时（如 ALERT_ACTIVE -> ALERT_PERSISTENT），不重置开始时间
  }
  
  /**
   * 检查是否为警报状态
   */
  private isAlertState(state: AlertStatus): boolean {
    return state === AlertStatus.ALERT_ACTIVE ||
           state === AlertStatus.ALERT_PERSISTENT ||
           state === AlertStatus.ALERT_ESCALATED;
  }
  
  /**
   * 获取当前状态
   */
  @Computed
  public get CurrentState(): AlertStatus {
    return this.currentState;
  }
  
  /**
   * 获取状态上下文
   */
  public getContext(): AlertStateContext {
    return this.cloneContext(this.context);
  }

  /**
   * 获取状态历史
   */
  public getStateHistory(): StateTransition[] {
    return this.stateHistory.slice();
  }
  
  /**
   * 重置状态机
   */
  public reset(): void {
    this.currentState = AlertStatus.IDLE;
    this.context = this.createDefaultContext();
    this.stateHistory = [];
    this.lastTransitionTime = Date.now();
    // 重置警报持续时间
    this.alertStartTime = 0;
    this.alertDuration = 0;
    // 重置警报触发分贝值记录
    this.alertTriggerDecibel = 0;
  }
  
  /**
   * 检查是否处于警报状态
   */
  @Computed
  public get AlertActive(): boolean {
    return this.currentState === AlertStatus.ALERT_ACTIVE ||
           this.currentState === AlertStatus.ALERT_PERSISTENT ||
           this.currentState === AlertStatus.ALERT_ESCALATED;
  }
  
  /**
   * 检查是否处于警告状态
   */
  public isWarningActive(): boolean {
    return this.currentState === AlertStatus.WARNING;
  }
  
  /**
   * 检查是否处于监控状态
   */
  public isMonitoring(): boolean {
    return this.currentState === AlertStatus.MONITORING;
  }
  
  /**
   * 获取状态持续时间
   */
  public getStateDuration(): number {
    return Date.now() - this.context.startTime;
  }
  
  /**
   * 获取警报持续时间
   */
  @Computed
  public get AlertDuration(): number {
    if (this.AlertActive) {
      return this.currentTime - this.alertStartTime;
    }
    return this.alertDuration;
  }
  
  /**
   * 获取格式化警报持续时间
   */
  @Computed
  public get FormattedAlertDuration(): string {
    const duration = this.AlertDuration;
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

  /**
   * 获取警报触发时的实际分贝值 - 修复分贝值不一致问题
   */
  @Computed
  public get AlertTriggerDecibel(): number {
    return this.alertTriggerDecibel;
  }
  
  /**
   * 合并配置对象
   */
  private mergeConfig(defaultConfig: StateMachineConfig, overrideConfig?: Partial<StateMachineConfig>): StateMachineConfig {
    const result: StateMachineConfig = {
      warningThresholdOffset: defaultConfig.warningThresholdOffset,
      persistentAlertDuration: defaultConfig.persistentAlertDuration,
      escalationThresholdOffset: defaultConfig.escalationThresholdOffset,
      debounceTime: defaultConfig.debounceTime
    };
    
    if (overrideConfig) {
      if (overrideConfig.warningThresholdOffset !== undefined) {
        result.warningThresholdOffset = overrideConfig.warningThresholdOffset;
      }
      if (overrideConfig.persistentAlertDuration !== undefined) {
        result.persistentAlertDuration = overrideConfig.persistentAlertDuration;
      }
      if (overrideConfig.escalationThresholdOffset !== undefined) {
        result.escalationThresholdOffset = overrideConfig.escalationThresholdOffset;
      }
      if (overrideConfig.debounceTime !== undefined) {
        result.debounceTime = overrideConfig.debounceTime;
      }
    }
    
    return result;
  }
  
  /**
   * 克隆上下文对象
   */
  private cloneContext(context: AlertStateContext): AlertStateContext {
    return {
      currentDecibel: context.currentDecibel,
      threshold: context.threshold,
      startTime: context.startTime,
      duration: context.duration,
      previousState: context.previousState,
      stateHistory: context.stateHistory.slice() // 浅拷贝数组
    };
  }

  /**
   * 销毁状态机
   */
  public destroy(): void {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = 0;
    }
    
    // 取消订阅秒定时器事件
    if (this.secondTickHandler) {
      this.secondTimerService.unsubscribe(this.secondTickHandler);
      this.secondTickHandler = null;
    }
    
    this.stateHistory = [];
  }
}