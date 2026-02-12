import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { LineChartSpectrumComponent } from '../decibel-meter/LineChartSpectrumComponent';
import { LineChartTimeDomainComponent } from '../decibel-meter/LineChartTimeDomainComponent';
import { StatisticsChartComponent } from '../statistics/StatisticsChartComponent';
import { AudioControllerService } from '../../services/AudioControllerService';
import { WindowManager } from '../../utils/WindowManager';
import window from '@ohos.window';

// 图表类型配置接口
interface ChartTypeConfig {
  title: string;
  componentId: number;
}

/**
 * 主页仪表卡片组件
 * 支持紧凑模式和展开模式，可在主页直接查看频谱图表
 */
@ComponentV2
export struct DashboardHomeCard {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local private isExpanded: boolean = false; // 是否展开
  @Local private currentChartIndex: number = 0; // 当前选中的图表索引
  @Local private isLandscape: boolean = false; // 是否横屏模式
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
    Column() {
      // 头部区域：标题+操作按钮
      this.buildHeader()

      // 图表内容区域（仅展开时显示）
      if (this.isExpanded) {
        Column({ space: DesignConstants.SPACING_SM }) {
          this.buildChartContent()
          this.buildFooter()
        }
        .width('100%')
        .margin({ top: DesignConstants.SPACING_SM })
        .animation({
          duration: 300,
          curve: Curve.EaseInOut
        })
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_XL)
    .shadow(DesignConstants.SHADOW_SM)
  }

  /**
   * 构建头部区域
   */
  @Builder
  private buildHeader() {
    Row() {
      // 左侧：图标+标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_meter'))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.icon_primary'))

        Column({ space: DesignConstants.SPACING_XS }) {
          Text('频谱分析')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))

          Text(this.isExpanded ? this.chartTypes[this.currentChartIndex].title : '点击展开查看')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
      }

      Blank()

      // 右侧：操作按钮组
      Row({ space: DesignConstants.SPACING_SM }) {
        // 图表切换按钮（仅展开模式显示）
        if (this.isExpanded) {
          Button() {
            Text('切')
              .fontSize(11)
              .fontColor($r('sys.color.font_on_primary'))
              .fontWeight(FontWeight.Medium)
          }
          .width(32)
          .height(32)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(16)
          .onClick(() => {
            this.switchChart()
          })
        }

        // 横屏按钮（仅展开模式显示）
        if (this.isExpanded) {
          Button() {
            Text(this.isLandscape ? '竖' : '横')
              .fontSize(11)
              .fontColor($r('sys.color.font_on_primary'))
              .fontWeight(FontWeight.Medium)
          }
          .width(32)
          .height(32)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(16)
          .onClick(() => {
            this.toggleLandscape()
          })
        }

        // 展开/收起按钮
        Button() {
          Text(this.isExpanded ? '收' : '展')
            .fontSize(11)
            .fontColor($r('sys.color.font_on_primary'))
            .fontWeight(FontWeight.Medium)
        }
        .width(32)
        .height(32)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(16)
        .onClick(() => {
          this.toggleExpand()
        })
        .animation({
          duration: 200,
          curve: Curve.EaseInOut
        })
      }
    }
    .width('100%')
    .height(40)
  }

  /**
   * 构建图表内容区域
   */
  @Builder
  private buildChartContent() {
    Stack({ alignContent: Alignment.Center }) {
      // 展开模式：使用Swiper显示完整图表
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
    }
    .width('100%')
    .height(this.chartHeight)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .clip(true)
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
   * 构建底部区域
   */
  @Builder
  private buildFooter() {
    Row() {
      Text('左右滑动切换图表')
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_secondary'))

      Blank()

      // 图表指示器
      Row({ space: DesignConstants.SPACING_XS }) {
        ForEach(this.chartTypes, (item: ChartTypeConfig, index?: number) => {
          Circle()
            .width(6)
            .height(6)
            .fill(this.currentChartIndex === index ? $r('sys.color.icon_primary') : $r('sys.color.font_tertiary'))
            .animation({
              duration: 200,
              curve: Curve.EaseInOut
            })
        })
      }
    }
    .width('100%')
    .height(24)
  }

  /**
   * 切换展开/收起状态
   */
  private toggleExpand(): void {
    this.isExpanded = !this.isExpanded
    console.info(`[DashboardHomeCard] 卡片状态: ${this.isExpanded ? '展开' : '收起'}`)
  }

  /**
   * 切换图表
   */
  private switchChart(): void {
    this.currentChartIndex = (this.currentChartIndex + 1) % this.chartTypes.length
  }

  /**
   * 切换横屏/竖屏
   */
  private async toggleLandscape(): Promise<void> {
    const windowManager = WindowManager.getInstance()
    const newOrientation = this.isLandscape ?
      window.Orientation.PORTRAIT : window.Orientation.LANDSCAPE

    const success = await windowManager.setOrientation(newOrientation)
    if (success) {
      this.isLandscape = !this.isLandscape
      console.info(`[DashboardHomeCard] 切换至${this.isLandscape ? '横屏' : '竖屏'}`)
    }
  }
}
