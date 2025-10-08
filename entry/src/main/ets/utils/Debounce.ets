import { debounceTime, Subject, Subscription } from 'rxjs';

/**
 * 完美防抖工具类
 * 内部维护多个防抖队列，支持应用退出时清理
 */
export class Debounce {
  // 内部维护的防抖队列
  private static normalClickSubject = new Subject<() => void>();

  // 订阅管理
  private static normalSubscription: Subscription;

  // 静态初始化 - 创建防抖队列
  static {
    // 普通点击队列 - 300ms防抖
    Debounce.normalSubscription = Debounce.normalClickSubject.pipe(
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
   * 应用退出时调用，清理所有防抖队列
   * 释放内存，防止内存泄漏
   */
  static unsubscribe(): void {
    // 取消所有订阅
    if (Debounce.normalSubscription) {
      Debounce.normalSubscription.unsubscribe();
    }

    // 完成所有Subject
    Debounce.normalClickSubject.complete();

    console.log('防抖队列已清理，内存已释放');
  }
}