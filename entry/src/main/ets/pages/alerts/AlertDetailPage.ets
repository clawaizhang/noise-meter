/**
 * 警报详情页
 * 展示单个警报记录的详细信息和趋势图
 */

import { AlertHistoryService, DecibelSample } from '../../services/AlertHistoryService';
import { AlertRecord, AlertSeverity } from '../../models/AlertRecord';
import { DesignConstants } from '../../constants/DesignConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';
import { router } from '@kit.ArkUI';
import {
  LineChart,
  LineChartModel,
  LineData,
  LineDataSet,
  EntryOhos,
  JArrayList,
  XAxisPosition,
  YAxis,
  YAxisLabelPosition,
  LimitLine,
  LimitLabelPosition,
  Mode
} from '@ohos/mpchart';
import { UnifiedChartStyle } from '../../components/common/charts/UnifiedChartStyle';

const TAG = 'AlertDetailPage';
const DOMAIN = 0xFF00;

/**
 * 警报详情页参数
 */
export interface AlertDetailPageParams {
  alertId: string;
}

/**
 * 分布范围接口
 */
interface DistributionRange {
  min: number;
  max: number;
  label: string;
}

/**
 * 分布项接口
 */
interface DistributionItem {
  range: string;
  count: number;
  percentage: number;
}

/**
 * 风险信息接口
 */
interface RiskInfo {
  text: string;
  color: string;
  icon: string;
}

@Builder
export function AlertDetailPageBuilder(params: AlertDetailPageParams) {
  AlertDetailPage({ alertId: params.alertId })
}

@ComponentV2
struct AlertDetailPage {
  @Param alertId: string = '';
  
  // 服务实例
  private alertHistoryService: AlertHistoryService = AlertHistoryService.getInstance();
  
  // 页面状态
  @Local private isLoading: boolean = true;
  @Local private record: AlertRecord | null = null;
  @Local private samples: DecibelSample[] = [];
  
  // 图表模型
  @Local private lineChartModel: LineChartModel = new LineChartModel();
  @Local private lineData: LineData = new LineData();

  aboutToAppear(): void {
    console.info(`[AlertDetailPage] 页面加载，警报ID: ${this.alertId}`);
    this.loadData();
  }

  /**
   * 加载数据
   */
  private async loadData(): Promise<void> {
    this.isLoading = true;
    
    try {
      // 加载警报记录
      this.record = await this.alertHistoryService.getAlertRecordById(this.alertId);
      
      if (this.record) {
        // 加载采样数据
        this.samples = await this.alertHistoryService.getAlertSamples(this.alertId);
        console.info(`[AlertDetailPage] 加载 ${this.samples.length} 个采样点`);
        
        // 初始化图表
        this.initializeChart();
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `加载数据失败: ${JSON.stringify(error)}`);
      promptAction.showToast({ message: '加载失败' });
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 初始化图表
   */
  private initializeChart(): void {
    if (this.samples.length === 0) {
      return;
    }

    // 配置图表基本属性
    this.lineChartModel.setDrawGridBackground(false);
    this.lineChartModel.setDrawBorders(false);
    
    // 禁用交互
    this.lineChartModel.setTouchEnabled(false);
    this.lineChartModel.setDragEnabled(false);
    this.lineChartModel.setScaleEnabled(false);
    this.lineChartModel.setPinchZoom(false);

    // 配置X轴
    const xAxis = this.lineChartModel.getXAxis();
    if (xAxis) {
      xAxis.setPosition(XAxisPosition.BOTTOM);
      xAxis.setDrawGridLines(false);
      xAxis.setDrawAxisLine(true);
      xAxis.setGranularity(1);
      xAxis.setLabelCount(5, true);
      xAxis.setTextSize(10);
      xAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      xAxis.setValueFormatter({
        getFormattedValue: (value: number): string => {
          const index = Math.round(value);
          if (index >= 0 && index < this.samples.length) {
            const timestamp = this.samples[index].timestamp;
            const date = new Date(timestamp);
            const mins = date.getMinutes().toString().padStart(2, '0');
            const secs = date.getSeconds().toString().padStart(2, '0');
            return `${mins}:${secs}`;
          }
          return '';
        }
      });
    }

    // 配置Y轴
    const leftAxis = this.lineChartModel.getAxisLeft();
    if (leftAxis) {
      leftAxis.setDrawGridLines(true);
      leftAxis.setGridColor(parseInt(UnifiedChartStyle.GRID_COLOR.replace('#', '0xFF')));
      leftAxis.setTextSize(10);
      leftAxis.setTextColor(parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF')));
      leftAxis.setAxisMinimum(this.record?.minDecibel ? this.record.minDecibel - 5 : 30);
      leftAxis.setAxisMaximum(this.record?.peakDecibel ? this.record.peakDecibel + 5 : 100);
      
      // 添加阈值线
      if (this.record?.threshold) {
        const limitLine = new LimitLine(this.record.threshold, '阈值');
        limitLine.setLineColor(0xFFFF9800); // 橙色
        limitLine.setLineWidth(2);
        limitLine.setTextColor(0xFFFF9800);
        limitLine.setTextSize(10);
        limitLine.setLabelPosition(LimitLabelPosition.RIGHT_TOP);
        leftAxis.addLimitLine(limitLine);
      }
    }

    const rightAxis = this.lineChartModel.getAxisRight();
    if (rightAxis) {
      rightAxis.setEnabled(false);
    }

    // 隐藏图例和描述
    const legend = this.lineChartModel.getLegend();
    if (legend) {
      legend.setEnabled(false);
    }
    const description = this.lineChartModel.getDescription();
    if (description) {
      description.setEnabled(false);
    }

    // 更新图表数据
    this.updateChartData();
  }

  /**
   * 更新图表数据
   */
  private updateChartData(): void {
    if (this.samples.length === 0) {
      return;
    }

    const entries: JArrayList<EntryOhos> = new JArrayList<EntryOhos>();
    for (let i = 0; i < this.samples.length; i++) {
      entries.add(new EntryOhos(i, this.samples[i].decibel));
    }

    const dataSet = new LineDataSet(entries, '分贝趋势');
    
    // 配置线条样式
    const severityColor = this.getSeverityColorHex(this.record?.severity ?? AlertSeverity.LOW);
    dataSet.setColorByColor(severityColor);
    dataSet.setLineWidth(2);
    dataSet.setDrawCircles(false);
    dataSet.setDrawValues(false);
    dataSet.setMode(Mode.LINEAR);
    
    // 填充渐变
    dataSet.setDrawFilled(true);
    dataSet.setFillColor(severityColor);
    dataSet.setFillAlpha(30);

    this.lineData.clearValues();
    this.lineData.addDataSet(dataSet);
    this.lineChartModel.setData(this.lineData);
    this.lineChartModel.invalidate();
  }

  /**
   * 获取严重程度颜色（十六进制）
   */
  private getSeverityColorHex(severity: AlertSeverity): number {
    switch (severity) {
      case AlertSeverity.LOW:
        return 0xFF4CAF50; // 绿色
      case AlertSeverity.MEDIUM:
        return 0xFFFF9800; // 橙色
      case AlertSeverity.HIGH:
      case AlertSeverity.CRITICAL:
        return 0xFFF44336; // 红色
      default:
        return 0xFF999999;
    }
  }

  /**
   * 格式化时间
   */
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
  }

  /**
   * 格式化日期
   */
  private formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    
    if (date.toDateString() === today.toDateString()) {
      return '今天';
    } else if (date.toDateString() === yesterday.toDateString()) {
      return '昨天';
    } else {
      return `${date.getMonth() + 1}月${date.getDate()}日`;
    }
  }

  /**
   * 计算分贝分布
   */
  private calculateDistribution(): DistributionItem[] {
    if (this.samples.length === 0) {
      return [];
    }

    const ranges: DistributionRange[] = [
      { min: 0, max: 60, label: '<60dB' },
      { min: 60, max: 70, label: '60-70dB' },
      { min: 70, max: 80, label: '70-80dB' },
      { min: 80, max: 90, label: '80-90dB' },
      { min: 90, max: 999, label: '>90dB' }
    ];

    const distribution: DistributionItem[] = ranges.map((range: DistributionRange): DistributionItem => ({
      range: range.label,
      count: 0,
      percentage: 0
    }));

    for (const sample of this.samples) {
      for (let i = 0; i < ranges.length; i++) {
        if (sample.decibel >= ranges[i].min && sample.decibel < ranges[i].max) {
          distribution[i].count++;
          break;
        }
      }
    }

    for (const item of distribution) {
      item.percentage = Math.round((item.count / this.samples.length) * 100);
    }

    return distribution.filter(item => item.count > 0);
  }

  build() {
    Column({ space: 0 }) {
      // 顶部导航栏
      this.buildHeader()

      if (this.isLoading) {
        // 加载中
        Column({ space: DesignConstants.SPACING_MD }) {
          LoadingProgress()
            .width(48)
            .height(48)
          Text('加载中...')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (!this.record) {
        // 空状态
        Column({ space: DesignConstants.SPACING_MD }) {
          Text('⚠️')
            .fontSize(48)
          Text('记录不存在')
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 内容区域
        Scroll() {
          Column({ space: DesignConstants.SPACING_LG }) {
            // 基本信息卡片
            this.buildInfoCard()

            // 趋势图
            if (this.samples.length > 0) {
              this.buildTrendChart()
            }

            // 统计分布
            if (this.samples.length > 0) {
              this.buildDistributionContent(this.calculateDistribution())
            }

            // 健康影响
            this.buildHealthImpactContent(
              this.calculateRiskInfo(
                this.record?.peakDecibel ?? 0,
                this.record?.avgDecibel ?? 0,
                this.record?.duration ?? 0
              ),
              this.record?.duration ?? 0,
              this.record?.peakDecibel ?? 0,
              this.record?.avgDecibel ?? 0
            )
          }
          .width('100%')
          .padding(DesignConstants.SPACING_LG)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
  }

  @Builder
  private buildHeader() {
    Row() {
      // 返回按钮
      Button() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.font_primary'))
      }
      .type(ButtonType.Circle)
      .backgroundColor('transparent')
      .width(44)
      .height(44)
      .onClick(() => {
        router.back();
      })

      // 标题
      Text('警报详情')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .layoutWeight(1)

      // 占位
      Blank()
        .width(44)
    }
    .width('100%')
    .height(56)
    .padding({ left: DesignConstants.SPACING_SM, right: DesignConstants.SPACING_SM })
  }

  @Builder
  private buildInfoCard() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 时间和严重程度
      Row() {
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(`${this.formatDate(this.record!.startTime)} ${this.formatTime(this.record!.startTime)}`)
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
          Text(`持续 ${this.record!.getFormattedDuration}`)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)

        // 严重程度标签
        Row({ space: DesignConstants.SPACING_XS }) {
          Circle()
            .width(8)
            .height(8)
            .fill(AlertRecord.getSeverityColor(this.record!.severity))
          Text(AlertRecord.getSeverityText(this.record!.severity))
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor(AlertRecord.getSeverityColor(this.record!.severity))
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: DesignConstants.SPACING_MD, right: DesignConstants.SPACING_MD })
        .height(32)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_FULL)
      }
      .width('100%')

      Divider()
        .strokeWidth(1)
        .color($r('sys.color.comp_divider'))

      // 数据网格
      Row() {
        this.buildDataItem('峰值', `${this.record!.peakDecibel.toFixed(0)}`, 'dB')
        this.buildDataItem('平均', `${this.record!.avgDecibel.toFixed(0)}`, 'dB')
        this.buildDataItem('最低', `${this.record!.minDecibel.toFixed(0)}`, 'dB')
        this.buildDataItem('阈值', `${this.record!.threshold.toFixed(0)}`, 'dB')
      }
      .width('100%')

      // 位置信息
      if (this.record!.location) {
        Row({ space: DesignConstants.SPACING_XS }) {
          Image($r('app.media.ic_location'))
            .width(16)
            .height(16)
            .fillColor($r('sys.color.font_tertiary'))
          Text(this.record!.location)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_tertiary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  @Builder
  private buildDataItem(label: string, value: string, unit: string) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
      Row({ space: 2 }) {
        Text(label)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
        Text(`(${unit})`)
          .fontSize(10)
          .fontColor($r('sys.color.font_tertiary'))
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildTrendChart() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_stats'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.brand'))
        Text('分贝变化趋势')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
        Text(`${this.samples.length} 个采样点`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .width('100%')

      // 图表
      LineChart({
        model: this.lineChartModel
      })
        .width('100%')
        .height(200)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  @Builder
  private buildDistributionContent(distribution: DistributionItem[]) {
    // 标题
    Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_stats'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.brand'))
        Text('分贝分布')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
      }
      .width('100%')

      // 分布条
      Column({ space: DesignConstants.SPACING_SM }) {
        ForEach(distribution, (item: DistributionItem) => {
          Row({ space: DesignConstants.SPACING_SM }) {
            Text(item.range)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .width(70)

            Stack({ alignContent: Alignment.Start }) {
              Row()
                .width('100%')
                .height(8)
                .backgroundColor($r('sys.color.comp_divider'))
                .borderRadius(DesignConstants.BORDER_RADIUS_FULL)

              Row()
                .width(`${item.percentage}%`)
                .height(8)
                .backgroundColor(this.getDistributionColor(item.range))
                .borderRadius(DesignConstants.BORDER_RADIUS_FULL)
            }
            .layoutWeight(1)
            .height(8)

            Text(`${item.count}次`)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .width(50)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        })
      }
      .width('100%')
    }


  /**
   * 获取分布颜色
   */
  private getDistributionColor(range: string): Resource {
    if (range.includes('>90') || range.includes('80-90')) {
      return $r('sys.color.alert');
    } else if (range.includes('70-80')) {
      return $r('sys.color.warning');
    }
    return $r('sys.color.confirm');
  }

  private calculateRiskInfo(maxDb: number, avgDb: number, duration: number): RiskInfo {
    // 计算风险等级
    let riskLevel: 'low' | 'moderate' | 'high' | 'extreme' = 'low';
    if (maxDb >= 90 || avgDb >= 80) {
      riskLevel = 'extreme';
    } else if (maxDb >= 80 || avgDb >= 70) {
      riskLevel = 'high';
    } else if (maxDb >= 70 || avgDb >= 60) {
      riskLevel = 'moderate';
    }

    // 获取风险信息
    if (riskLevel === 'low') {
      return { text: '低风险', color: '#4CAF50', icon: '✅' };
    } else if (riskLevel === 'moderate') {
      return { text: '中等风险', color: '#FF9800', icon: '⚠️' };
    } else if (riskLevel === 'high') {
      return { text: '高风险', color: '#F44336', icon: '🚨' };
    } else {
      return { text: '极高风险', color: '#9C27B0', icon: '☠️' };
    }
  }

  @Builder
  private buildHealthImpactContent(risk: RiskInfo, duration: number, maxDb: number, avgDb: number) {
    // 标题
    Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_smile'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.brand'))
        Text('健康影响评估')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
      }
      .width('100%')

      // 风险等级
      Row({ space: DesignConstants.SPACING_MD }) {
        Text(risk.icon)
          .fontSize(40)
        
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(risk.text)
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor(risk.color)
          Text(`本次暴露持续 ${Math.floor(duration / 60)}分${duration % 60}秒`)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor(risk.color + '15') // 15% 透明度
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)

      // 影响和建议
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('可能影响')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .width('100%')

        if (maxDb >= 90) {
          this.buildImpactItem('可能损伤听力', $r('sys.color.alert'));
          this.buildImpactItem('影响心血管健康', $r('sys.color.alert'));
        } else if (maxDb >= 80) {
          this.buildImpactItem('可能暂时影响听力', $r('sys.color.warning'));
          this.buildImpactItem('可能引起头痛疲劳', $r('sys.color.warning'));
        } else if (maxDb >= 70) {
          this.buildImpactItem('可能影响睡眠', $r('sys.color.warning'));
          this.buildImpactItem('可能影响注意力', $r('sys.color.warning'));
        } else {
          this.buildImpactItem('环境噪音良好', $r('sys.color.confirm'));
          this.buildImpactItem('对健康无明显影响', $r('sys.color.confirm'));
        }
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)

      // 建议
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('建议措施')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .width('100%')

        if (maxDb >= 90) {
          this.buildRecommendationItem('立即佩戴耳塞');
          this.buildRecommendationItem('尽快离开该环境');
        } else if (maxDb >= 80) {
          this.buildRecommendationItem('建议佩戴耳塞');
          this.buildRecommendationItem('控制停留时间');
        } else if (avgDb >= 70) {
          this.buildRecommendationItem('重要时段关闭门窗');
          this.buildRecommendationItem('使用白噪音助眠');
        } else if (avgDb >= 60) {
          this.buildRecommendationItem('安静时段做重要工作');
          this.buildRecommendationItem('适当休息放松');
        } else {
          this.buildRecommendationItem('环境适宜，无需防护');
          this.buildRecommendationItem('保持良好习惯');
        }
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    }

  @Builder
  private buildImpactItem(text: string, color: Resource) {
    Row({ space: DesignConstants.SPACING_SM }) {
      Circle()
        .width(6)
        .height(6)
        .fill(color)
      Text(text)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .layoutWeight(1)
    }
    .width('100%')
  }

  @Builder
  private buildRecommendationItem(text: string) {
    Row({ space: DesignConstants.SPACING_SM }) {
      Image($r('app.media.ic_save'))
        .width(16)
        .height(16)
        .fillColor($r('app.color.health_good'))
      Text(text)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: DesignConstants.SPACING_XS, bottom: DesignConstants.SPACING_XS })
  }
}
