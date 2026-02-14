import common from '@ohos.app.ability.common'
import { ReportHeader } from '../../components/noise-dialogs/ReportHeader'
import { DataOverview } from '../../components/noise-dialogs/DataOverview'
import { BasicInfoV2 } from '../../components/noise-dialogs/BasicInfoV2'
import { HealthImpact } from '../../components/noise-dialogs/HealthImpact'
import { NoiseDistribution } from '../../components/noise-dialogs/NoiseDistribution'
import { NoiseChartV2 } from '../../components/noise-dialogs/NoiseChartV2'
import { ReportWatermark } from '../../components/noise-dialogs/ReportWatermark'
import { DecibelRecordService } from '../../services/DecibelRecordService'
import { DecibelRecord } from '../../models/DecibelRecord'
import { promptAction } from '@kit.ArkUI'
import { DesignConstants } from '../../constants/DesignConstants'

export interface DetailDialogParamsV2 {
  selectedRecord: DecibelRecord;
  context: common.Context;
}

/**
 * 噪音检测报告 V2
 */
@Builder
export function DetailDialogBuilderV2(param: DetailDialogParamsV2) {
  NavDestination() {
    if (param.selectedRecord) {
      Scroll() {
        Column({ space: DesignConstants.SPACING_LG }) {
          // 1. 报告头部（含综合评分和分享按钮）
          ReportHeader({
            selectedRecord: param.selectedRecord,
            context: param.context
          })

          // 2. 数据概览
          DataOverview({
            selectedRecord: param.selectedRecord
          })

          // 3. 噪音趋势图
          NoiseChartV2({
            selectedRecord: param.selectedRecord
          })

          // 4. 健康影响评估
          HealthImpact({
            selectedRecord: param.selectedRecord
          })

          // 5. 分布统计
          NoiseDistribution({
            selectedRecord: param.selectedRecord
          })

          // 6. 基本信息
          BasicInfoV2({
            selectedRecord: param.selectedRecord,
            commentChange: (comment: string) => updateComment(param.selectedRecord!, comment, param.context)
          })

          // 7. 水印（体现专业性 + 仅供参考）
          ReportWatermark({
            timestamp: param.selectedRecord.timestamp
          })

          // 底部安全间距
          Row().height(32)
        }
        .id('noiseReportContainer')
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .backgroundColor($r('sys.color.background_secondary'))
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
  }
  .hideTitleBar(true)  // 隐藏导航栏标题和关闭按钮
  .backgroundColor($r('sys.color.background_secondary'))
  .mode(NavDestinationMode.DIALOG)
}

// 更新备注
async function updateComment(record: DecibelRecord, comment: string, context: common.Context): Promise<void> {
  try {
    record.comment = comment;
    const service = new DecibelRecordService(context as common.UIAbilityContext);
    await service.updateRecord(record);
    promptAction.showToast({
      message: '备注已保存',
      duration: 1500
    });
  } catch (error) {
    console.error('保存备注失败:', error);
    promptAction.showToast({
      message: '保存失败',
      duration: 1500
    });
  }
}
