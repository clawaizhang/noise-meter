import { LocationUtil, PermissionUtil } from '@pura/harmony-utils';
import { Permissions } from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import geoLocationManager from '@ohos.geoLocationManager';

/**
 * 位置显示组件样式接口
 */
interface LocationStyle {
  iconSize?: number;
  fontSize?: number;
  textColor?: string;
  iconColor?: string;
}

@Component
export struct LocationDisplay {
  @Prop style?: LocationStyle = {};
  @State location: string = '正在获取位置...';
  @State hasLocationPermission: boolean = false;
  @State permissionError: string = '';

  // 默认样式
  private defaultStyle: LocationStyle = {
    iconSize: 20,
    fontSize: 14,
    textColor: '#666666',
    iconColor: '#666666'
  };

  // 权限常量
  private static readonly PERMISSION_LIST: Array<Permissions> = [
    'ohos.permission.LOCATION' as Permissions,
    'ohos.permission.APPROXIMATELY_LOCATION' as Permissions
  ];

  aboutToAppear() {
    this.checkAndRequestPermission();
  }

  aboutToDisappear() {
    // 清理位置监听器
    LocationUtil.offLocationChange();
  }

  private async checkAndRequestPermission() {
    try {
      // 检查所有位置权限
      const hasLocationPermission = await PermissionUtil.checkPermissions(LocationDisplay.PERMISSION_LIST[0]);
      const hasApproxPermission = await PermissionUtil.checkPermissions(LocationDisplay.PERMISSION_LIST[1]);
      
      if (hasLocationPermission && hasApproxPermission) {
        this.hasLocationPermission = true;
        this.permissionError = '';
        await this.getLocation();
        return;
      }

      // 请求权限
      const granted = await PermissionUtil.requestPermissions(LocationDisplay.PERMISSION_LIST);
      if (granted) {
        this.hasLocationPermission = true;
        this.permissionError = '';
        await this.getLocation();
      } else {
        this.updateError('获取位置权限失败，请在设置中手动开启');
      }
    } catch (err) {
      console.error('位置权限检查失败:', JSON.stringify(err));
      this.updateError('位置权限检查失败');
    }
  }

  private updateError(error: string) {
    this.permissionError = error;
    this.hasLocationPermission = false;
    this.location = error;
  }

  private async getLocation() {
    try {
      const location = await LocationUtil.getCurrentLocation();
      this.updateLocation(location);
      
      // 监听位置变化
      LocationUtil.onLocationChangeEasy((location) => {
        this.updateLocation(location);
      });
    } catch (err) {
      console.error('获取位置失败:', JSON.stringify(err));
      this.updateError('获取位置失败');
    }
  }

  private updateLocation(location: geoLocationManager.Location) {
    if (location.latitude !== undefined && location.longitude !== undefined) {
      this.location = `位置: ${location.latitude.toFixed(4)}°, ${location.longitude.toFixed(4)}°`;
    }
  }

  build() {
    Row() {
      // 使用内联SVG代替图片资源
      Path()
        .width(this.style?.iconSize ?? this.defaultStyle.iconSize)
        .height(this.style?.iconSize ?? this.defaultStyle.iconSize)
        .commands('M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z')
        .fill(this.style?.iconColor ?? this.defaultStyle.iconColor)
        .margin({ right: 8 })

      Text(this.location)
        .fontSize(this.style?.fontSize ?? this.defaultStyle.fontSize)
        .fontColor(this.style?.textColor ?? this.defaultStyle.textColor)

      if (this.permissionError || this.location === '获取位置失败') {
        Text('重试')
          .fontSize(this.style?.fontSize ?? this.defaultStyle.fontSize)
          .fontColor('#2196F3')
          .margin({ left: 8 })
          .onClick(() => this.checkAndRequestPermission())
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: 16 })
  }
} 