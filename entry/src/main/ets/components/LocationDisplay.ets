import { LocationUtil, PermissionUtil } from '@pura/harmony-utils'
import { Permissions } from '@kit.AbilityKit'
import geoLocationManager from '@ohos.geoLocationManager'

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

  aboutToDisappear() {
    // 清理位置监听器
    LocationUtil.offLocationChange()
  }

  private async checkAndRequestPermission() {
    try {
      // 检查所有位置权限
      const hasLocationPermission = await PermissionUtil.checkPermissions(LocationDisplay.PERMISSION_LOCATION)
      const hasApproxPermission = await PermissionUtil.checkPermissions(LocationDisplay.PERMISSION_APPROXIMATELY_LOCATION)
      
      if (hasLocationPermission && hasApproxPermission) {
        this.hasLocationPermission = true
        this.permissionError = ''
        await this.getLocation()
        return
      }

      // 请求权限
      const granted = await PermissionUtil.requestPermissions([
        LocationDisplay.PERMISSION_LOCATION,
        LocationDisplay.PERMISSION_APPROXIMATELY_LOCATION
      ])
      if (granted) {
        this.hasLocationPermission = true
        this.permissionError = ''
        await this.getLocation()
      } else {
        this.updateError('获取位置权限失败，请在设置中手动开启')
      }
    } catch (err) {
      console.error('位置权限检查失败:', JSON.stringify(err))
      this.updateError('位置权限检查失败')
    }
  }

  private updateError(error: string) {
    this.permissionError = error
    this.hasLocationPermission = false
    this.location = error
  }

  private async getLocation() {
    try {
      const location = await LocationUtil.getCurrentLocation()
      this.updateLocation(location)
      
      // 监听位置变化
      LocationUtil.onLocationChangeEasy(this.updateLocation)
    } catch (err) {
      console.error('获取位置失败:', JSON.stringify(err))
      this.updateError('获取位置失败')
    }
  }

  private updateLocation(location: geoLocationManager.Location) {
    if (location.latitude !== undefined && location.longitude !== undefined) {
      this.location = `位置: ${location.latitude.toFixed(4)}°, ${location.longitude.toFixed(4)}°`
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
      if (this.permissionError || this.location === '获取位置失败') {
        Text('获取位置')
          .fontSize(14)
          .fontColor('#2196F3')
          .margin({ left: 8 })
          .onClick(async () => {
            const granted = await PermissionUtil.requestPermissionsEasy([
              LocationDisplay.PERMISSION_LOCATION,
              LocationDisplay.PERMISSION_APPROXIMATELY_LOCATION
            ])
            if (granted) {
              this.hasLocationPermission = true
              this.permissionError = ''
              await this.getLocation()
            }
          })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: 16 })
  }
} 