import { SecondTimerService } from './SecondTimerService';
import { AudioControllerService } from './AudioControllerService';
import { AudioControllerLifecycleState } from '../models/AudioControllerLifecycleState';
import { PreferenceKeys } from '../models/PreferenceKeys';
import { AppKeys } from '../models/AppKeys';

/**
 * 自动保存服务
 * 统一管理自动保存和时间显示逻辑
 */
export class AutoSaveService {
  private static instance: AutoSaveService | null = null;
  private secondTimerService: SecondTimerService = SecondTimerService.getInstance();
  private audioControllerService: AudioControllerService | null = null;
  private ak: AppKeys;
  private pk: PreferenceKeys;
  // 自动保存相关属性
  private recordingStartTime: number = Date.now();
  private isAutoSaveEnabled: boolean = false;
  private isTimeDisplayEnabled: boolean = false;
  // 回调函数
  private autoSaveCheckCallback?: () => void;
  private timeDisplayCallback?: () => void;

  private constructor(ak: AppKeys, pk: PreferenceKeys) {
    this.ak = ak;
    this.pk = pk;
    // 初始化回调函数
    this.autoSaveCheckCallback = this.createAutoSaveCheckCallback();
    this.timeDisplayCallback = this.createTimeDisplayCallback();

    console.info('[AutoSaveService] 服务已初始化');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(ak: AppKeys, pk: PreferenceKeys): AutoSaveService {
    if (!AutoSaveService.instance) {
      AutoSaveService.instance = new AutoSaveService(ak, pk);
      console.info('[AutoSaveService] 创建新实例');
    }
    return AutoSaveService.instance;
  }

  /**
   * 设置AudioControllerService引用
   */
  public setAudioControllerService(service: AudioControllerService): void {
    this.audioControllerService = service;
  }

  /**
   * 创建自动保存检查回调
   */
  private createAutoSaveCheckCallback(): () => void {
    return (): void => {
      // 只有在真正录制状态下且自动保存已启用时才检查自动保存
      const isActuallyRecording = this.isActuallyRecording();

      if (this.pk?.auto_save_enabled && isActuallyRecording && this.isAutoSaveEnabled) {
        console.info('[自动保存] 秒定时器触发，检查是否需要保存');
        this.checkAutoSaveNow();
      }
    };
  }

  /**
   * 创建时间显示回调
   */
  private createTimeDisplayCallback(): () => void {
    return (): void => {
      // 只有在录制状态下才更新时间显示
      if (this.isActuallyRecording() && this.isTimeDisplayEnabled && this.ak.uiDisplayState) {
        const currentTime = Date.now();
        this.ak.uiDisplayState.updateCurrentTime(currentTime);
        this.ak.uiDisplayState.updateTimeDisplay(this.pk!);
      }
    };
  }

  /**
   * 检查是否真正在录制状态
   */
  private isActuallyRecording(): boolean {
    const stateMachine = this.audioControllerService?.getStateMachine();
    return stateMachine?.isInState(AudioControllerLifecycleState.CONTROLLER_RECORDING) ?? false;
  }

  /**
   * 启动自动保存监控
   */
  public startAutoSaveMonitoring(): void {
    this.stopAutoSaveMonitoring();

    // 检查自动保存配置是否有效
    if (!this.pk?.auto_save_enabled || this.pk.auto_save_interval <= 0) {
      console.warn('[自动保存] 自动保存配置无效，跳过启动监控');
      return;
    }

    this.isAutoSaveEnabled = true;

    // 使用SecondTimerService进行秒级检查
    if (this.autoSaveCheckCallback) {
      this.secondTimerService.subscribe(this.autoSaveCheckCallback);
    }

    // 重置上次保存时间
    this.recordingStartTime = Date.now();
    this.ak.uiDisplayState.updateRecordingStartTime(this.recordingStartTime);

    console.info('[自动保存] 自动保存监控已启动（使用SecondTimerService）');
  }

  /**
   * 恢复自动保存监控
   * 与startAutoSaveMonitoring的区别：不重置上次保存时间，继续使用现有时间
   */
  public resumeAutoSaveMonitoring(): void {
    this.stopAutoSaveMonitoring();

    // 检查自动保存配置是否有效
    if (!this.pk?.auto_save_enabled || this.pk.auto_save_interval <= 0) {
      console.warn('[自动保存] 自动保存配置无效，跳过恢复监控');
      return;
    }

    this.isAutoSaveEnabled = true;

    // 使用SecondTimerService进行秒级检查
    if (this.autoSaveCheckCallback) {
      this.secondTimerService.subscribe(this.autoSaveCheckCallback);
    }

    // 注意：恢复时不重置上次保存时间，继续使用现有时间

    console.info('[自动保存] 自动保存监控已恢复（使用SecondTimerService）');
  }

  /**
   * 停止自动保存监控
   */
  public stopAutoSaveMonitoring(): void {
    this.isAutoSaveEnabled = false;

    // 取消订阅SecondTimerService
    if (this.autoSaveCheckCallback) {
      this.secondTimerService.unsubscribe(this.autoSaveCheckCallback);
    }

    console.info('[自动保存] 自动保存监控已停止');
  }

  /**
   * 启动时间显示更新
   */
  public startTimeDisplayUpdates(): void {
    this.stopTimeDisplayUpdates();

    this.isTimeDisplayEnabled = true;

    // 使用SecondTimerService进行秒级时间显示更新
    if (this.timeDisplayCallback) {
      this.secondTimerService.subscribe(this.timeDisplayCallback);
    }

    // 立即更新一次时间显示
    if (this.ak.uiDisplayState) {
      this.ak.uiDisplayState.updateCurrentTime(Date.now());
      this.ak.uiDisplayState.updateTimeDisplay(this.pk!);
    }

    console.info('[时间显示] 时间显示更新已启动（使用SecondTimerService）');
  }

  /**
   * 停止时间显示更新
   */
  public stopTimeDisplayUpdates(): void {
    this.isTimeDisplayEnabled = false;

    // 取消订阅SecondTimerService
    if (this.timeDisplayCallback) {
      this.secondTimerService.unsubscribe(this.timeDisplayCallback);
    }

    console.info('[时间显示] 时间显示更新已停止');
  }

  /**
   * 检查自动保存
   */
  private checkAutoSaveNow(): void {
    // 三重检查：确保在录制状态、自动保存已启用且配置有效
    if (!this.isActuallyRecording() || !this.isAutoSaveEnabled || !this.pk?.auto_save_enabled) {
      console.info('[自动保存] 检查被跳过：不在录制状态或自动保存未启用');
      return;
    }

    // 检查自动保存间隔配置是否有效
    if (this.pk.auto_save_interval <= 0) {
      console.warn('[自动保存] 自动保存间隔配置无效，跳过检查');
      return;
    }

    const currentTime = Date.now();
    const elapsed = currentTime - this.recordingStartTime;
    const intervalMs = this.pk.auto_save_interval * 60 * 1000;
    const remaining = intervalMs - elapsed;

    console.info(`[自动保存检查] 当前时间: ${currentTime}, 上次保存: ${this.recordingStartTime}, 已过时间: ${elapsed}ms, 剩余时间: ${remaining}ms`);

    // 如果时间间隔已过，执行自动保存
    if (remaining <= 0) {
      this.recordingStartTime = Date.now();

      // 更新UI显示状态（只更新自动保存时间，不更新录音开始时间）
      if (this.ak.uiDisplayState) {
        this.ak.uiDisplayState.updateTimeDisplay(this.pk);
      }

      // 只有在真正录制状态下且时间间隔已过时才执行自动保存
      this.performAutoSave();
    }
  }

  /**
   * 执行自动保存
   */
  private async performAutoSave(): Promise<void> {
    console.info('[自动保存] 执行定时自动保存');

    // 最终状态检查：确保仍在录制状态
    if (!this.isActuallyRecording()) {
      console.warn('[自动保存] 自动保存被取消：录制状态已改变');
      return;
    }

    try {
      // 通过状态机触发保存，与手动保存使用相同路径
      await this.audioControllerService?.restartRecordingFromExternal('自动保存');
      console.info('[自动保存] 自动保存成功');
    } catch (error) {
      console.error('[自动保存] 自动保存失败:', error);
      // 自动保存失败时，重置上次保存时间以避免连续失败
      this.recordingStartTime = Date.now();
    }
  }

  /**
   * 更新录音开始时间
   */
  public updateRecordingStartTime(startTime: number): void {
    this.recordingStartTime = startTime;

    // 更新UI显示状态
    if (this.ak.uiDisplayState) {
      this.ak.uiDisplayState.updateRecordingStartTime(startTime);
      this.ak.uiDisplayState.updateTimeDisplay(this.pk!);
    }
  }

  /**
   * 清理资源
   */
  public cleanup(): void {
    this.stopAutoSaveMonitoring();
    this.stopTimeDisplayUpdates();
    console.info('[AutoSaveService] 资源已清理');
  }
}