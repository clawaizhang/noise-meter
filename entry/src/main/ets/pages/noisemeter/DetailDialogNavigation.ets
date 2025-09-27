import common from '@ohos.app.ability.common'
import { BasicInfo } from "../../components/noise-dialogs/BasicInfo"
import { Statistics } from "../../components/noise-dialogs/Statistics"
import { NoiseChart } from "../../components/noise-dialogs/NoiseChart"
import { DecibelRecordService } from "../../services/DecibelRecordService"
import { DecibelRecord } from '../../models/DecibelRecord'
import { FileService } from '../../services/FileService'

export interface DetailDialogParams {
  selectedRecord: DecibelRecord;
  context: common.Context;
  fileService: FileService;
}

@Builder
export function DetailDialogBuilder(param: DetailDialogParams) {
  NavDestination() {
    if (param.selectedRecord) {
      // 内容区域 - 添加组件间距和响应式padding
      Scroll() {
        GridRow({
          columns: { sm: 1, md: 1 },
          breakpoints: { reference: BreakpointsReference.WindowSize },
          gutter: 16
        }) {
          GridCol({
            span: 1
          }) {
            BasicInfo({
              selectedRecord: param.selectedRecord, commentChange: (comment: string) => {
                param.selectedRecord!.comment = comment;
                new DecibelRecordService(getContext() as common.UIAbilityContext).updateRecord(param.selectedRecord!);
              }
            })
          }

          GridCol({
            span: 1
          }) {
            Statistics({ selectedRecord: param.selectedRecord })
          }

          GridCol({
            span: 1
          }) {
            NoiseChart({ playAudio: true, selectedRecord: param.selectedRecord })
          }
        }.id("detailDialogRoot").backgroundColor($r('sys.color.background_secondary'))
      }.scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
    }
  }
  .title('噪音检测报告')
  .padding(16)
  .backgroundColor($r('sys.color.background_secondary'))
}
