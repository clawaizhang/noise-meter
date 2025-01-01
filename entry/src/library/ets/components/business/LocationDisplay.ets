import promptAction from '@ohos.promptAction';
import { LocationService, LocationInfo } from '../../services/LocationService';
import common from '@ohos.app.ability.common';
import { PermissionUtil } from '@pura/harmony-utils';

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
  @State isLocationEnabled: boolean = false;
  private locationService: LocationService = LocationService.getInstance();
  @Prop style?: LocationStyle;

  async aboutToAppear() {
    await this.locationService.init(getContext(this));
    // 不再在初始化时检查并设置定位服务状态
    this.isLocationEnabled = false;
    this.location = '开启定位服务可查看位置信息';
    this.address = '';
  }

  async startSingleLocation() {
    try {
      // 先检查定位服务是否开启
      const isServiceEnabled = await this.locationService.checkLocationEnabled();
      if (!isServiceEnabled) {
        // 如果定位服务未开启，确保开关关闭
        this.isLocationEnabled = false;
        // 示开启定位服务对话框
        await this.showLocationServiceDialog();
        // 再次检查定位服务状态
        const isEnabled = await this.locationService.checkLocationEnabled();
        if (!isEnabled) {
          this.isLocationEnabled = false;
          return;
        }
      }

      // 检查定位权限
      const hasPermission = await this.locationService.requestLocationPermission();
      if (!hasPermission) {
        this.isLocationEnabled = false;
        this.location = '缺少位置权限';
        this.address = '请授予位置权限以使用定位功能';
        return;
      }

      this.isRefreshing = true;
      const locationInfo: LocationInfo = await this.locationService.requestSingleLocation();
      this.location = locationInfo.coordinates;
      this.address = locationInfo.address;
      this.isLocationEnabled = true;
    } catch (error) {
      console.error('Failed to request location:', error.message);
      this.location = '定位异常';
      this.address = error.message;
      this.isLocationEnabled = false;
    } finally {
      this.isRefreshing = false;
    }
  }

  private async showLocationServiceDialog(): Promise<void> {
    try {
      // 获取当前Context
      const context = getContext(this) as common.UIAbilityContext;

      try {
        // 请求开启定位服务
        const result = await this.locationService.requestLocationService(context);
        // 无论结果如何，都重新检查定位服务状态
        const isEnabled = await this.locationService.checkLocationEnabled();
        if (!isEnabled) {
          this.isLocationEnabled = false;
          return;
        }

        if (result) {
          // 如果用户同意开启定位服务，重新检查并开始定位
          const hasPermission = await this.locationService.requestLocationPermission();
          if (hasPermission) {
            this.isLocationEnabled = true;
            this.startSingleLocation();
          } else {
            this.isLocationEnabled = false;
          }
        } else {
          this.isLocationEnabled = false;
        }
      } catch (err) {
        console.error('请求开启定位服务失败:', JSON.stringify(err));
        this.isLocationEnabled = false;
        // 如果发生错误，显示设置对话框
        await promptAction.showDialog({
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
        }).then(async (result) => {
          if (result.index === 1) {
            try {
              // 使用新的API重新请求开启定位服务
              await this.locationService.requestLocationService(context);
              // 再次检查定位服务是否真的开启
              const isEnabled = await this.locationService.checkLocationEnabled();
              if (!isEnabled) {
                this.isLocationEnabled = false;
                return;
              }

              // 如果定位服务已开启，继续请求权限
              const hasPermission = await this.locationService.requestLocationPermission();
              if (hasPermission) {
                this.isLocationEnabled = true;
                this.startSingleLocation();
              } else {
                this.isLocationEnabled = false;
              }
            } catch (error) {
              console.error('跳转到系统设置页面失败:', error);
              this.isLocationEnabled = false;
            }
          } else {
            this.isLocationEnabled = false;
          }
        });
      }
    } catch (error) {
      console.error('显示定位服务对话框失败:', error);
      this.isLocationEnabled = false;
    }
  }

  aboutToDisappear() {
    this.locationService.destroy();
  }

  @Builder
  LocationIcon(options: IconOptions) {
    Stack() {
      Circle()
        .width(16)
        .height(16)
        .stroke(options?.color ?? '#666666')
        .strokeWidth(2)
        .fill('none')

      Circle()
        .width(6)
        .height(6)
        .fill(options?.color ?? '#666666')
    }
  }

  @Builder
  RefreshIcon(options: IconOptions) {
    Row() {
      Image($r('app.media.ic_refresh'))
        .width(16)
        .height(16)
        .fillColor(options?.color ?? '#666666')
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

  private formatLocation(location: string): string {
    if (!location || !location.includes(',')) {
      return '';
    }
    try {
      const coords = location.split(',');
      const lat = Number(coords[0]);
      const lng = Number(coords[1]);
      const formattedLocation = [lat, lng]
        .map(num => !isNaN(num) ? num.toFixed(2) : '')
        .filter(Boolean)
        .join(',');
      return formattedLocation;
    } catch (error) {
      console.error('格式化位置信息失败:', error);
      return '';
    }
  }

  build() {
    Column() {
      Row() {
        Row() {
          if (this.isLocationEnabled) {
            Button({ type: ButtonType.Circle, stateEffect: true }) {
              Row() {
                Image($r('app.media.ic_refresh'))
                  .width(16)
                  .height(16)
                  .fillColor(this.style?.iconColor ?? '#666666')
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
            .width(24)
            .height(24)
            .backgroundColor(this.style?.buttonColor ?? '#F5F5F5')
            .enabled(!this.isRefreshing)
            .onClick(() => {
              this.startSingleLocation();
            })
            .margin({ right: 8, left: -4 })
          } else {
            Column() {
              this.LocationIcon({
                size: 16,
                color: this.style?.iconColor ?? '#666666'
              })
            }
            .width(24)
            .height(24)
            .justifyContent(FlexAlign.Center)
            .margin({ right: 8, left: -4 })
          }

          Text('当前位置')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.style?.textColor ?? '#000000')

          if (this.isLocationEnabled && this.location) {
            Text(this.formatLocation(this.location))
              .fontSize(14)
              .fontColor(this.style?.textColor ?? '#666666')
              .margin({ left: 8 })
          }
        }

        Blank()

        Toggle({ type: ToggleType.Switch, isOn: $$this.isLocationEnabled })
          .selectedColor('#0091FF')
          .switchPointColor('#FFFFFF')
          .enabled(!this.isRefreshing)
          .margin({ right: -2 })
          .onChange(async (isOn: boolean) => {
            if (isOn) {
              // 先检查定位服务是否开启
              const isServiceEnabled = await this.locationService.checkLocationEnabled();
              if (!isServiceEnabled) {
                // 显示开启定位服务对话框
                this.isLocationEnabled = false;  // 确保开关保持关闭
                await this.showLocationServiceDialog();
                return;
              }

              // 如果定位服务已开启，请求定位权限
              const hasPermission = await this.locationService.requestLocationPermission();
              if (hasPermission) {
                this.isLocationEnabled = true;
                this.startSingleLocation();
              } else {
                this.isLocationEnabled = false;  // 确保开关保持关闭
                // 如果权限被拒绝，显示权限请求对话框
                await promptAction.showDialog({
                  title: '需要位置权限',
                  message: '请授予位置权限，以便获取位置信息',
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
                  this.isLocationEnabled = false;  // 确保开关保持关闭
                  if (result.index === 1) {
                    try {
                      // 使用PermissionUtil拉起系统权限设置页面
                      await PermissionUtil.requestPermissionsEasy(['ohos.permission.APPROXIMATELY_LOCATION',
                        'ohos.permission.LOCATION']).then(async (granted: boolean) => {
                        if (granted) {
                          this.isLocationEnabled = true;
                          this.startSingleLocation();
                        } else {
                          this.isLocationEnabled = false;  // 确保开关保持关闭
                          this.location = '缺少位置权限';
                          this.address = '请授予位置权限以使用定位功能';
                        }
                      });
                    } catch (error) {
                      console.error('跳转到权限设置页面失败:', error);
                      this.isLocationEnabled = false;  // 确保开关保持关闭
                      this.location = '缺少位置权限';
                      this.address = '请授予位置权限以使用定位功能';
                    }
                  } else {
                    // 用户点击取消
                    this.isLocationEnabled = false;  // 确保开关保持关闭
                    this.location = '缺少位置权限';
                    this.address = '请授予位置权限以使用定位功能';
                  }
                });
              }
            } else {
              this.isLocationEnabled = false;
              this.locationService.stopLocation();
            }
          })
      }
      .width('100%')
      .height(48)

      if (this.isLocationEnabled) {
        Row() {
          Text(this.address || '正在获取位置信息...')
            .fontSize(14)
            .fontColor(this.style?.textColor ?? '#666666')
            .textAlign(TextAlign.Start)
            .layoutWeight(1)
            .textOverflow({ overflow: TextOverflow.None })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ top: 4 })
      } else {
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