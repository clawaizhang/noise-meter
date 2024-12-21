import abilityAccessCtrl from '@ohos.abilityAccessCtrl'
import common from '@ohos.app.ability.common'
import { BusinessError } from '@ohos.base'

@Component
export struct PermissionError {
  @Prop errorMessage: string

  private openPermissionSettings() {
    try {
      let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager()
      let context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
      atManager.requestPermissionOnSetting(context, ['ohos.permission.MICROPHONE'])
        .then((data: Array<number>) => {
          console.info('权限设置结果:', JSON.stringify(data))
        })
        .catch((err: BusinessError) => {
          console.error('打开设置页面失败:', JSON.stringify(err))
        })
    } catch (err) {
      console.error('创建权限管理器失败:', err)
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