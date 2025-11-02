import common from '@ohos.app.ability.common';
import { ConfigurationConstant } from '@kit.AbilityKit';

export class ColorModeManager {
  // 静态属性存储监听器
  private static listeners: Set<() => void> = new Set();
  private static appContext: common.ApplicationContext | null = null;

  // 静态初始化 - 现在不需要configuration监听，由Index.ets中的Monitor处理
  public static init(): void {
    // 不再使用configuration.on监听，改为由Index.ets中的@Monitor('pk.display_mode')处理
  }

  // 设置应用上下文
  public static setAppContext(context: common.ApplicationContext): void {
    ColorModeManager.appContext = context;
  }

  // 设置颜色模式
  public static setColorMode(mode: string): void {
    if (!ColorModeManager.appContext) return;
    
    if (mode === 'default') {
      ColorModeManager.appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } else if (mode === 'light') {
      ColorModeManager.appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    } else if (mode === 'dark') {
      ColorModeManager.appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    }
    
    // 通知所有监听器颜色模式已改变
    ColorModeManager.notifyListeners();
  }

  // 添加监听器
  public static addListener(callback: () => void): void {
    ColorModeManager.listeners.add(callback);
  }

  // 移除监听器
  public static removeListener(callback: () => void): void {
    ColorModeManager.listeners.delete(callback);
  }

  // 通知所有监听器
  public static notifyListeners(): void {
    ColorModeManager.listeners.forEach(callback => callback());
  }
}