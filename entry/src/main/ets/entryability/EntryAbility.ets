import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { AbilityConstant, Want, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import hilog from '@ohos.hilog';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import wantAgent from '@ohos.app.ability.wantAgent';
import { WindowManager } from '../utils/WindowManager';
import { DisplayManager } from '../utils/DisplayManager';
import { NotificationHelper } from '../utils/NotificationHelper';
import { PreferenceService, PreferenceValue } from '../services/PreferenceService';
import { PreferenceKeyConstants } from '../constants/PreferenceKeyConstants';
import audio from '@ohos.multimedia.audio';
import { PermissionUtil } from '@pura/harmony-utils';
import { camera } from '@kit.CameraKit';

const TAG = 'EntryAbility';
const DOMAIN = 0x0000;
const NOTIFICATION_ID = 1;
export default class EntryAbility extends UIAbility {
  private keepScreenOn: boolean = false;
  private backgroundRunningEnabled: boolean = false;
  private meterOn: boolean = false;
  private backgroundRunningRequested: boolean = false;
  private  cameraManager: camera.CameraManager = camera.getCameraManager(getContext(this));


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
    PermissionUtil.checkPermissions('ohos.permission.CAMERA').then((result) => {
      if (result) {
        if (this.cameraManager.isTorchSupported()) {
          this.cameraManager.setTorchMode(camera.TorchMode.OFF);
        }
      }
    })
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');
    // 注册窗口并加载内容
    const windowManager = WindowManager.getInstance();
    windowManager.registerWindowStage(windowStage);
    windowManager.loadContent('pages/Index');
    windowManager.setKeepScreenOn(this.keepScreenOn);
    
    // 获取设备类型并设置窗口方向
    let windowClass: window.Window | undefined = undefined;
    windowStage.getMainWindow((err: BusinessError, data) => {
      const errCode: number = err.code;
      if (errCode) {
        hilog.error(DOMAIN, TAG, `Failed to obtain the main window. Cause code: ${err.code}, message: ${err.message}`);
        return;
      }
      windowClass = data;
      // 获取设备类型
      let deviceTypeInfo: string = deviceInfo.deviceType;
      hilog.info(DOMAIN, TAG, `the value of the deviceType is:${deviceTypeInfo}`);
      let orientation = window.Orientation.AUTO_ROTATION;
      // 判断设备是手机or平板，来设置窗口显示方向
      // if (deviceTypeInfo == 'phone') {
      //   orientation = window.Orientation.PORTRAIT;
      // } else if (deviceTypeInfo == 'tablet') {
      //   orientation = window.Orientation.LANDSCAPE;
      // }
      try {
        windowClass.setPreferredOrientation(orientation, (err: BusinessError) => {
          const errCode: number = err.code;
          if (errCode) {
            hilog.error(DOMAIN, TAG, `Failed to set window orientation. Cause code: ${err.code}, message: ${err.message}`);
            return;
          }
          hilog.info(DOMAIN, TAG, 'Succeeded in setting window orientation.');
        });
      } catch (exception) {
        hilog.error(DOMAIN, TAG, `Failed to set window orientation. Cause code: ${exception.code}, message: ${exception.message}`);
      }
    });

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
