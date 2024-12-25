import { LocationUtil, PermissionUtil } from '@pura/harmony-utils'
import { Permissions } from '@kit.AbilityKit'

@Component
export struct LocationDisplay {
  @State location: string = '正在获取位置...'
  @State hasLocationPermission: boolean = false
  @State permissionError: string = ''

  private static readonly PERMISSION_LOCATION: Permissions = 'ohos.permission.LOCATION'
  private static readonly PERMISSION_APPROXIMATELY_LOCATION: Permissions = 'ohos.permission.APPROXIMATELY_LOCATION'

  aboutToAppear() {
    this.checkAndRequestPermission()
  }

  private async checkAndRequestPermission() {
    try {
      // 先检查大致位置权限
      const hasApproxLocationPermission = await PermissionUtil.checkPermissions(LocationDisplay.PERMISSION_APPROXIMATELY_LOCATION)
      // 再检查精确位置权限
      const hasLocationPermission = await PermissionUtil.checkPermissions(LocationDisplay.PERMISSION_LOCATION)

      if (hasApproxLocationPermission && hasLocationPermission) {
        // 已有全部权限
        this.hasLocationPermission = true
        this.permissionError = ''
        await this.getLocation()
        return
      }

      // 请求权限
      const permissions: Permissions[] = [LocationDisplay.PERMISSION_APPROXIMATELY_LOCATION]
      if (!hasLocationPermission) {
        permissions.push(LocationDisplay.PERMISSION_LOCATION)
      }

      const granted = await PermissionUtil.requestPermissions(permissions)
      if (granted) {
        this.hasLocationPermission = true
        this.permissionError = ''
        await this.getLocation()
      } else {
        this.permissionError = '获取位置权限失败，请在设置中手动开启'
      }
    } catch (err) {
      this.permissionError = '位置权限检查失败'
      console.error('位置权限检查失败:', JSON.stringify(err))
    }
  }

  private async getLocation() {
    try {
      const location = await LocationUtil.getCurrentLocation()
      this.location = `位置: ${location.latitude.toFixed(4)}°, ${location.longitude.toFixed(4)}°`

      // 监听位置变化
      LocationUtil.onLocationChangeEasy((location) => {
        this.location = `位置: ${location.latitude.toFixed(4)}°, ${location.longitude.toFixed(4)}°`
      })
    } catch (err) {
      console.error('获取位置失败:', JSON.stringify(err))
      this.location = '获取位置失败'
    }
  }

  build() {
    Row() {
      Image($r('app.media.ic_location'))
        .width(20)
        .height(20)
        .margin({ right: 8 })
        .fillColor('#666666')
      Text(this.location)
        .fontSize(14)
        .fontColor('#666666')
      if (!this.hasLocationPermission) {
        Text('获取位置')
          .fontSize(14)
          .fontColor('#2196F3')
          .margin({ left: 8 })
          .onClick(() => {
            this.checkAndRequestPermission()
          })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: 16 })
  }
} 