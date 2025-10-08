import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2 } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import { DesignConstants } from '../../constants/DesignConstants';
import { Debounce } from '../../utils/Debounce';
import { EditableTitleBar, EditableLeftIconType } from '@kit.ArkUI';

export interface AutoSaveDialogParams {
  onClose: () => void;
  onSettingsApplied?: (settings: AutoSaveSettings) => void; // 新增：设置应用回调
}

export interface AutoSaveSettings {
  enabled: boolean;
  interval: number;
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
  // 临时状态变量 - 不立即持久化
  @Local tempAutoSaveEnabled: boolean = this.pk.auto_save_enabled;
  @Local tempInterval: number = this.pk.auto_save_interval;
  @Local tempCustomInterval: number = this.tempInterval;
  @Param @Require params: AutoSaveDialogParams;
  
  // 初始状态 - 用于检测是否有修改
  private initialAutoSaveEnabled: boolean = this.pk.auto_save_enabled;
  private initialInterval: number = this.pk.auto_save_interval;

  aboutToAppear() {
    // 记录初始状态用于修改检测
    this.init();
  }

  private init() {
    this.initialAutoSaveEnabled = this.pk.auto_save_enabled;
    this.initialInterval = this.pk.auto_save_interval;

    // 初始化临时状态
    this.tempAutoSaveEnabled = this.pk.auto_save_enabled;
    this.tempInterval = this.pk.auto_save_interval;
    this.tempCustomInterval = this.tempInterval;
  }

  // 处理保存操作
  private handleSave() {
    // 应用自动保存设置
    this.pk.auto_save_enabled = this.tempAutoSaveEnabled;
    this.pk.auto_save_interval = this.tempInterval;
    
    // 通过回调通知设置已应用
    if (this.params.onSettingsApplied) {
      const settings: AutoSaveSettings = {
        enabled: this.tempAutoSaveEnabled,
        interval: this.tempInterval
      };
      this.params.onSettingsApplied(settings);
    }
    
    // 显示保存成功提示
    const statusText = this.tempAutoSaveEnabled ? `已开启，间隔${this.tempInterval}分钟` : '已关闭';
    promptAction.showToast({
      message: `自动保存${statusText}`,
      duration: 2000
    });
    
    // 关闭弹窗
    this.params.onClose();
  }

  // 处理取消操作
  private handleCancel() {
    // 直接关闭弹窗，不应用任何设置
    this.params.onClose();
  }

  @Computed
  get selectedIndex(){
    return this.getPresetIndex(this.tempInterval);
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
      default: return this.tempCustomInterval;
    }
  }

  private handlePresetSelect(index: number) {
    // 只更新临时状态，不立即持久化
    const newInterval = this.getPresetInterval(index);
    this.tempInterval = newInterval;
    if (index !== -1) {
      this.tempCustomInterval = newInterval;
    }
  }

  private handleCustomInput(value: string) {
    const numValue = parseInt(value);
    if (!isNaN(numValue) && numValue >= 1 && numValue <= 60) {
      this.tempCustomInterval = numValue;
      this.tempInterval = numValue;
    }
  }

  // 处理开关变化 - 只更新临时状态
  private handleToggleChange(isOn: boolean) {
    this.tempAutoSaveEnabled = isOn;
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
      Debounce.click(() => {
        this.handlePresetSelect(params.index);
      });
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
        
        TextInput({ text: this.tempCustomInterval.toString() })
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
    Column({ space: 0 }) {
      // 使用EditableTitleBar提供标准的编辑界面标题栏
      EditableTitleBar({
        leftIconStyle: EditableLeftIconType.Cancel,
        title: '自动保存设置',
        isSaveIconRequired: true,
        onSave: () => {
          this.handleSave();
        },
        onCancel: () => {
          this.handleCancel();
        }
      })

      // 内容区域 - 从顶部开始排列
      Scroll() {
        Column({ space: DesignConstants.SPACING_LG }) {
          // 开关区域
          Row({ space: 8 }) {
            Text('启用自动保存')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))
              .layoutWeight(1)
            
            Toggle({ type: ToggleType.Switch, isOn: this.tempAutoSaveEnabled })
              .selectedColor($r('app.color.toggle_active'))
              .switchPointColor($r('app.color.background_primary'))
              .onChange((isOn: boolean) => {
                this.handleToggleChange(isOn);
              })
          }
          .width('100%')
          .padding(DesignConstants.SPACING_MD)
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)

          if (this.tempAutoSaveEnabled) {
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
        }
        .width('100%')
        .padding(DesignConstants.SPACING_LG)
        .alignItems(HorizontalAlign.Start) // 确保内容从左侧开始
      }
      .scrollBar(BarState.Auto)
      .scrollable(ScrollDirection.Vertical)
      .layoutWeight(1)
      .align(Alignment.TopStart) // 确保滚动区域从顶部开始
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start) // 确保整个列从顶部开始
  }
}

@Builder
export function AutoSaveSettingsDialogBuilder(params: AutoSaveDialogParams) {
  AutoSaveSettingsDialog({ params })
}