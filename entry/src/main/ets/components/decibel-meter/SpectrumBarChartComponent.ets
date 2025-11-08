import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { BaseChartComponent } from '../common/charts/BaseChartComponent';
import { ChartConfig, ChartType, DefaultChartConfig } from '../common/charts/ChartConfig';
import { AudioPresets } from '../../common/AudioConfig';
import { SpectrumDataProcessor, SpectrumDataPoint, PeakInfo } from './SpectrumDataProcessor';
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

    // 是否绘制图表的背景色，绘制范围为图表瀑布图的绘制范围，不包含轴线之外的部分
    this.model.setDrawGridBackground(true);
    // 设置图表的背景色，颜色的规格需要满足CanvasRenderingContext2D.fillstyle/strokestyle规格
    this.model.setGridBackgroundColor(DefaultChartConfig.backgroundColor);
    // 设置不绘制瀑布图的柱体阴影背景
    this.model.setDrawBarShadow(false);

    // 设置瀑布图的数值在柱体上方
    this.model.setDrawValueAboveBar(false);

    // 创建分贝限制线
    this.createLimitLines();

    // 设置图表左Y轴信息
    this.leftAxis = this.model.getAxisLeft();
    if (this.leftAxis) {
      this.leftAxis.setAxisMinimum(0);
      this.leftAxis.setAxisMaximum(120);
      this.leftAxis.setDrawLimitLinesBehindData(false);
      this.leftAxis.setDrawGridLines(true);
      this.leftAxis.setDrawAxisLine(true);
      this.leftAxis.setDrawLabels(true);
      this.leftAxis.setTextColor(DefaultChartConfig.textColor);
      this.leftAxis.setTextSize(DefaultChartConfig.fontSize.axis);
      this.leftAxis.setLabelCount(7, true); // 设置Y轴标签数量
      this.leftAxis.setAxisLineWidth(1.5);
      this.leftAxis.setAxisLineColor(parseInt(DefaultChartConfig.textColor.replace('#', '0xFF')));

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

    // 设置X轴信息
    this.xAxis = this.model.getXAxis();
    if (this.xAxis) {
      this.xAxis.setPosition(XAxisPosition.BOTTOM);
      this.xAxis.setDrawGridLines(false);
      this.xAxis.setDrawAxisLine(true);
      this.xAxis.setDrawLabels(true);
      this.xAxis.setTextColor(DefaultChartConfig.textColor);
      this.xAxis.setTextSize(DefaultChartConfig.fontSize.axis);
      this.xAxis.setLabelCount(Math.min(this.frequencyLabels.length, 8), true);
      this.xAxis.setGranularity(1);
      this.xAxis.setAxisLineWidth(1.5);
      this.xAxis.setAxisLineColor(parseInt(DefaultChartConfig.textColor.replace('#', '0xFF')));
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
   * 创建分贝限制线
   */
  private createLimitLines(): void {
    this.limitLines = [];

    // 安全级别 (50dB)
    const safeLine = new LimitLine(50, '安全');
    safeLine.setLineWidth(2);
    safeLine.enableDashedLine(5, 5, 0);
    safeLine.setLabelPosition(LimitLabelPosition.RIGHT_TOP);
    safeLine.setTextColor('#FF00FF00');
    safeLine.setLineColor('#FF00FF00');
    safeLine.setTextSize(10);
    this.limitLines.push(safeLine);

    // 注意级别 (70dB)
    const cautionLine = new LimitLine(70, '注意');
    cautionLine.setLineWidth(2);
    cautionLine.enableDashedLine(5, 5, 0);
    cautionLine.setLabelPosition(LimitLabelPosition.RIGHT_TOP);
    cautionLine.setTextColor('#FFFFFF00');
    cautionLine.setLineColor('#FFFFFF00');
    cautionLine.setTextSize(10);
    this.limitLines.push(cautionLine);

    // 危险级别 (85dB)
    const dangerLine = new LimitLine(85, '危险');
    dangerLine.setLineWidth(2);
    dangerLine.enableDashedLine(5, 5, 0);
    dangerLine.setLabelPosition(LimitLabelPosition.RIGHT_TOP);
    dangerLine.setTextColor('#FFFF8800');
    dangerLine.setLineColor('#FFFF8800');
    dangerLine.setTextSize(10);
    this.limitLines.push(dangerLine);

    // 极限级别 (110dB)
    const extremeLine = new LimitLine(110, '极限');
    extremeLine.setLineWidth(2);
    extremeLine.enableDashedLine(5, 5, 0);
    extremeLine.setLabelPosition(LimitLabelPosition.RIGHT_TOP);
    extremeLine.setTextColor('#FFFF0000');
    extremeLine.setLineColor('#FFFF0000');
    extremeLine.setTextSize(10);
    this.limitLines.push(extremeLine);
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
      const dataPoints = this.displayDataPoints;
      // 使用对数分布的索引，更好地匹配人耳听觉特性
      const indices = SpectrumDataProcessor.generateLogarithmicIndices(dataPoints, this.fftSize);

      for (let i = 0; i < dataPoints; i++) {
        const dataIndex = indices[i];
        if (dataIndex < sourceData.length) {
          // 频谱数据已经是分贝值，直接使用
          const dbValue = SpectrumDataProcessor.getDbValue(sourceData[dataIndex]);
          // 创建柱状图条目，使用频率索引作为X值，分贝值作为Y值范围
          const entry = new WaterfallEntry(i, 0, dbValue);

          // 根据分贝值设置颜色
          const color = SpectrumDataProcessor.getDbColor(dbValue);
          // 注意：这里需要根据MPChart库的实际API来设置颜色
          // 如果库支持单独设置每个柱子的颜色，可以在这里设置

          values.add(entry);
        }
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
    this.data = this.generateSpectrumBarData();

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

  build() {
    Column() {
      // 标题和信息栏
      Row() {
        Column() {
          Text('频谱柱状图')
            .fontSize(DefaultChartConfig.fontSize.title)
            .fontColor(DefaultChartConfig.textColor)
            .fontWeight(FontWeight.Medium)

          Text(`采样率: ${this.sampleRate}Hz | FFT: ${this.fftSize} | 模式: ${this.pk.audio_analysis_mode}`)
            .fontSize(DefaultChartConfig.fontSize.small)
            .fontColor(DefaultChartConfig.textColor)
            .opacity(0.8)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Column() {
          if (this.peakFrequency > 0) {
            Text(`峰值频率`)
              .fontSize(DefaultChartConfig.fontSize.small)
              .fontColor(DefaultChartConfig.textColor)
              .opacity(0.8)
            Text(`${this.formatFrequency(this.peakFrequency)}`)
              .fontSize(DefaultChartConfig.fontSize.label)
              .fontColor(SpectrumDataProcessor.getDbColor(this.peakDb))
              .fontWeight(FontWeight.Bold)
            Text(`${this.peakDb.toFixed(1)}dB`)
              .fontSize(DefaultChartConfig.fontSize.small)
              .fontColor(SpectrumDataProcessor.getDbColor(this.peakDb))
          }
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      // 频段指示器
      Row() {
        ForEach(this.FREQUENCY_BANDS, (band: FrequencyRange, index: number) => {
          Row() {
            Text(band.label)
              .fontSize(DefaultChartConfig.fontSize.small)
              .fontColor(DefaultChartConfig.textColor)
            Text(`${this.formatFrequency(band.startFreq)}-${this.formatFrequency(band.endFreq)}`)
              .fontSize(DefaultChartConfig.fontSize.small)
              .fontColor(DefaultChartConfig.textColor)
              .opacity(0.8)
          }
          .padding(8)
          .backgroundColor('#2A2B2D') // 深色背景，与整体风格一致
          .borderRadius(8)
          .margin({ right: 8 })
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

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
          .position({ x: '95%', y: '98%' })
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
      }
      .width('100%')
      .layoutWeight(1)
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