import { AMapLocationManagerImpl, AMapLocationType, AMapLocation, AMapLocationErrorInfo, AMapLocationOption, AMapLocationReGeocodeLanguage } from '@amap/amap_lbs_location';
import { AMapPrivacyAgreeStatus, AMapPrivacyInfoStatus, AMapPrivacyShowStatus } from '@amap/amap_lbs_common';
import { PermissionUtil } from '@pura/harmony-utils';
import geoLocationManager from '@ohos.geoLocationManager';
import promptAction from '@ohos.promptAction';

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

/**
 * 图标配置接口
 */
interface IconOptions {
  size?: number;
  color?: string;
  isRefreshing?: boolean;
}

@Component
export struct LocationDisplay {
  @State location: string = '正在获取位置...';
  @State address: string = '';
  @State isRefreshing: boolean = false;
  @State isLocationEnabled: boolean = false;  // 添加位置开关状态
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

  @Builder
  LocationIcon(options: IconOptions) {
    Stack() {
      // 定位图标外圈
      Circle()
        .width(options?.size ?? 24)
        .height(options?.size ?? 24)
        .stroke(options?.color ?? '#666666')
        .strokeWidth(2)
        .fill('none')
      
      // 定位图标中心点
      Circle()
        .width((options?.size ?? 24) * 0.4)
        .height((options?.size ?? 24) * 0.4)
        .fill(options?.color ?? '#666666')
    }
  }

  @Builder
  RefreshIcon(options: IconOptions) {
    Row() {
      Image($r('app.media.ic_refresh'))
        .width(16)
        .height(16)
        .fillColor(options?.color ?? '#FFFFFF')
        .objectFit(ImageFit.Contain)
        .rotate({
          angle: options?.isRefreshing ? 360 : 0,
          centerX: '50%',
          centerY: '50%'
        })
        .animation(options?.isRefreshing ? {
          duration: 1000,
          curve: Curve.EaseInOut,
          iterations: -1,
          playMode: PlayMode.Normal
        } : undefined)
    }
    .width(16)
    .height(16)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  RefreshButton() {
    Row() {
      if (this.isRefreshing) {
        LoadingProgress()
          .width(16)
          .height(16)
          .color('#FFFFFF')
          .backgroundColor('transparent')
          .margin({ right: 4 })
      } else {
        Row() {
          this.RefreshIcon({
            color: '#FFFFFF',
            isRefreshing: this.isRefreshing
          })
        }
        .margin({ right: 4 })
      }
      Text(this.isRefreshing ? '定位中...' : '刷新位置')
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .fontColor('#FFFFFF')
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
  }

  private async showPermissionDialog(): Promise<void> {
    try {
      await promptAction.showDialog({
        title: '需要位置权限',
        message: '请在系统设置中开启位置权限，以便获取位置信息',
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
      }).then(async (result) => {
        if (result.index === 1) {
          // 使用 PermissionUtil 拉起系统二次授权
          await PermissionUtil.requestPermissionsEasy(['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION']).then((granted) => {
            if (granted) {
              // 如果用户授予了权限，开启开关并开始定位
              this.isLocationEnabled = true;
              this.startSingleLocation();
            } else {
              // 如果用户在系统授权弹窗中拒绝，保持开关关闭
              this.isLocationEnabled = false;
            }
          });
        } else {
          // 用户点击取消按钮，保持开关关闭
          this.isLocationEnabled = false;
        }
      });
    } catch (error) {
      console.error('Failed to show permission dialog:', error);
      // 发生错误时也保持开关关闭
      this.isLocationEnabled = false;
    }
  }

  build() {
    Column() {
      Row() {
        Row() {
          Column() {
            this.LocationIcon({
              size: 24,
              color: this.style?.iconColor ?? '#666666'
            })
          }
          .margin({ right: 8 })
          
          Text('当前位置')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.style?.textColor ?? '#000000')
        }

        Blank()

        Toggle({ type: ToggleType.Switch, isOn: this.isLocationEnabled })
          .selectedColor('#0091FF')
          .switchPointColor('#FFFFFF')
          .onChange(async (isOn: boolean) => {
            // 先设置开关状态
            this.isLocationEnabled = isOn;
            
            if (isOn) {
              // 开启时请求权限并获取位置
              const hasPermission = await this.requestLocationPermission();
              if (hasPermission) {
                this.startSingleLocation();
              } else {
                // 如果权限被拒绝，显示权限提示对话框并关闭开关
                this.isLocationEnabled = false;
                this.showPermissionDialog();
              }
            } else {
              // 停止定位
              if (this.locationManager) {
                this.locationManager.stopUpdatingLocation();
              }
            }
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.isLocationEnabled) {
        // 只在开启状态显示位置信息
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
          this.RefreshButton()
        }
        .width(110)
        .height(32)
        .margin({ top: 16 })
        .borderRadius(16)
        .backgroundColor(this.isRefreshing ? '#0091FF' : '#0091FF')
        .enabled(!this.isRefreshing)
        .onClick(() => {
          this.startSingleLocation();
        })
        .animation({
          duration: 250,
          curve: Curve.EaseInOut,
          iterations: 1,
          playMode: PlayMode.Normal
        })
        .scale({
          x: this.isRefreshing ? 0.98 : 1,
          y: this.isRefreshing ? 0.98 : 1
        })
      } else {
        // 关闭状态显示提示文本
        Text('开启后可查看位置信息')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 4 })
          .textAlign(TextAlign.Start)
          .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.style?.backgroundColor ?? '#FFFFFF')
  }
} 