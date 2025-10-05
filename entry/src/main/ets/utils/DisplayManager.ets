import display from '@ohos.display';

export class DisplayManager {
  private static instance: DisplayManager;
  private displayListeners: Set<() => void> = new Set();
  private hiddenListeners: Set<() => void> = new Set();

  private constructor() {
  }

  // 获取单例实例
  public static getInstance(): DisplayManager {
    if (!DisplayManager.instance) {
      DisplayManager.instance = new DisplayManager();
      DisplayManager.instance.initDisplayListener();
    }
    return DisplayManager.instance;
  }

  // 初始化屏幕状态监听
  private initDisplayListener(): void {
    display.on('change', (state: display.DisplayState) => {
      if (state === display.DisplayState.STATE_ON) {
        this.displayListeners.forEach(callback => callback());
      } else {
        this.hiddenListeners.forEach(callback => callback());
      }
    });
  }

  public onForeground(): void {
    this.displayListeners.forEach(callback => callback());
  }

  public onBackground(): void {
    this.hiddenListeners.forEach(callback => callback());
  }

  // 注册屏幕显示回调
  public onDisplay(callback: () => void): void {
    this.displayListeners.add(callback);
  }

  // 取消注册屏幕显示回调
  public offDisplay(callback: () => void): void {
    this.displayListeners.delete(callback);
  }

  // 注册屏幕隐藏回调
  public onHidden(callback: () => void): void {
    this.hiddenListeners.add(callback);
  }

  // 取消注册屏幕隐藏回调
  public offHidden(callback: () => void): void {
    this.hiddenListeners.delete(callback);
  }
}