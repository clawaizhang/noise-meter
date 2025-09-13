import { DecibelMeter } from '../../components/decibel-meter/DecibelMeter';
import { navigationStack } from '../../constants/ProviderConstant';
import { PreferenceKeyConstants } from '../../constants/PreferenceKeyConstants';
import { PreferenceService } from '../../services/PreferenceService';
import { WeightingType } from '../../constants/WeightingConstants';
import { camera } from '@kit.CameraKit';
import { PressureSounds } from '../../components/decibel-meter/PressureSounds';

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
  @Local meterOn: boolean = true;
  @Local touchOn: boolean = false;
  @Local title: string = '静喵';
  @Local menuItems: Array<NavigationMenuItem> = [];
  private preferenceService: PreferenceService = PreferenceService.getInstance();

  aboutToDisappear(): void {
  }

  aboutToAppear(): void {
    // 初始化加权类型
    if (!this.preferenceService.getString(PreferenceKeyConstants.WEIGHTING)) {
      this.preferenceService.setString(PreferenceKeyConstants.WEIGHTING, WeightingType.A);
    }
    this.menuItems = this.noiseMeterMenus;
    this.preferenceService.setBoolean(PreferenceKeyConstants.METER_ON, true);
    this.meterOn = this.preferenceService.getBoolean(PreferenceKeyConstants.METER_ON, true);

  }

  @Monitor('currentIndex')
  onTabIndexChange(monitor: IMonitor) {
    const currentValue = monitor.value<number>()?.now;
    if (currentValue === 0) {
      this.title = '静喵';
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
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)

  }

  private noiseMeterMenus: Array<NavigationMenuItem> = [
    {
      value: '检测记录',
      icon: $r('app.media.ic_history'),
      action: () => {
        this.navStack.pushPathByName('DecibelHistory', null);
      }
    },
    {
      value: '设置',
      icon: $r('app.media.ic_settings'),
      action: () => {
        this.navStack.pushPathByName('Settings', null);
      }
    }
  ]
  private decibelHistoryMenus: Array<NavigationMenuItem> = []

  build() {
    NavDestination() {
      Tabs({
        barPosition: BarPosition.End,
        index: this.currentIndex
      }) {
        TabContent() {
          Column() {

            // 噪音检测区域
            DecibelMeter({ meterOn: this.meterOn })
              .width('92%')
          }
          .id('decibelMeterRoot')
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.background_secondary'))
          .alignItems(HorizontalAlign.Center)
        }
        .tabBar(this.TabBuilder('', $r('app.media.ic_meter'), 0))

        TabContent() {
          PressureSounds()
        }
        .tabBar(this.TabBuilder('', $r('app.media.ic_play'), 1))

      }
      .scrollable(false)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .width('100%')
      .height('100%')
      .barOverlap(true)
      .barBackgroundBlurStyle(BlurStyle.BACKGROUND_REGULAR)
      .barMode(BarMode.Fixed)
      .animationDuration(0)
    }
    .title(this.title, {
      mainTitleModifier: new MyTextModifier(),
      barStyle: this.currentIndex == 1 ? BarStyle.STACK : BarStyle.STANDARD,
      backgroundBlurStyle: BlurStyle.BACKGROUND_REGULAR
    })
    .menus(this.menuItems)
    .hideTitleBar(false)
    .backgroundColor($r('app.color.background_secondary'))
    .hideToolBar(true)
    .mode(NavDestinationMode.STANDARD)
    .animation({ duration: 200, curve: Curve.Linear })
  }
}

class MyTextModifier implements AttributeModifier<TextAttribute> {
  applyNormalAttribute(instance: TextAttribute): void {
    instance.fontColor($r('app.color.text_primary'));
  }
}
