import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AudioPresets } from '../../common/AudioConfig';
import { SpectrumDataProcessor, PeakInfo, PeakInterpolationMethod } from './SpectrumDataProcessor';
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
  LegendForm,
  IAxisValueFormatter,
  AxisBase,
} from '@ohos/mpchart';

@ComponentV2
export struct LineChartSpectrumComponent {
  // 输入参数
  @Param sampleRate: number = 44100
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys) ?? new PreferenceKeys();

  // 依赖注入
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys) ?? new AppKeys()

  // 频谱数据
  @Local private currentSpectrumData: Float32Array = new Float32Array();
  @Local private peakInfo: PeakInfo | null = null;
  
  // 峰值平滑处理相关
  @Local private smoothedPeakInfo: PeakInfo | null = null;
  @Local private lastPeakUpdateTime: number = 0;
  @Local private readonly PEAK_UPDATE_THRESHOLD_MS: number = 200; // 峰值更新最小间隔(ms)
  @Local private readonly PEAK_CHANGE_THRESHOLD_DB: number = 2.0; // 峰值变化阈值(dB)
  @Local private readonly PEAK_CHANGE_THRESHOLD_HZ: number = 100; // 峰值频率变化阈值(Hz)

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
      console.info(`[频谱图] 选中数据点: x=${e.getX()}, y=${e.getY()}`);
    },
    onNothingSelected: () => {
      // 处理取消选择事件
      console.info(`[频谱图] 取消选择`);
    }
  }

  @Monitor('ak.uiDisplayState.displaySpectrumData')
  onSpectrumDataChange(monitor: IMonitor) {
    const newSpectrum = monitor.value<Float32Array>()?.now;
    if (newSpectrum && this.ak.isDisplayApp) {
      this.currentSpectrumData = newSpectrum;
      // 使用改进的峰值检测方法（默认启用抛物线插值）
      this.peakInfo = SpectrumDataProcessor.findPeakFrequency(
        this.currentSpectrumData,
        this.fftSize,
        this.sampleRate,
        SpectrumDataProcessor.MIN_FREQUENCY,
        SpectrumDataProcessor.MAX_FREQUENCY,
        true, // 默认启用插值
        PeakInterpolationMethod.PARABOLIC // 默认使用抛物线插值
      );
      
      // 应用峰值平滑处理
      this.applyPeakSmoothing();
      
      // 更新图表数据
      this.updateChartData();
    }
  }

  /**
   * 应用峰值平滑处理
   * 减少峰值显示的抖动，提高用户体验
   */
  private applyPeakSmoothing(): void {
    if (!this.peakInfo) {
      return;
    }

    const currentTime = Date.now();
    
    // 如果是第一次检测到峰值，直接使用
    if (!this.smoothedPeakInfo) {
      this.smoothedPeakInfo = {
        frequency: this.peakInfo.frequency,
        dbValue: this.peakInfo.dbValue,
        index: this.peakInfo.index,
        amplitude: this.peakInfo.amplitude
      };
      this.lastPeakUpdateTime = currentTime;
      return;
    }

    // 检查是否满足时间间隔要求
    if (currentTime - this.lastPeakUpdateTime < this.PEAK_UPDATE_THRESHOLD_MS) {
      return; // 时间间隔太短，不更新
    }

    // 检查峰值变化是否超过阈值
    const dbChange = Math.abs(this.peakInfo.dbValue - this.smoothedPeakInfo.dbValue);
    const freqChange = Math.abs(this.peakInfo.frequency - this.smoothedPeakInfo.frequency);

    if (dbChange < this.PEAK_CHANGE_THRESHOLD_DB && freqChange < this.PEAK_CHANGE_THRESHOLD_HZ) {
      return; // 变化太小，不更新
    }

    // 应用平滑算法：加权平均
    const smoothingFactor = 0.15; // 平滑因子，越小越平滑
    this.smoothedPeakInfo = {
      frequency: smoothingFactor * this.peakInfo.frequency + (1 - smoothingFactor) * this.smoothedPeakInfo.frequency,
      dbValue: smoothingFactor * this.peakInfo.dbValue + (1 - smoothingFactor) * this.smoothedPeakInfo.dbValue,
      index: this.peakInfo.index,
      amplitude: smoothingFactor * this.peakInfo.amplitude + (1 - smoothingFactor) * this.smoothedPeakInfo.amplitude
    };
    
    this.lastPeakUpdateTime = currentTime;
  }

  /**
   * 更新图表数据
   */
  private updateChartData(): void {
    if (!this.model || this.currentSpectrumData.length === 0) {
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
   */
  private generateLineData(): LineData {
    const values: JArrayList<EntryOhos> = new JArrayList<EntryOhos>();
    
    // 获取频率步进和分贝步进
    const dbSteps: number[] = SpectrumDataProcessor.getDbSteps();
    const frequencySteps: number[] = SpectrumDataProcessor.getFrequencySteps();
    
    // 与原来的Canvas实现保持一致：使用对数坐标映射
    const LOG_MIN_FREQ = Math.log10(16); // 16Hz
    const logMaxFreq = Math.log10(20000); // 20kHz
    
    // 使用SpectrumDataProcessor生成增强的频谱数据点（包含低频插值）
    const enhancedDataPoints = SpectrumDataProcessor.generateEnhancedSpectrumData(
      this.currentSpectrumData,
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
    this.dataSet.setLineWidth(UnifiedChartStyle.LINE_WIDTHS.normal); // 使用统一样式线宽
    
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
    }

    // 设置图表右Y轴信息
    this.rightAxis = this.model.getAxisRight();
    if (this.rightAxis) {
      this.rightAxis.setLabelCount(7, true);
      this.rightAxis.setDrawGridLines(false);
      this.rightAxis.setSpaceTop(15);
      const dbSteps: number[] = SpectrumDataProcessor.getDbSteps();
      this.rightAxis.setAxisMinimum(dbSteps[0]);
      this.rightAxis.setAxisMaximum(dbSteps[dbSteps.length - 1]);
      this.rightAxis.setEnabled(false);
    }
    
    // 设置X轴信息 - 将标签移至上方并添加刻度线
    this.xAxis = this.model.getXAxis();
    if (this.xAxis) {
      this.xAxis.setPosition(XAxisPosition.TOP); // 将标签移至上方
      this.xAxis.setDrawGridLines(true); // 启用水平网格线作为刻度线
      this.xAxis.setDrawAxisLine(true); // 绘制轴线
      this.xAxis.setGranularity(1);
      this.xAxis.setLabelCount(10);
      this.xAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      this.xAxis.setTextSize(UnifiedChartStyle.FONT_SIZES.axis);
      this.xAxis.setYOffset(10); // 正偏移，使标签显示在图表上方
      this.xAxis.setAvoidFirstLastClipping(true); // 避免首尾标签被裁剪
      // 设置图表X轴显示范围，与映射后的X值保持一致
      // 由于跳过了16Hz以下的数据，所以最小值应该对应16Hz的映射值
      const LOG_MIN_FREQ = Math.log10(16);
      const logMaxFreq = Math.log10(20000);
      
      // 直接设置范围，因为16Hz映射到0，20kHz映射到20000
      this.xAxis.setAxisMinimum(0);     // 16Hz对应的映射值
      this.xAxis.setAxisMaximum(20000);  // 20kHz对应的映射值
      
      // 自定义X轴标签，按照对数坐标显示频率
      // 创建一个符合IAxisValueFormatter接口的对象
      const formatter: IAxisValueFormatter = {
        getFormattedValue: (value: number, axis: AxisBase): string => {
          // 将映射后的X值转换回频率
          const LOG_MIN_FREQ = Math.log10(16);
          const logMaxFreq = Math.log10(20000);
          const logFreq = LOG_MIN_FREQ + (value / 20000) * (logMaxFreq - LOG_MIN_FREQ);
          const frequency = Math.pow(10, logFreq);
          
          // 调试信息：验证映射是否正确
          console.info(`[频谱图] X轴值: ${value}, 对应频率: ${frequency}Hz`);
          
          // 使用统一样式格式化频率显示
          return UnifiedChartStyle.formatFrequency(frequency);
        }
      };
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
            .position({ x: '95%', y: '2%' })
            .translate({ x: '-50%' })
            .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
            .padding({ left: 4, right: 4 })
            .borderRadius(4)
          
          // Y轴单位标签
          Text('声级(dB)')
            .fontSize(UnifiedChartStyle.FONT_SIZES.axis)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .position({ x: '2%', y: '6%' })
            .translate({ y: '-50%' })
            .rotate({ angle: -90 })
            .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
            .padding({ left: 4, right: 4 })
            .borderRadius(4)
          
          // 峰值频率信息 - 使用通用组件
          PeakFrequencyDisplay({
            peakInfo: this.smoothedPeakInfo,
            positionX: '95%',
            positionY: '8%'
          })
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