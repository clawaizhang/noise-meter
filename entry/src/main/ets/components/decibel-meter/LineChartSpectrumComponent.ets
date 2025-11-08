import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AudioPresets } from '../../common/AudioConfig';
import { SpectrumDataProcessor, PeakInfo } from './SpectrumDataProcessor';
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
      // 使用公共模块查找峰值频率
      this.peakInfo = SpectrumDataProcessor.findPeakFrequency(
        this.currentSpectrumData,
        this.fftSize,
        this.sampleRate
      );
      // 更新图表数据
      this.updateChartData();
    }
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
    
    // 遍历所有FFT点，与原来的Canvas实现完全一致
    for (let i = 0; i < this.fftSize; i++) {
      const centerFreq: number = SpectrumDataProcessor.getIndexFrequency(i, this.fftSize, this.sampleRate);
      if (centerFreq < 16) {
        continue;
      } // 只显示16Hz以上的范围
      
      // 安全检查：确保currentSpectrumData存在且有效
      if (!this.currentSpectrumData || i >= this.currentSpectrumData.length) {
        continue;
      }
      
      // 频谱数据已经是分贝值，直接使用
      const dbValue: number = this.currentSpectrumData[i];
      
      // 确保分贝值在合理范围内
      const clampedDbValue: number = Math.max(dbSteps[0], Math.min(dbSteps[dbSteps.length - 1], dbValue));
      
      // 使用对数坐标映射，与原来的Canvas实现完全一致
      // 这样低频率部分会有更多的显示空间，高频率部分会被压缩
      const logFreq: number = Math.log10(centerFreq);
      const mappedX: number = ((logFreq - LOG_MIN_FREQ) / (logMaxFreq - LOG_MIN_FREQ)) * 20000;
      
      // 调试信息：只记录前几个数据点
      if (i < 5) {
        console.info(`[频谱图] 数据点${i}: 频率=${centerFreq}Hz, 映射X值=${mappedX}, 分贝=${clampedDbValue}dB`);
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
    this.model.setMaxVisibleValueCount(100);
    
    // 创建分贝限制线（与频谱柱状图保持一致）
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
      const dbSteps: number[] = SpectrumDataProcessor.getDbSteps();
      this.leftAxis.setAxisMinimum(dbSteps[0]);
      this.leftAxis.setAxisMaximum(dbSteps[dbSteps.length - 1]);
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
      const dbSteps: number[] = SpectrumDataProcessor.getDbSteps();
      this.rightAxis.setAxisMinimum(dbSteps[0]);
      this.rightAxis.setAxisMaximum(dbSteps[dbSteps.length - 1]);
      this.rightAxis.setEnabled(false);
    }
    
    // 设置X轴信息
    this.xAxis = this.model.getXAxis();
    if (this.xAxis) {
      this.xAxis.setPosition(XAxisPosition.BOTTOM);
      this.xAxis.setDrawGridLines(false);
      this.xAxis.setGranularity(1);
      this.xAxis.setLabelCount(10);
      this.xAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      this.xAxis.setTextSize(UnifiedChartStyle.FONT_SIZES.axis);
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
      // 图表标题
      Row() {
        Text('频谱分析')
          .fontSize(UnifiedChartStyle.FONT_SIZES.title)
          .fontWeight(FontWeight.Medium)
          .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
        
        Blank()
        
        // 显示峰值信息
        if (this.peakInfo && this.peakInfo.frequency > 0) {
          Text(`峰值: ${UnifiedChartStyle.formatFrequency(this.peakInfo.frequency)} (${UnifiedChartStyle.formatDecibel(this.peakInfo.dbValue)})`)
            .fontSize(UnifiedChartStyle.FONT_SIZES.value)
            .fontColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')))
            .backgroundColor(UnifiedChartStyle.BACKGROUND_COLOR)
            .padding({ left: UnifiedChartStyle.SPACING.sm, right: UnifiedChartStyle.SPACING.sm, top: 4, bottom: 4 })
            .borderRadius(UnifiedChartStyle.BORDER_RADIUS.small)
        }
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