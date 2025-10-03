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

// 噪音等级横幅配置接口
interface NoiseBannerConfig {
  decibelColor: ResourceColor;
  description: string;
}

// 当前分贝显示配置接口
interface CurrentDecibelConfig {
  decibelColor: ResourceColor;
  currentDecibel: number;
}

// 统计数据配置接口
interface StatisticsConfig {
  minDecibel: number;
  avgDecibel: number;
  maxDecibel: number;
  minColor: ResourceColor;
  avgColor: ResourceColor;
  maxColor: ResourceColor;
}

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
  @Param @Require locationInfo: string = '';
  
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
  noiseLevelBanner(config: NoiseBannerConfig) {
    Row({ space: 8 }) {
      Image($r('app.media.ic_info'))
        .width(14)
        .height(14)
        .fillColor(config.decibelColor);

      Text(config.description)
        .fontSize(12)
        .fontColor(config.decibelColor)
        .fontWeight(FontWeight.Medium);
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor(config.decibelColor + '20') // 20% 透明度
    .borderRadius(6)
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
  currentDecibelDisplay(config: CurrentDecibelConfig) {
    Column({ space: 0 }) {
      if (config.currentDecibel === 0) {
        Text('-')
          .fontSize(64)
          .fontWeight(FontWeight.Bold)
          .fontColor(config.decibelColor)
          .textAlign(TextAlign.Center)
          .width('100%')
          .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }));
      } else {
        Text(config.currentDecibel.toString())
          .fontSize(64)
          .fontWeight(FontWeight.Bold)
          .fontColor(config.decibelColor)
          .textAlign(TextAlign.Center)
          .width('100%')
          .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }));
      }
      
      Text('分贝')
        .fontSize(14)
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: 2 });
    }
    .padding({ top: 16, bottom: 16 })
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
  statisticsDisplay(config: StatisticsConfig) {
    Row({ space: 0 }) {
      // 最小值（左侧）
      Column({ space: 2 }) {
        Text('最小')
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .textAlign(TextAlign.Center)
          .width('100%');
        
        Text(config.minDecibel === 0 ? '-' : config.minDecibel.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor(config.minColor)
          .textAlign(TextAlign.Center)
          .width('100%');
      }
      .layoutWeight(1)

      // 分隔线
      Divider()
        .vertical(true)
        .strokeWidth(1)
        .color($r('sys.color.comp_divider'))
        .margin({ left: 12, right: 12 })
        .height(32)

      // 平均值（中间）
      Column({ space: 2 }) {
        Text('平均')
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .textAlign(TextAlign.Center)
          .width('100%');
        
        Text(config.avgDecibel === 0 ? '-' : config.avgDecibel.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor(config.avgColor)
          .textAlign(TextAlign.Center)
          .width('100%');
      }
      .layoutWeight(1)

      // 分隔线
      Divider()
        .vertical(true)
        .strokeWidth(1)
        .color($r('sys.color.comp_divider'))
        .margin({ left: 12, right: 12 })
        .height(32)

      // 最大值（右侧）
      Column({ space: 2 }) {
        Text('最大')
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .textAlign(TextAlign.Center)
          .width('100%');
        
        Text(config.maxDecibel === 0 ? '-' : config.maxDecibel.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor(config.maxColor)
          .textAlign(TextAlign.Center)
          .width('100%');
      }
      .layoutWeight(1)
    }
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(10)
  }

  @Builder
  systemStatusDisplay() {
    Row({ space: 12 }) {
      // 校准状态
      Row({ space: 4 }) {
        Image($r('app.media.ic_calibration'))
          .width(12)
          .height(12)
          .fillColor($r('sys.color.ohos_id_color_text_secondary'));
        
        Text(`校准:${this.calibrationValue} ${this.weightingType === WeightingType.A ? 'dB(A)' :
          this.weightingType === WeightingType.C ? 'dB(C)' : 'dB'}`)
          .fontSize(11)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'));
      }

      Blank()

      // 自动保存状态
      if (this.autoSaveCountdown) {
        Row({ space: 4 }) {
          Image($r('app.media.ic_save'))
            .width(12)
            .height(12)
            .fillColor($r('sys.color.ohos_id_color_text_secondary'));
          
          Text(this.autoSaveCountdown)
            .fontSize(11)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'));
        }
      }
    }
    .padding({ top: 8, bottom: 8, left: 12, right: 12 })
    .margin({top: 12})
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(6)
  }

  @Builder
  locationDisplay() {
    if (this.locationInfo) {
      Row({ space: 4 }) {
        Image($r('app.media.ic_location'))
          .width(12)
          .height(12)
          .fillColor($r('sys.color.ohos_id_color_text_secondary'));
        
        Text(this.locationInfo)
          .fontSize(11)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)
          .layoutWeight(1);
      }
      .padding({ top: 6, bottom: 6, left: 12, right: 12 })
      .width('100%')
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(6)
    }
  }

  build() {
    Column({ space: 0 }) {
      // 1. 噪音等级横幅（顶部）
      this.noiseLevelBanner({
        decibelColor: DecibelService.getDecibelColor(this.currentDecibel),
        description: DecibelService.getDecibelDescription(this.currentDecibel)
      })

      // 2. 当前分贝值显示（核心区域）
      this.currentDecibelDisplay({
        decibelColor: DecibelService.getDecibelColor(this.currentDecibel),
        currentDecibel: this.currentDecibel
      })

      // 3. 统计数据展示（最小值-平均值-最大值）
      this.statisticsDisplay({
        minDecibel: this.minDecibel,
        avgDecibel: this.avgDecibel,
        maxDecibel: this.maxDecibel,
        minColor: DecibelService.getDecibelColor(this.minDecibel),
        avgColor: DecibelService.getDecibelColor(this.avgDecibel),
        maxColor: DecibelService.getDecibelColor(this.maxDecibel)
      })

      // 4. 系统状态信息
      this.systemStatusDisplay()

      // 5. 位置信息
      this.locationDisplay()
    }
    .width('100%')
    .borderColor(this.isNoiseAlarm ? DecibelService.getDecibelColor(this.currentDecibel) : Color.Transparent)
    .borderWidth(this.isNoiseAlarm ? 2 : 0)
    .borderRadius(16)
  }
}