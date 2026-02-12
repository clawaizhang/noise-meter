import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { LineChartSpectrumComponent } from '../decibel-meter/LineChartSpectrumComponent';
import { LineChartTimeDomainComponent } from '../decibel-meter/LineChartTimeDomainComponent';
import { StatisticsChartComponent } from '../statistics/StatisticsChartComponent';
import { WindowManager } from '../../utils/WindowManager';
import window from '@ohos.window';

// 图表类型配置接口
interface ChartTypeConfig {
  title: string;
  shortTitle: string;
  componentId: number;
}

/**
 * 仪表全屏横屏组件
 * 占满整个屏幕，无标题栏无Tab栏，沉浸式查看图表
 */
@ComponentV2
export struct DashboardFullscreen {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local private currentChartIndex: number = 0; // 当前选中的图表索引
  @Local private showControls: boolean = true; // 是否显示控制按钮

  // 图表类型配置
  private readonly chartTypes: ChartTypeConfig[] = [
    { title: '频率频谱', shortTitle: '频谱', componentId: 0 },
    { title: '时域波形', shortTitle: '波形', componentId: 1 },
    { title: '声级分布', shortTitle: '分布', componentId: 2 }
  ]

  aboutToAppear(): void {
    console.info('[DashboardFullscreen] 进入全屏横屏模式');
  }

  aboutToDisappear(): void {
    console.info('[DashboardFullscreen] 退出全屏横屏模式');
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 图表内容 - 占满全屏
      this.buildFullscreenChart()

      // 当控制按钮隐藏时，显示透明层用于点击显示控制按钮
      if (!this.showControls) {
        Row()
          .width('100%')
          .height('100%')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showControls = true;
          })
          .zIndex(10)
      }

      // 悬浮控制层 - 最上层
      if (this.showControls) {
        this.buildFloatingControls()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
  }

  /**
   * 构建全屏图表
   */
  @Builder
  private buildFullscreenChart() {
    Swiper() {
      ForEach(this.chartTypes, (item: ChartTypeConfig, index?: number) => {
        Stack() {
          this.buildChart(item.title)
        }
      }, (item: ChartTypeConfig, index?: number) => item.title)
    }
    .index(this.currentChartIndex)
    .loop(true)
    .indicator(false)
    .duration(300)
    .curve(Curve.EaseInOut)
    .onChange((index: number) => {
      this.currentChartIndex = index;
    })
    .width('100%')
    .height('100%')        .zIndex(1)

  }

  /**
   * 构建图表
   */
  @Builder
  private buildChart(chartTitle: string) {
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
   * 构建悬浮控制层
   */
  @Builder
  private buildFloatingControls() {
    Stack({ alignContent: Alignment.Center }) {
      // 中间透明区域 - 点击隐藏控制按钮（先添加，在最底层）
      Row()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showControls = false;
        })
        .zIndex(21)

      // 顶部：标题和退出按钮（后添加，在中间层之上）
      this.buildTopFloatingControls()


      // 底部：图表切换按钮（最后添加，在最上层）
      this.buildBottomFloatingControls()
    }
    .width('100%')
    .height('100%')
    .animation({
      duration: 200,
      curve: Curve.EaseInOut
    })
    .zIndex(20)
  }

  /**
   * 构建顶部悬浮控制 - 半透明设计
   */
  @Builder
  private buildTopFloatingControls() {
    Row() {
      // 左侧：当前图表标题 - 半透明悬浮卡片
      Row({ space: 6 }) {
        Image($r('app.media.ic_meter'))
          .width(16)
          .height(16)
          .fillColor($r('sys.color.font_primary'))

        Text(this.chartTypes[this.currentChartIndex].title)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor('rgba(128, 128, 128, 0.6)')
      .borderRadius(16)

      Blank()

      // 右侧：退出按钮 - 半透明悬浮
      Button() {
        Text('退出')
          .fontSize(11)
          .fontColor($r('sys.color.font_primary'))
      }
      .width(48)
      .height(32)
      .backgroundColor('rgba(128, 128, 128, 0.6)')
      .borderRadius(16)
      .onClick(() => {
        this.exitFullscreen();
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12 })
    .position({ x: 0, y: 0 })
    .align(Alignment.Top).zIndex(22)
  }

  /**
   * 构建底部悬浮控制 - 半透明设计
   */
  @Builder
  private buildBottomFloatingControls() {
    Row({ space: 8 }) {
      // 三个图表切换按钮 - 半透明悬浮胶囊
      ForEach(this.chartTypes, (item: ChartTypeConfig, index?: number) => {
        Button() {
          Text(item.shortTitle)
            .fontSize(11)
            .fontColor(this.currentChartIndex === index ? 
              $r('sys.color.font_emphasize') : $r('sys.color.font_primary'))
            .fontWeight(this.currentChartIndex === index ? FontWeight.Medium : FontWeight.Normal)
        }
        .width(52)
        .height(32)
        .backgroundColor(this.currentChartIndex === index ? 
          'rgba(128, 128, 128, 0.5)' : 'rgba(128, 128, 128, 0.6)')
        .borderRadius(16)
        .onClick(() => {
          if (index !== undefined) {
            this.currentChartIndex = index;
          }
        })
      })
      
    }
    .padding({ left: 16, right: 16, bottom: 16 })
    .position({ x: 0, y: '100%' })
    .translate({ y: -56 })
    .align(Alignment.Bottom)        .zIndex(22)

  }

  /**
   * 退出全屏横屏模式
   */
  private async exitFullscreen(): Promise<void> {
    const windowManager = WindowManager.getInstance();
    await windowManager.setOrientation(window.Orientation.PORTRAIT);
    this.ak.isDashboardFullscreen = false;
    console.info('[DashboardFullscreen] 退出全屏模式');
  }
}
