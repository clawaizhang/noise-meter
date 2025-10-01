import { DecibelMeter } from '../../components/decibel-meter/DecibelMeter';
import { navigationStack } from '../../constants/ProviderConstant';
import { DialogHub } from '@hadss/dialoghub';
import { SettingsBuilder } from './SettingsNavigation';
import { NoiseStandardDialogBuilder } from './NoiseStandardDialogNavigation';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2 } from '@kit.ArkUI';

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
  @Local title: string = '静喵Sound';
  @Local menuItems: Array<NavigationMenuItem> = [];
  @Local as: AppKeys = AppStorageV2.connect(AppKeys)!;

  aboutToDisappear(): void {
  }

  aboutToAppear(): void {
    this.menuItems = this.noiseMeterMenus;
  }

  @Monitor('currentIndex')
  onTabIndexChange(monitor: IMonitor) {
    const currentValue = monitor.value<number>()?.now;
    if (currentValue === 0) {
      this.title = '仪表盘';
      this.menuItems = this.noiseMeterMenus;
    }
    if (currentValue === 1) {
      this.title = '我的';
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
    .flexGrow(1)
  }

  private noiseMeterMenus: Array<NavigationMenuItem> = [
    {
      value: '历史记录',
      icon: $r('app.media.ic_history'),
      action: () => {
        this.navStack.pushPathByName('DecibelHistory', null);
      }
    }
  ]

  @Builder
  DashboardContent() {
    Column() {
      // 噪音检测区域
      DecibelMeter({ meterOn: true })
        .id('decibelMeterId')
        .width('92%')
    }
    .id('decibelMeterRoot')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .opacity(this.currentIndex === 0 ? 1 : 0)
    .scale({ x: this.currentIndex === 0 ? 1 : 0.95, y: this.currentIndex === 0 ? 1 : 0.95 })
    .animation({
      duration: 300,
      curve: Curve.EaseOut,
      delay: 0,
      iterations: 1,
      playMode: PlayMode.Normal
    })
  }

  @Builder
  MyContent() {
    Column() {
      // 全局设置列表项
      List() {
        ListItem() {
          Row() {
            Image($r('app.media.ic_settings'))
              .width(24)
              .height(24)
              .fillColor($r('sys.color.font_primary'))
              .margin({ right: 12 })
            Text('全局设置')
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
            Image($r('app.media.ic_arrow_right'))
              .width(16)
              .height(16)
              .fillColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .height(56)
          .padding({
            left: 16,
            right: 16
          })
          .alignItems(VerticalAlign.Center)
        }
        .borderRadius(8)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .margin({ top: 20, left: 16, right: 16 })
        .onClick(() => {
          DialogHub.getSheet()
            .setStyle({ title: { title: '设置' }, backgroundColor: $r('sys.color.background_secondary') })
            .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
            .setComponentTargetId('myContentId')
            .setContent(wrapBuilder(SettingsBuilder))
            .build()
            .show();
        })

        // 噪音参考标准列表项
        ListItem() {
          Row() {
            Image($r('app.media.ic_info'))
              .width(24)
              .height(24)
              .fillColor($r('sys.color.font_primary'))
              .margin({ right: 12 })
            Text('噪音参考标准')
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
            Image($r('app.media.ic_arrow_right'))
              .width(16)
              .height(16)
              .fillColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .height(56)
          .padding({
            left: 16,
            right: 16
          })
          .alignItems(VerticalAlign.Center)
        }
        .borderRadius(8)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .margin({ top: 12, left: 16, right: 16 })
        .onClick(() => {
          let dialog = DialogHub.getSheet()
            .setStyle({ backgroundColor: $r('sys.color.background_secondary'), showClose: false })
            .setComponentTargetId('myContentId')
            .setConfig({ enableOutsideInteractive: false, scrollSizeMode: ScrollSizeMode.CONTINUOUS })
            .setContent(wrapBuilder(NoiseStandardDialogBuilder), this.as)
            .build();
          dialog.show();
          setInterval(() => {
            dialog.updateContent(this.as);
          }, 100)
        })
      }

    }
    .id('myContentId')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .opacity(this.currentIndex === 1 ? 1 : 0)
    .scale({ x: this.currentIndex === 1 ? 1 : 0.95, y: this.currentIndex === 1 ? 1 : 0.95 })
    .animation({
      duration: 300,
      curve: Curve.EaseOut,
      delay: 0,
      iterations: 1,
      playMode: PlayMode.Normal
    })
  }

  build() {
    NavDestination() {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          this.DashboardContent()
        }
        .tabBar(this.TabBuilder('仪表盘', $r('app.media.ic_meter'), 0))

        TabContent() {
          this.MyContent()
        }
        .tabBar(this.TabBuilder('我的', $r('app.media.ic_favorite'), 1))
      }
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .barMode(BarMode.Fixed)
      .barWidth('100%')
      .animationDuration(0)
    }
    .title(this.title, {
      barStyle: BarStyle.STANDARD,
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
