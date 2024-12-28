import geoLocationManager from '@ohos.geoLocationManager';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import { PermissionUtil } from '@pura/harmony-utils';

export interface LocationInfo {
  coordinates: string;
  address: string;
}

export class LocationService {
  private static instance: LocationService;

  private constructor() {}

  public static getInstance(): LocationService {
    if (!LocationService.instance) {
      LocationService.instance = new LocationService();
    }
    return LocationService.instance;
  }

  public async init(context: Context) {
    // 不需要特别初始化，直接使用 geoLocationManager
  }

  public async checkLocationEnabled(): Promise<boolean> {
    try {
      const locationEnabled = geoLocationManager.isLocationEnabled();
      return locationEnabled;
    } catch (error) {
      console.error('检查定位服务状态失败:', error);
      return false;
    }
  }

  public async requestLocationService(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestGlobalSwitch(context, abilityAccessCtrl.SwitchType.LOCATION);
      return result;
    } catch (error) {
      console.error('请求开启定位服务失败:', error);
      return false;
    }
  }

  public async requestLocationPermission(): Promise<boolean> {
    try {
      const hasPermission = await PermissionUtil.checkPermissions('ohos.permission.LOCATION');
      if (hasPermission) {
        return true;
      }

      const granted = await PermissionUtil.requestPermissions(['ohos.permission.APPROXIMATELY_LOCATION','ohos.permission.LOCATION']);
      return granted;
    } catch (error) {
      console.error('Failed to request location permission:', error.message);
      return false;
    }
  }

  public async requestSingleLocation(): Promise<LocationInfo> {
    return new Promise(async (resolve, reject) => {
      try {
        // 设置定位请求参数
        const requestInfo: geoLocationManager.LocationRequest = {
          priority: geoLocationManager.LocationRequestPriority.ACCURACY,
          scenario: geoLocationManager.LocationRequestScenario.NAVIGATION,
          timeInterval: 0,
          distanceInterval: 0,
          maxAccuracy: 0
        };

        // 获取位置信息
        const location = await geoLocationManager.getCurrentLocation(requestInfo);
        
        // 获取地理编码信息
        const reverseGeocodeRequest: geoLocationManager.ReverseGeoCodeRequest = {
          latitude: location.latitude,
          longitude: location.longitude,
          maxItems: 1,
          locale: "zh_CN"
        };

        const addresses = await geoLocationManager.getAddressesFromLocation(reverseGeocodeRequest);
        let address = '未获取到详细地址';
        
        if (addresses && addresses.length > 0) {
          const addressParts = [
            addresses[0].countryName,
            addresses[0].administrativeArea,
            addresses[0].locality,
            addresses[0].subLocality,
            addresses[0].roadName,
            addresses[0].premises
          ];

          // 添加具体地点名称
          if (addresses[0].placeName) {
            addressParts.push(addresses[0].placeName);
          }

          // 添加额外的描述信息
          if (addresses[0].descriptions && addresses[0].descriptions.length > 0) {
            addressParts.push(addresses[0].descriptions[0]);
          }

          address = addressParts.filter(Boolean).join('');
        }

        resolve({
          coordinates: `${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)}`,
          address: address
        });
      } catch (error) {
        reject(new Error(`Location failed: ${error.message}`));
      }
    });
  }

  public stopLocation() {
    // 华为Location Kit不需要显式停止单次定位
  }

  public destroy() {
    // 不需要特别清理
  }
} 