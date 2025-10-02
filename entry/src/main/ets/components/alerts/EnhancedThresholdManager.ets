/**
 * 增强型阈值管理组件
 * 实现分层架构的阈值管理界面
 */

import { ThresholdMode, PresetType, ThresholdConfig, PresetThreshold } from '../../models/ThresholdConfig';
import { thresholdManager } from '../../services/ThresholdManager';
import { DesignConstants } from '../../constants/DesignConstants';
import { curves } from '@kit.ArkUI';

@ObservedV2
class ThresholdOption {
  @Trace value: ThresholdMode;
  @Trace label: string;
  @Trace description: string;

  constructor(value: ThresholdMode, label: string, description: string) {
    this.value = value;
    this.label = label;
    this.description = description;
  }
}

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
  @Local private currentConfig: ThresholdConfig = thresholdManager.getCurrentConfig();
  @Local private modeOptions: ThresholdOption[] = [
    new ThresholdOption(ThresholdMode.SMART_PRESET, '智能预设', '基于环境类型自动设置阈值'),
    new ThresholdOption(ThresholdMode.TIME_SCHEDULING, '时段调度', '独立设置白天和夜间阈值'),
    new ThresholdOption(ThresholdMode.CUSTOM, '自定义', '完全手动控制所有阈值')
  ];

  // 构建模式选择器
  @Builder
  private buildModeSelector() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('阈值管理模式')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      ForEach(this.modeOptions, (option: ThresholdOption) => {
        this.buildModeOption(option)
      })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_SM)
  }

  // 构建模式选项
  @Builder
  private buildModeOption(option: ThresholdOption) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 选择指示器
      Circle({ width: 20, height: 20 })
        .fill(this.currentConfig.mode === option.value ?
        $r('sys.color.ohos_id_color_palette1') :
        $r('sys.color.background_secondary'))
        .border({
          width: 2,
          color: this.currentConfig.mode === option.value ?
          $r('sys.color.ohos_id_color_palette1') :
          $r('sys.color.font_tertiary')
        })

      Column({ space: DesignConstants.SPACING_XS }) {
        Text(option.label)
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        Text(option.description)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
          .alignSelf(ItemAlign.Start)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor(this.currentConfig.mode === option.value ?
    $r('sys.color.background_secondary') :
    $r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .onClick(() => {
      if (this.currentConfig.mode !== option.value) {
        this.logStateChange('切换模式', option.value);
        this.currentConfig = thresholdManager.switchMode(option.value);
      }
    })
    .animation({
      duration: 200,
      curve: curves.springMotion()
    })
  }

  // 构建智能预设面板
  @Builder
  private buildSmartPresetPanel() {
    if (this.currentConfig.mode === ThresholdMode.SMART_PRESET) {
      Column({ space: DesignConstants.SPACING_MD }) {
        Text('智能预设')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        // 预设选项网格
        GridRow({
          columns: { sm: 2, md: 4 },
          breakpoints: { reference: BreakpointsReference.WindowSize },
          gutter: { x: DesignConstants.SPACING_SM, y: DesignConstants.SPACING_SM }
        }) {
          ForEach([
            PresetType.QUIET_ENVIRONMENT,
            PresetType.GENERAL_ENVIRONMENT,
            PresetType.NOISY_ENVIRONMENT,
            PresetType.DANGEROUS_ENVIRONMENT
          ], (presetType: PresetType) => {
            GridCol({ span: 1 }) {
              this.buildPresetCard(presetType, this.getPresetByType(presetType))
            }
          })
        }
        .width('100%')
        .margin({ top: DesignConstants.SPACING_MD })

        // 时段调度开关
        this.buildTimeSchedulingSwitch()

        // 当前阈值显示
        this.buildCurrentThresholdDisplay()
      }
      .width('100%')
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .shadow(DesignConstants.SHADOW_SM)
      .margin({ top: DesignConstants.SPACING_LG })
    }
  }

  // 构建预设卡片
  @Builder
  private buildPresetCard(presetType: PresetType, preset: PresetThreshold) {
    if (preset) {
      Column({ space: DesignConstants.SPACING_XS }) {
        Text(`${preset.baseValue}dB`)
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.currentConfig.currentPreset === presetType ? Color.White : preset.color)

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
        this.logStateChange('选择预设', undefined, presetType);
        this.currentConfig = thresholdManager.selectPreset(presetType);
      })
      .animation({
        duration: 200,
        curve: curves.springMotion()
      })
    }
  }

  // 构建时段调度开关
  @Builder
  private buildTimeSchedulingSwitch() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('时段调度')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.currentConfig.timeSchedulingEnabled })
          .onChange((isOn: boolean) => {
            this.logStateChange(`切换时段调度: ${isOn ? '启用' : '禁用'}`);
            this.currentConfig = thresholdManager.setTimeSchedulingEnabled(isOn);
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.currentConfig.timeSchedulingEnabled ?
        '已启用时段调度，白天和夜间使用不同阈值' :
        '时段调度已关闭，全天使用统一阈值')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .margin({ top: DesignConstants.SPACING_MD })
  }

  // 构建时段调度面板
  @Builder
  private buildTimeSchedulingPanel() {
    if (this.currentConfig.mode === ThresholdMode.TIME_SCHEDULING) {
      Column({ space: DesignConstants.SPACING_MD }) {
        Text('时段调度设置')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        // 时段调度开关
        this.buildTimeSchedulingSwitch()

        // 白天阈值设置
        this.buildThresholdSlider(
          '白天阈值',
          '适用于日常活动环境',
          this.currentConfig.daytimeThreshold,
          (value: number) => {
            this.currentConfig = thresholdManager.setDaytimeThreshold(value);
          },
          $r('sys.color.ohos_id_color_palette3'), // 黄色
          '6:00 - 22:00'
        )

        // 夜间阈值设置
        this.buildThresholdSlider(
          '夜间阈值',
          '适用于休息睡眠环境',
          this.currentConfig.nighttimeThreshold,
          (value: number) => {
            this.currentConfig = thresholdManager.setNighttimeThreshold(value);
          },
          $r('sys.color.ohos_id_color_palette6'), // 深蓝色
          '22:00 - 6:00'
        )

        // 当前时段状态
        this.buildCurrentPeriodStatus()
      }
      .width('100%')
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .shadow(DesignConstants.SHADOW_SM)
      .margin({ top: DesignConstants.SPACING_LG })
    }
  }

  // 构建自定义面板
  @Builder
  private buildCustomPanel() {
    if (this.currentConfig.mode === ThresholdMode.CUSTOM) {
      Column({ space: DesignConstants.SPACING_MD }) {
        Text('自定义设置')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        // 基准阈值设置
        this.buildThresholdSlider(
          '基准阈值',
          '时段调度关闭时的统一阈值',
          this.currentConfig.baseThreshold,
          (value: number) => {
            this.currentConfig = thresholdManager.setBaseThreshold(value);
          },
          $r('sys.color.ohos_id_color_palette1'), // 主色
          '全天统一阈值'
        )

        // 时段调度开关
        this.buildTimeSchedulingSwitch()

        // 时段阈值设置（仅在时段调度启用时显示）
        if (this.currentConfig.timeSchedulingEnabled) {
          Column({ space: DesignConstants.SPACING_MD }) {
            this.buildThresholdSlider(
              '白天阈值',
              '适用于日常活动环境',
              this.currentConfig.daytimeThreshold,
              (value: number) => {
                this.currentConfig = thresholdManager.setDaytimeThreshold(value);
              },
              $r('sys.color.ohos_id_color_palette3'), // 黄色
              '6:00 - 22:00'
            )

            this.buildThresholdSlider(
              '夜间阈值',
              '适用于休息睡眠环境',
              this.currentConfig.nighttimeThreshold,
              (value: number) => {
                this.currentConfig = thresholdManager.setNighttimeThreshold(value);
              },
              $r('sys.color.ohos_id_color_palette6'), // 深蓝色
              '22:00 - 6:00'
            )
          }
          .width('100%')
        }

        // 当前阈值显示
        this.buildCurrentThresholdDisplay()
      }
      .width('100%')
      .padding(DesignConstants.SPACING_LG)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .shadow(DesignConstants.SHADOW_SM)
      .margin({ top: DesignConstants.SPACING_LG })
    }
  }

  // 构建阈值滑动条
  @Builder
  private buildThresholdSlider(
    title: string,
    description: string,
    value: number,
    onChange: (value: number) => void,
    color: Resource,
    timeRange: string
  ) {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题行
      Row({ space: DesignConstants.SPACING_SM }) {
        Text(title)
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        Text(`${value}dB`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(color)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 时间范围
      Text(timeRange)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)

      // 滑动条
      Slider({
        value: value,
        min: 30,
        max: 120,
        step: 1,
        style: SliderStyle.InSet
      })
        .blockColor(color)
        .trackColor($r('sys.color.background_secondary'))
        .selectedColor(color)
        .onChange((newValue: number) => {
          this.logStateChange(`调整阈值: ${newValue}dB`);
          onChange(newValue);
        })
        .margin({
          top: DesignConstants.SPACING_MD,
          bottom: DesignConstants.SPACING_MD
        })
        .height(20)
        .trackThickness(20)
        .blockSize({ width: 20, height: 20 })

      // 描述
      Text(description)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  // 构建当前时段状态
  @Builder
  private buildCurrentPeriodStatus() {
    Column({ space: DesignConstants.SPACING_XS }) {
      Row({ space: DesignConstants.SPACING_SM }) {
        Circle({ width: 8, height: 8 })
          .fill(thresholdManager.getCurrentTimePeriod() === '白天' ?
          $r('sys.color.ohos_id_color_palette3') :
          $r('sys.color.ohos_id_color_palette6'))

        Text(thresholdManager.getCurrentTimePeriod())
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        Text(`当前阈值: ${thresholdManager.getCurrentEffectiveThreshold()}dB`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.ohos_id_color_palette1'))
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(thresholdManager.getCurrentTimePeriod() === '白天' ?
        '白天时段 6:00 - 22:00' :
        '夜间时段 22:00 - 6:00')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .margin({ top: DesignConstants.SPACING_MD })
  }

  // 构建当前阈值显示
  @Builder
  private buildCurrentThresholdDisplay() {
    Column({ space: DesignConstants.SPACING_XS }) {
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('当前有效阈值')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        Text(`${thresholdManager.getCurrentEffectiveThreshold()}dB`)
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.ohos_id_color_palette1'))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(`基于${thresholdManager.getCurrentTimePeriod()}时段设置`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .margin({ top: DesignConstants.SPACING_MD })
  }

  // 状态监控方法（用于调试）
  private logStateChange(action: string, newMode?: ThresholdMode, newPreset?: PresetType): void {
    console.log(`[EnhancedThresholdManager] ${action}:`);
    console.log(`  - 当前模式: ${this.currentConfig.mode}`);
    console.log(`  - 当前预设: ${this.currentConfig.currentPreset}`);
    console.log(`  - 基准阈值: ${this.currentConfig.baseThreshold}dB`);
    console.log(`  - 时段调度: ${this.currentConfig.timeSchedulingEnabled ? '启用' : '禁用'}`);
    if (newMode) {
      console.log(`  - 新模式: ${newMode}`);
    }
    if (newPreset) {
      console.log(`  - 新预设: ${newPreset}`);
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
        $r('sys.color.ohos_id_color_palette2')
      ),
      new PresetConfig(
        PresetType.GENERAL_ENVIRONMENT,
        55,
        '一般环境',
        '办公室、教室等日常环境',
        $r('sys.color.ohos_id_color_palette5')
      ),
      new PresetConfig(
        PresetType.NOISY_ENVIRONMENT,
        70,
        '嘈杂环境',
        '街道、商场等嘈杂环境',
        $r('sys.color.ohos_id_color_palette3')
      ),
      new PresetConfig(
        PresetType.DANGEROUS_ENVIRONMENT,
        85,
        '危险环境',
        '工厂、工地等可能损伤听力的环境',
        $r('sys.color.ohos_id_color_palette4')
      )
    ];
    return presets.find(p => p.type === presetType)!;
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 模式选择器
      this.buildModeSelector()

      // 智能预设面板
      this.buildSmartPresetPanel()

      // 时段调度面板
      this.buildTimeSchedulingPanel()

      // 自定义面板
      this.buildCustomPanel()
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.background_secondary'))
    .alignItems(HorizontalAlign.Start)
  }
}