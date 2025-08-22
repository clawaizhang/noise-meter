import { DeviceHealthInfo } from "../../types/DeviceHealthInfo"
import { LengthUnit } from "@kit.ArkUI"
import { DesignConstants } from "../../constants/DesignConstants"

// 定义指标详情项的接口
interface MetricDetailItem {
  label: string
  value: string
  unit?: string
}

// 定义标题映射类型
type TitleMap = Record<string, string>;

// 定义电池状态映射类型
type BatteryStatusMap = Record<string, string>;

// 定义网络类型映射类型
type NetworkTypeMap = Record<string, string>;

// 定义传感器状态映射类型
type SensorStatusMap = Record<string, string>;

@ComponentV2
export struct DetailModal {
  @Param isVisible: boolean = false
  @Param metricType: string = ''

  // 安全获取映射值的方法
  private getMapValue(map: Record<string, string>, key: string): string | undefined {
    return map[key];
  }
  @Param @Require healthInfo: DeviceHealthInfo
  @Param @Require onClose: () => void

  @Local opacityValue: number = 0
  @Local scaleValue: number = 0.8

  aboutToAppear() {
    if (this.isVisible) {
      this.showAnimation()
    }
  }

  aboutToUpdate() {
    if (this.isVisible) {
      this.showAnimation()
    } else {
      this.hideAnimation()
    }
  }

  private showAnimation() {
    this.opacityValue = 0
    this.scaleValue = 0.8
    animateTo({
      duration: 300,
      curve: Curve.EaseOut
    }, () => {
      this.opacityValue = 1
      this.scaleValue = 1
    })
  }

  private hideAnimation() {
    animateTo({
      duration: 200,
      curve: Curve.EaseIn
    }, () => {
      this.opacityValue = 0
      this.scaleValue = 0.8
    })
  }

  private getMetricDetails(): Array<MetricDetailItem> {
    switch (this.metricType) {
      case 'battery':
        return [
          { label: '电量水平', value: this.healthInfo.battery.level.toString(), unit: '%' } as MetricDetailItem,
          { label: '电池健康度', value: this.healthInfo.battery.health.toString(), unit: '%' } as MetricDetailItem,
          { label: '电池温度', value: this.healthInfo.battery.temperature.toString(), unit: '°C' } as MetricDetailItem,
          { label: '充电状态', value: this.getBatteryStatusText(this.healthInfo.battery.status) } as MetricDetailItem
        ]
      case 'memory':
        return [
          { label: '总内存', value: this.formatBytes(Number(this.healthInfo.performance.memory.totalMem)), unit: '' } as MetricDetailItem,
          { label: '可用内存', value: this.formatBytes(Number(this.healthInfo.performance.memory.availableMem)), unit: '' } as MetricDetailItem,
          { label: '空闲内存', value: this.formatBytes(Number(this.healthInfo.performance.memory.freeMem)), unit: '' } as MetricDetailItem,
          { label: '内存使用率', value: this.calculateMemoryUsage().toString(), unit: '%' } as MetricDetailItem
        ]
      case 'storage':
        return [
          { label: '总存储', value: this.formatBytes(this.healthInfo.performance.storage.total), unit: '' } as MetricDetailItem,
          { label: '已用存储', value: this.formatBytes(this.healthInfo.performance.storage.used), unit: '' } as MetricDetailItem,
          { label: '可用存储', value: this.formatBytes(this.healthInfo.performance.storage.free), unit: '' } as MetricDetailItem,
          { label: '存储使用率', value: this.calculateStorageUsage().toString(), unit: '%' } as MetricDetailItem
        ]
      case 'cpu':
        return [
          { label: 'CPU使用率', value: this.healthInfo.performance.cpu.toString(), unit: '%' } as MetricDetailItem,
          { label: '性能状态', value: this.getCpuStatusText(this.healthInfo.performance.cpu) } as MetricDetailItem
        ]
      case 'network':
        return [
          { label: '网络连接', value: this.healthInfo.network.isConnected ? '已连接' : '未连接' } as MetricDetailItem,
          { label: '网络类型', value: this.getNetworkTypeText(this.healthInfo.network.type) } as MetricDetailItem,
          { label: '信号强度', value: this.healthInfo.network.signalStrength.toString(), unit: '/4' } as MetricDetailItem,
          { label: '下载速度', value: this.healthInfo.network.downloadSpeed.toString(), unit: 'kbps' } as MetricDetailItem,
          { label: '上传速度', value: this.healthInfo.network.uploadSpeed.toString(), unit: 'kbps' } as MetricDetailItem,
          { label: '网络延迟', value: this.healthInfo.network.latency.toString(), unit: 'ms' } as MetricDetailItem
        ]
      case 'sensors':
        return [
          { label: '传感器状态', value: this.getSensorStatusText(this.healthInfo.sensors.status) } as MetricDetailItem
        ]
      default:
        return [] as Array<MetricDetailItem>
    }
  }

  private getMetricTitle(): string {
    const titles: TitleMap = {
      'battery': '电池信息',
      'memory': '内存信息',
      'storage': '存储信息',
      'cpu': 'CPU信息',
      'network': '网络信息',
      'sensors': '传感器信息'
    }
    return this.getMapValue(titles, this.metricType) || '详细信息'
  }

  private getBatteryStatusText(status: string): string {
    const statusMap: BatteryStatusMap = {
      'charging': '充电中',
      'discharging': '放电中',
      'full': '已充满',
      'unknown': '未知状态'
    }
    return this.getMapValue(statusMap, status) || status
  }

  private getNetworkTypeText(type: string): string {
    const typeMap: NetworkTypeMap = {
      'wifi': 'Wi-Fi',
      'cellular': '移动网络',
      'ethernet': '以太网',
      'none': '无网络'
    }
    return this.getMapValue(typeMap, type) || type
  }

  private getSensorStatusText(status: string): string {
    const statusMap: SensorStatusMap = {
      'normal': '正常',
      'warning': '警告',
      'error': '错误'
    }
    return this.getMapValue(statusMap, status) || status
  }

  private getCpuStatusText(usage: number): string {
    if (usage < 30) return '空闲'
    if (usage < 60) return '正常'
    if (usage < 80) return '较高'
    return '过高'
  }

  private calculateMemoryUsage(): number {
    const total = Number(this.healthInfo.performance.memory.totalMem)
    const used = total - Number(this.healthInfo.performance.memory.availableMem)
    return Math.round((used / total) * 100)
  }

  private calculateStorageUsage(): number {
    const total = this.healthInfo.performance.storage.total
    const used = this.healthInfo.performance.storage.used
    return Math.round((used / total) * 100)
  }

  private formatBytes(bytes: number): string {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  build() {
    if (!this.isVisible) {
      // 不渲染不可见的弹窗
      Blank()
    } else {
      // 半透明背景层
      Stack({ alignContent: Alignment.Center }) {
        // 点击背景关闭弹窗
        Column() {
          Blank()
            .width('100%')
            .height('100%')
            .backgroundColor('#000000')
            .opacity(0.5)
            .onClick(() => {
              this.onClose()
            })
        }

        // 弹窗内容
        Column() {
          // 标题栏
          Row({ space: DesignConstants.SPACING_SM }) {
            Text(this.getMetricTitle())
              .fontSize(DesignConstants.DETAIL_MODAL.TITLE_SIZE)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
  
            Image($r('app.media.ic_close'))
              .width(DesignConstants.DETAIL_MODAL.ICON_SIZE)
              .height(DesignConstants.DETAIL_MODAL.ICON_SIZE)
              .onClick(() => {
                this.onClose()
              })
          }
          .width('100%')
          .padding({
            top: DesignConstants.DETAIL_MODAL.PADDING,
            bottom: DesignConstants.DETAIL_MODAL.PADDING,
            left: DesignConstants.DETAIL_MODAL.PADDING,
            right: DesignConstants.DETAIL_MODAL.PADDING
          })
          .borderWidth({ bottom: DesignConstants.BORDER_WIDTH_SM })
          .borderColor({ bottom: $r('app.color.border_primary') })

          // 详细信息列表
          Column({ space: DesignConstants.DETAIL_MODAL.SPACING }) {
            ForEach(this.getMetricDetails(), (item: MetricDetailItem, index: number) => {
              Row({ space: DesignConstants.SPACING_SM }) {
                Text(item.label)
                  .fontSize(DesignConstants.DETAIL_MODAL.CONTENT_SIZE)
                  .fontColor($r('app.color.text_secondary'))
                  .layoutWeight(1)
  
                Text(`${item.value}${item.unit || ''}`)
                  .fontSize(DesignConstants.DETAIL_MODAL.CONTENT_SIZE)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
              }
              .width('100%')
              .padding({
                left: DesignConstants.DETAIL_MODAL.PADDING,
                right: DesignConstants.DETAIL_MODAL.PADDING
              })
              
              if (index < this.getMetricDetails().length - 1) {
                Divider()
                  .strokeWidth(DesignConstants.BORDER_WIDTH_SM)
                  .color($r('app.color.border_primary'))
                  .margin({
                    left: DesignConstants.DETAIL_MODAL.PADDING,
                    right: DesignConstants.DETAIL_MODAL.PADDING
                  })
              }
            })
          }
          .width('100%')
          .padding({
            top: DesignConstants.DETAIL_MODAL.PADDING,
            bottom: DesignConstants.SPACING_LG
          })
        }
        .width('80%')
        .constraintSize({ maxWidth: 400 })
        .backgroundColor($r('app.color.background_primary'))
        .borderRadius(DesignConstants.DETAIL_MODAL.BORDER_RADIUS)
        .shadow(DesignConstants.SHADOW_LG)
        .opacity(this.opacityValue)
        .scale({ x: this.scaleValue, y: this.scaleValue })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(1000)
    }
  }
}