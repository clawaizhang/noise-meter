import router from '@ohos.router';
import { hidebug } from '@kit.PerformanceAnalysisKit';
import { SystemMemInfo } from '../../types/DeviceInfo';
import { formatMemory } from '../../utils/MemoryUtils';
import { DeviceHealthInfo } from '../../types/DeviceHealthInfo';
import { DeviceHealthService } from '../../services/DeviceHealthService';
import { HealthStatusCard } from '../../components/HealthStatusCard';
import { RatingPanel } from '../../components/RatingPanel';
import { FunctionLinksPanel } from '../../components/FunctionLinksPanel';
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
      const usedMem = Number(this.memoryInfo.totalMem - this.memoryInfo.freeMem);
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
      // 简化百分比计算，直接取整避免不必要的小数处理
      this.usagePercent = Math.round(usedMem / totalMem * 100);
      this.progressColor = this.usagePercent > 80 ? $r('app.color.health_bad') :
        this.usagePercent > 60 ? $r('app.color.health_warning') : $r('app.color.success');
    }
  }

  // 计算设备综合评分
  private calculateDeviceScore(): number {
    const healthInfo = this.deviceHealthService.getHealthInfo();
    
    // 如果健康信息无效，返回默认评分
    if (!healthInfo || healthInfo.score === 0) {
      return 85; // 默认良好评分
    }

    // 基于健康状态数据的评分计算逻辑
    let score = healthInfo.score;

    // 根据内存使用率调整评分
    if (this.usagePercent > 90) {
      score -= 15; // 内存使用率过高，扣分
    } else if (this.usagePercent > 80) {
      score -= 10; // 内存使用率较高，扣分
    } else if (this.usagePercent > 70) {
      score -= 5;  // 内存使用率中等，轻微扣分
    }

    // 确保评分在0-100范围内
    return Math.max(0, Math.min(100, Math.round(score)));
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
    Scroll() {
      Column() {
        // 设备评分面板 - 放在健康状态卡片上方
        Column() {
          Text($r('app.string.device_score_title'))
            .cardTitleStyle()
            .margin({ bottom: 12 })
            .width('100%')
            .textAlign(TextAlign.Center)
          
          RatingPanel({ score: this.calculateDeviceScore() })
            .width('100%')
        }
        .margin({ bottom: 24 })
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        // 健康度卡片
        Column() {
          Text($r('app.string.health_status_title'))
            .cardTitleStyle()
            .margin({ bottom: 12 })
            .width('100%')
            .textAlign(TextAlign.Center)
          
          HealthStatusCard({ memoryUsagePercentage: this.usagePercent })
        }
        .margin({ bottom: 24 })

        // 功能链接面板 - 放在健康状态卡片下方
        Column() {
          Text($r('app.string.function_links_title'))
            .cardTitleStyle()
            .margin({ bottom: 12 })
            .width('100%')
            .textAlign(TextAlign.Center)
          
          FunctionLinksPanel()
            .width('100%')
        }
        .margin({ bottom: 24 })

      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
  }
}