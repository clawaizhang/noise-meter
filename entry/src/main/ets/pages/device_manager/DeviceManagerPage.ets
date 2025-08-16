import router from '@ohos.router';
import statvfs from '@ohos.file.statvfs';
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
  @Local progressColor: string = '#52C41A';
  @Local healthInfo: DeviceHealthInfo = DeviceHealthService.getInstance().getHealthInfo();

  aboutToAppear() {
    this.getSystemMemoryInfo();
    setInterval(() => {
      this.getSystemMemoryInfo();
    }, 5000);
    
    // 动画效果
    animateTo({ duration: 1000 }, () => {
      this.rotateAngle = 360;
    });
    
    // 健康度数据更新监听
    DeviceHealthService.getInstance().registerUpdateListener((score: number) => {
      this.healthInfo = DeviceHealthService.getInstance().getHealthInfo();
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
      this.usagePercent = Number((usedMem / totalMem * 100).toFixed(1));
      this.progressColor = this.usagePercent > 80 ? '#FF4D4F' :
                         this.usagePercent > 60 ? '#FAAD14' : '#52C41A';
    }
  }

  @Builder
  MemoryDetailItem(label: string, value: string, icon: Resource) {
    Row() {
      Image(icon)
        .width(20)
        .height(20)
        .margin({right: 8})
      Text(label)
        .fontSize(14)
        .layoutWeight(1)
      Text(value)
        .fontSize(14)
        .fontColor('#1890FF')
    }
    .width('100%')
    .margin({bottom: 12})
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
            .margin({right: 8})
          Text('内存使用情况')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .margin({bottom: 12})

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
              .backgroundColor('#F5F5F5')
              .color(this.progressColor)
            .rotate({angle: this.rotateAngle})

            Column() {
              Text(`${this.usagePercent}%`)
                .fontSize(18)
                .fontColor(this.progressColor)
              Text('已使用')
                .fontSize(10)
                .fontColor('#666')
            }
          }
          .margin({top: 8, bottom: 12})

          // 内存详情
          Column() {
            this.MemoryDetailItem('可用内存', formatMemory(this.memoryInfo.availableMem), $r('app.media.ic_security'))
            this.MemoryDetailItem('已使用', formatMemory(BigInt(Number(this.memoryInfo.totalMem - this.memoryInfo.availableMem))), $r('app.media.ic_battery'))
            this.MemoryDetailItem('总内存', formatMemory(this.memoryInfo.totalMem), $r('app.media.ic_storage'))
          }
          .width('100%')
        }
        .padding(8)
        .borderRadius(8)
        .backgroundColor('#FFF')
        .shadow({radius: 6, color: '#00000010', offsetX: 0, offsetY: 2})
      }
      .width('100%')
      .padding(16)
    }
  }

  @Builder
  buildMemoryDetailItem(label: string, value: string, icon: Resource) {
    Row() {
      Image(icon)
        .width(20)
        .height(20)
        .margin({right: 8})
      Text(label)
        .fontSize(14)
        .layoutWeight(1)
      Text(value)
        .fontSize(14)
        .fontColor('#1890FF')
    }
    .width('100%')
    .margin({bottom: 12})
  }

  build() {
    Column() {
      // 健康度卡片
      HealthStatusCard({ healthInfo: this.healthInfo })
      
      // 手动刷新按钮
      Button('手动刷新')
        .onClick(() => {
          DeviceHealthService.getInstance().updateHealthInfo();
          this.healthInfo = DeviceHealthService.getInstance().getHealthInfo();
        })
        .width('50%')
        .margin(10)
        .backgroundColor($r('app.color.primary'))
        .fontColor(Color.White)
        
      // 设备状态卡片
      Column() {
        Row() {
          Text('设备状态')
            .cardTitleStyle()
          Blank()
          Text('良好')
            .fontSize(14)
            .fontColor($r('app.color.success'))
        }
        .width('100%')

        Divider()
          .strokeWidth(1)
          .color($r('app.color.divider'))

        Row() {

          Column() {
            this.buildMemoryInfo()
          }
        }
        .margin({ top: 12 })
      }
      .width('90%')
      .padding(16)
      .backgroundColor($r('app.color.background_secondary'))
      .borderRadius(12)
      .margin({ top: 8, bottom: 16 })

      // 功能入口网格
      Grid() {
        GridItem() {
          Column() {
            Image($r('app.media.ic_audio_analysis'))
              .width(32)
              .height(32)
            Text('清理加速')
              .gridItemTextStyle()
          }
          .onClick(() => {
            router.pushUrl({
              url: 'pages/CleanOptimizePage'
            }, router.RouterMode.Standard, (err) => {
              if (err) {
                console.error(`Failed to navigate to CleanOptimizePage: ${JSON.stringify(err)}`);
              }
            });
          })
        }

        GridItem() {
          Column() {
            Image($r('app.media.ic_battery'))
              .width(32)
              .height(32)
            Text('电池管理')
              .gridItemTextStyle()
          }
          .onClick(() => {
            router.pushUrl({
              url: 'pages/BatteryManagerPage'
            }, router.RouterMode.Standard, (err) => {
              if (err) {
                console.error(`Failed to navigate to BatteryManagerPage: ${JSON.stringify(err)}`);
              }
            });
          })
        }

        GridItem() {
          Column() {
            Image($r('app.media.ic_storage'))
              .width(32)
              .height(32)
            Text('存储管理')
              .gridItemTextStyle()
          }
          .onClick(() => {
            router.pushUrl({
              url: 'pages/StorageManagerPage'
            }, router.RouterMode.Standard, (err) => {
              if (err) {
                console.error(`Failed to navigate to StorageManagerPage: ${JSON.stringify(err)}`);
              }
            });
          })
        }

        GridItem() {
          Column() {
            Image($r('app.media.ic_security'))
              .width(32)
              .height(32)
            Text('安全中心')
              .gridItemTextStyle()
          }
          .onClick(() => {
            router.pushUrl({
              url: 'pages/SecurityCenterPage'
            }, router.RouterMode.Standard, (err) => {
              if (err) {
                console.error(`Failed to navigate to SecurityCenterPage: ${JSON.stringify(err)}`);
              }
            });
          })
        }

        GridItem() {
          Column() {
            Image($r('app.media.ic_info'))
              .width(32)
              .height(32)
            Text('测试评分')
              .gridItemTextStyle()
          }
          .onClick(() => {
            DeviceHealthService.getInstance().testScoring();
          })
        }

      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('90%')
      .height(180)
      .margin({ bottom: 16 })

    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
  }
}