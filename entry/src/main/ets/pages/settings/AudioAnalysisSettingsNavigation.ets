import { AppStorageV2, curves, PersistenceV2, promptAction } from '@kit.ArkUI';
import { navigationStack } from '../../constants/ProviderConstant';
import { DesignConstants } from '../../constants/DesignConstants';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppKeys } from '../../models/AppKeys';

@Extend(Image)
function itemIcon() {
  .width(DesignConstants.ICON_SIZE_MD)
  .height(DesignConstants.ICON_SIZE_MD)
  .fillColor($r('sys.color.font_primary'))
}

@Extend(Text)
function itemTitle() {
  .fontWeight(FontWeight.Medium)
}

@Extend(Text)
function itemDescription() {
  .fontColor($r('sys.color.font_secondary'))
  .fontSize(DesignConstants.FONT_SIZE_MD)
  .textAlign(TextAlign.Start)
  .alignSelf(ItemAlign.Start)
}

@Extend(Column)
function cardStyle() {
  .backgroundColor($r('sys.color.comp_background_primary'))
  .justifyContent(FlexAlign.Start)
  .alignItems(HorizontalAlign.Start)
  .borderRadius(16)
  .padding(16)
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
    .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
    .combine(TransitionEffect.translate({ x: -150, y: 0 }).animation({ curve: curves.springMotion() })))
}

@Extend(Row)
function listItemRow() {
  .alignItems(VerticalAlign.Center)
  .justifyContent(FlexAlign.Start)
}


@ComponentV2
export struct AudioAnalysisSettings {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local isAutoCalibrating: boolean = false;
  @Local countdown: number = 0;
  @Local calibrationProgress: number = 0;
  @Local as: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local gridColumns: number = 1;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
  }

  private startAutoCalibration() {
    this.isAutoCalibrating = true;
    this.countdown = 3;

    // 5秒倒计时
    const countdownInterval = setInterval(() => {
      this.countdown -= 1;
      if (this.countdown <= 0) {
        clearInterval(countdownInterval);
        this.beginCalibration();
      }
    }, 1000);
  }

  private beginCalibration() {
    const calibrationDuration = 8; // 8秒校准
    this.calibrationProgress = 0;
    let totalDecibel = 0;
    let sampleCount = 0;

    // 开始校准
    const calibrationInterval = setInterval(() => {
      this.calibrationProgress += 1;
      totalDecibel += this.as.db;
      sampleCount += 1;

      if (this.calibrationProgress >= calibrationDuration) {
        clearInterval(calibrationInterval);
        this.finishCalibration(totalDecibel / sampleCount);
      }
    }, 1000);
  }

  private finishCalibration(averageDecibel: number) {
    this.isAutoCalibrating = false;
    const newCalibrationValue = 26 - averageDecibel; // 计算与26dB的差值
    this.pk.calibration_value = Math.round(newCalibrationValue * 10) / 10; // 保留1位小数


    promptAction.showToast({
      message: `自动校准完成，新校准值: ${this.pk.calibration_value}dB`,
      duration: 3000
    });
  }

  build() {
    GridRow({
      columns:
      1,
      breakpoints: { reference: BreakpointsReference.WindowSize }
    , gutter: 16
    }) {

      // 声级校准设置
      GridCol() {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Row() {
              Image($r('app.media.ic_calibration'))
                .itemIcon()
              Text('声级校准')
                .itemTitle()
            }.layoutWeight(1)

            Text(`${this.pk.calibration_value}dB`)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_secondary'))
              .margin({ right: DesignConstants.SPACING_SM })
          }
          .listItemRow()

          Slider({
            value: this.pk.calibration_value,
            min: -30,
            max: 30,
            style: SliderStyle.InSet
          })
            .blockColor($r('sys.color.font_emphasize'))
            .trackColor($r('sys.color.background_secondary'))
            .selectedColor($r('sys.color.font_emphasize'))
            .showTips(true, `${this.as.db}dB`)
            .onChange((value: number) => {
              this.pk.calibration_value = value;
            })
            .margin({
              top: DesignConstants.SPACING_MD,
              bottom: DesignConstants.SPACING_MD
            })
            .height(24)
            .trackThickness(24)
            .blockSize({
              width: 24,
              height: 24
            })

          Text('手动校准麦克风灵敏度，确保测量精度')
            .itemDescription()
        }
        .cardStyle()

      }

      // 自动校准按钮
      GridCol() {
        Column({ space: 8 }) {
          Row({ space: 8 }) {
            Row() {
              Image($r('app.media.ic_calibration'))
                .itemIcon()
              Text('自动校准')
                .itemTitle()
            }.layoutWeight(1)

            if (this.isAutoCalibrating) {
              Text(this.countdown > 0 ? `${this.countdown}秒后开始校准` :
                `校准中,请保持安静...${8 - this.calibrationProgress}秒`)
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('sys.color.font_secondary'))
                .margin({ right: DesignConstants.SPACING_SM })
            } else {
              Button('开始校准')
                .type(ButtonType.Normal)
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .backgroundColor($r('sys.color.background_emphasize'))
                .borderRadius(DesignConstants.BORDER_RADIUS_LG)
                .height(32)
                .onClick(async () => {
                  const result = await promptAction.showDialog({
                    title: '自动校准提示',
                    message: '请在非常安静的房间中进行自动校准，特别是夜间效果最佳',
                    buttons: [
                      {
                        text: '取消',
                        color: $r('app.color.text_disabled')
                      },
                      {
                        text: '确认',
                        color: $r('app.color.primary')
                      }
                    ]
                  });

                  // 根据用户选择处理
                  if (result.index === 1) { // 确认按钮
                    this.startAutoCalibration();
                  }
                })
            }
          }
          .listItemRow()

          Text('自动计算并设置校准值')
            .itemDescription()
        }
        .cardStyle()
      }
    }
    .padding(16)
    .backgroundColor($r('sys.color.background_secondary'))
  }
}


@Builder
export function AudioAnalysisSettingsBuilder() {
  AudioAnalysisSettings()
}