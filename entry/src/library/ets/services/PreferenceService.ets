import { preferences } from '@kit.ArkData';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';

const TAG = 'PreferenceService';
const DOMAIN = 0x0000;

// 首选项值类型
export type PreferenceValue = string | number | boolean | null;

// 首选项变更监听器类型
export type PreferenceChangeListener = (key: string, value: PreferenceValue) => void;

/**
 * 首选项服务
 */
export class PreferenceService {
  private static instance: PreferenceService;
  private context: common.Context | null = null;
  private preferences: preferences.Preferences | null = null;
  private isInitialized: boolean = false;
  private listeners: Map<string, Set<PreferenceChangeListener>> = new Map();

  private constructor() {}

  /**
   * 获取PreferenceService实例
   */
  public static getInstance(): PreferenceService {
    if (!PreferenceService.instance) {
      PreferenceService.instance = new PreferenceService();
    }
    return PreferenceService.instance;
  }

  /**
   * 添加首选项变更监听器
   * @param key 键名
   * @param listener 监听器
   */
  public addChangeListener(key: string, listener: PreferenceChangeListener): void {
    if (!this.preferences) {
      throw new Error('首选项未初始化');
    }
    if (!this.listeners.has(key)) {
      this.listeners.set(key, new Set());
    }
    this.listeners.get(key)?.add(listener);

    // 如果是第一个监听器，添加preferences的change监听
    if (this.listeners.size === 1) {
      this.preferences.on('change', (changedKey: string) => {
        // 根据键名获取对应的默认值
        let defaultValue: PreferenceValue = null;
        if (this.preferences?.hasSync(changedKey)) {
          const currentValue = this.preferences?.getSync(changedKey, null);
          if (typeof currentValue === 'string') {
            defaultValue = '';
          } else if (typeof currentValue === 'number') {
            defaultValue = 0;
          } else if (typeof currentValue === 'boolean') {
            defaultValue = false;
          }
        }
        const value = this.preferences?.getSync(changedKey, defaultValue);
        const keyListeners = this.listeners.get(changedKey);
        if (keyListeners) {
          keyListeners.forEach(listener => {
            try {
              listener(changedKey, value as PreferenceValue);
            } catch (error) {
              console.error(`[首选项] 监听器执行失败: ${error}`);
            }
          });
        }
      });
    }
  }

  /**
   * 移除首选项变更监听器
   * @param key 键名
   * @param listener 监听器
   */
  public removeChangeListener(key: string, listener: PreferenceChangeListener): void {
    const keyListeners = this.listeners.get(key);
    if (keyListeners) {
      keyListeners.delete(listener);
      if (keyListeners.size === 0) {
        this.listeners.delete(key);
      }
    }

    // 如果没有监听器了，移除preferences的change监听
    if (this.listeners.size === 0 && this.preferences) {
      this.preferences.off('change');
    }
  }

  /**
   * 初始化首选项
   * @param context 上下文
   * @param storeName 首选项存储名称
   * @param defaultValues 默认值配置
   */
  public async init(context: common.Context, storeName: string, defaultValues: Map<string, boolean>): Promise<boolean> {
    if (this.isInitialized) {
      return true;
    }

    try {
      this.context = context;
      hilog.info(DOMAIN, TAG, '开始初始化首选项');

      // 获取首选项实例
      const options: preferences.Options = {
        name: storeName
      };
      this.preferences = preferences.getPreferencesSync(context, options);

      // 初始化默认值
      defaultValues.forEach((value: boolean, key: string) => {
        if (!this.preferences!.hasSync(key)) {
          this.preferences!.putSync(key, value);
        }
      });

      // 持久化到文件
      await new Promise<void>((resolve, reject) => {
        this.preferences!.flush((err: BusinessError) => {
          if (err) {
            reject(new Error(`持久化首选项失败: ${err.message}`));
            return;
          }
          resolve();
        });
      });

      this.isInitialized = true;
      hilog.info(DOMAIN, TAG, '首选项初始化完成');
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化首选项失败: %{public}s', error instanceof Error ? error.message : String(error));
      if (error instanceof Error && error.stack) {
        hilog.error(DOMAIN, TAG, '错误详情: %{public}s', error.stack);
      }
      return false;
    }
  }

  /**
   * 获取开关状态
   * @param key 键名
   */
  public isEnabled(key: string): boolean {
    if (!this.preferences) {
      throw new Error('首选项未初始化');
    }
    return this.getBoolean(key, false);
  }

  /**
   * 设置开关状态
   * @param key 键名
   * @param enabled 开关状态
   */
  public async setEnabled(key: string, enabled: boolean): Promise<void> {
    if (!this.preferences) {
      throw new Error('首选项未初始化');
    }

    try {
      this.setBoolean(key, enabled);
      await new Promise<void>((resolve, reject) => {
        this.preferences!.flush((err: BusinessError) => {
          if (err) {
            reject(new Error(`持久化开关状态失败: ${err.message}`));
            return;
          }
          resolve();
        });
      });
      hilog.info(DOMAIN, TAG, '开关状态已更新: %{public}s = %{public}s', key, enabled.toString());
    } catch (error) {
      hilog.error(DOMAIN, TAG, '设置开关状态失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw new Error('设置开关状态失败');
    }
  }

  /**
   * 获取字符串值
   * @param key 键名
   * @param defaultValue 默认值
   */
  public getString(key: string, defaultValue: string = ''): string {
    if (!this.preferences) {
      throw new Error('首选项未初始化');
    }
    const value = this.preferences.getSync(key, defaultValue);
    return typeof value === 'string' ? value : defaultValue;
  }

  /**
   * 设置字符串值
   * @param key 键名
   * @param value 值
   */
  public setString(key: string, value: string): Promise<void> {
    if (!this.preferences) {
      throw new Error('首选项未初始化');
    }
    this.preferences.put(key, value);
    return new Promise<void>((resolve, reject) => {
      this.preferences!.flush((err: BusinessError) => {
        if (err) {
          reject(new Error(`持久化字符串值失败: ${err.message}`));
          return;
        }
        resolve();
      });
    });
  }

  /**
   * 获取数字值
   * @param key 键名
   * @param defaultValue 默认值
   */
  public getNumber(key: string, defaultValue: number = 0): number {
    if (!this.preferences) {
      throw new Error('首选项未初始化');
    }
    const value = this.preferences.getSync(key, defaultValue);
    return typeof value === 'number' ? value : defaultValue;
  }

  /**
   * 设置数字值
   * @param key 键名
   * @param value 值
   */
  public setNumber(key: string, value: number): Promise<void> {
    if (!this.preferences) {
      throw new Error('首选项未初始化');
    }
    this.preferences.put(key, value);
    return new Promise<void>((resolve, reject) => {
      this.preferences!.flush((err: BusinessError) => {
        if (err) {
          reject(new Error(`持久化数字值失败: ${err.message}`));
          return;
        }
        resolve();
      });
    });
  }

  /**
   * 获取布尔值
   * @param key 键名
   * @param defaultValue 默认值
   */
  public getBoolean(key: string, defaultValue: boolean = false): boolean {
    if (!this.preferences) {
      throw new Error('首选项未初始化');
    }
    const value = this.preferences.getSync(key, defaultValue);
    return typeof value === 'boolean' ? value : defaultValue;
  }

  /**
   * 设置布尔值
   * @param key 键名
   * @param value 值
   */
  public setBoolean(key: string, value: boolean): Promise<void> {
    if (!this.preferences) {
      throw new Error('首选项未初始化');
    }
    this.preferences.put(key, value);
    return new Promise<void>((resolve, reject) => {
      this.preferences!.flush((err: BusinessError) => {
        if (err) {
          reject(new Error(`持久化布尔值失败: ${err.message}`));
          return;
        }
        resolve();
      });
    });
  }
}