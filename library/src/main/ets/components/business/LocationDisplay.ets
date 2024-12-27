import { AMapLocationManagerImpl, AMapLocationType, AMapLocation, AMapLocationErrorInfo, AMapLocationOption, AMapLocationReGeocodeLanguage } from '@amap/amap_lbs_location';
import { AMapPrivacyAgreeStatus, AMapPrivacyInfoStatus, AMapPrivacyShowStatus } from '@amap/amap_lbs_common';
import { PermissionUtil } from '@pura/harmony-utils';
import geoLocationManager from '@ohos.geoLocationManager';

/**
 * 位置显示组件的样式配置
 */
export interface LocationStyle {
  /** 背景颜色 */
  backgroundColor?: string;
  /** 文字颜色 */
  textColor?: string;
  /** 按钮颜色 */
  buttonColor?: string;
  /** 图标颜色 */
  iconColor?: string;
}

@Component
export struct LocationDisplay {
  @State location: string = '正在获取位置...';
  @State address: string = '';
  @State isRefreshing: boolean = false;
  private locationManager?: AMapLocationManagerImpl;
  @Prop style?: LocationStyle;

  private getLocationOptions(): AMapLocationOption {
    return {
      priority: geoLocationManager.LocationRequestPriority.FIRST_FIX, // 定位优先级：首次定位优先
      scenario: geoLocationManager.LocationRequestScenario.UNSET,    // 定位场景：默认
      maxAccuracy: 0,                                               // 定位精度：最高精度
      singleLocationTimeout: 8000,                                  // 单次定位超时时间：8秒
      locatingWithReGeocode: true,                                  // 返回逆地理信息
      reGeocodeLanguage: AMapLocationReGeocodeLanguage.Chinese,     // 逆地理编码语言：中文
      isOffset: true                                                // 偏移：开启偏移
    }
  }

  async aboutToAppear() {
    // 请求位置权限
    const hasPermission = await this.requestLocationPermission();
    if (!hasPermission) {
      this.location = '缺少位置权限';
      this.address = '请授予位置权限以使用定位功能';
      return;
    }

    // 设置Key
    AMapLocationManagerImpl.setApiKey("7dd65efe926c70f43ab42a7686cd8140");

    // 初始化隐私政策
    AMapLocationManagerImpl.updatePrivacyShow(AMapPrivacyShowStatus.DidShow, AMapPrivacyInfoStatus.DidContain, getContext(this));
    AMapLocationManagerImpl.updatePrivacyAgree(AMapPrivacyAgreeStatus.DidAgree, getContext(this));

    // 初始化定位管理器
    this.locationManager = new AMapLocationManagerImpl(getContext(this));
    
    // 设置定位参数
    const options = this.getLocationOptions();
    this.locationManager?.setLocationOption(AMapLocationType.Single, options);
    
    // 设置定位监听器
    this.locationManager?.setLocationListener(AMapLocationType.Single, {
      onLocationChanged: (location: AMapLocation) => {
        // 定位成功
        this.location = `${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)}`;
        if (location.reGeo) {
          const address = [
            location.reGeo.province,
            location.reGeo.city,
            location.reGeo.district,
            location.reGeo.street,
            location.reGeo.poiName
          ].filter(Boolean).join('');
          this.address = address || '未获取到详细地址';
        } else {
          this.address = '未获取到详细地址';
        }
        this.isRefreshing = false;
      },
      onLocationError: (errorInfo: AMapLocationErrorInfo) => {
        // 定位失败
        this.location = '定位失败';
        this.address = `错误码: ${errorInfo.errorCode}, ${errorInfo.errorMsg}`;
        console.error('Location failed:', errorInfo);
        this.isRefreshing = false;
      }
    });
    // 开始单次定位
    this.startSingleLocation();
  }

  private async requestLocationPermission(): Promise<boolean> {
    try {
      // 检查位置权限
      const hasPermission = await PermissionUtil.checkPermissions('ohos.permission.LOCATION');
      if (hasPermission) {
        return true;
      }

      // 请求位置权限
      const granted = await PermissionUtil.requestPermissions(['ohos.permission.APPROXIMATELY_LOCATION','ohos.permission.LOCATION']);
      return granted;
    } catch (error) {
      console.error('Failed to request location permission:', error.message);
      return false;
    }
  }

  async startSingleLocation() {
    if (!this.locationManager) {
      return;
    }

    // 检查权限
    const hasPermission = await this.requestLocationPermission();
    if (!hasPermission) {
      this.location = '缺少位置权限';
      this.address = '请授予位置权限以使用定位功能';
      return;
    }

    try {
      this.isRefreshing = true;
      this.locationManager.requestSingleLocation();
    } catch (error) {
      console.error('Failed to request location:', error.message);
      this.location = '定位异常';
      this.address = error.message;
      this.isRefreshing = false;
    }
  }

  aboutToDisappear() {
    // 组件销毁时释放资源
    if (this.locationManager) {
      this.locationManager.stopUpdatingLocation();  // 停止定位更新
      this.locationManager = undefined;
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_location'))
          .width(24)
          .height(24)
          .margin({ right: 8 })
          .fillColor(this.style?.iconColor ?? '#666666')
        Text('当前位置')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.style?.textColor ?? '#000000')
      }
      .width('100%')
      .margin({ bottom: 12 })

      Text(this.location)
        .fontSize(14)
        .fontColor(this.style?.textColor ?? '#666666')
        .margin({ bottom: 4 })
        .textAlign(TextAlign.Start)
        .width('100%')

      if (this.address) {
        Text(this.address)
          .fontSize(14)
          .fontColor(this.style?.textColor ?? '#666666')
          .margin({ top: 4 })
          .textAlign(TextAlign.Start)
          .width('100%')
      }

      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Row() {
          if (this.isRefreshing) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(Color.White)
              .margin({ right: 8 })
          }
          Text(this.isRefreshing ? '正在刷新...' : '刷新位置')
            .fontSize(16)
            .fontColor(Color.White)
        }
      }
      .width(140)
      .height(44)
      .margin({ top: 16 })
      .borderRadius(22)
      .backgroundColor(this.isRefreshing ? '#999999' : (this.style?.buttonColor ?? '#007DFF'))
      .enabled(!this.isRefreshing)
      .onClick(() => {
        this.startSingleLocation();
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.style?.backgroundColor ?? Color.White)
  }
} 