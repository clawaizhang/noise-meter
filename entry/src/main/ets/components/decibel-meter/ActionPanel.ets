import promptAction from '@ohos.promptAction';
import { PreferenceKeyConstants } from '../../constants/PreferenceKeyConstants';
import { WeightingType } from '../../constants/WeightingConstants';
import { PreferenceService, PreferenceValue } from '../../services/PreferenceService';
import { InputDialog } from './InputDialog';

@ComponentV2
export struct ActionPanel {
  @Param isUILocked: boolean = false;
  @Param @Require weightingType: WeightingType;
  @Event onReset: () => void;
  @Event onSave: (comment: string) => void;
  @Event lockToggle: () => void;
  @Event onToggleWeighting: (weightingType: WeightingType) => void;
  @Local meterOn: boolean = false;
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  private weightingTypes: Array<SelectOption> =
    [{ value: WeightingType.A }, { value: WeightingType.C }, { value: WeightingType.Z }];

  aboutToAppear(): void {
    this.meterOn = this.preferenceService.getBoolean(PreferenceKeyConstants.METER_ON, true);
    this.preferenceService.addChangeListener(PreferenceKeyConstants.METER_ON, (key: string, value: PreferenceValue) => {
      if (key === PreferenceKeyConstants.METER_ON && typeof value === 'boolean') {
        this.meterOn = value;
      }
    })
  }

  build() {
    Column() {
      // 操作按钮
      Row() {
        // 重置按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_reset'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.text_secondary'))
        }
        .width(40)
        .height(40)
        .enabled(this.meterOn)
        .backgroundColor($r('app.color.button_background'))
        .accessibilityDescription('重置当前数据')
        .onClick(async () => {
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
        })

        // 锁定按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_lock'))
            .width(20)
            .height(20)
            .fillColor(this.isUILocked ? $r('app.color.white') : $r('app.color.text_secondary'))
        }
        .width(40)
        .height(40)
        .enabled(this.meterOn)
        .backgroundColor(this.isUILocked ? $r('app.color.button_red') : $r('app.color.button_background'))
        .accessibilityDescription(this.isUILocked ? '解锁界面' : '锁定界面')
        .onClick(() => {
          this.lockToggle();
        })

        // 新增：切换频率加权方式选择框
        Select(this.weightingTypes)
          .width(40)
          .height(40)
          .backgroundColor($r('app.color.button_background'))
          .enabled(this.meterOn)
          .selected(this.getSelectedIndex())
          .value(this.weightingType)
          .accessibilityDescription('切换频率加权方式')
          .onSelect((index: number, value: string) => {
            this.onToggleWeighting(value as WeightingType);
          })

        // 保存按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_save'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.text_secondary'))
        }
        .width(40)
        .height(40)
        .enabled(this.meterOn)
        .backgroundColor($r('app.color.button_background'))
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
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({
        left: 24,
        right: 24,
        top: 8,
        bottom: 8
      })
    }
    .width('100%')
    .backgroundColor($r('app.color.background_tertiary'))
    .borderRadius(12)
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
    .margin({ top: 8 })
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
}
