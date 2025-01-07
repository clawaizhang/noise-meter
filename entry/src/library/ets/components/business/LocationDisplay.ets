import promptAction from '@ohos.promptAction';
import { LocationService, LocationInfo } from '../../services/LocationService';
import common from '@ohos.app.ability.common';
import { PermissionUtil } from '@pura/harmony-utils';
import { PreferenceService } from '../../services/PreferenceService';
import { PreferenceKeyConstants } from '../../constants/PreferenceKeyConstants';

@ComponentV2
export struct LocationDisplay {
  @Local location: string = '正在获取位置...';
  @Local address: string = '';
  @Local isEnabled: boolean = false;
  @Local isRefreshing: boolean = false;
  private locationService: LocationService = LocationService.getInstance();
  private preferenceService: PreferenceService = PreferenceService.getInstance();

  async aboutToAppear() {
    // 获取位置开关状态
    this.isEnabled = this.preferenceService.isEnabled(PreferenceKeyConstants.LOCATION);
    
    // 如果位置开关是打开的,自动获取位置信息
    if (this.isEnabled) {
      this.startSingleLocation();
    }
    
    // 监听位置开关状态变化
    this.preferenceService.subscribe((key: string) => {
      if (key === PreferenceKeyConstants.LOCATION) {
        const newEnabled = this.preferenceService.isEnabled(PreferenceKeyConstants.LOCATION);
        if (newEnabled !== this.isEnabled) {
          this.isEnabled = newEnabled;
          if (this.isEnabled) {
            // 开启时自动刷新位置
            this.startSingleLocation();
          } else {
            // 关闭时清空位置信息
            this.address = '请在设置中开启位置服务';
          }
        }
      }
    });
  }

  private async showLocationServiceDialog(): Promise<boolean> {
    const result = await promptAction.showDialog({
      title: '定位服务未开启',
      message: '请在系统设置中开启定位服务，以便获取位置信息',
      buttons: [
        {
          text: '取消',
          color: '#666666'
        },
        {
          text: '去设置',
          color: '#0091FF'
        }
      ]
    });
    return result.index === 1;
  }

  async startSingleLocation() {
    if (!this.isEnabled || this.isRefreshing) {
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
          this.address = '请开启系统定位服务';
          return;
        }
        // 用户同意去设置后，再次检查服务状态
        if (!this.locationService.checkLocationEnabled()) {
          this.address = '请开启系统定位服务';
          return;
        }
      }

      // 检查定位权限
      const hasPermission = await this.locationService.requestLocationPermission();
      if (!hasPermission) {
        this.address = '请授予位置权限';
        return;
      }

      // 获取位置信息
      const locationInfo: LocationInfo = await this.locationService.requestSingleLocation();
      this.address = locationInfo.address;
    } catch (error) {
      console.error('Failed to request location:', error.message);
      this.address = '获取位置失败,请稍后重试';
    } finally {
      this.isRefreshing = false;
    }
  }

  aboutToDisappear() {
    // 取消订阅状态变更
    this.preferenceService.unsubscribe();
  }

  build() {
    Row() {
      if (this.isEnabled) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Row() {
            Image($r('app.media.ic_refresh'))
              .width(16)
              .height(16)
              .fillColor('#666666')
              .rotate({
                angle: this.isRefreshing ? 360 : 0,
                centerX: '50%',
                centerY: '50%'
              })
              .animation({
                duration: this.isRefreshing ? 1000 : 0,
                iterations: this.isRefreshing ? -1 : 0,
                curve: Curve.Linear
              })
          }
        }
        .width(20)
        .height(20)
        .backgroundColor('#F5F5F5')
        .enabled(!this.isRefreshing)
        .onClick(() => {
          this.startSingleLocation();
        })
        .margin({ right: 8 })
      }

      Text(this.isEnabled ? (this.address || '点击刷新按钮获取位置') : '请在设置中开启位置服务')
        .fontSize(14)
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .layoutWeight(1)
    }
    .width('100%')
    .height(40)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
} 