/**
 * 增强版自定义配置面板组件
 * 提供详细的音频分析参数自定义配置界面，包含参数说明、可视化展示和推荐场景
 */

import { AudioAnalysisConfig, DEFAULT_CUSTOM_CONFIG } from '../../common/AudioConfig';
import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';
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
  value: ResourceStr;
}

// 参数详细说明类
class ParameterDetail {
  name: string;
  description: string;
  impact: string;
  recommendedScenarios: string[];
  technicalNote: string;

  constructor(name: string, description: string, impact: string, recommendedScenarios: string[], technicalNote: string) {
    this.name = name;
    this.description = description;
    this.impact = impact;
    this.recommendedScenarios = recommendedScenarios;
    this.technicalNote = technicalNote;
  }
}

// 技术指标类
class TechnicalMetrics {
  frequencyResolution: string;
  timeResolution: string;
  effectiveUpdateRate: string;
  bufferSizeKB: string;

  constructor(frequencyResolution: string, timeResolution: string, effectiveUpdateRate: string, bufferSizeKB: string) {
    this.frequencyResolution = frequencyResolution;
    this.timeResolution = timeResolution;
    this.effectiveUpdateRate = effectiveUpdateRate;
    this.bufferSizeKB = bufferSizeKB;
  }
}

@ComponentV2
export struct EnhancedCustomConfigPanel {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local display: boolean = true;
  @Local expandedParameter: string = ''; // 当前展开的参数
  @Event onSelectedChange: () => void;
  @Event onConfigChange?: (config: AudioAnalysisConfig) => void;
  @Local tempCustomConfig: AudioAnalysisConfig = this.pk.custom_audio_config.clone();
  
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

  // 参数详细说明
  private readonly parameterDetails: Map<string, ParameterDetail> = new Map([
    ['fftSize', new ParameterDetail(
      'FFT大小',
      '快速傅里叶变换的采样点数，决定了频率分辨率',
      'FFT越大，频率分辨率越高，但计算延迟也越大。较小的FFT提供更好的时间分辨率。',
      ['1024: 适合快速变化的信号，如脉冲噪声', '2048: 平衡频率和时间分辨率，适合一般测量', '4096: 高频率分辨率，适合稳态信号分析', '8192: 极高频率分辨率，适合精密声学分析'],
      '频率分辨率 = 采样率 / FFT大小'
    )],
    ['updateInterval', new ParameterDetail(
      '更新间隔',
      '音频分析结果的更新频率',
      '间隔越短，响应越快，但CPU占用越高。间隔越长，显示越平滑，但可能错过瞬时变化。',
      ['35ms: 实时监测，适合脉冲噪声测量', '100ms: 快速响应，适合一般噪声监测', '200ms: 标准响应，适合大多数应用', '500ms: 平滑显示，适合稳态噪声', '1000ms: 超平滑，适合长期趋势分析'],
      '更新频率 = 1000 / 更新间隔 (Hz)'
    )],
    ['windowType', new ParameterDetail(
      '窗函数类型',
      '用于减少频谱泄漏的数学函数',
      '不同窗函数在频率分辨率和幅度精度之间有不同的权衡',
      ['汉宁窗: 通用性好，频率分辨率适中', '布莱克曼窗: 频率泄漏更少，但主瓣较宽'],
      '窗函数影响频谱分析的动态范围和频率精度'
    )],
    ['smoothingFactor', new ParameterDetail(
      '平滑因子',
      '控制数据显示的平滑程度',
      '值越大，显示越平滑，但响应越慢。值越小，响应越快，但显示可能不稳定。',
      ['0.05-0.15: 高灵敏度，适合快速变化信号', '0.2-0.3: 平衡模式，适合一般应用', '0.35-0.5: 高平滑度，适合稳态信号'],
      '平滑算法: 新值 = 平滑因子 × 当前值 + (1-平滑因子) × 上次值'
    )],
    ['overlap', new ParameterDetail(
      '重叠率',
      '连续FFT分析之间的数据重叠比例',
      '重叠率越高，时间分辨率越好，但计算量越大',
      ['0.1-0.3: 低计算量，适合资源受限环境', '0.4-0.6: 平衡模式，适合一般应用', '0.7-0.9: 高时间分辨率，适合精密分析'],
      '有效更新率 = 原始更新率 / (1-重叠率)'
    )]
  ]);

  // 重置配置到默认值
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
    
    if (this.onConfigChange) {
      this.onConfigChange(this.tempCustomConfig);
    }
  }

  // 计算技术指标
  private calculateTechnicalMetrics(): TechnicalMetrics {
    const sampleRate = 44100; // 假设采样率
    const frequencyResolution = sampleRate / this.tempCustomConfig.fftSize;
    const timeResolution = (this.tempCustomConfig.fftSize / sampleRate) * 1000;
    const effectiveUpdateRate = this.tempCustomConfig.updateInterval / (1 - this.tempCustomConfig.overlap);
    
    return new TechnicalMetrics(
      frequencyResolution.toFixed(1),
      timeResolution.toFixed(1),
      effectiveUpdateRate.toFixed(0),
      (this.tempCustomConfig.bufferSize / 1024).toFixed(1)
    );
  }

  // 构建增强的参数选择器
  @Builder
  private buildEnhancedParameterSelector(
    paramKey: string,
    value: number | string,
    options: SelectOption[],
    onValueChange: (newValue: number | string) => void
  ) {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 参数标题和值
      Row({ space: DesignConstants.SPACING_MD }) {
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(this.parameterDetails.get(paramKey)!.name)
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
          
          Text(this.parameterDetails.get(paramKey)!.description)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 当前值显示
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(value.toString())
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.icon_emphasize'))
          
          Text('当前值')
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_secondary'))
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      // 参数选择器
      Row({ space: DesignConstants.SPACING_MD }) {
        Select(this.buildSelectOptions(options))
          .value(value + '')
          .selected(this.findOptionIndex(value, options))
          .onSelect((index: number) => {
            const newValue = options[index].value;
            onValueChange(newValue);
            if (this.onConfigChange) {
              this.onConfigChange(this.tempCustomConfig);
            }
          })
          .width(140)
        
        // 展开/收起按钮
        Button(this.expandedParameter === paramKey ? '收起详情' : '查看详情')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.icon_emphasize'))
          .backgroundColor(Color.Transparent)
          .border({ width: 1, color: $r('sys.color.icon_emphasize') })
          .height(32)
          .onClick(() => {
            this.expandedParameter = this.expandedParameter === paramKey ? '' : paramKey;
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      // 详细说明区域
      if (this.expandedParameter === paramKey) {
        Column({ space: DesignConstants.SPACING_MD }) {
          // 影响说明
          Column({ space: DesignConstants.SPACING_SM }) {
            Text('参数影响')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
              .alignSelf(ItemAlign.Start)
             
            Text(this.parameterDetails.get(paramKey)!.impact)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .alignSelf(ItemAlign.Start)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding(DesignConstants.SPACING_SM)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_SM)

          // 推荐场景
          Column({ space: DesignConstants.SPACING_SM }) {
            Text('推荐场景')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
              .alignSelf(ItemAlign.Start)
             
            ForEach(this.parameterDetails.get(paramKey)!.recommendedScenarios, (scenario: string) => {
              Row({ space: DesignConstants.SPACING_SM }) {
                Text('•')
                  .fontSize(DesignConstants.FONT_SIZE_SM)
                  .fontColor($r('sys.color.icon_emphasize'))
                 
                Text(scenario)
                  .fontSize(DesignConstants.FONT_SIZE_SM)
                  .fontColor($r('sys.color.font_secondary'))
                  .layoutWeight(1)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
            })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding(DesignConstants.SPACING_SM)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_SM)

          // 技术说明
          Column({ space: DesignConstants.SPACING_SM }) {
            Text('技术说明')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
              .alignSelf(ItemAlign.Start)
             
            Text(this.parameterDetails.get(paramKey)!.technicalNote)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .alignSelf(ItemAlign.Start)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .padding(DesignConstants.SPACING_SM)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_SM)
        }
        .width('100%')
        .animation({ duration: 300, curve: Curve.EaseInOut })
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .border({ width: 1, color: $r('sys.color.comp_border_color') })
  }

  // 查找选项索引
  private findOptionIndex(value: number | string, options: SelectOption[]): number {
    const option = options.find(opt => opt.value === value);
    return option ? option.index : 0;
  }

  // 构建选择选项数组
  private buildSelectOptions(options: SelectOption[]): SelectOptionS[] {
    const result: SelectOptionS[] = [];
    for (let i = 0; i < options.length; i++) {
      result.push({ value: options[i].label + '' });
    }
    return result;
  }

  // 构建技术指标显示
  @Builder
  private buildTechnicalMetrics() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('技术指标')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .width('100%')
      
      Row({ space: DesignConstants.SPACING_MD }) {
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(this.calculateTechnicalMetrics().frequencyResolution + ' Hz')
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.icon_emphasize'))
          
          Text('频率分辨率')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(this.calculateTechnicalMetrics().timeResolution + ' ms')
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.icon_emphasize'))
          
          Text('时间分辨率')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(this.calculateTechnicalMetrics().effectiveUpdateRate + ' Hz')
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.icon_emphasize'))
          
          Text('有效更新率')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(this.calculateTechnicalMetrics().bufferSizeKB + ' KB')
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.icon_emphasize'))
          
          Text('缓冲区大小')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 标题和说明
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('自定义音频分析配置')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .width('100%')
        
        Text('调整以下参数以优化您的音频分析体验。点击"查看详情"了解每个参数的具体影响和推荐场景。')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .width('100%')
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 技术指标显示
      this.buildTechnicalMetrics()
      
      // 配置参数区域
      if (this.display) {
        Column({ space: DesignConstants.SPACING_MD }) {
          // FFT大小选择
          this.buildEnhancedParameterSelector(
            'fftSize',
            this.tempCustomConfig.fftSize,
            this.fftSizeOptions,
            (newValue: number | string) => {
              this.tempCustomConfig.fftSize = newValue as number;
              this.tempCustomConfig.bufferSize = this.tempCustomConfig.fftSize * 2;
            }
          )

          // 更新间隔选择
          this.buildEnhancedParameterSelector(
            'updateInterval',
            this.tempCustomConfig.updateInterval,
            this.updateIntervalOptions,
            (newValue: number | string) => {
              this.tempCustomConfig.updateInterval = newValue as number;
            }
          )

          // 窗函数类型选择
          this.buildEnhancedParameterSelector(
            'windowType',
            this.tempCustomConfig.windowType,
            this.windowTypeOptions,
            (newValue: number | string) => {
              this.tempCustomConfig.windowType = newValue as WindowType;
            }
          )

          // 平滑因子选择
          this.buildEnhancedParameterSelector(
            'smoothingFactor',
            this.tempCustomConfig.smoothingFactor,
            this.smoothingFactorOptions,
            (newValue: number | string) => {
              this.tempCustomConfig.smoothingFactor = newValue as number;
            }
          )

          // 重叠率选择
          this.buildEnhancedParameterSelector(
            'overlap',
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

      // 重置按钮
      Button('重置为默认值', { type: ButtonType.Normal })
        .width('100%')
        .height(48)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor($r('sys.color.interactive_active'))
        .fontColor($r('sys.color.font_on_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          Throttle.click(() => {
            this.resetToDefault();
          });
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .margin({ bottom: 100 })
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.background_secondary'))
  }
}