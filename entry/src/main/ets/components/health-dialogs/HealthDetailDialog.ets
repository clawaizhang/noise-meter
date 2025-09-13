import { DeviceHealthInfo } from "../../types/DeviceHealthInfo"
import { DesignConstants } from "../../constants/DesignConstants"
import { DialogContainer } from "../common/DialogContainer"
import { navigationStack } from "../../constants/ProviderConstant"
import { JSON } from '@kit.ArkTS'
import hilog from '@ohos.hilog'
import { DeviceHealthService } from "../../services/DeviceHealthService"

const TAG = 'HealthDetailDialog';
const DOMAIN = 0x0000;

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

export interface HealthDetailDialogParams {
  metricType: string;
}

@ComponentV2
export struct HealthDetailDialog {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  @Local metricType: string = ''
  @Local healthInfo: DeviceHealthInfo  = DeviceHealthService.getInstance().getHealthInfo();

  // 安全获取映射值的方法
  private getMapValue(map: Record<string, string>, key: string): string | undefined {
    return map[key];
  }

  aboutToAppear() {
    try {
      const params = JSON.parse(JSON.stringify(this.navStack.getParamByName('HealthDetailDialog'))) as HealthDetailDialogParams[];

      if (!params || typeof params !== 'object') {
        hilog.error(DOMAIN, TAG, '导航参数无效');
        return;
      }
      const param = params[0];

      if (!param.metricType) {
        hilog.error(DOMAIN, TAG, '导航参数缺少必要字段');
        return;
      }

      this.metricType = param.metricType;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '解析导航参数失败: %{public}s', error instanceof Error ? error.message : String(error));
    }
  }

  private getMetricDetails(): Array<MetricDetailItem> {
    if (!this.healthInfo) {
      return [] as Array<MetricDetailItem>;
    }

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
    if (!this.healthInfo) {
      return 0;
    }
    const total = Number(this.healthInfo.performance.memory.totalMem)
    const used = total - Number(this.healthInfo.performance.memory.availableMem)
    return Math.round((used / total) * 100)
  }

  private calculateStorageUsage(): number {
    if (!this.healthInfo) {
      return 0;
    }
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

  @Builder
  HealthDetailDialogBuilder() {
    Column() {
      // 标题
      Text(this.getMetricTitle())
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 16 })

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

    }
    .padding(16)
  }

  build() {
    DialogContainer({
      ContentBuilder: () => {
        this.HealthDetailDialogBuilder()
      }
    })
  }
}

// 对话框构建器
@Builder
export function HealthDetailDialogBuilder() {
  HealthDetailDialog()
}