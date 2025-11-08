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
  YAxisLabelPosition,
  IAxisValueFormatter,
  AxisBase,
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
      // 调试日志：记录频率到X轴的映射
      console.info(`[X轴格式化器初始化] 频率${freq}Hz -> X值${xValue}`);
    }
    return map;
  })();
  
  getFormattedValue(value: number, axis: AxisBase): string {
    // 调试日志：记录输入的X值
    console.info(`[X轴格式化器] 输入X值: ${value}`);
    
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
    
    // 调试日志：记录找到的最接近频率和距离
    console.info(`[X轴格式化器] 最接近频率: ${closestFreq}Hz, 距离: ${minDistance}`);
    
    // 根据频率范围使用不同的容差
    let threshold: number;
    if (closestFreq <= 63) {
      threshold = 200; // 低频区域使用更大容差，确保63Hz能匹配
    } else if (closestFreq <= 1000) {
      threshold = 450; // 中频区域使用中等容差，特别为1000Hz增加容差
    } else {
      threshold = 700; // 高频区域使用较大容差
    }
    
    // 调试日志：记录容差和比较结果
    console.info(`[X轴格式化器] 容差: ${threshold}, 是否匹配: ${minDistance <= threshold}`);
    
    // 隐藏第一个和最后一个标签
    if (closestFreq === 16 || closestFreq === 16000) {
      console.info(`[X轴格式化器] 隐藏首尾标签: ${closestFreq}Hz`);
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
      
      // 调试日志：记录最终返回的标签
      console.info(`[X轴格式化器] 返回标签: "${formattedValue}"`);
      return formattedValue;
    } else {
      // 调试日志：记录不匹配的情况
      console.info(`[X轴格式化器] 不匹配，返回空字符串`);
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
    // 获取分贝步进值
    const dbSteps: number[] = SpectrumDataProcessor.getDbSteps();
    
    // 隐藏第一个和最后一个标签
    if (value === dbSteps[0] || value === dbSteps[dbSteps.length - 1]) {
      console.info(`[Y轴格式化器] 隐藏首尾标签: ${value}dB`);
      return '';
    }
    
    // 返回正常的分贝值标签
    console.info(`[Y轴格式化器] 返回标签: ${value}dB`);
    return `${value}`;
  }
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
   * 生成频率标签 - 按照对数分布显示标准频率点
   */
  private generateFrequencyLabels(): void {
    this.frequencyLabels = [];
    
    // 标准频率点 - 按照对数分布
    const standardFreqs = [16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
    
    // 根据采样率过滤有效的频率点
    const validFreqs = standardFreqs.filter(freq => freq >= 16 && freq <= this.sampleRate / 2);
    
    // 获取增强的频谱数据用于计算索引
    const enhancedDataPoints = SpectrumDataProcessor.generateEnhancedSpectrumData(
      this.smoothedSpectrumData.length > 0 ? this.smoothedSpectrumData : this.currentSpectrumData,
      this.fftSize,
      this.sampleRate,
      16, // 最小频率16Hz
      SpectrumDataProcessor.MAX_FREQUENCY
    );
    
    // 为每个有效频率点计算对应的显示索引
    const displayCount = this.displayDataPoints;
    const frequencyIndexMap: Map<number, number> = new Map();
    
    for (const freq of validFreqs) {
      // 在增强数据中找到最接近该频率的数据点
      let closestIndex = 0;
      let minDiff = Number.MAX_VALUE;
      
      for (let i = 0; i < enhancedDataPoints.length; i++) {
        const diff = Math.abs(enhancedDataPoints[i].frequency - freq);
        if (diff < minDiff) {
          minDiff = diff;
          closestIndex = i;
        }
      }
      
      // 将增强数据索引转换为显示索引
      const displayIndex = Math.round((closestIndex / enhancedDataPoints.length) * displayCount);
      frequencyIndexMap.set(displayIndex, freq);
    }
    
    // 按索引排序并生成标签
    const sortedIndices = Array.from(frequencyIndexMap.keys()).sort((a, b) => a - b);
    
    for (const index of sortedIndices) {
      const freq = frequencyIndexMap.get(index)!;
      this.frequencyLabels.push(SpectrumDataProcessor.formatFrequency(freq));
    }
    
    // 如果没有有效的频率标签，使用默认对数分布
    if (this.frequencyLabels.length === 0) {
      const logIndices = SpectrumDataProcessor.generateLogarithmicIndices(Math.min(8, displayCount), this.fftSize);
      for (const index of logIndices) {
        const freq = SpectrumDataProcessor.getIndexFrequency(index, this.fftSize, this.sampleRate);
        if (freq >= 16 && freq <= this.sampleRate / 2) {
          this.frequencyLabels.push(SpectrumDataProcessor.formatFrequency(freq));
        }
      }
    }
    
    console.info(`[频谱图] 生成频率标签: ${this.frequencyLabels.join(', ')}`);
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
      // 对于峰值频率计算，我们需要使用未加权的频谱数据
      // 但是这里我们只能使用已有的加权的频谱数据，因为原始音频数据不可用
      // 峰值频率的主要计算已经在AudioController中使用未加权频谱完成
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

    // 设置图表数据最大的绘制数
    this.model.setMaxVisibleValueCount(100);

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
    this.model.setGridBackgroundColor(UnifiedChartStyle.BACKGROUND_COLOR);
    // 设置不绘制瀑布图的柱体阴影背景
    this.model.setDrawBarShadow(false);

    // 设置瀑布图的数值在柱体上方
    this.model.setDrawValueAboveBar(false);

    // 设置图表左Y轴信息 - 参考现行图的配置
    this.leftAxis = this.model.getAxisLeft();
    if (this.leftAxis) {
      // 获取分贝步进值并设置正确的标签数量
      const dbSteps: number[] = SpectrumDataProcessor.getDbSteps();
      this.leftAxis.setLabelCount(dbSteps.length, true); // 使用实际的分贝步进数量
      // 设置标签位置为内部
      this.leftAxis.setPosition(YAxisLabelPosition.INSIDE_CHART);
      // 设置距离顶部距离
      this.leftAxis.setSpaceTop(15);
      this.leftAxis.setSpaceBottom(15); // 为内部标签添加底部间距
      // 设置最小值和最大值，确保使用正确的分贝范围
      this.leftAxis.setAxisMinimum(dbSteps[0]); // -20
      this.leftAxis.setAxisMaximum(dbSteps[dbSteps.length - 1]); // 140
      this.leftAxis.setYOffset(-10);
      // 设置网格线样式
      this.leftAxis.setDrawGridLines(true);
      this.leftAxis.setGridColor(parseInt(UnifiedChartStyle.GRID_COLOR.replace('#', '0xFF')));
      this.leftAxis.setGridLineWidth(UnifiedChartStyle.LINE_WIDTHS.grid);
      this.leftAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      this.leftAxis.setTextSize(UnifiedChartStyle.FONT_SIZES.axis);
      
      // 优化Y轴显示 - 隐藏轴线但保留标签
      this.leftAxis.setDrawAxisLine(false); // 隐藏Y轴线
      this.leftAxis.setAxisLineWidth(0); // 设置轴线宽度为0
      this.leftAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      this.leftAxis.setTextSize(UnifiedChartStyle.FONT_SIZES.axis);
      
      // 确保Y轴使用精确的分贝刻度
      this.leftAxis.setGranularity(20); // 设置20dB的间隔
      this.leftAxis.setCenterAxisLabels(false); // 禁用中心轴标签，确保只显示定义的刻度
      
      // 使用自定义的Y轴格式化器，隐藏第一个和最后一个标签
      const yAxisFormatter = new YAxisValueFormatter();
      this.leftAxis.setValueFormatter(yAxisFormatter);
      
    }

    // 设置图表右Y轴信息
    this.rightAxis = this.model.getAxisRight();
    if (this.rightAxis) {
      this.rightAxis.setEnabled(false);
      this.rightAxis.setAxisMinimum(0);
    }

    // 设置X轴信息 - 参考现行图的配置
    this.xAxis = this.model.getXAxis();
    if (this.xAxis) {
      this.xAxis.setPosition(XAxisPosition.TOP); // 将标签移至上方
      this.xAxis.setDrawGridLines(true); // 启用水平网格线作为刻度线
      this.xAxis.setDrawAxisLine(true); // 绘制轴线
      this.xAxis.setGranularity(1);
      this.xAxis.setLabelCount(11, false); // 强制显示11个标签，不自动调整
      this.xAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      this.xAxis.setTextSize(UnifiedChartStyle.FONT_SIZES.axis);
      this.xAxis.setYOffset(-15); // 正偏移，使标签显示在图表上方
      this.xAxis.setXOffset(20);
      this.xAxis.setAvoidFirstLastClipping(true); // 避免首尾标签被裁剪
      
      // 设置图表X轴显示范围，与映射后的X值保持一致
      // 由于跳过了16Hz以下的数据，所以最小值应该对应16Hz的映射值
      
      // 直接设置范围，因为16Hz映射到0，20kHz映射到20000
      this.xAxis.setAxisMinimum(0);     // 16Hz对应的映射值
      this.xAxis.setAxisMaximum(20000);  // 20kHz对应的映射值
      
      // 使用自定义的X轴格式化器，显示标准对数频率点
      const formatter = new StandardFrequencyAxisValueFormatter();
      this.xAxis.setValueFormatter(formatter);
      
      // 设置X轴单位标签
      this.xAxis.setAxisLineWidth(UnifiedChartStyle.LINE_WIDTHS.grid); // 显示轴线
      this.xAxis.setAxisLineColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
    }

    // 为图表设置markerView
    this.normalMarker = new MarkerView();
    this.model.setMarker(this.normalMarker);

    // 生成初始数据
    this.data = this.generateSpectrumBarData();

    // 将数据与图表配置类绑定
    this.model.setData(this.data);
    
    this.model.setVisibleXRangeMaximum(20000); // 显示最大20kHz范围
  }

  /**
   * 生成频谱柱状图数据 - 参考现行图的对数坐标映射
   */
  private generateSpectrumBarData(): BarData {
    let values: JArrayList<WaterfallEntry> = new JArrayList<WaterfallEntry>();

    // 使用平滑后的频谱数据
    const sourceData = this.smoothedSpectrumData.length > 0 ?
      this.smoothedSpectrumData : this.currentSpectrumData;

    if (sourceData.length > 0) {
      // 获取频率步进和分贝步进
      const dbSteps: number[] = SpectrumDataProcessor.getDbSteps();
      
      // 与原来的Canvas实现保持一致：使用对数坐标映射
      const LOG_MIN_FREQ = Math.log10(16); // 16Hz
      const logMaxFreq = Math.log10(20000); // 20kHz
      
      // 使用SpectrumDataProcessor生成增强的频谱数据点（包含低频插值）
      const enhancedDataPoints = SpectrumDataProcessor.generateEnhancedSpectrumData(
        sourceData,
        this.fftSize,
        this.sampleRate,
        16, // 最小频率16Hz
        SpectrumDataProcessor.MAX_FREQUENCY
      );
      
      // 遍历增强后的数据点
      for (const dataPoint of enhancedDataPoints) {
        const frequency: number = dataPoint.frequency;
        const dbValue: number = dataPoint.dbValue;
        
        // 确保分贝值在合理范围内
        const clampedDbValue: number = Math.max(dbSteps[0], Math.min(dbSteps[dbSteps.length - 1], dbValue));
        
        // 使用对数坐标映射，与原来的Canvas实现完全一致
        // 这样低频率部分会有更多的显示空间，高频率部分会被压缩
        const logFreq: number = Math.log10(frequency);
        const mappedX: number = ((logFreq - LOG_MIN_FREQ) / (logMaxFreq - LOG_MIN_FREQ)) * 20000;
        
        // 调试信息：只记录前几个数据点
        if (enhancedDataPoints.indexOf(dataPoint) < 5) {
          console.info(`[频谱图] 数据点: 频率=${frequency}Hz, 映射X值=${mappedX}, 分贝=${clampedDbValue}dB`);
        }
        
        // 创建柱状图条目，使用映射后的X值，确保与原来的Canvas实现完全一致
        // 注意：WaterfallEntry的构造函数参数可能是(x, y, y2)或(x, y, height)
        // 这里使用(mappedX, 0, clampedDbValue)表示从0开始到clampedDbValue高度的柱子
        const entry = new WaterfallEntry(mappedX, 0, clampedDbValue);
        values.add(entry);
      }
      
      console.info(`[频谱图] 生成了${values.size()}个数据点，分贝范围: ${dbSteps[0]}dB 到 ${dbSteps[dbSteps.length - 1]}dB`);
    } else {
      // 如果没有频谱数据，则使用默认数据
      const dbSteps: number[] = SpectrumDataProcessor.getDbSteps();
      const minDb = dbSteps[0]; // -20dB
      const maxDb = dbSteps[dbSteps.length - 1]; // 140dB
      
      // 生成一些默认的对数分布数据点
      for (let i = 0; i < 50; i++) {
        // 在对数空间中均匀分布频率
        const logFreq = Math.log10(16) + (Math.log10(20000) - Math.log10(16)) * (i / 50);
        const frequency = Math.pow(10, logFreq);
        const mappedX = ((logFreq - Math.log10(16)) / (Math.log10(20000) - Math.log10(16))) * 20000;
        
        // 生成在有效范围内的默认值
        const randomValue = minDb + Math.random() * (maxDb - minDb) * 0.6; // 默认值在安全范围内
        values.add(new WaterfallEntry(mappedX, 0, randomValue));
      }
      
      console.info(`[频谱图] 使用默认数据，生成了${values.size()}个数据点`);
    }

    this.dataSet = new WaterfallDataSet(values, '频谱数据');
    this.dataSet.setHighLightColor(0xFF888888);
    this.dataSet.setDrawIcons(false);
    this.dataSet.setValueTextSize(9);
    this.dataSet.setValueTextColor(parseInt(DefaultChartConfig.textColor.replace('#', '0xFF')));

    // 设置柱状图样式
    this.dataSet.setDrawValues(false); // 不显示数值标签，避免拥挤

    // 设置柱状图颜色 - 根据分贝值动态设置
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
      
      // 尝试设置颜色 - 根据MPChart库的实际API调整
      // 注意：根据ArkTS约束，可能需要使用其他方式设置颜色
      console.info(`[频谱图] 设置了${colors.length}个颜色值`);
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
        
        // 峰值频率信息 - 使用通用组件
        PeakFrequencyDisplay({
          peakInfo: {
            frequency: this.ak.uiDisplayState.displayPeakFreq,
            dbValue: this.ak.uiDisplayState.displayDb
          },
          positionX: '86%',
          positionY: '15%'
        })
      }
      .width('100%')
      .layoutWeight(1) // 占用剩余空间

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