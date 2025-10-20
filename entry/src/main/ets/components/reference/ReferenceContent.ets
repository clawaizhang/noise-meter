import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { navigationStack } from '../../constants/ProviderConstant';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { NoiseDescriptionDialogBuilder } from '../../pages/noisemeter/NoiseDescriptionDialogNavigation';
import { NoiseStandardDialogBuilder } from '../../pages/noisemeter/NoiseStandardDialogNavigation';
import { Throttle } from '../../utils/Debounce';
import { DecibelService } from '../../services/DecibelService';
import { NoiseStandards } from '../../constants/NoiseStandardConstants';
import { NoiseStandard } from '../../models/NoiseStandard';
import { DialogStyleManager } from '../../utils/DialogStyleManager';
import { interval, Subscription } from 'rxjs';

// 参考功能卡片配置
interface ReferenceCardConfig {
  title: string;
  icon: Resource;
  description: string;
  currentValue?: string;
  currentColor?: Resource;
  onTap: () => void;
}

// 噪音场景描述
interface DecibelDescription {
  description: string;
  db: number;
  color: Resource;
}

const decibelDescriptions: DecibelDescription[] = [
  { description: '喷气发动机', db: 140, color: $r('app.color.decibel_unbearable') },
  { description: '飞机起飞', db: 130, color: $r('app.color.decibel_very_noisy') },
  { description: '摇滚音乐会', db: 110, color: $r('app.color.decibel_very_noisy') },
  { description: '建筑工地', db: 85, color: $r('app.color.decibel_noisy') },
  { description: '地铁列车', db: 85, color: $r('app.color.decibel_noisy') },
  { description: '重型卡车', db: 85, color: $r('app.color.decibel_noisy') },
  { description: '繁忙的街道', db: 80, color: $r('app.color.decibel_noisy') },
  { description: '繁忙的餐厅', db: 70, color: $r('app.color.decibel_normal') },
  { description: '普通对话', db: 60, color: $r('app.color.decibel_normal') },
  { description: '安静的办公室', db: 50, color: $r('app.color.decibel_quiet') },
  { description: '安静的图书馆', db: 40, color: $r('app.color.decibel_quiet') },
  { description: '耳语声', db: 30, color: $r('app.color.decibel_very_quiet') },
  { description: '安静的录音室', db: 20, color: $r('app.color.decibel_very_quiet') },
  { description: '几乎无声', db: 10, color: $r('app.color.decibel_very_quiet') },
];

@ComponentV2
export struct ReferenceContent {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  
  // 定时器管理
  private noiseDescriptionUpdateIntervalId: number | null = null;
  private noiseStandardUpdateSubscription: Subscription | undefined;

  aboutToDisappear() {
    // 清理定时器
    if (this.noiseDescriptionUpdateIntervalId) {
      clearInterval(this.noiseDescriptionUpdateIntervalId);
      this.noiseDescriptionUpdateIntervalId = null;
    }
    
    // 清理订阅
    this.noiseStandardUpdateSubscription?.unsubscribe();
    this.noiseStandardUpdateSubscription = undefined;
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 页面标题
      this.buildPageHeader()
      
      // 参考功能卡片区
      this.buildReferenceCards()
    }
    .width('100%')
    .height('100%')
    .padding(DesignConstants.SPACING_MD)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  private buildPageHeader() {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text('参考信息')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
      
      Text('噪音场景和标准参考')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  @Builder
  private buildReferenceCards() {
    GridRow({ columns: 2, gutter: DesignConstants.SPACING_MD }) {
      // 噪音场景参考
      GridCol({ span: 1 }) {
        this.buildReferenceCard({
          title: '噪音场景参考',
          icon: $r('app.media.ic_info'),
          description: '常见环境噪音分贝对照',
          currentValue: `${this.ak.uiDisplayState.displayDb} dB`,
          currentColor: DecibelService.getDecibelColor(this.ak.uiDisplayState.displayDb),
          onTap: () => { this.openNoiseDescriptionDialog() }
        })
      }
      
      // 噪音参考标准
      GridCol({ span: 1 }) {
        this.buildReferenceCard({
          title: '噪音参考标准',
          icon: $r('app.media.ic_document_edit'),
          description: '国家标准限值参考',
          currentValue: this.getCurrentStandardStatus(),
          currentColor: this.getCurrentStandardColor(),
          onTap: () => { this.openNoiseStandardDialog() }
        })
      }
    }
    .width('100%')

    // 实时对比显示区域
    this.buildRealTimeComparison()

  }

  @Builder
  private buildReferenceCard(config: ReferenceCardConfig) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标区域
      Image(config.icon)
        .width(32)
        .height(32)
        .fillColor($r('sys.color.icon_primary'))

      // 右侧内容区域
      Column({ space: DesignConstants.SPACING_XS }) {
        // 标题行
        Row() {
          Text(config.title)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
          
          Blank()
        }
        .width('100%')

        // 描述行
        Row() {
          Text(config.description)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
          
          Blank()
        }
        .width('100%')

        // 当前值显示区域
        if (config.currentValue) {
          Row() {
            Text(config.currentValue)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontWeight(FontWeight.Medium)
              .fontColor(config.currentColor || $r('sys.color.font_primary'))
            
            Blank()
          }
          .width('100%')
          .margin({ top: DesignConstants.SPACING_XS })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(80)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .shadow(DesignConstants.SHADOW_SM)
    .onClick(config.onTap)
  }

  @Builder
  private buildRealTimeComparison() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('实时对比')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 当前分贝值显示
      Row() {
        Text('当前分贝值:')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
        
        Text(`${this.ak.uiDisplayState.displayDb} dB`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontWeight(FontWeight.Medium)
          .fontColor(DecibelService.getDecibelColor(this.ak.uiDisplayState.displayDb))
          .margin({ left: DesignConstants.SPACING_XS })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      // 最接近的噪音场景
      if (this.ClosestNoiseScene) {
        Row() {
          Text('最接近场景:')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
          
          Text(this.ClosestNoiseScene.description)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.ClosestNoiseScene.color)
            .margin({ left: DesignConstants.SPACING_XS })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }

      // 标准符合情况
      Row() {
        Text('标准符合:')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
        
        Text(this.StandardCompliance)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getStandardComplianceColor())
          .margin({ left: DesignConstants.SPACING_XS })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%').margin({ top: DesignConstants.SPACING_MD })
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  // 获取最接近的噪音场景
  @Computed
  private get ClosestNoiseScene(): DecibelDescription | null {
    const currentDb = this.ak.uiDisplayState.displayDb;
    let closestScene: DecibelDescription | null = null;
    let minDiff = Infinity;

    for (const scene of decibelDescriptions) {
      const diff = Math.abs(scene.db - currentDb);
      if (diff < minDiff) {
        minDiff = diff;
        closestScene = scene;
      }
    }

    return closestScene;
  }

  // 获取当前标准状态
  private getCurrentStandardStatus(): string {
    const currentDb = this.ak.uiDisplayState.displayDb;
    const residentialStandard = NoiseStandards[0]; // 居住区标准
    
    if (currentDb < residentialStandard.dayLimit) {
      return '符合标准';
    } else if (currentDb < residentialStandard.dayLimit + 10) {
      return '轻度超标';
    } else {
      return '严重超标';
    }
  }

  // 获取当前标准状态颜色
  private getCurrentStandardColor(): Resource {
    const currentDb = this.ak.uiDisplayState.displayDb;
    const residentialStandard = NoiseStandards[0]; // 居住区标准
    
    if (currentDb < residentialStandard.dayLimit) {
      return $r('sys.color.confirm');
    } else if (currentDb < residentialStandard.dayLimit + 10) {
      return $r('sys.color.warning');
    } else {
      return $r('sys.color.alert');
    }
  }

  // 获取标准符合情况
  @Computed
  private get StandardCompliance(): string {
    const currentDb = this.ak.uiDisplayState.displayDb;
    const residentialStandard = NoiseStandards[0]; // 居住区标准
    
    if (currentDb < residentialStandard.dayLimit) {
      return '符合居住区标准';
    } else if (currentDb < residentialStandard.nightLimit) {
      return '符合夜间标准';
    } else {
      return '超出标准限值';
    }
  }

  // 获取标准符合情况颜色
  private getStandardComplianceColor(): Resource {
    const currentDb = this.ak.uiDisplayState.displayDb;
    const residentialStandard = NoiseStandards[0]; // 居住区标准
    
    if (currentDb < residentialStandard.dayLimit) {
      return $r('sys.color.confirm');
    } else if (currentDb < residentialStandard.nightLimit) {
      return $r('sys.color.warning');
    } else {
      return $r('sys.color.alert');
    }
  }

  // 打开噪音场景参考对话框
  private openNoiseDescriptionDialog() {
    Throttle.click(() => {
      const noiseDescriptionDialog = DialogHub.getSheet()
        .setStyle({ backgroundColor: $r('sys.color.background_secondary') })
        .setComponentTargetId('mainId')
        .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
        .setContent(wrapBuilder(NoiseDescriptionDialogBuilder), this.ak)
        .build();

      // 注册Dialog到样式管理器
      DialogStyleManager.registerDialog(noiseDescriptionDialog);
      noiseDescriptionDialog.show();

      // 添加实时更新机制 - 每100ms更新
      if (this.noiseDescriptionUpdateIntervalId) {
        clearInterval(this.noiseDescriptionUpdateIntervalId);
      }
      this.noiseDescriptionUpdateIntervalId = setInterval(() => {
        noiseDescriptionDialog.updateContent(this.ak);
      }, 100);
    })
  }

  // 打开噪音参考标准对话框
  private openNoiseStandardDialog() {
    Throttle.click(() => {
      const noiseStandardDialog = DialogHub.getSheet()
        .setStyle({ backgroundColor: $r('sys.color.background_secondary') })
        .setComponentTargetId('mainId')
        .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
        .setContent(wrapBuilder(NoiseStandardDialogBuilder), this.ak)
        .build();

      // 注册Dialog到样式管理器
      DialogStyleManager.registerDialog(noiseStandardDialog);
      noiseStandardDialog.show();

      // 添加实时更新机制 - 每500ms更新
      this.noiseStandardUpdateSubscription?.unsubscribe();
      this.noiseStandardUpdateSubscription = interval(500).subscribe(() => {
        noiseStandardDialog.updateContent(this.ak);
      });
    })
  }
}