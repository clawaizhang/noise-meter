import { navigationStack } from '../../constants/ProviderConstant'
import { PreferenceService } from '../../services/PreferenceService'
import { DeviceManagerPage } from './DeviceManagerPage'
import { ScreenshotUtils } from '../../utils/ScreenshotUtils'
import { common } from '@kit.AbilityKit'
import { SettingsDeviceManager } from '../../components/SettingsDeviceManager'

@Builder
export function DeviceManagerBuilder() {
  MainDeviceManager()
}

@ComponentV2
export struct MainDeviceManager {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  @Local currentIndex: number = 0
  @Local meterOn: boolean = true;
  @Local title:string = '手机管家';
  @Local menuItems:Array<NavigationMenuItem> = [];
  private preferenceService: PreferenceService = PreferenceService.getInstance();

  aboutToAppear(): void {
    this.menuItems = this.deviceManagerMenus;
  }

  @Monitor('currentIndex')
  onTabIndexChange(monitor: IMonitor) {
    const currentValue = monitor.value<number>()?.now;
    if (currentValue === 0) {
      this.title  = '手机管家';
      this.menuItems = this.deviceManagerMenus;
    }
    if (currentValue === 1) {
      this.title = '信息';
      this.menuItems = this.messageMenus;
    }
    if (currentValue === 2) {
      this.title = '设置';
      this.menuItems = [];
    }
  }


  @Builder
  TabBuilder(title: string, icon: Resource, index: number) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? $r('app.color.icon_active') : $r('app.color.icon_inactive'))
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
        .margin({ top: 4 })
    }


    .justifyContent(FlexAlign.Center)
  }

  private deviceManagerMenus: Array<NavigationMenuItem> = [
    {
      value: '分享',
      icon: $r('app.media.ic_share'),
      action: () => {
        const context = getContext(this) as common.UIAbilityContext;
        const uiContext = this.getUIContext();
        const now = new Date();
        const timestamp = now.toISOString().replace(/[:.]/g, '-').slice(0, 19);
        ScreenshotUtils.captureAndShare(
          context,
          uiContext,
          'deviceManagerRoot',
          `device_manager_screenshot_${timestamp}.jpg`,
          '手机管家截图',
          '当前手机管家截图'
        );
      }
    }
  ]

  private messageMenus: Array<NavigationMenuItem> = []

  build() {
    NavDestination() {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          Column() {
            DeviceManagerPage()
          }
          .id('deviceManagerRoot')


          .backgroundColor($r('app.color.background_secondary'))
          .alignItems(HorizontalAlign.Center)
        }
        .tabBar(this.TabBuilder('手机管家', $r('app.media.ic_meter'), 0))

        TabContent() {

        }
        .tabBar(this.TabBuilder('检测记录', $r('app.media.ic_history'), 1))



        TabContent() {
          SettingsDeviceManager()
        }
        .tabBar(this.TabBuilder('设置', $r('app.media.ic_settings'), 2))
      }
      .scrollable(false)
      .onChange((index: number) => {
        this.currentIndex = index;
      })


      .barHeight(56)
      .barMode(BarMode.Fixed)
      .animationDuration(0)
    }
    .title(this.title, { mainTitleModifier: new MyTextModifier() })
    .menus(this.menuItems)
    .backgroundColor($r('app.color.background_secondary'))
    .hideToolBar(true)
    .mode(NavDestinationMode.STANDARD)
  }
}

class MyTextModifier implements AttributeModifier<TextAttribute> {
  applyNormalAttribute(instance: TextAttribute): void {
    instance.fontColor($r('app.color.text_primary'));
  }
}
