import { DeviceManagerPage } from './DeviceManagerPage'

@Builder
export function DeviceManagerBuilder() {
  MainDeviceManager()
}

@ComponentV2
export struct MainDeviceManager {

  async aboutToAppear() {
  }

  build() {
    Column() {
      DeviceManagerPage()
    }
    .width('100%')
    .height('100%')
  }
}