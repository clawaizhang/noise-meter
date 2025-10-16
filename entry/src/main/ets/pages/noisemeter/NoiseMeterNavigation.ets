import { DecibelMeter } from '../../components/decibel-meter/DecibelMeter';
import { navigationStack } from '../../constants/ProviderConstant';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AlertsContent } from '../../components/alerts/AlertsContent';
import { AlertsSettingsBuilder, AlertsSettingsProps } from '../settings/AlertsSettingsNavigation';
import { MyContentComponent } from '../../components/my-content/MyContentComponent';

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
      this.title = '噪音警报';
      this.menuItems = this.alertsMenus;
    }
    if (currentValue === 1) {
      this.title = '静喵Sound';
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
        .fillColor(this.currentIndex === index ? $r('sys.color.icon_emphasize') : $r('sys.color.icon_primary'))
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? $r('sys.color.font_emphasize') : $r('sys.color.font_primary'))
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
          Text(`专业版 · ${Math.ceil((this.pk.member_ship.expiryDate - Date.now()) / (1000 * 60 * 60 * 24))}天`)
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
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        // 警报页面 - 使用独立的AlertsContent组件
        TabContent() {
          AlertsContent()
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
        .tabBar(this.TabBuilder('警报',this.currentIndex == 0 ? $r("app.media.bell_bing_bold"):$r("app.media.ic_alarm"), 0))

        TabContent() {
          this.DashboardContent()
        }
        .tabBar(this.TabBuilder('静喵Sound',this.currentIndex == 1 ? $r("app.media.solar_spedometer_middle_bold"):$r("app.media.ic_meter"), 1))

        TabContent() {
          MyContentComponent({ currentIndex: this.currentIndex })
        }
        .tabBar(this.TabBuilder('我的', this.currentIndex == 2 ? $r("app.media.solar_user_circle_bold"):$r("app.media.ic_user"), 2))
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
