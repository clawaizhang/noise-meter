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
import { DesignConstants } from '../../constants/DesignConstants';

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
  @Param @Require systemNotificationEnabled: boolean = true;
  @Param @Require isNoiseAlarm: boolean = false;
  @Param @Require autoSaveCountdown: string = '';
  
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
  noiseLevelBanner() {

    Row({ space: 8 }) {
      Image($r('app.media.ic_info'))
        .width(16)
        .height(16)
        .fillColor(DecibelService.getDecibelColor(this.currentDecibel));

      Text(DecibelService.getDecibelDescription(this.currentDecibel))
        .fontSize(14)
        .fontColor(DecibelService.getDecibelColor(this.currentDecibel))
        .fontWeight(FontWeight.Medium);
    }
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor(DecibelService.getDecibelColor(this.currentDecibel) + '20') // 20% 透明度
    .borderRadius(8)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      let dialog = DialogHub.getSheet()
        .setContent(wrapBuilder(NoiseDescriptionDialogBuilder), this.as)
        .setStyle({ backgroundColor: $r('sys.color.background_secondary'), showClose: false })
        .setConfig({ enableOutsideInteractive: false, scrollSizeMode: ScrollSizeMode.CONTINUOUS })
        .setComponentTargetId('noiseLevelBannerId')
        .build();
      dialog.show();
      setInterval(() => {
        dialog.updateContent(this.as);
      }, 100)
    })
    .id('noiseLevelBannerId')
  }

  @Builder
  currentDecibelDisplay() {

    Column({ space: 0 }) {
      if (this.currentDecibel === 0) {
        Text('-')
          .fontSize(80)
          .fontWeight(FontWeight.Bold)
          .fontColor(DecibelService.getDecibelColor(this.currentDecibel))
          .textAlign(TextAlign.Center)
          .width('100%')
          .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }));
      } else {
        Text(this.currentDecibel.toString())
          .fontSize(80)
          .fontWeight(FontWeight.Bold)
          .fontColor(DecibelService.getDecibelColor(this.currentDecibel))
          .textAlign(TextAlign.Center)
          .width('100%')
          .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }));
      }
      
      Text('分贝')
        .fontSize(16)
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: 4 });
    }
    .padding({ top: 24, bottom: 24 })
    .width('100%')
    .alignItems(HorizontalAlign.Center)
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
  }

  @Builder
  statisticsDisplay() {
    Row({ space: 0 }) {
      // 平均值
      Column({ space: 4 }) {
        Text('平均')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .textAlign(TextAlign.Center)
          .width('100%');
        
        Text(this.avgDecibel === 0 ? '-' : this.avgDecibel.toString())
          .fontSize(32)
          .fontWeight(FontWeight.Medium)
          .fontColor(DecibelService.getDecibelColor(this.avgDecibel))
          .textAlign(TextAlign.Center)
          .width('100%');
      }
      .layoutWeight(1)

      // 分隔线
      Divider()
        .vertical(true)
        .strokeWidth(1)
        .color($r('sys.color.comp_divider'))
        .margin({ left: 16, right: 16 })
        .height(40)

      // 最大值
      Column({ space: 4 }) {
        Text('最大')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .textAlign(TextAlign.Center)
          .width('100%');
        
        Text(this.maxDecibel === 0 ? '-' : this.maxDecibel.toString())
          .fontSize(32)
          .fontWeight(FontWeight.Medium)
          .fontColor(DecibelService.getDecibelColor(this.maxDecibel))
          .textAlign(TextAlign.Center)
          .width('100%');
      }
      .layoutWeight(1)

      // 分隔线
      Divider()
        .vertical(true)
        .strokeWidth(1)
        .color($r('sys.color.comp_divider'))
        .margin({ left: 16, right: 16 })
        .height(40)

      // 最小值
      Column({ space: 4 }) {
        Text('最小')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .textAlign(TextAlign.Center)
          .width('100%');
        
        Text(this.minDecibel === 0 ? '-' : this.minDecibel.toString())
          .fontSize(32)
          .fontWeight(FontWeight.Medium)
          .fontColor(DecibelService.getDecibelColor(this.minDecibel))
          .textAlign(TextAlign.Center)
          .width('100%');
      }
      .layoutWeight(1)
    }
    .padding({ top: 16, bottom: 16, left: 24, right: 24 })
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(12)
  }

  @Builder
  systemStatusDisplay() {
    Row({ space: 16 }) {
      // 校准状态
      Row({ space: 4 }) {
        Image($r('app.media.ic_calibration'))
          .width(14)
          .height(14)
          .fillColor($r('sys.color.ohos_id_color_text_secondary'));
        
        Text(`校准:${this.calibrationValue} ${this.weightingType === WeightingType.A ? 'dB(A)' :
          this.weightingType === WeightingType.C ? 'dB(C)' : 'dB'}`)
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'));
      }

      Blank()

      // 自动保存状态
      if (this.autoSaveCountdown) {
        Row({ space: 4 }) {
          Image($r('app.media.ic_save'))
            .width(14)
            .height(14)
            .fillColor($r('sys.color.ohos_id_color_text_secondary'));
          
          Text(this.autoSaveCountdown)
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'));
        }
      }
    }
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(8)
  }

  build() {
    Column({ space: 16 }) {
      // 1. 噪音等级横幅（顶部）
      this.noiseLevelBanner()

      // 2. 当前分贝值显示（核心区域）
      this.currentDecibelDisplay()

      // 3. 统计数据展示
      this.statisticsDisplay()

      // 4. 系统状态信息
      this.systemStatusDisplay()

      // 5. 位置信息（由父组件传入）
      Blank()
        .height(40) // 为位置信息预留空间
    }
    .width('100%')
    .borderColor(this.isNoiseAlarm ? DecibelService.getDecibelColor(this.currentDecibel) : Color.Transparent)
    .borderWidth(this.isNoiseAlarm ? 2 : 0)
    .borderRadius(16)
  }
}