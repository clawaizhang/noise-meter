import { throttleTime, Subject, Subscription } from 'rxjs';

/**
 * 完美节流工具类
 * 内部维护多个节流队列，支持应用退出时清理
 */
export class Throttle {
  // 内部维护的节流队列
  private static normalClickSubject = new Subject<() => void>();

  // 订阅管理
  private static normalSubscription: Subscription;

  // 静态初始化 - 创建节流队列
  static {
    // 普通点击队列 - 500ms节流
    Throttle.normalSubscription = Throttle.normalClickSubject.pipe(
      throttleTime(500)
    ).subscribe((clickHandler:() => void) => {
      clickHandler();
    });

  }

  /**
   * 普通点击 - 500ms节流
   * 适用于大部分按钮操作
   */
  static click(clickHandler: () => void): void {
    Throttle.normalClickSubject.next(clickHandler);
  }

  /**
   * 应用退出时调用，清理所有节流队列
   * 释放内存，防止内存泄漏
   */
  static unsubscribe(): void {
    // 取消所有订阅
    if (Throttle.normalSubscription) {
      Throttle.normalSubscription.unsubscribe();
    }

    // 完成所有Subject
    Throttle.normalClickSubject.complete();

    console.log('节流队列已清理，内存已释放');
  }
}