import { WatchPreferenceKeys } from '../../models/WatchPreferenceKeys';
import { router } from '@kit.ArkUI';
import vibrator from '@ohos.vibrator';
import { promptAction } from '@kit.ArkUI';

const TAG: string = 'WatchThresholdSettings';

/**
 * 警报阈值设置 - 紧凑设计
 * 顶部信息按钮，中间控制，去除滑块
 */
@Entry
@Component
struct WatchThresholdSettings {
  private preferenceKeys: WatchPreferenceKeys = WatchPreferenceKeys.getInstance();
  @State alertThreshold: number = 80;

  aboutToAppear(): void {
    this.alertThreshold = this.preferenceKeys.alertThreshold;
  }

  private vibrate(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 30 }, { id: 0, usage: 'alarm' });
    } catch (e) {}
  }

  private adjustValue(delta: number): void {
    const newValue = Math.max(40, Math.min(100, this.alertThreshold + delta));
    if (newValue !== this.alertThreshold) {
      this.alertThreshold = newValue;
      this.preferenceKeys.alertThreshold = newValue;
      this.vibrate();
    }
  }

  private showInfo(): void {
    promptAction.showDialog({
      title: '警报阈值说明',
      message: '当环境噪音超过此阈值时，手表会振动提醒您注意听力保护。\n\n推荐设置：\n• 80分贝 - 日常使用（推荐）\n• 85分贝 - 工作场所标准\n• 90分贝 - 高噪音环境\n\n范围：40 ~ 100分贝',
      buttons: [{ text: '知道了', color: '#34C759' }]
    });
  }

  build() {
    Column({ space: 0 }) {
      // 标题栏 - 标题居中，信息按钮紧跟后面
      Row({ space: 8 }) {
        Text('警报阈值')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
        
        // 信息按钮紧跟标题
        Button() {
          Text('i')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8E8E93')
        }
        .width(22)
        .height(22)
        .backgroundColor('#2C2C2E')
        .borderRadius(11)
        .onClick(() => this.showInfo())
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 25, bottom: 50 })

      // === 核心控制区 ===
      Row({ space: 16 }) {
        // 减号按钮
        Button('−')
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .width(50)
          .height(50)
          .backgroundColor('#2C2C2E')
          .onClick(() => this.adjustValue(-5))

        // 数值显示
        Column({ space: 2 }) {
          Text(this.alertThreshold.toString())
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor('#34C759')
          
          Text('分贝')
            .fontSize(12)
            .fontColor('#8E8E93')
        }
        .width(80)

        // 加号按钮
        Button('+')
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .width(50)
          .height(50)
          .backgroundColor('#2C2C2E')
          .onClick(() => this.adjustValue(5))
      }

      // 范围提示
      Text('40 ~ 100 dB')
        .fontSize(11)
        .fontColor('#666666')
        .margin({ top: 20 })

      Blank()

      // 返回提示
      Text('右滑返回')
        .fontSize(11)
        .fontColor('#48484A')
        .margin({ bottom: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
