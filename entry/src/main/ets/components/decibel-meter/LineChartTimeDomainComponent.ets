import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AudioPresets } from '../../common/AudioConfig';
import { UnifiedChartStyle } from '../common/charts/UnifiedChartStyle';
import {
  JArrayList,
  XAxis,
  XAxisPosition,
  YAxis,
  Description,
  Legend,
  OnChartValueSelectedListener,
  Highlight,
  EntryOhos,
  YAxisLabelPosition,
  LineDataSet,
  ILineDataSet,
  LineData,
  Mode,
  LineChart,
  LineChartModel,
  LimitLine,
  LimitLabelPosition,
  ChartColorStop,
  LegendForm,
  IAxisValueFormatter,
} from '@ohos/mpchart';

@ComponentV2
export struct LineChartTimeDomainComponent {
  // 输入参数
  @Param sampleRate: number = 44100
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  // 依赖注入
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys)!

  // 时域数据
  @Local private currentTimeDomainData: number[] = [];
  
  // 滑动窗口相关
  @Local private maxWindowDataPoints: number = 500; // 滑动窗口最大数据点数

  // LineChart 相关
  @Local private model: LineChartModel | null = null;
  @Local private dataSet: LineDataSet | null = null;
  @Local private leftAxis: YAxis | null = null;
  @Local private rightAxis: YAxis | null = null;
  @Local private xAxis: XAxis | null = null;
  @Local private limitLine1: LimitLine | null = null;
  @Local private limitLine2: LimitLine | null = null;

  @Computed
  get fftSize() {
    return AudioPresets.getConfig(this.pk.audio_analysis_mode).fftSize;
  }

  // 构造数据选择监听器
  private valueSelectedListener: OnChartValueSelectedListener = {
    onValueSelected: (e: EntryOhos, h: Highlight) => {
      // 处理数据点选择事件
      console.info(`[时域图] 选中数据点: x=${e.getX()}, y=${e.getY()}`);
    },
    onNothingSelected: () => {
      // 处理取消选择事件
      console.info(`[时域图] 取消选择`);
    }
  }

  @Monitor('ak.uiDisplayState.displayTimeDomainData')
  onTimeDomainDataChange(monitor: IMonitor) {
    if (this.ak.isDisplayApp) {
      // 直接使用最新的时域数据，因为AudioController已经限制了数据量（512个点）
      this.currentTimeDomainData = this.ak.uiDisplayState.displayTimeDomainData;
      
      // 更新图表数据
      this.updateChartData();
    }
  }

  /**
   * 更新图表数据
   */
  private updateChartData(): void {
    if (!this.model || this.currentTimeDomainData.length === 0) {
      return;
    }

    const lineData: LineData = this.generateLineData();
    this.model.setData(lineData);
    
    // 触发数据更新
    lineData.notifyDataChanged();
    this.model.notifyDataSetChanged();
    this.model.invalidate();
  }

  /**
   * 生成时域图数据
   */
  private generateLineData(): LineData {
    const values: JArrayList<EntryOhos> = new JArrayList<EntryOhos>();
    
    // 由于已经通过滑动窗口限制了数据量，这里可以直接使用所有数据
    // 不再需要额外的采样逻辑
    const dataLength = this.currentTimeDomainData.length;
    
    // 直接使用所有数据点，因为滑动窗口已经限制了数据量
    for (let i = 0; i < dataLength; i++) {
      values.add(new EntryOhos(i, this.currentTimeDomainData[i]));
    }

    // 创建数据集
    this.dataSet = new LineDataSet(values, '时域波形');
    this.dataSet.setHighLightColor(parseInt(UnifiedChartStyle.HIGHLIGHT_COLOR.replace('#', '0xFF')));
    this.dataSet.setDrawIcons(false);
    this.dataSet.setMode(Mode.LINEAR); // 直线模式
    this.dataSet.setDrawCircles(false); // 不绘制圆点，因为数据点太多
    this.dataSet.setDrawCircleHole(false);
    this.dataSet.setColorByColor(parseInt(UnifiedChartStyle.PRIMARY_COLOR.replace('#', '0xFF'))); // 设置折线颜色
    this.dataSet.setLineWidth(UnifiedChartStyle.LINE_WIDTHS.normal); // 使用统一样式线宽

    // 使用统一样式的渐变色填充
    const gradientFillColor = UnifiedChartStyle.getGradientFillColor(UnifiedChartStyle.PRIMARY_COLOR);
    const gradientArrayList = new JArrayList<ChartColorStop>();
    for (const stop of gradientFillColor) {
      gradientArrayList.add(stop);
    }
    this.dataSet.setGradientFillColor(gradientArrayList);
    this.dataSet.setDrawFilled(true);

    const dataSetList: JArrayList<ILineDataSet> = new JArrayList<ILineDataSet>();
    dataSetList.add(this.dataSet);

    return new LineData(dataSetList);
  }

  /**
   * 初始化图表配置
   */
  private initChart(): void {
    if (!this.model) {
      return;
    }

    // 为图表添加数据选择的监听器
    this.model.setOnChartValueSelectedListener(this.valueSelectedListener);
    
    // 获取图表描述部件，设置图表描述部件不可用
    let description: Description | null = this.model.getDescription();
    if (description) {
      description.setEnabled(false);
    }
    
    // 获取图表图例部件，禁用图例因为只有一根线
    let legend: Legend | null = this.model.getLegend();
    if (legend) {
      legend.setEnabled(false); // 禁用图例，因为只有一根线，显示"时域波形"标签是多余的
    }
    
    // 设置图表数据最大的绘制数
    this.model.setMaxVisibleValueCount(500);
    
    // 优化图表交互设置，关闭不必要的触摸功能
    this.model.setTouchEnabled(true); // 保持基本触摸功能以显示导航按钮
    this.model.setDragEnabled(false); // 禁用拖动
    this.model.setScaleEnabled(false); // 禁用缩放
    this.model.setScaleXEnabled(false); // 禁用X轴缩放
    this.model.setScaleYEnabled(false); // 禁用Y轴缩放
    this.model.setPinchZoom(false); // 禁用捏合缩放
    this.model.setHighlightPerTapEnabled(false); // 禁用点击高亮
    this.model.setHighlightPerDragEnabled(false); // 禁用拖动高亮

    // 创建时域限制线（0线为中心线）
    this.createLimitLines();
    
    // 设置左Y轴信息 - 将标签移至内部
    this.leftAxis = this.model.getAxisLeft();
    if (this.leftAxis) {
      // 设置绘制标签个数
      this.leftAxis.setLabelCount(7, true);
      // 设置标签位置为内部
      this.leftAxis.setPosition(YAxisLabelPosition.INSIDE_CHART);
      // 设置距离顶部距离
      this.leftAxis.setSpaceTop(15);
      this.leftAxis.setSpaceBottom(15); // 为内部标签添加底部间距
      // 设置最小值和最大值
      this.leftAxis.setAxisMinimum(-1.0);
      this.leftAxis.setAxisMaximum(1.0);
      // 设置网格线样式
      this.leftAxis.setDrawGridLines(true);
      this.leftAxis.setGridColor(parseInt(UnifiedChartStyle.GRID_COLOR.replace('#', '0xFF')));
      this.leftAxis.setGridLineWidth(UnifiedChartStyle.LINE_WIDTHS.grid);
      this.leftAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      this.leftAxis.setTextSize(UnifiedChartStyle.FONT_SIZES.axis);
      
      // 优化Y轴显示 - 隐藏轴线但保留标签
      this.leftAxis.setDrawAxisLine(false); // 隐藏Y轴线
      this.leftAxis.setAxisLineWidth(0); // 设置轴线宽度为0
    }

    // 设置图表右Y轴信息
    this.rightAxis = this.model.getAxisRight();
    if (this.rightAxis) {
      this.rightAxis.setLabelCount(7, true);
      this.rightAxis.setDrawGridLines(false);
      this.rightAxis.setSpaceTop(15);
      this.rightAxis.setAxisMinimum(-1.0);
      this.rightAxis.setAxisMaximum(1.0);
      this.rightAxis.setEnabled(false);
    }
    
    // 设置X轴信息 - 将标签移至上方并添加刻度线
    this.xAxis = this.model.getXAxis();
    if (this.xAxis) {
      this.xAxis.setPosition(XAxisPosition.TOP); // 将标签移至上方
      this.xAxis.setDrawGridLines(true); // 启用水平网格线作为刻度线
      this.xAxis.setDrawAxisLine(true); // 绘制轴线
      this.xAxis.setGranularity(1);
      this.xAxis.setLabelCount(5);
      this.xAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      this.xAxis.setTextSize(UnifiedChartStyle.FONT_SIZES.axis);
      this.xAxis.setYOffset(10); // 正偏移，使标签显示在图表上方
      this.xAxis.setAvoidFirstLastClipping(true); // 避免首尾标签被裁剪
      
      // 设置X轴单位标签
      this.xAxis.setAxisLineWidth(UnifiedChartStyle.LINE_WIDTHS.grid); // 显示轴线
      this.xAxis.setAxisLineColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      
      // 自定义X轴标签，显示时间单位（毫秒）
      const sampleRate = this.sampleRate; // 保存sampleRate值
      class TimeAxisFormatter implements IAxisValueFormatter {
        getFormattedValue(value: number): string {
          // 将采样点索引转换为时间（毫秒）
          const timeMs = (value / sampleRate) * 1000;
          return timeMs.toFixed(1);
        }
      }
      this.xAxis.setValueFormatter(new TimeAxisFormatter());
    }
    
    // 设置图表最大的X轴显示范围
    this.model.setVisibleXRangeMaximum(this.fftSize);
    
    // 初始化数据
    const lineData: LineData = this.generateLineData();
    this.model.setData(lineData);
  }
  
  /**
   * 创建时域限制线（0线为中心线）
   */
  private createLimitLines(): void {
    if (!this.leftAxis) return;
    
    // 清除之前的限制线
    this.leftAxis.removeAllLimitLines();
    
    // 添加0中心线
    const centerLine = new LimitLine(0, '0');
    centerLine.setLineWidth(UnifiedChartStyle.LINE_WIDTHS.thin);
    centerLine.enableDashedLine(5, 5, 0);
    centerLine.setLabelPosition(LimitLabelPosition.RIGHT_TOP);
    centerLine.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
    centerLine.setLineColor(parseInt(UnifiedChartStyle.GRID_COLOR.replace('#', '0xFF')));
    centerLine.setTextSize(UnifiedChartStyle.FONT_SIZES.value);
    
    this.leftAxis.addLimitLine(centerLine);
  }

  aboutToAppear() {
    // Step1: 初始化图表配置构建类
    this.model = new LineChartModel();
    
    // Step2: 配置图表指定样式
    this.initChart();
  }

  build() {
    Column() {
      // 采样点信息行（去掉标题，只保留采样点数量）
      Row() {
        Blank()
        
        // 显示数据点数量
        Text(`采样点: ${this.currentTimeDomainData.length}`)
          .fontSize(UnifiedChartStyle.FONT_SIZES.value)
          .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
          .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
          .padding({ left: UnifiedChartStyle.SPACING.sm, right: UnifiedChartStyle.SPACING.sm, top: 4, bottom: 4 })
          .borderRadius(UnifiedChartStyle.BORDER_RADIUS.small)
      }
      .width('100%')
      .padding({ left: UnifiedChartStyle.SPACING.md, right: UnifiedChartStyle.SPACING.md, top: UnifiedChartStyle.SPACING.xs, bottom: UnifiedChartStyle.SPACING.xs })
      
      // LineChart组件
      if (this.model) {
        Stack() {
          LineChart({ model: this.model })
            .width('100%')
            .height('100%')
            .borderRadius(UnifiedChartStyle.BORDER_RADIUS.large) // 添加圆角，与其他图表保持一致
          
          // X轴单位标签
          Text('时间(ms)')
            .fontSize(UnifiedChartStyle.FONT_SIZES.axis)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .position({ x: '95%', y: '2%' })
            .translate({ x: '-50%' })
            .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
            .padding({ left: 4, right: 4 })
            .borderRadius(4)
          
          // Y轴单位标签
          Text('幅值')
            .fontSize(UnifiedChartStyle.FONT_SIZES.axis)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .position({ x: '1%', y: '5%' })
            .translate({ y: '-50%' })
            .rotate({ angle: -90 })
            .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
            .padding({ left: 4, right: 4 })
            .borderRadius(4)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
    .borderRadius(UnifiedChartStyle.BORDER_RADIUS.large)
  }
}