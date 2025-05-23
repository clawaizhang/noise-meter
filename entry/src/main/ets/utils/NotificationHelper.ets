import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

const TAG = 'NotificationHelper';
const DOMAIN = 0xFF00;

export class NotificationHelper {
  private static instance: NotificationHelper;
  private context: common.UIAbilityContext;

  private constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  public static getInstance(context: common.UIAbilityContext): NotificationHelper {
    if (!NotificationHelper.instance) {
      NotificationHelper.instance = new NotificationHelper(context);
    }
    return NotificationHelper.instance;
  }

  public async checkAndRequestPermission(): Promise<boolean> {
    try {
      const isEnabled = await notificationManager.isNotificationEnabled();
      hilog.info(DOMAIN, TAG, `Notification enabled: ${isEnabled}`);
      
      if (!isEnabled) {
        await notificationManager.requestEnableNotification(this.context);
        hilog.info(DOMAIN, TAG, 'Notification permission granted');
        return true;
      }
      return true;
    } catch (err) {
      const error = err as BusinessError;
      if (error.code === 1600004) {
        hilog.error(DOMAIN, TAG, `Notification permission denied, code: ${error.code}`);
      } else {
        hilog.error(DOMAIN, TAG, `Notification permission error, code: ${error.code}, message: ${error.message}`);
      }
      return false;
    }
  }

  public async showNotification(id: number, title: string, text: string, additionalText: string = ''): Promise<void> {
    try {
      const notificationRequest: notificationManager.NotificationRequest = {
        id: id,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: text,
            additionalText: additionalText
          }
        }
      };

      notificationManager.publish(notificationRequest, (err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `Failed to publish notification. Code: ${err.code}, message: ${err.message}`);
          return;
        }
        hilog.info(DOMAIN, TAG, 'Notification published successfully');
      });
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, `Notification error: ${error.code}, ${error.message}`);
    }
  }
}