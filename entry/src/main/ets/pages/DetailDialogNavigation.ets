import common from '@ohos.app.ability.common'
import hilog from '@ohos.hilog'
import { noiseMeterNavStack } from '../constants/ProviderConstant'
import { JSON } from '@kit.ArkTS'
import { DialogTitleBuilder } from "../components/noise-dialogs/DialogTitle"
import { BasicInfo } from "../components/noise-dialogs/BasicInfo"
import { Statistics } from "../components/noise-dialogs/Statistics"
import { NoiseChart } from "../components/noise-dialogs/NoiseChart"
import { DecibelRecordService } from "../services/DecibelRecordService"
import emitter from '@ohos.events.emitter'
import { DecibelRecord } from '../models/DecibelRecord'
import { FileService } from '../services/FileService'
import { ScreenshotUtils } from '../utils/ScreenshotUtils'

const DETAIL_DIALOG_CLOSED_EVENT = 100101

const TAG = 'DetailDialog';
const DOMAIN = 0x0000;

export interface DetailDialogParams {
  selectedRecord: DecibelRecord;
  context: common.Context;
  fileService: FileService;
}

@ComponentV2
export struct DetailDialog {
  @Consumer(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack();
  @Local selectedRecord: DecibelRecord | null = null;
  @Local context: common.Context | null = null;
  @Local fileService: FileService | null = null;
  @Local translateY: number = 1000;
  private startY: number = 0;
  @Local private bgOpacity: number = 0;
  private recordService: DecibelRecordService = new DecibelRecordService(getContext() as common.UIAbilityContext)

  async aboutToAppear() {
    try {
      this.bgOpacity = 0;
      const params = JSON.parse(JSON.stringify(this.navStack.getParamByName('DetailDialog'))) as DetailDialogParams[];

      if (!params || typeof params !== 'object') {
        hilog.error(DOMAIN, TAG, '导航参数无效');
        return;
      }
      const param = params[0];

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

      animateTo({ duration: 800, curve: Curve.Smooth }, () => {
        this.translateY = 0;
        setTimeout(() => {
          animateTo({ duration: 400, curve: Curve.EaseIn }, () => {
            this.bgOpacity = 0.3;
          });
        }, 400);
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化失败: %{public}s', error instanceof Error ? error.message : String(error));
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Row() {
            Row()
              .width(40)
              .height(4)
              .borderRadius(2)
              .backgroundColor($r('app.color.dark_text_secondary'))
          }
          .width('100%')
          .height(20)
          .justifyContent(FlexAlign.Center)

          Column() {
            if (this.selectedRecord) {
              DialogTitleBuilder(this.selectedRecord, () => {
                this.closeDialog();
              }, async () => {
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
              })

              Column() {
                BasicInfo({  selectedRecord: this.selectedRecord,commentChange: (comment: string) => {
                  this.selectedRecord!.comment = comment;
                  this.recordService.updateRecord(this.selectedRecord!);
                }})
                Statistics({ selectedRecord: this.selectedRecord })
                NoiseChart({ playAudio: true, selectedRecord: this.selectedRecord })
              }
              .width('100%')
              .padding({ left: 16, right: 16, bottom: 16 })
            }
          }
          .width('100%')
        }
        .id("detailDialogRoot")
        .width('100%')
        .backgroundColor($r('app.color.dark_background_primary'))
        .borderRadius({ topLeft: 16, topRight: 16 })
        .translate({ y: this.translateY })
        .gesture(
          PanGesture({ direction: PanDirection.Vertical })
            .onActionStart((event: GestureEvent) => {
              this.startY = event.offsetY;
            })
            .onActionUpdate((event: GestureEvent) => {
              const deltaY = event.offsetY - this.startY;
              if (deltaY > 0) {
                this.translateY = deltaY;
                this.bgOpacity = Math.max(0, 0.3 * (1 - deltaY / 250));
              }
            })
            .onActionEnd(() => {
              if (this.translateY > 100) {
                this.closeDialog();
                animateTo({ duration: 1200, curve: Curve.EaseIn }, () => {
                  this.translateY = 1000;
                });
              } else {
                animateTo({ duration: 800, curve: Curve.Smooth }, () => {
                  this.translateY = 0;
                  this.bgOpacity = 0.3;
                });
              }
            })
        )
        .animation({
          duration: 800,
          curve: Curve.Smooth
        })
      }
      .height('100%')
      .width('100%')
    }
    .backgroundColor($r('app.color.dark_background_primary'))
    .animation({
      duration: 400,
      curve: Curve.EaseOut,
      iterations: 1,
      playMode: PlayMode.Normal
    })
    .hideTitleBar(true)
    .mode(NavDestinationMode.DIALOG)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onBackPressed(() => {
      this.closeDialog()
      animateTo({ duration: 1200, curve: Curve.EaseIn }, () => {
        this.translateY = 1000;
      });
      animateTo({ duration: 600, curve: Curve.EaseIn }, () => {
        this.bgOpacity = 0;
      });
      return true;
    })
  }

  private closeDialog() {
    if (this.selectedRecord) {
      const eventData: emitter.EventData = {
        data: {
          id: this.selectedRecord.id
        }
      };
      emitter.emit({
        eventId: DETAIL_DIALOG_CLOSED_EVENT
      }, eventData);
    }
    this.navStack.pop();
  }
}

@Builder
export function DetailDialogBuilder() {
  DetailDialog()
}
