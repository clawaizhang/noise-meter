import { commonEventManager } from '@kit.BasicServicesKit';
import hilog from '@ohos.hilog';

const TAG = 'DisplayManager';
const DOMAIN = 0x0000;

export class DisplayManager {
  private static instance: DisplayManager;
  private displayListeners: Set<() => void> = new Set();
  private hiddenListeners: Set<() => void> = new Set();
  private subscriber: commonEventManager.CommonEventSubscriber | undefined = undefined;
  private isSubscribed: boolean = false;

  private constructor() {
  }

  // 获取单例实例
  public static getInstance(): DisplayManager {
    if (!DisplayManager.instance) {
      DisplayManager.instance = new DisplayManager();
      DisplayManager.instance.initCommonEventSubscriber();
    }
    return DisplayManager.instance;
  }

  // 初始化公共事件订阅者
  private async initCommonEventSubscriber(): Promise<void> {
    try {
      const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
        events: ['usual.event.SCREEN_ON', 'usual.event.SCREEN_OFF'],
        priority: 80
      };

      this.subscriber = await commonEventManager.createSubscriber(subscribeInfo);
      await this.subscribeToCommonEvents();
      hilog.info(DOMAIN, TAG, '公共事件订阅者创建成功');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `创建公共事件订阅者失败: ${err.code}, ${err.message}`);
    }
  }

  // 订阅公共事件
  private async subscribeToCommonEvents(): Promise<void> {
    if (!this.subscriber || this.isSubscribed) {
      return;
    }

    try {
      if (canIUse('SystemCapability.Notification.CommonEvent')){
        commonEventManager.subscribe(this.subscriber, (err, data) => {
          if (err) {
            hilog.error(DOMAIN, TAG, `订阅公共事件失败: ${err.code}, ${err.message}`);
            return;
          }

          const event = data?.event;
          hilog.info(DOMAIN, TAG, `收到公共事件: ${event}`);

          if (event === 'usual.event.SCREEN_ON') {
            // 亮屏事件
            this.displayListeners.forEach(callback => callback());
            hilog.info(DOMAIN, TAG, '触发亮屏回调');
          } else if (event === 'usual.event.SCREEN_OFF') {
            // 熄屏事件
            this.hiddenListeners.forEach(callback => callback());
            hilog.info(DOMAIN, TAG, '触发熄屏回调');
          }
        });

      }

      this.isSubscribed = true;
      hilog.info(DOMAIN, TAG, '公共事件订阅成功');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `订阅公共事件异常: ${err.code}, ${err.message}`);
    }
  }

  // 退订公共事件
  private async unsubscribeFromCommonEvents(): Promise<void> {
    if (!this.subscriber || !this.isSubscribed) {
      return;
    }

    try {
      if (canIUse('SystemCapability.Notification.CommonEvent')) {
        commonEventManager.unsubscribe(this.subscriber);
      }
      this.isSubscribed = false;
      hilog.info(DOMAIN, TAG, '公共事件退订成功');
    } catch (err) {
      hilog.error(DOMAIN, TAG, `退订公共事件失败: ${err.code}, ${err.message}`);
    }
  }

  // 销毁订阅者
  public async destroy(): Promise<void> {
    await this.unsubscribeFromCommonEvents();
    this.displayListeners.clear();
    this.hiddenListeners.clear();
    this.subscriber = undefined;
    hilog.info(DOMAIN, TAG, 'DisplayManager已销毁');
  }

  public onForeground(): void {
    this.displayListeners.forEach(callback => callback());
  }

  public onBackground(): void {
    this.hiddenListeners.forEach(callback => callback());
  }

  // 注册屏幕显示回调
  public onDisplay(callback: () => void): void {
    this.displayListeners.add(callback);
  }

  // 取消注册屏幕显示回调
  public offDisplay(callback: () => void): void {
    this.displayListeners.delete(callback);
  }

  // 注册屏幕隐藏回调
  public onHidden(callback: () => void): void {
    this.hiddenListeners.add(callback);
  }

  // 取消注册屏幕隐藏回调
  public offHidden(callback: () => void): void {
    this.hiddenListeners.delete(callback);
  }
}