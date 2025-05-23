import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common, WantAgent, wantAgent } from '@kit.AbilityKit';

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
      // 创建WantAgent用于点击通知返回应用
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [{
          bundleName: this.context.applicationInfo.name,
          abilityName: 'EntryAbility'
        }],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      };

      const agent = await new Promise<WantAgent>((resolve, reject) => {
        wantAgent.getWantAgent(wantAgentInfo, (err, agent) => {
          if (err) {
            reject(err);
          } else {
            resolve(agent);
          }
        });
      });

      const notificationRequest: notificationManager.NotificationRequest = {
        id: id,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: title,
            text: text,
            additionalText: additionalText
          }
        },
        wantAgent: agent
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

  public cancelNotification(id: number): void {
    try {
      notificationManager.cancel(id, (err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `Failed to cancel notification. Code: ${err.code}, message: ${err.message}`);
          return;
        }
        hilog.info(DOMAIN, TAG, `Notification ${id} cancelled successfully`);
      });
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(DOMAIN, TAG, `Cancel notification error: ${error.code}, ${error.message}`);
    }
  }
}