interface Location {
  latitude?: number;
  longitude?: number;
}

export class LocationUtil {
  static async getCurrentLocation(): Promise<Location> {
    return {
      latitude: 39.9042,
      longitude: 116.4074
    };
  }

  static onLocationChangeEasy(callback: (location: Location) => void) {
    // 模拟位置更新
    callback({
      latitude: 39.9042,
      longitude: 116.4074
    });
  }

  static offLocationChange() {
    // 模拟清理监听器
  }
}

export class PermissionUtil {
  static async checkPermissions(permission: string): Promise<boolean> {
    return true;
  }

  static async requestPermissions(permissions: string[]): Promise<boolean> {
    return true;
  }
} 