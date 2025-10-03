import { DecibelMeter } from '../../components/decibel-meter/DecibelMeter';
import { navigationStack } from '../../constants/ProviderConstant';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { SettingsBuilder } from './SettingsNavigation';
import { NoiseStandardDialogBuilder } from './NoiseStandardDialogNavigation';
import { AboutSettingsBuilder } from '../settings/AboutSettingsNavigation';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2 } from '@kit.ArkUI';
import { ListItemBuilder } from '../../components/common/ListItemBuilder';
import { interval, Subscription } from 'rxjs';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2 } from '@kit.ArkUI';
import { AlertsContent } from '../../components/alerts/AlertsContent';
import { AlertsSettingsBuilder } from '../settings/AlertsSettingsNavigation';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Want } from '@kit.AbilityKit';

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
  @Local currentIndex: number = 1
  @Local title: string = '静喵Sound';
  @Local menuItems: Array<NavigationMenuItem> = [];
  @Local as: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  noiseReferSub?:Subscription
  
  // DialogHub实例缓存
  private alertsDialog: InfSheet | null = null;


  aboutToDisappear(): void {
    this.noiseReferSub?.unsubscribe();
  }

  aboutToAppear(): void {
    this.menuItems = this.noiseMeterMenus;
  }

  @Monitor('currentIndex')
  onTabIndexChange(monitor: IMonitor) {
    const currentValue = monitor.value<number>()?.now;
    if (currentValue === 0) {
      this.title = '噪音警报';
      this.menuItems = this.alertsMenus;
    }
    if (currentValue === 1) {
      this.title = '仪表盘';
      this.menuItems = this.noiseMeterMenus;
    }
    if (currentValue === 2) {
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
  
  private alertsMenus: Array<NavigationMenuItem> = [
    {
      value: '警报设置',
      icon: $r('app.media.ic_settings'),
      action: () => {
        if (!this.alertsDialog) {
          this.alertsDialog = DialogHub.getSheet()
            .setStyle({ title: { title: '警报与通知' }, backgroundColor: $r('sys.color.background_secondary') })
            .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
            .setComponentTargetId('mainAppId')
            .setContent(wrapBuilder(AlertsSettingsBuilder))
            .build();
        }
        this.alertsDialog.show();
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
  MyContent() {
    Column() {
      // 全局设置列表项
      List() {
        ListItemBuilder(
          $r('app.media.ic_settings'),
          '全局设置',
          () => {
            DialogHub.getSheet()
              .setStyle({ title: { title: '设置' }, backgroundColor: $r('sys.color.background_secondary') })
              .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
              .setComponentTargetId('myContentId')
              .setContent(wrapBuilder(SettingsBuilder))
              .build()
              .show();
          },
          20
        )

        // 给作者五星好评设置
        ListItemBuilder(
          $r('app.media.ic_favorite'),
          '五星好评',
          () => {
            this.navigateToAppStoreRating();
          },
        )

        // 关于列表项
        ListItemBuilder(
          $r('app.media.ic_info'),
          '关于',
          () => {
            DialogHub.getSheet()
              .setStyle({ title: { title: '关于' }, backgroundColor: $r('sys.color.background_secondary') })
              .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
              .setComponentTargetId('myContentId')
              .setContent(wrapBuilder(AboutSettingsBuilder))
              .build()
              .show();
          }
        )
      }

    }
    .id('myContentId')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
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


  // 跳转到应用商店评价页面
  private navigateToAppStoreRating = () => {
    const context = getContext(this) as common.UIAbilityContext;
    const want: Want = {
      action: 'ohos.want.action.appdetail',
      uri: 'store://appgallery.huawei.com/app/detail?id=yu.zhang.myapplication.noise_meter_pro&action=write-review'
    };
    context.startAbility(want).then(() => {
      console.info('Succeeded in starting App Store rating page successfully.');
    }).catch((err: BusinessError) => {
      console.error(`Failed to start App Store rating page. Code: ${err.code}, message: ${err.message}`);
    });
  }

  build() {
    NavDestination() {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        // 警报页面 - 使用独立的AlertsContent组件
        TabContent() {
          AlertsContent()
        }
        .tabBar(this.TabBuilder('警报', $r('app.media.ic_alarm'), 0))

        TabContent() {
          this.DashboardContent()
        }
        .tabBar(this.TabBuilder('仪表盘', $r('app.media.ic_meter'), 1))

        TabContent() {
          this.MyContent()
        }
        .tabBar(this.TabBuilder('我的', $r('app.media.ic_favorite'), 2))
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
    .id('mainAppId')
    .menus(this.menuItems)
    .hideTitleBar(false)
    .hideToolBar(true)
    .mode(NavDestinationMode.STANDARD)
    .backgroundColor($r('sys.color.background_secondary'))
    .animation({ duration: 200, curve: Curve.Linear })
  }
}
