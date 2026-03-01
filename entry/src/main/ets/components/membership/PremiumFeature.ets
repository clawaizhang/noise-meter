/**
 * 专业功能包装组件
 * 用于控制会员功能的显示和交互
 * 集成新的会员升级页面系统
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { defaultPricingPlans, UpgradeContentBuilder, UpgradeContentProps } from './UpgradeContent';
import { DialogStyleManager } from '../../utils/DialogStyleManager';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2 } from '@kit.ArkUI';
import { Throttle } from '../../utils/Debounce';

@ComponentV2
export struct PremiumFeature {
  @BuilderParam content: () => void; // 功能内容
  @Param @Require featureName: string; // 功能名称
  @Param @Require featureDesc: string; // 功能描述
  @Param icon: Resource = $r('app.media.ic_vip'); // 功能图标
  @Event onUpgrade?: () => void; // 升级成功回调
  @Param showTrialOption: boolean = false; // 是否显示试用选项
  @Local private upgradeDialog: InfSheet | null = null; // 升级提示弹框
  @Local private pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!; // 升级提示弹框
  private props: UpgradeContentProps = {
    featureName: this.featureName,
    featureDesc: this.featureDesc,
    icon: this.icon,
    pricingPlans: defaultPricingPlans,
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

  private createDialog(): InfSheet {
    return DialogHub.getSheet()
      .setStyle({
        backgroundColor: $r('sys.color.background_secondary'),
      })
      .setContent(wrapBuilder(UpgradeContentBuilder), this.props)
      .setComponentTargetId('mainId')
      .build();
  }

  /**
   * 显示升级提示弹框
   */
  private showUpgradeDialog() {
      this.upgradeDialog = this.createDialog();
      this.upgradeDialog.getStatus()
    this.upgradeDialog.show();
  }

  build() {
    // 专业版用户直接显示功能
    if (this.pk.member_ship.can) {
      this.content();
    } else {
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
          .margin({ top: DesignConstants.SPACING_XS, right: DesignConstants.SPACING_XS })
          .fillColor($r('sys.color.icon_emphasize'))

      }
      .border({
        width: DesignConstants.BORDER_WIDTH_SM,
        color: $r('sys.color.comp_border_color')
      })
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .backgroundColor($r('sys.color.background_secondary'))
      .onClick(() => {
        Throttle.click(() => {
          this.showUpgradeDialog();
        });
      })
    }
  }
}

