import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2 } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import { DesignConstants } from '../../constants/DesignConstants';

export interface AutoSaveDialogParams {
  onClose: () => void;
}

export interface PresetOptionParams {
  index: number;
  label: string;
  description: string;
  selectedIndex: number;
}

@ComponentV2
export struct AutoSaveSettingsDialog {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local autoSaveEnabled: boolean = this.pk.auto_save_enabled;
  @Local interval: number = this.pk.auto_save_interval;
  @Local customInterval: number = this.interval;
  @Param @Require params: AutoSaveDialogParams;

  aboutToAppear() {
    // 确保状态正确初始化
    this.autoSaveEnabled = this.pk.auto_save_enabled;
    this.interval = this.pk.auto_save_interval;
    this.customInterval = this.interval;
  }

  @Computed
  get selectedIndex(){
    return this.getPresetIndex(this.interval);
  }

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
    // 立即更新所有相关状态
    const newInterval = this.getPresetInterval(index);
    this.interval = newInterval;
    if (index !== -1) {
      this.customInterval = newInterval;
    }
  }

  private handleCustomInput(value: string) {
    const numValue = parseInt(value);
    if (!isNaN(numValue) && numValue >= 1 && numValue <= 60) {
      this.customInterval = numValue;
      this.interval = numValue;
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
  private buildPresetOption(params: PresetOptionParams) {

    Column({ space: 4 }) {
      Text(params.label)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor(params.selectedIndex === params.index ? $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))
      
      Text(params.description)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor(params.selectedIndex === params.index ? $r('sys.color.font_on_primary') : $r('sys.color.font_secondary'))
    }
    .width('100%')
    .height(72)
    .backgroundColor(params.selectedIndex === params.index ? $r('sys.color.interactive_active') : $r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .padding(DesignConstants.SPACING_MD)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.handlePresetSelect(params.index);
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
            this.buildPresetOption({
              index: 0,
              label: '3分钟',
              description: '工业监测',
              selectedIndex: this.selectedIndex
            })
          }
          GridCol({ span: 1 }) {
            this.buildPresetOption({
              index: 1,
              label: '5分钟',
              description: '综合应用',
              selectedIndex: this.selectedIndex
            })
          }
          GridCol({ span: 1 }) {
            this.buildPresetOption({
              index: 2,
              label: '10分钟',
              description: '社区投诉',
              selectedIndex: this.selectedIndex
            })
          }
          GridCol({ span: 1 }) {
            this.buildPresetOption({
              index: 3,
              label: '20分钟',
              description: '健康监测',
              selectedIndex: this.selectedIndex
            })
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