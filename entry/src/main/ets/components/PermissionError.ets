import abilityAccessCtrl from '@ohos.abilityAccessCtrl'
import common from '@ohos.app.ability.common'
import { BusinessError } from '@ohos.base'
import bundleManager from '@ohos.bundle.bundleManager'

@Component
export struct PermissionError {
  @Prop errorMessage: string

  private async checkPermission(): Promise<boolean> {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      const tokenId = bundleInfo.appInfo.accessTokenId
      const atManager = abilityAccessCtrl.createAtManager()
      const result = await atManager.checkAccessToken(tokenId, 'ohos.permission.MICROPHONE')
      return result === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
    } catch (err) {
      console.error('检查权限失败:', err)
      return false
    }
  }

  private async openPermissionSettings() {
    try {
      let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager()
      let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
      await atManager.requestPermissionOnSetting(context, ['ohos.permission.MICROPHONE'])
      
      // 等待一段时间后检查权限状态
      setTimeout(async () => {
        const hasPermission = await this.checkPermission()
        if (hasPermission) {
          // 如果获得了权限，重新启动应用
          context.terminateSelf()
        }
      }, 1000)
    } catch (err) {
      console.error('打开设置页面失败:', err)
    }
  }

  build() {
    if (this.errorMessage !== '') {
      Row() {
        Text(this.errorMessage)
          .fontSize(16)
          .fontColor('#F44336')
        
        Text('去设置')
          .fontSize(16)
          .fontColor('#2196F3')
          .margin({ left: 10 })
          .onClick(() => this.openPermissionSettings())
      }
      .margin({ bottom: 20 })
    }
  }
} 