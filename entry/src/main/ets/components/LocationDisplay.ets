import { LocationUtil } from '@pura/harmony-utils'

@Component
export struct LocationDisplay {
  @State location: string = '正在获取位置...'
  @Link hasLocationPermission: boolean

  aboutToAppear() {
    if (this.hasLocationPermission) {
      this.getLocation()
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