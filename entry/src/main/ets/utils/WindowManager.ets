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
  public loadContent(pagePath: string, then: (windowStage:window.WindowStage | null) => void): void {
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
      then(this.windowStage);
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
    });
  }

}
