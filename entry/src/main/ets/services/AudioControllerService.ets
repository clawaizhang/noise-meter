import { Subject, BehaviorSubject, filter, throttleTime } from 'rxjs';
import { UIDisplayState } from '../models/UIDisplayState';
import { DataProcessingState } from '../models/DataProcessingState';
import { PreferenceKeys } from '../models/PreferenceKeys';
import { AppKeys } from '../models/AppKeys';
import { LocationInfo } from '../services/LocationService';
import { AudioControllerStateMachine } from './AudioControllerStateMachine';
import { AudioControllerLifecycleState, StateTransitionEvent } from '../models/AudioControllerLifecycleState';
import { AudioService, AudioServiceState } from './AudioService';
import { AutoSaveService } from './AutoSaveService';
import {
  AudioControllerEvent,
  AudioControllerEventType,
  AudioControllerEventPublisher,
  StartRecordingEvent,
  StopRecordingEvent,
  PauseRecordingEvent,
  ResumeRecordingEvent,
  ResetDataEvent,
  StateChangeEvent,
  StopRecordingPayload
} from '../models/AudioControllerEvents';

/**
 * AudioController服务
 * 用于管理AudioController实例和事件通信
 */
export class AudioControllerService {
  private static instance: AudioControllerService | null = null;
  private dataProcessingState: DataProcessingState;
  private uiDisplayState: UIDisplayState;
  // 重置事件Subject
  private resetSubject = new Subject<void>();
  // 保存事件Subject
  private saveSubject = new Subject<string>();
  // 开始检测事件Subject
  private startDetectionSubject = new Subject<void>();
  // 暂停检测事件Subject
  private pauseDetectionSubject = new Subject<void>();
  // 位置数据Subject
  private locationSubject = new BehaviorSubject<LocationInfo | null>(null);
  // 错误数据Subject
  private errorSubject = new Subject<string[]>();
  private pk: PreferenceKeys;
  // 状态机相关
  private stateMachine?: AudioControllerStateMachine;
  private stateChangeSubject = new Subject<StateTransitionEvent>();
  // 事件总线
  private eventSubject = new Subject<AudioControllerEvent>();
  // 自动保存服务
  private autoSaveService: AutoSaveService;

  constructor(ak: AppKeys, pk: PreferenceKeys) {
    this.dataProcessingState = ak.dataProcessingState;
    this.uiDisplayState = ak.uiDisplayState;
    this.pk = pk;
    this.autoSaveService = AutoSaveService.getInstance(ak, pk);
    // 设置AutoSaveService的AudioControllerService引用
    this.autoSaveService.setAudioControllerService(this);
  }


  /**
   * 获取单例实例
   */
  public static getInstance(ak: AppKeys, pk: PreferenceKeys): AudioControllerService {
    if (!AudioControllerService.instance) {
      AudioControllerService.instance = new AudioControllerService(ak, pk);
      console.info('[AudioControllerService] 创建新实例');
    } else {
      console.info('[AudioControllerService] 返回现有实例');
    }
    return AudioControllerService.instance;
  }

  /**
   * 获取单例实例（不创建新实例）
   */
  public static getInstancePlain(): AudioControllerService | null {
    if (!AudioControllerService.instance) {
      console.warn('[AudioControllerService] 实例尚未初始化，返回null');
    }
    return AudioControllerService.instance;
  }

  /**
   * 触发重置事件
   */
  public resetData(): void {
    this.resetSubject.next();
  }

  /**
   * 触发保存事件
   */
  public saveData(comments: string): void {
    this.saveSubject.next(comments);
  }

  /**
   * 触发开始检测事件
   */
  public startDetection(): void {
    this.startDetectionSubject.next();
  }

  /**
   * 触发暂停检测事件
   */
  public pauseDetection(): void {
    this.pauseDetectionSubject.next();
  }

  /**
   * 订阅重置事件
   */
  public subscribeReset(callback: () => void): void {
    this.onResetData(callback);
  }

  /**
   * 订阅保存事件
   */
  public subscribeSave(callback: (comments: string) => void): void {
    this.onStopRecording(callback);
  }

  /**
   * 订阅开始检测事件
   */
  public subscribeStartDetection(callback: () => void): void {
    this.onStartRecording(callback);
  }

  /**
   * 订阅暂停检测事件
   */
  public subscribeStopDetection(callback: (comment:string) => void): void {
    this.onStopRecording(callback);
  }

  /**
   * 订阅暂停检测事件
   */
  public subscribePauseDetection(callback: () => void): void {
    this.onPauseRecording(callback);
  }

  /**
   * 订阅恢复检测事件
   */
  public subscribeResumeDetection(callback: () => void): void {
    this.onResumeRecording(callback);
  }

  /**
   * 更新位置信息
   */
  public updateLocation(location: LocationInfo | null): void {
    this.locationSubject.next(location);
  }

  /**
   * 获取位置Observable
   */
  public getLocation$() {
    return this.locationSubject.asObservable();
  }

  /**
   * 发布错误信息
   */
  public publishError(errors: string[]): void {
    this.errorSubject.next(errors);
  }

  /**
   * 获取错误Observable
   */
  public getError$() {
    return this.errorSubject.asObservable();
  }

  /**
   * 暂停UI更新（后台运行时调用）
   */
  public pauseUIUpdates(): void {
    this.uiDisplayState.pauseUIUpdates();
    this.dataProcessingState.isBackground = true;
    console.info('[双管线架构] UI更新已暂停');
  }

  /**
   * 恢复UI更新（前台运行时调用）
   */
  public resumeUIUpdates(): void {
    this.uiDisplayState.resumeUIUpdates();
    this.dataProcessingState.isBackground = false;
    // 同步最新数据到UI
    this.uiDisplayState.syncFromProcessingState(this.dataProcessingState);
    // 立即更新一次时间显示
    this.uiDisplayState.updateTimeDisplay(this.pk);
    console.info('[双管线架构] UI更新已恢复');
  }

  /**
   * 检查是否在后台运行
   */
  public isInBackground(): boolean {
    return this.dataProcessingState.isBackground;
  }

  /**
   * 启动时间显示更新
   */
  public startTimeDisplayUpdates(): void {
    this.autoSaveService.startTimeDisplayUpdates();
  }

  /**
   * 停止时间显示更新
   */
  public stopTimeDisplayUpdates(): void {
    this.autoSaveService.stopTimeDisplayUpdates();
  }

  /**
   * 更新录音开始时间
   * @param startTime 录音开始时间戳
   */
  public updateRecordingStartTime(startTime: number): void {
    this.autoSaveService.updateRecordingStartTime(startTime);
  }

  /**
   * 恢复自动保存监控
   * 与startAutoSaveMonitoring的区别：不重置上次保存时间，继续使用现有时间
   */
  public resumeAutoSaveMonitoring(): void {
    this.autoSaveService.resumeAutoSaveMonitoring();
  }

  // ========== 事件总线方法 ==========

  /**
   * 发布事件
   */
  public publishEvent(event: AudioControllerEvent): void {
    this.eventSubject.next(event);
    console.info(`[事件总线] 发布事件: ${event.type}`, event);
  }

  /**
   * 订阅所有事件
   */
  public onEvent(callback: (event: AudioControllerEvent) => void): void {
    // 去重
    this.eventSubject.subscribe(callback);
  }

  /**
   * 订阅启动录制事件
   */
  public onStartRecording(callback: () => void): void {
    this.eventSubject.pipe(
      filter(event => event.type === AudioControllerEventType.START_RECORDING),
      throttleTime(100)
    ).subscribe(callback);
  }

  /**
   * 订阅停止录制事件
   */
  public onStopRecording(callback: (comments: string) => void): void {
    this.eventSubject.pipe(
      filter(event => event.type === AudioControllerEventType.STOP_RECORDING),
      throttleTime(100)
    ).subscribe(event => {
      const stopEvent = event as StopRecordingEvent;
      callback((stopEvent.payload as StopRecordingPayload).comments);
    });
  }

  /**
   * 订阅暂停录制事件
   */
  public onPauseRecording(callback: () => void): void {
    this.eventSubject.pipe(
      filter(event => event.type === AudioControllerEventType.PAUSE_RECORDING),
      throttleTime(100)
    ).subscribe(callback);
  }

  /**
   * 订阅恢复录制事件
   */
  public onResumeRecording(callback: () => void): void {
    this.eventSubject.pipe(
      filter(event => event.type === AudioControllerEventType.RESUME_RECORDING),
      throttleTime(100)
    ).subscribe(callback);
  }

  /**
   * 订阅重置数据事件
   */
  public onResetData(callback: () => void): void {
    this.eventSubject.pipe(
      filter(event => event.type === AudioControllerEventType.RESET_DATA),
      throttleTime(100)
    ).subscribe(callback);
  }

  /**
   * 设置事件路由
   */
  private setupEventRouting(): void {
    // 将事件总线事件路由到现有的Subject，保持向后兼容性
    this.onStartRecording(() => {
      console.info('[事件路由] 触发开始检测事件');
      this.startDetectionSubject.next();
    });

    this.onStopRecording((comments: string) => {
      console.info('[事件路由] 触发保存事件:', comments);
      this.saveSubject.next(comments);
    });

    this.onPauseRecording(() => {
      console.info('[事件路由] 触发暂停检测事件');
      this.pauseDetectionSubject.next();
    });

    this.onResumeRecording(() => {
      console.info('[事件路由] 触发恢复检测事件');
      this.startDetectionSubject.next();
    });

    this.onResetData(() => {
      console.info('[事件路由] 触发重置事件');
      this.resetSubject.next();
    });
  }

  /**
   * 清理资源
   */
  public dispose(): void {
    this.stopTimeDisplayUpdates();
    this.resetSubject.complete();
    this.saveSubject.complete();
    this.startDetectionSubject.complete();
  }

  // ========== 状态机相关方法 ==========

  /**
   * 初始化状态机
   */
  public initializeStateMachine(): void {
    if (!this.stateMachine) {

      // 创建事件发布器适配器 - 使用箭头函数避免 this 绑定问题
      const eventPublisher: AudioControllerEventPublisher = {
        publishEvent: (event: AudioControllerEvent): void => {
          // 直接使用 eventSubject 发布事件，避免递归调用
          this.eventSubject.next(event);
          console.info(`[事件总线] 发布事件: ${event.type}`, event);
        },
        onEvent: (callback: (event: AudioControllerEvent) => void): void => {
          this.eventSubject.subscribe(callback);
        }
      };

      // 重构后的构造函数，不再传入AudioController
      this.stateMachine = new AudioControllerStateMachine(eventPublisher);

      // 设置状态变更监听
      this.stateMachine.onStateChange((event) => {
        this.handleStateChange(event);
      });

      // 设置错误监听
      this.stateMachine.onError((error) => {
        this.publishError([error]);
      });

      // 设置事件路由
      this.setupEventRouting();

      // 注册AudioService状态监听器 - 修复状态同步问题
      const audioService = AudioService.getInstance();
      audioService.addStateChangeListener((audioState: AudioServiceState) => {
        this.handleAudioServiceStateChange(audioState);
      });

      console.info('[AudioControllerService] 状态机初始化完成（事件驱动架构）');
    }
  }

  /**
   * 获取状态机实例
   */
  public getStateMachine(): AudioControllerStateMachine | null {
    return this.stateMachine ?? null;
  }

  /**
   * 处理状态变更事件
   */
  private handleStateChange(event: StateTransitionEvent): void {
    // 通过RxJS发布状态变更事件
    this.stateChangeSubject.next(event);

    // 根据状态变更执行相应操作
    switch (event.toState) {
      case AudioControllerLifecycleState.CONTROLLER_ERROR:
        // 发布错误信息
        if (event.error) {
          this.publishError([event.error]);
        }
        break;

      case AudioControllerLifecycleState.CONTROLLER_RECORDING:
        console.info('[状态机] 录制已开始');
        break;

      case AudioControllerLifecycleState.CONTROLLER_IDLE:
        console.info('[状态机] 录制已停止');
        break;
    }
  }

  /**
   * 状态查询接口 - 供外部服务使用
   */
  public getCurrentState(): AudioControllerLifecycleState | null {
    return this.stateMachine?.getCurrentState() ?? null;
  }

  public getStateHistory(): StateTransitionEvent[] {
    return this.stateMachine?.getStateHistory() ?? [];
  }

  public isRecording(): boolean {
    const state = this.getCurrentState();
    return state === AudioControllerLifecycleState.CONTROLLER_RECORDING;
  }

  public isStarting(): boolean {
    const state = this.getCurrentState();
    return state === AudioControllerLifecycleState.CONTROLLER_STARTING;
  }

  public isStopping(): boolean {
    const state = this.getCurrentState();
    return state === AudioControllerLifecycleState.CONTROLLER_STOPPING;
  }

  public isInError(): boolean {
    const state = this.getCurrentState();
    return state === AudioControllerLifecycleState.CONTROLLER_ERROR;
  }

  /**
   * 状态控制接口 - 供外部服务使用
   */
  public async startRecordingFromExternal(): Promise<void> {
    if (!this.stateMachine) {
      throw new Error('状态机未初始化');
    }

    try {
      await this.stateMachine.startRecording();
    } catch (error) {
      console.error('[外部服务] 启动录制失败:', error);
      throw new Error(error);
    }
  }

  public async stopRecordingFromExternal(comments: string): Promise<void> {
    if (!this.stateMachine) {
      throw new Error('状态机未初始化');
    }

    try {
      await this.stateMachine.stopRecording(comments);
    } catch (error) {
      console.error('[外部服务] 停止录制失败:', error);
      throw new Error(error);
    }
  }

  public async pauseRecordingFromExternal(): Promise<void> {
    if (!this.stateMachine) {
      throw new Error('状态机未初始化');
    }

    try {
      await this.stateMachine.pauseRecording();
    } catch (error) {
      console.error('[外部服务] 暂停录制失败:', error);
      throw new Error(error);
    }
  }

  public async resumeRecordingFromExternal(): Promise<void> {
    if (!this.stateMachine) {
      throw new Error('状态机未初始化');
    }

    try {
      await this.stateMachine.resumeRecording();
    } catch (error) {
      console.error('[外部服务] 恢复录制失败:', error);
      throw new Error(error);
    }
  }

  public async resetStateFromExternal(): Promise<void> {
    if (!this.stateMachine) {
      throw new Error('状态机未初始化');
    }

    try {
      await this.stateMachine.resetState();
    } catch (error) {
      console.error('[外部服务] 重置状态失败:', error);
      throw new Error(error);
    }
  }

  /**
   * 事件监听接口 - 供外部服务使用
   */
  public onStateChangeFromExternal(callback: (event: StateTransitionEvent) => void): void {
    this.stateChangeSubject.subscribe(callback);
  }

  public onErrorFromExternal(callback: (error: string) => void): void {
    this.errorSubject.subscribe((errors) => {
      if (errors.length > 0) {
        callback(errors[0]);
      }
    });
  }

  /**
   * 处理AudioService状态变化
   * 这个方法需要在AudioService状态变化时调用
   */
  public handleAudioServiceStateChange(audioState: AudioServiceState, error?: string): void {
    if (this.stateMachine) {
      this.stateMachine.handleAudioServiceStateChange(audioState, error);
    }
  }

  /**
   * 重启录制（停止后自动启动）
   * 供外部服务使用
   */
  public async restartRecordingFromExternal(comments: string): Promise<void> {
    if (!this.stateMachine) {
      throw new Error('状态机未初始化');
    }

    try {
      // 先停止录制
      await this.stateMachine.stopRecording(comments);

      // 等待状态变为IDLE后自动重新开始
      return new Promise<void>((resolve, reject) => {
        let timeoutId: number | undefined;
        const stateChangeSubscription = this.stateChangeSubject.subscribe((event) => {
          if (event.toState === AudioControllerLifecycleState.CONTROLLER_IDLE) {
            // 状态变为IDLE后，自动重新开始录制
            console.info('[AudioControllerService] 状态已变为IDLE，自动重新开始录制');
            this.stateMachine!.startRecording().then(resolve).catch(reject);

            // 清理订阅和超时
            if (timeoutId) {
              clearTimeout(timeoutId);
            }
            stateChangeSubscription.unsubscribe();
          }
        });

        // 设置超时保护
        timeoutId = setTimeout(() => {
          stateChangeSubscription.unsubscribe();
          reject(new Error('重启录制超时'));
        }, 10000); // 10秒超时
      });
    } catch (error) {
      console.error('[外部服务] 重启录制失败:', error);
      throw new Error(error);
    }
  }
}

