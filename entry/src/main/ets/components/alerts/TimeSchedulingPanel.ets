/**
 * 时段调度面板组件
 * 提供白天/夜间不同阈值的调度设置
 */

import { ALERT_COLORS, TIME_PERIOD_CONFIG } from '../../constants/AlertsConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { curves } from '@kit.ArkUI';

@ComponentV2
export struct TimeSchedulingPanel {
  @Param @Require isEnabled: boolean = false; // 时段调度是否启用
  @Param @Require daytimeThreshold: number = 70; // 白天阈值
  @Param @Require nighttimeThreshold: number = 50; // 夜间阈值
  @Param @Require onEnabledChange: (enabled: boolean) => void; // 启用状态变化回调
  @Param @Require onDaytimeThresholdChange: (value: number) => void; // 白天阈值变化回调
  @Param @Require onNighttimeThresholdChange: (value: number) => void; // 夜间阈值变化回调
  @Local private currentTime: Date = new Date(); // 当前时间
  private timeInterval?: number; // 时间更新定时器

  // 获取当前时段
  private getCurrentTimePeriod(): string {
    const hours = this.currentTime.getHours();
    if (hours >= TIME_PERIOD_CONFIG.DAYTIME_START && hours < TIME_PERIOD_CONFIG.DAYTIME_END) {
      return 'daytime';
    } else {
      return 'nighttime';
    }
  }

  // 获取当前时段描述
  private getCurrentTimePeriodDescription(): string {
    const period = this.getCurrentTimePeriod();
    return period === 'daytime' ? '白天时段' : '夜间时段';
  }

  // 获取当前有效阈值
  private getCurrentEffectiveThreshold(): number {
    if (!this.isEnabled) {
      return Math.max(this.daytimeThreshold, this.nighttimeThreshold);
    }

    const period = this.getCurrentTimePeriod();
    return period === 'daytime' ? this.daytimeThreshold : this.nighttimeThreshold;
  }

  // 构建时段调度开关
  @Builder
  private buildSchedulingSwitch() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_time_weighting'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.font_primary'))

        Text('时段调度')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.isEnabled })
          .onChange((isOn: boolean) => {
            this.onEnabledChange(isOn);
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.isEnabled ?
        '已启用时段调度，白天和夜间使用不同阈值' :
        '时段调度已关闭，全天使用统一阈值')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Start)
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
  }

  // 构建当前时段状态
  @Builder
  private buildCurrentPeriodStatus() {
    if (this.isEnabled) {


      Column({ space: DesignConstants.SPACING_XS }) {
        Row({ space: DesignConstants.SPACING_SM }) {
          Circle({ width: 8, height: 8 })
            .fill(this.getCurrentTimePeriod() === 'daytime' ?
            ALERT_COLORS.WARNING :
            $r('sys.color.ohos_id_color_palette6')) // 深蓝色

          Text(this.getCurrentTimePeriodDescription())
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))

          Text(`当前阈值: ${this.getCurrentEffectiveThreshold()}dB`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor(ALERT_COLORS.PRIMARY)
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(this.getCurrentTimePeriod() === 'daytime' ?
          `白天时段 ${TIME_PERIOD_CONFIG.DAYTIME_START}:00 - ${TIME_PERIOD_CONFIG.DAYTIME_END}:00` :
          `夜间时段 ${TIME_PERIOD_CONFIG.NIGHTTIME_START}:00 - ${TIME_PERIOD_CONFIG.NIGHTTIME_END}:00`)
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
  }

  // 构建时段阈值设置
  @Builder
  private buildPeriodThresholdSettings() {
    if (this.isEnabled) {
      Column({ space: DesignConstants.SPACING_LG }) {
        // 白天阈值设置
        this.buildThresholdSlider(
          '白天阈值',
          '适用于日常活动环境',
          this.daytimeThreshold,
          (value: number) => {
            this.onDaytimeThresholdChange(value);
          },
          ALERT_COLORS.WARNING,
          `${TIME_PERIOD_CONFIG.DAYTIME_START}:00 - ${TIME_PERIOD_CONFIG.DAYTIME_END}:00`
        )

        // 夜间阈值设置
        this.buildThresholdSlider(
          '夜间阈值',
          '适用于休息睡眠环境',
          this.nighttimeThreshold,
          (value: number) => {
            this.onNighttimeThresholdChange(value);
          },
          $r('sys.color.ohos_id_color_palette6'), // 深蓝色
          `${TIME_PERIOD_CONFIG.NIGHTTIME_START}:00 - ${TIME_PERIOD_CONFIG.NIGHTTIME_END}:00`
        )
      }
      .width('100%')
      .margin({ top: DesignConstants.SPACING_MD })
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
          .fontWeight(FontWeight.Bold)
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
        max: 100,
        step: 1,
        style: SliderStyle.InSet
      })
        .blockColor(color)
        .trackColor($r('sys.color.background_secondary'))
        .selectedColor(color)
        .onChange((newValue: number) => {
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
        .textAlign(TextAlign.Start)
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  // 启动时间更新定时器
  private startTimeUpdate() {
    this.timeInterval = setInterval(() => {
      this.currentTime = new Date();
    }, 60000); // 每分钟更新一次
  }

  // 停止时间更新定时器
  private stopTimeUpdate() {
    if (this.timeInterval) {
      clearInterval(this.timeInterval);
      this.timeInterval = undefined;
    }
  }

  aboutToAppear() {
    this.startTimeUpdate();
  }

  aboutToDisappear() {
    this.stopTimeUpdate();
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 时段调度开关
      this.buildSchedulingSwitch()

      // 当前时段状态
      this.buildCurrentPeriodStatus()

      // 时段阈值设置
      this.buildPeriodThresholdSettings()
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor(ALERT_COLORS.CARD_BACKGROUND)
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_SM)
  }
}