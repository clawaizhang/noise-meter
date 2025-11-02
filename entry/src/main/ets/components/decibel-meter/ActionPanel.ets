import promptAction from '@ohos.promptAction';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { WeightingType } from '../../constants/WeightingConstants';
import { InputDialog } from './InputDialog';
import { ColorMetrics, LengthMetrics, PersistenceV2 } from '@kit.ArkUI';
import { camera } from '@kit.CameraKit';
import common from '@ohos.app.ability.common';
import { ActionBarButton, ActionBarStyle, HdsActionBar } from '@kit.UIDesignKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { Throttle } from '../../utils/Debounce';

@ComponentV2
export struct ActionPanel {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local isTorchOn: boolean = false;
  @Local isExpand: boolean = true;
  @Local isPrimaryIconChanged: boolean = false;
  @Param @Require weightingType: WeightingType;
  @Event onReset: () => void;
  @Event onSave: (comment: string) => void;

  aboutToAppear(): void {
  }

  build() {
    // 简单版本检测：大于60000用HdsActionBar，否则用旧的
    if (deviceInfo.distributionOSApiVersion >= 60000) {
      // 高版本：使用HdsActionBar
      this.buildHdsActionBar()
    } else {
      // 低版本：保持原有布局
      this.buildOriginalPanel()
    }
  }

  @Builder
  buildHdsActionBar() {
    // 高版本设备：使用HdsActionBar
    HdsActionBar({
      startButtons: [
        new ActionBarButton({
          baseIcon: $r('app.media.solar_restart_circle_bold'),
          iconSize: LengthMetrics.vp(24),
          width: LengthMetrics.vp(48),
          backgroundColor: ColorMetrics.resourceColor($r('sys.color.comp_background_primary')),
          hoverTips: '重置当前数据',
          accessibilityText: '重置按钮',
          accessibilityDescription: '重置当前数据',
          onClick: () => {
            Throttle.click(() => {
              this.onResetButtonClicked();
            })
          }
        }),
        // 手电筒功能已移动到工具Tab，这里不再显示
        new ActionBarButton({
          baseIcon: $r('app.media.solar_download_square_bold'),
          iconSize: LengthMetrics.vp(24),
          width: LengthMetrics.vp(48),
          backgroundColor: ColorMetrics.resourceColor($r('sys.color.comp_background_primary')),
          hoverTips: '保存当前数据',
          accessibilityText: '保存按钮',
          accessibilityDescription: '保存当前噪音数据',
          onClick: () => {
            Throttle.click(() => {
              this.onSaveButtonClicked();
            })
          }
        })
      ],
      actionBarStyle: new ActionBarStyle({
        height: LengthMetrics.vp(48),
        backgroundBlurStyle: BlurStyle.COMPONENT_ULTRA_THIN,
        startSpace: LengthMetrics.vp(0),
        endSpace: LengthMetrics.vp(0),
        innerSpace: LengthMetrics.vp(32),
        isHorizontal: true,
        isPrimaryIconChanged: this.isPrimaryIconChanged
      }),
      isExpand: this.isExpand
    }).margin({ bottom: -8 })
  }

  @Builder
  buildOriginalPanel() {
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
      .onClick(() => {
        Throttle.click(() => {
          this.onResetButtonClicked();
        });
      })

      // 手电筒功能已移动到工具Tab，这里不再显示

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
      .onClick(() => {
        Throttle.click(() => {
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
        });
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

  private onSaveButtonClicked() {
    const dialogController = new CustomDialogController({
      builder: InputDialog({
        title: '保存记录',
        onConfirm: (comment: string) => {
          this.onSave(comment);
          // 保存成功后提供视觉反馈
          this.isPrimaryIconChanged = true;
          setTimeout(() => {
            this.isPrimaryIconChanged = false;
          }, 2000);
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

  // 手电筒功能已移动到工具Tab，这里不再提供
}
