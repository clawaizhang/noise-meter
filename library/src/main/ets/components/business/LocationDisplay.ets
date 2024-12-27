import { AMapLocationManagerImpl, AMapLocationType, AMapLocation, AMapLocationErrorInfo } from '@amap/amap_lbs_location';
import { IAMapLocationListener } from '@amap/amap_lbs_location';
import { AMapPrivacyAgreeStatus, AMapPrivacyInfoStatus, AMapPrivacyShowStatus } from '@amap/amap_lbs_common';

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
  private locationManager?: AMapLocationManagerImpl;
  @Prop style?: LocationStyle;

  aboutToAppear() {
    // 设置Key
    AMapLocationManagerImpl.setApiKey("7dd65efe926c70f43ab42a7686cd8140");  // 请替换为您的实际高德地图Key

    // 初始化隐私政策
    AMapLocationManagerImpl.updatePrivacyShow(AMapPrivacyShowStatus.DidShow, AMapPrivacyInfoStatus.DidContain, getContext(this));
    AMapLocationManagerImpl.updatePrivacyAgree(AMapPrivacyAgreeStatus.DidAgree, getContext(this));

    // 获取Index页面传递的locationManager实例
    this.locationManager = new AMapLocationManagerImpl(getContext(this));
    // 设置定位监听器
    this.locationManager?.setLocationListener(AMapLocationType.Single, {
      onLocationChanged: (location: AMapLocation) => {
        // 定位成功
        this.location = `${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)}`;
        // 从reGeo中获取地址信息
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
      },
      onLocationError: (errorInfo: AMapLocationErrorInfo) => {
        // 定位失败
        this.location = '定位失败';
        this.address = `错误码: ${errorInfo.errorCode}, ${errorInfo.errorMsg}`;
        console.error('Location failed:', errorInfo);
      }
    });
    // 开始单次定位
    this.startSingleLocation();
  }

  startSingleLocation() {
    if (!this.locationManager) {
      return;
    }

    try {
      this.locationManager.requestSingleLocation();
    } catch (error) {
      console.error('Failed to request location:', error);
      this.location = '定位异常';
      this.address = error.toString();
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

      Button('刷新位置')
        .width(120)
        .height(40)
        .margin({ top: 16 })
        .backgroundColor(this.style?.buttonColor ?? '#007DFF')
        .onClick(() => {
          this.startSingleLocation();
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.style?.backgroundColor ?? Color.White)
  }
} 