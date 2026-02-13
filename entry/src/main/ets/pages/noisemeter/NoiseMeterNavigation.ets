import { navigationStack } from '../../constants/ProviderConstant';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { MyContentComponent } from '../../components/my-content/MyContentComponent';
import { HomePageContent } from '../../components/home/HomePageContent';
import { AudioController } from '../../components/decibel-meter/AudioController';
import { DashboardFullscreen } from '../../components/home/DashboardFullscreen';
import { WindowManager } from '../../utils/WindowManager';
import { HistoryContent } from '../../components/history/HistoryContent';
import window from '@ohos.window';

// Tab配置接口定义
interface TabConfig {
  title: string;
  icon: Resource;
  index: number;
}

// Tab 类型定义（精简为3个Tab）
enum TabType {
  DETECTION = 0,  // 检测（原主页）
  HISTORY = 1,    // 历史
  MY = 2          // 我的（整合设置/警报/影响/参考）
}

@Builder
export function NoiseMeterBuilder() {
  MainNoiseMeter()
}

@ComponentV2
export struct MainNoiseMeter {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  @Local currentIndex: number = 0
  @Local title: string = '检测';
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  aboutToDisappear(): void {
  }

  aboutToAppear(): void {
  }

  @Monitor('currentIndex')
  onTabIndexChange(monitor: IMonitor) {
    const currentValue = monitor.value<number>()?.now;
    
    // 根据索引设置标题
    switch (currentValue) {
      case TabType.DETECTION:
        this.title = '检测';
        break;
      case TabType.HISTORY:
        this.title = '历史';
        break;
      case TabType.MY:
        this.title = '我的';
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

  @Monitor('ak.isDashboardFullscreen')
  onDashboardFullscreenChange(monitor: IMonitor) {
    const isFullscreen = monitor.value<boolean>()?.now;
    if (isFullscreen) {
      this.enterLandscapeMode();
    } else {
      this.exitLandscapeMode();
    }
  }

  /**
   * 进入横屏模式
   */
  private async enterLandscapeMode(): Promise<void> {
    const windowManager = WindowManager.getInstance();
    await windowManager.setOrientation(window.Orientation.LANDSCAPE);
    console.info('[MainNoiseMeter] 进入横屏模式');
  }

  /**
   * 退出横屏模式
   */
  private async exitLandscapeMode(): Promise<void> {
    const windowManager = WindowManager.getInstance();
    const mainWindow = await windowManager.getMainWindow();
    if (!mainWindow) return;

    const uiContext = mainWindow.getUIContext();
    const widthBp = uiContext.getWindowWidthBreakpoint();

    let orientation = window.Orientation.AUTO_ROTATION;
    if (widthBp <= WidthBreakpoint.WIDTH_SM) {
      orientation = window.Orientation.PORTRAIT;
    }

    await windowManager.setOrientation(orientation);
    console.info('[MainNoiseMeter] 退出横屏模式');
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

  @Builder
  DetectionContent() {
    HomePageContent()
      .opacity(this.currentIndex === TabType.DETECTION ? 1 : 0)
      .scale({ x: this.currentIndex === TabType.DETECTION ? 1 : 0.95, 
              y: this.currentIndex === TabType.DETECTION ? 1 : 0.95 })
      .animation({
        duration: 300,
        curve: Curve.EaseOut,
        delay: 0,
        iterations: 1,
        playMode: PlayMode.Normal
      })
  }

  @Builder
  HistoryContentBuilder() {
    HistoryContent({
      isActiveTab: this.currentIndex === TabType.HISTORY
    })
      .opacity(this.currentIndex === TabType.HISTORY ? 1 : 0)
      .scale({ x: this.currentIndex === TabType.HISTORY ? 1 : 0.95, 
              y: this.currentIndex === TabType.HISTORY ? 1 : 0.95 })
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
    .padding({ left: 16 })
    .height('100%')
  }

  build() {
    NavDestination() {
      // 音频控制器（逻辑组件，不渲染UI）
      AudioController()

      if (this.ak.isDashboardFullscreen) {
        // 全屏横屏模式：只显示仪表全屏组件
        DashboardFullscreen()
      } else {
        // 正常模式：显示Tabs（精简为3个）
        Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
          // 检测Tab（原主页）
          TabContent() {
            this.DetectionContent()
          }
          .tabBar(this.TabBuilder({
            title: '检测',
            icon: this.currentIndex == 0 ? $r("app.media.ic_home_bold") : $r("app.media.ic_home"),
            index: 0
          }))

          // 历史Tab
          TabContent() {
            this.HistoryContentBuilder()
          }
          .tabBar(this.TabBuilder({
            title: '历史',
            icon: this.currentIndex == 1 ? $r("app.media.ic_history") : $r("app.media.ic_history"),
            index: 1
          }))

          // 我的Tab（整合设置/警报/影响/参考）
          TabContent() {
            this.MyContentBuilder()
          }
          .tabBar(this.TabBuilder({
            title: '我的',
            icon: this.currentIndex == 2 ? $r("app.media.solar_user_circle_bold") : $r("app.media.ic_user"),
            index: 2
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
    }
    .hideTitleBar(true)  // 隐藏顶部标题栏，节省空间
    .id('mainAppId')
    .menus([])
    .hideToolBar(true)
    .mode(NavDestinationMode.STANDARD)
    .backgroundColor($r('sys.color.background_secondary'))
    .animation({ duration: 200, curve: Curve.Linear })
  }
}
