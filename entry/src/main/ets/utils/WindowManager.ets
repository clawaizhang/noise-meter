import window from '@ohos.window';
import { BusinessError } from '@kit.BasicServicesKit';
import hilog from '@ohos.hilog';
import { DialogHub } from '@hadss/dialoghub';

const TAG = 'WindowManager';
const DOMAIN = 0x0000;

export class WindowManager {
  private static instance: WindowManager;
  private windowStage: window.WindowStage | null = null;
  private mainWindow: window.Window | null = null;

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
        this.mainWindow = windowObj;
        DialogHub.init(windowObj.getUIContext());
      })
      then(this.windowStage);
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
    });
  }

  /**
   * 获取主窗口对象
   */
  public async getMainWindow(): Promise<window.Window | null> {
    if (this.mainWindow) {
      return this.mainWindow;
    }
    
    if (!this.windowStage) {
      hilog.error(DOMAIN, TAG, 'WindowStage is null');
      return null;
    }
    
    try {
      this.mainWindow = await this.windowStage.getMainWindow();
      return this.mainWindow;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to get main window: ${error}`);
      return null;
    }
  }

  /**
   * 设置窗口方向
   * @param orientation 窗口方向
   * @returns 是否设置成功
   */
  public async setOrientation(orientation: window.Orientation): Promise<boolean> {
    const mainWindow = await this.getMainWindow();
    if (!mainWindow) {
      hilog.error(DOMAIN, TAG, 'Main window is null');
      return false;
    }

    return new Promise<boolean>((resolve) => {
      mainWindow.setPreferredOrientation(orientation, (err: BusinessError) => {
        if (err.code) {
          hilog.error(DOMAIN, TAG,
            `Failed to set orientation. Code: ${err.code}, message: ${err.message}`);
          resolve(false);
        } else {
          hilog.info(DOMAIN, TAG, `Orientation set to: ${orientation}`);
          resolve(true);
        }
      });
    });
  }

  /**
   * 获取当前窗口方向
   * @returns 当前窗口方向
   */
  public async getCurrentOrientation(): Promise<window.Orientation> {
    const mainWindow = await this.getMainWindow();
    if (!mainWindow) {
      hilog.error(DOMAIN, TAG, 'Main window is null');
      return window.Orientation.UNSPECIFIED;
    }

    try {
      return mainWindow.getPreferredOrientation();
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to get current orientation: ${error}`);
      return window.Orientation.UNSPECIFIED;
    }
  }
}
