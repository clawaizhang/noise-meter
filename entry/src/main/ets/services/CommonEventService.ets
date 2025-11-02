/**
 * 通用公共事件服务
 * 负责管理公共事件的订阅和分发
 */

import commonEventManager from '@ohos.commonEventManager';

export class CommonEventService {
  private static instance: CommonEventService | null = null;
  private subscribers: Map<string, commonEventManager.CommonEventSubscriber> = new Map();
  private eventHandlers: Map<string, Function[]> = new Map();

  /**
   * 获取 CommonEventService 实例
   */
  public static getInstance(): CommonEventService {
    if (!CommonEventService.instance) {
      CommonEventService.instance = new CommonEventService();
    }
    return CommonEventService.instance;
  }

  /**
   * 订阅公共事件
   * @param event 事件名称
   * @param handler 事件处理函数
   */
  public async subscribeEvent(event: string, handler: Function): Promise<void> {
    if (!canIUse('SystemCapability.Notification.CommonEvent')) {
      console.warn(`[公共事件] 系统不支持公共事件: ${event}`);
      return;
    }

    // 添加事件处理器
    if (!this.eventHandlers.has(event)) {
      this.eventHandlers.set(event, []);
    }
    this.eventHandlers.get(event)!.push(handler);

    // 如果还没有订阅者，创建订阅者
    if (!this.subscribers.has(event)) {
      await this.createSubscriber(event);
    }

    console.info(`[公共事件] 已订阅事件: ${event}`);
  }

  /**
   * 取消订阅公共事件
   * @param event 事件名称
   * @param handler 事件处理函数
   */
  public unsubscribeEvent(event: string, handler: Function): void {
    const handlers = this.eventHandlers.get(event);
    if (handlers) {
      const index = handlers.indexOf(handler);
      if (index > -1) {
        handlers.splice(index, 1);
      }
      
      // 如果没有处理器了，取消订阅
      if (handlers.length === 0) {
        this.removeSubscriber(event);
        this.eventHandlers.delete(event);
      }
    }

    console.info(`[公共事件] 已取消订阅事件: ${event}`);
  }

  /**
   * 创建公共事件订阅者
   * @param event 事件名称
   */
  private async createSubscriber(event: string): Promise<void> {
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [event]
    };

    try {
      const subscriber = await commonEventManager.createSubscriber(subscribeInfo);
      this.subscribers.set(event, subscriber);

      // 订阅事件
      commonEventManager.subscribe(subscriber, (err, data) => {
        if (err) {
          console.error(`[公共事件] 订阅事件失败: ${event}`, err);
          return;
        }

        // 调用所有注册的处理器
        const handlers = this.eventHandlers.get(event);
        if (handlers) {
          handlers.forEach(handler => {
            try {
              handler(data);
            } catch (error) {
              console.error(`[公共事件] 事件处理器执行失败: ${event}`, error);
            }
          });
        }
      });

      console.info(`[公共事件] 成功创建订阅者: ${event}`);
    } catch (error) {
      console.error(`[公共事件] 创建订阅者失败: ${event}`, error);
    }
  }

  /**
   * 移除公共事件订阅者
   * @param event 事件名称
   */
  private removeSubscriber(event: string): void {
    const subscriber = this.subscribers.get(event);
    if (subscriber) {
      try {
        commonEventManager.unsubscribe(subscriber);
        this.subscribers.delete(event);
        console.info(`[公共事件] 成功移除订阅者: ${event}`);
      } catch (error) {
        console.error(`[公共事件] 移除订阅者失败: ${event}`, error);
      }
    }
  }

  /**
   * 清理所有订阅
   */
  public destroy(): void {
    for (const event of this.subscribers.keys()) {
      this.removeSubscriber(event);
    }
    this.eventHandlers.clear();
    console.info('[公共事件] 所有订阅已清理');
  }
}