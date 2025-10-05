/**
 * 使用时长追踪服务
 * 负责追踪用户使用APP的时长
 */

import { PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../models/PreferenceKeys';
import { ContinuousUsageManager } from './ContinuousUsageManager';

// 使用时长追踪状态
export enum UsageTrackingState {
  IDLE = 'IDLE',        // 空闲状态
  TRACKING = 'TRACKING', // 追踪中
  PAUSED = 'PAUSED'     // 已暂停
}

export class UsageTrackingService {
  private static instance: UsageTrackingService | null = null;
  private pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  private continuousUsageManager: ContinuousUsageManager = ContinuousUsageManager.getInstance();
  
  private usageTimer: number = 0;
  private currentSeconds: number = 0;
  private state: UsageTrackingState = UsageTrackingState.IDLE;
  private secondsChangeCallbacks: ((seconds: number) => void)[] = [];
  private stateChangeCallbacks: ((state: UsageTrackingState) => void)[] = [];
  private usageCompleteCallbacks: ((seconds: number) => void)[] = [];

  /**
   * 获取 UsageTrackingService 实例
   */
  public static getInstance(): UsageTrackingService {
    if (!UsageTrackingService.instance) {
      UsageTrackingService.instance = new UsageTrackingService();
    }
    return UsageTrackingService.instance;
  }

  /**
   * 初始化服务
   */
  public initialize(): void {
    // 恢复上次的使用秒数
    this.currentSeconds = this.continuousUsageManager.getTodayUsageSeconds();
    
    // 如果今日已完成使用，重置状态
    if (this.continuousUsageManager.isTodayUsageCompleted()) {
      this.currentSeconds = 60; // 设置为完成状态
    }
    
    console.info(`[使用追踪] 初始化完成，当前使用秒数: ${this.currentSeconds}`);
  }

  /**
   * 开始追踪使用时长
   */
  public startTracking(): void {
    if (this.state === UsageTrackingState.TRACKING) {
      return; // 已经在追踪中
    }

    // 如果今日已完成使用，不再开始追踪
    if (this.continuousUsageManager.isTodayUsageCompleted()) {
      console.info('[使用追踪] 今日使用已完成，不再开始追踪');
      return;
    }

    this.state = UsageTrackingState.TRACKING;
    this.notifyStateChange();
    
    // 记录最后进入前台时间
    this.pk.last_app_foreground_time = Date.now();
    
    // 开始计时器
    this.startUsageTimer();
    
    console.info('[使用追踪] 开始追踪使用时长');
  }

  /**
   * 暂停追踪（APP进入后台）
   */
  public pauseTracking(): void {
    if (this.state !== UsageTrackingState.TRACKING) {
      return;
    }

    this.state = UsageTrackingState.PAUSED;
    this.notifyStateChange();
    
    // 停止计时器
    this.stopUsageTimer();
    
    // 保存当前进度
    this.saveUsageProgress();
    
    console.info(`[使用追踪] 暂停追踪，当前使用秒数: ${this.currentSeconds}`);
  }

  /**
   * 恢复追踪（APP回到前台）
   */
  public resumeTracking(): void {
    if (this.state !== UsageTrackingState.PAUSED) {
      return;
    }

    this.state = UsageTrackingState.TRACKING;
    this.notifyStateChange();
    
    // 更新最后进入前台时间
    this.pk.last_app_foreground_time = Date.now();
    
    // 重新开始计时器
    this.startUsageTimer();
    
    console.info('[使用追踪] 恢复追踪使用时长');
  }

  /**
   * 停止追踪
   */
  public stopTracking(): void {
    this.state = UsageTrackingState.IDLE;
    this.notifyStateChange();
    
    // 停止计时器
    this.stopUsageTimer();
    
    // 保存当前进度
    this.saveUsageProgress();
    
    console.info('[使用追踪] 停止追踪使用时长');
  }

  /**
   * 获取当前使用秒数
   * @returns 使用秒数
   */
  public getCurrentSeconds(): number {
    return this.currentSeconds;
  }

  /**
   * 获取追踪状态
   * @returns 追踪状态
   */
  public getTrackingState(): UsageTrackingState {
    return this.state;
  }

  /**
   * 检查是否完成今日使用
   * @returns 是否完成
   */
  public isTodayUsageCompleted(): boolean {
    return this.continuousUsageManager.isTodayUsageCompleted();
  }

  /**
   * 获取今日使用进度百分比
   * @param totalSeconds 总需要秒数
   * @returns 进度百分比 (0-100)
   */
  public getProgressPercent(totalSeconds: number = 60): number {
    return Math.min(100, Math.round((this.currentSeconds / totalSeconds) * 100));
  }

  /**
   * 获取剩余秒数
   * @param totalSeconds 总需要秒数
   * @returns 剩余秒数
   */
  public getRemainingSeconds(totalSeconds: number = 60): number {
    return Math.max(0, totalSeconds - this.currentSeconds);
  }

  /**
   * 注册使用秒数变化回调
   * @param callback 回调函数
   */
  public onSecondsChange(callback: (seconds: number) => void): void {
    this.secondsChangeCallbacks.push(callback);
  }

  /**
   * 注册状态变化回调
   * @param callback 回调函数
   */
  public onStateChange(callback: (state: UsageTrackingState) => void): void {
    this.stateChangeCallbacks.push(callback);
  }

  /**
   * 注册使用完成回调
   * @param callback 回调函数
   */
  public onUsageComplete(callback: (seconds: number) => void): void {
    this.usageCompleteCallbacks.push(callback);
  }

  /**
   * 开始使用计时器
   */
  private startUsageTimer(): void {
    this.stopUsageTimer(); // 确保没有重复的计时器
    
    this.usageTimer = setInterval(() => {
      if (this.state === UsageTrackingState.TRACKING) {
        this.currentSeconds++;
        
        // 更新到连续使用管理器
        this.continuousUsageManager.updateTodayUsageSeconds(this.currentSeconds);
        
        // 通知秒数变化
        this.notifySecondsChange();
        
        // 每10秒自动保存进度
        if (this.currentSeconds % 10 === 0) {
          this.saveUsageProgress();
        }
        
        // 检查是否完成使用
        if (this.currentSeconds >= 60 && !this.continuousUsageManager.isTodayUsageCompleted()) {
          this.handleUsageCompletion();
        }
        
        // 检查使用时长异常
        this.handleUsageTimeException();
      }
    }, 1000);
  }

  /**
   * 停止使用计时器
   */
  private stopUsageTimer(): void {
    if (this.usageTimer) {
      clearInterval(this.usageTimer);
      this.usageTimer = 0;
    }
  }

  /**
   * 处理使用完成
   */
  private handleUsageCompletion(): void {
    console.info('[使用追踪] 今日使用已完成');
    
    // 标记今日使用完成
    this.continuousUsageManager.markTodayUsageCompleted();
    
    // 保存最终进度
    this.saveUsageProgress();
    
    // 通知使用完成
    this.notifyUsageComplete();
    
    // 停止追踪
    this.stopTracking();
  }

  /**
   * 处理使用时长异常
   */
  private handleUsageTimeException(): void {
    // 如果使用时长异常大，可能是系统时间被修改
    if (this.currentSeconds > 3600) { // 超过1小时
      console.warn('[使用追踪] 检测到使用时长异常，重置今日使用数据');
      this.continuousUsageManager.resetContinuousUsageData();
      this.currentSeconds = 0;
      this.notifySecondsChange();
    }
  }

  /**
   * 保存使用进度
   */
  private saveUsageProgress(): void {
    // 使用PersistenceV2自动持久化@Trace注解的数据
    // 这里只需要确保数据同步到ContinuousUsageManager
    this.continuousUsageManager.updateTodayUsageSeconds(this.currentSeconds);
  }

  /**
   * 通知秒数变化
   */
  private notifySecondsChange(): void {
    this.secondsChangeCallbacks.forEach(callback => {
      try {
        callback(this.currentSeconds);
      } catch (error) {
        console.error('[使用追踪] 秒数变化回调执行失败:', error);
      }
    });
  }

  /**
   * 通知状态变化
   */
  private notifyStateChange(): void {
    this.stateChangeCallbacks.forEach(callback => {
      try {
        callback(this.state);
      } catch (error) {
        console.error('[使用追踪] 状态变化回调执行失败:', error);
      }
    });
  }

  /**
   * 通知使用完成
   */
  private notifyUsageComplete(): void {
    this.usageCompleteCallbacks.forEach(callback => {
      try {
        callback(this.currentSeconds);
      } catch (error) {
        console.error('[使用追踪] 使用完成回调执行失败:', error);
      }
    });
  }

  /**
   * 清理资源
   */
  public destroy(): void {
    this.stopTracking();
    this.secondsChangeCallbacks = [];
    this.stateChangeCallbacks = [];
    this.usageCompleteCallbacks = [];
  }
}