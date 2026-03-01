import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AudioPresets } from '../../common/AudioConfig';
import { SpectrumDataProcessor, PeakInfo, PeakInterpolationMethod } from './SpectrumDataProcessor';
import { UnifiedChartStyle } from '../common/charts/UnifiedChartStyle';
import { SpectrumDisplayService, SpectrumDisplayData } from '../../services/SpectrumDisplayService';
import { PeakFrequencyDisplay } from './PeakFrequencyDisplay';
import { MultiplePeakFrequencyDisplay } from './MultiplePeakFrequencyDisplay';
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
  AxisBase,
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
      threshold = 200;
    } else if (closestFreq <= 1000) {
      threshold = 450;
    } else {
      threshold = 700;
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
  private minDb: number = -20;
  private maxDb: number = 140;
  
  setRange(minDb: number, maxDb: number): void {
    this.minDb = minDb;
    this.maxDb = maxDb;
  }
  
  getFormattedValue(value: number, axis: AxisBase): string {
    // 隐藏第一个和最后一个标签
    if (value <= this.minDb + 0.1 || value >= this.maxDb - 0.1) {
      return '';
    }
    return `${Math.round(value)}`;
  }
}

@ComponentV2
export struct LineChartSpectrumComponent {
  // 输入参数
  @Param sampleRate: number = 44100
  @Param isVisible: boolean = true // 图表是否可见
  @Param isPreviewMode: boolean = false // 是否为预览模式（紧凑显示）
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys) ?? new PreferenceKeys();

  // 频谱显示服务
  private spectrumDisplayService: SpectrumDisplayService = SpectrumDisplayService.getInstance();
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys) ?? new AppKeys()

  // 频谱数据
  @Local private currentSpectrumData: Float32Array = new Float32Array();
  @Local private peakInfo: PeakInfo | null = null;
  @Local private peakInfos: PeakInfo[] = [];
  
  // 性能优化：缓存 displayData 避免重复处理
  private cachedDisplayData: SpectrumDisplayData | null = null;

  // LineChart 相关
  @Local private model: LineChartModel | null = null;
  @Local private dataSet: LineDataSet | null = null;
  @Local private leftAxis: YAxis | null = null;
  @Local private rightAxis: YAxis | null = null;
  @Local private xAxis: XAxis | null = null;
  @Local private limitLine1: LimitLine | null = null;
  @Local private limitLine2: LimitLine | null = null;
  
  // 性能优化：帧率控制
  private lastUpdateTime: number = 0;
  private readonly MIN_UPDATE_INTERVAL: number = 100; // 最小更新间隔 100ms (10 FPS)
  
  // 性能优化：Y轴格式化器缓存
  private yAxisFormatter: YAxisValueFormatter = new YAxisValueFormatter();

  @Computed
  get fftSize() {
    return AudioPresets.getConfig(this.pk.audio_analysis_mode).fftSize;
  }

  // 构造数据选择监听器
  private valueSelectedListener: OnChartValueSelectedListener = {
    onValueSelected: (e: EntryOhos, h: Highlight) => {
      // 处理数据点选择事件
      console.info(`[频谱图] 选中数据点: x=${e.getX()}, y=${e.getY()}`);
    },
    onNothingSelected: () => {
      // 处理取消选择事件
      console.info(`[频谱图] 取消选择`);
    }
  }

  @Monitor('ak.uiDisplayState.displaySpectrumData')
  onSpectrumDataChange(monitor: IMonitor) {
    // 只有当图表可见时才处理数据更新
    if (!this.isVisible) {
      return;
    }
    
    // 性能优化：帧率控制
    const now = Date.now();
    if (now - this.lastUpdateTime < this.MIN_UPDATE_INTERVAL) {
      return;
    }
    this.lastUpdateTime = now;
    
    const newSpectrum = monitor.value<Float32Array>()?.now;
    if (newSpectrum && this.ak.isDisplayApp) {
      this.currentSpectrumData = newSpectrum;
      
      // 获取频谱显示配置
      const spectrumConfig = this.spectrumDisplayService.getDisplayConfig(this.pk);
      
      // 使用SpectrumDisplayService处理频谱数据
      // 性能优化：缓存 displayData 供 generateLineData 使用
      this.cachedDisplayData = this.spectrumDisplayService.processSpectrumData(
        this.currentSpectrumData,
        this.fftSize,
        this.sampleRate,
        spectrumConfig
      );
      
      // 使用处理后的峰值信息
      this.peakInfo = this.cachedDisplayData.peakInfo;
      this.peakInfos = this.cachedDisplayData.peakInfos;
      
      // 更新图表数据
      this.updateChartData();
    }
  }

  /**
   * 更新图表数据
   */
  private updateChartData(): void {
    if (!this.model || this.currentSpectrumData.length === 0 || !this.isVisible) {
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
   * 生成频谱图数据
   * 直接使用SpectrumDisplayService处理后的数据
   */
  private generateLineData(): LineData {
    const values: JArrayList<EntryOhos> = new JArrayList<EntryOhos>();
    
    // 性能优化：使用缓存的 displayData
    const displayData = this.cachedDisplayData;
    if (!displayData) {
      // 如果没有缓存数据，返回空数据集
      const emptyDataSetList: JArrayList<ILineDataSet> = new JArrayList<ILineDataSet>();
      const emptyDataSet = new LineDataSet(values, '频谱数据');
      emptyDataSetList.add(emptyDataSet);
      return new LineData(emptyDataSetList);
    }
    
    // 获取频谱显示配置
    const spectrumConfig = this.spectrumDisplayService.getDisplayConfig(this.pk);
    
    // 获取频率和分贝范围
    const frequencyRangeConfig = this.spectrumDisplayService.getFrequencyRange(spectrumConfig, this.fftSize, this.sampleRate);
    const decibelRangeConfig = this.spectrumDisplayService.getDecibelRange(spectrumConfig);
    
    // 与原来的Canvas实现保持一致：使用对数坐标映射
    const LOG_MIN_FREQ = Math.log10(frequencyRangeConfig.minFreq);
    const logMaxFreq = Math.log10(frequencyRangeConfig.maxFreq);
    
    // 遍历处理后的数据点
    for (const dataPoint of displayData.dataPoints) {
      const frequency: number = dataPoint.frequency;
      const dbValue: number = dataPoint.dbValue;
      
      // 确保分贝值在配置范围内
      const clampedDbValue: number = Math.max(decibelRangeConfig.minDb, Math.min(decibelRangeConfig.maxDb, dbValue));
      
      // 使用对数坐标映射，与原来的Canvas实现完全一致
      // 这样低频率部分会有更多的显示空间，高频率部分会被压缩
      const logFreq: number = Math.log10(frequency);
      const mappedX: number = ((logFreq - LOG_MIN_FREQ) / (logMaxFreq - LOG_MIN_FREQ)) * 20000;
      
      // 使用映射后的X值，确保与原来的Canvas实现完全一致
      values.add(new EntryOhos(mappedX, clampedDbValue));
    }

    // 创建数据集
    this.dataSet = new LineDataSet(values, '频谱数据');
    this.dataSet.setHighLightColor(parseInt(UnifiedChartStyle.HIGHLIGHT_COLOR.replace('#', '0xFF')));
    this.dataSet.setDrawIcons(false);
    this.dataSet.setMode(Mode.LINEAR); // 直线模式
    this.dataSet.setDrawCircles(false); // 不绘制圆点，因为数据点太多
    this.dataSet.setDrawCircleHole(false);
    this.dataSet.setColorByColor(parseInt(UnifiedChartStyle.PRIMARY_COLOR.replace('#', '0xFF'))); // 设置折线颜色

    // 使用统一样式的渐变色填充
    const gradientFillColor = UnifiedChartStyle.getGradientFillColor(UnifiedChartStyle.PRIMARY_COLOR);
    const gradientArrayList = new JArrayList<ChartColorStop>();
    for (const stop of gradientFillColor) {
      gradientArrayList.add(stop);
    }
    this.dataSet.setGradientFillColor(gradientArrayList);
    this.dataSet.setDrawFilled(true);
    this.dataSet.setLineWidth(UnifiedChartStyle.LINE_WIDTHS.ultra_thin); // 使用统一样式线宽
    
    // 禁用高亮指示器
    this.dataSet.setDrawHighlightIndicators(false); // 禁用高亮指示器
    this.dataSet.setDrawVerticalHighlightIndicator(false); // 禁用垂直高亮线
    this.dataSet.setDrawHorizontalHighlightIndicator(false); // 禁用水平高亮线

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

    // 获取频谱显示配置
    const spectrumConfig = this.spectrumDisplayService.getDisplayConfig(this.pk);
    const decibelRangeConfig = this.spectrumDisplayService.getDecibelRange(spectrumConfig);
    const frequencyRangeConfig = this.spectrumDisplayService.getFrequencyRange(spectrumConfig, this.fftSize, this.sampleRate);

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
      legend.setEnabled(false); // 禁用图例，因为只有一根线，显示"频谱数据"标签是多余的
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

    // 创建分贝限制线（与频谱柱状图保持一致）
    this.createLimitLines();
    
    // 设置左Y轴信息 - 将标签移至内部
    this.leftAxis = this.model.getAxisLeft();
    if (this.leftAxis) {
      // 获取分贝步进值并设置正确的标签数量
      const dbSteps: number[] = this.spectrumDisplayService.getDecibelSteps(decibelRangeConfig.minDb, decibelRangeConfig.maxDb);
      this.leftAxis.setLabelCount(dbSteps.length, true); // 使用实际的分贝步进数量
      // 设置标签位置为内部
      this.leftAxis.setPosition(YAxisLabelPosition.INSIDE_CHART);
      // 设置距离顶部距离
      this.leftAxis.setSpaceTop(15);
      this.leftAxis.setSpaceBottom(15); // 为内部标签添加底部间距
      // 设置最小值和最大值，确保使用配置的分贝范围
      this.leftAxis.setAxisMinimum(decibelRangeConfig.minDb);
      this.leftAxis.setAxisMaximum(decibelRangeConfig.maxDb);
      this.leftAxis.setYOffset(-10)
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
      this.yAxisFormatter.setRange(decibelRangeConfig.minDb, decibelRangeConfig.maxDb);
      this.leftAxis.setValueFormatter(this.yAxisFormatter);
    }

    // 设置图表右Y轴信息
    this.rightAxis = this.model.getAxisRight();
    if (this.rightAxis) {
      this.rightAxis.setLabelCount(7, true);
      this.rightAxis.setDrawGridLines(false);
      this.rightAxis.setSpaceTop(15);
      this.rightAxis.setAxisMinimum(decibelRangeConfig.minDb);
      this.rightAxis.setAxisMaximum(decibelRangeConfig.maxDb);
      this.rightAxis.setEnabled(false);
    }
    
    // 设置X轴信息 - 将标签移至上方并添加刻度线
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

    this.model.setVisibleXRangeMaximum(20000); // 显示最大20kHz范围
    
    // 初始化数据
    const lineData: LineData = this.generateLineData();
    this.model.setData(lineData);
  }
  
  /**
   * 创建分贝限制线（与频谱柱状图保持一致）
   */
  private createLimitLines(): void {
    if (!this.leftAxis) return;
    
    // 清除之前的限制线
    this.leftAxis.removeAllLimitLines();
    
    // 添加统一样式的限制线
    for (const limitLineConfig of UnifiedChartStyle.LIMIT_LINES) {
      const limitLine = new LimitLine(limitLineConfig.value, limitLineConfig.label);
      limitLine.setLineWidth(UnifiedChartStyle.LINE_WIDTHS.normal);
      limitLine.enableDashedLine(5, 5, 0);
      limitLine.setLabelPosition(LimitLabelPosition.RIGHT_TOP);
      limitLine.setTextColor(parseInt(limitLineConfig.color.replace('#', '0xFF')));
      limitLine.setLineColor(parseInt(limitLineConfig.color.replace('#', '0xFF')));
      limitLine.setTextSize(UnifiedChartStyle.FONT_SIZES.value);
      
      this.leftAxis.addLimitLine(limitLine);
    }
  }

  aboutToAppear() {
    // Step1: 初始化图表配置构建类
    this.model = new LineChartModel();
    
    // Step2: 配置图表指定样式
    this.initChart();
  }

  build() {
    Column() {
      // LineChart组件
      if (this.model) {
        Stack() {
          LineChart({ model: this.model })
            .width('100%')
            .height('100%')
            .borderRadius(UnifiedChartStyle.BORDER_RADIUS.large) // 添加圆角，与其他图表保持一致
          
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
          
          // 峰值频率信息 - 根据设置决定是否显示
          if (this.spectrumDisplayService.getDisplayConfig(this.pk).showPeakFrequency) {

            // 根据峰值数量选择显示组件
            if (this.spectrumDisplayService.getDisplayConfig(this.pk).peakCount > 1) {
              // 多峰值显示
              MultiplePeakFrequencyDisplay({
                peakInfos: this.peakInfos,
                positionX: '86%',
                positionY: '15%'
              })
            } else {
              // 单峰值显示 - 直接使用处理后的峰值信息，不再进行额外平滑
              PeakFrequencyDisplay({
                peakInfo: this.peakInfo,
                positionX: '86%',
                positionY: '15%'
              })
            }
          }
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