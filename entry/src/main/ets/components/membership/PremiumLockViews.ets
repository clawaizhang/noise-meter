/**
 * 专业版锁定视图组件库
 * 
 * 提供三种独立实现的锁定UI方案：
 * 1. SettingLockView - 设置页开关（底部卡片式）
 * 2. TabLockView - Tab选择器（角标式）
 * 3. FullScreenLockView - 核心功能（全屏引导式）
 * 
 * 使用方式：直接在需要的地方引入对应的组件，不再使用统一的PremiumFeature弹框
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2 } from '@kit.ArkUI';
import { 
  MembershipCenterDialog, 
  MembershipCenterDialogProps 
} from './MembershipCenterDialog';
import { DialogHub, InfSheet } from '@hadss/dialoghub';

// ============ 通用工具函数 ============

/**
 * 检查当前用户是否为专业版
 */
export function isProMember(): boolean {
  const pk = PersistenceV2.connect(PreferenceKeys)!;
  return pk.member_ship.can;
}

/**
 * 打开会员中心弹窗
 */
export function openMembershipCenter(onClose?: () => void): void {
  const props: MembershipCenterDialogProps = {
    onClose: () => {
      onClose?.();
    }
  };

  DialogHub.getSheet()
    .setStyle({
      title: { title: '会员中心' },
      backgroundColor: $r('sys.color.background_secondary')
    })
    .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
    .setComponentTargetId('mainId')
    .setContent(wrapBuilder(MembershipCenterDialogBuilder), props)
    .build()
    .show();
}

@Builder
function MembershipCenterDialogBuilder(props: MembershipCenterDialogProps) {
  MembershipCenterDialog({ onClose: props.onClose })
}

// ============ 通用类型定义 ============

export interface BenefitTagItem {
  icon: string;
  text: string;
}

// ============ 场景1：设置页开关（底部卡片式）============

export interface SettingLockViewParams {
  featureId: string;
  featureName: string;
  featureDesc: string;
  benefitTags?: Array<BenefitTagItem>;
  trialPrice?: string;
  onUpgrade?: () => void;
}

@ComponentV2
export struct SettingLockView {
  @Param params: SettingLockViewParams = {
    featureId: '',
    featureName: '专业功能',
    featureDesc: '解锁更多专业功能',
    benefitTags: [
      { icon: '🎁', text: '7天免费试用' },
      { icon: '☁️', text: '云端同步' }
    ],
    trialPrice: '0.01元立即试用'
  };
  @BuilderParam content: () => void;
  @Local private isPressed: boolean = false;

  private handleUnlockClick() {
    Throttle.click(() => {
      openMembershipCenter(() => {
        this.params.onUpgrade?.();
      });
    });
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 底层：置灰的内容预览
      Column() {
        this.content()
      }
      .width('100%')
      .opacity(0.45)
      .enabled(false)
      .blur(1.2)

      // 渐变遮罩
      Column()
        .width('100%')
        .height(100)
        .background(
          'linear-gradient(to bottom, rgba(255,255,255,0) 0%, rgba(255,255,255,0.98) 100%)'
        )

      // 底部解锁引导卡片
      Column({ space: DesignConstants.SPACING_MD }) {
        // 图标 + 标题
        Row({ space: DesignConstants.SPACING_SM }) {
          Stack() {
            Circle()
              .width(44)
              .height(44)
              .fill('rgba(255, 107, 107, 0.12)')
            
            Image($r('app.media.ic_lock'))
              .width(20)
              .height(20)
              .fillColor('#FF6B6B')
          }

          Column({ space: DesignConstants.SPACING_XS }) {
            Row({ space: DesignConstants.SPACING_SM }) {
              Text(this.params.featureName)
                .fontSize(DesignConstants.FONT_SIZE_LG)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('sys.color.font_primary'))
              
              this.ProBadge()
            }

            Text(this.params.featureDesc)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')

        // 权益标签
        if (this.params.benefitTags && this.params.benefitTags.length > 0) {
          Row({ space: DesignConstants.SPACING_SM }) {
            ForEach(this.params.benefitTags, (tag: BenefitTagItem) => {
              this.BenefitTag(tag.icon, tag.text)
            })
          }
          .width('100%')
        }

        // 解锁按钮
        Button() {
          Row({ space: DesignConstants.SPACING_SM }) {
            Text('🔓')
              .fontSize(16)
            Text(this.params.trialPrice || '立即解锁')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
        }
        .width('100%')
        .height(44)
        .backgroundColor('#FF6B6B')
        .borderRadius(22)
        .shadow({
          radius: 8,
          color: 'rgba(255, 107, 107, 0.35)',
          offsetX: 0,
          offsetY: 3
        })
        .stateEffect(true)
        .onClick(() => this.handleUnlockClick())
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.background_primary'))
      .borderRadius({ topLeft: 16, topRight: 16 })
      .shadow({
        radius: 8,
        color: 'rgba(0, 0, 0, 0.06)',
        offsetX: 0,
        offsetY: -2
      })
    }
    .width('100%')
    .clip(true)
  }

  @Builder
  ProBadge() {
    Row({ space: 2 }) {
      Image($r('app.media.ic_vip'))
        .width(10)
        .height(10)
        .fillColor('#FFD700')
      Text('PRO')
        .fontSize(9)
        .fontWeight(FontWeight.Bold)
        .fontColor('#B8860B')
    }
    .padding({ left: 5, right: 5, top: 2, bottom: 2 })
    .backgroundColor('#FFF8DC')
    .border({ width: 0.5, color: '#FFD700' })
    .borderRadius(8)
  }

  @Builder
  BenefitTag(icon: string, text: string) {
    Row({ space: 4 }) {
      Text(icon)
        .fontSize(11)
      Text(text)
        .fontSize(11)
        .fontColor($r('sys.color.font_secondary'))
    }
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(10)
  }
}

// ============ 场景2：Tab选择器（角标式）============

interface TabLockViewParams {
  featureId: string;
  featureName: string;
  featureDesc: string;
  unlockText?: string;
  onUpgrade?: () => void;
}

@ComponentV2
export struct TabLockView {
  @Param params: TabLockViewParams = {
    featureId: '',
    featureName: '专业功能',
    featureDesc: '解锁此功能',
    unlockText: '解锁'
  };
  @BuilderParam content: () => void;
  @Local private showTooltip: boolean = false;

  private handleUnlockClick() {
    Throttle.click(() => {
      openMembershipCenter(() => {
        this.params.onUpgrade?.();
      });
    });
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 置灰的内容
      Column() {
        this.content()
      }
      .width('100%')
      .opacity(0.35)
      .enabled(false)

      // 悬浮解锁提示
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_vip'))
          .width(16)
          .height(16)
          .fillColor('#FFD700')
        
        Text(this.params.unlockText || `解锁${this.params.featureName}`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
        
        Text('›')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontColor($r('sys.color.brand'))
      }
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor($r('sys.color.background_primary'))
      .borderRadius(20)
      .shadow({
        radius: 6,
        color: 'rgba(0, 0, 0, 0.12)'
      })
      .onClick(() => this.handleUnlockClick())
    }
    .width('100%')
    .height('100%')
  }
}

// ============ 场景3：核心功能（全屏引导式）============

interface FeaturePreviewItem {
  icon: string;
  title: string;
  desc: string;
}

interface FullScreenLockViewParams {
  featureId: string;
  featureName: string;
  featureDesc: string;
  previewItems?: FeaturePreviewItem[];
  backgroundContent?: () => void;
  trialDays?: number;
  trialPrice?: string;
  onUpgrade?: () => void;
}

@ComponentV2
export struct FullScreenLockView {
  @Param params: FullScreenLockViewParams = {
    featureId: '',
    featureName: '专业功能',
    featureDesc: '解锁高级功能',
    previewItems: [],
    trialDays: 7,
    trialPrice: '0.01元试用'
  };
  @BuilderParam backgroundContent: () => void;
  @Local private isPressed: boolean = false;

  private handleUnlockClick() {
    Throttle.click(() => {
      openMembershipCenter(() => {
        this.params.onUpgrade?.();
      });
    });
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 背景：模糊的功能预览（如果提供）
      if (this.backgroundContent) {
        Column() {
          this.backgroundContent()
        }
        .width('100%')
        .opacity(0.35)
        .blur(2)
        .grayscale(0.8)
      }

      // 解锁卡片 - 撑满宽度设计
      Column({ space: DesignConstants.SPACING_MD }) {
        // 顶部图标和标题行
        Row({ space: DesignConstants.SPACING_MD }) {
          // VIP 图标
          Stack() {
            Circle()
              .width(48)
              .height(48)
              .fill('rgba(255, 215, 0, 0.15)')
            
            Text('💎')
              .fontSize(24)
          }

          // 标题区域
          Column({ space: DesignConstants.SPACING_XS }) {
            Text(this.params.featureName)
              .fontSize(DesignConstants.FONT_SIZE_LG)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
            
            Text(this.params.featureDesc)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')

        // 功能预览列表 - 横向或纵向
        if (this.params.previewItems && this.params.previewItems.length > 0) {
          Column({ space: DesignConstants.SPACING_XS }) {
            ForEach(this.params.previewItems, (item: FeaturePreviewItem) => {
              this.PreviewItemCompact(item.icon, item.title, item.desc)
            })
          }
          .width('100%')
          .padding(DesignConstants.SPACING_SM)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        }

        // 试用按钮行
        Row({ space: DesignConstants.SPACING_MD }) {
          // 价格信息
          Column({ space: 0 }) {
            Text(`🎁 ${this.params.trialDays || 7}天免费试用`)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))
              .fontWeight(FontWeight.Medium)
            
            Text('0.01元体验价')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_tertiary'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 解锁按钮
          Button('立即解锁')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor(Color.White)
            .backgroundColor('#FF6B6B')
            .borderRadius(20)
            .height(40)
            .padding({ left: 20, right: 20 })
            .shadow({
              radius: 6,
              color: 'rgba(255, 107, 107, 0.3)',
              offsetX: 0,
              offsetY: 2
            })
            .onClick(() => this.handleUnlockClick())
        }
        .width('100%')
        .padding({ top: DesignConstants.SPACING_SM })
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .shadow({
        radius: 12,
        color: 'rgba(0, 0, 0, 0.08)'
      })
    }
    .width('100%')
    .padding({ left: DesignConstants.SPACING_MD, right: DesignConstants.SPACING_MD })
  }

  @Builder
  PreviewItem(icon: string, title: string, desc: string) {
    Row({ space: DesignConstants.SPACING_SM }) {
      Text(icon)
        .fontSize(20)
      
      Column({ space: 2 }) {
        Text(title)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
        
        Text(desc)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }

  // 紧凑版功能预览项
  @Builder
  PreviewItemCompact(icon: string, title: string, desc: string) {
    Row({ space: DesignConstants.SPACING_SM }) {
      Text(icon)
        .fontSize(18)
      
      Column({ space: 0 }) {
        Text(title)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
        
        Text(desc)
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 3, bottom: 3 })
  }
}

// ============ 场景4：列表项锁定（简洁角标式）============

interface ListItemLockViewParams {
  featureName: string;
  lockedCount?: number;
  totalCount?: number;
  onUpgrade?: () => void;
}

@ComponentV2
export struct ListItemLockView {
  @Param params: ListItemLockViewParams = {
    featureName: '记录',
    lockedCount: 0,
    totalCount: 0
  };
  @BuilderParam lockedItemContent: () => void;
  @Local private isPressed: boolean = false;

  private handleUnlockClick() {
    Throttle.click(() => {
      openMembershipCenter(() => {
        this.params.onUpgrade?.();
      });
    });
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 置灰的列表项
      Column() {
        if (this.lockedItemContent) {
          this.lockedItemContent()
        }
      }
      .width('100%')
      .opacity(0.3)
      .enabled(false)

      // 悬浮解锁提示
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_vip'))
          .width(16)
          .height(16)
          .fillColor('#FFD700')
        
        Text(this.getUnlockText())
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
        
        Text('›')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontColor($r('sys.color.brand'))
      }
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor($r('sys.color.background_primary'))
      .borderRadius(20)
      .shadow({
        radius: 6,
        color: 'rgba(0, 0, 0, 0.12)'
      })
      .onClick(() => this.handleUnlockClick())
    }
    .width('100%')
    .height('100%')
  }

  private getUnlockText(): string {
    if (this.params.lockedCount && this.params.lockedCount > 0) {
      return `解锁查看全部 ${this.params.totalCount || '100+'} 条${this.params.featureName}`;
    }
    return `解锁${this.params.featureName}`;
  }
}

// ============ 场景5：简洁PRO标签（仅显示标签）============

interface ProBadgeOnlyParams {
  badgeSize: 'small' | 'medium' | 'large';
}

@ComponentV2
export struct ProBadgeOnly {
  @Param params: ProBadgeOnlyParams = {
    badgeSize: 'small'
  };

  build() {
    Row({ space: 2 }) {
      Image($r('app.media.ic_vip'))
        .width(this.getIconSize())
        .height(this.getIconSize())
        .fillColor('#FFD700')
      
      Text('PRO')
        .fontSize(this.getFontSize())
        .fontWeight(FontWeight.Bold)
        .fontColor('#B8860B')
    }
    .padding(this.getPadding())
    .backgroundColor('#FFF8DC')
    .border({ width: 0.5, color: '#FFD700' })
    .borderRadius(this.getBorderRadius())
  }

  private getIconSize(): number {
    switch (this.params.badgeSize) {
      case 'small': return 10;
      case 'medium': return 12;
      case 'large': return 14;
      default: return 10;
    }
  }

  private getFontSize(): number {
    switch (this.params.badgeSize) {
      case 'small': return 9;
      case 'medium': return 10;
      case 'large': return 12;
      default: return 9;
    }
  }

  private getPadding(): Padding {
    switch (this.params.badgeSize) {
      case 'small': return { left: 5, right: 5, top: 2, bottom: 2 };
      case 'medium': return { left: 6, right: 6, top: 3, bottom: 3 };
      case 'large': return { left: 8, right: 8, top: 4, bottom: 4 };
      default: return { left: 5, right: 5, top: 2, bottom: 2 };
    }
  }

  private getBorderRadius(): number {
    switch (this.params.badgeSize) {
      case 'small': return 8;
      case 'medium': return 10;
      case 'large': return 12;
      default: return 8;
    }
  }
}
