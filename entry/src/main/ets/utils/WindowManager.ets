import window from '@ohos.window';
import { BusinessError } from '@kit.BasicServicesKit';
import hilog from '@ohos.hilog';
import { DialogHub } from '@hadss/dialoghub';

const TAG = 'WindowManager';
const DOMAIN = 0x0000;

export class WindowManager {
  private static instance: WindowManager;
  private windowStage: window.WindowStage | null = null;

  private constructor() {
  }

  // 获取单例实例
  public static getInstance(): WindowManager {
    if (!WindowManager.instance) {
      WindowManager.instance = new WindowManager();
    }
    return WindowManager.instance;
  }

  // 注册窗口stage
  public registerWindowStage(windowStage: window.WindowStage): void {
    this.windowStage = windowStage;
    hilog.info(DOMAIN, TAG, 'WindowStage registered');
  }

  // 加载页面内容
  public loadContent(pagePath: string, then: () => void): void {
    if (!this.windowStage) {
      hilog.error(DOMAIN, TAG, 'WindowStage is null');
      return;
    }

    this.windowStage.loadContent(pagePath, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      this.windowStage?.getMainWindow().then(windowObj => {
        DialogHub.init(windowObj.getUIContext());
      })
      then();
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
    });
  }

  // 设置屏幕常亮状态
  public setKeepScreenOn(keepOn: boolean): void {
    if (!this.windowStage) {
      hilog.error(DOMAIN, TAG, 'WindowStage is null');
      return;
    }

    this.windowStage.getMainWindow((err, windowClass) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to obtain the main window. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }

      try {
        let promise = windowClass.setWindowKeepScreenOn(keepOn);
        promise.then(() => {
          hilog.info(DOMAIN, TAG, `Succeeded in setting window keep screen on: ${keepOn}`);
        }).catch((err: BusinessError) => {
          hilog.error(DOMAIN, TAG, 'Failed to set window keep screen on. Cause: %{public}s', JSON.stringify(err) ?? '');
        });
      } catch (exception) {
        hilog.error(DOMAIN, TAG, 'Failed to set window keep screen on. Cause: %{public}s',
          JSON.stringify(exception) ?? '');
      }
    });
  }
}
