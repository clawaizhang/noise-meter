import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import {
  SpectrumDisplayService,
  SpectrumDisplayMode,
  SpectrumDisplayConfig,
  SpectrumDisplayData
} from '../../services/SpectrumDisplayService';
import { UnifiedChartStyle } from '../common/charts/UnifiedChartStyle';
import { PeakFrequencyDisplay } from './PeakFrequencyDisplay';
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
  WaterfallChart,
  WaterfallChartModel,
  BarData,
  WaterfallDataSet,
  WaterfallEntry,
  IBarDataSet,
  IAxisValueFormatter,
  AxisBase
} from '@ohos/mpchart';

/**
 * 自定义X轴值格式化器
 * 用于显示标准对数频率点标签
 */
class StandardFrequencyAxisValueFormatter implements IAxisValueFormatter {
  private static readonly STANDARD_FREQUENCIES = [16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
  private static readonly LOG_MIN_FREQ = Math.log10(16);
  private static readonly LOG_MAX_FREQ = Math.log10(20000);
  // 预计算标准频率点对应的X轴位置
  private static readonly FREQUENCY_TO_X_MAP: Map<number, number> = (() => {
    const map = new Map<number, number>();
    for (const freq of StandardFrequencyAxisValueFormatter.STANDARD_FREQUENCIES) {
      const logFreq = Math.log10(freq);
      const xValue = ((logFreq - StandardFrequencyAxisValueFormatter.LOG_MIN_FREQ) /
        (StandardFrequencyAxisValueFormatter.LOG_MAX_FREQ - StandardFrequencyAxisValueFormatter.LOG_MIN_FREQ)) * 20000;
      map.set(freq, xValue);
    }
    return map;
  })();

  getFormattedValue(value: number, axis: AxisBase): string {
    // 查找当前X值最接近的标准频率点
    let closestFreq = StandardFrequencyAxisValueFormatter.STANDARD_FREQUENCIES[0];
    let minDistance = Math.abs(value - StandardFrequencyAxisValueFormatter.FREQUENCY_TO_X_MAP.get(closestFreq)!);

    for (const freq of StandardFrequencyAxisValueFormatter.STANDARD_FREQUENCIES) {
      const freqXValue = StandardFrequencyAxisValueFormatter.FREQUENCY_TO_X_MAP.get(freq)!;
      const distance = Math.abs(value - freqXValue);
      if (distance < minDistance) {
        minDistance = distance;
        closestFreq = freq;
      }
    }

    // 根据频率范围使用不同的容差
    let threshold: number;
    if (closestFreq <= 63) {
      threshold = 200; // 低频区域使用更大容差
    } else if (closestFreq <= 1000) {
      threshold = 450; // 中频区域使用中等容差
    } else {
      threshold = 700; // 高频区域使用较大容差
    }

    // 隐藏第一个和最后一个标签
    if (closestFreq === 16 || closestFreq === 16000) {
      return '';
    }

    if (minDistance <= threshold) {
      // 使用统一样式格式化频率显示
      let formattedValue: string;
      if (closestFreq >= 1000) {
        formattedValue = `${(closestFreq / 1000).toFixed(0)}k`;
      } else {
        formattedValue = `${Math.round(closestFreq)}`;
      }

      return formattedValue;
    } else {
      return '';
    }
  }
}

/**
 * 自定义Y轴值格式化器
 * 用于隐藏第一个和最后一个Y轴标签
 */
class YAxisValueFormatter implements IAxisValueFormatter {
  getFormattedValue(value: number, axis: AxisBase): string {
    // 隐藏第一个和最后一个标签
    const displayData = this.getDisplayData();
    if (!displayData || displayData.decibelSteps.length === 0) {
      return '';
    }

    const minDb = displayData.decibelSteps[0];
    const maxDb = displayData.decibelSteps[displayData.decibelSteps.length - 1];

    if (value === minDb || value === maxDb) {
      return '';
    }

    // 返回正常的分贝值标签
    return `${value}`;
  }

  // 获取显示数据（需要从外部设置）
  private displayData: SpectrumDisplayData | null = null;

  setDisplayData(data: SpectrumDisplayData): void {
    this.displayData = data;
  }

  private getDisplayData(): SpectrumDisplayData | null {
    return this.displayData;
  }
}

@ComponentV2
export struct ProfessionalSpectrumAnalyzer {
  // 输入参数
  @Param sampleRate: number = 44100
  // 依赖注入
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys) ?? new AppKeys()
  @Local private pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys) ?? new PreferenceKeys();
  // 服务实例
  @Local private spectrumDisplayService: SpectrumDisplayService = SpectrumDisplayService.getInstance();
  // 频谱数据
  @Local private currentSpectrumData: Float32Array = new Float32Array();
  @Local private previousSpectrumData: Float32Array = new Float32Array();
  @Local private displayData: SpectrumDisplayData | null = null;
  @Local private displayConfig: SpectrumDisplayConfig | null = null;
  // LineChart 相关
  @Local private lineChartModel: LineChartModel | null = null;
  @Local private lineDataSet: LineDataSet | null = null;
  @Local private lineChartLeftAxis: YAxis | null = null;
  @Local private lineChartRightAxis: YAxis | null = null;
  @Local private lineChartXAxis: XAxis | null = null;
  // BarChart 相关
  @Local private barChartModel: WaterfallChartModel | null = null;
  @Local private barDataSet: WaterfallDataSet | null = null;
  @Local private barChartLeftAxis: YAxis | null = null;
  @Local private barChartRightAxis: YAxis | null = null;
  @Local private barChartXAxis: XAxis | null = null;
  // Y轴格式化器实例
  @Local private yAxisFormatter: YAxisValueFormatter = new YAxisValueFormatter();

  @Computed
  get fftSize() {
    // 这里应该从AudioConfig获取，为了简化直接使用固定值
    return 2048;
  }

  @Computed
  get isLineChartMode(): boolean {
    return this.displayConfig?.displayMode === SpectrumDisplayMode.LINE ||
      this.displayConfig?.displayMode === SpectrumDisplayMode.HYBRID;
  }

  @Computed
  get isBarChartMode(): boolean {
    return this.displayConfig?.displayMode === SpectrumDisplayMode.BAR ||
      this.displayConfig?.displayMode === SpectrumDisplayMode.HYBRID;
  }

  @Computed
  get isHybridMode(): boolean {
    return this.displayConfig?.displayMode === SpectrumDisplayMode.HYBRID;
  }

  // 构造数据选择监听器
  private valueSelectedListener: OnChartValueSelectedListener = {
    onValueSelected: (e: EntryOhos, h: Highlight) => {
      console.info(`[专业频谱分析器] 选中数据点: x=${e.getX()}, y=${e.getY()}`);
    },
    onNothingSelected: () => {
      console.info(`[专业频谱分析器] 取消选择`);
    }
  }

  @Monitor('ak.uiDisplayState.displaySpectrumData')
  onSpectrumDataChange(monitor: IMonitor) {
    const newSpectrum = monitor.value<Float32Array>()?.now;
    if (newSpectrum && this.ak.isDisplayApp) {
      this.currentSpectrumData = newSpectrum;
      this.updateDisplayData();
    }
  }

  @Monitor('pk.spectrum_display_mode','pk.spectrum_smoothing_factor','pk.spectrum_show_peak_frequency','pk.spectrum_frequency_range','pk.spectrum_db_range')
  onDisplayConfigChange() {
    this.displayConfig = this.spectrumDisplayService.getDisplayConfig(this.pk);
    this.updateDisplayData();
  }

  aboutToAppear() {
    // 初始化显示配置
    this.displayConfig = this.spectrumDisplayService.getDisplayConfig(this.pk);

    // 初始化图表
    this.initializeLineChart();
    this.initializeBarChart();
  }

  /**
   * 更新显示数据
   */
  private updateDisplayData(): void {
    if (!this.displayConfig || this.currentSpectrumData.length === 0) {
      return;
    }

    // 处理频谱数据
    this.displayData = this.spectrumDisplayService.processSpectrumData(
      this.currentSpectrumData,
      this.fftSize,
      this.sampleRate,
      this.displayConfig
    );

    // 更新Y轴格式化器的数据
    this.yAxisFormatter.setDisplayData(this.displayData);

    // 更新图表数据
    this.updateChartData();
  }

  /**
   * 更新图表数据
   */
  private updateChartData(): void {
    if (!this.displayData) {
      return;
    }

    // 更新线形图
    if (this.lineChartModel && (this.isLineChartMode || this.isHybridMode)) {
      const lineData = this.generateLineData();
      this.lineChartModel.setData(lineData);
      lineData.notifyDataChanged();
      this.lineChartModel.notifyDataSetChanged();
      this.lineChartModel.invalidate();
    }

    // 更新柱状图
    if (this.barChartModel && (this.isBarChartMode || this.isHybridMode)) {
      const barData = this.generateBarData();
      this.barChartModel.setData(barData);
      barData.notifyDataChanged();
      this.barChartModel.notifyDataSetChanged();
      this.barChartModel.invalidate();
    }
  }

  /**
   * 初始化线形图
   */
  private initializeLineChart(): void {
    if (!this.lineChartModel) {
      this.lineChartModel = new LineChartModel();
    }

    // 设置监听器
    this.lineChartModel.setOnChartValueSelectedListener(this.valueSelectedListener);

    // 设置描述
    let description: Description | null = this.lineChartModel.getDescription();
    if (description) {
      description.setEnabled(false);
    }

    // 设置图例
    let legend: Legend | null = this.lineChartModel.getLegend();
    if (legend) {
      legend.setEnabled(false);
    }

    // 设置最大可见值数量
    this.lineChartModel.setMaxVisibleValueCount(100);

    // 设置交互
    this.lineChartModel.setTouchEnabled(true);
    this.lineChartModel.setDragEnabled(false);
    this.lineChartModel.setScaleEnabled(false);
    this.lineChartModel.setScaleXEnabled(false);
    this.lineChartModel.setScaleYEnabled(false);
    this.lineChartModel.setPinchZoom(false);
    this.lineChartModel.setHighlightPerTapEnabled(false);
    this.lineChartModel.setHighlightPerDragEnabled(false);

    // 设置坐标轴
    this.setupLineChartAxes();

    // 创建限制线
    this.createLimitLines(this.lineChartLeftAxis);
  }

  /**
   * 初始化柱状图
   */
  private initializeBarChart(): void {
    if (!this.barChartModel) {
      this.barChartModel = new WaterfallChartModel();
    }

    // 设置监听器
    this.barChartModel.setOnChartValueSelectedListener(this.valueSelectedListener);

    // 设置描述
    let description: Description | null = this.barChartModel.getDescription();
    if (description) {
      description.setEnabled(false);
    }

    // 设置图例
    let legend: Legend | null = this.barChartModel.getLegend();
    if (legend) {
      legend.setEnabled(false);
    }

    // 设置最大可见值数量
    this.barChartModel.setMaxVisibleValueCount(100);

    // 设置交互
    this.barChartModel.setTouchEnabled(true);
    this.barChartModel.setDragEnabled(false);
    this.barChartModel.setScaleEnabled(false);
    this.barChartModel.setScaleXEnabled(false);
    this.barChartModel.setScaleYEnabled(false);
    this.barChartModel.setPinchZoom(false);
    this.barChartModel.setHighlightPerTapEnabled(false);
    this.barChartModel.setHighlightPerDragEnabled(false);

    // 设置背景
    this.barChartModel.setDrawGridBackground(true);
    this.barChartModel.setGridBackgroundColor(UnifiedChartStyle.BACKGROUND_COLOR);
    this.barChartModel.setDrawBarShadow(false);
    this.barChartModel.setDrawValueAboveBar(false);

    // 设置坐标轴
    this.setupBarChartAxes();

    // 创建限制线
    this.createLimitLines(this.barChartLeftAxis);
  }

  /**
   * 设置线形图坐标轴
   */
  private setupLineChartAxes(): void {
    if (!this.lineChartModel) {
      return;
    }

    // 左Y轴
    this.lineChartLeftAxis = this.lineChartModel.getAxisLeft();
    if (this.lineChartLeftAxis) {
      this.setupCommonYAxis(this.lineChartLeftAxis);
    }

    // 右Y轴
    this.lineChartRightAxis = this.lineChartModel.getAxisRight();
    if (this.lineChartRightAxis) {
      this.lineChartRightAxis.setEnabled(false);
    }

    // X轴
    this.lineChartXAxis = this.lineChartModel.getXAxis();
    if (this.lineChartXAxis) {
      this.setupCommonXAxis(this.lineChartXAxis);
    }
  }

  /**
   * 设置柱状图坐标轴
   */
  private setupBarChartAxes(): void {
    if (!this.barChartModel) {
      return;
    }

    // 左Y轴
    this.barChartLeftAxis = this.barChartModel.getAxisLeft();
    if (this.barChartLeftAxis) {
      this.setupCommonYAxis(this.barChartLeftAxis);
    }

    // 右Y轴
    this.barChartRightAxis = this.barChartModel.getAxisRight();
    if (this.barChartRightAxis) {
      this.barChartRightAxis.setEnabled(false);
    }

    // X轴
    this.barChartXAxis = this.barChartModel.getXAxis();
    if (this.barChartXAxis) {
      this.setupCommonXAxis(this.barChartXAxis);
    }
  }

  /**
   * 设置通用Y轴
   */
  private setupCommonYAxis(yAxis: YAxis): void {
    if (!this.displayData) {
      return;
    }

    const dbSteps = this.displayData.decibelSteps;

    yAxis.setLabelCount(dbSteps.length, true);
    yAxis.setPosition(YAxisLabelPosition.INSIDE_CHART);
    yAxis.setSpaceTop(15);
    yAxis.setSpaceBottom(15);
    yAxis.setAxisMinimum(dbSteps[0]);
    yAxis.setAxisMaximum(dbSteps[dbSteps.length - 1]);
    yAxis.setYOffset(-10);
    yAxis.setDrawGridLines(true);
    yAxis.setGridColor(parseInt(UnifiedChartStyle.GRID_COLOR.replace('#', '0xFF')));
    yAxis.setGridLineWidth(UnifiedChartStyle.LINE_WIDTHS.grid);
    yAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
    yAxis.setTextSize(UnifiedChartStyle.FONT_SIZES.axis);
    yAxis.setDrawAxisLine(false);
    yAxis.setAxisLineWidth(0);
    yAxis.setGranularity(20);
    yAxis.setCenterAxisLabels(false);
    yAxis.setValueFormatter(this.yAxisFormatter);
  }

  /**
   * 设置通用X轴
   */
  private setupCommonXAxis(xAxis: XAxis): void {
    xAxis.setPosition(XAxisPosition.TOP);
    xAxis.setDrawGridLines(true);
    xAxis.setDrawAxisLine(true);
    xAxis.setGranularity(1);
    xAxis.setLabelCount(11, false);
    xAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
    xAxis.setTextSize(UnifiedChartStyle.FONT_SIZES.axis);
    xAxis.setYOffset(-15);
    xAxis.setXOffset(20);
    xAxis.setAvoidFirstLastClipping(true);
    xAxis.setAxisMinimum(0);
    xAxis.setAxisMaximum(20000);
    xAxis.setValueFormatter(new StandardFrequencyAxisValueFormatter());
    xAxis.setAxisLineWidth(UnifiedChartStyle.LINE_WIDTHS.grid);
    xAxis.setAxisLineColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
  }

  /**
   * 创建限制线
   */
  private createLimitLines(yAxis: YAxis | null): void {
    if (!yAxis) {
      return;
    }

    // 清除之前的限制线
    yAxis.removeAllLimitLines();

    // 添加统一样式的限制线
    for (const limitLineConfig of UnifiedChartStyle.LIMIT_LINES) {
      const limitLine = new LimitLine(limitLineConfig.value, limitLineConfig.label);
      limitLine.setLineWidth(UnifiedChartStyle.LINE_WIDTHS.normal);
      limitLine.enableDashedLine(5, 5, 0);
      limitLine.setLabelPosition(LimitLabelPosition.RIGHT_TOP);
      limitLine.setTextColor(parseInt(limitLineConfig.color.replace('#', '0xFF')));
      limitLine.setLineColor(parseInt(limitLineConfig.color.replace('#', '0xFF')));
      limitLine.setTextSize(UnifiedChartStyle.FONT_SIZES.value);

      yAxis.addLimitLine(limitLine);
    }
  }

  /**
   * 生成线形图数据
   */
  private generateLineData(): LineData {
    if (!this.displayData) {
      return new LineData(new JArrayList<ILineDataSet>());
    }

    const values: JArrayList<EntryOhos> = new JArrayList<EntryOhos>();

    // 使用对数坐标映射
    const LOG_MIN_FREQ = Math.log10(16);
    const LOG_MAX_FREQ = Math.log10(20000);

    for (const dataPoint of this.displayData.dataPoints) {
      const frequency: number = dataPoint.frequency;
      const dbValue: number = dataPoint.dbValue;

      // 使用对数坐标映射
      const logFreq: number = Math.log10(frequency);
      const mappedX: number = ((logFreq - LOG_MIN_FREQ) / (LOG_MAX_FREQ - LOG_MIN_FREQ)) * 20000;

      values.add(new EntryOhos(mappedX, dbValue));
    }

    // 创建数据集
    this.lineDataSet = new LineDataSet(values, '频谱数据');
    this.lineDataSet.setHighLightColor(parseInt(UnifiedChartStyle.HIGHLIGHT_COLOR.replace('#', '0xFF')));
    this.lineDataSet.setDrawIcons(false);
    this.lineDataSet.setMode(Mode.LINEAR);
    this.lineDataSet.setDrawCircles(false);
    this.lineDataSet.setDrawCircleHole(false);
    this.lineDataSet.setColorByColor(parseInt(UnifiedChartStyle.PRIMARY_COLOR.replace('#', '0xFF')));

    // 设置渐变填充
    const gradientFillColor = UnifiedChartStyle.getGradientFillColor(UnifiedChartStyle.PRIMARY_COLOR);
    const gradientArrayList = new JArrayList<ChartColorStop>();
    for (const stop of gradientFillColor) {
      gradientArrayList.add(stop);
    }
    this.lineDataSet.setGradientFillColor(gradientArrayList);
    this.lineDataSet.setDrawFilled(true);
    this.lineDataSet.setLineWidth(UnifiedChartStyle.LINE_WIDTHS.normal);

    // 禁用高亮指示器
    this.lineDataSet.setDrawHighlightIndicators(false);
    this.lineDataSet.setDrawVerticalHighlightIndicator(false);
    this.lineDataSet.setDrawHorizontalHighlightIndicator(false);

    const dataSetList: JArrayList<ILineDataSet> = new JArrayList<ILineDataSet>();
    dataSetList.add(this.lineDataSet);

    return new LineData(dataSetList);
  }

  /**
   * 生成柱状图数据
   */
  private generateBarData(): BarData {
    if (!this.displayData) {
      return new BarData(new JArrayList<IBarDataSet>());
    }

    const values: JArrayList<WaterfallEntry> = new JArrayList<WaterfallEntry>();

    // 使用对数坐标映射
    const LOG_MIN_FREQ = Math.log10(16);
    const LOG_MAX_FREQ = Math.log10(20000);

    for (const dataPoint of this.displayData.dataPoints) {
      const frequency: number = dataPoint.frequency;
      const dbValue: number = dataPoint.dbValue;

      // 使用对数坐标映射
      const logFreq: number = Math.log10(frequency);
      const mappedX: number = ((logFreq - LOG_MIN_FREQ) / (LOG_MAX_FREQ - LOG_MIN_FREQ)) * 20000;

      // 创建柱状图条目
      const entry = new WaterfallEntry(mappedX, 0, dbValue);
      values.add(entry);
    }

    this.barDataSet = new WaterfallDataSet(values, '频谱数据');
    this.barDataSet.setHighLightColor(0xFF888888);
    this.barDataSet.setDrawIcons(false);
    this.barDataSet.setValueTextSize(9);
    this.barDataSet.setValueTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
    this.barDataSet.setDrawValues(false);

    let dataSetList: JArrayList<IBarDataSet> = new JArrayList<IBarDataSet>();
    dataSetList.add(this.barDataSet);

    let barData: BarData = new BarData(dataSetList);
    barData.setBarWidth(0.7);
    barData.setTopRadius(3);

    return barData;
  }

  build() {
    Column() {
      // 线形图
      if (this.isLineChartMode && this.lineChartModel) {
        Stack() {
          LineChart({ model: this.lineChartModel })
            .width('100%')
            .height('100%')
            .borderRadius(UnifiedChartStyle.BORDER_RADIUS.large)

          // X轴单位标签
          Text('频率(Hz)')
            .fontSize(UnifiedChartStyle.FONT_SIZES.axis)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .position({ x: '87%', y: '5%' })
            .translate({ x: '-50%' })
            .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
            .padding({ left: 4, right: 4 })
            .borderRadius(4)

          // Y轴单位标签
          Text(`声级dB(${this.pk.weighting_type})`)
            .fontSize(UnifiedChartStyle.FONT_SIZES.axis)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .position({ x: '3%', y: '85%' })
            .translate({ y: '-50%' })
            .rotate({ angle: -90 })
            .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
            .padding({ left: 4, right: 4 })
            .borderRadius(4)

          // 峰值频率信息
          if (this.displayConfig?.showPeakFrequency && this.displayData?.peakInfo) {
            PeakFrequencyDisplay({
              peakInfo: this.displayData.peakInfo,
              positionX: '86%',
              positionY: '15%'
            })
          }
        }
        .width('100%')
        .layoutWeight(1)
      }

      // 柱状图
      if (this.isBarChartMode && this.barChartModel) {
        Stack() {
          WaterfallChart({ model: this.barChartModel })
            .width('100%')
            .height('100%')
            .borderRadius(UnifiedChartStyle.BORDER_RADIUS.large)

          // X轴单位标签
          Text('频率(Hz)')
            .fontSize(UnifiedChartStyle.FONT_SIZES.axis)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .position({ x: '87%', y: '5%' })
            .translate({ x: '-50%' })
            .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
            .padding({ left: 4, right: 4 })
            .borderRadius(4)

          // Y轴单位标签
          Text(`声级dB(${this.pk.weighting_type})`)
            .fontSize(UnifiedChartStyle.FONT_SIZES.axis)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .position({ x: '3%', y: '85%' })
            .translate({ y: '-50%' })
            .rotate({ angle: -90 })
            .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
            .padding({ left: 4, right: 4 })
            .borderRadius(4)

          // 峰值频率信息
          if (this.displayConfig?.showPeakFrequency && this.displayData?.peakInfo) {
            PeakFrequencyDisplay({
              peakInfo: this.displayData.peakInfo,
              positionX: '86%',
              positionY: '15%'
            })
          }
        }
        .width('100%')
        .layoutWeight(1)
      }

      // 混合模式 - 同时显示线形图和柱状图
      if (this.isHybridMode) {
        Stack() {
          // 柱状图作为底层
          if (this.barChartModel) {
            WaterfallChart({ model: this.barChartModel })
              .width('100%')
              .height('100%')
              .borderRadius(UnifiedChartStyle.BORDER_RADIUS.large)
              .opacity(0.7)
          }

          // 线形图作为上层
          if (this.lineChartModel) {
            LineChart({ model: this.lineChartModel })
              .width('100%')
              .height('100%')
              .borderRadius(UnifiedChartStyle.BORDER_RADIUS.large)
          }

          // X轴单位标签
          Text('频率(Hz)')
            .fontSize(UnifiedChartStyle.FONT_SIZES.axis)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .position({ x: '87%', y: '5%' })
            .translate({ x: '-50%' })
            .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
            .padding({ left: 4, right: 4 })
            .borderRadius(4)

          // Y轴单位标签
          Text(`声级dB(${this.pk.weighting_type})`)
            .fontSize(UnifiedChartStyle.FONT_SIZES.axis)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .position({ x: '3%', y: '85%' })
            .translate({ y: '-50%' })
            .rotate({ angle: -90 })
            .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
            .padding({ left: 4, right: 4 })
            .borderRadius(4)

          // 峰值频率信息
          if (this.displayConfig?.showPeakFrequency && this.displayData?.peakInfo) {
            PeakFrequencyDisplay({
              peakInfo: this.displayData.peakInfo,
              positionX: '86%',
              positionY: '15%'
            })
          }

          // 模式指示器
          Text('混合模式')
            .fontSize(12)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .backgroundColor('rgba(0, 153, 204, 0.8)')
            .padding({
              left: 8,
              right: 8,
              top: 4,
              bottom: 4
            })
            .borderRadius(4)
            .position({ x: '50%', y: '10%' })
            .translate({ x: '-50%' })
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