import { PermissionUtil } from '@pura/harmony-utils';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { AppKeys } from '../models/AppKeys';
import { PreferenceKeys } from '../models/PreferenceKeys';

/**
 * 权限状态管理服务
 * 统一管理应用权限状态
 */
export class PermissionService {
  private static instance: PermissionService | null = null;
  
  /**
   * 获取 PermissionService 实例
   */
  public static getInstance(): PermissionService {
    if (!PermissionService.instance) {
      PermissionService.instance = new PermissionService();
    }
    return PermissionService.instance;
  }
  
  /**
   * 检查并更新麦克风权限状态
   * @returns Promise<boolean> 是否有权限
   */
  async checkAndUpdateMicrophonePermission(): Promise<boolean> {
    try {
      const hasPermission = await PermissionUtil.checkPermissions('ohos.permission.MICROPHONE');
      // 更新AppKeys中的实时状态
      AppStorageV2.connect(AppKeys)!.microphonePermissionGranted = hasPermission;
      console.info(`[权限管理] 麦克风权限状态: ${hasPermission ? '已授权' : '未授权'}`);
      return hasPermission;
    } catch (error) {
      console.error('[权限管理] 检查麦克风权限失败:', error);
      AppStorageV2.connect(AppKeys)!.microphonePermissionGranted = false;
      return false;
    }
  }
  
  /**
   * 请求麦克风权限
   * @returns Promise<boolean> 是否授权成功
   */
  async requestMicrophonePermission(): Promise<boolean> {
    try {
      console.info('[权限管理] 开始请求麦克风权限');
      const granted = await PermissionUtil.requestPermissions(['ohos.permission.MICROPHONE']);
      
      // 更新实时状态
      AppStorageV2.connect(AppKeys)!.microphonePermissionGranted = granted;
      
      // 更新持久化状态
      const pk = PersistenceV2.connect(PreferenceKeys)!;
      pk.microphone_permission_requested = true;
      
      console.info(`[权限管理] 麦克风权限请求结果: ${granted ? '授权成功' : '授权失败'}`);
      return granted;
    } catch (error) {
      console.error('[权限管理] 请求麦克风权限失败:', error);
      AppStorageV2.connect(AppKeys)!.microphonePermissionGranted = false;
      return false;
    }
  }
  
  /**
   * 跳转到权限设置页面
   */
  async openPermissionSettings(): Promise<void> {
    try {
      console.info('[权限管理] 跳转到权限设置页面');
      await PermissionUtil.requestPermissionOnSettingEasy(['ohos.permission.MICROPHONE']);
      // 从设置返回后重新检查权限状态
      await this.checkAndUpdateMicrophonePermission();
    } catch (error) {
      console.error('[权限管理] 跳转权限设置失败:', error);
    }
  }
  
  /**
   * 初始化权限状态
   */
  async initializePermissionState(): Promise<void> {
    try {
      console.info('[权限管理] 初始化权限状态');
      await this.checkAndUpdateMicrophonePermission();
    } catch (error) {
      console.error('[权限管理] 初始化权限状态失败:', error);
    }
  }
  
  /**
   * 获取麦克风权限状态
   * @returns boolean 是否有权限
   */
  getMicrophonePermissionStatus(): boolean {
    return AppStorageV2.connect(AppKeys)!.microphonePermissionGranted;
  }
  
  /**
   * 是否已请求过麦克风权限
   * @returns boolean 是否已请求过
   */
  hasRequestedMicrophonePermission(): boolean {
    const pk = PersistenceV2.connect(PreferenceKeys)!;
    return pk.microphone_permission_requested;
  }
}