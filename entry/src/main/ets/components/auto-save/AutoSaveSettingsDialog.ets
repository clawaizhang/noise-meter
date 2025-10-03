import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2 } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import { DesignConstants } from '../../constants/DesignConstants';

export interface AutoSaveDialogParams {
  onClose: () => void;
}

@ComponentV2
export struct AutoSaveSettingsDialog {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local autoSaveEnabled: boolean = this.pk.auto_save_enabled;
  @Local interval: number = this.pk.auto_save_interval;
  @Local selectedPreset: number = this.getPresetIndex(this.interval);
  @Local customInterval: number = this.interval;
  @Param @Require params: AutoSaveDialogParams;

  private getPresetIndex(interval: number): number {
    switch (interval) {
      case 3: return 0;
      case 5: return 1;
      case 10: return 2;
      case 20: return 3;
      default: return -1; // 自定义模式
    }
  }

  private getPresetInterval(index: number): number {
    switch (index) {
      case 0: return 3;
      case 1: return 5;
      case 2: return 10;
      case 3: return 20;
      default: return this.customInterval;
    }
  }

  private handlePresetSelect(index: number) {
    this.selectedPreset = index;
    this.interval = this.getPresetInterval(index);
    if (index !== -1) {
      this.customInterval = this.interval;
    }
  }

  private handleCustomInput(value: string) {
    const numValue = parseInt(value);
    if (!isNaN(numValue) && numValue >= 1 && numValue <= 60) {
      this.customInterval = numValue;
      this.interval = numValue;
      this.selectedPreset = -1; // 切换到自定义模式
    }
  }

  private handleConfirm() {
    this.pk.auto_save_enabled = this.autoSaveEnabled;
    this.pk.auto_save_interval = this.interval;
    
    promptAction.showToast({
      message: this.autoSaveEnabled ? `自动保存已启用：每${this.interval}分钟保存` : '自动保存已禁用',
      duration: 2000
    });
    
    this.params.onClose();
  }

  private handleCancel() {
    this.params.onClose();
  }

  @Builder
  private buildPresetOption(index: number, label: string, description: string) {

    Column({ space: 4 }) {
      Text(label)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.selectedPreset === index ? $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))
      
      Text(description)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor(this.selectedPreset === index ? $r('sys.color.font_on_primary') : $r('sys.color.font_secondary'))
    }
    .width('100%')
    .height(72)
    .backgroundColor(this.selectedPreset === index ? $r('sys.color.interactive_active') : $r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .padding(DesignConstants.SPACING_MD)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.handlePresetSelect(index);
    })
  }

  @Builder
  private buildCustomInput() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('自定义间隔：')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
        
        TextInput({ text: this.customInterval.toString() })
          .width(80)
          .height(40)
          .type(InputType.Number)
          .enterKeyType(EnterKeyType.Done)
          .onChange((value: string) => {
            this.handleCustomInput(value);
          })
        
        Text('分钟')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
      }
      
      Text('（1-60分钟）')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 开关区域
      Row({ space: 8 }) {
        Text('启用自动保存')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
        
        Toggle({ type: ToggleType.Switch, isOn: this.autoSaveEnabled })
          .selectedColor($r('app.color.toggle_active'))
          .switchPointColor($r('app.color.background_primary'))
          .onChange((isOn: boolean) => {
            this.autoSaveEnabled = isOn;
          })
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)

      if (this.autoSaveEnabled) {
        // 预设选项区域
        GridRow({ columns: 2, gutter: 12 }) {
          GridCol({ span: 1 }) {
            this.buildPresetOption(0, '3分钟', '工业监测')
          }
          GridCol({ span: 1 }) {
            this.buildPresetOption(1, '5分钟', '综合应用')
          }
          GridCol({ span: 1 }) {
            this.buildPresetOption(2, '10分钟', '社区投诉')
          }
          GridCol({ span: 1 }) {
            this.buildPresetOption(3, '20分钟', '健康监测')
          }
        }
        .width('100%')

        // 自定义输入区域
        this.buildCustomInput()
      }

      // 按钮区域
      Row({ space: 12 }) {
        Button('取消', { type: ButtonType.Normal })
          .layoutWeight(1)
          .height(48)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            this.handleCancel();
          })

        Button('确认', { type: ButtonType.Capsule })
          .layoutWeight(1)
          .height(48)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_on_primary'))
          .backgroundColor($r('sys.color.interactive_active'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            this.handleConfirm();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
  }
}

@Builder
export function AutoSaveSettingsDialogBuilder(params: AutoSaveDialogParams) {
  AutoSaveSettingsDialog({ params })
}