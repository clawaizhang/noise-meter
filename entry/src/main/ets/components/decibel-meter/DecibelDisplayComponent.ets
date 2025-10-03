import { DecibelService } from '../../services/DecibelService';
import { WeightingType } from '../../constants/WeightingConstants';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { resourceManager } from '@kit.LocalizationKit';
import { DialogStyleManager } from '../../utils/DialogStyleManager';
import { NoiseDescriptionDialogBuilder } from '../../pages/noisemeter/NoiseDescriptionDialogNavigation';
import { NoiseStandardDialogBuilder } from '../../pages/noisemeter/NoiseStandardDialogNavigation';
import { AppKeys } from '../../models/AppKeys';
import { AppStorageV2, curves } from '@kit.ArkUI';
import { interval, Subscription } from 'rxjs';

// 噪音等级横幅配置接口
interface NoiseBannerConfig {
  description: string;
}

// 当前分贝显示配置接口
interface CurrentDecibelConfig {
  decibelColor?: ResourceColor;
  currentDecibel: number;
}

// 统计数据配置接口
interface StatisticsConfig {
  minDecibel: number;
  avgDecibel: number;
  maxDecibel: number;
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
  
  // 内部状态
  noiseStandardSub?: Subscription;
  
  // DialogHub实例缓存
  private noiseDescriptionDialog: InfSheet | null = null;
  private noiseStandardDialog: InfSheet | null = null;

  // 定时器管理
  private noiseDescriptionUpdateIntervalId: number | null = null;
  private noiseStandardUpdateSubscription?: Subscription;
  
  @Local as: AppKeys = AppStorageV2.connect(AppKeys)!;
  sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();

  aboutToAppear() {
    // 初始化稳定描述
  }

  aboutToDisappear() {
    // 清理资源
    this.noiseStandardSub?.unsubscribe();
    
    // 清理DialogHub定时器
    this.cleanupDialogTimers();
    
    // 注销Dialog
    if (this.noiseDescriptionDialog) {
      DialogStyleManager.unregisterDialog(this.noiseDescriptionDialog);
    }
    if (this.noiseStandardDialog) {
      DialogStyleManager.unregisterDialog(this.noiseStandardDialog);
    }
  }
  
  // 清理DialogHub相关定时器
  private cleanupDialogTimers() {
    // 清理噪音描述对话框定时器
    if (this.noiseDescriptionUpdateIntervalId) {
      clearInterval(this.noiseDescriptionUpdateIntervalId);
      this.noiseDescriptionUpdateIntervalId = null;
    }
    
    // 清理噪音标准对话框定时器
    this.noiseStandardUpdateSubscription?.unsubscribe();
    this.noiseStandardUpdateSubscription = undefined;
  }

  @Builder
  noiseLevelBanner(config: NoiseBannerConfig) {
    Row({ space: 8 }) {
      Image($r('app.media.ic_info'))
        .width(14)
        .height(14)
        .fillColor($r('sys.color.font_secondary'));

      Text(config.description)
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'))
        .fontWeight(FontWeight.Medium);
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .borderRadius(6)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (!this.noiseDescriptionDialog) {
        this.noiseDescriptionDialog = DialogHub.getSheet()
          .setContent(wrapBuilder(NoiseDescriptionDialogBuilder), this.as)
          .setStyle({ backgroundColor: $r('sys.color.background_secondary') })
          .setConfig({ enableOutsideInteractive: true, scrollSizeMode: ScrollSizeMode.CONTINUOUS })
          .setComponentTargetId('popupTargetId')
          .build();
        
        // 注册Dialog到样式管理器
        DialogStyleManager.registerDialog(this.noiseDescriptionDialog);
      }
      this.noiseDescriptionDialog.show();
      
      // 清理之前的定时器并启动新的
      if (this.noiseDescriptionUpdateIntervalId) {
        clearInterval(this.noiseDescriptionUpdateIntervalId);
      }
      this.noiseDescriptionUpdateIntervalId = setInterval(() => {
        this.noiseDescriptionDialog?.updateContent(this.as);
      }, 100);
    })
    .id('noiseLevelBannerId')
  }

  @Builder
  currentDecibelDisplay(config: CurrentDecibelConfig) {
    Row({ space: 8 }) {
      if (config.currentDecibel === 0) {
        Text('-')
          .fontSize(64)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.alert'))
          .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }));
      } else {
        Text(`${config.currentDecibel}dB`)
          .fontSize(64)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.alert'))
          .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }));
      }
    }
    .padding({ top: 16, bottom: 16 })
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Bottom)
    .id('currentDbComp')
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
          .fontColor($r('sys.color.font_secondary'))
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
          .fontColor($r('sys.color.font_secondary'))
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
          .fontColor($r('sys.color.font_secondary'))
          .textAlign(TextAlign.Center)
          .width('100%');
      }
      .layoutWeight(1)
    }
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
    .width('100%')
    // 移除背景色，使用透明背景
    .backgroundColor(Color.Transparent)
    .borderRadius(0)
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
    // 移除背景色，使用透明背景
    .backgroundColor(Color.Transparent)
    .borderRadius(0)
  }

  @Builder
  noiseStandardDisplay() {
    Row({ space: 6 }) {
      Image($r('app.media.ic_info'))
        .width(12)
        .height(12)
        .fillColor($r('sys.color.ohos_id_color_text_secondary'));
      
      Text('噪音参考标准')
        .fontSize(11)
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .layoutWeight(1);
      
      Image($r('app.media.ic_arrow_right'))
        .width(10)
        .height(10)
        .fillColor($r('sys.color.ohos_id_color_text_secondary'));
    }
    .padding({ top: 6, bottom: 6, left: 12, right: 12 })
    .margin({top: 12})
    .width('100%')
    // 移除背景色，使用透明背景
    .backgroundColor(Color.Transparent)
    .borderRadius(0)
    .onClick(() => {
      // 点击打开噪音参考标准对话框
      if (!this.noiseStandardDialog) {
        this.noiseStandardDialog = DialogHub.getSheet()
          .setStyle({ backgroundColor: $r('sys.color.background_secondary') })
          .setComponentTargetId('popupTargetId')
          .setConfig({ enableOutsideInteractive: true, scrollSizeMode: ScrollSizeMode.CONTINUOUS })
          .setContent(wrapBuilder(NoiseStandardDialogBuilder), this.as)
          .build();
        
        // 注册Dialog到样式管理器
        DialogStyleManager.registerDialog(this.noiseStandardDialog);
      }
      this.noiseStandardDialog.show();
      
      // 清理之前的订阅并启动新的
      this.noiseStandardUpdateSubscription?.unsubscribe();
      this.noiseStandardUpdateSubscription = interval(500).subscribe(() => {
        this.noiseStandardDialog?.updateContent(this.as);
      });
    })
    .id('noiseStandardDisplayId')
  }


  build() {
    Column({ space: 0 }) {
      // 1. 噪音等级横幅（顶部）
      this.noiseLevelBanner({
        description: DecibelService.getDecibelDescription(this.currentDecibel)
      })

      // 2. 当前分贝值显示（核心区域）
      this.currentDecibelDisplay({
        currentDecibel: this.currentDecibel
      })

      // 3. 统计数据展示（最小值-平均值-最大值）
      this.statisticsDisplay({
        minDecibel: this.minDecibel,
        avgDecibel: this.avgDecibel,
        maxDecibel: this.maxDecibel
      })

      // 4. 系统状态信息
      this.systemStatusDisplay()

      // 5. 噪音参考标准
      this.noiseStandardDisplay()
    }
    .width('100%')
    .borderColor(this.isNoiseAlarm ? DecibelService.getDecibelColor(this.currentDecibel) : Color.Transparent)
    .borderWidth(this.isNoiseAlarm ? 2 : 0)
    .borderRadius(0)
  }
}