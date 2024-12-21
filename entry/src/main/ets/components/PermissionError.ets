import { PermissionService } from '../services/PermissionService'

@Component
export struct PermissionError {
  @Prop errorMessage: string
  permissionService: PermissionService | null = null

  build() {
    if (this.errorMessage !== '') {
      Row() {
        Text(this.errorMessage)
          .fontSize(16)
          .fontColor('#F44336')
        
        Text('授予权限')
          .fontSize(16)
          .fontColor('#2196F3')
          .margin({ left: 10 })
          .onClick(() => {
            this.permissionService?.openPermissionSettings(['ohos.permission.MICROPHONE'])
          })
      }
      .margin({ bottom: 20 })
    }
  }
} 