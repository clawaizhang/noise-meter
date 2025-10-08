import { debounceTime, Subject, Subscription } from 'rxjs';

/**
 * 完美防抖工具类
 * 内部维护多个防抖队列，支持应用退出时清理
 */
export class Debounce {
  // 内部维护的防抖队列
  private static normalClickSubject = new Subject<() => void>();
  private static fastClickSubject = new Subject<() => void>();

  // 订阅管理
  private static normalSubscription: Subscription;
  private static fastSubscription: Subscription;

  // 静态初始化 - 创建防抖队列
  static {
    // 普通点击队列 - 300ms防抖
    Debounce.normalSubscription = Debounce.normalClickSubject.pipe(
      debounceTime(300)
    ).subscribe((clickHandler:() => void) => {
      clickHandler();
    });

    // 快速点击队列 - 150ms防抖
    Debounce.fastSubscription = Debounce.fastClickSubject.pipe(
      debounceTime(150)
    ).subscribe((clickHandler:() => void) => {
      clickHandler();
    });

  }

  /**
   * 普通点击 - 300ms防抖
   * 适用于大部分按钮操作
   */
  static click(clickHandler: () => void): void {
    Debounce.normalClickSubject.next(clickHandler);
  }

  /**
   * 快速点击 - 150ms防抖
   * 适用于切换、轻量操作
   */
  static fastClick(clickHandler: () => void): void {
    Debounce.fastClickSubject.next(clickHandler);
  }

  /**
   * 应用退出时调用，清理所有防抖队列
   * 释放内存，防止内存泄漏
   */
  static unsubscribe(): void {
    // 取消所有订阅
    if (Debounce.normalSubscription) {
      Debounce.normalSubscription.unsubscribe();
    }
    if (Debounce.fastSubscription) {
      Debounce.fastSubscription.unsubscribe();
    }

    // 完成所有Subject
    Debounce.normalClickSubject.complete();
    Debounce.fastClickSubject.complete();

    console.log('防抖队列已清理，内存已释放');
  }
}