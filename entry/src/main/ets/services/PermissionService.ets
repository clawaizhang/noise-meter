import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl'
import bundleManager from '@ohos.bundle.bundleManager'
import common from '@ohos.app.ability.common'

export interface PermissionCallback {
  onPermissionGranted: () => void;
}

export class PermissionService {
  private context: common.UIAbilityContext
  private callback: PermissionCallback | null = null

  constructor(context: common.UIAbilityContext) {
    this.context = context
  }

  public setCallback(callback: PermissionCallback) {
    this.callback = callback
  }

  /**
   * 检查权限状态
   * @param permission 权限名称
   * @returns 是否已授权
   */
  public async checkPermission(permission: Permissions): Promise<boolean> {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      const tokenId = bundleInfo.appInfo.accessTokenId
      const atManager = abilityAccessCtrl.createAtManager()
      const result = await atManager.checkAccessToken(tokenId, permission)
      return result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
    } catch (err) {
      console.error('检查权限失败:', err)
      return false
    }
  }

  /**
   * 请求权限
   * @param permissions 权限列表
   * @returns 是否获得授权
   */
  public async requestPermissions(permissions: Permissions[]): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager()
      await atManager.requestPermissionsFromUser(this.context, permissions)
      const hasPermission = await this.checkPermission(permissions[0])
      if (hasPermission) {
        this.callback?.onPermissionGranted()
      }
      return hasPermission
    } catch (err) {
      console.error('请求权限失败:', err)
      return false
    }
  }

  /**
   * 打开权限设置页面
   * @param permissions 权限列表
   */
  public async openPermissionSettings(permissions: Permissions[]): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager()
      await atManager.requestPermissionOnSetting(this.context, permissions)
      // 等待一段时间后检查权限状态
      setTimeout(async () => {
        const hasPermission = await this.checkPermission(permissions[0])
        if (hasPermission) {
          this.callback?.onPermissionGranted()
        }
      }, 1000)
    } catch (err) {
      console.error('打开设置页面失败:', JSON.stringify(err))
    }
  }
} 