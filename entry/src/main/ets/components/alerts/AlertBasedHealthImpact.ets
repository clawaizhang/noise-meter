/**
 * 基于警报数据的健康影响分析组件
 * 使用警报历史数据计算健康影响，而非实时测量数据
 */

import { AlertHistoryService } from '../../services/AlertHistoryService';
import { AlertSummary, AlertSeverity } from '../../models/AlertRecord';
import { DesignConstants } from '../../constants/DesignConstants';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'AlertBasedHealthImpact';
const DOMAIN = 0xFF00;

/**
 * 健康评估结果
 */
export interface HealthAssessment {
  level: 'safe' | 'low' | 'moderate' | 'high' | 'extreme';
  levelText: string;
  levelColor: string;
  icon: string;
  exposureMinutes: number;
  maxDecibel: number;
  alertCount: number;
  description: string;
  impacts: string[];
  recommendations: string[];
  energyDose: number; // 能量剂量（用于科学计算）
}

@ComponentV2
export struct AlertBasedHealthImpact {
  // 服务实例
  private alertHistoryService: AlertHistoryService = AlertHistoryService.getInstance();
  
  // 状态
  @Local private isLoading: boolean = true;
  @Local private assessment: HealthAssessment | null = null;
  @Local private alertSummary: AlertSummary | null = null;

  aboutToAppear(): void {
    this.loadAssessment();
  }

  /**
   * 加载健康评估数据
   */
  private async loadAssessment(): Promise<void> {
    this.isLoading = true;
    
    try {
      // 获取今日警报摘要
      const summary = await this.alertHistoryService.getTodaySummary();
      this.alertSummary = summary;
      
      // 计算健康评估
      this.assessment = this.calculateHealthAssessment(summary);
      
      hilog.info(DOMAIN, TAG, `健康评估完成`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, `加载健康评估失败`);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 计算健康评估
   * 
   * 使用能量累加公式计算暴露剂量：
   * Dose = Σ(10^(dB/10) * duration)
   * 
   * 参考标准：
   * - 安全：每日能量剂量 < 10^7.5 (约相当于 70dB 暴露 8小时)
   * - 低风险：能量剂量 10^7.5 ~ 10^8.0
   * - 中等风险：能量剂量 10^8.0 ~ 10^8.5
   * - 高风险：能量剂量 10^8.5 ~ 10^9.0
   * - 极高风险：能量剂量 > 10^9.0
   */
  private calculateHealthAssessment(summary: AlertSummary): HealthAssessment {
    const exposureMinutes = Math.floor(summary.todayDuration / 60);
    const maxDecibel = summary.peakDecibel;
    const alertCount = summary.todayCount;
    
    // 简化的能量剂量计算
    // 使用平均峰值和暴露时长的近似计算
    const avgDecibel = summary.avgDecibel || maxDecibel * 0.85; // 估算平均分贝
    const durationHours = summary.todayDuration / 3600;
    
    // 能量剂量计算：10^(dB/10) * hours
    const energyDose = Math.pow(10, avgDecibel / 10) * durationHours;
    
    // 根据能量剂量和健康标准确定风险等级
    let level: 'safe' | 'low' | 'moderate' | 'high' | 'extreme' = 'safe';
    let levelText = '安全';
    let levelColor = '#4CAF50';
    let icon = '✅';
    let description = '今日噪音暴露处于安全范围';
    let impacts: string[] = ['无明显健康影响'];
    let recommendations: string[] = ['保持良好习惯', '无需特殊防护'];
    
    if (energyDose > 1e9 || maxDecibel >= 100) {
      level = 'extreme';
      levelText = '极高风险';
      levelColor = '#9C27B0';
      icon = '☠️';
      description = `累计超标暴露 ${exposureMinutes} 分钟，可能对听力造成永久性损伤`;
      impacts = ['听力损伤风险极高', '心血管健康受影响', '可能造成永久性听力损失'];
      recommendations = ['立即停止暴露', '佩戴专业防护耳塞', '尽快就医检查听力'];
    } else if (energyDose > 3.16e8 || maxDecibel >= 90) {
      level = 'high';
      levelText = '高风险';
      levelColor = '#F44336';
      icon = '🚨';
      description = `累计超标暴露 ${exposureMinutes} 分钟，需要立即采取防护措施`;
      impacts = ['听力可能受损', '注意力难以集中', '可能导致头痛疲劳'];
      recommendations = ['佩戴耳塞防护', '减少暴露时间', '寻找安静环境'];
    } else if (energyDose > 1e8 || maxDecibel >= 85) {
      level = 'moderate';
      levelText = '中等风险';
      levelColor = '#FF9800';
      icon = '⚠️';
      description = `累计超标暴露 ${exposureMinutes} 分钟，建议采取防护措施`;
      impacts = ['可能影响睡眠', '工作效率可能下降', '长期可能影响健康'];
      recommendations = ['重要时段戴耳塞', '适当休息放松', '控制暴露时长'];
    } else if (energyDose > 3.16e7 || maxDecibel >= 80) {
      level = 'low';
      levelText = '低风险';
      levelColor = '#FFC107';
      icon = '💡';
      description = `累计超标暴露 ${exposureMinutes} 分钟，注意防护即可`;
      impacts = ['轻微不适感', '可能影响专注力'];
      recommendations = ['关注噪音变化', '适当休息', '必要时戴耳塞'];
    }

    return {
      level,
      levelText,
      levelColor,
      icon,
      exposureMinutes,
      maxDecibel,
      alertCount,
      description,
      impacts,
      recommendations,
      energyDose
    };
  }

  /**
   * 获取暴露进度百分比（相对于每日限额）
   */
  private getExposureProgress(): number {
    if (!this.assessment) {
      return 0;
    }
    // 参考 WHO 标准：85dB 8小时为 100% 限额
    // 简化为基于能量剂量的计算
    const maxDose = 3.16e8; // 85dB * 8h 约等于的能量剂量 (1e8.5 = 3.16e8)
    const percentage = (this.assessment.energyDose / maxDose) * 100;
    return Math.min(percentage, 100);
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      if (this.isLoading) {
        // 加载中
        Row({ space: DesignConstants.SPACING_MD }) {
          LoadingProgress()
            .width(24)
            .height(24)
          Text('计算中...')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .height(100)
        .justifyContent(FlexAlign.Center)
      } else if (!this.assessment || this.assessment.alertCount === 0) {
        // 无警报记录 - 安全状态
        this.buildSafeState()
      } else {
        // 有警报记录 - 显示评估
        this.buildAssessmentContent()
      }
    }
    .width('100%')
  }

  @Builder
  private buildSafeState() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 图标和标题
      Row({ space: DesignConstants.SPACING_MD }) {
        Text('✅')
          .fontSize(48)
        
        Column({ space: DesignConstants.SPACING_XS }) {
          Text('环境良好')
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
          Text('今日暂无超标警报')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor('#4CAF5015')
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)

      // 建议
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('保持建议')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .width('100%')

        this.buildRecommendationItem('继续保持当前环境');
        this.buildRecommendationItem('定期监测噪音变化');
        this.buildRecommendationItem('享受安静时光');
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    }
    .width('100%')
  }

  @Builder
  private buildAssessmentContent() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 评估卡片
      Column({ space: DesignConstants.SPACING_MD }) {
        // 图标和等级
        Row({ space: DesignConstants.SPACING_MD }) {
          Text(this.assessment!.icon)
            .fontSize(48)
          
          Column({ space: DesignConstants.SPACING_XS }) {
            Text(this.assessment!.levelText)
              .fontSize(DesignConstants.FONT_SIZE_XL)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.assessment!.levelColor)
            Text(this.assessment!.description)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')

        // 暴露进度条（如果有超标暴露）
        if (this.assessment!.exposureMinutes > 0) {
          Column({ space: DesignConstants.SPACING_XS }) {
            Row() {
              Text('暴露限额使用')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.font_secondary'))
              
              Blank()
              
              Text(`${this.getExposureProgress().toFixed(0)}%`)
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor(this.assessment!.levelColor)
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')

            // 进度条
            Stack({ alignContent: Alignment.Start }) {
              Row()
                .width('100%')
                .height(8)
                .backgroundColor($r('sys.color.comp_divider'))
                .borderRadius(DesignConstants.BORDER_RADIUS_FULL)

              Row()
                .width(`${this.getExposureProgress()}%`)
                .height(8)
                .backgroundColor(this.assessment!.levelColor)
                .borderRadius(DesignConstants.BORDER_RADIUS_FULL)
            }
            .width('100%')
            .height(8)
          }
          .width('100%')
          .margin({ top: DesignConstants.SPACING_SM })
        }

        // 统计数据
        Row() {
          this.buildStatItem('超标次数', `${this.assessment!.alertCount}次`);
          this.buildStatItem('累计时长', `${this.assessment!.exposureMinutes}分`);
          this.buildStatItem('最高峰值', `${this.assessment!.maxDecibel.toFixed(0)}dB`);
        }
        .width('100%')
        .margin({ top: DesignConstants.SPACING_SM })
      }
      .width('100%')
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor(this.assessment!.levelColor + '15') // 15% 透明度
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)

      // 健康影响
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('可能影响')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .width('100%')

        ForEach(this.assessment!.impacts, (impact: string) => {
          this.buildImpactItem(impact);
        })
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)

      // 建议措施
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('建议措施')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .width('100%')

        ForEach(this.assessment!.recommendations, (rec: string) => {
          this.buildRecommendationItem(rec);
        })
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    }
    .width('100%')
  }

  @Builder
  private buildStatItem(label: string, value: string) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(value)
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
      Text(label)
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_secondary'))
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildImpactItem(text: string) {
    Row({ space: DesignConstants.SPACING_SM }) {
      Circle()
        .width(6)
        .height(6)
        .fill(this.assessment?.levelColor || '#999999')
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
