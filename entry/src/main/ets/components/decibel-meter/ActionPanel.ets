import promptAction from '@ohos.promptAction';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { WeightingType } from '../../constants/WeightingConstants';
import { InputDialog } from './InputDialog';
import { PersistenceV2 } from '@kit.ArkUI';
import { camera } from '@kit.CameraKit';
import common from '@ohos.app.ability.common';

@ComponentV2
export struct ActionPanel {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local isTorchOn: boolean = false;
  @Param @Require weightingType: WeightingType;
  @Event onReset: () => void;
  @Event onSave: (comment: string) => void;

  aboutToAppear(): void {
  }

  build() {
    // 操作按钮 - 响应式布局
    Row({ space: 32 }) {
      // 重置按钮
      Button({ type: ButtonType.Circle }) {
        Image($r("app.media.solar_restart_circle_bold"))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.icon_secondary'))
      }
      .width(48)
      .height(48)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .accessibilityDescription('重置当前数据')
      .onClick(async () => {
        await this.onResetButtonClicked();
      })

      // 手电筒按钮
      Button({ type: ButtonType.Circle }) {
        Image($r("app.media.ic_flashlight_bold"))
          .width(24)
          .height(24)
          .fillColor(this.isTorchOn ? '#ffffffff' : $r('sys.color.icon_secondary'))
      }
      .width(48)
      .height(48)
      .backgroundColor(this.isTorchOn ? $r('sys.color.background_emphasize') :
      $r('sys.color.comp_background_primary'))
      .accessibilityDescription(this.isTorchOn ? '关闭手电筒' : '打开手电筒')
      .onClick(() => {
        this.toggleTorch();
      })

      // 保存按钮
      Button({ type: ButtonType.Circle }) {
        Image($r("app.media.solar_download_square_bold"))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.icon_secondary'))
      }
      .id('showNoiseDetailDialogFromActionPanels')
      .width(48)
      .height(48)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .accessibilityDescription('保存当前数据')
      .onClick(async () => {
        const dialogController = new CustomDialogController({
          builder: InputDialog({
            title: '保存记录',
            onConfirm: (comment: string) => {
              this.onSave(comment);
            },
            onClose: () => {
              dialogController.close();
            }
          }),
          cancel: () => {
            console.log('Dialog canceled');
          },
          autoCancel: true
        });
        dialogController.open();
      })
    }
    .width(224)
    .height(48)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(32)
    .margin({ bottom: 16 })
    .animation({ curve: Curve.EaseOut })
  }

  private async onResetButtonClicked() {
    const confirmed = await promptAction.showDialog({
      title: '确认重置',
      message: '确认要重置当前数据吗？此操作不可恢复。',
      buttons: [
        {
          text: '取消',
          color: $r('app.color.button_cancel')
        },
        {
          text: '确认',
          color: $r('app.color.button_warning')
        }
      ]
    });
    if (confirmed.index === 1) {
      this.onReset();
    }
  }

  // 新增方法：根据weightingType获取对应的索引
  getSelectedIndex(): number {
    switch (this.weightingType) {
      case WeightingType.A:
        return 0;
      case WeightingType.C:
        return 1;
      case WeightingType.Z:
        return 2;
      default:
        return 0;
    }
  }

  // 手电筒切换功能
  private toggleTorch() {
    let cameraManager: camera.CameraManager = camera.getCameraManager(getContext(this) as common.UIAbilityContext);
    if (cameraManager.isTorchSupported()) {
      cameraManager.setTorchMode(this.isTorchOn ? camera.TorchMode.OFF : camera.TorchMode.ON);
      this.isTorchOn = !this.isTorchOn;
    }
  }

}
