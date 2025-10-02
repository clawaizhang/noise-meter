import { DecibelService } from '../../services/DecibelService';
import { StatisticsService } from '../../services/StatisticsService';
import { AudioAnalysisMode } from '../../common/AudioConfig';
import { WeightingType } from '../../constants/WeightingConstants';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { resourceManager } from '@kit.LocalizationKit';
import { NoiseDescriptionDialogBuilder } from '../../pages/noisemeter/NoiseDescriptionDialogNavigation';
import { image } from '@kit.ImageKit';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2, curves } from '@kit.ArkUI';
import { Subscription } from 'rxjs';

@ComponentV2
export struct DecibelDisplayComponent {
  // 输入参数
  @Param @Require currentDecibel: number = 0;
  @Param @Require minDecibel: number = 0;
  @Param @Require maxDecibel: number = 0;
  @Param @Require avgDecibel: number = 0;
  @Param @Require weightingType: WeightingType = WeightingType.A;
  @Param @Require calibrationValue: number = 0;
  @Param @Require noiseThreshold: number = 80;
  @Param @Require noiseAlarmEnabled: boolean = true;
  @Param @Require isNoiseAlarm: boolean = false;
  
  // 内部状态
  @Local private showAvgInsteadOfMin: boolean = true;
  
  @Local as: AppKeys = AppStorageV2.connect(AppKeys)!;
  sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();

  aboutToAppear() {
    // 组件现在只负责显示，不需要初始化音频处理
  }

  aboutToDisappear() {
    // 清理资源
  }

  @Builder
  noiseCalibration() {
    Row({ space: 4 }) {
      Text('声级校准:')
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'));

      Text(`${this.calibrationValue} ${this.weightingType === WeightingType.A ? 'dB(A)' :
        this.weightingType === WeightingType.C ? 'dB(C)' : 'dB'}`)
        .fontSize(12)
        .fontColor('sys.color.font_secondary');
    }
    .opacity(0.7)
  }

  @Builder
  noiseDescriptions() {
    Row() {
      Image($r('app.media.ic_info'))
        .width(12)
        .height(12)
        .fillColor(DecibelService.getDecibelColor(this.currentDecibel));

      Text(DecibelService.getDecibelDescription(this.currentDecibel))
        .fontSize(12)
        .fontColor(DecibelService.getDecibelColor(this.currentDecibel))
        .fontWeight(FontWeight.Medium);
    }
    .padding(8)
    .borderRadius(8)
    .border({
      width: 1,
      color: DecibelService.getDecibelColor(this.currentDecibel)
    })
    .id('noiseDescriptionButtonId')
    .onClick(() => {
      let dialog = DialogHub.getSheet()
        .setContent(wrapBuilder(NoiseDescriptionDialogBuilder), this.as)
        .setStyle({ backgroundColor: $r('sys.color.background_secondary'), showClose: false })
        .setConfig({ enableOutsideInteractive: false, scrollSizeMode: ScrollSizeMode.CONTINUOUS })
        .setComponentTargetId('noiseDescriptionButtonId')
        .build();
      dialog.show();
      setInterval(() => {
        dialog.updateContent(this.as);
      }, 100)
    })
  }

  @Builder
  max() {
    Column() {
      Text('最大')
        .fontSize(this.as.responsive.fontSize.sm)
        .margin({ bottom: this.as.responsive.spacing.xs });
      Text(this.maxDecibel === 0 ? '-' : this.maxDecibel.toString())
        .fontSize(this.as.responsive.fontSize.xxxl)
        .fontWeight(FontWeight.Medium)
        .fontColor(DecibelService.getDecibelColor(this.maxDecibel))
        .animation({ curve: Curve.EaseOut });
    }
    .alignItems(HorizontalAlign.Center)
    .margin({
      left: this.as.responsive.spacing.lg
    })
  }

  @Builder
  averageMin() {
    Column() {
      Text(this.showAvgInsteadOfMin ? '平均' : '最小')
        .fontSize(this.as.responsive.fontSize.sm)
      Text(this.showAvgInsteadOfMin ?
        (this.avgDecibel === 0 ? '-' : this.avgDecibel.toString()) :
        (this.minDecibel === 0 ? '-' : this.minDecibel.toString()))
        .fontSize(this.as.responsive.fontSize.xxxl)
        .fontWeight(FontWeight.Medium)
        .fontColor(DecibelService.getDecibelColor(
          this.showAvgInsteadOfMin ? this.avgDecibel : this.minDecibel))
        .onClick(() => {
          this.showAvgInsteadOfMin = !this.showAvgInsteadOfMin;
        });
    }
    .alignItems(HorizontalAlign.Center)
  }


  @Builder
  CurrentDecibel() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        if (this.currentDecibel === 0) {
          Text('-')
            .fontSize(this.as.responsive.fontSize.xxxxl)
            .textShadow({
              radius: 2,
              color: Color.White,
              offsetX: 0,
              offsetY: 0
            })
            .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }))
            .fontWeight(FontWeight.Bold)
            .fontColor(DecibelService.getDecibelColor(this.currentDecibel));
        } else {
          Text(this.currentDecibel.toString())
            .fontSize(this.as.responsive.fontSize.xxxxl)
            .textShadow({
              radius: 2,
              color: Color.White,
              offsetX: 0,
              offsetY: 0
            })
            .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }))
            .fontWeight(FontWeight.Bold)
            .fontColor(DecibelService.getDecibelColor(this.currentDecibel));
        }
      }
      .backgroundColor('#00000000')
      .margin({ bottom: -this.as.responsive.spacing.xl, right: -this.as.responsive.spacing.xl })
      .id('currentDbComp')
      .onClick(() => {
        DialogHub.getPopup()
          .setTextContent('当前分贝值')
          .setComponentTargetId('currentDbComp')
          .setStyle({
            radius: $r('sys.float.chip_small_radius'),
            maskColor: '#00000000',
          })
          .setConfig({
            dialogPosition: {
              preferPlacement: Placement.Top
            },
            dialogBehavior: { isModal: true, autoDismiss: true }
          })
          .build()
          .show();
      })
      .alignItems(HorizontalAlign.Center);
    }
  }

  build() {
    Column() {
      // 噪音场景参考和升级校准信息
      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        this.noiseDescriptions()
        this.noiseCalibration()
      }
      .margin({
        bottom: this.as.responsive.spacing.md,
        left: this.as.responsive.spacing.lg,
        right: this.as.responsive.spacing.lg,
        top: this.as.responsive.spacing.md
      })

      // 分贝显示卡片
      Row({ space: this.as.responsive.spacing.sm }) {
        this.averageMin()
        this.CurrentDecibel()
        this.max()
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Bottom)
      .borderColor(this.isNoiseAlarm ? DecibelService.getDecibelColor(this.currentDecibel) : Color.Transparent)
    }
    .justifyContent(FlexAlign.Center)
  }
}