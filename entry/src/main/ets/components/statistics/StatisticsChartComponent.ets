/**
 * 统计分布图组件 - 基于mpchart库重构版本
 * 使用BarChart组件替代Canvas绘制，提供更好的性能和交互体验
 * 遵循ArkTS规范，保持原有的数据结构和功能
 * 统一图表风格，与频谱柱状图保持一致
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { UnifiedChartStyle } from '../common/charts/UnifiedChartStyle';
import {
  BarChart,
  BarChartModel,
  BarData,
  BarDataSet,
  BarEntry,
  JArrayList,
  IValueFormatter,
  XAxisPosition,
  LimitLine,
  LimitLabelPosition,
  YAxis,
  YAxisLabelPosition
} from '@ohos/mpchart';
import { UiStatisticsData } from '../../models/UIDisplayState';

// 字体大小配置类
class FontSizeConfig {
  title: number = 16;
  axis: number = 13;
  stats: number = 14;
  small: number = 10;
}

// 布局配置类
class LayoutConfig {
  chartHeight: Length = 150;
  statsHeight: Length = 60;
  fontSize: FontSizeConfig = new FontSizeConfig();
}

// X轴值格式化器
class XAxisValueFormatter implements IValueFormatter {
  private labels: string[];

  constructor(labels: string[]) {
    this.labels = labels;
  }

  getFormattedValue(value: number): string {
    const index = Math.round(value);
    return index >= 0 && index < this.labels.length ? this.labels[index] : '';
  }
}

@ComponentV2
export struct StatisticsChartComponent {
  // 输入参数
  @Param canvasWidthInput: number = 0;
  @Param canvasHeightInput: number = 0;
  // 依赖注入
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  // BarChart模型
  @Local private barChartModel: BarChartModel = new BarChartModel();
  @Local private barData: BarData = new BarData();
  // 布局状态
  @Local private layoutConfig: LayoutConfig = this.getDefaultLayoutConfig();

  // 监听状态变化
  @Monitor('ak.uiDisplayState.displayDb')
  private onDistributionChange() {
    this.updateChartData();
  }

  @Monitor('ak.uiDisplayState.displayStatistics')
  private onStatisticsChange() {
    this.updateChartData();
  }

  @Monitor('ak.windowWidthBreakpoint')
  private onWindowSizeChange() {
    this.layoutConfig = this.getLayoutConfig();
  }

  aboutToAppear() {
    this.initializeChart();
  }

  // 获取默认布局配置
  private getDefaultLayoutConfig(): LayoutConfig {
    const config = new LayoutConfig();
    config.chartHeight = 150;
    config.statsHeight = 60;
    config.fontSize = new FontSizeConfig();
    config.fontSize.title = UnifiedChartStyle.FONT_SIZES.title;
    config.fontSize.axis = UnifiedChartStyle.FONT_SIZES.axis;
    config.fontSize.stats = UnifiedChartStyle.FONT_SIZES.stats || 14;
    config.fontSize.small = UnifiedChartStyle.FONT_SIZES.value;
    return config;
  }

  // 获取响应式布局配置
  private getLayoutConfig(): LayoutConfig {
    const isSmallScreen = this.ak.windowWidthBreakpoint <= 1;
    const isFullScreen = this.ak.windowWidthBreakpoint >= 3;

    const config = new LayoutConfig();

    if (isSmallScreen) {
      config.chartHeight = 100;
      config.statsHeight = 45;
      config.fontSize.title = UnifiedChartStyle.getResponsiveFontSize(UnifiedChartStyle.FONT_SIZES.title, 0.875);
      config.fontSize.axis = UnifiedChartStyle.getResponsiveFontSize(UnifiedChartStyle.FONT_SIZES.axis, 0.846);
      config.fontSize.stats = UnifiedChartStyle.getResponsiveFontSize(UnifiedChartStyle.FONT_SIZES.stats || 14, 0.857);
      config.fontSize.small = UnifiedChartStyle.getResponsiveFontSize(UnifiedChartStyle.FONT_SIZES.value, 0.9);
    } else if (isFullScreen) {
      config.chartHeight = 180;
      config.statsHeight = 70;
      config.fontSize.title = UnifiedChartStyle.getResponsiveFontSize(UnifiedChartStyle.FONT_SIZES.title, 1.125);
      config.fontSize.axis = UnifiedChartStyle.getResponsiveFontSize(UnifiedChartStyle.FONT_SIZES.axis, 1.077);
      config.fontSize.stats = UnifiedChartStyle.getResponsiveFontSize(UnifiedChartStyle.FONT_SIZES.stats || 14, 1.071);
      config.fontSize.small = UnifiedChartStyle.getResponsiveFontSize(UnifiedChartStyle.FONT_SIZES.value, 1.1);
    } else {
      config.chartHeight = 150;
      config.statsHeight = 60;
      config.fontSize.title = UnifiedChartStyle.FONT_SIZES.title;
      config.fontSize.axis = UnifiedChartStyle.FONT_SIZES.axis;
      config.fontSize.stats = UnifiedChartStyle.FONT_SIZES.stats || 14;
      config.fontSize.small = UnifiedChartStyle.FONT_SIZES.value;
    }

    return config;
  }

  // 初始化图表配置
  private initializeChart(): void {
    console.debug('[统计图表] 初始化BarChart配置');

    // 配置图表基本属性
    this.barChartModel.setDrawGridBackground(false);
    this.barChartModel.setDrawBorders(false);
    this.barChartModel.setDrawBarShadow(false);
    this.barChartModel.setHighlightFullBarEnabled(false);
    
    // 优化图表交互设置，关闭不必要的触摸功能
    this.barChartModel.setTouchEnabled(true); // 保持基本触摸功能以显示导航按钮
    this.barChartModel.setDragEnabled(false); // 禁用拖动
    this.barChartModel.setScaleEnabled(false); // 禁用缩放
    this.barChartModel.setScaleXEnabled(false); // 禁用X轴缩放
    this.barChartModel.setScaleYEnabled(false); // 禁用Y轴缩放
    this.barChartModel.setPinchZoom(false); // 禁用捏合缩放
    this.barChartModel.setHighlightPerTapEnabled(false); // 禁用点击高亮
    this.barChartModel.setHighlightPerDragEnabled(false); // 禁用拖动高亮

    // 配置X轴 - 将标签移至上方并添加刻度线
    const xAxis = this.barChartModel.getXAxis();
    if (xAxis) {
      xAxis.setPosition(XAxisPosition.TOP); // 将标签移至上方
      xAxis.setDrawGridLines(true); // 启用水平网格线作为刻度线
      xAxis.setDrawAxisLine(true); // 绘制轴线
      xAxis.setGranularity(1);
      xAxis.setLabelCount(11, true);
      xAxis.setTextSize(this.layoutConfig.fontSize.axis);
      xAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      xAxis.setAxisLineWidth(UnifiedChartStyle.LINE_WIDTHS.grid); // 显示轴线
      xAxis.setAxisLineColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      xAxis.setYOffset(10); // 正偏移，使标签显示在图表上方
      xAxis.setAvoidFirstLastClipping(true); // 避免首尾标签被裁剪
    }

    // 配置Y轴 - 将标签移至内部
    const leftAxis = this.barChartModel.getAxisLeft();
    if (leftAxis) {
      leftAxis.setDrawGridLines(true);
      leftAxis.setGridColor(parseInt(UnifiedChartStyle.GRID_COLOR.replace('#', '0xFF')));
      leftAxis.setGridLineWidth(UnifiedChartStyle.LINE_WIDTHS.grid);
      leftAxis.setGranularity(1);
      leftAxis.setTextSize(this.layoutConfig.fontSize.axis);
      leftAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      leftAxis.setAxisMinimum(0);
      leftAxis.setDrawAxisLine(false); // 隐藏Y轴线
      leftAxis.setAxisLineWidth(0); // 设置轴线宽度为0
      leftAxis.setAxisLineColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      leftAxis.setPosition(YAxisLabelPosition.INSIDE_CHART); // 将Y轴标签移至内部
      leftAxis.setSpaceTop(10); // 为内部标签添加顶部间距
      leftAxis.setSpaceBottom(10); // 为内部标签添加底部间距
    }

    const rightAxis = this.barChartModel.getAxisRight();
    if (rightAxis) {
      rightAxis.setEnabled(false);
    }

    // 配置图例
    const legend = this.barChartModel.getLegend();
    if (legend) {
      legend.setEnabled(false);
    }

    // 配置描述
    const description = this.barChartModel.getDescription();
    if (description) {
      description.setEnabled(false);
    }

    // 初始数据更新
    this.updateChartData();
  }

  // 更新图表数据
  private updateChartData(): void {
    const distribution = this.ak.uiDisplayState.displayStatisticsDistribution;

    if (distribution.length === 0) {
      console.debug('[统计图表] 无分布数据，跳过更新');
      return;
    }

    console.debug(`[统计图表] 更新数据: ${distribution.length}个区间`);

    // 创建BarEntry列表
    const entries: JArrayList<BarEntry> = new JArrayList<BarEntry>();
    for (let i = 0; i < distribution.length; i++) {
      entries.add(new BarEntry(i, distribution[i]));
    }

    // 创建数据集
    const dataSet = new BarDataSet(entries, '分贝分布');

    // 使用统一样式的颜色
    const colors = UnifiedChartStyle.getStatisticsBarColors(distribution.length);
    for (let i = 0; i < colors.length; i++) {
      dataSet.addColor(colors[i]);
    }

    dataSet.setDrawValues(true);
    dataSet.setValueTextSize(this.layoutConfig.fontSize.small);
    dataSet.setValueTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));

    // 配置柱子样式
    dataSet.setBarBorderColor(parseInt(UnifiedChartStyle.GRID_COLOR.replace('#', '0xFF')));
    dataSet.setBarBorderWidth(UnifiedChartStyle.LINE_WIDTHS.thin);
    dataSet.setBarShadowColor(0x00000000); // 透明阴影

    // 设置数据
    this.barData.clearValues();
    this.barData.addDataSet(dataSet);
    this.barData.setBarWidth(0.8); // 柱子宽度

    // 更新X轴标签
    this.updateXAxisLabels();

    // 设置数据到图表
    this.barChartModel.setData(this.barData);
    this.barChartModel.invalidate(); // 刷新图表
  }

  // 更新X轴标签
  private updateXAxisLabels(): void {
    const xAxis = this.barChartModel.getXAxis();
    if (xAxis) {
      const labels: string[] = [];

      for (let i = 0; i < 11; i++) {
        const label = i === 10 ? '100+' : `${i * 10}`;
        labels.push(label);
      }

      xAxis.setValueFormatter(new XAxisValueFormatter(labels));
    }
  }

  // 计算标准差
  private calculateStandardDeviation(): number {
    const distribution = this.ak.uiDisplayState.displayStatisticsDistribution;
    if (distribution.length === 0 || distribution.reduce((a, b) => a + b, 0) === 0) {
      return 0;
    }

    // 计算加权平均值
    let weightedSum = 0;
    let totalCount = 0;
    for (let i = 0; i < distribution.length; i++) {
      const midValue = i * 10 + 5; // 使用区间中值
      weightedSum += midValue * distribution[i];
      totalCount += distribution[i];
    }

    const mean = weightedSum / totalCount;

    // 计算方差
    let variance = 0;
    for (let i = 0; i < distribution.length; i++) {
      const midValue = i * 10 + 5;
      variance += Math.pow(midValue - mean, 2) * distribution[i];
    }
    variance /= totalCount;

    return Math.sqrt(variance);
  }

  build() {
    Column() {
      // BarChart组件（去掉标题，因为标签页已显示图表名称）
      Stack() {
        BarChart({
          model: this.barChartModel
        })
          .width('100%')
          .height('100%')
          .borderRadius(UnifiedChartStyle.BORDER_RADIUS.large) // 添加圆角，与其他图表保持一致
        
        // X轴单位标签
        Text('声级(dB)')
          .fontSize(this.layoutConfig.fontSize.axis)
          .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
          .position({ x: '95%', y: '2%' })
          .translate({ x: '-50%' })
          .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
          .padding({ left: 4, right: 4 })
          .borderRadius(4)
        
        // Y轴单位标签
        Text('次数')
          .fontSize(this.layoutConfig.fontSize.axis)
          .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
          .position({ x: '1%', y: '5%' })
          .translate({ y: '-50%' })
          .rotate({ angle: -90 })
          .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
          .padding({ left: 4, right: 4 })
          .borderRadius(4)
      }
      .width('100%')
      .layoutWeight(1) // 使用layoutWeight确保与其他图表尺寸一致
      .margin({ bottom: UnifiedChartStyle.SPACING.md })

      // 统计指标显示
      this.buildStatisticsInfo(
        this.ak.uiDisplayState.displayStatistics,
        this.calculateStandardDeviation(),
        this.ak.windowWidthBreakpoint <= 1,
        this.ak.windowWidthBreakpoint >= 3
      )
    }
    .width('100%')
    .padding(UnifiedChartStyle.SPACING.md)
    .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
    .borderRadius(UnifiedChartStyle.BORDER_RADIUS.large)
  }

  // 构建统计信息显示
  @Builder
  private buildStatisticsInfo(stats: UiStatisticsData, stdDev: number, isSmallScreen: boolean, isFullScreen: boolean) {
    Column() {
      // 统计信息标题
      Text('统计指标')
        .fontSize(this.layoutConfig.fontSize.stats)
        .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ bottom: UnifiedChartStyle.SPACING.sm })

      if (isSmallScreen) {
        // 小屏幕：紧凑两行显示
        Row() {
          Text(`平均值: ${UnifiedChartStyle.formatDecibel(stats.avgDb)}`)
            .fontSize(this.layoutConfig.fontSize.stats)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .layoutWeight(1)
            .textAlign(TextAlign.Start)

          Text(`最大值: ${UnifiedChartStyle.formatDecibel(stats.maxDb)}`)
            .fontSize(this.layoutConfig.fontSize.stats)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .margin({ bottom: UnifiedChartStyle.SPACING.xs })

        Row() {
          Text(`最小值: ${UnifiedChartStyle.formatDecibel(stats.minDb)}`)
            .fontSize(this.layoutConfig.fontSize.stats)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .layoutWeight(1)
            .textAlign(TextAlign.Start)

          Text(`标准差: ${UnifiedChartStyle.formatDecibel(stdDev)}`)
            .fontSize(this.layoutConfig.fontSize.stats)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
      } else if (isFullScreen) {
        // 全屏模式：两行显示
        Text(`平均值: ${UnifiedChartStyle.formatDecibel(stats.avgDb)} | 最大值: ${UnifiedChartStyle.formatDecibel(stats.maxDb)}`)
          .fontSize(this.layoutConfig.fontSize.stats)
          .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: UnifiedChartStyle.SPACING.xs })

        Text(`最小值: ${UnifiedChartStyle.formatDecibel(stats.minDb)} | 标准差: ${UnifiedChartStyle.formatDecibel(stdDev)}`)
          .fontSize(this.layoutConfig.fontSize.stats)
          .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
          .textAlign(TextAlign.Center)
          .width('100%')
      } else {
        // 中等屏幕：单行显示
        Text(`平均值: ${UnifiedChartStyle.formatDecibel(stats.avgDb)} | 最大值: ${UnifiedChartStyle.formatDecibel(stats.maxDb)} | 最小值: ${UnifiedChartStyle.formatDecibel(stats.minDb)} | 标准差: ${UnifiedChartStyle.formatDecibel(stdDev)}`)
          .fontSize(this.layoutConfig.fontSize.stats)
          .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
          .textAlign(TextAlign.Center)
          .width('100%')
      }
    }
    .width('100%')
    .height(this.layoutConfig.statsHeight)
  }
}