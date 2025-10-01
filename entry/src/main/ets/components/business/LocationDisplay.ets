import promptAction from '@ohos.promptAction';
import { LocationService, LocationInfo } from '../../services/LocationService';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2 } from '@kit.ArkUI';

@ComponentV2
export struct LocationDisplay {
  @Local location: string = '正在获取位置...';
  @Local address: string = '';
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local isRefreshing: boolean = false;
  private locationService: LocationService = LocationService.getInstance();
  
  // 位置更新事件
  @Event onLocationUpdate: (locationInfo: LocationInfo | null) => void = () => {}

  @Monitor('pk.location_enabled')
  onLocationEnabledChange(monitor: IMonitor) {
    const beforeEnabled = monitor.value<boolean>()?.before;
    const newEnabled = monitor.value<boolean>()?.now;
    if (newEnabled !== beforeEnabled) {
      if (newEnabled) {
        // 开启时自动刷新位置
        this.startSingleLocation();
      } else {
        // 关闭时清空位置信息和缓存，并发射null事件
        this.address = '开启位置服务可记录噪音检测位置';
        this.locationService.clearCache();
        // 发射位置服务关闭事件
        this.onLocationUpdate(null);
      }
    }
  }

  async aboutToAppear() {

    // 如果位置开关是打开的,自动获取位置信息
    if (this.pk.location_enabled) {
      this.startSingleLocation();
    } else {
      // 位置服务关闭时发射null事件
      this.onLocationUpdate(null);
    }

  }

  private async showLocationServiceDialog(): Promise<boolean> {
    const result = await promptAction.showDialog({
      title: '开启定位服务',
      message: '开启定位服务可以记录噪音检测的位置信息',
      buttons: [
        {
          text: '取消',
          color: $r('app.color.text_secondary')
        },
        {
          text: '去开启',
          color: $r('app.color.button_primary')
        }
      ]
    });
    return result.index === 1;
  }

  async startSingleLocation() {
    if (!this.pk.location_enabled || this.isRefreshing) {
      return;
    }

    try {
      this.isRefreshing = true;
      this.address = '正在获取位置信息...';

      // 检查定位服务是否开启
      const isServiceEnabled = this.locationService.checkLocationEnabled();
      if (!isServiceEnabled) {
        // 显示设置对话框
        const shouldOpenSettings = await this.showLocationServiceDialog();
        if (!shouldOpenSettings) {
          this.address = '开启系统定位服务可获取位置信息';
          return;
        }
        // 用户同意去设置后，再次检查服务状态
        if (!this.locationService.checkLocationEnabled()) {
          this.address = '开启系统定位服务可获取位置信息';
          return;
        }
      }

      // 检查定位权限
      const hasPermission = await this.locationService.requestLocationPermission();
      if (!hasPermission) {
        this.address = '授予位置权限可获取位置信息';
        this.pk.location_enabled = false;
        return;
      }

      // 获取位置信息
      const locationInfo: LocationInfo = await this.locationService.requestSingleLocation();
      this.address = locationInfo.address;
      // 发射位置更新事件
      this.onLocationUpdate(locationInfo);
    } catch (error) {
      console.error('Failed to request location:', error.message);
      this.address = '获取位置失败,请稍后重试';
      // 发射位置获取失败事件
      this.onLocationUpdate(null);
    } finally {
      this.isRefreshing = false;
    }
  }

  aboutToDisappear() {

  }

  build() {
    Row() {
      if (this.pk.location_enabled) {
        this.refreshButton()
      }

      Text(this.pk.location_enabled ? (this.address || '点击刷新按钮获取位置') : '开启位置服务可记录噪音检测位置')
        .textAlign(TextAlign.Center).textOverflow({ overflow: TextOverflow.MARQUEE })
    }

    .height(40)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  refreshButton() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Image($r('app.media.ic_refresh'))
        .width(16)
        .height(16)
        .fillColor($r('sys.color.icon_secondary'))
        .rotate({
          angle: this.isRefreshing ? 360 : 0,
          centerX: '50%',
          centerY: '50%'
        })
        .animation({
          duration: this.isRefreshing ? 1000 : 0,
          iterations: this.isRefreshing ? -1 : 0,
          curve: Curve.Linear
        });
    }
    .width(20)
    .height(20)
    .backgroundColor($r('sys.color.background_secondary'))
    .enabled(!this.isRefreshing)
    .onClick(() => {
      this.startSingleLocation();
    })
  }
}