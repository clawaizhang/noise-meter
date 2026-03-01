import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { LineChartSpectrumComponent } from '../decibel-meter/LineChartSpectrumComponent';
import { LineChartTimeDomainComponent } from '../decibel-meter/LineChartTimeDomainComponent';
import { StatisticsChartComponent } from '../statistics/StatisticsChartComponent';
import { AudioControllerService } from '../../services/AudioControllerService';
import { SpectrumQuickSettings } from '../decibel-meter/SpectrumQuickSettings';

// 图表类型配置接口
interface ChartTypeConfig {
  title: string;
  componentId: number;
}

/**
 * 主页仪表卡片组件
 * 支持紧凑模式和展开模式，可在主页直接查看频谱图表
 * 极简设计：无边框、无标题栏、右下角悬浮全屏按钮
 */
@ComponentV2
export struct DashboardHomeCard {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local private currentChartIndex: number = 0; // 当前选中的图表索引
  private readonly chartHeight: number = 320; // 图表区域高度
  private audioControllerService: AudioControllerService = AudioControllerService.getInstance(this.ak, this.pk);

  // 图表类型配置
  private readonly chartTypes: ChartTypeConfig[] = [
    { title: '频率频谱', componentId: 0 },
    { title: '时域波形', componentId: 1 },
    { title: '声级分布', componentId: 2 }
  ]

  aboutToAppear(): void {
    // 确保AudioControllerService已正确初始化
    console.info('[DashboardHomeCard] AudioControllerService实例状态:',
      this.audioControllerService ? '已初始化' : '未初始化');
  }

  build() {
    Column({ space: 0 }) {
      // 图表内容区域
      this.buildChartContent()
    }
    .width('100%')
    // 移除padding、backgroundColor、borderRadius、shadow，实现无边框效果
  }

  /**
   * 构建图表内容区域
   */
  @Builder
  private buildChartContent() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      // 图表区域
      Swiper() {
        ForEach(this.chartTypes, (item: ChartTypeConfig, index?: number) => {
          Stack() {
            this.buildExpandedChart(item.title)
          }
        }, (item: ChartTypeConfig, index?: number) => item.title)
      }
      .index(this.currentChartIndex)
      .loop(true)
      .indicator(true)
      .duration(300)
      .curve(Curve.EaseInOut)
      .onChange((index: number) => {
        this.currentChartIndex = index
      })
      .width('100%')
      .height('100%')

      // 左下角快捷设置工具栏 + 全屏按钮
      Row({ space: 8 }) {
        // 快捷设置工具栏 - 放在全屏按钮左边
        SpectrumQuickSettings()

        // 全屏按钮
        Button() {
          Text('⛶')
            .fontSize(14)
            .fontColor(Color.White)
        }
        .width(32)
        .height(32)
        .backgroundColor('rgba(0, 0, 0, 0.4)')
        .borderRadius(16)
        .stateEffect(true)
        .onClick(() => {
          this.enterFullscreen();
        })
      }
      .position({ x: '100%', y: '100%' })
      .translate({ x: -120, y: -44 })  // 往左移，避免超出
      .zIndex(10)
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .height(this.chartHeight)
    .backgroundColor($r('sys.color.background_secondary'))
    .clip(false) // 修改为false，避免裁剪快捷设置按钮
  }

  /**
   * 构建展开模式图表
   */
  @Builder
  private buildExpandedChart(chartTitle: string) {
    Column() {
      if (chartTitle === '频率频谱') {
        LineChartSpectrumComponent({
          sampleRate: 44100,
          isVisible: true,
          isPreviewMode: false
        })
      } else if (chartTitle === '时域波形') {
        LineChartTimeDomainComponent({
          sampleRate: 44100,
          isVisible: true,
          isPreviewMode: false
        })
      } else if (chartTitle === '声级分布') {
        StatisticsChartComponent({
          isVisible: true,
          isPreviewMode: false
        })
      }
    }
    .width('100%')
    .height('100%')
    .padding(4)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 进入全屏横屏模式
   */
  private async enterFullscreen(): Promise<void> {
    // 设置全屏状态，这会触发 NoiseMeterNavigation 显示全屏仪表
    this.ak.isDashboardFullscreen = true;
    console.info('[DashboardHomeCard] 进入全屏横屏模式');
  }
}
