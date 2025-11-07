import { AudioControllerLifecycleState, StateTransitionEvent, StateMachineConfig, AudioControllerStateMachineInterface } from '../models/AudioControllerLifecycleState';
import { AudioService, AudioServiceState } from './AudioService';
import { AudioControllerEvent, AudioControllerEventType, AudioControllerEventPublisher, StartRecordingEvent, StopRecordingEvent, PauseRecordingEvent, ResumeRecordingEvent, ResetDataEvent, StateChangeEvent } from '../models/AudioControllerEvents';

/**
 * AudioController状态机实现
 * 负责管理AudioController的完整生命周期状态
 */
export class AudioControllerStateMachine implements AudioControllerStateMachineInterface {
  private currentState: AudioControllerLifecycleState = AudioControllerLifecycleState.CONTROLLER_IDLE;
  private stateHistory: StateTransitionEvent[] = [];
  private stateChangeCallbacks: ((event: StateTransitionEvent) => void)[] = [];
  private errorCallbacks: ((error: string) => void)[] = [];
  private config: StateMachineConfig;
  private eventPublisher?: AudioControllerEventPublisher
  
  constructor( eventPublisher?: AudioControllerEventPublisher) {
    this.eventPublisher = eventPublisher;
    this.config = {
      enableRetry: true,
      maxRetryCount: 3,
      retryInterval: 1000,
      enableStateLogging: true
    };
    
    console.info('[AudioControllerStateMachine] 状态机初始化完成（事件驱动架构）');
  }

  public async pauseRecording(): Promise<void> {
    if (!this.canTransitionTo(AudioControllerLifecycleState.CONTROLLER_PAUSING)) {
      throw new Error(`无法从 ${this.currentState} 状态暂停录制`);
    }
    
    this.transitionTo(AudioControllerLifecycleState.CONTROLLER_PAUSING, '用户请求暂停录制');
    
    try {
      // 发布暂停录制事件
      this.publishEvent({
        type: AudioControllerEventType.PAUSE_RECORDING,
        timestamp: Date.now()
      } as PauseRecordingEvent);
      // 注意：实际的状态转换会在AudioService状态变化时触发
    } catch (error) {
      this.transitionTo(AudioControllerLifecycleState.CONTROLLER_ERROR, '暂停录制失败', error.message);
      throw new Error(error.message);
    }
  }

  /**
   * 状态转换验证
   */
  private canTransitionTo(targetState: AudioControllerLifecycleState): boolean {
    const validTransitions: Record<AudioControllerLifecycleState, AudioControllerLifecycleState[]> = {
      [AudioControllerLifecycleState.CONTROLLER_IDLE]: [
        AudioControllerLifecycleState.CONTROLLER_STARTING,
        AudioControllerLifecycleState.CONTROLLER_ERROR
      ],
      [AudioControllerLifecycleState.CONTROLLER_STARTING]: [
        AudioControllerLifecycleState.CONTROLLER_RECORDING,
        AudioControllerLifecycleState.CONTROLLER_ERROR
      ],
      [AudioControllerLifecycleState.CONTROLLER_RECORDING]: [
        AudioControllerLifecycleState.CONTROLLER_STOPPING,
        AudioControllerLifecycleState.CONTROLLER_PAUSING,
        AudioControllerLifecycleState.CONTROLLER_ERROR
      ],
      [AudioControllerLifecycleState.CONTROLLER_STOPPING]: [
        AudioControllerLifecycleState.CONTROLLER_IDLE,
        AudioControllerLifecycleState.CONTROLLER_ERROR
      ],
      [AudioControllerLifecycleState.CONTROLLER_PAUSING]: [
        AudioControllerLifecycleState.CONTROLLER_PAUSED,
        AudioControllerLifecycleState.CONTROLLER_ERROR
      ],
      [AudioControllerLifecycleState.CONTROLLER_PAUSED]: [
        AudioControllerLifecycleState.CONTROLLER_RESUMING,
        AudioControllerLifecycleState.CONTROLLER_STOPPING,
        AudioControllerLifecycleState.CONTROLLER_ERROR
      ],
      [AudioControllerLifecycleState.CONTROLLER_RESUMING]: [
        AudioControllerLifecycleState.CONTROLLER_RECORDING,
        AudioControllerLifecycleState.CONTROLLER_ERROR
      ],
      [AudioControllerLifecycleState.CONTROLLER_ERROR]: [
        AudioControllerLifecycleState.CONTROLLER_IDLE,
        AudioControllerLifecycleState.CONTROLLER_STARTING,
        AudioControllerLifecycleState.CONTROLLER_RESUMING
      ]
    };
    
    const allowedTransitions = validTransitions[this.currentState] || [];
    return allowedTransitions.includes(targetState);
  }
  
  /**
   * 执行状态转换
   */
  private transitionTo(newState: AudioControllerLifecycleState, reason?: string, error?: string): void {
    const oldState = this.currentState;
    
    if (!this.canTransitionTo(newState)) {
      const errorMsg = `无效的状态转换: ${oldState} -> ${newState}`;
      console.error(`[状态机] ${errorMsg}`);
      throw new Error(errorMsg);
    }
    
    this.currentState = newState;
    
    const event: StateTransitionEvent = {
      fromState: oldState,
      toState: newState,
      timestamp: Date.now(),
      reason,
      error
    };
    
    this.stateHistory.push(event);
    
    // 触发状态变更回调
    this.stateChangeCallbacks.forEach(callback => callback(event));

    // 发布状态变更事件
    this.publishStateChangeEvent(event);

    if (this.config.enableStateLogging) {
      console.info(`[状态机] ${oldState} -> ${newState} ${reason ? `原因: ${reason}` : ''}`);
    }
  }
  
  /**
   * 强制设置状态（仅用于测试）
   */
  public forceSetState(state: AudioControllerLifecycleState): void {
    this.currentState = state;
    console.warn(`[状态机] 强制设置状态为: ${state}`);
  }
  
  // ========== 状态查询方法 ==========
  
  public getCurrentState(): AudioControllerLifecycleState {
    return this.currentState;
  }
  
  public getStateHistory(): StateTransitionEvent[] {
    return [...this.stateHistory];
  }
  
  public isInState(state: AudioControllerLifecycleState): boolean {
    return this.currentState === state;
  }
  
  // ========== 状态控制方法 ==========
  
  public async startRecording(): Promise<void> {
    if (!this.canTransitionTo(AudioControllerLifecycleState.CONTROLLER_STARTING)) {
      throw new Error(`无法从 ${this.currentState} 状态启动录制`);
    }
    
    this.transitionTo(AudioControllerLifecycleState.CONTROLLER_STARTING, '用户请求启动录制');
    
    try {
      // 发布启动录制事件，而不是直接调用AudioController
      this.publishEvent({
        type: AudioControllerEventType.START_RECORDING,
        timestamp: Date.now()
      } as StartRecordingEvent);
      // 注意：实际的状态转换会在AudioService状态变化时触发
    } catch (error) {
      this.transitionTo(AudioControllerLifecycleState.CONTROLLER_ERROR, '启动录制失败', error.message);
      throw new Error(error.message);
    }
  }
  
  public async stopRecording(comments: string): Promise<void> {
    if (!this.canTransitionTo(AudioControllerLifecycleState.CONTROLLER_STOPPING)) {
      throw new Error(`无法从 ${this.currentState} 状态停止录制`);
    }
    
    this.transitionTo(AudioControllerLifecycleState.CONTROLLER_STOPPING, '用户请求停止录制');
    
    try {
      // 发布停止录制事件，而不是直接调用AudioController
      const stopEvent: StopRecordingEvent = {
        type: AudioControllerEventType.STOP_RECORDING,
        timestamp: Date.now(),
        payload: { comments }
      } as StopRecordingEvent;
      this.publishEvent(stopEvent as AudioControllerEvent);
      // 注意：实际的状态转换会在AudioService状态变化时触发
    } catch (error) {
      this.transitionTo(AudioControllerLifecycleState.CONTROLLER_ERROR, '停止录制失败', error.message);
      throw new Error(error.message);
    }
  }
  
  public async resumeRecording(): Promise<void> {
    if (!this.canTransitionTo(AudioControllerLifecycleState.CONTROLLER_RESUMING)) {
      throw new Error(`无法从 ${this.currentState} 状态恢复录制`);
    }
    
    this.transitionTo(AudioControllerLifecycleState.CONTROLLER_RESUMING, '用户请求恢复录制');
    
    try {
      // 发布恢复录制事件
      this.publishEvent({
        type: AudioControllerEventType.RESUME_RECORDING,
        timestamp: Date.now()
      } as ResumeRecordingEvent);
      // 注意：实际的状态转换会在AudioService状态变化时触发
    } catch (error) {
      this.transitionTo(AudioControllerLifecycleState.CONTROLLER_ERROR, '恢复录制失败', error.message);
      throw new Error(error.message);
    }
  }
  
  public async resetState(): Promise<void> {
    //reset 不需要状态转换
    try {
      // 发布重置数据事件，而不是直接调用AudioController
      this.publishEvent({
        type: AudioControllerEventType.RESET_DATA,
        timestamp: Date.now()
      } as ResetDataEvent);
    } catch (error) {
      console.error('[状态机] 重置状态失败:', error);
    }
  }
  
  // ========== 事件监听方法 ==========
  
  public onStateChange(callback: (event: StateTransitionEvent) => void): void {
    this.stateChangeCallbacks.push(callback);
  }
  
  public onError(callback: (error: string) => void): void {
    this.errorCallbacks.push(callback);
  }
  
  // ========== 配置管理方法 ==========
  
  public updateConfig(config: Partial<StateMachineConfig>): void {
    // 手动合并配置对象，避免使用展开操作符
    const mergedConfig: StateMachineConfig = {
      enableRetry: config.enableRetry ?? this.config.enableRetry,
      maxRetryCount: config.maxRetryCount ?? this.config.maxRetryCount,
      retryInterval: config.retryInterval ?? this.config.retryInterval,
      enableStateLogging: config.enableStateLogging ?? this.config.enableStateLogging
    };
    this.config = mergedConfig;
    console.info('[状态机] 配置已更新:', this.config);
  }
  
  public getConfig(): StateMachineConfig {
    // 手动复制配置对象，避免使用展开操作符
    return {
      enableRetry: this.config.enableRetry,
      maxRetryCount: this.config.maxRetryCount,
      retryInterval: this.config.retryInterval,
      enableStateLogging: this.config.enableStateLogging
    };
  }
  
  // ========== 事件发布方法 ==========

  /**
   * 发布事件
   */
  private publishEvent(event: AudioControllerEvent): void {
    if (this.eventPublisher) {
      this.eventPublisher.publishEvent(event);
    } else {
      console.warn('[状态机] 事件发布器未设置，无法发布事件:', event);
    }
  }

  /**
   * 发布状态变更事件
   */
  private publishStateChangeEvent(event: StateTransitionEvent): void {
    this.publishEvent({
      type: AudioControllerEventType.STATE_CHANGE,
      timestamp: Date.now(),
      payload: event
    } as AudioControllerEvent);
  }

  // ========== 资源清理方法 ==========

  public dispose(): void {
    this.stateChangeCallbacks = [];
    this.errorCallbacks = [];
    this.stateHistory = [];
    console.info('[状态机] 资源已清理');
  }
  
  /**
   * 处理AudioService状态变化
   * 这个方法需要在外部调用，用于同步AudioService状态
   */
  public handleAudioServiceStateChange(audioState: AudioServiceState, error?: string): void {
    switch (this.currentState) {
      case AudioControllerLifecycleState.CONTROLLER_STARTING:
        if (audioState === AudioServiceState.CAPTURING) {
          this.transitionTo(AudioControllerLifecycleState.CONTROLLER_RECORDING, 'AudioService开始采集');
        } else if (audioState === AudioServiceState.IDLE) {
          this.transitionTo(AudioControllerLifecycleState.CONTROLLER_ERROR, 'AudioService启动失败', error);
        }
        break;
        
      case AudioControllerLifecycleState.CONTROLLER_RESUMING:
        if (audioState === AudioServiceState.IDLE || audioState === AudioServiceState.STARTING) {
          this.transitionTo(AudioControllerLifecycleState.CONTROLLER_RECORDING, 'AudioService恢复采集');
        } else if (audioState === AudioServiceState.CAPTURING) {
          this.transitionTo(AudioControllerLifecycleState.CONTROLLER_ERROR, 'AudioService恢复失败', error);
        }
        break;
        
      case AudioControllerLifecycleState.CONTROLLER_STOPPING:
        if (audioState === AudioServiceState.IDLE) {
          this.transitionTo(AudioControllerLifecycleState.CONTROLLER_IDLE, 'AudioService停止完成');
        }
        break;
        
      case AudioControllerLifecycleState.CONTROLLER_RECORDING:
        if (audioState === AudioServiceState.IDLE) {
          this.transitionTo(AudioControllerLifecycleState.CONTROLLER_ERROR, 'AudioService意外停止', error);
        }
        break;
        
      case AudioControllerLifecycleState.CONTROLLER_PAUSING:
        if (audioState === AudioServiceState.IDLE) {
          this.transitionTo(AudioControllerLifecycleState.CONTROLLER_PAUSED, 'AudioService暂停完成');
        }
        break;
    }
  }
}