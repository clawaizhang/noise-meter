/**
 * 专业功能包装组件
 * 用于控制会员功能的显示和交互
 * 集成新的会员升级页面系统
 */

import { MembershipManager } from '../../services/MembershipManager';
import { DesignConstants } from '../../constants/DesignConstants';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { UpgradeContent, defaultPricingPlans, defaultFeatureComparison, UpgradeContentProps,
  UpgradeContentBuilder } from './UpgradeContent';

@ComponentV2
export struct PremiumFeature {
  @BuilderParam content: () => void; // 功能内容
  @Param @Require featureName: string; // 功能名称
  @Param @Require featureDesc: string; // 功能描述
  @Param @Require icon: Resource; // 功能图标
  @Event onUpgrade?: () => void; // 升级成功回调
  @Param showTrialOption: boolean = false; // 是否显示试用选项
  @Local private upgradeDialog: InfSheet | null = null; // 升级提示弹框

  /**
   * 显示升级提示弹框
   */
  private showUpgradeDialog() {
   let props:UpgradeContentProps = {
      featureName: this.featureName,
      featureDesc: this.featureDesc,
    icon: this.icon,
    pricingPlans: defaultPricingPlans,
    featureComparison: this.getFeatureComparison(),
    onUpgrade: () => {
      // 升级成功处理
      console.info(`功能 "${this.featureName}" 已解锁`);
      if (this.onUpgrade) {
        this.onUpgrade();
      }
      // 关闭弹窗
      if (this.upgradeDialog) {
        this.upgradeDialog.dismiss();
      }
    },
    onLater: () => {
      // 用户选择稍后再说
      console.info(`用户暂不升级 "${this.featureName}"`);
      if (this.upgradeDialog) {
        this.upgradeDialog.dismiss();
      }
    },
    showTrialOption: this.showTrialOption
    }
    if (!this.upgradeDialog) {
      this.upgradeDialog = DialogHub.getSheet()
        .setStyle({
          backgroundColor: $r('sys.color.background_primary'),
        })
        .setContent(wrapBuilder(UpgradeContentBuilder),props)
        .setComponentTargetId('mainId')
        .build();
    }
    this.upgradeDialog.show();
  }

  /**
   * 获取功能对比配置
   */
  private getFeatureComparison() {
    // 基于当前功能生成特定的对比配置
    const baseComparison = [...defaultFeatureComparison];
    
    // 可以根据具体功能调整对比内容
    switch (this.featureName) {
      case '频率加权模式':
        return baseComparison.filter(item =>
          item.feature === '频率加权' ||
          item.feature === '广告显示'
        );
      case '音频分析模式':
        return baseComparison.filter(item =>
          item.feature === '音频分析' ||
          item.feature === '广告显示'
        );
      case '自定义模式':
        return baseComparison.filter(item =>
          item.feature === '自定义设置' ||
          item.feature === '广告显示'
        );
      case '智能时段警报':
        return baseComparison.filter(item =>
          item.feature === '警报系统' ||
          item.feature === '广告显示'
        );
      default:
        return baseComparison;
    }
  }

  build() {
    // 专业版用户直接显示功能
    if (MembershipManager.hasProFeature()) {
      this.content();
    } else {
      // 免费用户显示带锁标识的置灰功能
      Stack({ alignContent: Alignment.TopEnd }) {
        // 功能内容（置灰显示）
        Column() {
          this.content()
        }
        .enabled(false)
        .opacity(DesignConstants.OPACITY_DISABLED)

        // vip图标（右上角）
        Image($r('app.media.ic_vip'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.font_tertiary'))
          .margin({ top: DesignConstants.SPACING_SM, right: DesignConstants.SPACING_SM })
        
      }
      .border({
        width: DesignConstants.BORDER_WIDTH_SM,
        color: $r('sys.color.comp_border_color')
      })
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .backgroundColor($r('sys.color.background_secondary'))
      .onClick(() => {
        this.showUpgradeDialog();
      })
      .gesture(
        // 添加长按提示
        LongPressGesture({ repeat: false })
          .onAction((event: GestureEvent) => {
            if (event.repeat) {
              console.info(`长按功能 "${this.featureName}"`);
            }
          })
      )
    }
  }
}

