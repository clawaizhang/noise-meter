import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { navigationStack } from '../../constants/ProviderConstant';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { NoiseDescriptionDialogBuilder } from '../../pages/noisemeter/NoiseDescriptionDialogNavigation';
import { NoiseStandardDialogBuilder } from '../../pages/noisemeter/NoiseStandardDialogNavigation';
import { Throttle } from '../../utils/Debounce';
import { DialogStyleManager } from '../../utils/DialogStyleManager';

// 参考功能卡片配置
interface ReferenceCardConfig {
  title: string;
  icon: Resource;
  description: string;
  onTap: () => void;
}

@ComponentV2
export struct ReferenceContent {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

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
          onTap: () => { this.openNoiseDescriptionDialog() }
        })
      }
      
      // 噪音参考标准
      GridCol({ span: 1 }) {
        this.buildReferenceCard({
          title: '噪音参考标准',
          icon: $r('app.media.ic_document_edit'),
          description: '国家标准限值参考',
          onTap: () => { this.openNoiseStandardDialog() }
        })
      }
    }
    .width('100%')
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
    })
  }
}