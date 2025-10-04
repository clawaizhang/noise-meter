/**
 * 专业功能包装组件
 * 用于控制会员功能的显示和交互
 */

import { MembershipManager } from '../../services/MembershipManager';
import { DesignConstants } from '../../constants/DesignConstants';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { UpgradeContentBuilder, UpgradeContentProps } from './UpgradeContent';

@ComponentV2
export struct PremiumFeature {
  @BuilderParam content: () => void; // 功能内容
  @Param @Require featureName: string; // 功能名称
  @Param @Require featureDesc: string; // 功能描述
  @Param @Require icon: Resource; // 功能图标
  @Local private upgradeDialog: InfSheet | null = null; // 升级提示弹框

  /**
   * 显示升级提示弹框
   */
  private showUpgradeDialog() {
    let props: UpgradeContentProps = { featureName: this.featureName, featureDesc: this.featureDesc, icon: this.icon }
    if (!this.upgradeDialog) {
      this.upgradeDialog = DialogHub.getSheet()
        .setStyle({
          backgroundColor: $r('sys.color.background_secondary'),
        })
        .setContent(wrapBuilder(UpgradeContentBuilder), props
        )
        .setComponentTargetId('mainId')
        .build();
    }
    this.upgradeDialog.updateContent(props);
    this.upgradeDialog.show();
  }

  build() {
    // 专业版用户直接显示功能
    if (MembershipManager.isProMember()) {
      this.content();
    } else {
      // 免费用户显示带锁标识的置灰功能
      Stack({ alignContent: Alignment.TopEnd }) {
        // 功能内容（置灰显示）
        Column() {
          this.content()
        }
        .enabled(false)

        // 锁形图标（右上角）
        Image($r('app.media.ic_vip'))
          .width(20)
          .height(20)
          .margin({ top: 2, right: 2 })
      }
      .onClick(() => {
        this.showUpgradeDialog();
      })
    }
  }
}

