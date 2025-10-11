import { BusinessError } from '@ohos.base';
import { notificationManager } from '@kit.NotificationKit';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppKeys } from '../models/AppKeys';
import { PreferenceKeys } from '../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';

const TAG = 'AlertService';
const DOMAIN = 0xFF00;

/**
 * 通知频率控制器 - 管理通知发送频率
 */
interface NotificationFrequencyStatus {
  notificationCount: number;
  lastNotificationTime: number;
}

class AlertFrequencyController {
  private lastNotificationTime: number = 0;
  private notificationCount: number = 0;
  private readonly BASE_SILENT_PERIOD = 30000; // 30秒基础静默期
  private readonly PROGRESSIVE_INTERVALS = [30000, 60000, 120000, 300000]; // 渐进间隔

  /**
   * 检查是否可以发送通知
   */
  canSendNotification(): boolean {
    const now = Date.now();
    
    if (this.lastNotificationTime === 0) {
      return true;
    }

    const elapsed = now - this.lastNotificationTime;
    const currentInterval = this.getCurrentInterval();
    
    return elapsed >= currentInterval;
  }

  /**
   * 获取当前通知间隔
   */
  private getCurrentInterval(): number {
    const index = Math.min(this.notificationCount, this.PROGRESSIVE_INTERVALS.length - 1);
    return this.PROGRESSIVE_INTERVALS[index];
  }

  /**
   * 记录通知发送
   */
  recordNotificationSent(): void {
    this.lastNotificationTime = Date.now();
    this.notificationCount++;
  }

  /**
   * 重置通知状态
   */
  reset(): void {
    this.notificationCount = 0;
  }

  /**
   * 获取通知状态信息
   */
  getStatus(): NotificationFrequencyStatus {
    return {
      notificationCount: this.notificationCount,
      lastNotificationTime: this.lastNotificationTime
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
  private pk: PreferenceKeys;
  
  private constructor(context: common.UIAbilityContext, pk: PreferenceKeys) {
    this.context = context;
    this.pk = pk;
    this.frequencyController = new AlertFrequencyController();
    this.initializeNotificationSlot();
  }

  public static getInstance(context: common.UIAbilityContext,pk: PreferenceKeys): AlertService {
    if (!AlertService.instance) {
      AlertService.instance = new AlertService(context,pk);
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
    try {
      // 1. 总是更新 DataProcessingState 中的警报状态（没有频率限制）
      const appKeys: AppKeys = AppStorageV2.connect(AppKeys)!;
      appKeys.dataProcessingState.alertState.triggerAlert();
      
      // 2. 检查是否启用通知
      if (!this.pk.system_notification_enabled) {
        hilog.info(DOMAIN, TAG, `警报触发但通知已关闭: ${currentDecibel}dB > ${threshold}dB`);
        return;
      }
      
      // 3. 检查是否可以发送通知（有频率限制）
      if (this.frequencyController.canSendNotification()) {
        // 发布通知
        await this.publishAlertNotification(currentDecibel, threshold);
        
        // 记录通知发送
        this.frequencyController.recordNotificationSent();
        
        hilog.info(DOMAIN, TAG, `警报触发成功并发送通知: ${currentDecibel}dB > ${threshold}dB`);
      } else {
        hilog.info(DOMAIN, TAG, `警报触发但通知在静默期内: ${currentDecibel}dB > ${threshold}dB`);
      }
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
    // 更新 DataProcessingState 中的警报状态
    const appKeys: AppKeys = AppStorageV2.connect(AppKeys)!;
    appKeys.dataProcessingState.alertState.clearAlert();
    
    this.frequencyController.reset();
    hilog.info(DOMAIN, TAG, '警报状态已重置');
  }

  /**
   * 获取通知频率状态信息
   */
  public getAlertStatus(): NotificationFrequencyStatus {
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
   * 更新系统通知权限状态
   */
  public async updateSystemPermissionStatus(): Promise<void> {
    try {
      const isEnabled = await this.checkNotificationPermission();
      const appKeys: AppKeys = AppStorageV2.connect(AppKeys)!;
      appKeys.systemNotificationPermissionGranted = isEnabled;
      hilog.info(DOMAIN, TAG, `系统通知权限状态已更新: ${isEnabled}`);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `更新系统通知权限状态失败: ${err.code}, ${err.message}`);
    }
  }

  /**
   * 请求通知权限
   */
  public async requestNotificationPermission(): Promise<void> {
    try {
      // 记录权限申请状态
      this.pk.notification_permission_requested = true;
      
      await notificationManager.requestEnableNotification(this.context);
      hilog.info(DOMAIN, TAG, '通知权限请求成功');
      // 权限请求后更新状态
      await this.updateSystemPermissionStatus();
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `请求通知权限失败: ${err.code}, ${err.message}`);
      // 即使请求失败也更新状态
      await this.updateSystemPermissionStatus();
    }
  }

  /**
   * 跳转到系统通知设置页面
   */
  public async openSystemNotificationSettings(): Promise<void> {
    try {
      // 如果已经申请过权限，直接跳转到系统设置
      if (this.pk.notification_permission_requested) {
        if (canIUse('SystemCapability.Notification.NotificationSettings')) {
          notificationManager.openNotificationSettings(this.context)
        }
        hilog.info(DOMAIN, TAG, '跳转到系统通知设置页面');
      } else {
        // 首次申请，使用requestEnableNotification
        hilog.info(DOMAIN, TAG, '首次申请通知权限');
        await this.requestNotificationPermission();
      }
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `跳转到系统通知设置失败: ${err.code}, ${err.message}`);
      // 如果跳转失败，尝试请求权限
      await this.requestNotificationPermission();
    }
  }
}