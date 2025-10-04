import { UpgradeContent, defaultPricingPlans, defaultFeatureComparison } from './UpgradeContent'
import { DialogHub } from '@ohos/dialog'

/**
 * 会员升级页面使用示例
 * 这个文件展示了如何在DialogHub中使用新的UpgradeContent组件
 */

// 在DialogHub中显示会员升级弹窗的示例函数
export function showMembershipUpgradeDialog(
  featureName: string,
  featureDesc: string,
  icon: Resource,
  onUpgrade?: () => void,
  onLater?: () => void
) {
  DialogHub.show({
    content: () => {
      UpgradeContent({
        featureName: featureName,
        featureDesc: featureDesc,
        icon: icon,
        pricingPlans: defaultPricingPlans,
        featureComparison: defaultFeatureComparison,
        onUpgrade: () => {
          // 购买成功后的处理
          console.info('会员升级成功');
          if (onUpgrade) {
            onUpgrade();
          }
          DialogHub.dismiss();
        },
        onLater: () => {
          // 用户选择稍后再说
          console.info('用户选择稍后升级');
          if (onLater) {
            onLater();
          }
          DialogHub.dismiss();
        },
        showTrialOption: true
      })
    },
    // 弹窗配置
    modalTransition: {
      type: 'slide',
      options: {
        direction: 'bottom'
      }
    },
    // 点击背景关闭
    autoCancel: true,
    // 自定义样式
    customStyle: {
      backgroundColor: $r('sys.color.background_primary'),
      borderRadius: DesignConstants.BORDER_RADIUS_LG,
      margin: {
        left: DesignConstants.SPACING_LG,
        right: DesignConstants.SPACING_LG
      }
    }
  })
}

// 频率加权功能的升级弹窗示例
export function showFrequencyWeightingUpgrade() {
  showMembershipUpgradeDialog(
    '频率加权模式',
    '解锁A/C/Z计权等专业功能',
    $r('app.media.ic_frequency_weighting'),
    () => {
      // 购买成功后的回调
      console.info('频率加权功能已解锁');
      // 这里可以更新应用状态，解锁专业功能
    },
    () => {
      // 用户取消的回调
      console.info('用户暂不升级频率加权功能');
    }
  )
}

// 音频分析模式的升级弹窗示例
export function showAudioAnalysisUpgrade() {
  showMembershipUpgradeDialog(
    '音频分析模式',
    '解锁快速/慢速/脉冲响应等专业分析',
    $r('app.media.ic_audio_analysis'),
    () => {
      console.info('音频分析模式已解锁');
      // 解锁音频分析功能
    },
    () => {
      console.info('用户暂不升级音频分析模式');
    }
  )
}

// 自定义模式的升级弹窗示例
export function showCustomModeUpgrade() {
  showMembershipUpgradeDialog(
    '自定义模式',
    '解锁FFT参数自定义等高级配置',
    $r('app.media.ic_settings'),
    () => {
      console.info('自定义模式已解锁');
      // 解锁自定义模式功能
    },
    () => {
      console.info('用户暂不升级自定义模式');
    }
  )
}

// 智能警报的升级弹窗示例
export function showSmartAlertsUpgrade() {
  showMembershipUpgradeDialog(
    '智能时段警报',
    '解锁基于时间段的智能提醒系统',
    $r('app.media.ic_alarm'),
    () => {
      console.info('智能时段警报已解锁');
      // 解锁智能警报功能
    },
    () => {
      console.info('用户暂不升级智能警报');
    }
  )
}

// 完整会员功能的升级弹窗示例
export function showFullMembershipUpgrade() {
  showMembershipUpgradeDialog(
    '专业版会员',
    '解锁所有专业功能，提升测量体验',
    $r('app.media.ic_vip'),
    () => {
      console.info('专业版会员已激活');
      // 激活所有专业功能
    },
    () => {
      console.info('用户暂不升级专业版');
    }
  )
}

// 在PremiumFeature组件中的使用示例
@ComponentV2
export struct PremiumFeatureExample {
  @State isProMember: boolean = false;

  build() {
    Column() {
      if (this.isProMember) {
        // 专业用户显示完整功能
        this.buildProFeatureContent()
      } else {
        // 免费用户显示升级提示
        this.buildUpgradePrompt()
      }
    }
  }

  @Builder
  private buildProFeatureContent() {
    // 专业功能的完整实现
    Text('专业功能内容')
      .fontSize(DesignConstants.FONT_SIZE_LG)
      .fontColor($r('sys.color.font_primary'))
  }

  @Builder
  private buildUpgradePrompt() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 功能预览（置灰显示）
      this.buildProFeatureContent()
        .opacity(DesignConstants.OPACITY_DISABLED)
        .enabled(false)
      
      // 升级提示
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_lock'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor($r('sys.color.text_tertiary'))
        
        Text('专业功能')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.text_tertiary'))
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .onClick(() => {
        // 点击显示升级弹窗
        showMembershipUpgradeDialog(
          '专业功能',
          '解锁此功能的完整版本',
          $r('app.media.ic_lock'),
          () => {
            // 购买成功后更新状态
            this.isProMember = true;
          },
          () => {
            // 用户取消
            console.info('用户暂不升级');
          }
        )
      })
    }
  }
}

// 会员状态管理示例
export class MembershipExampleManager {
  // 检查是否为专业会员
  static isProMember(): boolean {
    // 这里应该从本地存储或服务器获取会员状态
    // 暂时返回false作为示例
    return false;
  }

  // 激活专业会员
  static activateProMembership(planType: string) {
    console.info(`激活专业会员，方案类型: ${planType}`);
    // 这里应该更新本地存储和服务器状态
    // 暂时只记录日志
  }

  // 检查特定功能权限
  static hasFeaturePermission(feature: string): boolean {
    const proFeatures = [
      'frequency_weighting',
      'audio_analysis', 
      'custom_mode',
      'smart_alerts'
    ];
    
    if (proFeatures.includes(feature)) {
      return this.isProMember();
    }
    
    // 基础功能对所有用户开放
    return true;
  }
}

// 使用示例说明
/**
 * 使用方法：
 * 
 * 1. 在需要显示升级提示的地方调用：
 *    showFrequencyWeightingUpgrade()
 * 
 * 2. 在PremiumFeature组件中使用：
 *    PremiumFeatureExample()
 * 
 * 3. 检查功能权限：
 *    if (MembershipExampleManager.hasFeaturePermission('frequency_weighting')) {
 *        // 显示专业功能
 *    } else {
 *        // 显示升级提示
 *    }
 */