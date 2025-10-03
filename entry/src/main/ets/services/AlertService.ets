import { BusinessError } from '@ohos.base';
import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AlertService';
const DOMAIN = 0xFF00;

/**
 * 警报频率控制器 - 管理警报触发频率
 */
interface AlertCount {
  alertCount: number;
  lastAlertTime: number;
}

class AlertFrequencyController {
  private lastAlertTime: number = 0;
  private alertCount: number = 0;
  private readonly BASE_SILENT_PERIOD = 30000; // 30秒基础静默期
  private readonly PROGRESSIVE_INTERVALS = [30000, 60000, 120000, 300000]; // 渐进间隔

  /**
   * 检查是否可以触发警报
   */
  canTriggerAlert(): boolean {
    const now = Date.now();
    
    if (this.lastAlertTime === 0) {
      return true;
    }

    const elapsed = now - this.lastAlertTime;
    const currentInterval = this.getCurrentInterval();
    
    return elapsed >= currentInterval;
  }

  /**
   * 获取当前警报间隔
   */
  private getCurrentInterval(): number {
    const index = Math.min(this.alertCount, this.PROGRESSIVE_INTERVALS.length - 1);
    return this.PROGRESSIVE_INTERVALS[index];
  }

  /**
   * 记录警报触发
   */
  recordAlert(): void {
    this.lastAlertTime = Date.now();
    this.alertCount++;
  }

  /**
   * 重置警报状态
   */
  reset(): void {
    this.alertCount = 0;
  }

  /**
   * 获取警报状态信息
   */
  getStatus(): AlertCount {
    return {
      alertCount: this.alertCount,
      lastAlertTime: this.lastAlertTime
    };
  }
}

/**
 * 警报服务类 - 提供用户友好的多模态警报功能
 * 特点：使用notificationManager实现声音和振动，智能频率控制
 */
export class AlertService {
  private static instance: AlertService;
  private context: common.UIAbilityContext;
  private frequencyController: AlertFrequencyController;
  
  private constructor(context: common.UIAbilityContext) {
    this.context = context;
    this.frequencyController = new AlertFrequencyController();
    this.initializeNotificationSlot();
  }

  public static getInstance(context: common.UIAbilityContext): AlertService {
    if (!AlertService.instance) {
      AlertService.instance = new AlertService(context);
    }
    return AlertService.instance;
  }

  /**
   * 初始化通知渠道
   */
  private async initializeNotificationSlot(): Promise<void> {
    try {
      // 确保有服务提醒类型的通知渠道
      await notificationManager.addSlot(notificationManager.SlotType.SERVICE_INFORMATION);
      hilog.info(DOMAIN, TAG, '通知渠道初始化成功');
    } catch (error) {
      // 渠道可能已存在，忽略错误
      const err = error as BusinessError;
      if (err.code !== 1600012) { // 不是"已存在"错误
        hilog.warn(DOMAIN, TAG, `通知渠道初始化警告: ${err.code}, ${err.message}`);
      }
    }
  }

  /**
   * 触发多模态警报
   * @param currentDecibel 当前分贝值
   * @param threshold 阈值
   */
  public async triggerAlert(currentDecibel: number, threshold: number): Promise<void> {
    // 检查频率控制
    if (!this.frequencyController.canTriggerAlert()) {
      hilog.info(DOMAIN, TAG, '警报在静默期内，忽略触发');
      return;
    }

    try {
      // 发布通知
      await this.publishAlertNotification(currentDecibel, threshold);
      
      // 记录警报触发
      this.frequencyController.recordAlert();
      
      hilog.info(DOMAIN, TAG, `警报触发成功: ${currentDecibel}dB > ${threshold}dB, 警报次数: ${this.frequencyController.getStatus().alertCount}`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `触发警报失败: ${err.code}, ${err.message}`);
    }
  }

  /**
   * 发布静默系统通知（不包含声音和振动）
   */
  private async publishAlertNotification(
    currentDecibel: number,
    threshold: number
  ): Promise<void> {
    const notificationRequest: notificationManager.NotificationRequest = {
      id: 999998, // 使用固定ID避免重复
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: "噪音警报",
          text: `当前噪音 ${currentDecibel}dB 超过阈值 ${threshold}dB`,
          additionalText: "请采取适当防护措施"
        }
      },
      deliveryTime: new Date().getTime(),
    };

    await notificationManager.publish(notificationRequest);
    hilog.info(DOMAIN, TAG, '静默警报通知发布成功');
  }

  /**
   * 重置警报状态（当噪音恢复正常时调用）
   */
  public resetAlertState(): void {
    this.frequencyController.reset();
    hilog.info(DOMAIN, TAG, '警报状态已重置');
  }

  /**
   * 获取警报状态信息
   */
  public getAlertStatus(): AlertCount {
    return this.frequencyController.getStatus();
  }

  /**
   * 检查通知权限
   */
  public async checkNotificationPermission(): Promise<boolean> {
    try {
      const isEnabled = await notificationManager.isNotificationEnabled();
      hilog.info(DOMAIN, TAG, `通知权限状态: ${isEnabled}`);
      return isEnabled;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `检查通知权限失败: ${err.code}, ${err.message}`);
      return false;
    }
  }

  /**
   * 请求通知权限
   */
  public async requestNotificationPermission(): Promise<void> {
    try {
      await notificationManager.requestEnableNotification(this.context);
      hilog.info(DOMAIN, TAG, '通知权限请求成功');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `请求通知权限失败: ${err.code}, ${err.message}`);
    }
  }
}