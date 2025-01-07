import { PreferenceService } from '../../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';

@ComponentV2
export struct Settings {
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  @Local isLocationEnabled: boolean = false;
  @Local isRecordEnabled: boolean = false;

  aboutToAppear() {
    // 获取初始状态
    this.isLocationEnabled = this.preferenceService.isEnabled(PreferenceKeyConstants.LOCATION);
    this.isRecordEnabled = this.preferenceService.isEnabled(PreferenceKeyConstants.RECORD);
  }

  build() {
    Column() {
      // 位置开关
      Column() {
        Row() {
          Row() {
            Image($r('app.media.ic_location'))
              .width(24)
              .height(24)
              .fillColor('#666666')
              .margin({ right: 8 })

            Text('位置')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#000000')
          }

          Blank()

          Toggle({ type: ToggleType.Switch, isOn: this.isLocationEnabled })
            .selectedColor('#0091FF')
            .switchPointColor('#FFFFFF')
            .onChange(async (isOn: boolean) => {
              await this.preferenceService.setEnabled(PreferenceKeyConstants.LOCATION, isOn);
              this.isLocationEnabled = isOn;
            })
        }
        .width('100%')
        .height(56)
        .alignItems(VerticalAlign.Center)

        Text(this.isLocationEnabled ? '已开启,可以记录噪音检测时的位置信息' : '已关闭,不会记录位置信息')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: 32, bottom: 12 })
          .textAlign(TextAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // 分割线
      Row()
        .width('100%')
        .height(1)
        .backgroundColor('#F5F5F5')

      // 录音开关
      Column() {
        Row() {
          Row() {
            Image($r('app.media.ic_mic'))
              .width(24)
              .height(24)
              .fillColor('#666666')
              .margin({ right: 8 })

            Text('录音')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#000000')
          }

          Blank()

          Toggle({ type: ToggleType.Switch, isOn: this.isRecordEnabled })
            .selectedColor('#0091FF')
            .switchPointColor('#FFFFFF')
            .onChange(async (isOn: boolean) => {
              await this.preferenceService.setEnabled(PreferenceKeyConstants.RECORD, isOn);
              this.isRecordEnabled = isOn;
            })
        }
        .width('100%')
        .height(56)
        .alignItems(VerticalAlign.Center)

        Text(this.isRecordEnabled ? '已开启,可以录制噪音检测时的音频' : '已关闭,不会录制音频')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ left: 32, bottom: 12 })
          .textAlign(TextAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .backgroundColor('#F5F5F5')
  }
} 