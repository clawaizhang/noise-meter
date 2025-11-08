import { navigationStack } from '../../constants/ProviderConstant';
import { AppStorageV2, curves, PersistenceV2 } from '@kit.ArkUI';
import display from '@ohos.display';
import { SpectrumChartComponent } from './SpectrumChartComponent';
import { SpectrumBarChartComponent } from './SpectrumBarChartComponent';
import { TimeDomainChartComponent } from './TimeDomainChartComponent';
import { LineChartSpectrumComponent } from './LineChartSpectrumComponent';
import { LineChartTimeDomainComponent } from './LineChartTimeDomainComponent';
import { StatisticsChartComponent } from '../statistics/StatisticsChartComponent';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { resourceManager } from '@kit.LocalizationKit';
import { image } from '@kit.ImageKit';
import { AppKeys } from '../../models/AppKeys';
import { AudioControllerService } from '../../services/AudioControllerService';
import { Throttle } from '../../utils/Debounce';

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
  @Local private currentTabIndex: number = 0; // 当前选中的标签页索引
  private animationTimeOutId: number | undefined;
  // 服务实例
  private audioControllerService: AudioControllerService = AudioControllerService.getInstance(this.ak, this.pk);
  // 双管线架构：UI显示状态
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();

  // 图表类型配置
  private readonly chartTypes: ChartTypeConfig[] = [
    { title: '频谱图', componentId: 0 },
    { title: '频谱柱状图', componentId: 1 },
    { title: '时域图', componentId: 2 },
    { title: '统计分布图', componentId: 3 }
  ]

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 图表内容区域 - 直接全屏显示
      Stack() {
        // 使用Tabs组件实现标签页切换
        Tabs({ index: this.currentTabIndex }) {
          ForEach(this.chartTypes, (item: ChartTypeConfig, index?: number) => {
            TabContent() {
              this.buildChartContent(item.title)
            }
            .tabBar(item.title)
          })
        }
        .vertical(false)
        .scrollable(true)
        .barMode(BarMode.Fixed)
        .barWidth('100%')
        .animationDuration(300)
        .onChange((index: number) => {
          this.currentTabIndex = index;
        })
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(16)
      }
      .layoutWeight(1)

      Column()
        .width(this.dWidthHeight)
        .height(this.dWidthHeight)
        .backgroundImage(this.bgImage)
        .scale({ x: this.dScale, y: this.dScale })
        .translate({ x: this.translateX, y: this.translateY })
    }.margin({ top: 16 })
  }

  /**
   * 构建图表内容 - 直接全屏显示，无需全屏按钮
   */
  @Builder
  buildChartContent(chartTitle: string) {
    Column() {
      // 图表组件 - 直接全屏显示
      if (chartTitle === '频谱图') {
        LineChartSpectrumComponent({ sampleRate: 44100 })
      } else if (chartTitle === '频谱柱状图') {
        SpectrumBarChartComponent()
      } else if (chartTitle === '时域图') {
        LineChartTimeDomainComponent({ sampleRate: 44100 })
      } else if (chartTitle === '统计分布图') {
        StatisticsChartComponent()
      }
    }
    .width('100%')
    .height('100%')
    .padding(8) // 减少padding，让图表更大
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
}
