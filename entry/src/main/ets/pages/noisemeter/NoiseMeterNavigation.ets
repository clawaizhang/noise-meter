import { DecibelMeter } from '../../components/decibel-meter/DecibelMeter';
import { navigationStack } from '../../constants/ProviderConstant';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AlertsContent } from '../../components/alerts/AlertsContent';
import { AlertsSettingsBuilder, AlertsSettingsProps } from '../settings/AlertsSettingsNavigation';
import { MyContentComponent } from '../../components/my-content/MyContentComponent';
import { EnhancedExposureContent } from '../../components/exposure/EnhancedExposureContent';
import { HomePageContent } from '../../components/home/HomePageContent';
import { AudioController } from '../../components/decibel-meter/AudioController';
import { ReferenceContent } from '../../components/reference/ReferenceContent';
import { ToolsContent } from '../../components/tools/ToolsContent';

// 导航菜单项接口定义
interface NavigationMenuItem {
  value: string;
  icon: Resource;
  action: () => void;
}

// Tab配置接口定义
interface TabConfig {
  title: string;
  icon: Resource;
  index: number;
}

@Builder
export function NoiseMeterBuilder() {
  MainNoiseMeter()
}

@ComponentV2
export struct MainNoiseMeter {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  @Local currentIndex: number = 0
  @Local title: string = '主页';
  @Local menuItems: Array<NavigationMenuItem> = [];
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  aboutToDisappear(): void {
  }

  aboutToAppear(): void {
    this.menuItems = this.noiseMeterMenus;
  }

  @Monitor('currentIndex')
  onTabIndexChange(monitor: IMonitor) {
    const currentValue = monitor.value<number>()?.now;
    if (currentValue === 0) {
      this.title = '主页';
      this.menuItems = this.homeMenus;
    }
    if (currentValue === 1) {
      this.title = '仪表盘';
      this.menuItems = this.noiseMeterMenus;
    }
    if (currentValue === 2) {
      this.title = '操作台';
      this.menuItems = this.toolsMenus;
    }
    if (currentValue === 3) {
      this.title = '警报';
      this.menuItems = this.alertsMenus;
    }
    if (currentValue === 4) {
      this.title = '影响';
      this.menuItems = this.exposureMenus;
    }
    if (currentValue === 5) {
      this.title = '参考';
      this.menuItems = this.referenceMenus;
    }
    if (currentValue === 6) {
      this.title = '我的';
      this.menuItems = [];
    }
    // 同步到AppKeys
    this.ak.currentTabIndex = currentValue!;
  }

  @Monitor('ak.currentTabIndex')
  onTabIndexChangeFromAppKeys(monitor: IMonitor) {
    const targetIndex = monitor.value<number>()?.now;
    if (targetIndex !== undefined && targetIndex !== this.currentIndex) {
      this.currentIndex = targetIndex;
    }
  }

  @Computed
  get pro() {
    return `专业版 · ${Math.ceil((this.pk.member_ship.expiryDate - Date.now()) / (1000 * 60 * 60 * 24))}天`;
  }

  @Builder
  TabBuilder(config: TabConfig) {
    Column() {
      Image(config.icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === config.index ? $r('sys.color.icon_emphasize') : $r('sys.color.icon_primary'))
      Text(config.title)
        .fontSize(12)
        .fontColor(this.currentIndex === config.index ? $r('sys.color.font_emphasize') : $r('sys.color.font_primary'))
        .margin({ top: 4 })
    }
    .justifyContent(FlexAlign.Center)
    .flexGrow(1)
  }

  private homeMenus: Array<NavigationMenuItem> = [

  ]
  private noiseMeterMenus: Array<NavigationMenuItem> = [

  ]
  private alertsMenus: Array<NavigationMenuItem> = [
    {
      value: '警报设置',
      icon: $r('app.media.ic_alarm'),
      action: () => {
        let alertsDialog: InfSheet;
        let props: AlertsSettingsProps = {
          onSave: () => {
            alertsDialog.dismiss();
          },
          onClose: () => {
            alertsDialog.dismiss();
          }
        }
        alertsDialog = DialogHub.getSheet()
          .setStyle({ showClose: false, backgroundColor: $r('sys.color.background_secondary') })
          .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
          .setComponentTargetId('mainId')
          .setContent(wrapBuilder(AlertsSettingsBuilder), props)
          .build();
        alertsDialog.show();
      }
    }
  ]
  private exposureMenus: Array<NavigationMenuItem> = [
    {
      value: '历史趋势',
      icon: $r('app.media.ic_history'),
      action: () => {
        this.navStack.pushPathByName('DecibelHistory', null);
      }
    }
  ]
  private referenceMenus: Array<NavigationMenuItem> = [

  ]
  private toolsMenus: Array<NavigationMenuItem> = [

  ]

  @Builder
  HomeContent() {
    HomePageContent()
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

  @Builder
  private buildTitleContent() {
    Column({ space: 2 }) {
      // 主标题 - 在上方
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 副标题 - 在下方（会员标签）
      if (this.pk.member_ship.can) {
        Row({ space: 4 }) {
          Image($r('app.media.ic_vip'))
            .width(14)
            .height(14)
            .fillColor($r('sys.color.confirm'))
          Text(this.pro)
            .fontSize(11)
            .fontColor($r('sys.color.confirm'))
        }
        .padding({
          left: 6,
          right: 6,
          top: 2,
          bottom: 2
        })
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(8)
        .alignSelf(ItemAlign.Start)
      } else {
        Row({ space: 4 }) {
          Image($r('app.media.ic_vip'))
            .width(14)
            .height(14)
            .fillColor($r('sys.color.font_secondary'))
          Text('基础版')
            .fontSize(11)
            .fontColor($r('sys.color.font_secondary'))
        }
        .padding({
          left: 6,
          right: 6,
          top: 2,
          bottom: 2
        })
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(8)
        .alignSelf(ItemAlign.Start)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .padding({ left: 16 }) // 左侧边距
    .height('100%')
  }

  build() {
    NavDestination() {
      // 音频控制器（逻辑组件，不渲染UI）- 使用RxJS数据流
      AudioController()
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        // 主页 - 使用HomeContent组件
        TabContent() {
          this.HomeContent()
        }
        .tabBar(this.TabBuilder({
          title: '主页',
          icon: this.currentIndex == 0 ? $r("app.media.ic_home_bold") : $r("app.media.ic_home"),
          index: 0
        }))

        // 主页页面 - 使用DashboardContent组件
        TabContent() {
          this.DashboardContent()
        }
        .tabBar(this.TabBuilder({
          title: '仪表盘',
          icon: this.currentIndex == 1 ? $r("app.media.solar_spedometer_middle_bold") : $r("app.media.ic_meter"),
          index: 1
        }))

        // 工具页面 - 使用ToolsContent组件
        TabContent() {
          ToolsContent()
            .opacity(this.currentIndex === 2 ? 1 : 0)
            .scale({ x: this.currentIndex === 2 ? 1 : 0.95, y: this.currentIndex === 2 ? 1 : 0.95 })
            .animation({
              duration: 300,
              curve: Curve.EaseOut,
              delay: 0,
              iterations: 1,
              playMode: PlayMode.Normal
            })
        }
        .tabBar(this.TabBuilder({
          title: '操作台',
          icon: this.currentIndex == 2 ? $r("app.media.ic_atom_bold") : $r("app.media.ic_atom"),
          index: 2
        }))

        // 警报页面 - 使用独立的AlertsContent组件
        TabContent() {
          AlertsContent()
            .opacity(this.currentIndex === 3 ? 1 : 0)
            .scale({ x: this.currentIndex === 3 ? 1 : 0.95, y: this.currentIndex === 3 ? 1 : 0.95 })
            .animation({
              duration: 300,
              curve: Curve.EaseOut,
              delay: 0,
              iterations: 1,
              playMode: PlayMode.Normal
            })
        }
        .tabBar(this.TabBuilder({
          title: '警报',
          icon: this.currentIndex == 3 ? $r("app.media.bell_bing_bold") : $r("app.media.ic_alarm"),
          index: 3
        }))

        TabContent() {
          EnhancedExposureContent()
            .opacity(this.currentIndex === 4 ? 1 : 0)
            .scale({ x: this.currentIndex === 4 ? 1 : 0.95, y: this.currentIndex === 4 ? 1 : 0.95 })
            .animation({
              duration: 300,
              curve: Curve.EaseOut,
              delay: 0,
              iterations: 1,
              playMode: PlayMode.Normal
            })
        }
        .tabBar(this.TabBuilder({
          title: '影响',
          icon: this.currentIndex == 4 ? $r("app.media.i_solar_radar_bold") : $r("app.media.i_solar_radar_outline"),
          index: 4
        }))

        // 参考页面 - 使用ReferenceContent组件
        TabContent() {
          ReferenceContent()
            .opacity(this.currentIndex === 5 ? 1 : 0)
            .scale({ x: this.currentIndex === 5 ? 1 : 0.95, y: this.currentIndex === 5 ? 1 : 0.95 })
            .animation({
              duration: 300,
              curve: Curve.EaseOut,
              delay: 0,
              iterations: 1,
              playMode: PlayMode.Normal
            })
        }
        .tabBar(this.TabBuilder({
          title: '参考',
          icon: this.currentIndex == 5 ? $r("app.media.ic_book2_bold") : $r("app.media.ic_book2"),
          index: 5
        }))

        TabContent() {
          MyContentComponent().opacity(this.currentIndex === 6 ? 1 : 0)
            .scale({ x: this.currentIndex === 6 ? 1 : 0.95, y: this.currentIndex === 6 ? 1 : 0.95 })
        }
        .tabBar(this.TabBuilder({
          title: '我的',
          icon: this.currentIndex == 6 ? $r("app.media.solar_user_circle_bold") : $r("app.media.ic_user"),
          index: 6
        }))
      }
      .scrollable(false)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .barMode(BarMode.Fixed)
      .barWidth('100%')
      .animationDuration(0)
    }
    .title(this.buildTitleContent, {
      barStyle: BarStyle.STANDARD,
      backgroundBlurStyle: BlurStyle.BACKGROUND_REGULAR,
    })
    .id('mainAppId')
    .menus(this.menuItems)
    .hideTitleBar(false)
    .hideToolBar(true)
    .mode(NavDestinationMode.STANDARD)
    .backgroundColor($r('sys.color.background_secondary'))
    .animation({ duration: 200, curve: Curve.Linear })
  }
}
