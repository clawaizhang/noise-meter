import { navigationStack } from '../../constants/ProviderConstant'
import { PreferenceService } from '../../services/PreferenceService'
import { ScreenshotUtils } from '../../utils/ScreenshotUtils'
import { common } from '@kit.AbilityKit'
import { SettingsDeviceManager } from '../../components/SettingsDeviceManager'
import { LocalSendPage } from './LocalSendPage'
import { LocalSendService } from '../../services/LocalSendService'

@Builder
export function LocalSendBuilder() {
  MainLocalSend()
}

@ComponentV2
export struct MainLocalSend {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  @Local currentIndex: number = 0
  @Local title:string = '手机管家';
  @Local menuItems:Array<NavigationMenuItem> = [];

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
    .width('100%')
    .height('100%')
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
          'localSendRoot',
          `local_send_screenshot_${timestamp}.jpg`,
          '手机管家截图',
          '当前手机管家截图'
        );
      }
    },
    {
      value: '发送文件',
      icon: $r('app.media.ic_share'),
      action: () => {
        const localSendService = LocalSendService.getInstance();
        // 这里可以添加文件选择逻辑
        console.log('启动文件发送功能');
      }
    },
    {
      value: '清除记录',
      icon: $r('app.media.ic_share'),
      action: () => {
        const localSendService = LocalSendService.getInstance();
        localSendService.clearCompletedTransfers();
        console.log('已清除完成的传输记录');
      }
    }
  ]

  private messageMenus: Array<NavigationMenuItem> = []

  build() {
    NavDestination() {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          Column() {
            LocalSendPage()
          }
          .id('localSendRoot')
          .width('100%')
          .height('100%')
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
      .width('100%')
      .height('100%')
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
