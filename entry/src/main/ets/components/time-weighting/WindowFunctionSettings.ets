import { WindowType } from '../../common/AudioConfig';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';

@ComponentV2
export struct WindowFunctionSettings {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  build() {
    Column({ space: 12 }) {
      // 窗函数覆盖开关
      Row() {
        Toggle({ type: ToggleType.Switch, isOn: this.pk.window_function_override_enabled })
          .onChange((value: boolean) => {
            this.pk.window_function_override_enabled = value;
          })
        Text('启用窗函数覆盖')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .margin({ left: 12 })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      // 窗函数类型选择（仅在启用覆盖时显示）
      if (this.pk.window_function_override_enabled) {
        Column({ space: 8 }) {
          Text('选择窗函数类型')
            .fontSize(14)
            .fontColor(Color.Gray)
            .width('100%')
            .textAlign(TextAlign.Start)

          Row({ space: 12 }) {
            // Hanning窗选项
            Column({ space: 4 }) {
              Radio({ value: WindowType.HANNING, group: 'windowType' })
                .checked(this.pk.window_function_override_type === WindowType.HANNING)
                .onChange((checked: boolean) => {
                  if (checked) {
                    this.pk.window_function_override_type = WindowType.HANNING;
                  }
                })
              Text('Hanning窗')
                .fontSize(14)
                .fontColor(this.pk.window_function_override_type === WindowType.HANNING ? Color.Blue : Color.Black)
              Text('主瓣较宽，旁瓣衰减快')
                .fontSize(12)
                .fontColor(Color.Gray)
            }
            .padding(8)
            .borderRadius(8)
            .border({
              width: this.pk.window_function_override_type === WindowType.HANNING ? 2 : 1,
              color: this.pk.window_function_override_type === WindowType.HANNING ? Color.Blue : Color.Gray
            })
            .backgroundColor(this.pk.window_function_override_type === WindowType.HANNING ?
            Color.Blue : Color.Transparent)
            .onClick(() => {
              this.pk.window_function_override_type = WindowType.HANNING;
            })

            // Blackman窗选项
            Column({ space: 4 }) {
              Radio({ value: WindowType.BLACKMAN, group: 'windowType' })
                .checked(this.pk.window_function_override_type === WindowType.BLACKMAN)
                .onChange((checked: boolean) => {
                  if (checked) {
                    this.pk.window_function_override_type = WindowType.BLACKMAN;
                  }
                })
              Text('Blackman窗')
                .fontSize(14)
                .fontColor(this.pk.window_function_override_type === WindowType.BLACKMAN ? Color.Blue : Color.Black)
              Text('主瓣更窄，旁瓣衰减更强')
                .fontSize(12)
                .fontColor(Color.Gray)
            }
            .padding(8)
            .borderRadius(8)
            .border({
              width: this.pk.window_function_override_type === WindowType.BLACKMAN ? 2 : 1,
              color: this.pk.window_function_override_type === WindowType.BLACKMAN ? Color.Blue : Color.Gray
            })
            .backgroundColor(this.pk.window_function_override_type === WindowType.BLACKMAN ?
            Color.Blue : Color.Transparent)
            .onClick(() => {
              this.pk.window_function_override_type = WindowType.BLACKMAN;
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          // 窗函数说明
          Text('窗函数影响频谱分析的频率分辨率和旁瓣抑制能力。Hanning窗适合一般应用，Blackman窗提供更好的频率分辨率。')
            .fontSize(12)
            .fontColor(Color.Gray)
            .width('100%')
            .textAlign(TextAlign.Start)
            .padding(8)
            .backgroundColor(Color.Gray)
            .borderRadius(8)
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .border({ width: 1, color: Color.Gray })
        .borderRadius(12)
        .backgroundColor(Color.White)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }
}