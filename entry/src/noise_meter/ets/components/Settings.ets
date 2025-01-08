import { PreferenceService } from '../../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../../library/ets/constants/PreferenceKeyConstants';
import { CustomTitleBar } from '../../../library/ets/components/common/CustomTitleBar';
import { WeightingType, getWeightingDescription } from '../../../library/ets/constants/WeightingConstants';

@ComponentV2
export struct Settings {
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  @Local isLocationEnabled: boolean = false;
  @Local isRecordEnabled: boolean = false;
  @Local selectedWeighting: WeightingType = WeightingType.A;

  private getWeightingIndex(type: WeightingType): number {
    switch (type) {
      case WeightingType.A:
        return 0;
      case WeightingType.C:
        return 1;
      case WeightingType.Z:
        return 2;
      default:
        return 0;
    }
  }

  private getWeightingType(index: number): WeightingType {
    switch (index) {
      case 0:
        return WeightingType.A;
      case 1:
        return WeightingType.C;
      case 2:
        return WeightingType.Z;
      default:
        return WeightingType.A;
    }
  }

  aboutToAppear() {
    // 获取初始状态
    this.isLocationEnabled = this.preferenceService.isEnabled(PreferenceKeyConstants.LOCATION);
    this.isRecordEnabled = this.preferenceService.isEnabled(PreferenceKeyConstants.RECORD);
    this.selectedWeighting = (this.preferenceService.getString(PreferenceKeyConstants.WEIGHTING) || WeightingType.A) as WeightingType;
  }

  build() {
    Column() {
      // 标题栏
      CustomTitleBar({ title: '设置' })

      // 设置列表
      List() {
        // 加权设置
        ListItem() {
          Column() {
            Row() {
              Row() {
                Image($r('app.media.ic_weighting'))
                  .width(24)
                  .height(24)
                  .fillColor('#666666')
                  .margin({ right: 8 })

                Text('分贝计权')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#000000')
              }

              Blank()

              Select([
                { value: 'A计权' },
                { value: 'C计权' },
                { value: 'Z计权' }
              ])
                .selected(this.getWeightingIndex(this.selectedWeighting))
                .value(this.selectedWeighting + '计权')
                .font({ size: 16 })
                .fontColor('#666666')
                .selectedOptionFont({ size: 16 })
                .optionFont({ size: 16 })
                .onSelect(async (index: number, value: string) => {
                  const weightingType = this.getWeightingType(index);
                  await this.preferenceService.putString(PreferenceKeyConstants.WEIGHTING, weightingType);
                  this.selectedWeighting = weightingType;
                })
                .padding({ left: 12, right: 12 })
                .margin({ right: 4 })
                .borderRadius(16)
                .backgroundColor(Color.White)
            }
            .width('100%')
            .height(56)
            .alignItems(VerticalAlign.Center)
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FFFFFF')
        }

        ListItem() {
          Text(getWeightingDescription(this.selectedWeighting))
            .fontSize(14)
            .fontColor('#666666')
            .margin({ left: 48 })
            .textAlign(TextAlign.Start)
        }
        .backgroundColor('#F5F5F5')
        .padding({ top: 8, bottom: 12 })

        // 分割线
        ListItem() {
          Row()
            .width('100%')
            .height(1)
            .backgroundColor('#F5F5F5')
        }

        // 位置开关
        ListItem() {
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
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FFFFFF')
        }

        ListItem() {
          Text(this.isLocationEnabled ? '已开启,可以记录噪音检测时的位置信息' : '已关闭,不会记录位置信息')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ left: 48 })
            .textAlign(TextAlign.Start)
        }
        .backgroundColor('#F5F5F5')
        .padding({ top: 8, bottom: 12 })

        // 分割线
        ListItem() {
          Row()
            .width('100%')
            .height(1)
            .backgroundColor('#F5F5F5')
        }

        // 录音开关
        ListItem() {
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
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .backgroundColor('#FFFFFF')
        }

        ListItem() {
          Text(this.isRecordEnabled ? '已开启,可以录制噪音检测时的音频' : '已关闭,不会录制音频')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ left: 48 })
            .textAlign(TextAlign.Start)
        }
        .backgroundColor('#F5F5F5')
        .padding({ top: 8, bottom: 12 })
      }
      .width('100%')
      .margin({ top: 12 })
      .divider({
        strokeWidth: 1,
        color: '#F5F5F5',
        startMargin: 16,
        endMargin: 16
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
} 