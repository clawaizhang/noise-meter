import { navigationStack } from '../../constants/ProviderConstant';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import display from '@ohos.display';
import { SpectrumChartComponent } from './SpectrumChartComponent';
import { TimeDomainChartComponent } from './TimeDomainChartComponent';
import { StatisticsChartComponent } from '../statistics/StatisticsChartComponent';
import { FullScreenChartDashboard } from './FullScreenChartDashboard';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { LocationInfo } from '../../services/LocationService';
import { LocationDisplay } from '../business/LocationDisplay';
import { resourceManager } from '@kit.LocalizationKit';
import { image } from '@kit.ImageKit';
import { AppKeys } from '../../models/AppKeys';
import { PermissionService } from '../../services/PermissionService';
import { AudioController } from './AudioController';
import { AudioControllerService } from '../../services/AudioControllerService';
import { AudioDeviceMonitorService } from '../../services/AudioDeviceMonitorService';
import { Throttle } from '../../utils/Debounce';
import { StatusAlertsComponent } from '../status-alerts/StatusAlertsComponent';

@ComponentV2
export struct DashBoard {
  @Param @Require meterOn: boolean = true;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local dScale: number = 1; // 页面缩放比例
  @Local translateX: number = 0; // X轴位移
  @Local translateY: number = 0; // Y轴位移
  @Local dOpacity: number = 1; // 页面透明度
  @Local dWidthHeight: string = ''; // 页面透明度
  @Local bgImage: image.PixelMap | undefined = undefined; // 页面透明度
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private isFullScreenMode: boolean = false; // 全屏模式状态
  @Local private currentFullScreenChartType: string = '频谱图'; // 当前全屏显示的图表类型
  private animationTimeOutId: number | undefined;
  // 服务实例
  private audioControllerService: AudioControllerService = AudioControllerService.getInstance(this.ak, this.pk);
  // 双管线架构：UI显示状态
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 全屏模式显示
      if (this.isFullScreenMode) {
        FullScreenChartDashboard({
          canvasWidth: this.ak.windowWidth - 32,
          canvasHeight: this.ak.windowHeight - 330, // 重新计算高度：120 + 底部标签栏56px
          initialChartType: this.currentFullScreenChartType,
          onExitFullScreen: () => {
            this.exitFullScreenMode();
          },
        })
          .borderRadius(16)
          .width('100%')
          .height('100%')
      } else {
        // 正常模式显示
        Scroll() {
          GridRow({ columns: 12, breakpoints: { reference: BreakpointsReference.WindowSize }, gutter: 16 }) {

            // 频谱图 - 优化布局，占据更多空间
            GridCol({
              span: {
                xs: 12, // 横向XS/SM：单列布局（全宽）
                sm: 12, // 横向XS/SM：单列布局（全宽）
                md: 6, // 横向MD及以上：双列布局（半宽）
                lg: 6, // 横向MD及以上：双列布局（半宽）
                xl: 6    // 横向MD及以上：双列布局（半宽）
              }
            }) {
              Column() {
                SpectrumChartComponent()

                // 全屏按钮
                this.buildFullScreenButton('频谱图')
              }
            }
            .backgroundColor($r('sys.color.comp_background_primary'))
            .borderRadius(16)

            // 时域波形图 - 优化布局，占据更多空间
            GridCol({
              span: {
                xs: 12, // 横向XS/SM：单列布局（全宽）
                sm: 12, // 横向XS/SM：单列布局（全宽）
                md: 6, // 横向MD及以上：双列布局（半宽）
                lg: 6, // 横向MD及以上：双列布局（半宽）
                xl: 6    // 横向MD及以上：双列布局（半宽）
              }
            }) {
              Column() {
                TimeDomainChartComponent()

                // 全屏按钮
                this.buildFullScreenButton('时域图')
              }
            }
            .backgroundColor($r('sys.color.comp_background_primary'))
            .borderRadius(16)

            // 统计分布图 - 新增统计图表组件
            GridCol({
              span: {
                xs: 12, // 横向XS/SM：单列布局（全宽）
                sm: 12, // 横向XS/SM：单列布局（全宽）
                md: 6, // 横向MD及以上：双列布局（半宽）
                lg: 6, // 横向MD及以上：双列布局（半宽）
                xl: 6    // 横向MD及以上：双列布局（半宽）
              }
            }) {
              Column() {
                StatisticsChartComponent()

                // 全屏按钮
                this.buildFullScreenButton('统计分布图')

              }
            }
            .borderRadius(16)
            .backgroundColor($r('sys.color.comp_background_primary'))
          }
          .id('mainNoiseMeterDisplayId')
          .onBreakpointChange(breakPoints => {
            // 断点信息现在由 AppStorage 统一管理，这里不再需要处理
            console.info(`[CAT_ANIMATION] GridRow 断点变化: ${breakPoints}`);
          })
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }

      Column()
        .width(this.dWidthHeight)
        .height(this.dWidthHeight)
        .backgroundImage(this.bgImage)
        .scale({ x: this.dScale, y: this.dScale })
        .translate({ x: this.translateX, y: this.translateY })
    }.margin({ top: 16 })
  }

  aboutToDisappear() {
    // 清理资源
    this.audioControllerService.dispose();
  }

  aboutToAppear() {

    // 确保AudioControllerService已正确初始化
    console.info('[DecibelMeter] AudioControllerService实例状态:',
      this.audioControllerService ? '已初始化' : '未初始化');
  }

  // 启动折叠动画
  startCollapseAnimation() {
    // 获取屏幕尺寸
    const displayClass = display.getDefaultDisplaySync();
    this.dWidthHeight = '100%';
    this.animationTimeOutId = setTimeout(() => {
      // 页面内容动画
      this.getUIContext().animateTo({
        duration: 800,
        curve: Curve.EaseIn,
        onFinish: () => {
          this.dScale = 1;
          this.translateX = 0;
          this.translateY = 0;
          this.bgImage = undefined;
          this.dWidthHeight = '';
          clearTimeout(this.animationTimeOutId);
        }
      }, () => {
        this.dScale = 0.05;
        this.translateX = this.getUIContext().px2vp(displayClass.width) / 2 - 30;
        this.translateY = -this.getUIContext().px2vp(displayClass.height) / 2 + 20;
      });
    }, 100)
  }

  /**
   * 构建全屏按钮
   */
  @Builder
  buildFullScreenButton(chartType: string) {
    Row() {
      Blank()

      Button('全屏查看')
        .fontSize(12)
        .type(ButtonType.Capsule)
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .fontColor($r('sys.color.font_secondary'))
        .padding({
          left: 12,
          right: 12,
          top: 6,
          bottom: 6
        })
        .onClick(() => {
          Throttle.click(() => {
            this.enterFullScreenMode(chartType);
          })
        })
    }
    .width('100%')
    .padding(8)
  }

  /**
   * 进入全屏模式
   */
  private enterFullScreenMode(chartType: string): void {
    console.info(`[全屏模式] 进入全屏模式，图表类型: ${chartType}`);
    this.isFullScreenMode = true;
    // 将图表类型传递给全屏组件
    this.currentFullScreenChartType = chartType;
  }

  /**
   * 退出全屏模式
   */
  private exitFullScreenMode(): void {
    console.info('[全屏模式] 退出全屏模式');
    this.isFullScreenMode = false;
  }
}
