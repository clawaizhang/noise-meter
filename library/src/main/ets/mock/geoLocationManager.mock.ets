export interface Location {
  latitude?: number;
  longitude?: number;
}

export class LocationImpl implements Location {
  latitude?: number;
  longitude?: number;

  constructor(latitude?: number, longitude?: number) {
    this.latitude = latitude;
    this.longitude = longitude;
  }
}

export interface LocationRequest {
  priority: number;
  scenario: number;
  timeInterval: number;
  distanceInterval: number;
}

export class LocationRequestImpl implements LocationRequest {
  priority: number;
  scenario: number;
  timeInterval: number;
  distanceInterval: number;

  constructor(priority: number, scenario: number, timeInterval: number, distanceInterval: number) {
    this.priority = priority;
    this.scenario = scenario;
    this.timeInterval = timeInterval;
    this.distanceInterval = distanceInterval;
  }
}

export type LocationCallback = (location: Location) => void;

export interface GeoLocationManager {
  getCurrentLocation(request: LocationRequest): Promise<Location>;
  on(type: string, request: LocationRequest, callback: LocationCallback): void;
  off(type: string, callback?: LocationCallback): void;
}

class GeoLocationManagerImpl implements GeoLocationManager {
  getCurrentLocation(request: LocationRequest): Promise<Location> {
    return Promise.resolve(new LocationImpl(39.9042, 116.4074));
  }

  on(type: string, request: LocationRequest, callback: LocationCallback): void {
    // 模拟位置更新
    callback(new LocationImpl(39.9042, 116.4074));
  }

  off(type: string, callback?: LocationCallback): void {
    // 模拟清理监听器
  }
}

export default new GeoLocationManagerImpl(); 