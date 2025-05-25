import promptAction from '@ohos.promptAction';
import { LocationService, LocationInfo } from '../../services/LocationService';
import { PreferenceService, PreferenceChangeListener, PreferenceValue } from '../../services/PreferenceService';
import { PreferenceKeyConstants } from '../../constants/PreferenceKeyConstants';
import { Theme } from '../../utils/Theme';

@ComponentV2
export struct LocationDisplay {
  @Local location: string = '正在获取位置...';
  @Local address: string = '';
  @Local isEnabled: boolean = false;
  @Local isRefreshing: boolean = false;
  private locationService: LocationService = LocationService.getInstance();
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  private locationListener?: PreferenceChangeListener;

  async aboutToAppear() {
    this.preferenceService = PreferenceService.getInstance();
    
    // 获取位置开关状态
    this.isEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.LOCATION, true);
    
    // 如果位置开关是打开的,自动获取位置信息
    if (this.isEnabled) {
      this.startSingleLocation();
    }

    // 使用新的监听方式
    this.locationListener = (key: string, value: PreferenceValue): void => {
      if (key === PreferenceKeyConstants.LOCATION) {
        const newEnabled = this.preferenceService.getBoolean(PreferenceKeyConstants.LOCATION, true);
        if (newEnabled !== this.isEnabled) {
          this.isEnabled = newEnabled;
          if (this.isEnabled) {
            // 开启时自动刷新位置
            this.startSingleLocation();
          } else {
            // 关闭时清空位置信息和缓存
            this.address = '开启位置服务可记录噪音检测位置';
            this.locationService.clearCache();
          }
        }
      }
    };
    
    this.preferenceService.addChangeListener(PreferenceKeyConstants.LOCATION, this.locationListener);
  }

  private async showLocationServiceDialog(): Promise<boolean> {
    const result = await promptAction.showDialog({
      title: '开启定位服务',
      message: '开启定位服务可以记录噪音检测的位置信息',
      buttons: [
        {
          text: '取消',
          color: Theme.getColor('text_secondary')
        },
        {
          text: '去开启',
          color: Theme.getColor('button_primary')
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
    // 移除监听器
    if (this.locationListener) {
      this.preferenceService.removeChangeListener(PreferenceKeyConstants.LOCATION, this.locationListener);
    }
  }

  build() {
    Row() {
      if (this.isEnabled) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Row() {
            Image($r('app.media.ic_refresh'))
              .width(16)
              .height(16)
              .fillColor(Theme.getColor('text_secondary'))
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
        .backgroundColor(Theme.getColor('button_secondary'))
        .enabled(!this.isRefreshing)
        .onClick(() => {
          this.startSingleLocation();
        })
        .margin({ right: 8 })
      }

      Text(this.isEnabled ? (this.address || '点击刷新按钮获取位置') : '开启位置服务可记录噪音检测位置')
        .fontSize(14)
        .fontColor(Theme.getColor('text_secondary'))
        .textAlign(TextAlign.Center)
        .layoutWeight(1)
    }
    .width('100%')
    .height(40)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
} 