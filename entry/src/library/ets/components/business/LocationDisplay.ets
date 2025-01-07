import promptAction from '@ohos.promptAction';
import { LocationService, LocationInfo } from '../../services/LocationService';
import common from '@ohos.app.ability.common';
import { PermissionUtil } from '@pura/harmony-utils';
import { PreferenceService } from '../../services/PreferenceService';
import { LocationStateMachine } from '../../services/LocationStateMachine';
import { LocationState } from '../../constants/LocationStateEnum';

/**
 * 图标配置接口
 */
interface IconOptions {
  size?: number;
  color?: string;
  isRefreshing?: boolean;
}

@ComponentV2
export struct LocationDisplay {
  @Local location: string = '正在获取位置...';
  @Local address: string = '';
  @Local locationState: LocationState = LocationState.DISABLED;
  @Local isEnabled: boolean = false;
  private locationService: LocationService = LocationService.getInstance();
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  private locationStateMachine: LocationStateMachine = LocationStateMachine.getInstance();

  private get isRefreshing(): boolean {
    return this.locationState === LocationState.LOCATING;
  }

  async aboutToAppear() {
    await this.locationStateMachine.init(getContext(this));
    this.updateState();
    
    // 监听状态变化
    this.locationStateMachine.onStateChange((state: LocationState) => {
      this.updateState();
      // 只有在启用状态下才自动刷新位置
      if (this.isEnabled && state === LocationState.ENABLED) {
        this.startSingleLocation();
      }
    });
  }

  private updateState() {
    this.locationState = this.locationStateMachine.getState();
    this.isEnabled = this.locationStateMachine.isEnabled();
  }

  async startSingleLocation() {
    try {
      await this.locationStateMachine.startLocating();
      this.updateState();
      // 重置显示状态
      this.location = '正在获取位置...';
      this.address = '正在获取位置信息...';

      const locationInfo: LocationInfo = await this.locationService.requestSingleLocation();
      this.location = locationInfo.coordinates;
      this.address = locationInfo.address;
      await this.locationStateMachine.finishLocating();
    } catch (error) {
      console.error('Failed to request location:', error.message);
      this.location = '未获取到位置信息';
      this.address = '请稍后重试';
      await this.locationStateMachine.failLocating();
    } finally {
      this.updateState();
    }
  }

  aboutToDisappear() {
    this.locationStateMachine.destroy();
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
        .map(num =>!isNaN(num) ? num.toFixed(2) : '')
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
            .margin({ right: 8, left: -8 })
          } else {
            Column() {
              this.LocationIcon({
                size: 16,
                color: '#666666'
              })
            }
            .width(24)
            .height(24)
            .justifyContent(FlexAlign.Center)
            .margin({ right: 4, left: -8 })
          }

          Text('位置')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#000000')

          if (this.isEnabled) {
            Text(this.formatLocation(this.location))
              .fontSize(14)
              .fontColor('#666666')
              .margin({ left: 8 })
          } else {
            Text('已关闭')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ left: 4 })
          }
        }

        Blank()

        Toggle({ type: ToggleType.Switch, isOn: this.isEnabled })
          .selectedColor('#0091FF')
          .switchPointColor('#FFFFFF')
          .enabled(!this.isRefreshing)
          .margin({ right: -2 })
          .onChange(async () => {
            await this.locationStateMachine.toggle();
          })
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)

      if (this.isEnabled) {
        Row() {
          Text(this.address || '正在获取位置信息...')
            .fontSize(14)
            .fontColor('#666666')
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
          .margin({ top: 4, left: -4 })
          .textAlign(TextAlign.Start)
          .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
  }
}