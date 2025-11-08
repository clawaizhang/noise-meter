import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DesignConstants } from '../../constants/DesignConstants';
import { DialogHub, InfSheet } from '@hadss/dialoghub';

/**
 * 采样率设置参数
 */
export interface SampleRateSettingsParams {
  onClose: () => void;
  onSettingsApplied: (sampleRate: number, decimationEnabled: boolean, decimationFactor: number) => void;
}

/**
 * 采样率选项类
 */
class SampleRateOption {
  public value: number = 0;
  public label: string = '';

  constructor(value: number, label: string) {
    this.value = value;
    this.label = label;
  }
}

/**
 * 降采样因子选项类
 */
class DecimationFactorOption {
  public value: number = 0;
  public label: string = '';

  constructor(value: number, label: string) {
    this.value = value;
    this.label = label;
  }
}

/**
 * 采样率选项
 */
const SAMPLE_RATE_OPTIONS: SampleRateOption[] = [
  new SampleRateOption(8000, '8 kHz'),
  new SampleRateOption(11025, '11.025 kHz'),
  new SampleRateOption(16000, '16 kHz'),
  new SampleRateOption(22050, '22.05 kHz'),
  new SampleRateOption(44100, '44.1 kHz'),
  new SampleRateOption(48000, '48 kHz')
];

/**
 * 降采样因子选项
 */
const DECIMATION_FACTOR_OPTIONS: DecimationFactorOption[] = [
  new DecimationFactorOption(2, '2倍'),
  new DecimationFactorOption(4, '4倍'),
  new DecimationFactorOption(8, '8倍'),
  new DecimationFactorOption(16, '16倍')
];

/**
 * 采样率设置对话框组件
 */
@ComponentV2
export struct SampleRateSettingsDialog {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local selectedSampleRate: number = 44100;
  @Local decimationEnabled: boolean = false;
  @Local selectedDecimationFactor: number = 2;
  @Param params: SampleRateSettingsParams | null = null;

  aboutToAppear(): void {
    // 初始化当前设置
    this.selectedSampleRate = this.pk.audio_sample_rate;
    this.decimationEnabled = this.pk.audio_decimation_enabled;
    this.selectedDecimationFactor = this.pk.audio_decimation_factor;
    
    // 检查当前是否为自定义模式
    if (this.pk.audio_analysis_mode === 'CUSTOM_TIME_WEIGHTING') {
      console.info('[采样率设置] 当前为自定义模式，采样率设置在自定义配置中管理');
    }
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 标题
      Row() {
        Text('采样率设置')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: DesignConstants.SPACING_MD, bottom: DesignConstants.SPACING_MD })

      // 采样率选择
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('采样率')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        // 采样率选项网格
        GridRow({ columns: 2, gutter: DesignConstants.SPACING_SM }) {
          ForEach(SAMPLE_RATE_OPTIONS, (option: SampleRateOption) => {
            GridCol({ span: 1 }) {
              this.buildSampleRateOption(option)
            }
          })
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 降采样设置
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('降采样设置')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        // 降采样开关
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('启用降采样')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))

          Toggle({ type: ToggleType.Switch, isOn: this.decimationEnabled })
            .onChange((isOn: boolean) => {
              this.decimationEnabled = isOn;
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        // 降采样因子选择
        if (this.decimationEnabled) {
          Column({ space: DesignConstants.SPACING_SM }) {
            Text('降采样因子')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .alignSelf(ItemAlign.Start)

            // 降采样因子选项网格
            GridRow({ columns: 2, gutter: DesignConstants.SPACING_SM }) {
              ForEach(DECIMATION_FACTOR_OPTIONS, (option: DecimationFactorOption) => {
                GridCol({ span: 1 }) {
                  this.buildDecimationFactorOption(option)
                }
              })
            }
            .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 说明信息
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('说明')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        Text('降采样可以大幅降低计算量，提高处理速度，但会损失高频信号成分。适用于对实时性要求高但不需要高频分析的场景。')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .lineHeight(20)

        // 自定义模式提示
        if (this.pk.audio_analysis_mode === 'CUSTOM_TIME_WEIGHTING') {
          Column({ space: DesignConstants.SPACING_XS }) {
            Text('注意')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.warning'))
              .alignSelf(ItemAlign.Start)

            Text('当前为自定义模式，采样率设置请在自定义配置中管理。此处的设置仅对预设模式（快速、慢速、脉冲）生效。')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .lineHeight(18)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ top: DesignConstants.SPACING_SM })
          .backgroundColor($r('sys.color.alert'))
          .borderRadius(DesignConstants.BORDER_RADIUS_SM)
          .padding(DesignConstants.SPACING_SM)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 按钮区域
      Row({ space: DesignConstants.SPACING_MD }) {
        Button('取消')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .layoutWeight(1)
          .onClick(() => {
            this.params?.onClose();
          })

        Button('应用')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .layoutWeight(1)
          .onClick(() => {
            this.applySettings();
          })
      }
      .width('100%')
      .margin({ top: DesignConstants.SPACING_LG })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  @Builder
  private buildSampleRateOption(option: SampleRateOption) {
    Row() {
      Text(option.label)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor(this.selectedSampleRate === option.value ?
          $r('sys.color.font_emphasize') : $r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(40)
    .padding(DesignConstants.SPACING_SM)
    .backgroundColor(this.selectedSampleRate === option.value ?
      $r('sys.color.comp_background_emphasize') : $r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_SM)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.selectedSampleRate = option.value;
    })
  }

  @Builder
  private buildDecimationFactorOption(option: DecimationFactorOption) {
    Row() {
      Text(option.label)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor(this.selectedDecimationFactor === option.value ?
          $r('sys.color.font_emphasize') : $r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(40)
    .padding(DesignConstants.SPACING_SM)
    .backgroundColor(this.selectedDecimationFactor === option.value ?
      $r('sys.color.comp_background_emphasize') : $r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_SM)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.selectedDecimationFactor = option.value;
    })
  }

  private applySettings(): void {
    // 检查是否为自定义模式
    if (this.pk.audio_analysis_mode === 'CUSTOM_TIME_WEIGHTING') {
      // 自定义模式下不应用设置，只显示提示
      console.info('[采样率设置] 自定义模式下不应用全局采样率设置');
      // 关闭对话框
      this.params?.onClose();
      return;
    }

    // 更新配置
    this.pk.audio_sample_rate = this.selectedSampleRate;
    this.pk.audio_decimation_enabled = this.decimationEnabled;
    this.pk.audio_decimation_factor = this.selectedDecimationFactor;

    // 通知应用设置
    this.params?.onSettingsApplied(
      this.selectedSampleRate,
      this.decimationEnabled,
      this.selectedDecimationFactor
    );

    // 关闭对话框
    this.params?.onClose();
  }
}

/**
 * 采样率设置对话框构建器
 */
@Builder
export function SampleRateSettingsBuilder(params: SampleRateSettingsParams) {
  SampleRateSettingsDialog({ params: params })
}