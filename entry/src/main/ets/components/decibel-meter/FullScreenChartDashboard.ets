/**
 * 全屏图表仪表盘组件
 * 提供单图全屏显示功能，支持底部标签栏切换和手势滑动切换
 */

import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { SpectrumChartComponent } from './SpectrumChartComponent';
import { TimeDomainChartComponent } from './TimeDomainChartComponent';
import { StatisticsChartComponent } from '../statistics/StatisticsChartComponent';

// 图表类型枚举
enum ChartType {
  SPECTRUM = 'spectrum',
  TIME_DOMAIN = 'time_domain',
  STATISTICS = 'statistics'
}

@ComponentV2
export struct FullScreenChartDashboard {
  // 依赖注入
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();

  // 组件状态
  @Local private currentChartType: ChartType = ChartType.SPECTRUM;
  @Local private isAnimating: boolean = false;
  @Local private chartOpacity: number = 1;
  @Local private swipeStartX: number = 0;
  @Local private swipeEndX: number = 0;
  @Local private swipeOffset: number = 0;


  aboutToAppear() {
    console.info('[全屏仪表盘] 组件初始化完成');
  }

  aboutToDisappear() {
    console.info('[全屏仪表盘] 组件即将销毁');
  }

  /**
   * 切换到指定图表类型
   */
  private switchToChart(chartType: ChartType): void {
    if (this.isAnimating || this.currentChartType === chartType) {
      return;
    }

    console.info(`[全屏仪表盘] 切换图表: ${this.currentChartType} -> ${chartType}`);
    this.startSwitchAnimation(chartType);
  }

  /**
   * 开始切换动画
   */
  private startSwitchAnimation(targetChartType: ChartType): void {
    this.isAnimating = true;

    // 淡出动画
    this.getUIContext().animateTo({
      duration: 200,
      curve: Curve.EaseOut,
      onFinish: () => {
        // 切换图表类型
        this.currentChartType = targetChartType;
        
        // 淡入动画
        this.getUIContext().animateTo({
          duration: 200,
          curve: Curve.EaseIn,
          onFinish: () => {
            this.isAnimating = false;
            this.swipeOffset = 0;
          }
        }, () => {
          this.chartOpacity = 1;
        });
      }
    }, () => {
      this.chartOpacity = 0;
    });
  }

  /**
   * 处理手势滑动开始
   */
  private handleSwipeStart(event: GestureEvent): void {
    if (this.isAnimating) return;
    
    this.swipeStartX = event.offsetX;
    this.swipeEndX = event.offsetX;
    this.swipeOffset = 0;
  }

  /**
   * 处理手势滑动更新
   */
  private handleSwipeUpdate(event: GestureEvent): void {
    if (this.isAnimating) return;
    
    this.swipeEndX = event.offsetX;
    this.swipeOffset = this.swipeEndX - this.swipeStartX;
  }

  /**
   * 处理手势滑动结束
   */
  private handleSwipeEnd(event: GestureEvent): void {
    if (this.isAnimating) return;

    const swipeDistance = this.swipeEndX - this.swipeStartX;
    const minSwipeDistance = 50; // 最小滑动距离阈值

    if (Math.abs(swipeDistance) > minSwipeDistance) {
      if (swipeDistance > 0) {
        // 右滑 - 切换到上一个图表
        this.switchToPreviousChart();
      } else {
        // 左滑 - 切换到下一个图表
        this.switchToNextChart();
      }
    } else {
      // 滑动距离不足，恢复原位
      this.swipeOffset = 0;
    }
  }

  /**
   * 切换到下一个图表
   */
  private switchToNextChart(): void {
    const chartTypes = [ChartType.SPECTRUM, ChartType.TIME_DOMAIN, ChartType.STATISTICS];
    const currentIndex = chartTypes.indexOf(this.currentChartType);
    const nextIndex = (currentIndex + 1) % chartTypes.length;
    
    this.switchToChart(chartTypes[nextIndex]);
  }

  /**
   * 切换到上一个图表
   */
  private switchToPreviousChart(): void {
    const chartTypes = [ChartType.SPECTRUM, ChartType.TIME_DOMAIN, ChartType.STATISTICS];
    const currentIndex = chartTypes.indexOf(this.currentChartType);
    const prevIndex = (currentIndex - 1 + chartTypes.length) % chartTypes.length;
    
    this.switchToChart(chartTypes[prevIndex]);
  }

  /**
   * 获取图表类型对应的显示名称
   */
  private getChartDisplayName(chartType: ChartType): string {
    switch (chartType) {
      case ChartType.SPECTRUM:
        return '频谱图';
      case ChartType.TIME_DOMAIN:
        return '时域图';
      case ChartType.STATISTICS:
        return '统计分布图';
      default:
        return '未知图表';
    }
  }

  /**
   * 构建底部标签栏
   */
  @Builder
  private buildTabBar() {
    Row({ space: 0 }) {
      // 频谱图标签
      Column({ space: 4 }) {
        Text('频谱图')
          .fontSize(14)
          .fontColor(this.currentChartType === ChartType.SPECTRUM ? 
            $r('sys.color.ohos_id_color_primary') : 
            $r('sys.color.ohos_id_color_text_secondary'))
          .fontWeight(this.currentChartType === ChartType.SPECTRUM ? FontWeight.Medium : FontWeight.Normal)
        
        // 选中指示器
        if (this.currentChartType === ChartType.SPECTRUM) {
          Row()
            .width(24)
            .height(3)
            .backgroundColor($r('sys.color.ohos_id_color_primary'))
            .borderRadius(2)
        } else {
          Row()
            .width(24)
            .height(3)
            .backgroundColor(Color.Transparent)
        }
      }
      .layoutWeight(1)
      .height(56)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.switchToChart(ChartType.SPECTRUM);
      })

      // 时域图标签
      Column({ space: 4 }) {
        Text('时域图')
          .fontSize(14)
          .fontColor(this.currentChartType === ChartType.TIME_DOMAIN ? 
            $r('sys.color.ohos_id_color_primary') : 
            $r('sys.color.ohos_id_color_text_secondary'))
          .fontWeight(this.currentChartType === ChartType.TIME_DOMAIN ? FontWeight.Medium : FontWeight.Normal)
        
        // 选中指示器
        if (this.currentChartType === ChartType.TIME_DOMAIN) {
          Row()
            .width(24)
            .height(3)
            .backgroundColor($r('sys.color.ohos_id_color_primary'))
            .borderRadius(2)
        } else {
          Row()
            .width(24)
            .height(3)
            .backgroundColor(Color.Transparent)
        }
      }
      .layoutWeight(1)
      .height(56)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.switchToChart(ChartType.TIME_DOMAIN);
      })

      // 统计分布图标签
      Column({ space: 4 }) {
        Text('统计分布图')
          .fontSize(14)
          .fontColor(this.currentChartType === ChartType.STATISTICS ? 
            $r('sys.color.ohos_id_color_primary') : 
            $r('sys.color.ohos_id_color_text_secondary'))
          .fontWeight(this.currentChartType === ChartType.STATISTICS ? FontWeight.Medium : FontWeight.Normal)
        
        // 选中指示器
        if (this.currentChartType === ChartType.STATISTICS) {
          Row()
            .width(24)
            .height(3)
            .backgroundColor($r('sys.color.ohos_id_color_primary'))
            .borderRadius(2)
        } else {
          Row()
            .width(24)
            .height(3)
            .backgroundColor(Color.Transparent)
        }
      }
      .layoutWeight(1)
      .height(56)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        this.switchToChart(ChartType.STATISTICS);
      })
    }
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_primary'))
    .border({
      width: { top: 1 },
      color: $r('sys.color.comp_border_color'),
      style: BorderStyle.Solid
    })
  }

  /**
   * 构建图表显示区域
   */
  @Builder
  private buildChartArea() {
    Stack({ alignContent: Alignment.Center }) {
      // 频谱图
      if (this.currentChartType === ChartType.SPECTRUM) {
        Column() {
          SpectrumChartComponent()
        }
        .width('100%')
        .height('100%')
        .opacity(this.chartOpacity)
        .translate({ x: this.swipeOffset })
      }

      // 时域图
      if (this.currentChartType === ChartType.TIME_DOMAIN) {
        Column() {
          TimeDomainChartComponent()
        }
        .width('100%')
        .height('100%')
        .opacity(this.chartOpacity)
        .translate({ x: this.swipeOffset })
      }

      // 统计分布图
      if (this.currentChartType === ChartType.STATISTICS) {
        Column() {
          StatisticsChartComponent()
        }
        .width('100%')
        .height('100%')
        .opacity(this.chartOpacity)
        .translate({ x: this.swipeOffset })
      }
    }
    .width('100%')
    .height('100%')
    .layoutWeight(1)
    .gesture(
      PanGesture({ direction: PanDirection.Horizontal, distance: 5 })
        .onActionStart((event: GestureEvent) => {
          this.handleSwipeStart(event);
        })
        .onActionUpdate((event: GestureEvent) => {
          this.handleSwipeUpdate(event);
        })
        .onActionEnd((event: GestureEvent) => {
          this.handleSwipeEnd(event);
        })
        .onActionCancel(() => {
          this.swipeOffset = 0;
        })
    )
  }

  build() {
    Column() {
      // 图表显示区域
      this.buildChartArea()


      // 底部标签栏
      this.buildTabBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.comp_background_primary'))
  }
}