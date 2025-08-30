import { DecibelMeter } from '../../components/decibel-meter/DecibelMeter';
import { navigationStack } from '../../constants/ProviderConstant';
import { DecibelHistory } from './DecibelHistoryNavigation';
import { Settings } from '../../components/Settings';
import { common } from '@kit.AbilityKit';
import promptAction from '@ohos.promptAction';
import { PreferenceKeyConstants } from '../../constants/PreferenceKeyConstants';
import { PreferenceService } from '../../services/PreferenceService';
import { ScreenshotUtils } from '../../utils/ScreenshotUtils';
import { emitter } from '@kit.BasicServicesKit';
import { WeightingType } from '../../constants/WeightingConstants';
import { ResponsiveLayout, Breakpoint, LayoutMode } from '../../utils/ResponsiveLayout';

// 导航菜单项接口定义
interface NavigationMenuItem {
  value: string;
  icon: Resource;
  action: () => void;
}

// 响应式数值接口定义
interface ResponsiveNumberValues {
  xsmall: number;
  small: number;
  medium: number;
  large: number;
  xlarge: number;
}

// 响应式字符串接口定义
interface ResponsiveStringValues {
  xsmall: string;
  small: string;
  medium: string;
  large: string;
  xlarge: string;
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
  @Local title:string = '仪表盘';
  @Local menuItems:Array<NavigationMenuItem> = [];
  @Local private responsiveLayout: ResponsiveLayout = ResponsiveLayout.getInstance()
  @Local private currentBreakpoint: Breakpoint = Breakpoint.XS
  @Local private currentLayoutMode: LayoutMode = LayoutMode.XSMALL
  @Local private isLandscape: boolean = false // 新增：横屏状态
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  
  aboutToDisappear(): void {
    // 移除ResponsiveLayout的监听器
    this.responsiveLayout.removeChangeListener((width, height, breakpoint, layoutMode) => {
      this.updateResponsiveLayout(width);
    });
  }

  // 更新响应式布局状态
  private updateResponsiveLayout(width: number): void {
    this.currentBreakpoint = this.responsiveLayout.getBreakpoint(width);
    this.currentLayoutMode = this.responsiveLayout.getLayoutMode(this.currentBreakpoint);
    // 获取当前屏幕信息来判断是否为横屏
    const screenInfo = this.responsiveLayout.getCurrentScreenInfo();
    this.isLandscape = screenInfo.isLandscape;
    console.info(`[FREQ_TRACE][Responsive] 导航断点: ${this.currentBreakpoint}, 布局模式: ${this.currentLayoutMode}, 横屏: ${this.isLandscape}`);
  }

  aboutToAppear(): void {
    // 初始化加权类型
    if (!this.preferenceService.getString(PreferenceKeyConstants.WEIGHTING)) {
      this.preferenceService.setString(PreferenceKeyConstants.WEIGHTING, WeightingType.A);
    }
    this.menuItems = this.noiseMeterMenus;
    this.preferenceService.setBoolean(PreferenceKeyConstants.METER_ON, true);
    this.meterOn = this.preferenceService.getBoolean(PreferenceKeyConstants.METER_ON, true);

    // 使用ResponsiveLayout的统一监听系统
    this.responsiveLayout.addChangeListener((width, height, breakpoint, layoutMode) => {
      this.updateResponsiveLayout(width);
      console.info(`[FREQ_TRACE][Responsive] 导航窗口尺寸变化: ${width}x${height}`);
    });
    
    // 初始化响应式布局状态
    const screenInfo = this.responsiveLayout.getCurrentScreenInfo();
    this.updateResponsiveLayout(screenInfo.width);
  }

  @Monitor('currentIndex')
  onTabIndexChange(monitor: IMonitor) {
    const currentValue = monitor.value<number>()?.now;
    if (currentValue === 0) {
      this.title  = '仪表盘';
      this.menuItems = this.noiseMeterMenus;
    }
    if (currentValue === 1) {
      this.title = '检测记录';
      this.menuItems = this.decibelHistoryMenus;
    }
    if (currentValue === 2) {
      this.title = '设置';
      this.menuItems = [];
    }
  }


  @Builder
  TabBuilder(title: string, icon: Resource, index: number) {
    // 横屏时使用纵向布局，竖屏时使用横向布局
    if (this.isLandscape) {
      // 横屏纵向布局
      Row() {
        Image(icon)
          .width(this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 20,
            small: 22,
            medium: 24,
            large: 26,
            xlarge: 28
          } as ResponsiveNumberValues))
          .height(this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 20,
            small: 22,
            medium: 24,
            large: 26,
            xlarge: 28
          } as ResponsiveNumberValues))
          .fillColor(this.currentIndex === index ? $r('app.color.icon_active') : $r('app.color.icon_inactive'))
          .margin({ right: 8 })
        Text(title)
          .fontSize(this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 10,
            small: 11,
            medium: 12,
            large: 13,
            xlarge: 14
          } as ResponsiveNumberValues))
          .fontColor(this.currentIndex === index ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
      }
      .width('100%')
      .height(this.responsiveLayout.getResponsiveValue<number>({
        xsmall: 48,
        small: 52,
        medium: 56,
        large: 60,
        xlarge: 64
      } as ResponsiveNumberValues))
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 12 })
    } else {
      // 竖屏横向布局
      Column() {
        Image(icon)
          .width(this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 20,
            small: 22,
            medium: 24,
            large: 26,
            xlarge: 28
          } as ResponsiveNumberValues))
          .height(this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 20,
            small: 22,
            medium: 24,
            large: 26,
            xlarge: 28
          } as ResponsiveNumberValues))
          .fillColor(this.currentIndex === index ? $r('app.color.icon_active') : $r('app.color.icon_inactive'))
        Text(title)
          .fontSize(this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 10,
            small: 11,
            medium: 12,
            large: 13,
            xlarge: 14
          } as ResponsiveNumberValues))
          .fontColor(this.currentIndex === index ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
          .margin({ top: this.responsiveLayout.getResponsiveValue<number>({
            xsmall: 2,
            small: 3,
            medium: 4,
            large: 5,
            xlarge: 6
          } as ResponsiveNumberValues) })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
  }

  private noiseMeterMenus: Array<NavigationMenuItem> = [
    {
      value: this.meterOn ? '关机' : '开机',
      icon: this.meterOn ? $r("app.media.ic_power_off") : $r('app.media.ic_power_on'),
      action: () => {
        if (this.meterOn) {
          promptAction.showDialog({
            title: '确认关机',
            message: '确认要关闭仪表盘吗？',
            buttons: [
              {
                text: '取消',
                color: $r('app.color.text_secondary')
              },
              {
                text: '确认',
                color: $r('app.color.button_danger')
              }
            ]
          }).then((result) => {
            if (result.index === 1) { // 1 表示确定按钮
              this.meterOn = false;
              this.preferenceService.setBoolean(PreferenceKeyConstants.METER_ON, false);
            }
          });
        } else {
          this.meterOn = true;
          this.preferenceService.setBoolean(PreferenceKeyConstants.METER_ON, true);
        }
      }
    },
    {
      value: '参考标准',
      icon: $r('app.media.ic_info'),
      action: () => {
        this.navStack.pushPathByName('NoiseStandardDialog', null);
      }
    },
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
          'decibelMeterRoot',
          `noise_meter_screenshot_${timestamp}.jpg`,
          '噪音分贝仪截图',
          '当前噪音检测结果截图'
        );
      }
    }
  ]

  private decibelHistoryMenus: Array<NavigationMenuItem> = [{
    value: '清空记录',
    icon: $r('app.media.ic_delete'),
    action: () => {
      emitter.emit({ eventId: 101 })
    }
  }]

  build() {
    NavDestination() {
      Tabs({
        barPosition: BarPosition.End, // 横屏时tab在左侧，竖屏时在底部
        index: this.currentIndex
      }) {
        TabContent() {
          Column() {

            // 噪音检测区域
            DecibelMeter({ meterOn: this.meterOn })
              .width(this.responsiveLayout.getResponsiveValue<string>({
                xsmall: '88%',
                small: '90%',
                medium: '92%',
                large: '94%',
                xlarge: '96%'
              } as ResponsiveStringValues))
          }
          .id('decibelMeterRoot')
          .width('100%')
          .height('100%')
          .backgroundColor($r('app.color.background_secondary'))
          .alignItems(HorizontalAlign.Center)
        }
        .tabBar(this.TabBuilder('仪表盘', $r('app.media.ic_meter'), 0))

        TabContent() {
          DecibelHistory({ currentTabIndex: this.currentIndex })
        }
        .tabBar(this.TabBuilder('检测记录', $r('app.media.ic_history'), 1))

        // TabContent() {
        //   LeqStatistics()
        // }
        // .tabBar(this.TabBuilder('统计', $r('app.media.ic_stats'), 2))

        TabContent() {
          Settings()
        }
        .tabBar(this.TabBuilder('设置', $r('app.media.ic_settings'), 2))
      }
      .scrollable(false)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .width('100%')
      .height('100%')
      .barHeight(this.isLandscape ?
        // 横屏时tab栏高度自适应
        '100%' :
        // 竖屏时使用响应式高度
        this.responsiveLayout.getResponsiveValue<number>({
          xsmall: 48,
          small: 50,
          medium: 56,
          large: 60,
          xlarge: 64
        } as ResponsiveNumberValues)
      )
      .barWidth(this.isLandscape ?
        // 横屏时tab栏宽度使用响应式值
        this.responsiveLayout.getResponsiveValue<number>({
          xsmall: 80,
          small: 90,
          medium: 100,
          large: 110,
          xlarge: 120
        } as ResponsiveNumberValues) :
        // 竖屏时宽度自适应
        '100%'
      )
      .barMode(BarMode.Fixed)
      .vertical(this.isLandscape)
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
