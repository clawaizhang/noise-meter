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

  @Monitor('ak.uiDisplayState.displayDb')
  onTimeDomainDataChange(monitor: IMonitor) {
    const newTimeDomainData = monitor.value<number[]>()?.now;
    if (newTimeDomainData && this.ak.isDisplayApp) {
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
    
    // 时域数据可能很长，需要采样显示
    const maxPoints = 500; // 限制最大数据点数
    const dataLength = this.currentTimeDomainData.length;
    
    if (dataLength <= maxPoints) {
      // 如果数据点不多，全部显示
      for (let i = 0; i < dataLength; i++) {
        values.add(new EntryOhos(i, this.currentTimeDomainData[i]));
      }
    } else {
      // 如果数据点太多，进行均匀采样
      const step = Math.floor(dataLength / maxPoints);
      for (let i = 0; i < dataLength; i += step) {
        values.add(new EntryOhos(i, this.currentTimeDomainData[i]));
      }
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
    
    // 获取图表图例部件，设置图表图例形状为线形
    let legend: Legend | null = this.model.getLegend();
    if (legend) {
      legend.setEnabled(true);
      legend.setForm(LegendForm.LINE);
      legend.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      legend.setTextSize(UnifiedChartStyle.FONT_SIZES.legend);
    }
    
    // 设置图表数据最大的绘制数
    this.model.setMaxVisibleValueCount(500);
    
    // 创建时域限制线（0线为中心线）
    this.createLimitLines();
    
    // 设置左Y轴信息
    this.leftAxis = this.model.getAxisLeft();
    if (this.leftAxis) {
      // 设置绘制标签个数
      this.leftAxis.setLabelCount(7, true);
      // 设置标签位置
      this.leftAxis.setPosition(YAxisLabelPosition.OUTSIDE_CHART);
      // 设置距离顶部距离
      this.leftAxis.setSpaceTop(15);
      // 设置最小值和最大值
      this.leftAxis.setAxisMinimum(-1.0);
      this.leftAxis.setAxisMaximum(1.0);
      // 设置网格线样式
      this.leftAxis.setDrawGridLines(true);
      this.leftAxis.setGridColor(parseInt(UnifiedChartStyle.GRID_COLOR.replace('#', '0xFF')));
      this.leftAxis.setGridLineWidth(UnifiedChartStyle.LINE_WIDTHS.grid);
      this.leftAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      this.leftAxis.setTextSize(UnifiedChartStyle.FONT_SIZES.axis);
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
    
    // 设置X轴信息
    this.xAxis = this.model.getXAxis();
    if (this.xAxis) {
      this.xAxis.setPosition(XAxisPosition.BOTTOM);
      this.xAxis.setDrawGridLines(false);
      this.xAxis.setGranularity(1);
      this.xAxis.setLabelCount(5);
      this.xAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      this.xAxis.setTextSize(UnifiedChartStyle.FONT_SIZES.axis);
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
      // 图表标题
      Row() {
        Text('时域波形')
          .fontSize(UnifiedChartStyle.FONT_SIZES.title)
          .fontWeight(FontWeight.Medium)
          .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
        
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
      .padding({ left: UnifiedChartStyle.SPACING.md, right: UnifiedChartStyle.SPACING.md, top: UnifiedChartStyle.SPACING.sm, bottom: UnifiedChartStyle.SPACING.sm })
      
      // LineChart组件
      if (this.model) {
        LineChart({ model: this.model })
          .width('100%')
          .layoutWeight(1)
          .borderRadius(UnifiedChartStyle.BORDER_RADIUS.large) // 添加圆角，与其他图表保持一致
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
    .borderRadius(UnifiedChartStyle.BORDER_RADIUS.large)
  }
}