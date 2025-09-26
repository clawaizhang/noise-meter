import { DecibelMeter } from '../../components/decibel-meter/DecibelMeter';
import { navigationStack } from '../../constants/ProviderConstant';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DialogHub } from '@hadss/dialoghub';
import { SettingsBuilder } from './SettingsNavigation';
import { PersistenceV2 } from '@kit.ArkUI';

// 导航菜单项接口定义
interface NavigationMenuItem {
  value: string;
  icon: Resource;
  action: () => void;
}


@Builder
export function NoiseMeterBuilder() {
  MainNoiseMeter()
}

@ComponentV2
export struct MainNoiseMeter {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  @Local currentIndex: number = 0
  @Local touchOn: boolean = false;
  @Local title: string = '静喵Sound';
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local menuItems: Array<NavigationMenuItem> = [];

  aboutToDisappear(): void {
  }

  aboutToAppear(): void {
    this.menuItems = this.noiseMeterMenus;
  }

  @Monitor('currentIndex')
  onTabIndexChange(monitor: IMonitor) {
    const currentValue = monitor.value<number>()?.now;
    if (currentValue === 0) {
      this.title = '静喵Sound';
      this.menuItems = this.noiseMeterMenus;
    }
    if (currentValue === 1) {
      this.title = 'Sound';
      this.menuItems = this.decibelHistoryMenus;
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

  private noiseMeterMenus: Array<NavigationMenuItem> = [
    {
      value: '历史记录',
      icon: $r('app.media.ic_history'),
      action: () => {
        this.navStack.pushPathByName('DecibelHistory', null);
      }
    },
    {
      value: '设置',
      icon: $r('app.media.ic_settings'),
      action: () => {
        DialogHub.getSheet()
          .setStyle({ title: { title: '设置' }, backgroundColor: $r('sys.color.background_secondary') })
          .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
          .setComponentTargetId('decibelMeterId')
          .setContent(wrapBuilder(SettingsBuilder))
          .build()
          .show();
      }
    }
  ]
  private decibelHistoryMenus: Array<NavigationMenuItem> = []

  build() {
    NavDestination() {
      Column() {
        // 噪音检测区域
        DecibelMeter({ meterOn: true })
          .id('decibelMeterId')
          .width('92%')
      }
      .id('decibelMeterRoot')
      .alignItems(HorizontalAlign.Center)
    }
    .title(this.title, {
      barStyle: this.currentIndex == 1 ? BarStyle.STACK : BarStyle.STANDARD,
      backgroundBlurStyle: BlurStyle.BACKGROUND_REGULAR
    })
    .menus(this.menuItems)
    .hideTitleBar(false)
    .hideToolBar(true)
    .mode(NavDestinationMode.STANDARD)
    .backgroundColor($r('sys.color.background_secondary'))
    .animation({ duration: 200, curve: Curve.Linear })
  }
}
