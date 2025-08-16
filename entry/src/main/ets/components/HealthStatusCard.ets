import { DeviceHealthInfo } from "../types/DeviceHealthInfo"

@ComponentV2
export struct HealthStatusCard {
  @Param @Require healthInfo: DeviceHealthInfo

  build() {
    Column() {
      // 健康度评分
      Row() {
        Image($r('app.media.ic_battery'))
          .width(24)
          .height(24)
        Text($r('app.string.device_health_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text(`${this.healthInfo.score}`)
          .fontSize(24)
          .fontColor(this.getScoreColor())
          .margin({left: 8})
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      // 健康度进度条
      Progress({
        value: this.healthInfo.score,
        type: ProgressType.Linear
      })
      .width('100%')
      .height(8)
      .style({
        strokeWidth: 8,
      }).color(this.getScoreColor())

      // 详细指标
      Grid() {
        GridItem() {
          this.HealthMetricItem($r('app.string.battery_label'), `${this.healthInfo.battery.level}%`, this.healthInfo.battery.health)
        }
        GridItem() {
          this.HealthMetricItem($r('app.string.cpu_label'), `${this.healthInfo.performance.cpu}%`, 100 - this.healthInfo.performance.cpu)
        }
        GridItem() {
          this.HealthMetricItem($r('app.string.memory_label'), `${this.getMemoryUsage()}%`, 100 - this.getMemoryUsage())
        }
        GridItem() {
          this.HealthMetricItem($r('app.string.storage_label'), `${this.getStorageUsage()}%`, 100 - this.getStorageUsage())
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
    }
    .padding(16)
  }

  @Builder
  HealthMetricItem(label: ResourceStr, value: string, score: number) {
    Column() {
      Text(label)
        .fontSize(14)
      Text(value)
        .fontSize(16)
        .fontColor(this.getMetricColor(score))
    }
  }

  private getScoreColor(): ResourceColor {
    if (this.healthInfo.score >= 80) return $r('app.color.health_good');
    if (this.healthInfo.score >= 60) return $r('app.color.health_warning');
    return $r('app.color.health_bad');
  }

  private getMetricColor(score: number): ResourceColor {
    if (score >= 80) return $r('app.color.health_good');
    if (score >= 60) return $r('app.color.health_warning');
    return $r('app.color.health_bad');
  }

  private getMemoryUsage(): number {
    const total = Number(this.healthInfo.performance.memory.totalMem);
    const used = total - Number(this.healthInfo.performance.memory.availableMem);
    return Math.round((used / total) * 100);
  }

  private getStorageUsage(): number {
    const total = this.healthInfo.performance.storage.total;
    const used = this.healthInfo.performance.storage.used;
    return Math.round((used / total) * 100);
  }
}