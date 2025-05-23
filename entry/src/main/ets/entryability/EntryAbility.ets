import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { AbilityConstant, Want, common } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import wantAgent from '@ohos.app.ability.wantAgent';
import { WindowManager } from '../utils/WindowManager';
import { PreferenceService, PreferenceValue } from '../../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';
import { DisplayManager } from '../utils/DisplayManager';
import { NotificationHelper } from '../utils/NotificationHelper';

const TAG = 'EntryAbility';
const DOMAIN = 0x0000;
const NOTIFICATION_ID = 1;
export default class EntryAbility extends UIAbility {
  private keepScreenOn: boolean = false;
  private backgroundRunningEnabled: boolean = false;
  private backgroundRunningRequested: boolean = false;

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');

    // 请求通知权限
    const notificationHelper = NotificationHelper.getInstance(this.context);
    await notificationHelper.checkAndRequestPermission();

    // 初始化首选项默认值
    const preferenceService = PreferenceService.getInstance();
    preferenceService.init(this.context);
    // 获取初始值
    this.keepScreenOn = preferenceService.getBoolean(PreferenceKeyConstants.KEEP_SCREEN_ON, false);
    this.backgroundRunningEnabled = preferenceService.getBoolean(PreferenceKeyConstants.BACKGROUND_RUNNING, false);

    // 注册监听器
    preferenceService.addChangeListener(PreferenceKeyConstants.KEEP_SCREEN_ON,
      (key: string, newValue: PreferenceValue) => {
        this.keepScreenOn = newValue as boolean;
        const windowManager = WindowManager.getInstance();
        windowManager.setKeepScreenOn(this.keepScreenOn);
      });

    preferenceService.addChangeListener(PreferenceKeyConstants.BACKGROUND_RUNNING,
      (key: string, newValue: PreferenceValue) => {
        this.backgroundRunningEnabled = newValue as boolean;
      });
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');
    // 注册窗口并加载内容
    const windowManager = WindowManager.getInstance();
    windowManager.registerWindowStage(windowStage);
    windowManager.loadContent('pages/Index');
    windowManager.setKeepScreenOn(this.keepScreenOn);
    windowStage.getMainWindowSync().setPreferredOrientation(window.Orientation.PORTRAIT);
  }

  onWindowStageDestroy(): void {
    const windowManager = WindowManager.getInstance();
    windowManager.setKeepScreenOn(this.keepScreenOn);
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    const windowManager = WindowManager.getInstance();
    windowManager.setKeepScreenOn(this.keepScreenOn);
    DisplayManager.getInstance().onForeground();
    if (this.backgroundRunningRequested) {
      this.stopBackgroundRunning();
    }
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    const windowManager = WindowManager.getInstance();
    windowManager.setKeepScreenOn(this.keepScreenOn);
    DisplayManager.getInstance().onBackground();

    if (this.backgroundRunningEnabled) {
      this.startBackgroundRunning();
    }

    // 发布后台通知
    const notificationHelper = NotificationHelper.getInstance(this.context);
    notificationHelper.showNotification(
      NOTIFICATION_ID,
      '噪音监测中',
      '应用已转入后台持续监测环境噪音',
      '点击返回应用查看实时数据'
    );

    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }

  private startBackgroundRunning(): void {
    // 创建WantAgent参数
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: this.context.applicationInfo.name,
          abilityName: 'EntryAbility'
        }
      ],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };

    try {
      wantAgent.getWantAgent(wantAgentInfo, (err, agent) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `Get wantAgent failed, error: ${JSON.stringify(err)}`);
          return;
        }
        backgroundTaskManager.startBackgroundRunning(this.context,
          backgroundTaskManager.BackgroundMode.AUDIO_RECORDING,
          agent,
          (err) => {
            if (err) {
              hilog.error(DOMAIN, TAG, `Start background running failed, error: ${JSON.stringify(err)}`);
              return;
            }
            this.backgroundRunningRequested = true;
            hilog.info(DOMAIN, TAG, 'Start background running successfully');
          });
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Start background running failed, error: ${JSON.stringify(err)}`);
    }
  }

  private stopBackgroundRunning(): void {
    try {
      backgroundTaskManager.stopBackgroundRunning(this.context, (err) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `Stop background running failed, error: ${JSON.stringify(err)}`);
          return;
        }
        this.backgroundRunningRequested = false;
        hilog.info(DOMAIN, TAG, 'Stop background running successfully');
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Stop background running failed, error: ${JSON.stringify(err)}`);
    }
  }
}
