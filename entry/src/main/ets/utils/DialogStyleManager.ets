import { InfSheet } from '@hadss/dialoghub';
import { ColorModeManager } from './ColorModeManager';

export class DialogStyleManager {
  // 静态属性存储Dialog集合
  private static dialogs: Set<InfSheet> = new Set();

  // 静态初始化
  public static init(): void {
    ColorModeManager.addListener(() => {
      DialogStyleManager.updateAllDialogs();
    });
  }

  // 注册Dialog
  public static registerDialog(dialog: InfSheet): void {
    DialogStyleManager.dialogs.add(dialog);
  }

  // 注销Dialog
  public static unregisterDialog(dialog: InfSheet): void {
    DialogStyleManager.dialogs.delete(dialog);
  }

  // 更新所有Dialog样式
  private static updateAllDialogs(): void {
    DialogStyleManager.dialogs.forEach(dialog => {
      try {
        dialog.updateStyle({
          backgroundColor: $r('sys.color.background_secondary')
        });
      } catch (error) {
        // Dialog可能已销毁，从集合中移除
        DialogStyleManager.dialogs.delete(dialog);
      }
    });
  }
}