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

// Tab 类型定义（移除仪表Tab后的索引）
enum TabType {
  HOME = 0,
  TOOLS = 1,
  ALERTS = 2,
  EXPOSURE = 3,
  REFERENCE = 4,
  MY = 5
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
    this.menuItems = this.homeMenus;
  }

  @Monitor('currentIndex')
  onTabIndexChange(monitor: IMonitor) {
    const currentValue = monitor.value<number>()?.now;
    
    // 根据索引设置标题和菜单
    switch (currentValue) {
      case TabType.HOME:
        this.title = '主页';
        this.menuItems = this.homeMenus;
        break;
      case TabType.TOOLS:
        this.title = '设置';
        this.menuItems = this.toolsMenus;
        break;
      case TabType.ALERTS:
        this.title = '警报';
        this.menuItems = this.alertsMenus;
        break;
      case TabType.EXPOSURE:
        this.title = '影响';
        this.menuItems = this.exposureMenus;
        break;
      case TabType.REFERENCE:
        this.title = '参考';
        this.menuItems = this.referenceMenus;
        break;
      case TabType.MY:
        this.title = '我的';
        this.menuItems = [];
        break;
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

  private homeMenus: Array<NavigationMenuItem> = []
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
  private referenceMenus: Array<NavigationMenuItem> = []
  private toolsMenus: Array<NavigationMenuItem> = []

  @Builder
  HomeContent() {
    HomePageContent()
      .opacity(this.currentIndex === TabType.HOME ? 1 : 0)
      .scale({ x: this.currentIndex === TabType.HOME ? 1 : 0.95, 
              y: this.currentIndex === TabType.HOME ? 1 : 0.95 })
      .animation({
        duration: 300,
        curve: Curve.EaseOut,
        delay: 0,
        iterations: 1,
        playMode: PlayMode.Normal
      })
  }

  @Builder
  ToolsContentBuilder() {
    ToolsContent()
      .opacity(this.currentIndex === TabType.TOOLS ? 1 : 0)
      .scale({ x: this.currentIndex === TabType.TOOLS ? 1 : 0.95, 
              y: this.currentIndex === TabType.TOOLS ? 1 : 0.95 })
      .animation({
        duration: 300,
        curve: Curve.EaseOut,
        delay: 0,
        iterations: 1,
        playMode: PlayMode.Normal
      })
  }

  @Builder
  AlertsContentBuilder() {
    AlertsContent()
      .opacity(this.currentIndex === TabType.ALERTS ? 1 : 0)
      .scale({ x: this.currentIndex === TabType.ALERTS ? 1 : 0.95, 
              y: this.currentIndex === TabType.ALERTS ? 1 : 0.95 })
      .animation({
        duration: 300,
        curve: Curve.EaseOut,
        delay: 0,
        iterations: 1,
        playMode: PlayMode.Normal
      })
  }

  @Builder
  ExposureContentBuilder() {
    EnhancedExposureContent()
      .opacity(this.currentIndex === TabType.EXPOSURE ? 1 : 0)
      .scale({ x: this.currentIndex === TabType.EXPOSURE ? 1 : 0.95, 
              y: this.currentIndex === TabType.EXPOSURE ? 1 : 0.95 })
      .animation({
        duration: 300,
        curve: Curve.EaseOut,
        delay: 0,
        iterations: 1,
        playMode: PlayMode.Normal
      })
  }

  @Builder
  ReferenceContentBuilder() {
    ReferenceContent()
      .opacity(this.currentIndex === TabType.REFERENCE ? 1 : 0)
      .scale({ x: this.currentIndex === TabType.REFERENCE ? 1 : 0.95, 
              y: this.currentIndex === TabType.REFERENCE ? 1 : 0.95 })
      .animation({
        duration: 300,
        curve: Curve.EaseOut,
        delay: 0,
        iterations: 1,
        playMode: PlayMode.Normal
      })
  }

  @Builder
  MyContentBuilder() {
    MyContentComponent()
      .opacity(this.currentIndex === TabType.MY ? 1 : 0)
      .scale({ x: this.currentIndex === TabType.MY ? 1 : 0.95, 
              y: this.currentIndex === TabType.MY ? 1 : 0.95 })
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

        // 工具页面 - 使用ToolsContent组件
        TabContent() {
          this.ToolsContentBuilder()
        }
        .tabBar(this.TabBuilder({
          title: '设置',
          icon: this.currentIndex == 1 ? $r("app.media.ic_atom_bold") : $r("app.media.ic_atom"),
          index: 1
        }))

        // 警报页面 - 使用独立的AlertsContent组件
        TabContent() {
          this.AlertsContentBuilder()
        }
        .tabBar(this.TabBuilder({
          title: '警报',
          icon: this.currentIndex == 2 ? $r("app.media.bell_bing_bold") : $r("app.media.ic_alarm"),
          index: 2
        }))

        TabContent() {
          this.ExposureContentBuilder()
        }
        .tabBar(this.TabBuilder({
          title: '影响',
          icon: this.currentIndex == 3 ? $r("app.media.i_solar_radar_bold") : $r("app.media.i_solar_radar_outline"),
          index: 3
        }))

        // 参考页面 - 使用ReferenceContent组件
        TabContent() {
          this.ReferenceContentBuilder()
        }
        .tabBar(this.TabBuilder({
          title: '参考',
          icon: this.currentIndex == 4 ? $r("app.media.ic_book2_bold") : $r("app.media.ic_book2"),
          index: 4
        }))

        TabContent() {
          this.MyContentBuilder()
        }
        .tabBar(this.TabBuilder({
          title: '我的',
          icon: this.currentIndex == 5 ? $r("app.media.solar_user_circle_bold") : $r("app.media.ic_user"),
          index: 5
        }))
      }
      .scrollable(false)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .barMode(BarMode.Fixed)
      .barWidth('100%')
      .barHeight(56)
      .animationDuration(0)
    }
    .title(this.buildTitleContent, {
      barStyle: BarStyle.STANDARD,
      backgroundBlurStyle: BlurStyle.BACKGROUND_REGULAR,
    })
    .id('mainAppId')
    .menus(this.menuItems)
    .hideToolBar(true)
    .mode(NavDestinationMode.STANDARD)
    .backgroundColor($r('sys.color.background_secondary'))
    .animation({ duration: 200, curve: Curve.Linear })
  }
}
