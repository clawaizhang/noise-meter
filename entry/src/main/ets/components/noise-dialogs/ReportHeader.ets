import { DecibelRecord } from '../../models/DecibelRecord';
import { DecibelService } from '../../services/DecibelService';
import { DesignConstants } from '../../constants/DesignConstants';
import { promptAction } from '@kit.ArkUI';
import { ScreenshotUtils } from '../../utils/ScreenshotUtils';
import common from '@ohos.app.ability.common';

/**
 * 报告头部组件
 * 包含综合评分、报告编号、检测时间等元信息
 */
@ComponentV2
export struct ReportHeader {
  @Param selectedRecord: DecibelRecord | null = null;
  @Param context: common.Context | null = null;

  // 计算综合评分 (0-100)
  @Computed
  get overallScore(): number {
    if (!this.selectedRecord) return 0;
    const avg = this.selectedRecord.avgDecibel;
    const score = Math.max(0, Math.min(100, Math.round(100 - (avg - 30) * (100 / 60))));
    return score;
  }

  @Computed
  get scoreGrade(): string {
    const score = this.overallScore;
    if (score >= 80) return '优秀';
    if (score >= 60) return '良好';
    if (score >= 40) return '一般';
    if (score >= 20) return '较差';
    return '危险';
  }

  @Computed
  get scoreColor(): Resource {
    const score = this.overallScore;
    if (score >= 80) return $r('app.color.health_good');
    if (score >= 60) return $r('app.color.decibel_quiet');
    if (score >= 40) return $r('app.color.decibel_normal');
    if (score >= 20) return $r('app.color.decibel_noisy');
    return $r('app.color.health_bad');
  }

  private formatReportId(timestamp: number): string {
    const date = new Date(timestamp);
    return `R${date.getFullYear().toString().slice(2)}${String(date.getMonth() + 1).padStart(2, '0')}${String(date.getDate()).padStart(2, '0')}${String(date.getHours()).padStart(2, '0')}${String(date.getMinutes()).padStart(2, '0')}`;
  }

  // 分享报告 - 截图并调用系统分享
  private async shareReport(): Promise<void> {
    console.info('[ReportHeader] 分享按钮被点击');
    
    if (!this.selectedRecord) {
      console.error('[ReportHeader] selectedRecord 为空');
      promptAction.showToast({ message: '分享失败：数据为空', duration: 2000 });
      return;
    }

    if (!this.context) {
      console.error('[ReportHeader] context 为空');
      promptAction.showToast({ message: '分享失败：上下文为空', duration: 2000 });
      return;
    }

    try {
      const score = this.overallScore;
      const grade = this.scoreGrade;
      
      promptAction.showToast({
        message: '正在生成报告截图...',
        duration: 1500
      });

      // 获取 UIContext - 使用组件的 getUIContext 方法
      const uiContext = this.getUIContext();
      const uiAbilityContext = this.context as common.UIAbilityContext;
                       
      if (!uiContext) {
        console.error('[ReportHeader] 无法获取 UIContext');
        promptAction.showToast({ message: '分享失败：无法获取UI上下文', duration: 2000 });
        return;
      }
      
      console.info('[ReportHeader] UIContext 获取成功，开始调用截图');

      // 延迟确保组件已完全渲染
      await new Promise<void>(resolve => setTimeout(resolve, 500));

      // 调用截图分享
      await ScreenshotUtils.captureAndShare(
        uiAbilityContext,
        uiContext,
        'noiseReportContainer',
        `noise_report_${this.selectedRecord.timestamp}.jpg`,
        '噪音检测报告',
        `综合评分${score}分(${grade})，平均${this.selectedRecord.avgDecibel.toFixed(1)}dB`
      );
      
      console.info('[ReportHeader] 分享成功');
    } catch (error) {
      console.error('[ReportHeader] 分享失败:', error);
      const errorMessage = error instanceof Error ? error.message : '未知错误';
      promptAction.showToast({
        message: `分享失败：${errorMessage}`,
        duration: 3000
      });
    }
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题和分享按钮放在同一行
      Row() {
        Row({ space: DesignConstants.SPACING_SM }) {
          Image($r('app.media.ic_audio_analysis'))
            .width(DesignConstants.ICON_SIZE_MD)
            .height(DesignConstants.ICON_SIZE_MD)
            .fillColor($r('sys.color.brand'))
          Text('噪音检测报告')
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
        }

        Blank()

        // 分享按钮
        Button() {
          Image($r('app.media.ic_share'))
            .width(DesignConstants.ICON_SIZE_SM)
            .height(DesignConstants.ICON_SIZE_SM)
            .fillColor($r('sys.color.font_secondary'))
        }
        .width(36)
        .height(36)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(18)
        .onClick(() => this.shareReport())
      }
      .width('100%')

      // 综合评分卡片
      Row({ space: DesignConstants.SPACING_LG }) {
        // 左侧：大分数
        Column({ space: DesignConstants.SPACING_SM }) {
          Text('综合评分')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_tertiary'))
          
          Text(`${this.overallScore}`)
            .fontSize(56)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.scoreColor)
            .height(56)
          
          Text(this.scoreGrade)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.scoreColor)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor($r('sys.color.comp_background_secondary'))
            .borderRadius(4)
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width(90)

        // 分隔线
        Column()
          .width(1)
          .height(80)
          .backgroundColor($r('sys.color.comp_background_secondary'))

        // 右侧：报告信息
        Column({ space: DesignConstants.SPACING_SM }) {
          // 报告编号
          Row({ space: DesignConstants.SPACING_SM }) {
            Text('编号')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_tertiary'))
              .width(40)
            Text(this.formatReportId(this.selectedRecord!.timestamp))
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
          }
          .width('100%')

          // 检测时间
          Row({ space: DesignConstants.SPACING_SM }) {
            Text('时间')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_tertiary'))
              .width(40)
            Text(this.formatDateTime(this.selectedRecord!.timestamp))
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .layoutWeight(1)
          }
          .width('100%')

          // 检测时长
          Row({ space: DesignConstants.SPACING_SM }) {
            Text('时长')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_tertiary'))
              .width(40)
            Text(`${this.formatDuration(this.selectedRecord!.duration)}`)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
          }
          .width('100%')

          // 计权类型
          if (this.selectedRecord!.weightingTypes?.length > 0) {
            Row({ space: DesignConstants.SPACING_SM }) {
              Text('计权')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.font_tertiary'))
                .width(40)
              Text(Array.from(new Set(this.selectedRecord!.weightingTypes)).join('/'))
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.brand'))
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .shadow(DesignConstants.SHADOW_SM)
    }
    .width('100%')
  }

  private formatDateTime(timestamp: number): string {
    const date = new Date(timestamp);
    return `${date.getFullYear()}/${date.getMonth() + 1}/${date.getDate()} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
  }

  private formatDuration(seconds: number): string {
    if (seconds < 60) {
      return `${seconds}秒`;
    } else {
      const mins = Math.floor(seconds / 60);
      const secs = seconds % 60;
      return secs > 0 ? `${mins}分${secs}秒` : `${mins}分钟`;
    }
  }
}
