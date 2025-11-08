import { navigationStack } from '../../constants/ProviderConstant';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import display from '@ohos.display';
import { SpectrumBarChartComponent } from './SpectrumBarChartComponent';
import { LineChartSpectrumComponent } from './LineChartSpectrumComponent';
import { LineChartTimeDomainComponent } from './LineChartTimeDomainComponent';
import { StatisticsChartComponent } from '../statistics/StatisticsChartComponent';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { resourceManager } from '@kit.LocalizationKit';
import { image } from '@kit.ImageKit';
import { AppKeys } from '../../models/AppKeys';
import { AudioControllerService } from '../../services/AudioControllerService';

// 图表类型配置接口
interface ChartTypeConfig {
  title: string;
  componentId: number;
}

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
  @Local private currentTabIndex: number = 0; // 当前选中的图表索引
  @Local private showNavigationButtons: boolean = false; // 是否显示导航按钮
  @Local private navigationButtonsOpacity: number = 0; // 导航按钮透明度
  private animationTimeOutId: number | undefined;
  private navigationButtonsTimeoutId: number | undefined;
  // 服务实例
  private audioControllerService: AudioControllerService = AudioControllerService.getInstance(this.ak, this.pk);
  // 双管线架构：UI显示状态
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();

  // 图表类型配置
  private readonly chartTypes: ChartTypeConfig[] = [
    { title: '频率频谱图', componentId: 0 },
    { title: '频谱柱状图', componentId: 1 },
    { title: '时域波形图', componentId: 2 },
    { title: '声级分布图', componentId: 3 }
  ]

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 使用Swiper组件实现图表切换
      Swiper() {
        ForEach(this.chartTypes, (item: ChartTypeConfig, index?: number) => {
          Stack() {
            // 图表内容
            this.buildChartContent(item.title)
          }
        }, (item: ChartTypeConfig, index?: number) => item.title)
      }
      .index(this.currentTabIndex)
      .loop(true)
      .indicator(true) // 禁用默认指示器
      .duration(300) // 设置切换动画时长
      .curve(Curve.EaseInOut) // 设置动画曲线
      .onChange((index: number) => {
        this.currentTabIndex = index;
      })
      .width('100%')
      .height('100%')
      .borderRadius(16)
      .onClick(() => {
        // 点击图表区域显示导航按钮
        this.showNavigationButtons = true;
        this.navigationButtonsOpacity = 1;
        
        // 清除之前的超时
        if (this.navigationButtonsTimeoutId) {
          clearTimeout(this.navigationButtonsTimeoutId);
        }
        
        // 设置3秒后自动隐藏导航按钮
        this.navigationButtonsTimeoutId = setTimeout(() => {
          this.getUIContext().animateTo({
            duration: 300,
            curve: Curve.EaseOut,
            onFinish: () => {
              this.showNavigationButtons = false;
              this.navigationButtonsOpacity = 0;
            }
          }, () => {
            this.navigationButtonsOpacity = 0;
          });
        }, 3000);
      })
      
      // 当前图表标题指示器 - 置于最上层
      if (this.showNavigationButtons) {
        Text(this.chartTypes[this.currentTabIndex].title)
          .fontSize(14)
          .fontColor(Color.White)
          .opacity(this.navigationButtonsOpacity * 0.8)
          .position({ x: '50%', y: 24 })
          .translate({ x: -50, y: 0 })
          .textAlign(TextAlign.Center)
          .width(100)
          .backgroundColor('rgba(0, 0, 0, 0.6)')
          .padding(8)
          .borderRadius(16)
          .animation({
            duration: 300,
            curve: Curve.EaseInOut
          })
          .zIndex(10) // 确保标题在最上层
      }

      Column()
        .width(this.dWidthHeight)
        .height(this.dWidthHeight)
        .backgroundImage(this.bgImage)
        .scale({ x: this.dScale, y: this.dScale })
        .translate({ x: this.translateX, y: this.translateY })
    }.margin({ top: 8, left: 8, right: 8, bottom: 8 })
  }

  /**
   * 构建图表内容 - 直接全屏显示，无需全屏按钮
   */
  @Builder
  buildChartContent(chartTitle: string) {
    Column() {
      // 图表组件 - 直接全屏显示
      if (chartTitle === '频率频谱图') {
        LineChartSpectrumComponent({ sampleRate: 44100 })
      } else if (chartTitle === '频谱柱状图') {
        SpectrumBarChartComponent()
      } else if (chartTitle === '时域波形图') {
        LineChartTimeDomainComponent({ sampleRate: 44100 })
      } else if (chartTitle === '声级分布图') {
        StatisticsChartComponent()
      }
    }
    .width('100%')
    .height('100%')
    .padding(0) // 完全移除padding以最大化显示区域
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 重置导航按钮超时
   */
  private resetNavigationTimeout() {
    // 清除之前的超时
    if (this.navigationButtonsTimeoutId) {
      clearTimeout(this.navigationButtonsTimeoutId);
    }
    
    // 设置3秒后自动隐藏导航按钮
    this.navigationButtonsTimeoutId = setTimeout(() => {
      this.getUIContext().animateTo({
        duration: 300,
        curve: Curve.EaseOut,
        onFinish: () => {
          this.showNavigationButtons = false;
          this.navigationButtonsOpacity = 0;
        }
      }, () => {
        this.navigationButtonsOpacity = 0;
      });
    }, 3000);
  }

  aboutToDisappear() {
    // 清理资源
    this.audioControllerService.dispose();
    
    // 清理导航按钮超时ID
    if (this.navigationButtonsTimeoutId) {
      clearTimeout(this.navigationButtonsTimeoutId);
      this.navigationButtonsTimeoutId = undefined;
    }
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
}
