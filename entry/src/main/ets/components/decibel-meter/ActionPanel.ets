import promptAction from '@ohos.promptAction';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { WeightingType } from '../../constants/WeightingConstants';
import { InputDialog } from './InputDialog';
import { LengthMetrics, PersistenceV2 } from '@kit.ArkUI';
import { camera } from '@kit.CameraKit';
import common from '@ohos.app.ability.common';

@ComponentV2
export struct ActionPanel {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local isTorchOn: boolean = false;
  @Param @Require weightingType: WeightingType;
  @Event onReset: () => void;
  @Event onSave: (comment: string) => void;
  private weightingTypes: Array<SelectOption> =
    [{ value: WeightingType.A }, { value: WeightingType.C }, { value: WeightingType.Z }];

  aboutToAppear(): void {
  }

  build() {
    // 操作按钮
    Flex({
      wrap: FlexWrap.Wrap,
      justifyContent: FlexAlign.SpaceEvenly,
      alignContent: FlexAlign.Center,
      alignItems: ItemAlign.Center,
      space: { main: LengthMetrics.vp(8), cross: LengthMetrics.vp(8) }
    }) {
      // 重置按钮
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_reset'))
          .width(20)
          .height(20).fillColor($r('sys.color.icon_secondary'))

      }
      .width(40)
      .height(40)
      .backgroundColor($r('sys.color.comp_background_secondary'))

      .accessibilityDescription('重置当前数据')
      .onClick(async () => {
        await this.onResetButtonClicked();
      })

      Button({ type: ButtonType.Circle }) {
        Image($r('sys.media.light_flashlight_on_fill'))
          .width(20)
          .height(20).fillColor(this.isTorchOn ? '#ffffffff' :$r('sys.color.icon_secondary'))

      }
      .width(40)
      .height(40)
      .backgroundColor(this.isTorchOn ? $r('sys.color.background_emphasize') : $r('sys.color.comp_background_secondary'))

      .accessibilityDescription(this.isTorchOn ? '解锁界面' : '锁定界面')
      .onClick(() => {
        this.toggleTorch();
      })

      // 保存按钮
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_save'))
          .width(20)
          .height(20).fillColor($r('sys.color.icon_secondary'))

      }
      .id('showNoiseDetailDialogFromActionPanels')
      .width(40)
      .height(40)
      .backgroundColor($r('sys.color.comp_background_secondary'))
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
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(12)
    .padding(8)
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
      promptAction.showToast({ message: '手电筒已' + (this.isTorchOn ? '关闭' : '打开') });
      this.isTorchOn = !this.isTorchOn;
    }
  }

  // 频率加权方式切换功能
  private onToggleWeighting(weightingType: WeightingType) {
    this.pk.weighting_type = weightingType;
    // 弹出提示框显示当前频率加权方式
    promptAction.showToast({
      message: `已切换为: ${weightingType} 计权`,
      duration: 2000
    });
  }
}
