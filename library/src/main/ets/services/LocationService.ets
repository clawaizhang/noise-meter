import { AMapLocationManagerImpl, AMapLocationType, AMapLocation, AMapLocationErrorInfo, AMapLocationOption, AMapLocationReGeocodeLanguage } from '@amap/amap_lbs_location';
import { AMapPrivacyAgreeStatus, AMapPrivacyInfoStatus, AMapPrivacyShowStatus } from '@amap/amap_lbs_common';
import { PermissionUtil } from '@pura/harmony-utils';
import geoLocationManager from '@ohos.geoLocationManager';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';

export interface LocationInfo {
  coordinates: string;
  address: string;
}

export class LocationService {
  private locationManager?: AMapLocationManagerImpl;
  private static instance: LocationService;

  private constructor() {}

  public static getInstance(): LocationService {
    if (!LocationService.instance) {
      LocationService.instance = new LocationService();
    }
    return LocationService.instance;
  }

  private getLocationOptions(): AMapLocationOption {
    return {
      priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
      scenario: geoLocationManager.LocationRequestScenario.UNSET,
      maxAccuracy: 0,
      singleLocationTimeout: 8000,
      locatingWithReGeocode: true,
      reGeocodeLanguage: AMapLocationReGeocodeLanguage.Chinese,
      isOffset: true
    }
  }

  public async init(context: Context) {
    // 设置Key
    AMapLocationManagerImpl.setApiKey("7dd65efe926c70f43ab42a7686cd8140");

    // 初始化隐私政策
    AMapLocationManagerImpl.updatePrivacyShow(AMapPrivacyShowStatus.DidShow, AMapPrivacyInfoStatus.DidContain, context);
    AMapLocationManagerImpl.updatePrivacyAgree(AMapPrivacyAgreeStatus.DidAgree, context);

    // 初始化定位管理器
    this.locationManager = new AMapLocationManagerImpl(context);
    
    // 设置定位参数
    const options = this.getLocationOptions();
    this.locationManager?.setLocationOption(AMapLocationType.Single, options);
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
    return new Promise((resolve, reject) => {
      if (!this.locationManager) {
        reject(new Error('Location manager not initialized'));
        return;
      }

      this.locationManager.setLocationListener(AMapLocationType.Single, {
        onLocationChanged: (location: AMapLocation) => {
          const coordinates = `${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)}`;
          let address = '未获取到详细地址';
          
          if (location.reGeo) {
            address = [
              location.reGeo.province,
              location.reGeo.city,
              location.reGeo.district,
              location.reGeo.street,
              location.reGeo.poiName
            ].filter(Boolean).join('');
          }

          resolve({ coordinates, address });
        },
        onLocationError: (errorInfo: AMapLocationErrorInfo) => {
          reject(new Error(`Location failed: ${errorInfo.errorCode}, ${errorInfo.errorMsg}`));
        }
      });

      try {
        this.locationManager.requestSingleLocation();
      } catch (error) {
        reject(error);
      }
    });
  }

  public stopLocation() {
    if (this.locationManager) {
      this.locationManager.stopUpdatingLocation();
    }
  }

  public destroy() {
    if (this.locationManager) {
      this.locationManager.stopUpdatingLocation();
      this.locationManager = undefined;
    }
  }
} 