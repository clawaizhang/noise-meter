import { WatchPreferenceKeys } from '../../models/WatchPreferenceKeys';
import { promptAction,router } from '@kit.ArkUI';
import vibrator from '@ohos.vibrator';

const TAG: string = 'WatchSettings';

/**
 * 手表端设置主页 - 紧凑列表
 */
@Entry
@Component
struct WatchSettings {
  private preferenceKeys: WatchPreferenceKeys = WatchPreferenceKeys.getInstance();
  
  @State alertThreshold: number = 80;
  @State calibrationValue: number = 0;
  @State vibrateEnabled: boolean = true;

  aboutToAppear(): void {
    this.refreshSettings();
  }

  // 页面显示时刷新（从子页面返回时）
  onPageShow(): void {
    this.refreshSettings();
  }

  private refreshSettings(): void {
    this.alertThreshold = this.preferenceKeys.alertThreshold;
    this.calibrationValue = this.preferenceKeys.calibrationValue;
    this.vibrateEnabled = this.preferenceKeys.vibrateEnabled;
  }

  private vibrate(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 25 }, { id: 0, usage: 'alarm' });
    } catch (e) {}
  }

  private showAbout(): void {
    promptAction.showDialog({
      title: '关于',
      message: '静喵Sound\n版本：2.0.0\n\n' +
               '测量算法：A计权滤波 · 快速响应\n' +
               '使用A计权曲线模拟人耳听觉特性，适合环境噪音检测。',
      buttons: [{ text: '知道了', color: '#34C759' }]
    });
  }

  build() {
    Column({ space: 0 }) {
      // 标题
      Text('设置')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .margin({ top: 25, bottom: 20 })

      // 设置列表
      List({ space: 10 }) {
        // 1. 警报阈值
        ListItem() {
          Row() {
            Column({ space: 2 }) {
              Text('警报阈值')
                .fontSize(15)
                .fontColor('#FFFFFF')
              Text(this.alertThreshold + ' 分贝')
                .fontSize(12)
                .fontColor('#8E8E93')
            }
            .alignItems(HorizontalAlign.Start)

            Image($r('app.media.ic_arrow_right'))
              .width(16)
              .height(16)
              .opacity(0.4)
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#1C1C1E')
          .borderRadius(10)
        }
        .onClick(() => {
          this.vibrate();
          router.pushUrl({ url: 'pages/wearable/WatchThresholdSettings' });
        })

        // 2. 麦克风校准
        ListItem() {
          Row() {
            Column({ space: 2 }) {
              Text('麦克风校准')
                .fontSize(15)
                .fontColor('#FFFFFF')
              Text(this.calibrationValue === 0 ? '未校准' : 
                   (this.calibrationValue > 0 ? '+' : '') + this.calibrationValue + ' 分贝')
                .fontSize(12)
                .fontColor(this.calibrationValue === 0 ? '#8E8E93' : '#FFCC00')
            }
            .alignItems(HorizontalAlign.Start)

            Image($r('app.media.ic_arrow_right'))
              .width(16)
              .height(16)
              .opacity(0.4)
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#1C1C1E')
          .borderRadius(10)
        }
        .onClick(() => {
          this.vibrate();
          router.pushUrl({ url: 'pages/wearable/WatchCalibrationSettings' });
        })

        // 3. 振动提醒 - 独立卡片，带说明
        ListItem() {
          Column({ space: 8 }) {
            // 第一行：标题 + 开关
            Row() {
              Text('振动提醒')
                .fontSize(15)
                .fontColor('#FFFFFF')
              
              Toggle({ type: ToggleType.Switch, isOn: this.vibrateEnabled })
                .width(44)
                .height(26)
                .selectedColor('#34C759')
                .onChange((isOn: boolean): void => {
                  this.vibrateEnabled = isOn;
                  this.preferenceKeys.vibrateEnabled = isOn;
                  this.vibrate();
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            // 第二行：说明文字
            Text(this.vibrateEnabled ? 
              '当噪音超过' + this.alertThreshold + '分贝时振动提醒' : 
              '振动提醒已关闭')
              .fontSize(11)
              .fontColor('#8E8E93')
              .width('100%')
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#1C1C1E')
          .borderRadius(10)
        }

        // 4. 关于
        ListItem() {
          Row() {
            Column({ space: 2 }) {
              Text('关于')
                .fontSize(15)
                .fontColor('#FFFFFF')
              Text('查看版本信息')
                .fontSize(12)
                .fontColor('#8E8E93')
            }
            .alignItems(HorizontalAlign.Start)
            
            Image($r('app.media.ic_arrow_right'))
              .width(16)
              .height(16)
              .opacity(0.4)
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#1C1C1E')
          .borderRadius(10)
        }
        .onClick(() => {
          this.vibrate();
          this.showAbout();
        })
      }
      .padding({ left: 15, right: 15 })
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // 底部提示
      Text('右滑返回')
        .fontSize(10)
        .fontColor('#48484A')
        .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
