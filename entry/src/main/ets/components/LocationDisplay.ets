import { LocationUtil, PermissionUtil } from '@pura/harmony-utils'

@Component
export struct LocationDisplay {
  @State location: string = '正在获取位置...'
  @State hasLocationPermission: boolean = false

  aboutToAppear() {
    this.checkAndRequestPermission()
  }

  private async checkAndRequestPermission() {
    try {
      const hasPermission = await PermissionUtil.checkPermissions('ohos.permission.LOCATION')
      if (hasPermission) {
        this.hasLocationPermission = true
        this.getLocation()
        return
      }

      const granted = await PermissionUtil.requestPermissions(['ohos.permission.LOCATION'])
      if (granted) {
        this.hasLocationPermission = true
        this.getLocation()
      } else {
        this.location = '无法获取位置信息'
      }
    } catch (err) {
      console.error('位置权限检查失败:', JSON.stringify(err))
      this.location = '位置权限检查失败'
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
      Text(this.hasLocationPermission ? this.location : '等待位置权限...')
        .fontSize(14)
        .fontColor('#666666')
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: 16 })
  }
} 