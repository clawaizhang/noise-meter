import { WatchUsageData } from '../../models/WatchUsageData';

const TAG = 'WatchUsageManager';

/**
 * 手表端使用状态枚举
 */
export enum UsageState {
  READY = 'ready',       // 准备开始
  RUNNING = 'running',   // 检测中
  PAUSED = 'paused',     // 单次时间到，等待操作
  LOCKED = 'locked'      // 次数用完，已锁定
}

/**
 * 手表端使用管理器
 * 管理非会员的每日使用限制：3次，每次60秒
 * 
 * 注意：WatchUsageData 需要在 UI 中通过 PersistenceV2.connect() 创建并传入
 */
export class WatchUsageManager {
  private data: WatchUsageData;
  private timer?: number;
  private onTickCallback: ((seconds: number) => void) | null = null;
  private onCompleteCallback: (() => void) | null = null;

  /**
   * 构造函数
   * @param data 通过 PersistenceV2.connect() 获取的 WatchUsageData 实例
   */
  constructor(data: WatchUsageData) {
    this.data = data;
    this.checkAndResetIfNeeded();
  }

  /**
   * 检查是否需要重置（跨天）
   */
  private checkAndResetIfNeeded(): void {
    if (this.data.needReset()) {
      console.info(`[${TAG}] 跨天重置使用次数`);
      this.data.reset();
    }
  }

  /**
   * 获取当前使用数据
   */
  getData(): WatchUsageData {
    this.checkAndResetIfNeeded();
    return this.data;
  }

  /**
   * 开始一次新的检测
   * @returns 是否成功开始（有剩余次数才能开始）
   */
  startSession(): boolean {
    this.checkAndResetIfNeeded();
    
    if (!this.data.hasRemainingTimes()) {
      console.warn(`[${TAG}] 没有剩余次数，无法开始`);
      return false;
    }

    this.data.startSession();
    console.info(`[${TAG}] 开始检测，剩余次数: ${this.data.getRemainingTimes()}`);
    return true;
  }

  /**
   * 结束当前检测（手动停止或时间到）
   * @param isTimeUp 是否是时间到结束
   */
  endSession(isTimeUp: boolean = false): void {
    if (isTimeUp) {
      this.data.endSession();
      console.info(`[${TAG}] 检测结束，已使用次数: ${this.data.usedTimes}`);
    }
  }

  /**
   * 开始倒计时
   */
  startCountdown(
    onTick: (seconds: number) => void,
    onComplete: () => void
  ): void {
    this.stopCountdown();
    this.onTickCallback = onTick;
    this.onCompleteCallback = onComplete;

    // 立即回调一次当前秒数
    if (this.onTickCallback) {
      this.onTickCallback(this.data.remainingSeconds);
    }

    this.timer = setInterval(() => {
      this.data.tick();
      
      if (this.onTickCallback) {
        this.onTickCallback(this.data.remainingSeconds);
      }

      if (this.data.remainingSeconds <= 0) {
        this.stopCountdown();
        this.endSession(true);
        if (this.onCompleteCallback) {
          this.onCompleteCallback();
        }
      }
    }, 1000);

    console.info(`[${TAG}] 倒计时开始: ${this.data.remainingSeconds}s`);
  }

  /**
   * 停止倒计时
   */
  stopCountdown(): void {
    if (this.timer !== undefined) {
      clearInterval(this.timer);
      this.timer = undefined;
      console.info(`[${TAG}] 倒计时停止`);
    }
  }

  /**
   * 重置倒计时（用于重新开始）
   */
  resetCountdown(): void {
    this.stopCountdown();
    this.data.resetCountdown();
  }

  /**
   * 获取当前状态
   */
  getState(): UsageState {
    this.checkAndResetIfNeeded();
    
    const remainingTimes = this.data.getRemainingTimes();
    
    if (remainingTimes === 0) {
      return UsageState.LOCKED;
    }
    
    if (this.data.remainingSeconds <= 0) {
      return UsageState.PAUSED;
    }
    
    if (this.timer !== undefined) {
      return UsageState.RUNNING;
    }
    
    return UsageState.READY;
  }

  /**
   * 检查是否是受限状态（非会员）
   */
  isRestricted(isMember: boolean): boolean {
    return !isMember;
  }
}
