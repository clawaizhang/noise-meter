import bundleManager from '@ohos.bundle.bundleManager'
import common from '@ohos.app.ability.common'
import { BusinessError } from '@ohos.base'

@Component
export struct PermissionError {
  @Prop errorMessage: string

  private openPermissionSettings() {
    let context = getContext(this) as common.UIAbilityContext
    let bundleName = context.applicationInfo.name
    bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      .then((bundleInfo: bundleManager.BundleInfo) => {
        let tokenId = bundleInfo.appInfo.accessTokenId
        let uri = `permission://app/permission/application-detail?tokenId=${tokenId}&bundleName=${bundleName}`
        context.startAbility({
          action: 'action.settings.app.info',
          uri: uri
        }).catch((err: BusinessError) => {
          console.error('打开设置页面失败:', err.message)
        })
      })
      .catch((err: BusinessError) => {
        console.error('获取应用信息失败:', err.message)
      })
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