import { LocalSendDevice, DeviceType, DeviceStatus } from '../../models/LocalSendDevice'
import { LocalSendFile, FileType } from '../../models/LocalSendFile'
import { LocalSendTransfer, TransferStatus, TransferDirection } from '../../models/LocalSendTransfer'
import { LocalSendService } from '../../services/LocalSendService'
import common from '@ohos.app.ability.common'
import prompt from '@ohos.prompt'

@ComponentV2
export struct LocalSendPage {
  @Local devices: LocalSendDevice[] = []
  @Local transfers: LocalSendTransfer[] = []
  @Local selectedFiles: LocalSendFile[] = []
  @Local isDiscovering: boolean = false
  @Local showFilePicker: boolean = false
  @Local currentView: 'devices' | 'transfers' = 'devices'

  private localSendService: LocalSendService = LocalSendService.getInstance()
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext

  aboutToAppear(): void {
    this.initializeServices()
    this.loadTransfers()
  }

  private async initializeServices(): Promise<void> {
    try {
      await this.localSendService.initializePreferences(this.context)
    } catch (error) {
      console.error('初始化服务失败:', error)
      this.showError('初始化服务失败')
    }
  }

  private showError(message: string): void {
    prompt.showToast({
      message: message,
      duration: 2000
    })
  }

  private showSuccess(message: string): void {
    prompt.showToast({
      message: message,
      duration: 2000
    })
  }

  private async loadTransfers(): Promise<void> {
    try {
      this.transfers = this.localSendService.getTransfers()
    } catch (error) {
      console.error('加载传输记录失败:', error)
      this.showError('加载传输记录失败')
    }
  }

  private async discoverDevices(): Promise<void> {
    this.isDiscovering = true
    try {
      this.devices = await this.localSendService.discoverDevices()
      if (this.devices.length > 1) { // 除了当前设备外还有其他设备
        this.showSuccess(`发现 ${this.devices.length - 1} 个设备`)
      } else {
        this.showError('未发现其他设备')
      }
    } catch (error) {
      console.error('设备发现失败:', error)
      this.showError('设备发现失败')
    }
    this.isDiscovering = false
  }

  private async sendToDevice(deviceId: string): Promise<void> {
    if (this.selectedFiles.length === 0) {
      this.showError('请先选择文件')
      return
    }

    try {
      await this.localSendService.sendFiles(this.selectedFiles, deviceId)
      this.selectedFiles = []
      this.loadTransfers()
      this.showSuccess('文件发送成功')
    } catch (error) {
      console.error('发送文件失败:', error)
      this.showError('发送文件失败')
    }
  }

  private getDeviceIcon(deviceType: DeviceType): Resource {
    switch (deviceType) {
      case DeviceType.PHONE:
        return $r('app.media.ic_user')
      case DeviceType.TABLET:
        return $r('app.media.ic_meter')
      case DeviceType.COMPUTER:
        return $r('app.media.ic_cpu')
      default:
        return $r('app.media.ic_user')
    }
  }

  private getStatusColor(status: DeviceStatus): Resource {
    switch (status) {
      case DeviceStatus.ONLINE:
        return $r('app.color.success')
      case DeviceStatus.TRANSFERRING:
        return $r('app.color.health_warning')
      case DeviceStatus.CONNECTING:
        return $r('app.color.primary')
      default:
        return $r('app.color.error')
    }
  }

  @Builder
  DeviceList() {
    Column() {
      if (this.devices.length === 0) {
        Column() {
          Image($r('app.media.ic_refresh'))
            .width(64)
            .height(64)
            .margin({ bottom: 16 })
          Text('未发现设备')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
          Text('点击刷新按钮搜索附近设备')
            .fontSize(14)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ top: 8 })
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.devices, (device: LocalSendDevice) => {
            ListItem() {
              Row() {
                Image(this.getDeviceIcon(device.deviceType))
                  .width(40)
                  .height(40)
                  .margin({ right: 12 })
                
                Column() {
                  Text(device.name)
                    .fontSize(16)
                    .fontColor($r('app.color.text_primary'))
                  Text(device.ipAddress)
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                }
                .layoutWeight(1)

                Column() {
                  Text(device.status)
                    .fontSize(12)
                    .fontColor(this.getStatusColor(device.status))
                  if (this.selectedFiles.length > 0) {
                    Button($r('app.string.send_button'), { type: ButtonType.Capsule })
                      .onClick(() => {
                        this.sendToDevice(device.id)
                      })
                    .margin({ top: 4 })
                    .width(60)
                    .height(28)
                  }
                }
                .alignItems(HorizontalAlign.End)
              }
              .padding(16)
              .width('100%')
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
  }

  @Builder
  TransferList() {
    Column() {
      if (this.transfers.length === 0) {
        Column() {
          Image($r('app.media.ic_history'))
            .width(64)
            .height(64)
            .margin({ bottom: 16 })
          Text('暂无传输记录')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.transfers, (transfer: LocalSendTransfer) => {
            ListItem() {
              Row() {
                Column() {
                  Text(transfer.fileName)
                    .fontSize(14)
                    .fontColor($r('app.color.text_primary'))
                  Text(`${transfer.deviceName} • ${this.formatFileSize(transfer.fileSize)}`)
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                }
                .layoutWeight(1)

                Column() {
                  Text(`${transfer.progress}%`)
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                  Progress({
                    value: transfer.progress,
                    total: 100
                  })
                  .width(60)
                }
              }
              .padding(12)
            }
          })
        }
      }
    }
  }

  private formatFileSize(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  build() {
    Column() {
      // 顶部操作栏
      Row() {
        Button(this.isDiscovering ? $r('app.string.searching_button') : $r('app.string.refresh_button'), { type: ButtonType.Normal })
          .onClick(() => {
            this.discoverDevices()
          })
        .enabled(!this.isDiscovering)

        Button($r('app.string.select_file_button'), { type: ButtonType.Normal })
          .onClick(async () => {
            this.isDiscovering = true
            try {
              this.selectedFiles = await this.localSendService.selectFiles()
              if (this.selectedFiles.length > 0) {
                this.showSuccess(`已选择 ${this.selectedFiles.length} 个文件`)
              }
            } catch (error) {
              console.error('选择文件失败:', error)
              this.showError('选择文件失败')
            }
            this.isDiscovering = false
          })
        .margin({ left: 12 })

        Button(this.currentView === 'devices' ? $r('app.string.view_transfers_button') : $r('app.string.view_devices_button'), { type: ButtonType.Normal })
          .onClick(() => {
            this.currentView = this.currentView === 'devices' ? 'transfers' : 'devices'
          })
        .margin({ left: 12 })
      }
      .padding(16)
      .justifyContent(FlexAlign.Start)

      // 内容区域
      if (this.currentView === 'devices') {
        this.DeviceList()
      } else {
        this.TransferList()
      }

      // 选中的文件提示
      if (this.selectedFiles.length > 0) {
        Text(`已选择 ${this.selectedFiles.length} 个文件`)
          .fontSize(14)
          .fontColor($r('app.color.success'))
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .height('100%')
  }
}