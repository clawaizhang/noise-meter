/**
 * 显示配置接口
 * 定义各端的显示参数
 */
export interface IDisplayConfig {
  deviceType: string;
  supportSpectrum: boolean;
  supportHistory: boolean;
  supportReport: boolean;
  supportVibrate: boolean;
  defaultFontSize: number;
  largeFontSize: number;
  pagePadding: number;
  buttonSize: number;
}

/**
 * 手机显示配置
 */
export const PhoneDisplayConfig: IDisplayConfig = {
  deviceType: 'phone',
  supportSpectrum: true,
  supportHistory: true,
  supportReport: true,
  supportVibrate: false,
  defaultFontSize: 16,
  largeFontSize: 36,
  pagePadding: 16,
  buttonSize: 48
};

/**
 * 平板显示配置
 */
export const TabletDisplayConfig: IDisplayConfig = {
  deviceType: 'tablet',
  supportSpectrum: true,
  supportHistory: true,
  supportReport: true,
  supportVibrate: false,
  defaultFontSize: 18,
  largeFontSize: 48,
  pagePadding: 24,
  buttonSize: 56
};

/**
 * 手表显示配置
 */
export const WearableDisplayConfig: IDisplayConfig = {
  deviceType: 'wearable',
  supportSpectrum: false,
  supportHistory: false,
  supportReport: false,
  supportVibrate: true,
  defaultFontSize: 14,
  largeFontSize: 56,
  pagePadding: 12,
  buttonSize: 64
};

/**
 * 显示配置映射
 */
export const DisplayConfigs: Map<string, IDisplayConfig> = new Map([
  ['phone', PhoneDisplayConfig],
  ['tablet', TabletDisplayConfig],
  ['wearable', WearableDisplayConfig]
]);
