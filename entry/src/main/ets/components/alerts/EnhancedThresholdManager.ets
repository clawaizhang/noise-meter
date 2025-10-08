/**
 * 简化型阈值管理组件
 * 单一面板设计：环境类型选择 + 时段调度开关
 */

import { DEFAULT_THRESHOLD_CONFIG, PresetThreshold, PresetType, ThresholdConfig } from '../../models/ThresholdConfig';
import { DesignConstants } from '../../constants/DesignConstants';
import { Debounce } from '../../utils/Debounce';
import { curves, PersistenceV2 } from '@kit.ArkUI';
import { ThresholdManager } from '../../services/ThresholdManager';
import { PremiumFeature } from '../membership/PremiumFeature';
import { PreferenceKeys } from '../../models/PreferenceKeys';

@ObservedV2
class PresetConfig {
  @Trace type: PresetType;
  @Trace baseValue: number;
  @Trace name: string;
  @Trace description: string;
  @Trace color: Resource;

  constructor(type: PresetType, baseValue: number, name: string, description: string, color: Resource) {
    this.type = type;
    this.baseValue = baseValue;
    this.name = name;
    this.description = description;
    this.color = color;
  }
}

@ComponentV2
export struct EnhancedThresholdManager {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Param @Require currentConfig: ThresholdConfig = ThresholdConfig.clone(this.pk.alarm_threshold);
  @Event onConfigChange?: (config: ThresholdConfig) => void;

  aboutToAppear(): void {
  }

  // 更新配置并触发回调
  private updateConfig(newConfig: ThresholdConfig) {
    if (this.onConfigChange) {
      this.onConfigChange(newConfig);
    }
  }

  // 构建环境类型选择器
  @Builder
  private buildEnvironmentSelector() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 环境类型选项网格
      GridRow({
        columns: { sm: 2, md: 3 },
        breakpoints: { reference: BreakpointsReference.WindowSize },
        gutter: { x: DesignConstants.SPACING_SM, y: DesignConstants.SPACING_SM }
      }) {
        ForEach([
          PresetType.QUIET_ENVIRONMENT,
          PresetType.GENERAL_ENVIRONMENT,
          PresetType.NOISY_ENVIRONMENT,
          PresetType.DANGEROUS_ENVIRONMENT,
          PresetType.CUSTOM
        ], (presetType: PresetType) => {
          GridCol({ span: 1 }) {
            this.buildEnvironmentCard(presetType, this.getPresetByType(presetType))
          }
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  // 构建环境类型卡片
  @Builder
  private buildEnvironmentCard(presetType: PresetType, preset: PresetThreshold) {
    if (preset) {
      Column({ space: DesignConstants.SPACING_XS }) {
        if (presetType !== PresetType.CUSTOM) {
          Text(`${preset.baseValue}dB`)
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.currentConfig.currentPreset === presetType ? Color.White : preset.color)
        }

        Text(preset.name)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.currentConfig.currentPreset === presetType ? Color.White : $r('sys.color.font_primary'))

        Text(preset.description)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(this.currentConfig.currentPreset === presetType ? Color.White : $r('sys.color.font_secondary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor(this.currentConfig.currentPreset === presetType ? preset.color :
        $r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .border({
        width: this.currentConfig.currentPreset === presetType ? 2 : 1,
        color: this.currentConfig.currentPreset === presetType ? preset.color : $r('sys.color.background_secondary')
      })
      .onClick(() => {
        Debounce.click(() => {
          this.logStateChange('选择环境类型', presetType);
          this.currentConfig.currentPreset = presetType;

          // 根据选择的预设类型更新对应的阈值数值
          if (presetType !== PresetType.CUSTOM) {
            const preset = this.getPresetByType(presetType);
            this.currentConfig.baseThreshold = preset.baseValue;
            this.currentConfig.daytimeThreshold = preset.baseValue;
            this.currentConfig.nighttimeThreshold = preset.baseValue - 5; // 夜间阈值比白天低5dB
          }

          this.updateConfig(this.currentConfig);
        })
      })
      .animation({
        duration: 200,
        curve: curves.springMotion()
      })
    }
  }

  // 构建统一的阈值设置面板（包含时段调度开关和环境类型选择）
  @Builder
  private buildUnifiedThresholdPanel() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题栏（包含时段调度开关）
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('阈值设置')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        // 时段调度开关
        PremiumFeature({ featureName: '时段调度', featureDesc: '白天和夜间使用不同阈值' }) {
          Row({ space: DesignConstants.SPACING_XS }) {
            Text('时段调度')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))

            Toggle({ type: ToggleType.Switch, isOn: this.currentConfig.timeSchedulingEnabled })
              .onChange((isOn: boolean) => {
                this.logStateChange(`切换时段调度: ${isOn ? '启用' : '禁用'}`);
                this.currentConfig.timeSchedulingEnabled = isOn;
                this.updateConfig(this.currentConfig);
              })
          }
          .alignItems(VerticalAlign.Center)
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 时段调度状态描述
      Text(this.currentConfig.timeSchedulingEnabled ?
        '已启用时段调度，白天和夜间使用不同阈值' :
        '时段调度已关闭，全天使用统一阈值')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)

      // 阈值设置区域
      this.buildDynamicThresholdControls()

      // 环境类型选择区域
      Column({ space: DesignConstants.SPACING_SM }) {
        // 引导提示
        Text('选择环境类型快速设置阈值')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .alignSelf(ItemAlign.Start)

        PremiumFeature({ featureName: '选择预设环境', featureDesc: '选择预设环境快速设置阈值' }) {
          // 环境类型网格选择器
          this.buildEnvironmentSelector()
        }
      }
      .width('100%')
      .margin({ top: DesignConstants.SPACING_MD })

    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_SM)
  }

  // 构建动态阈值控制区域
  @Builder
  private buildDynamicThresholdControls() {
    if (this.currentConfig.currentPreset === PresetType.CUSTOM) {
      Column({ space: DesignConstants.SPACING_MD }) {
        // 自定义模式状态提示
        Text('手动调整阈值设置')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .alignSelf(ItemAlign.Start)

        if (!this.currentConfig.timeSchedulingEnabled) {
          // 时段调度关闭：显示统一阈值滚动条
          this.buildThresholdSlider({
            title: '统一阈值',
            description: '全天使用的统一阈值',
            value: this.currentConfig.baseThreshold,
            onChange: (value: number) => {
              this.currentConfig.baseThreshold = value;
              this.updateConfig(this.currentConfig);
            },
            color: $r('sys.color.brand'),
            timeRange: '全天统一阈值'
          })
        } else {
          // 时段调度开启：显示白天和夜间阈值滚动条
          Column({ space: DesignConstants.SPACING_MD }) {
            this.buildThresholdSlider({
              title: '白天阈值',
              description: '适用于日常活动环境',
              value: this.currentConfig.daytimeThreshold,
              onChange: (value: number) => {
                this.currentConfig.daytimeThreshold = value;
                this.updateConfig(this.currentConfig);
              },
              color: $r('sys.color.brand'),
              timeRange: '6:00 - 22:00'
            })

            this.buildThresholdSlider({
              title: '夜间阈值',
              description: '适用于休息睡眠环境',
              value: this.currentConfig.nighttimeThreshold,
              onChange: (value: number) => {
                this.currentConfig.nighttimeThreshold = value;
                this.updateConfig(this.currentConfig);
              },
              color: $r('sys.color.brand'),
              timeRange: '22:00 - 6:00'
            })
          }
          .width('100%')
        }
      }
      .width('100%')
    } else {
      // 预设环境类型：显示当前阈值信息
      Column({ space: DesignConstants.SPACING_MD }) {
        // 预设环境状态提示
        Text(`当前使用${this.getPresetByType(this.currentConfig.currentPreset).name}预设阈值`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .alignSelf(ItemAlign.Start)

        if (!this.currentConfig.timeSchedulingEnabled) {
          // 时段调度关闭：显示统一阈值
          this.buildThresholdInfo({
            title: '统一阈值',
            value: `${this.currentConfig.baseThreshold}dB`,
            description: '全天使用的统一阈值',
            color: $r('sys.color.brand')
          })
        } else {
          // 时段调度开启：显示白天和夜间阈值
          Column({ space: DesignConstants.SPACING_MD }) {
            this.buildThresholdInfo({
              title: '白天阈值',
              value: `${this.currentConfig.daytimeThreshold}dB`,
              description: '适用于日常活动环境',
              color: $r('sys.color.brand')
            })

            this.buildThresholdInfo({
              title: '夜间阈值',
              value: `${this.currentConfig.nighttimeThreshold}dB`,
              description: '适用于休息睡眠环境',
              color: $r('sys.color.brand')
            })
          }
          .width('100%')
        }
      }
      .width('100%')
    }
  }

  // 构建阈值信息显示（无滚动条）
  @Builder
  private buildThresholdInfo(config: IThresholdInfoConfig) {
    Column({ space: DesignConstants.SPACING_SM }) {
      Row({ space: DesignConstants.SPACING_SM }) {
        Text(config.title)
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        Text(config.value)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(config.color)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(config.description)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  // 构建阈值滑动条
  @Builder
  private buildThresholdSlider(config: ISliderConfig) {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题行
      Row({ space: DesignConstants.SPACING_SM }) {
        Text(config.title)
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        Text(`${config.value}dB`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(config.color)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 时间范围
      Text(config.timeRange)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)

      // 滑动条
      Slider({
        value: config.value,
        min: 30,
        max: 120,
        step: 1,
        style: SliderStyle.InSet
      })
        .blockColor(config.color)
        .trackColor($r('sys.color.background_secondary'))
        .selectedColor(config.color)
        .onChange((newValue: number) => {
          this.logStateChange(`调整阈值: ${newValue}dB`);
          config.onChange(newValue);
          this.updateConfig(this.currentConfig);
        })
        .margin({
          top: DesignConstants.SPACING_MD,
          bottom: DesignConstants.SPACING_MD
        })
        .height(20)
        .trackThickness(20)
        .blockSize({ width: 20, height: 20 })

      // 描述
      Text(config.description)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  // 状态监控方法（用于调试）
  private logStateChange(action: string, newPreset?: PresetType): void {
    console.log(`[EnhancedThresholdManager] ${action}:`);
    console.log(`  - 当前环境类型: ${this.currentConfig.currentPreset}`);
    console.log(`  - 基准阈值: ${this.currentConfig.baseThreshold}dB`);
    console.log(`  - 时段调度: ${this.currentConfig.timeSchedulingEnabled ? '启用' : '禁用'}`);
    if (newPreset) {
      console.log(`  - 新环境类型: ${newPreset}`);
    }
  }

  // 根据类型获取预设
  private getPresetByType(presetType: PresetType): PresetThreshold {
    const presets: PresetConfig[] = [
      new PresetConfig(
        PresetType.QUIET_ENVIRONMENT,
        40,
        '安静环境',
        '图书馆、卧室等需要安静的环境',
        $r('sys.color.confirm')
      ),
      new PresetConfig(
        PresetType.GENERAL_ENVIRONMENT,
        55,
        '一般环境',
        '办公室、教室等日常环境',
        $r('sys.color.brand')
      ),
      new PresetConfig(
        PresetType.NOISY_ENVIRONMENT,
        70,
        '嘈杂环境',
        '街道、商场等嘈杂环境',
        $r('sys.color.alert')
      ),
      new PresetConfig(
        PresetType.DANGEROUS_ENVIRONMENT,
        85,
        '危险环境',
        '工厂、工地等可能损伤听力的环境',
        $r('sys.color.warning')
      ),
      new PresetConfig(
        PresetType.CUSTOM,
        60,
        '自定义',
        '手动设置阈值',
        $r('sys.color.ohos_id_color_palette1')
      )
    ];
    return presets.find(p => p.type === presetType)!;
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {

      // 统一的阈值设置面板（包含时段调度开关和环境类型选择）
      this.buildUnifiedThresholdPanel()

    }
    .width('100%')
    .backgroundColor($r('sys.color.background_secondary'))
    .alignItems(HorizontalAlign.Start)
  }
}

// 滑动条配置接口
interface ISliderConfig {
  title: string;
  description: string;
  value: number;
  onChange: (value: number) => void;
  color: Resource;
  timeRange: string;
}

// 阈值信息配置接口
interface IThresholdInfoConfig {
  title: string;
  value: string;
  description: string;
  color: Resource;
}