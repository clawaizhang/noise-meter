import { DeviceHealthInfo, ScoreHealth } from "../types/DeviceHealthInfo"
import { LengthUnit } from "@kit.ArkUI"
import { DeviceHealthService } from "../services/DeviceHealthService"

@ComponentV2
export struct HealthStatusCard {
  @Param @Require memoryUsagePercentage: number
  @Local healthInfo: DeviceHealthInfo = DeviceHealthService.getInstance().getHealthInfo();

  build() {
    Flex({
      wrap: FlexWrap.Wrap,
      alignContent: FlexAlign.Center,
      space: { main: { value: 32, unit: LengthUnit.VP }, cross: { value: 32, unit: LengthUnit.VP } }
    }) {
      // 健康度环形进度条
      Stack() {
        Progress({
          value: this.healthInfo.score,
          type: ProgressType.Ring
        })
          .width(200)
          .height(200)
          .style({
            strokeWidth: 20,
            scaleWidth: 6,
          })
          .color(this.getScoreColor())
          .backgroundColor($r('app.color.background_tertiary'))
          .animation({
            duration: 1000,
            curve: Curve.EaseOut
          })

        Text(`${this.healthInfo.score}分`)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getScoreColor())
      }
      .margin({ bottom: 24 })
      .width('100%')
      .height(140)

      // 详细指标 - 环形进度条布局
      Flex({
        wrap: FlexWrap.Wrap,
        space: { main: { value: 8, unit: LengthUnit.VP }, cross: { value: 8, unit: LengthUnit.VP } },
        alignContent: FlexAlign.Center,
        justifyContent: FlexAlign.Center,
        alignItems: ItemAlign.Center
      }) {
        // 网络质量
        Stack() {
          Progress({
            value: this.healthInfo.network.signalStrength * 25,
            type: ProgressType.Ring
          })
            .width(120)
            .height(120)
            .style({
              strokeWidth: 12,
              scaleWidth: 4,
            })
            .color(this.getMetricColor(this.healthInfo.network.signalStrength * 25))
            .backgroundColor($r('app.color.background_tertiary'))
            .animation({
              duration: 1000,
              curve: Curve.EaseOut
            })

          Column() {
            Image($r('app.media.ic_security'))
              .width(16)
              .height(16)
              .margin({ bottom: 4 })
            Text($r('app.string.network_label'))
              .fontSize(10)
              .fontColor($r('app.color.text_secondary'))
            Text(`${this.healthInfo.network.signalStrength}/4`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getMetricColor(this.healthInfo.network.signalStrength * 25))
          }
        }
        .width(120)
        .height(120)

        // 传感器状态
        Stack() {
          Progress({
            value: this.healthInfo.sensors.status === 'normal' ? 100 :
                   this.healthInfo.sensors.status === 'warning' ? 60 : 30,
            type: ProgressType.Ring
          })
            .width(120)
            .height(120)
            .style({
              strokeWidth: 12,
              scaleWidth: 4,
            })
            .color(this.getMetricColor(
              this.healthInfo.sensors.status === 'normal' ? 100 :
              this.healthInfo.sensors.status === 'warning' ? 60 : 30
            ))
            .backgroundColor($r('app.color.background_tertiary'))
            .animation({
              duration: 1000,
              curve: Curve.EaseOut
            })

          Column() {
            Image($r('app.media.ic_meter'))
              .width(16)
              .height(16)
              .margin({ bottom: 4 })
            Text($r('app.string.sensors_label'))
              .fontSize(10)
              .fontColor($r('app.color.text_secondary'))
            Text(this.healthInfo.sensors.status === 'normal' ? '正常' :
                 this.healthInfo.sensors.status === 'warning' ? '警告' : '错误')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getMetricColor(
                this.healthInfo.sensors.status === 'normal' ? 100 :
                this.healthInfo.sensors.status === 'warning' ? 60 : 30
              ))
          }
        }
        .width(120)
        .height(120)

        // 电池健康度
        Stack() {
          Progress({
            value: this.healthInfo.battery.level,
            type: ProgressType.Ring
          })
            .width(120)
            .height(120)
            .style({
              strokeWidth: 12,
              scaleWidth: 4,
            })
            .color(this.getMetricColor(this.healthInfo.battery.health))
            .backgroundColor($r('app.color.background_tertiary'))
            .animation({
              duration: 1000,
              curve: Curve.EaseOut
            })

          Column() {
            Image($r('app.media.ic_battery'))
              .width(16)
              .height(16)
              .margin({ bottom: 4 })
            Text($r('app.string.battery_label'))
              .fontSize(10)
              .fontColor($r('app.color.text_secondary'))
            Text(this.healthInfo.battery.level + '%')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getMetricColor(this.healthInfo.battery.health))
          }
        }
        .width(120)
        .height(120)

        // CPU使用率
        Stack() {
          Progress({
            value: this.healthInfo.performance.cpu,
            type: ProgressType.Ring
          })
            .width(120)
            .height(120)
            .style({
              strokeWidth: 12,
              scaleWidth: 4,
            })
            .color(this.getMetricColor(100 - this.healthInfo.performance.cpu))
            .backgroundColor($r('app.color.background_tertiary'))
            .animation({
              duration: 1000,
              curve: Curve.EaseOut
            })

          Column() {
            Image($r('app.media.ic_meter'))
              .width(16)
              .height(16)
              .margin({ bottom: 4 })
            Text($r('app.string.cpu_label'))
              .fontSize(10)
              .fontColor($r('app.color.text_secondary'))
            Text(`${(this.healthInfo.performance.cpu).toFixed(1)}%`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getMetricColor(100 - this.healthInfo.performance.cpu))
          }
        }
        .width(120)
        .height(120)

        // 内存使用率
        Stack() {
          Progress({
            value: 100 - Number(this.memoryUsagePercentage.toFixed(1)),
            type: ProgressType.Ring
          })
            .width(120)
            .height(120)
            .style({
              strokeWidth: 12,
              scaleWidth: 4,
            })
            .color(this.getMetricColor(this.memoryUsagePercentage))
            .backgroundColor($r('app.color.background_tertiary'))
            .animation({
              duration: 1000,
              curve: Curve.EaseOut
            })

          Column() {
            Image($r('app.media.ic_storage'))
              .width(16)
              .height(16)
              .margin({ bottom: 4 })
            Text($r('app.string.memory_label'))
              .fontSize(10)
              .fontColor($r('app.color.text_secondary'))
            Text(`${100-this.memoryUsagePercentage}%`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getMetricColor(this.memoryUsagePercentage))
          }
        }
        .width(120)
        .height(120)

        // 存储使用率
        Stack() {
          Progress({
            value: Math.round((this.healthInfo.performance.storage.used / this.healthInfo.performance.storage.total) *
              100),
            type: ProgressType.Ring
          })
            .width(120)
            .height(120)
            .style({
              strokeWidth: 12,
              scaleWidth: 4,
            })
            .color(this.getMetricColor(100 -
            Math.round((this.healthInfo.performance.storage.used / this.healthInfo.performance.storage.total) * 100)))
            .backgroundColor($r('app.color.background_tertiary'))
            .animation({
              duration: 1000,
              curve: Curve.EaseOut
            })

          Column() {
            Image($r('app.media.ic_storage'))
              .width(16)
              .height(16)
              .margin({ bottom: 4 })
            Text($r('app.string.storage_label'))
              .fontSize(10)
              .fontColor($r('app.color.text_secondary'))
            Text(`${Math.round((this.healthInfo.performance.storage.used / this.healthInfo.performance.storage.total) *
              100)}%`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getMetricColor(100 -
              Math.round((this.healthInfo.performance.storage.used / this.healthInfo.performance.storage.total) * 100)))
          }
        }
        .width(120)
        .height(120)

      }
    }
    .margin({ top: 32 })
    .padding(24)
    .backgroundColor($r('app.color.background_primary'))
    .borderRadius(16)
    .shadow({
      radius: 12,
      color: $r('app.color.shadow_light'),
      offsetX: 0,
      offsetY: 4
    })
    .width('100%')
  }

  @LocalBuilder
  HealthMetricItem($$: ScoreHealth) {
    Column() {
      Image($$.icon)
        .width(20)
        .height(20)
        .margin({ right: 8 })
      Column() {
        Text($$.label)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
        Text($$.value)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getMetricColor($$.score))
      }
      .alignItems(HorizontalAlign.Start)
    }
    .padding(12)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(12)
    .width(120)
    .height(80)
  }

  private getScoreColor(): ResourceColor {
    if (this.healthInfo.score >= 80) {
      return $r('app.color.health_good');
    }
    if (this.healthInfo.score >= 60) {
      return $r('app.color.health_warning');
    }
    return $r('app.color.health_bad');
  }

  private getMetricColor(score: number): ResourceColor {
    if (score >= 80) {
      return $r('app.color.health_good');
    }
    if (score >= 60) {
      return $r('app.color.health_warning');
    }
    return $r('app.color.health_bad');
  }

  private getMemoryUsage(): number {
    const total = Number(this.healthInfo.performance.memory.totalMem);
    const used =
      Number(this.healthInfo.performance.memory.totalMem) - Number(this.healthInfo.performance.memory.availableMem);
    return Math.round((Number(this.healthInfo.performance.memory.totalMem) -
      Number(this.healthInfo.performance.memory.availableMem) / Number(this.healthInfo.performance.memory.totalMem)) *
      100);
  }

  private getStorageUsage(): number {
    const total = this.healthInfo.performance.storage.total;
    const used = this.healthInfo.performance.storage.used;
    return Math.round((this.healthInfo.performance.storage.used / this.healthInfo.performance.storage.total) * 100);
  }
}