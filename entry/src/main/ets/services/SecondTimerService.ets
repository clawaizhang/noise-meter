/**
 * 全局秒定时器服务
 * 提供每秒触发一次的事件，用于需要秒级更新的组件
 */
export class SecondTimerService {
  private static instance: SecondTimerService;
  private timerId: number = 0;
  private isRunning: boolean = false;
  private subscribers: Set<() => void> = new Set();
  
  private constructor() {
    // 私有构造函数
  }

  public static getInstance(): SecondTimerService {
    if (!SecondTimerService.instance) {
      SecondTimerService.instance = new SecondTimerService();
    }
    return SecondTimerService.instance;
  }

  /**
   * 启动秒定时器
   */
  public start(): void {
    if (this.isRunning) {
      return;
    }

    this.isRunning = true;
    this.timerId = setInterval(() => {
      this.emitSecondTick();
    }, 1000); // 每秒触发一次

    console.info('[SecondTimerService] 秒定时器已启动');
  }

  /**
   * 停止秒定时器
   */
  public stop(): void {
    if (!this.isRunning) {
      return;
    }

    this.isRunning = false;
    if (this.timerId) {
      clearInterval(this.timerId);
      this.timerId = 0;
    }

    console.info('[SecondTimerService] 秒定时器已停止');
  }

  /**
   * 订阅秒事件
   */
  public subscribe(callback: () => void): void {
    this.subscribers.add(callback);
  }

  /**
   * 取消订阅秒事件
   */
  public unsubscribe(callback: () => void): void {
    this.subscribers.delete(callback);
  }

  /**
   * 发射秒事件
   */
  private emitSecondTick(): void {
    // 通知所有订阅者
    this.subscribers.forEach(callback => {
      try {
        callback();
      } catch (error) {
        console.error('[SecondTimerService] 事件回调执行失败:', error);
      }
    });
  }

  /**
   * 检查定时器是否正在运行
   */
  public isTimerRunning(): boolean {
    return this.isRunning;
  }

  /**
   * 获取订阅者数量
   */
  public getSubscriberCount(): number {
    return this.subscribers.size;
  }

  /**
   * 销毁服务
   */
  public destroy(): void {
    this.stop();
    this.subscribers.clear();
    console.info('[SecondTimerService] 服务已销毁');
  }
}