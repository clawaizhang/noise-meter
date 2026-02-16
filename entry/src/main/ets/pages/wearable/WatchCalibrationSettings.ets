import { WatchPreferenceKeys } from '../../models/WatchPreferenceKeys';
import { promptAction, router } from '@kit.ArkUI';
import vibrator from '@ohos.vibrator';
import { IAudioService, AudioData } from '../../core/interfaces/IAudioService';
import { useAudioService } from '../../core/factory/ServiceFactory';
import { WatchAudioService } from '../../wearable/impl/WatchAudioService';

const TAG: string = 'WatchCalibrationSettings';

/**
 * 麦克风校准 - 紧凑设计
 * 核心：原始值、左右调整、结果值、偏移标注
 */
@Entry
@Component
struct WatchCalibrationSettings {
  private preferenceKeys: WatchPreferenceKeys = WatchPreferenceKeys.getInstance();
  private audioService: IAudioService = useAudioService();
  
  @State calibrationValue: number = 0;
  @State rawDecibel: number = 0;

  aboutToAppear(): void {
    this.calibrationValue = this.preferenceKeys.calibrationValue;
    this.audioService.onDataUpdate((data: AudioData) => {
      this.rawDecibel = data.currentDecibel;
    });
    if (!this.audioService.isRecording()) {
      this.startAudio();
    }
  }

  aboutToDisappear(): void {
    (this.audioService as WatchAudioService).setCalibration(this.calibrationValue);
  }

  private async startAudio(): Promise<void> {
    const inited = await this.audioService.init();
    if (inited) await this.audioService.start();
  }

  // 计算校准后的显示值（步进1，都是整数）
  private getCalibratedDisplay(): string {
    if (this.rawDecibel <= 0) return '--';
    return Math.round(this.rawDecibel + this.calibrationValue).toString();
  }

  private vibrate(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 30 }, { id: 0, usage: 'alarm' });
    } catch (e) {}
  }

  private adjustCalibration(delta: number): void {
    const newValue = Math.max(-30, Math.min(30, this.calibrationValue + delta));
    if (newValue !== this.calibrationValue) {
      this.calibrationValue = newValue;
      this.preferenceKeys.calibrationValue = newValue;
      (this.audioService as WatchAudioService).setCalibration(newValue);
      this.vibrate();
    }
  }

  private showInfo(): void {
    promptAction.showDialog({
      title: '麦克风校准',
      message: '调整偏移量使最终值与专业噪音计一致。\n\n' +
               '计算：最终值 = 原始检测 + 偏移\n\n' +
               '范围：-30 ~ +30分贝\n' +
               '步进：1分贝\n\n' +
               '例：原始75分贝 + 偏移+2 = 最终77分贝',
      buttons: [{ text: '知道了', color: '#34C759' }]
    });
  }

  build() {
    Column({ space: 0 }) {
      // 标题 + i按钮（紧凑）
      Row({ space: 6 }) {
        Text('麦克风校准')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
        Button() {
          Text('i')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor('#8E8E93')
        }
        .width(20)
        .height(20)
        .backgroundColor('#2C2C2E')
        .borderRadius(10)
        .onClick(() => this.showInfo())
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 20, bottom: 30 })

      // 原始值（紧凑）
      Column({ space: 1 }) {
        Text('原始 ' + (this.rawDecibel > 0 ? this.rawDecibel.toString() : '--') + ' 分贝')
          .fontSize(12)
          .fontColor('#666666')
      }
      .margin({ bottom: 20 })

      // 核心控制区
      Row({ space: 12 }) {
        Button('−')
          .fontSize(28)
          .width(52)
          .height(52)
          .backgroundColor('#2C2C2E')
          .onClick(() => this.adjustCalibration(-1))

        // 结果值
        Column({ space: 2 }) {
          Text(this.getCalibratedDisplay())
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor('#34C759')
          Text('分贝')
            .fontSize(12)
            .fontColor('#8E8E93')
          // 偏移标注
          if (this.calibrationValue !== 0) {
            Text((this.calibrationValue > 0 ? '+' : '') + Math.round(this.calibrationValue).toString())
              .fontSize(13)
              .fontColor('#FFCC00')
              .margin({ top: 2 })
          } else {
            Text('未校准')
              .fontSize(11)
              .fontColor('#666666')
              .margin({ top: 2 })
          }
        }
        .width(80)

        Button('+')
          .fontSize(28)
          .width(52)
          .height(52)
          .backgroundColor('#2C2C2E')
          .onClick(() => this.adjustCalibration(1))
      }
      .margin({ bottom: 25 })

      // 重置按钮 - 只有校准值不为0时才显示
      if (this.calibrationValue !== 0) {
        Button('重置')
          .fontSize(11)
          .width(64)
          .height(30)
          .backgroundColor('#2C2C2E')
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.calibrationValue = 0;
            this.preferenceKeys.calibrationValue = 0;
            (this.audioService as WatchAudioService).setCalibration(0);
            this.vibrate();
          })
      }

      Blank()

      Text('右滑返回')
        .fontSize(10)
        .fontColor('#48484A')
        .margin({ bottom: 25 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
