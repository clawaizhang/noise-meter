import promptAction from '@ohos.promptAction';
import { PreferenceKeyConstants } from '../../constants/PreferenceKeyConstants';
import { WeightingType } from '../../constants/WeightingConstants';
import { PreferenceService, PreferenceValue } from '../../services/PreferenceService';
import { InputDialog } from './InputDialog';

@ComponentV2
export struct VerticalActionPanel {
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
    // 圆弧状按钮区域设计
    Column() {
      // 竖排按钮布局
      Column() {
        // 重置按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_reset'))
            .width(24)
            .height(24)
            .fillColor($r('app.color.text_secondary'))
        }
        .width(50)
        .height(50)
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
        .margin({ bottom: 12 })

        // 锁定按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_lock'))
            .width(24)
            .height(24)
            .fillColor(this.isUILocked ? $r('app.color.white') : $r('app.color.text_secondary'))
        }
        .width(50)
        .height(50)
        .enabled(this.meterOn)
        .backgroundColor(this.isUILocked ? $r('app.color.button_red') : $r('app.color.button_background'))
        .accessibilityDescription(this.isUILocked ? '解锁界面' : '锁定界面')
        .onClick(() => {
          this.lockToggle();
        })
        .margin({ bottom: 12 })

        // 频率选择器
        Select(this.weightingTypes)
          .width(50)
          .height(50)
          .backgroundColor($r('app.color.button_background'))
          .enabled(this.meterOn)
          .selected(this.getSelectedIndex())
          .value(this.weightingType)
          .accessibilityDescription('切换频率加权方式')
          .onSelect((index: number, value: string) => {
            this.onToggleWeighting(value as WeightingType);
          })
          .margin({ bottom: 12 })

        // 保存按钮
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.ic_save'))
            .width(24)
            .height(24)
            .fillColor($r('app.color.text_secondary'))
        }
        .width(50)
        .height(50)
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
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_tertiary'))
    .borderRadius(24)  // 更大的圆角实现圆弧效果
    .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
    .justifyContent(FlexAlign.Center)
    .padding({ top: 16, bottom: 16 })
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