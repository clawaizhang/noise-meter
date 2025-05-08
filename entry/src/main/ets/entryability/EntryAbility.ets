import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { AbilityConstant, Want } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';
import { WindowManager } from '../utils/WindowManager';
import { PreferenceService, PreferenceValue } from '../../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';

const TAG = 'EntryAbility';
const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private keepScreenOn: boolean = false;

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');

    // 初始化首选项默认值
    const preferenceService = PreferenceService.getInstance();
    preferenceService.init(this.context);
    // 获取初始值
    this.keepScreenOn = preferenceService.getBoolean(PreferenceKeyConstants.KEEP_SCREEN_ON, false);

    // 注册监听器
    preferenceService.addChangeListener(PreferenceKeyConstants.KEEP_SCREEN_ON,
      (key: string, newValue: PreferenceValue) => {
        this.keepScreenOn = newValue as boolean;
        const windowManager = WindowManager.getInstance();
        windowManager.setKeepScreenOn(this.keepScreenOn);
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
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    const windowManager = WindowManager.getInstance();
    windowManager.setKeepScreenOn(this.keepScreenOn);
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }
}
