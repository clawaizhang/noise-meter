import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { AbilityConstant, Want, common } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import wantAgent from '@ohos.app.ability.wantAgent';
import { WindowManager } from '../utils/WindowManager';
import { DisplayManager } from '../utils/DisplayManager';
import { NotificationHelper } from '../utils/NotificationHelper';
import { PreferenceService, PreferenceValue } from '../services/PreferenceService';
import { PreferenceKeyConstants } from '../constants/PreferenceKeyConstants';
import audio from '@ohos.multimedia.audio';

const TAG = 'EntryAbility';
const DOMAIN = 0x0000;
const NOTIFICATION_ID = 1;
export default class EntryAbility extends UIAbility {
  private keepScreenOn: boolean = false;
  private backgroundRunningEnabled: boolean = false;
  private meterOn: boolean = false;
  private backgroundRunningRequested: boolean = false;

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');

    // 初始化首选项默认值
    const preferenceService = PreferenceService.getInstance();
    preferenceService.init(this.context);
    // 获取初始值
    this.keepScreenOn = preferenceService.getBoolean(PreferenceKeyConstants.KEEP_SCREEN_ON, false);
    this.backgroundRunningEnabled = preferenceService.getBoolean(PreferenceKeyConstants.BACKGROUND_RUNNING, false);
    this.meterOn = preferenceService.getBoolean(PreferenceKeyConstants.METER_ON, false);

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

    preferenceService.addChangeListener(PreferenceKeyConstants.PRIVACY_AGREED,
      (key: string, newValue: PreferenceValue) => {
        if (newValue) {
          // 请求通知权限
          const notificationHelper = NotificationHelper.getInstance(this.context);
          notificationHelper.checkAndRequestPermission();
        }
      });
    preferenceService.addChangeListener(PreferenceKeyConstants.METER_ON,
      (key: string, newValue: PreferenceValue) => {
        this.meterOn = newValue as boolean;
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
    // audio.getAudioManager().getVolumeManager().getAppVolumePercentage().then((volume) => {
    //   PreferenceService.getInstance().setNumber(PreferenceKeyConstants.VOLUME, volume);
    // });
    // audio.getAudioManager().getVolumeManager().on('volumeChange', (volume) => {
    //   if (volume.volumeType === audio.AudioVolumeType.MEDIA && volume.volume < 100) {
    //     PreferenceService.getInstance().setNumber(PreferenceKeyConstants.VOLUME, volume.volume);
    //   }
    // });
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
      // 取消后台通知
      const notificationHelper = NotificationHelper.getInstance(this.context);
      notificationHelper.cancelNotification(NOTIFICATION_ID);
      this.stopBackgroundRunning();
    }

    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    const windowManager = WindowManager.getInstance();
    windowManager.setKeepScreenOn(this.keepScreenOn);
    DisplayManager.getInstance().onBackground();

    if (this.backgroundRunningEnabled && this.meterOn) {
      this.startBackgroundRunning();
    }

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
            // 发布后台通知
            const notificationHelper = NotificationHelper.getInstance(this.context);
            notificationHelper.showNotification(
              NOTIFICATION_ID,
              '噪音监测中',
              '应用已转入后台持续监测环境噪音',
              '点击返回应用查看实时数据'
            );
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
