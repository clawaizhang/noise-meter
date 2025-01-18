import { DecibelRecord } from "../../models/DecibelRecord"
import common from '@ohos.app.ability.common'
import { FileService } from "../../services/FileService"
import hilog from '@ohos.hilog'
import { noiseMeterNavStack } from '../../../../noise_meter/ets/constant/ProviderConstant'
import { JSON } from '@kit.ArkTS'
import { ScreenshotUtils } from "../../utils/ScreenshotUtils"
import { DialogTitleBuilder } from "./DialogTitle"
import { BasicInfoBuilder } from "./BasicInfo"
import { Statistics } from "./Statistics"
import { NoiseChart } from "./NoiseChart"

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

      this.selectedRecord = param.selectedRecord;
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
              .backgroundColor('#DDDDDD')
          }
          .width('100%')
          .height(20)
          .justifyContent(FlexAlign.Center)

          Column() {
            if (this.selectedRecord) {
              DialogTitleBuilder(this.selectedRecord, () => {
                this.navStack.pop();
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
                BasicInfoBuilder(this.selectedRecord)
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
        .backgroundColor(Color.White)
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
                this.navStack.pop();
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
    .backgroundColor(`rgba(0,0,0,${this.bgOpacity})`)
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
      this.navStack.pop();
      animateTo({ duration: 1200, curve: Curve.EaseIn }, () => {
        this.translateY = 1000;
      });
      animateTo({ duration: 600, curve: Curve.EaseIn }, () => {
        this.bgOpacity = 0;
      });
      return true;
    })
  }
}

@Builder
export function DetailDialogBuilder() {
  DetailDialog()
}
