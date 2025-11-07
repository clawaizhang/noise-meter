import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { AbilityConstant, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import hilog from '@ohos.hilog';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import wantAgent from '@ohos.app.ability.wantAgent';
import { WindowManager } from '../utils/WindowManager';
import { DisplayManager } from '../utils/DisplayManager';
import { NotificationHelper } from '../utils/NotificationHelper';
import { PreferenceKeys } from '../models/PreferenceKeys';
import { AppKeys } from '../models/AppKeys';
import { AppUtil, PermissionUtil } from '@pura/harmony-utils';
import { camera } from '@kit.CameraKit';
import { AppStorageV2, display, PersistenceV2 } from '@kit.ArkUI';
import { WindowFunctionCache } from '../utils/WindowFunctionCache';
import { DataProcessingState } from '../models/DataProcessingState';
import { UIDisplayState } from '../models/UIDisplayState';
import { of } from 'rxjs';
import { AudioControllerService } from '../services/AudioControllerService';

const TAG = 'EntryAbility';
const DOMAIN = 0x0000;
const NOTIFICATION_ID = 1;

export default class EntryAbility extends UIAbility {
  private backgroundRunningRequested: boolean = false;
  private cameraManager: camera.CameraManager = camera.getCameraManager(getContext(this));
  private mainWindow: window.Window | undefined = undefined;

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');
    // 初始化FFT优化 - 预缓存窗函数
    of().subscribe(() => {
      WindowFunctionCache.initialize()
    })
  }

  async onDestroy(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');

    // 销毁DisplayManager资源
    const displayManager = DisplayManager.getInstance();
    await displayManager.destroy();

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
    windowManager.loadContent('pages/Index', (windowStageRegistered) => {
      AppUtil.init(this.context);
      PersistenceV2.connect(PreferenceKeys, () => new PreferenceKeys());
      AppStorageV2.connect(AppKeys, () => new AppKeys())!;
      AppStorageV2.connect(DataProcessingState, () => new DataProcessingState())!;
      AppStorageV2.connect(UIDisplayState, () => new UIDisplayState())!;
      PersistenceV2.notifyOnError((key: string, reason: string, msg: string) => {
        console.error(`error key: ${key}, reason: ${reason}, message: ${msg}`);
      });
      // 获取设备类型并设置窗口方向
      windowStageRegistered?.getMainWindow((err: BusinessError, windowClass) => {
        if (err.code || !windowClass) {
          hilog.error(DOMAIN, TAG,
            `Failed to obtain the main window. Cause code: ${err.code}, message: ${err.message}`);
          return;
        }
        this.mainWindow = windowClass;
        // 初始化窗口尺寸和断点信息
        this.updateWindowBreakpointInfo();

        // 监听窗口尺寸变化
        this.setupWindowSizeChangeListener();
        // 使用系统提供的断点计算方法
        const uiContext = this.mainWindow.getUIContext();
        const widthBp = uiContext.getWindowWidthBreakpoint();
        // 获取设备类型
        let orientation = window.Orientation.AUTO_ROTATION;
        windowClass.getWindowProperties().windowRect
        // 判断设备类型来设置窗口显示方向
        if (widthBp <= WidthBreakpoint.WIDTH_SM) {
          // 小屏强制竖屏
          orientation = window.Orientation.PORTRAIT;
        }
        try {
          windowClass.setPreferredOrientation(orientation, (err: BusinessError) => {
            const errCode: number = err.code;
            if (errCode) {
              hilog.error(DOMAIN, TAG,
                `Failed to set window orientation. Cause code: ${err.code}, message: ${err.message}`);
              return;
            }
            hilog.info(DOMAIN, TAG, 'Succeeded in setting window orientation.');
          });
        } catch (exception) {
          hilog.error(DOMAIN, TAG,
            `Failed to set window orientation. Cause code: ${exception.code}, message: ${exception.message}`);
        }
      });
    });


  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');

  }

  onForeground(): void {
    DisplayManager.getInstance().onForeground();
    if (this.backgroundRunningRequested) {
      // 取消后台通知
      const notificationHelper = NotificationHelper.getInstance(this.context);
      notificationHelper.cancelNotification(NOTIFICATION_ID);
      // this.stopBackgroundRunning();
    }

    // 双管线架构：恢复UI更新
    // AudioControllerService.getInstancePlain()?.resumeUIUpdates();

    // 恢复录音（如果之前正在录音）
    this.resumeRecording();

    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    DisplayManager.getInstance().onBackground();

    // 双管线架构：暂停UI更新
    // AudioControllerService.getInstancePlain()?.pauseUIUpdates();

    // 暂停录音（如果正在录音）
    this.pauseRecording();

    // this.startBackgroundRunning();

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
        if (PersistenceV2.connect(PreferenceKeys)!.background_running) {
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
        }
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

  /**
   * 暂停录音
   */
  private async pauseRecording(): Promise<void> {
    try {
      const audioControllerService = AudioControllerService.getInstancePlain();
      if (audioControllerService && audioControllerService.isRecording()) {
        hilog.info(DOMAIN, TAG, '应用进入后台，暂停录音');
        await audioControllerService.pauseRecordingFromExternal();
        hilog.info(DOMAIN, TAG, '录音已暂停');
      } else {
        hilog.info(DOMAIN, TAG, '当前未在录音，无需暂停');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `暂停录音失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 恢复录音
   */
  private async resumeRecording(): Promise<void> {
    try {
      const audioControllerService = AudioControllerService.getInstancePlain();
      if (audioControllerService && audioControllerService.isPaused()) {
        hilog.info(DOMAIN, TAG, '应用回到前台，恢复录音');
        await audioControllerService.resumeRecordingFromExternal();
        hilog.info(DOMAIN, TAG, '录音已恢复');
      } else {
        hilog.info(DOMAIN, TAG, '当前未处于暂停状态，无需恢复');
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `恢复录音失败: ${JSON.stringify(error)}`);
    }
  }

  // 设置窗口尺寸变化监听
  private setupWindowSizeChangeListener(): void {
    if (!this.mainWindow) {
      hilog.error(DOMAIN, TAG, 'Main window is not available for size change listener');
      return;
    }

    this.mainWindow.on('windowSizeChange', (windowSize: window.Size) => {
      hilog.info(DOMAIN, TAG, `Window size changed: ${windowSize.width}x${windowSize.height}`);
      this.updateWindowBreakpointInfo();
    });
    display.on('change', (displayId: number) => {
      hilog.info(DOMAIN, TAG, `Display changed: ${displayId}`)
      this.updateWindowBreakpointInfo();
    })
  }

  // 更新窗口断点信息
  private updateWindowBreakpointInfo(): void {
    if (!this.mainWindow) {
      return;
    }

    try {
      // 获取窗口尺寸
      const windowSize = this.mainWindow.getWindowProperties();
      const widthVp = px2vp(windowSize.windowRect.width);
      const heightVp = px2vp(windowSize.windowRect.height);

      // 使用系统提供的断点计算方法
      const uiContext = this.mainWindow.getUIContext();
      const widthBp = uiContext.getWindowWidthBreakpoint();
      const heightBp = uiContext.getWindowHeightBreakpoint();
      const isLandscape = widthVp > heightVp;

      // 更新到 AppStorage
      let appKeys = AppStorageV2.connect(AppKeys)!;
      appKeys.windowWidthBreakpoint = widthBp;
      appKeys.windowHeightBreakpoint = heightBp;
      appKeys.windowWidth = widthVp;
      appKeys.windowHeight = heightVp;
      appKeys.isLandscape = isLandscape;

      hilog.info(DOMAIN, TAG,
        `Window breakpoints updated - Width: ${widthBp}(${widthVp}vp), Height: ${heightBp}(${heightVp}vp), Landscape: ${isLandscape}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to update window breakpoint info: ${error}`);
    }
  }
}
