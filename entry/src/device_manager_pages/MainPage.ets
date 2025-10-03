import { DatabaseConstants } from '../main/ets/constants/DatabaseConstants';
import { DbConfig } from '../main/ets/interfaces/DatabaseInterfaces';
import { MainDeviceManager } from '../main/ets/pages/device_manager/MainDeviceManagerNavigation';

@ComponentV2
export struct MainPage {
  build() {
    MainDeviceManager()
  }
}

export const dbConfig: DbConfig = {
  dbName: DatabaseConstants.DEVICE_MANAGER_DB,
  upgradeConfigs: []
}