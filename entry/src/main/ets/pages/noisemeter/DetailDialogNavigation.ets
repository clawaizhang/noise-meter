import common from '@ohos.app.ability.common'
import hilog from '@ohos.hilog'
import { navigationStack } from '../../constants/ProviderConstant'
import { BasicInfo } from "../../components/noise-dialogs/BasicInfo"
import { Statistics } from "../../components/noise-dialogs/Statistics"
import { NoiseChart } from "../../components/noise-dialogs/NoiseChart"
import { DecibelRecordService } from "../../services/DecibelRecordService"
import { DecibelRecord } from '../../models/DecibelRecord'
import { FileService } from '../../services/FileService'
import { ScreenshotUtils } from '../../utils/ScreenshotUtils'
import { SymbolGlyphModifier } from '@kit.ArkUI'

const TAG = 'DetailDialog';
const DOMAIN = 0x0000;

export interface DetailDialogParams {
  selectedRecord: DecibelRecord;
  context: common.Context;
  fileService: FileService;
}

@ComponentV2
export struct DetailDialog {
  @BuilderParam param: DetailDialogParams
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  @Local selectedRecord: DecibelRecord | null = null;
  @Local context: common.Context | null = null;
  @Local fileService: FileService | null = null;
  private recordService: DecibelRecordService = new DecibelRecordService(getContext() as common.UIAbilityContext)

  async aboutToAppear() {
    try {
      const param = this.param;
      if (!param.selectedRecord || !param.context || !param.fileService) {
        hilog.error(DOMAIN, TAG, '导航参数缺少必要字段');
        return;
      }
      this.recordService.getRecordById(param.selectedRecord.id).then((record) => {
        this.selectedRecord = record
      })
      this.context = param.context;
      this.fileService = param.fileService;

      if (!this.context) {
        hilog.error(DOMAIN, TAG, 'Context is not available');
        return;
      }
      if (!this.fileService) {
        hilog.error(DOMAIN, TAG, 'FileService is not available');
        return;
      }

      hilog.info(DOMAIN, TAG, 'AudioPlayerService 初始化成功');

    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化失败: %{public}s', error instanceof Error ? error.message : String(error));
    }
  }

  build() {
    NavDestination() {
      if (this.selectedRecord) {
        // 内容区域 - 添加组件间距和响应式padding
        GridRow({
          columns: { sm: 1, md: 1 },
          breakpoints: { reference: BreakpointsReference.WindowSize },
          gutter: 16
        }) {
          GridCol({
            span: 1
          }) {
            BasicInfo({
              selectedRecord: this.selectedRecord, commentChange: (comment: string) => {
                this.selectedRecord!.comment = comment;
                this.recordService.updateRecord(this.selectedRecord!);
              }
            })
          }

          GridCol({
            span: 1
          }) {
            Statistics({ selectedRecord: this.selectedRecord })
          }

          GridCol({
            span: 1
          }) {
            NoiseChart({ playAudio: true, selectedRecord: this.selectedRecord })
          }
        }.id("detailDialogRoot")
      }
    }
    .title('噪音检测报告')
    .menus([{
      value: '分享',
      symbolIcon: new SymbolGlyphModifier($r("sys.symbol.share")),
      action: async () => {
        const context = getContext(this) as common.UIAbilityContext;
        const uiContext = this.getUIContext();
        try {
          const now = new Date();
          const timestamp = now.toISOString().replace(/[:.]/g, '-').slice(0, 19);
          await ScreenshotUtils.captureAndShare(
            context,
            uiContext,
            'detailDialogRoot',
            `noise_report_${timestamp}.jpg`,
            '噪音检测报告截图',
            '当前噪音检测报告详情截图'
          );
        } catch (error) {
          hilog.error(DOMAIN, TAG, '截图分享失败: %{public}s',
            error instanceof Error ? error.message : String(error));
        }
      }
    }])
    .padding(16)
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

@Builder
export function DetailDialogBuilder(params: DetailDialogParams) {
  DetailDialog({ param: params })
}
