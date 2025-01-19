import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { AbilityConstant, Want } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'EntryAbility';
const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private windowStage: window.WindowStage | null = null;
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');
    this.windowStage = windowStage;
    // 加载页面内容
    this.windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
    });

    // 设置屏幕常亮
    let windowClass: window.Window | undefined = undefined;
    this.windowStage.getMainWindow((err, data) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to obtain the main window. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      windowClass = data;
      try {
        let promise = windowClass.setWindowKeepScreenOn(true);
        promise.then(() => {
          hilog.info(DOMAIN, TAG, 'Succeeded in setting window keep screen on.');
        }).catch((err: BusinessError) => {
          hilog.error(DOMAIN, TAG, 'Failed to set window keep screen on. Cause: %{public}s', JSON.stringify(err) ?? '');
        });
      } catch (exception) {
        hilog.error(DOMAIN, TAG, 'Failed to set window keep screen on. Cause: %{public}s',
          JSON.stringify(exception) ?? '');
      }
    });
  }

  onWindowStageDestroy(): void {
    // 设置屏幕常亮
    if(this.windowStage) {
      let windowClass: window.Window | undefined = undefined;
      this.windowStage.getMainWindow((err, data) => {
        if (err.code) {
          hilog.error(DOMAIN, TAG, 'Failed to obtain the main window. Cause: %{public}s', JSON.stringify(err) ?? '');
          return;
        }
        windowClass = data;
        try {
          let promise = windowClass.setWindowKeepScreenOn(false);
          promise.then(() => {
            hilog.info(DOMAIN, TAG, 'Succeeded in setting window keep screen on.');
          }).catch((err: BusinessError) => {
            hilog.error(DOMAIN, TAG, 'Failed to set window keep screen on. Cause: %{public}s', JSON.stringify(err) ?? '');
          });
        } catch (exception) {
          hilog.error(DOMAIN, TAG, 'Failed to set window keep screen on. Cause: %{public}s',
            JSON.stringify(exception) ?? '');
        }
      });
    }
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // 设置屏幕常亮
    if(this.windowStage) {
      let windowClass: window.Window | undefined = undefined;
      this.windowStage.getMainWindow((err, data) => {
        if (err.code) {
          hilog.error(DOMAIN, TAG, 'Failed to obtain the main window. Cause: %{public}s', JSON.stringify(err) ?? '');
          return;
        }
        windowClass = data;
        try {
          let promise = windowClass.setWindowKeepScreenOn(true);
          promise.then(() => {
            hilog.info(DOMAIN, TAG, 'Succeeded in setting window keep screen on.');
          }).catch((err: BusinessError) => {
            hilog.error(DOMAIN, TAG, 'Failed to set window keep screen on. Cause: %{public}s', JSON.stringify(err) ?? '');
          });
        } catch (exception) {
          hilog.error(DOMAIN, TAG, 'Failed to set window keep screen on. Cause: %{public}s',
            JSON.stringify(exception) ?? '');
        }
      });
    }
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    // 设置屏幕常亮
    if(this.windowStage) {
      let windowClass: window.Window | undefined = undefined;
      this.windowStage.getMainWindow((err, data) => {
        if (err.code) {
          hilog.error(DOMAIN, TAG, 'Failed to obtain the main window. Cause: %{public}s', JSON.stringify(err) ?? '');
          return;
        }
        windowClass = data;
        try {
          let promise = windowClass.setWindowKeepScreenOn(false);
          promise.then(() => {
            hilog.info(DOMAIN, TAG, 'Succeeded in setting window keep screen on.');
          }).catch((err: BusinessError) => {
            hilog.error(DOMAIN, TAG, 'Failed to set window keep screen on. Cause: %{public}s', JSON.stringify(err) ?? '');
          });
        } catch (exception) {
          hilog.error(DOMAIN, TAG, 'Failed to set window keep screen on. Cause: %{public}s',
            JSON.stringify(exception) ?? '');
        }
      });
    }
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }
}
