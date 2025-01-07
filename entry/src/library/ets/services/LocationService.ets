import common from '@ohos.app.ability.common';
import { LocationUtil } from '@pura/harmony-utils';
import geoLocationManager from '@ohos.geoLocationManager';

/**
 * 位置信息
 */
export interface LocationInfo {
  coordinates: string;
  address: string;
}

/**
 * 位置服务
 */
export class LocationService {
  private static instance: LocationService;
  private cachedLocation: LocationInfo | null = null;

  private constructor() {}

  public static getInstance(): LocationService {
    if (!LocationService.instance) {
      LocationService.instance = new LocationService();
    }
    return LocationService.instance;
  }

  public async init(context: common.Context): Promise<void> {
    // LocationUtil不需要初始化
  }

  /**
   * 检查定位服务是否开启
   */
  public checkLocationEnabled(): boolean {
    return LocationUtil.isLocationEnabled();
  }

  /**
   * 请求定位权限
   */
  public async requestLocationPermission(): Promise<boolean> {
    return await LocationUtil.requestLocationPermissions();
  }

  /**
   * 请求单次定位
   */
  public async requestSingleLocation(): Promise<LocationInfo> {
    try {
      const location = await LocationUtil.getCurrentLocationEasy();
      const geoAddress = await LocationUtil.getAddressFromLocation(location.latitude, location.longitude);
      this.cachedLocation = {
        coordinates: `${location.latitude},${location.longitude}`,
        address: geoAddress.placeName || ''
      };
      return this.cachedLocation;
    } catch (error) {
      this.cachedLocation = {
        coordinates: '未获取到位置信息',
        address: '请稍后重试'
      };
      throw new Error('获取位置信息失败');
    }
  }

  /**
   * 获取缓存的位置信息
   */
  public getCachedLocation(): LocationInfo | null {
    return this.cachedLocation;
  }

  /**
   * 停止定位
   */
  public stopLocation(): void {
    LocationUtil.offLocationChange(true);
  }
}