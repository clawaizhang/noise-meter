import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl'
import bundleManager from '@ohos.bundle.bundleManager'
import common from '@ohos.app.ability.common'

export class PermissionService {
  private context: common.UIAbilityContext

  constructor(context: common.UIAbilityContext) {
    this.context = context
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
      return true
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
    } catch (err) {
      console.error('打开设置页面失败:', err)
    }
  }
} 