import router from '@ohos.router';
import { hidebug } from '@kit.PerformanceAnalysisKit';
import { SystemMemInfo } from '../../types/DeviceInfo';
import { formatMemory } from '../../utils/MemoryUtils';
import { DeviceHealthInfo } from '../../types/DeviceHealthInfo';
import { DeviceHealthService } from '../../services/DeviceHealthService';
import { HealthStatusCard } from '../../components/HealthStatusCard';
import { netQuality } from '@kit.NetworkBoostKit';

@Extend(Text)
function titleTextStyle() {
  .fontSize(20)
  .fontWeight(FontWeight.Medium)
  .fontColor($r('app.color.text_primary'))
}

@Extend(Text)
function cardTitleStyle() {
  .fontSize(16)
  .fontWeight(FontWeight.Medium)
  .fontColor($r('app.color.text_primary'))
}

@Extend(Text)
function cardValueStyle() {
  .fontSize(24)
  .fontWeight(FontWeight.Bold)
  .fontColor($r('app.color.text_primary'))
}

@Extend(Text)
function gridItemTextStyle() {
  .fontSize(14)
  .fontColor($r('app.color.text_secondary'))
  .margin({ top: 8 })
}

@ComponentV2
export struct DeviceManagerPage {
  @Local memoryInfo: SystemMemInfo | null = null;
  @Local rotateAngle: number = 0;
  @Local usagePercent: number = 0;
  @Local progressColor: Resource = $r('app.color.success');
  private deviceHealthService: DeviceHealthService = DeviceHealthService.getInstance();

  aboutToAppear() {
    this.getSystemMemoryInfo();
    setInterval(() => {
      this.getSystemMemoryInfo();
    }, 5000);

    // 动画效果
    animateTo({ duration: 1000 }, () => {
      this.rotateAngle = 360;
    });
  }

  aboutToDisappear(): void {
    netQuality.off('netQosChange');
  }

  // 获取系统内存信息
  private async getSystemMemoryInfo() {
    const rawData = hidebug.getSystemMemInfo();
    this.memoryInfo = {
      totalMem: rawData.totalMem,
      freeMem: rawData.freeMem,
      availableMem: rawData.availableMem
    };

    // 计算初始值
    if (this.memoryInfo) {
      const usedMem = Number(this.memoryInfo.totalMem - this.memoryInfo.availableMem);
      const totalMem = Number(this.memoryInfo.totalMem);
      this.deviceHealthService
        .getHealthInfo()
        .performance
        .memory
        .availableMem = this.memoryInfo.availableMem;
      this.deviceHealthService
        .getHealthInfo()
        .performance
        .memory
        .totalMem = this.memoryInfo.totalMem;
      let usageString = (usedMem / totalMem * 100).toFixed(1);
      if (usageString.includes(".")) {
        usageString = usageString.substring(0, usageString.indexOf("."));
      }
      this.usagePercent = Number(usageString);
      this.progressColor = this.usagePercent > 80 ? $r('app.color.health_bad') :
        this.usagePercent > 60 ? $r('app.color.health_warning') : $r('app.color.success');
    }
  }

  @Builder
  MemoryDetailItem(label: string, value: string, icon: Resource) {
    Row() {
      Image(icon)
        .width(20)
        .height(20)
        .margin({ right: 8 })
      Text(label)
        .fontSize(14)
        .layoutWeight(1)
      Text(value)
        .fontSize(14)
        .fontColor($r('app.color.primary'))
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  buildMemoryInfo() {
    if (this.memoryInfo) {
      Column() {
        // 标题栏
        Row() {
          Image($r('app.media.ic_storage'))
            .width(24)
            .height(24)
            .margin({ right: 8 })
          Text('内存使用情况')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .margin({ bottom: 12 })

        // 内存卡片
        Column() {
          // 环形进度条
          Stack() {
            Progress({
              value: this.usagePercent,
              type: ProgressType.Ring,
            })
              .width(80)
              .height(80)
              .style({
                strokeWidth: 8,
              })
              .backgroundColor($r('app.color.background_secondary'))
              .color(this.progressColor)
              .rotate({ angle: this.rotateAngle })

            Column() {
              Text(`${this.usagePercent}%`)
                .fontSize(18)
                .fontColor(this.progressColor)
              Text('已使用')
                .fontSize(10)
                .fontColor($r('app.color.text_secondary'))
            }
          }
          .margin({ top: 8, bottom: 12 })

          // 内存详情
          Column() {
            this.MemoryDetailItem('可用内存', formatMemory(this.memoryInfo.availableMem), $r('app.media.ic_security'))
            this.MemoryDetailItem('已使用',
              formatMemory(BigInt(Number(this.memoryInfo.totalMem - this.memoryInfo.availableMem))),
              $r('app.media.ic_battery'))
            this.MemoryDetailItem('总内存', formatMemory(this.memoryInfo.totalMem), $r('app.media.ic_storage'))
          }
          .width('100%')
        }
        .padding(8)
        .borderRadius(8)
        .backgroundColor($r('app.color.white'))
        .shadow({
          radius: 6,
          color: $r('app.color.shadow_light'),
          offsetX: 0,
          offsetY: 2
        })
      }
      .width('100%')
      .padding(16)
    }
  }

  @Builder
  GridItemBuilder(icon: Resource, label: string, targetPage: string) {
    Column() {
      Image(icon)
        .width(32)
        .height(32)
      Text(label)
        .gridItemTextStyle()
    }
    .onClick(() => {
      router.pushUrl({
        url: targetPage
      }, router.RouterMode.Standard, (err) => {
        if (err) {
          console.error(`Failed to navigate to ${targetPage}: ${JSON.stringify(err)}`);
        }
      });
    })
  }

  build() {
    Column() {
      // 健康度卡片
      HealthStatusCard({ memoryUsagePercentage: this.usagePercent })

    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
  }
}