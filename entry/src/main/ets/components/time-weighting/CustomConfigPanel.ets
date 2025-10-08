/**
 * 自定义配置面板组件
 * 提供完整的音频分析参数自定义配置界面
 */

import { AudioAnalysisConfig, DEFAULT_CUSTOM_CONFIG } from '../../common/AudioConfig';
import { DesignConstants } from '../../constants/DesignConstants';
import { Debounce } from '../../utils/Debounce';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2 } from '@kit.ArkUI';
import { WindowType } from '../../common/WindowType';

// 选项接口
interface SelectOption {
  value: number | string;
  label: string;
  index: number;
}

interface SelectOptionS {
  /**
   * Option string.
   *
   * @type { ResourceStr }
   * @syscap SystemCapability.ArkUI.ArkUI.Full
   * @since 8
   */
  /**
   * Option string.
   *
   * @type { ResourceStr }
   * @syscap SystemCapability.ArkUI.ArkUI.Full
   * @crossplatform
   * @since 10
   */
  /**
   * Option string.
   *
   * @type { ResourceStr }
   * @syscap SystemCapability.ArkUI.ArkUI.Full
   * @crossplatform
   * @atomicservice
   * @since 11
   */
  value: ResourceStr;
}

@ComponentV2
export struct CustomConfigPanel {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local display: boolean = true;
  @Event onSelectedChange: () => void;
  @Event onConfigChange?: (config: AudioAnalysisConfig) => void; // 新增：配置变化回调
  @Local tempCustomConfig: AudioAnalysisConfig =
    new AudioAnalysisConfig(this.pk.custom_audio_config.fftSize, this.pk.custom_audio_config.updateInterval,
      this.pk.custom_audio_config.smoothingFactor, this.pk.custom_audio_config.windowType,
      this.pk.custom_audio_config.overlap, this.pk.custom_audio_config.bufferSize); // 临时配置状态
  // FFT大小选项
  private readonly fftSizeOptions: SelectOption[] = [
    { value: 1024, label: '1024', index: 0 },
    { value: 2048, label: '2048', index: 1 },
    { value: 4096, label: '4096', index: 2 },
    { value: 8192, label: '8192', index: 3 }
  ];
  // 更新间隔选项
  private readonly updateIntervalOptions: SelectOption[] = [
    { value: 35, label: '35ms', index: 0 },
    { value: 100, label: '100ms', index: 1 },
    { value: 200, label: '200ms', index: 2 },
    { value: 500, label: '500ms', index: 3 },
    { value: 1000, label: '1000ms', index: 4 }
  ];
  // 窗函数选项
  private readonly windowTypeOptions: SelectOption[] = [
    { value: WindowType.HANNING, label: '汉宁窗', index: 0 },
    { value: WindowType.BLACKMAN, label: '布莱克曼窗', index: 1 }
  ];
  // 平滑因子选项
  private readonly smoothingFactorOptions: SelectOption[] = [
    { value: 0.05, label: '0.05', index: 0 },
    { value: 0.1, label: '0.1', index: 1 },
    { value: 0.15, label: '0.15', index: 2 },
    { value: 0.2, label: '0.2', index: 3 },
    { value: 0.25, label: '0.25', index: 4 },
    { value: 0.3, label: '0.3', index: 5 },
    { value: 0.35, label: '0.35', index: 6 },
    { value: 0.4, label: '0.4', index: 7 },
    { value: 0.45, label: '0.45', index: 8 },
    { value: 0.5, label: '0.5', index: 9 }
  ];
  // 重叠率选项
  private readonly overlapOptions: SelectOption[] = [
    { value: 0.1, label: '0.1', index: 0 },
    { value: 0.2, label: '0.2', index: 1 },
    { value: 0.3, label: '0.3', index: 2 },
    { value: 0.4, label: '0.4', index: 3 },
    { value: 0.5, label: '0.5', index: 4 },
    { value: 0.6, label: '0.6', index: 5 },
    { value: 0.7, label: '0.7', index: 6 },
    { value: 0.8, label: '0.8', index: 7 },
    { value: 0.9, label: '0.9', index: 8 }
  ];

  // 重置配置到默认值 - 只更新临时状态
  private resetToDefault() {
    this.display = false;
    setTimeout(() => {
      this.display = true;
    }, 500);
    this.tempCustomConfig.fftSize = DEFAULT_CUSTOM_CONFIG.fftSize;
    this.tempCustomConfig.updateInterval = DEFAULT_CUSTOM_CONFIG.updateInterval;
    this.tempCustomConfig.smoothingFactor = DEFAULT_CUSTOM_CONFIG.smoothingFactor;
    this.tempCustomConfig.windowType = DEFAULT_CUSTOM_CONFIG.windowType;
    this.tempCustomConfig.overlap = DEFAULT_CUSTOM_CONFIG.overlap;
    this.tempCustomConfig.bufferSize = DEFAULT_CUSTOM_CONFIG.bufferSize;
    // 通知配置变化
    if (this.onConfigChange) {
      this.onConfigChange(this.tempCustomConfig);
    }
  }

  // 构建参数选择器
  @Builder
  private buildParameterSelector(label: string, value: number | string, options: SelectOption[],
    onValueChange: (newValue: number | string) => void) {
    Row({ space: DesignConstants.SPACING_MD }) {
      Text(label)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
        .layoutWeight(1)

      Select(options.map(option => {
        let opt: SelectOptionS = { value: option.label + '' };
        return opt;
      }))
        .value(value + '')
        .selected(this.findOptionIndex(value, options))
        .onSelect((index: number) => {
          const newValue = options[index].value;
          onValueChange(newValue);
          // 通知配置变化
          if (this.onConfigChange) {
            this.onConfigChange(this.tempCustomConfig);
          }
        })
        .width(120)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  // 查找选项索引
  private findOptionIndex(value: number | string, options: SelectOption[]): number {
    const option = options.find(opt => opt.value === value);
    return option ? option.index : 0;
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 技术参数显示
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('当前配置参数')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .width('100%')

        Column({ space: DesignConstants.SPACING_XS }) {
          Text(`FFT大小: ${this.tempCustomConfig.fftSize}`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))

          Text(`更新间隔: ${this.tempCustomConfig.updateInterval}ms`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))

          Text(`窗函数: ${this.tempCustomConfig.windowType === WindowType.HANNING ? '汉宁窗' : '布莱克曼窗'}`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))

          Text(`平滑因子: ${this.tempCustomConfig.smoothingFactor}`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))

          Text(`重叠率: ${this.tempCustomConfig.overlap}`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))

          Text(`缓冲区大小: ${this.tempCustomConfig.bufferSize}字节`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      }
      .width('100%')

      // 重置按钮
      Button('重置为默认值', { type: ButtonType.Normal })
        .width('100%')
        .height(48)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor($r('sys.color.interactive_active'))
        .fontColor($r('sys.color.font_on_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          Debounce.click(() => {
            this.resetToDefault();
          });
        })
      // 配置参数区域
      if (this.display) {
        Column({ space: DesignConstants.SPACING_MD }) {
          Text('自定义配置')
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
            .width('100%')

          // FFT大小选择
          this.buildParameterSelector(
            'FFT大小',
            this.tempCustomConfig.fftSize,
            this.fftSizeOptions,
            (newValue: number | string) => {
              this.tempCustomConfig.fftSize = newValue as number;
              this.tempCustomConfig.bufferSize = this.tempCustomConfig.fftSize * 2;
            }
          )

          // 更新间隔选择
          this.buildParameterSelector(
            '更新间隔',
            this.tempCustomConfig.updateInterval,
            this.updateIntervalOptions,
            (newValue: number | string) => {
              this.tempCustomConfig.updateInterval = newValue as number;
            }
          )

          // 窗函数类型选择
          this.buildParameterSelector(
            '窗函数类型',
            this.tempCustomConfig.windowType,
            this.windowTypeOptions,
            (newValue: number | string) => {
              this.tempCustomConfig.windowType = newValue as WindowType;
            }
          )

          // 平滑因子选择
          this.buildParameterSelector(
            '平滑因子',
            this.tempCustomConfig.smoothingFactor,

            this.smoothingFactorOptions,
            (newValue: number | string) => {
              this.tempCustomConfig.smoothingFactor = newValue as number;
            }
          )

          // 重叠率选择
          this.buildParameterSelector(
            '重叠率',
            this.tempCustomConfig.overlap,
            this.overlapOptions,
            (newValue: number | string) => {
              this.tempCustomConfig.overlap = newValue as number;
            }
          )
        }
        .width('100%')
      } else {
        Column() {
          LoadingProgress().width(45).height(45);
        }.alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
      }

    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .margin({ bottom: 100 })
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.background_secondary'))
  }
}