/**
 * 智能阈值预设组件
 * 提供基于声学标准的预设阈值选择
 */

import { PRESET_THRESHOLDS, ALERT_COLORS, PresetThreshold, SMART_LINKAGE_CONFIG, PRESET_MAPPING,
  DayNightTime } from '../../constants/AlertsConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { curves } from '@kit.ArkUI';

@ComponentV2
export struct SmartThresholdPresets {
  @Param @Require currentThreshold: number = 70; // 当前阈值
  @Param @Require currentPreset: string = 'custom'; // 当前预设
  @Param @Require onThresholdChange: (value: number) => void; // 阈值变化回调
  @Param @Require onPresetChange: (preset: string) => void; // 预设变化回调
  @Param @Require onDaytimeThresholdChange?: (value: number) => void; // 白天阈值变化回调（新增）
  @Param @Require onNighttimeThresholdChange?: (value: number) => void; // 夜间阈值变化回调（新增）
  @Local private isCustomMode: boolean = false; // 是否自定义模式
  @Local private customThreshold: number = 70; // 自定义阈值

  aboutToAppear() {
    this.customThreshold = this.currentThreshold;
    this.isCustomMode = this.currentPreset === 'custom';
  }

  // 检查是否为预设值
  private isPresetValue(value: number): boolean {
    return PRESET_THRESHOLDS.some(preset => preset.value === value);
  }

  // 获取当前预设名称
  private getCurrentPresetName(): string {
    if (this.isCustomMode) {
      return '自定义';
    }
    const preset = PRESET_THRESHOLDS.find(p => p.value === this.currentThreshold);
    return preset ? preset.name : '自定义';
  }

  // 构建预设选项
  @Builder
  private buildPresetOptions() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 预设选项标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('智能预设')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        Text(this.getCurrentPresetName())
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(ALERT_COLORS.PRIMARY)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 预设选项网格
      GridRow({
        columns: { sm: 2, md: 4 },
        breakpoints: { reference: BreakpointsReference.WindowSize },
        gutter: { x: DesignConstants.SPACING_SM, y: DesignConstants.SPACING_SM }
      }) {
        ForEach(PRESET_THRESHOLDS, (preset: PresetThreshold) => {
          GridCol({ span: 1 }) {
            this.buildPresetCard(preset)
          }
        })

        // 自定义选项
        GridCol({ span: 1 }) {
          this.buildCustomCard()
        }
      }
      .width('100%')
      .margin({ top: DesignConstants.SPACING_MD })
    }
  }

  // 计算时段调度阈值（智能联动）
  private calculateTimeSchedulingThresholds(baseThreshold: number): DayNightTime {
    let difference = 0;
    
    // 基于基准阈值智能计算差值
    if (baseThreshold <= 40) {
      difference = 5;  // 安静环境：差值较小
    } else if (baseThreshold <= 55) {
      difference = 10; // 一般环境：标准差值
    } else if (baseThreshold <= 70) {
      difference = 15; // 嘈杂环境：较大差值
    } else {
      difference = 20; // 危险环境：最大差值
    }
    
    return {
      daytime: baseThreshold + difference,
      nighttime: baseThreshold - difference
    };
  }

  // 构建预设卡片
  @Builder
  private buildPresetCard(preset: PresetThreshold) {

    Column({ space: DesignConstants.SPACING_XS }) {
      // 阈值数值
      Text(`${preset.value}dB`)
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor(!this.isCustomMode && this.currentThreshold === preset.value ? Color.White : preset.color)

      // 预设名称
      Text(preset.name)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor(!this.isCustomMode && this.currentThreshold === preset.value ? Color.White :
        $r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)

      // 描述
      Text(preset.description)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor(!this.isCustomMode && this.currentThreshold === preset.value ? Color.White :
        $r('sys.color.font_secondary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor(!this.isCustomMode && this.currentThreshold === preset.value ? preset.color :
    ALERT_COLORS.CARD_BACKGROUND)
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .border({
      width: !this.isCustomMode && this.currentThreshold === preset.value ? 2 : 1,
      color: !this.isCustomMode && this.currentThreshold === preset.value ? preset.color :
      $r('sys.color.background_secondary')
    })
    .onClick(() => {
      this.isCustomMode = false;
      const presetKey = preset.name.toLowerCase().replace(' ', '_');
      this.onPresetChange(presetKey);
      this.onThresholdChange(preset.value);
      
      // 智能联动：自动计算并更新时段调度阈值
      if (SMART_LINKAGE_CONFIG.ENABLED && this.onDaytimeThresholdChange && this.onNighttimeThresholdChange) {
        const thresholds = this.calculateTimeSchedulingThresholds(preset.value);
        this.onDaytimeThresholdChange(thresholds.daytime);
        this.onNighttimeThresholdChange(thresholds.nighttime);
      }
    })
    .animation({
      duration: 200,
      curve: curves.springMotion()
    })
  }

  // 构建自定义卡片
  @Builder
  private buildCustomCard() {

    Column({ space: DesignConstants.SPACING_XS }) {
      // 自定义图标
      Image($r('app.media.ic_settings'))
        .width(DesignConstants.ICON_SIZE_MD)
        .height(DesignConstants.ICON_SIZE_MD)
        .fillColor(this.isCustomMode ? Color.White : ALERT_COLORS.PRIMARY)

      // 自定义文本
      Text('自定义')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isCustomMode ? Color.White : ALERT_COLORS.PRIMARY)

      Text('手动设置阈值')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor(this.isCustomMode ? Color.White : $r('sys.color.font_secondary'))
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor(this.isCustomMode ? ALERT_COLORS.PRIMARY : ALERT_COLORS.CARD_BACKGROUND)
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .border({
      width: this.isCustomMode ? 2 : 1,
      color: this.isCustomMode ? ALERT_COLORS.PRIMARY : $r('sys.color.background_secondary')
    })
    .onClick(() => {
      this.isCustomMode = true;
      this.onPresetChange('custom');
    })
    .animation({
      duration: 200,
      curve: curves.springMotion()
    })
  }

  // 构建自定义阈值调节器
  @Builder
  private buildCustomThresholdSlider() {
    if (this.isCustomMode) {


      Column({ space: DesignConstants.SPACING_SM }) {
        // 标题
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('自定义阈值')
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
            .layoutWeight(1)

          Text(`${this.customThreshold}dB`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor(ALERT_COLORS.PRIMARY)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 滑动条
        Slider({
          value: this.customThreshold,
          min: 30,
          max: 120,
          step: 1,
          style: SliderStyle.InSet
        })
          .blockColor(ALERT_COLORS.PRIMARY)
          .trackColor($r('sys.color.background_secondary'))
          .selectedColor(ALERT_COLORS.PRIMARY)
          .onChange((value: number, mode: SliderChangeMode) => {
            this.customThreshold = value;
            if (mode === SliderChangeMode.End) {
              this.onThresholdChange(value);
            }
          })
          .margin({
            top: DesignConstants.SPACING_MD,
            bottom: DesignConstants.SPACING_MD
          })
          .height(24)
          .trackThickness(24)
          .blockSize({ width: 24, height: 24 })

        // 阈值范围说明
        Row({ space: DesignConstants.SPACING_MD }) {
          Text('30dB')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))

          Text('安静')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor(ALERT_COLORS.SUCCESS)

          Text('|')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_tertiary'))

          Text('70dB')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))

          Text('嘈杂')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor(ALERT_COLORS.WARNING)

          Text('|')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_tertiary'))

          Text('120dB')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))

          Text('危险')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor(ALERT_COLORS.ERROR)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .margin({ top: DesignConstants.SPACING_MD })
      .animation({
        duration: 300,
        curve: curves.springMotion()
      })
    }
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 预设选项
      this.buildPresetOptions()

      // 自定义阈值调节器
      this.buildCustomThresholdSlider()
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor(ALERT_COLORS.CARD_BACKGROUND)
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_SM)
  }
}