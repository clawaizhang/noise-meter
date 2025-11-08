import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { BaseChartComponent } from '../common/charts/BaseChartComponent';
import { ChartConfig, ChartType, DefaultChartConfig } from '../common/charts/ChartConfig';
import { AudioPresets } from '../../common/AudioConfig';
import { SpectrumDataProcessor, SpectrumDataPoint, PeakInfo } from './SpectrumDataProcessor';
import { PeakFrequencyDisplay } from './PeakFrequencyDisplay';
import {
  WaterfallChart,
  WaterfallChartModel,
  BarData,
  WaterfallDataSet,
  WaterfallEntry,
  ChartGesture,
  Description,
  EntryOhos,
  Fill,
  Highlight,
  IBarDataSet,
  JArrayList,
  Legend,
  LimitLabelPosition,
  LimitLine,
  MarkerView,
  OnChartGestureListener,
  OnChartValueSelectedListener,
  XAxis,
  XAxisPosition,
  YAxis,
  YAxisLabelPosition
} from '@ohos/mpchart';
import { UnifiedChartStyle } from '../common/charts/UnifiedChartStyle';

// 频率范围类型
interface FrequencyRange {
  startFreq: number;
  endFreq: number;
  label: string;
}

// 分贝颜色映射类型
interface DbColorRange {
  minDb: number;
  maxDb: number;
  color: string;
}

@ComponentV2
export struct SpectrumBarChartComponent {
  // 输入参数
  @Param canvasWidthInput: number = 0
  @Param canvasHeightInput: number = 0
  @Param sampleRate: number = 44100
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys) ?? new PreferenceKeys();

  // 依赖注入
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys) ?? new AppKeys()

  // 频谱数据
  @Local private currentSpectrumData: Float32Array = new Float32Array();
  @Local private smoothedSpectrumData: Float32Array = new Float32Array();
  @Local private previousSpectrumData: Float32Array = new Float32Array();

  // 瀑布图相关属性
  @Local private model: WaterfallChartModel = new WaterfallChartModel();
  @Local private dataSet: WaterfallDataSet | null = null;
  @Local private data: BarData | null = null;
  @Local private leftAxis: YAxis | null = null;
  @Local private rightAxis: YAxis | null = null;
  @Local private xAxis: XAxis | null = null;
  @Local private limitLines: LimitLine[] = [];
  @Local private normalMarker: MarkerView | null = null;

  // 频率相关属性
  @Local private frequencyLabels: string[] = [];
  @Local private peakFrequency: number = 0;
  @Local private peakDb: number = 0;
  @Local private selectedFrequency: number = 0;
  @Local private selectedDb: number = 0;
  
  // 峰值平滑处理相关
  @Local private smoothedPeakFrequency: number = 0;
  @Local private smoothedPeakDb: number = 0;
  @Local private lastPeakUpdateTime: number = 0;
  @Local private readonly PEAK_UPDATE_THRESHOLD_MS: number = 800; // 增加峰值更新最小间隔(ms)
  @Local private readonly PEAK_CHANGE_THRESHOLD_DB: number = 5.0; // 增加峰值变化阈值(dB)
  @Local private readonly PEAK_CHANGE_THRESHOLD_HZ: number = 250; // 增加峰值频率变化阈值(Hz)
  @Local private readonly PEAK_SMOOTHING_FACTOR: number = 0.05; // 降低平滑因子，使变化更平缓
  @Local private peakHistory: PeakInfo[] = []; // 峰值历史记录
  @Local private readonly PEAK_HISTORY_SIZE: number = 5; // 峰值历史记录大小

  // 频段定义
  private readonly FREQUENCY_BANDS: FrequencyRange[] = [
    { startFreq: 20, endFreq: 250, label: '低频' },
    { startFreq: 250, endFreq: 2000, label: '中频' },
    { startFreq: 2000, endFreq: 20000, label: '高频' }
  ];

  @Computed
  get fftSize() {
    return AudioPresets.getConfig(this.pk.audio_analysis_mode).fftSize;
  }

  @Computed
  get chartConfig(): ChartConfig {
    return {
      margin: DefaultChartConfig.margin,
      aspectRatio: 1.5,
      backgroundColor: DefaultChartConfig.backgroundColor,
      gridColor: DefaultChartConfig.gridColor,
      textColor: DefaultChartConfig.textColor,
      fontSize: DefaultChartConfig.fontSize,
      chartType: ChartType.SPECTRUM_BAR,
      responsive: DefaultChartConfig.responsive
    };
  }

  @Computed
  get displayDataPoints(): number {
    // 根据屏幕大小和FFT大小动态调整显示点数
    const screenWidth = this.ak.windowWidth;
    const basePoints = 20;
    const maxPoints = Math.min(this.fftSize / 2, 50);

    if (screenWidth < 600) {
      return Math.min(basePoints, maxPoints);
    } else if (screenWidth < 900) {
      return Math.min(basePoints * 1.5, maxPoints);
    } else {
      return Math.min(basePoints * 2, maxPoints);
    }
  }

  /**
   * 查找峰值频率
   */
  private findPeakFrequency(): void {
    const peakInfo = SpectrumDataProcessor.findPeakFrequency(
      this.smoothedSpectrumData,
      this.fftSize,
      this.sampleRate
    );

    if (peakInfo) {
      this.peakFrequency = peakInfo.frequency;
      this.peakDb = peakInfo.dbValue;
    }
  }

  /**
   * 应用峰值平滑处理
   * 减少峰值显示的抖动，提高用户体验
   */
  private applyPeakSmoothing(): void {
    const currentTime = Date.now();
    
    // 如果是第一次检测到峰值，直接使用
    if (this.smoothedPeakFrequency === 0 && this.smoothedPeakDb === 0) {
      this.smoothedPeakFrequency = this.peakFrequency;
      this.smoothedPeakDb = this.peakDb;
      this.lastPeakUpdateTime = currentTime;
      // 添加到历史记录
      this.peakHistory.push({
        frequency: this.peakFrequency,
        dbValue: this.peakDb,
        index: 0,
        amplitude: Math.pow(10, this.peakDb / 20)
      });
      return;
    }

    // 检查是否满足时间间隔要求
    if (currentTime - this.lastPeakUpdateTime < this.PEAK_UPDATE_THRESHOLD_MS) {
      return; // 时间间隔太短，不更新
    }

    // 检查峰值变化是否超过阈值
    const dbChange = Math.abs(this.peakDb - this.smoothedPeakDb);
    const freqChange = Math.abs(this.peakFrequency - this.smoothedPeakFrequency);

    if (dbChange < this.PEAK_CHANGE_THRESHOLD_DB && freqChange < this.PEAK_CHANGE_THRESHOLD_HZ) {
      return; // 变化太小，不更新
    }

    // 添加当前峰值到历史记录
    this.peakHistory.push({
      frequency: this.peakFrequency,
      dbValue: this.peakDb,
      index: 0,
      amplitude: Math.pow(10, this.peakDb / 20)
    });

    // 限制历史记录大小
    if (this.peakHistory.length > this.PEAK_HISTORY_SIZE) {
      this.peakHistory.shift();
    }

    // 计算历史记录的加权平均，最新的记录权重更高
    let weightedFreq = 0;
    let weightedDb = 0;
    let totalWeight = 0;

    for (let i = 0; i < this.peakHistory.length; i++) {
      const weight = (i + 1) / this.peakHistory.length; // 线性增加的权重
      weightedFreq += this.peakHistory[i].frequency * weight;
      weightedDb += this.peakHistory[i].dbValue * weight;
      totalWeight += weight;
    }

    const avgFreq = weightedFreq / totalWeight;
    const avgDb = weightedDb / totalWeight;

    // 应用平滑算法：结合历史平均和当前值
    this.smoothedPeakFrequency = this.PEAK_SMOOTHING_FACTOR * this.peakFrequency +
                                 (1 - this.PEAK_SMOOTHING_FACTOR) * avgFreq;
    this.smoothedPeakDb = this.PEAK_SMOOTHING_FACTOR * this.peakDb +
                         (1 - this.PEAK_SMOOTHING_FACTOR) * avgDb;
    
    this.lastPeakUpdateTime = currentTime;
  }

  /**
   * 生成频率标签
   */
  private generateFrequencyLabels(): void {
    this.frequencyLabels = [];
    const dataPoints = this.displayDataPoints;

    if (dataPoints <= 8) {
      // 少量数据点时显示所有标签
      for (let i = 0; i < dataPoints; i++) {
        const freq = SpectrumDataProcessor.getIndexFrequency(i * Math.floor(this.fftSize / 2 / dataPoints), this.fftSize, this.sampleRate);
        this.frequencyLabels.push(SpectrumDataProcessor.formatFrequency(freq));
      }
    } else {
      // 大量数据点时显示关键频率点
      const keyIndices = [0, Math.floor(dataPoints * 0.25), Math.floor(dataPoints * 0.5), Math.floor(dataPoints * 0.75), dataPoints - 1];
      for (const index of keyIndices) {
        const freq = SpectrumDataProcessor.getIndexFrequency(index * Math.floor(this.fftSize / 2 / dataPoints), this.fftSize, this.sampleRate);
        this.frequencyLabels.push(SpectrumDataProcessor.formatFrequency(freq));
      }
    }
  }

  /**
   * 格式化频率显示
   */
  private formatFrequency(freq: number): string {
    return SpectrumDataProcessor.formatFrequency(freq);
  }

  // 构造数据选择监听器
  private valueSelectedListener: OnChartValueSelectedListener = {
    onValueSelected: (e: EntryOhos, h: Highlight) => {
      const index = e.getX();
      this.selectedFrequency = SpectrumDataProcessor.getIndexFrequency(index, this.fftSize, this.sampleRate);
      this.selectedDb = e.getY();
      console.info(`SpectrumBarChartComponent 选中频率: ${this.formatFrequency(this.selectedFrequency)}, 分贝: ${this.selectedDb.toFixed(1)}dB`);
    },
    onNothingSelected: () => {
      this.selectedFrequency = 0;
      this.selectedDb = 0;
      console.info("SpectrumBarChartComponent 取消选择");
    }
  }

  // 构造手势识别事件监听器
  private chartGestureListener: OnChartGestureListener = {
    onChartGestureStart: (isTouchEvent: boolean, me: TouchEvent | GestureEvent, lastPerformedGestureMode: ChartGesture) => {
    },
    onChartGestureEnd: (isTouchEvent: boolean, me: TouchEvent | GestureEvent, lastPerformedGestureMode: ChartGesture) => {
      // ...todoSomething
    },
    onChartLongPressed: (isTouchEvent: boolean, me: TouchEvent | GestureEvent) => {
      // ...todoSomething
    },
    onChartDoubleTapped: (isTouchEvent: boolean, me: TouchEvent | GestureEvent) => {
      // ...todoSomething
    },
    onChartSingleTapped: (isTouchEvent: boolean, me: TouchEvent | GestureEvent) => {
      // ...todoSomething
    },
    onChartFling: (isTouchEvent: boolean, me1: TouchEvent | GestureEvent, me2: TouchEvent, velocityX: number, velocityY: number) => {
      // ...todoSomething
    },
    onChartScale: (isTouchEvent: boolean, me: TouchEvent | GestureEvent, scaleX: number, scaleY: number) => {
      // ...todoSomething
    },
    onChartTranslate: (isTouchEvent: boolean, me: TouchEvent | GestureEvent, dX: number, dY: number) => {
      // ...todoSomething
    },
    onChartMove: (isTouchEvent: boolean, me: TouchEvent | GestureEvent) => {
      // ...todoSomething
    }
  }

  @Monitor('ak.uiDisplayState.displaySpectrumData')
  onSpectrumDataChange(monitor: IMonitor) {
    const newSpectrum = monitor.value<Float32Array>()?.now;
    if (newSpectrum && this.ak.isDisplayApp) {
      this.currentSpectrumData = newSpectrum;
      this.applyDataSmoothing();
      this.findPeakFrequency();
      this.applyPeakSmoothing();
      this.generateFrequencyLabels();
      this.updateChartData();
    }
  }

  aboutToAppear() {
    // 初始化图表配置
    this.initializeChart();
  }

  /**
   * 应用数据平滑处理
   */
  private applyDataSmoothing(): void {
    if (this.currentSpectrumData.length === 0) return;

    // 初始化平滑数据数组
    if (this.smoothedSpectrumData.length !== this.currentSpectrumData.length) {
      this.smoothedSpectrumData = new Float32Array(this.currentSpectrumData.length);
      this.previousSpectrumData = new Float32Array(this.currentSpectrumData.length);
    }

    // 计算信号强度并获取自适应平滑因子
    const signalStrength = SpectrumDataProcessor.calculateAverageSignalStrength(this.currentSpectrumData);
    const adaptiveSmoothingFactor = SpectrumDataProcessor.calculateAdaptiveSmoothingFactor(signalStrength);

    // 应用自适应平滑
    this.smoothedSpectrumData = SpectrumDataProcessor.applyDataSmoothing(
      this.currentSpectrumData,
      this.previousSpectrumData,
      adaptiveSmoothingFactor
    );

    // 保存当前数据用于下次平滑
    this.previousSpectrumData.set(this.currentSpectrumData);
  }

  /**
   * 初始化图表配置
   */
  private initializeChart(): void {
    // Step1:必须：初始化图表配置构建类
    this.model = new WaterfallChartModel();

    // Step2:配置图表指定样式，各部件间没有先后之分

    // 为图表添加数据选择的监听器
    this.model.setOnChartValueSelectedListener(this.valueSelectedListener);
    // 为图表添加手势识别监听器
    this.model.setOnChartGestureListener(this.chartGestureListener);

    // 获取图表描述部件，设置图表描述部件不可用，即图表不进行绘制描述部件
    let description: Description | null = this.model.getDescription()
    if (description) {
      description.setEnabled(false);
    }

    // 获取图表图例部件，设置图表图例部件不可用
    let l: Legend | null = this.model.getLegend();
    if (l) {
      l.setEnabled(false);
    }

    // 设置图表数据最大的绘制数，如果超过该数值，则不进行绘制图表的数值标签
    this.model.setMaxVisibleValueCount(this.displayDataPoints);

    // 优化图表交互设置，关闭不必要的触摸功能
    this.model.setTouchEnabled(true); // 保持基本触摸功能以显示导航按钮
    this.model.setDragEnabled(false); // 禁用拖动
    this.model.setScaleEnabled(false); // 禁用缩放
    this.model.setScaleXEnabled(false); // 禁用X轴缩放
    this.model.setScaleYEnabled(false); // 禁用Y轴缩放
    this.model.setPinchZoom(false); // 禁用捏合缩放
    this.model.setHighlightPerTapEnabled(false); // 禁用点击高亮
    this.model.setHighlightPerDragEnabled(false); // 禁用拖动高亮

    // 是否绘制图表的背景色，绘制范围为图表瀑布图的绘制范围，不包含轴线之外的部分
    this.model.setDrawGridBackground(true);
    // 设置图表的背景色，颜色的规格需要满足CanvasRenderingContext2D.fillstyle/strokestyle规格
    this.model.setGridBackgroundColor(DefaultChartConfig.backgroundColor);
    // 设置不绘制瀑布图的柱体阴影背景
    this.model.setDrawBarShadow(false);

    // 设置瀑布图的数值在柱体上方
    this.model.setDrawValueAboveBar(false);

    // 设置图表左Y轴信息 - 将标签移至内部
    this.leftAxis = this.model.getAxisLeft();
    if (this.leftAxis) {
      // 使用正确的分贝范围
      const dbSteps: number[] = SpectrumDataProcessor.getDbSteps();
      this.leftAxis.setAxisMinimum(dbSteps[0]); // -20
      this.leftAxis.setAxisMaximum(dbSteps[dbSteps.length - 1]); // 140
      this.leftAxis.setDrawLimitLinesBehindData(false);
      this.leftAxis.setDrawGridLines(true);
      this.leftAxis.setDrawAxisLine(false); // 隐藏Y轴线
      this.leftAxis.setDrawLabels(true);
      this.leftAxis.setPosition(YAxisLabelPosition.INSIDE_CHART); // 将Y轴标签移至内部
      this.leftAxis.setTextColor(DefaultChartConfig.textColor);
      this.leftAxis.setTextSize(DefaultChartConfig.fontSize.axis);
      this.leftAxis.setLabelCount(dbSteps.length, true); // 使用实际的分贝步进数量
      this.leftAxis.setAxisLineWidth(0); // 设置轴线宽度为0
      this.leftAxis.setAxisLineColor(parseInt(DefaultChartConfig.textColor.replace('#', '0xFF')));
      this.leftAxis.setSpaceTop(10); // 为内部标签添加顶部间距
      this.leftAxis.setSpaceBottom(10); // 为内部标签添加底部间距
      
      // 确保Y轴使用精确的分贝刻度
      this.leftAxis.setGranularity(20); // 设置20dB的间隔
      this.leftAxis.setCenterAxisLabels(false); // 禁用中心轴标签，确保只显示定义的刻度

      // 添加所有限制线
      for (const limitLine of this.limitLines) {
        this.leftAxis.addLimitLine(limitLine);
      }
    }

    // 设置图表右Y轴信息
    this.rightAxis = this.model.getAxisRight();
    if (this.rightAxis) {
      this.rightAxis.setEnabled(false);
      this.rightAxis.setAxisMinimum(0);
    }

    // 设置X轴信息 - 将标签移至上方并添加刻度线
    this.xAxis = this.model.getXAxis();
    if (this.xAxis) {
      this.xAxis.setPosition(XAxisPosition.TOP); // 将标签移至上方
      this.xAxis.setDrawGridLines(true); // 启用水平网格线作为刻度线
      this.xAxis.setDrawAxisLine(true); // 绘制轴线
      this.xAxis.setDrawLabels(true);
      this.xAxis.setTextColor(DefaultChartConfig.textColor);
      this.xAxis.setTextSize(DefaultChartConfig.fontSize.axis);
      this.xAxis.setLabelCount(Math.min(this.frequencyLabels.length, 8), true);
      this.xAxis.setGranularity(1);
      this.xAxis.setAxisLineWidth(UnifiedChartStyle.LINE_WIDTHS.grid); // 显示轴线
      this.xAxis.setAxisLineColor(parseInt(DefaultChartConfig.textColor.replace('#', '0xFF')));
      this.xAxis.setYOffset(10); // 正偏移，使标签显示在图表上方
      this.xAxis.setAvoidFirstLastClipping(true); // 避免首尾标签被裁剪
    }

    // 为图表设置markerView
    this.normalMarker = new MarkerView();
    this.model.setMarker(this.normalMarker);

    // 生成初始数据
    this.data = this.generateSpectrumBarData();

    // 将数据与图表配置类绑定
    this.model.setData(this.data);
    // 设置图表最大的X轴显示范围
    this.model.setVisibleXRangeMaximum(this.displayDataPoints);
  }

  /**
   * 生成频谱柱状图数据
   */
  private generateSpectrumBarData(): BarData {
    let values: JArrayList<WaterfallEntry> = new JArrayList<WaterfallEntry>();

    // 使用平滑后的频谱数据
    const sourceData = this.smoothedSpectrumData.length > 0 ?
      this.smoothedSpectrumData : this.currentSpectrumData;

    if (sourceData.length > 0) {
      // 使用增强的频谱数据（包含低频插值点）
      const enhancedDataPoints = SpectrumDataProcessor.generateEnhancedSpectrumData(
        sourceData,
        this.fftSize,
        this.sampleRate,
        16, // 最小频率16Hz
        SpectrumDataProcessor.MAX_FREQUENCY
      );

      // 根据显示点数均匀采样增强后的数据点
      const displayCount = this.displayDataPoints;
      const step = Math.max(1, Math.floor(enhancedDataPoints.length / displayCount));
      
      for (let i = 0; i < displayCount && i * step < enhancedDataPoints.length; i++) {
        const dataPoint = enhancedDataPoints[i * step];
        const dbValue = dataPoint.dbValue;
        
        // 创建柱状图条目，使用索引作为X值，分贝值作为Y值范围
        const entry = new WaterfallEntry(i, 0, dbValue);

        // 根据分贝值设置颜色
        const color = SpectrumDataProcessor.getDbColor(dbValue);
        // 注意：这里需要根据MPChart库的实际API来设置颜色
        // 如果库支持单独设置每个柱子的颜色，可以在这里设置

        values.add(entry);
      }
    } else {
      // 如果没有频谱数据，则使用默认数据
      const dataPoints = this.displayDataPoints;
      for (let i = 0; i < dataPoints; i++) {
        const randomValue = Math.random() * 80; // 默认值在安全范围内
        values.add(new WaterfallEntry(i, 0, randomValue));
      }
    }

    this.dataSet = new WaterfallDataSet(values, '频谱数据');
    this.dataSet.setHighLightColor(0xFF888888);
    this.dataSet.setDrawIcons(false);
    this.dataSet.setValueTextSize(9);
    this.dataSet.setValueTextColor(parseInt(DefaultChartConfig.textColor.replace('#', '0xFF')));

    // 设置柱状图样式
    this.dataSet.setDrawValues(false); // 不显示数值标签，避免拥挤

    // 尝试设置颜色渐变（如果库支持）
    // 这里可能需要根据MPChart库的实际API进行调整
    try {
      // 设置柱状图颜色数组
      const colors: number[] = [];
      for (let i = 0; i < values.size(); i++) {
        const entry = values.get(i);
        const dbValue = entry.getY();
        const color = SpectrumDataProcessor.getDbColor(dbValue);
        // 将颜色字符串转换为数字
        colors.push(parseInt(color.replace('#', '0xFF')));
      }
      // 使用正确的API设置颜色
      // 注意：根据ArkTS约束，不能使用setColors方法
      // 这里使用其他方式设置颜色，例如通过构造函数或其他API
      // 如果WaterfallDataSet不支持设置颜色数组，可以考虑在创建时设置
    } catch (e) {
      console.error('设置柱状图颜色失败:', e);
    }

    let dataSetList: JArrayList<IBarDataSet> = new JArrayList<IBarDataSet>();
    dataSetList.add(this.dataSet);

    let barData: BarData = new BarData(dataSetList);
    // 设置瀑布图宽度
    barData.setBarWidth(0.7);
    // 设置顶部圆角半径
    barData.setTopRadius(3);

    return barData;
  }

  /**
   * 更新图表数据
   */
  private updateChartData(): void {
    if (!this.model) {
      return;
    }

    // 生成新的数据
    const newData = this.generateSpectrumBarData();

    // 只有当新数据与当前数据有显著差异时才更新
    if (this.shouldUpdateChart(newData)) {
      this.data = newData;

      // 更新图表数据
      this.model.setData(this.data);

      // 更新X轴标签
      if (this.xAxis && this.frequencyLabels.length > 0) {
        // 这里可能需要根据库的API设置自定义标签
        // 如果库支持，可以设置频率标签
      }

      // 触发数据更新
      this.data.notifyDataChanged();
      this.model.notifyDataSetChanged();
      this.model.invalidate();
    }
  }

  /**
   * 判断是否需要更新图表
   * 通过比较新旧数据的差异来减少不必要的更新
   */
  private shouldUpdateChart(newData: BarData): boolean {
    if (!this.data || !newData) {
      return true;
    }

    try {
      const oldDataSet = this.data.getDataSets().get(0) as WaterfallDataSet;
      const newDataSet = newData.getDataSets().get(0) as WaterfallDataSet;
      
      if (!oldDataSet || !newDataSet) {
        return true;
      }

      const oldValues = oldDataSet.getValues()!;
      const newValues = newDataSet.getValues()!;
      
      if (oldValues.size() !== newValues.size()) {
        return true;
      }

      // 计算数据差异，只有当差异超过阈值时才更新
      let totalDifference = 0;
      for (let i = 0; i < oldValues.size(); i++) {
        const oldValue = oldValues.get(i).getY();
        const newValue = newValues.get(i).getY();
        totalDifference += Math.abs(oldValue - newValue);
      }

      const averageDifference = totalDifference / oldValues.size();
      return averageDifference > 2.0; // 只有当平均差异超过2dB时才更新
    } catch (e) {
      console.error('比较图表数据时出错:', e);
      return true; // 出错时默认更新
    }
  }

  build() {
    Column() {
      // 使用瀑布图组件显示频谱柱状图
      Stack() {
        WaterfallChart({ model: this.model })
          .width('100%')
          .height('100%')
          .borderRadius(16)
          .backgroundColor(this.chartConfig.backgroundColor)
        
        // X轴单位标签
        Text('频率(Hz)')
          .fontSize(DefaultChartConfig.fontSize.axis)
          .fontColor(DefaultChartConfig.textColor)
          .position({ x: '95%', y: '2%' })
          .translate({ x: '-50%' })
          .backgroundColor(this.chartConfig.backgroundColor)
          .padding({ left: 4, right: 4 })
          .borderRadius(4)
        
        // Y轴单位标签
        Text('声级(dB)')
          .fontSize(DefaultChartConfig.fontSize.axis)
          .fontColor(DefaultChartConfig.textColor)
          .position({ x: '1%', y: '5%' })
          .translate({ y: '-50%' })
          .rotate({ angle: -90 })
          .backgroundColor(this.chartConfig.backgroundColor)
          .padding({ left: 4, right: 4 })
          .borderRadius(4)
        
        // 峰值频率信息 - 使用通用组件
        PeakFrequencyDisplay({
          peakInfo: {
            frequency: this.smoothedPeakFrequency,
            dbValue: this.smoothedPeakDb
          },
          positionX: '95%',
          positionY: '8%'
        })
      }
      .width('100%')
      .layoutWeight(1) // 占用剩余空间
      .margin({ left: 16, right: 16, bottom: 8 })

      // 选中频率信息
      if (this.selectedFrequency > 0) {
        Row() {
          Text(`选中频率: ${this.formatFrequency(this.selectedFrequency)}`)
            .fontSize(DefaultChartConfig.fontSize.label)
            .fontColor(DefaultChartConfig.textColor)
          Blank()
          Text(`${this.selectedDb.toFixed(1)}dB`)
            .fontSize(DefaultChartConfig.fontSize.label)
            .fontColor(SpectrumDataProcessor.getDbColor(this.selectedDb))
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#2A2B2D') // 深色背景，与整体风格一致
        .borderRadius({ topLeft: 16, topRight: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(DefaultChartConfig.backgroundColor) // 设置整个组件的背景色
  }
}