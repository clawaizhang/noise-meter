/**
 * AudioController生命周期状态枚举
 * 避免与AudioServiceState冲突，使用不同的状态名称
 */
export enum AudioControllerLifecycleState {
  CONTROLLER_IDLE = 'CONTROLLER_IDLE',           // 空闲状态
  CONTROLLER_STARTING = 'CONTROLLER_STARTING',   // 启动中状态
  CONTROLLER_RECORDING = 'CONTROLLER_RECORDING', // 录制中状态
  CONTROLLER_STOPPING = 'CONTROLLER_STOPPING',   // 停止中状态
  CONTROLLER_PAUSING = 'CONTROLLER_PAUSING',     // 暂停中状态
  CONTROLLER_PAUSED = 'CONTROLLER_PAUSED',       // 已暂停状态
  CONTROLLER_RESUMING = 'CONTROLLER_RESUMING',   // 恢复中状态
  CONTROLLER_ERROR = 'CONTROLLER_ERROR'          // 错误状态
}

/**
 * 状态转换事件接口
 */
export interface StateTransitionEvent {
  fromState: AudioControllerLifecycleState;
  toState: AudioControllerLifecycleState;
  timestamp: number;
  reason?: string;
  error?: string;
}

/**
 * 状态机配置接口
 */
export interface StateMachineConfig {
  enableRetry: boolean;
  maxRetryCount: number;
  retryInterval: number;
  enableStateLogging: boolean;
}

/**
 * 状态机接口定义
 */
export interface AudioControllerStateMachineInterface {
  // 状态查询
  getCurrentState(): AudioControllerLifecycleState;
  getStateHistory(): StateTransitionEvent[];
  isInState(state: AudioControllerLifecycleState): boolean;
  
  // 状态控制
  startRecording(): Promise<void>;
  stopRecording(comments: string): Promise<void>;
  pauseRecording(): Promise<void>;
  resumeRecording(): Promise<void>;
  resetState(): Promise<void>;
  
  // 事件监听
  onStateChange(callback: (event: StateTransitionEvent) => void): void;
  onError(callback: (error: string) => void): void;
  
  // 配置管理
  updateConfig(config: Partial<StateMachineConfig>): void;
  getConfig(): StateMachineConfig;
  
  // 资源清理
  dispose(): void;
}