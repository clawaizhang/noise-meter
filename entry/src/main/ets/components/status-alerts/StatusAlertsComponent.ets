import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PermissionService } from '../../services/PermissionService';
import { AudioDeviceMonitorService, AudioDeviceInfo } from '../../services/AudioDeviceMonitorService';
import { AudioControllerService } from '../../services/AudioControllerService';
import { Subscription } from 'rxjs';
import { Throttle } from '../../utils/Debounce';

@ComponentV2
export struct StatusAlertsComponent {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!
  @Local private errorMessages: string[] = []
  @Local private hasExternalDeviceConnected: boolean = false
  @Local private connectedDeviceName: string = ''
  
  // 服务实例
  private permissionService: PermissionService = PermissionService.getInstance()
  private audioDeviceMonitorService: AudioDeviceMonitorService = AudioDeviceMonitorService.getInstance()
  private audioControllerService: AudioControllerService = AudioControllerService.getInstance(this.ak, this.pk)
  
  // RxJS订阅管理
  private errorSubscription?: Subscription

  build() {
    Column({ space: 16 }) {
      // 权限提示组件 - 显示在顶部
      if (!this.ak.microphonePermissionGranted) {
        this.smartPermissionPrompt()
      }

      // 外置设备警告显示
      if (this.hasExternalDeviceConnected) {
        this.externalDeviceWarningDisplay()
      }

      // 错误消息显示区域
      if (this.errorMessages.length > 0) {
        this.errorMessagesDisplay()
      }
    }
    .width('100%')
  }

  aboutToDisappear() {
    // 清理RxJS订阅
    if (this.errorSubscription) {
      this.errorSubscription.unsubscribe()
    }
    // 取消设备状态监听
    this.unregisterDeviceChangeListener()
  }

  aboutToAppear() {
    // 注册设备状态监听
    this.registerDeviceChangeListener()

    // 订阅错误信息流
    this.errorSubscription = this.audioControllerService.getError$().subscribe(
      (errors: string[]) => {
        this.errorMessages = errors
        console.info('[RxJS] StatusAlertsComponent接收到错误信息:', errors)
      }
    )
  }

  @Builder
  smartPermissionPrompt() {
    Row() {
      Image($r('app.media.ic_mic'))
        .width(20)
        .height(20)
        .margin({ right: 8 })

      Column() {
        Text('需要麦克风权限才能检测噪音')
          .fontSize(14)
          .fontColor($r('app.color.ohos_id_color_warning'))

        if (!this.pk.microphone_permission_requested) {
          Text('点击按钮授权')
            .fontSize(12)
            .fontColor($r('app.color.ohos_id_color_text_secondary'))
            .margin({ top: 2 })
        } else {
          Text('请在系统设置中开启麦克风权限')
            .fontSize(12)
            .fontColor($r('app.color.ohos_id_color_text_secondary'))
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      if (!this.pk.microphone_permission_requested) {
        Button('授权')
          .fontSize(12)
          .padding({
            left: 16,
            right: 16,
            top: 6,
            bottom: 6
          })
          .onClick(async () => {
            Throttle.click(async () => {
              const permissionService = PermissionService.getInstance()
              await permissionService.requestMicrophonePermission()
            })
          })
      } else {
        Button('去设置')
          .fontSize(12)
          .padding({
            left: 16,
            right: 16,
            top: 6,
            bottom: 6
          })
          .onClick(async () => {
            Throttle.click(async () => {
              const permissionService = PermissionService.getInstance()
              await permissionService.openPermissionSettings()
            })
          })
      }
    }
    .padding(16)
    .width('100%')
    .backgroundColor($r('app.color.comp_background_warning_secondary'))
    .borderRadius(16)
  }

  @Builder
  errorMessagesDisplay() {
    Column({ space: 8 }) {
      ForEach(this.errorMessages, (errorMsg: string, index: number) => {
        Row() {
          Image($r('sys.media.ic_grid_unknown'))
            .width(16)
            .height(16)
            .margin({ right: 8 })
            .fillColor($r('app.color.ohos_id_color_warning'))

          Text(errorMsg)
            .fontSize(14)
            .fontColor($r('app.color.ohos_id_color_warning'))
            .layoutWeight(1)

          Blank()

          Button('关闭')
            .fontSize(12)
            .type(ButtonType.Capsule)
            .onClick(() => {
              // 移除特定错误消息
              Throttle.click(() => {
              this.errorMessages.splice(index, 1)
              });
            })
        }
        .width('100%')
        .backgroundColor($r('app.color.comp_background_warning_secondary'))
        .borderRadius(8)
        .padding(8)
      })
    }
  }

  @Builder
  externalDeviceWarningDisplay() {
    Row() {
      Image($r('sys.media.ic_grid_unknown'))
        .width(20)
        .height(20)
        .margin({ right: 8 })
        .fillColor($r('app.color.ohos_id_color_warning'))

      Column() {
        Text('•外接音频设备接入，建议重新校准以确保噪音检测准确。')
          .fontSize(14)
          .fontColor($r('app.color.ohos_id_color_warning'))
          .textAlign(TextAlign.Start)
        Text('•使用降噪耳机可能导致音频播放音量变小。')
          .fontSize(14)
          .fontColor($r('app.color.ohos_id_color_warning'))
          .textAlign(TextAlign.Start)
        Text('•如您需要听音乐、看视频，建议退出本应用以避免干扰。')
          .fontSize(14)
          .fontColor($r('app.color.ohos_id_color_warning'))
          .textAlign(TextAlign.Start)

        if (this.connectedDeviceName) {
          Text(`设备: ${this.connectedDeviceName}`)
            .fontSize(12)
            .fontColor($r('app.color.ohos_id_color_text_secondary'))
            .margin({ top: 2 })
            .textAlign(TextAlign.Start)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Blank()

      Button('关闭')
        .fontSize(12)
        .type(ButtonType.Capsule)
        .padding({
          left: 16,
          right: 16,
          top: 6,
          bottom: 6
        })
        .onClick(() => {
          Throttle.click(() => {
            // 关闭警告提示
            this.hasExternalDeviceConnected = false
            this.connectedDeviceName = ''
            console.info('[DEVICE_WARNING] 用户关闭设备警告提示')
          })
        })
    }
    .padding(16)
    .width('100%')
    .backgroundColor($r('app.color.comp_background_warning_secondary'))
    .borderRadius(16)
  }

  /**
   * 注册设备状态监听器
   */
  private registerDeviceChangeListener(): void {
    this.audioDeviceMonitorService.addDeviceChangeListener((deviceInfo: AudioDeviceInfo) => {
      this.handleDeviceChange(deviceInfo)
    })

    // 初始化当前设备状态
    const connectedDevices = this.audioDeviceMonitorService.getConnectedDevices()
    this.hasExternalDeviceConnected = connectedDevices.length > 0
    if (this.hasExternalDeviceConnected && connectedDevices.length > 0) {
      this.connectedDeviceName = connectedDevices[0].deviceName
    }
  }

  /**
   * 取消设备状态监听器
   */
  private unregisterDeviceChangeListener(): void {
    // 由于回调函数是匿名函数，这里需要重新设计监听器管理
    // 暂时使用空实现，实际项目中应该维护回调函数引用
  }

  /**
   * 处理设备状态变化
   * @param deviceInfo 设备信息
   */
  private handleDeviceChange(deviceInfo: AudioDeviceInfo): void {
    this.hasExternalDeviceConnected = deviceInfo.connectionState === 0 // CONNECTED = 0
    if (this.hasExternalDeviceConnected) {
      this.connectedDeviceName = deviceInfo.deviceName
    } else {
      this.connectedDeviceName = ''
    }

    console.info(`[DEVICE_CHANGE] 外置设备${this.hasExternalDeviceConnected ? '接入' :
      '断开'}: ${deviceInfo.deviceName}`)
  }
}