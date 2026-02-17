/**
 * 专业功能包装组件 - 升级版
 * 
 * 功能分层策略：
 * - 完全锁定模式：功能完全隐藏/置灰，点击弹出升级提示（适用于核心付费功能）
 * - 软限制模式：功能可用但有限制，超出限制后提示升级（适用于数据存储类）
 * - 对比模式：显示功能对比表，让用户了解差异（适用于设置页）
 * 
 * 设计参考：MembershipCenterDialog、UpgradeContent
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2 } from '@kit.ArkUI';
import { Throttle } from '../../utils/Debounce';
import { MembershipCenterDialog, MembershipCenterDialogProps } from './MembershipCenterDialog';

/** 锁定模式枚举 */
export enum PremiumLockMode {
  /** 完全锁定 - 置灰显示，点击弹出升级 */
  FULL_LOCK = 'FULL_LOCK',
  /** 软限制 - 显示可用状态，使用时检查限制 */
  SOFT_LIMIT = 'SOFT_LIMIT',
  /** 对比展示 - 显示功能对比，不阻止使用 */
  COMPARISON = 'COMPARISON',
  /** 仅标签 - 显示VIP标签但不阻止使用 */
  BADGE_ONLY = 'BADGE_ONLY'
}

/** 功能限制类型 */
export enum LimitType {
  /** 次数限制 */
  COUNT = 'COUNT',
  /** 时间限制 */
  TIME = 'TIME',
  /** 数据量限制 */
  DATA_SIZE = 'DATA_SIZE',
  /** 功能范围限制 */
  SCOPE = 'SCOPE'
}

/** 功能限制配置 */
export interface FeatureLimit {
  type: LimitType;
  freeLimit: number;      // 免费版限制
  proLimit: number;       // 专业版限制（-1表示无限制）
  currentValue: number;   // 当前已使用值
  unit?: string;          // 单位（次、天、条等）
}

/** 功能对比项 */
export interface FeatureComparisonItem {
  feature: string;        // 功能名称
  freeDesc: string;       // 免费版描述
  proDesc: string;        // 专业版描述
  isHighlight?: boolean;  // 是否高亮差异
}

/** 组件配置接口 */
export interface PremiumFeatureConfig {
  /** 功能ID */
  featureId: string;
  /** 功能名称 */
  featureName: string;
  /** 功能描述 */
  featureDesc: string;
  /** 功能图标 */
  icon: Resource;
  /** 锁定模式 */
  lockMode: PremiumLockMode;
  /** 功能限制（软限制模式下使用） */
  limit?: FeatureLimit;
  /** 功能对比列表（对比模式下使用） */
  comparisonList?: FeatureComparisonItem[];
  /** 是否显示试用提示 */
  showTrialTip?: boolean;
  /** 试用天数 */
  trialDays?: number;
  /** 解锁成功回调 */
  onUnlock?: () => void;
}

/** 升级提示类型 */
export enum UpgradePromptType {
  /** 功能解锁提示 */
  FEATURE_UNLOCK = 'FEATURE_UNLOCK',
  /** 限制达到提示 */
  LIMIT_REACHED = 'LIMIT_REACHED',
  /** 功能对比提示 */
  COMPARISON = 'COMPARISON',
  /** 试用邀请提示 */
  TRIAL_INVITE = 'TRIAL_INVITE'
}

@ComponentV2
export struct PremiumFeature {
  // 基础配置参数
  @Param @Require featureId: string;
  @Param @Require featureName: string;
  @Param @Require featureDesc: string;
  @Param icon: Resource = $r('app.media.ic_vip');
  @Param lockMode: PremiumLockMode = PremiumLockMode.FULL_LOCK;
  @Param limit: FeatureLimit | null = null;
  @Param comparisonList: FeatureComparisonItem[] = [];
  @Param showTrialTip: boolean = true;
  @Param trialDays: number = 7;
  
  // 内容构建器 - 只有一个@BuilderParam，通过trailing lambda传入
  @BuilderParam content: () => void;
  
  // 回调
  @Event onUpgradeClick: () => void = () => {};
  @Event onUnlock: () => void = () => {};
  @Event onLimitReached: () => void = () => {};
  
  // 本地状态
  @Local private pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local private upgradeDialog: InfSheet | null = null;
  @Local private isPressed: boolean = false;
  @Local private showLimitWarning: boolean = false;
  
  // 计算属性：是否为专业版用户
  @Computed
  get isProMember(): boolean {
    return this.pk.member_ship.can;
  }
  
  // 计算属性：是否已超限
  @Computed
  get isLimitExceeded(): boolean {
    if (!this.limit) return false;
    return this.limit.currentValue >= this.limit.freeLimit;
  }
  
  // 计算属性：限制进度
  @Computed
  get limitProgress(): number {
    if (!this.limit) return 0;
    return Math.min(100, (this.limit.currentValue / this.limit.freeLimit) * 100);
  }

  aboutToDisappear(): void {
    // 清理弹窗
    if (this.upgradeDialog) {
      this.upgradeDialog.dismiss();
      this.upgradeDialog = null;
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      // 主要内容区域
      this.content()
      
      // 根据模式显示不同的锁定UI
      if (!this.isProMember) {
        this.buildLockOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }
  
  // 构建锁定覆盖层
  @Builder
  private buildLockOverlay() {
    if (this.lockMode === PremiumLockMode.FULL_LOCK) {
      this.buildFullLockOverlay()
    } else if (this.lockMode === PremiumLockMode.SOFT_LIMIT) {
      this.buildSoftLimitOverlay()
    } else if (this.lockMode === PremiumLockMode.COMPARISON) {
      this.buildComparisonOverlay()
    } else if (this.lockMode === PremiumLockMode.BADGE_ONLY) {
      this.buildBadgeOnlyOverlay()
    }
  }
  
  // ========== 完全锁定模式 ==========
  @Builder
  private buildFullLockOverlay() {
    Column() {
      // 置灰层
      Column() {
        this.content()
      }
      .width('100%')
      .height('100%')
      .opacity(DesignConstants.OPACITY_DISABLED)
      .enabled(false)
      .backgroundColor($r('sys.color.background_secondary'))
      
      // 点击区域
      Column() {
        // VIP角标
        Row({ space: DesignConstants.SPACING_XS }) {
          Image($r('app.media.ic_vip'))
            .width(DesignConstants.ICON_SIZE_SM)
            .height(DesignConstants.ICON_SIZE_SM)
            .fillColor($r('sys.color.icon_emphasize'))
          
          Text('PRO')
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.icon_emphasize'))
        }
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .backgroundColor('rgba(255, 255, 255, 0.9)')
        .borderRadius(DesignConstants.BORDER_RADIUS_SM)
        .margin({ top: DesignConstants.SPACING_SM, right: DesignConstants.SPACING_SM })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.End)
      .onClick(() => {
        Throttle.click(() => {
          this.showUpgradePrompt(UpgradePromptType.FEATURE_UNLOCK);
        });
      })
    }
    .width('100%')
    .height('100%')
  }
  
  // ========== 软限制模式 ==========
  @Builder
  private buildSoftLimitOverlay() {
    Column() {
      // 顶部限制提示条
      if (this.limit && this.limitProgress >= 70) {
        Row({ space: DesignConstants.SPACING_XS }) {
          Image($r('app.media.ic_info'))
            .width(14)
            .height(14)
            .fillColor(this.isLimitExceeded ? $r('sys.color.alert') : $r('sys.color.warning'))
          
          Text(this.getLimitTipText())
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor(this.isLimitExceeded ? $r('sys.color.alert') : $r('sys.color.warning'))
            .layoutWeight(1)
          
          if (this.isLimitExceeded) {
            Text('升级解锁 >')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.brand'))
              .fontWeight(FontWeight.Medium)
          }
        }
        .width('100%')
        .padding({ left: DesignConstants.SPACING_SM, right: DesignConstants.SPACING_SM, 
                  top: 6, bottom: 6 })
        .backgroundColor(this.isLimitExceeded ? 'rgba(255, 107, 107, 0.1)' : 'rgba(255, 193, 7, 0.1)')
        .onClick(() => {
          if (this.isLimitExceeded) {
            Throttle.click(() => {
              this.showUpgradePrompt(UpgradePromptType.LIMIT_REACHED);
            });
          }
        })
      }
      
      // 内容区域（可点击）
      Column() {
        this.content()
      }
      .width('100%')
      .layoutWeight(1)
      .enabled(!this.isLimitExceeded)
      .opacity(this.isLimitExceeded ? DesignConstants.OPACITY_DISABLED : 1)
      .onClick(() => {
        if (!this.isLimitExceeded) {
          // 正常点击，让内容自己处理
        }
      })
    }
    .width('100%')
    .height('100%')
  }
  
  // 获取限制提示文本
  private getLimitTipText(): string {
    if (!this.limit) return '';
    const unit = this.limit.unit || '';
    if (this.isLimitExceeded) {
      return `已达上限 ${this.limit.freeLimit}${unit}，升级解锁无限使用`;
    }
    if (this.limitProgress >= 90) {
      return `即将达到限制 (${this.limit.currentValue}/${this.limit.freeLimit}${unit})`;
    }
    return `免费额度：${this.limit.currentValue}/${this.limit.freeLimit}${unit}`;
  }
  
  // ========== 对比模式 ==========
  @Builder
  private buildComparisonOverlay() {
    Column() {
      // 对比标签
      Row({ space: DesignConstants.SPACING_XS }) {
        Image($r('app.media.ic_vip'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor($r('sys.color.icon_emphasize'))
        
        Text('查看对比')
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.icon_emphasize'))
      }
      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      .backgroundColor('rgba(255, 255, 255, 0.9)')
      .borderRadius(DesignConstants.BORDER_RADIUS_SM)
      .margin({ top: DesignConstants.SPACING_SM, right: DesignConstants.SPACING_SM })
      .onClick(() => {
        Throttle.click(() => {
          this.showUpgradePrompt(UpgradePromptType.COMPARISON);
        });
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.End)
  }
  
  // ========== 仅标签模式 ==========
  @Builder
  private buildBadgeOnlyOverlay() {
    Row({ space: DesignConstants.SPACING_XS }) {
      Image($r('app.media.ic_vip'))
        .width(DesignConstants.ICON_SIZE_SM)
        .height(DesignConstants.ICON_SIZE_SM)
        .fillColor($r('sys.color.icon_emphasize'))
      
      Text('PRO')
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.icon_emphasize'))
    }
    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
    .backgroundColor('rgba(255, 255, 255, 0.9)')
    .borderRadius(DesignConstants.BORDER_RADIUS_SM)
    .margin({ top: DesignConstants.SPACING_SM, right: DesignConstants.SPACING_SM })
  }

  // ========== 升级提示弹窗 ==========
  private showUpgradePrompt(type: UpgradePromptType): void {
    switch (type) {
      case UpgradePromptType.FEATURE_UNLOCK:
        this.showFeatureUnlockDialog();
        break;
      case UpgradePromptType.LIMIT_REACHED:
        this.showLimitReachedDialog();
        break;
      case UpgradePromptType.COMPARISON:
        this.showComparisonDialog();
        break;
      case UpgradePromptType.TRIAL_INVITE:
        this.showTrialInviteDialog();
        break;
    }
  }
  
  // 功能解锁弹窗
  private showFeatureUnlockDialog(): void {
    let params: FeatureUnlockParams = {
      featureName: this.featureName,
      featureDesc: this.featureDesc,
      icon: this.icon,
      showTrialTip: this.showTrialTip,
      trialDays: this.trialDays,
      onUpgrade: () => {
        this.dismissDialog();
        this.openMembershipCenter();
      },
      onLater: () => {
        this.dismissDialog();
      }
    };
    this.upgradeDialog = DialogHub.getSheet()
      .setStyle({
        title: { title: this.featureName },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(FeatureUnlockContentBuilder), params)
      .build();
    this.upgradeDialog.show();
  }
  
  // 限制达到弹窗
  private showLimitReachedDialog(): void {
    if (!this.limit) return;

    let params: LimitReachedParams = {
      featureName: this.featureName,
      limit: this.limit,
      onUpgrade: () => {
        this.dismissDialog();
        this.openMembershipCenter();
      },
      onLater: () => {
        this.dismissDialog();
      }
    };
    this.upgradeDialog = DialogHub.getSheet()
      .setStyle({
        title: { title: '使用额度已达上限' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(LimitReachedContentBuilder), params)
      .build();
    this.upgradeDialog.show();
  }
  
  // 功能对比弹窗
  private showComparisonDialog(): void {
    let params: ComparisonParams = {
      featureName: this.featureName,
      comparisonList: this.comparisonList,
      onUpgrade: () => {
        this.dismissDialog();
        this.openMembershipCenter();
      }
    };
    this.upgradeDialog = DialogHub.getSheet()
      .setStyle({
        title: { title: `${this.featureName} - 版本对比` },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(ComparisonContentBuilder), params)
      .build();
    this.upgradeDialog.show();
  }
  
  // 试用邀请弹窗
  private showTrialInviteDialog(): void {
    let params: TrialInviteParams = {
      trialDays: this.trialDays,
      onStartTrial: () => {
        this.dismissDialog();
        this.openMembershipCenter();
      },
      onLater: () => {
        this.dismissDialog();
      }
    };
    this.upgradeDialog = DialogHub.getSheet()
      .setStyle({
        title: { title: '🎁 免费试用专业版' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(TrialInviteContentBuilder), params)
      .build();
    this.upgradeDialog.show();
  }
  
  // 打开会员中心
  private openMembershipCenter(): void {
    let props: MembershipCenterDialogProps = {
      onClose: () => {
        this.onUpgradeClick();
        // 检查是否已升级
        if (this.pk.member_ship.can) {
          this.onUnlock();
        }
      }
    };

    this.upgradeDialog = DialogHub.getSheet()
      .setStyle({
        title: { title: '会员中心' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(MembershipCenterDialogBuilder), props)
      .build();
    this.upgradeDialog.show();
  }
  
  // 关闭弹窗
  private dismissDialog(): void {
    if (this.upgradeDialog) {
      this.upgradeDialog.dismiss();
      this.upgradeDialog = null;
    }
  }
}

// ========== 子组件：功能解锁内容 ==========
interface FeatureUnlockParams {
  featureName: string;
  featureDesc: string;
  icon: Resource;
  showTrialTip: boolean;
  trialDays: number;
  onUpgrade: () => void;
  onLater: () => void;
}

@Builder
function FeatureUnlockContentBuilder(params: FeatureUnlockParams) {
  Column({ space: DesignConstants.SPACING_LG }) {
    // 功能图标和名称
    Column({ space: DesignConstants.SPACING_MD }) {
      Image(params.icon)
        .width(64)
        .height(64)
        .fillColor($r('sys.color.brand'))
      
      Text(params.featureName)
        .fontSize(DesignConstants.FONT_SIZE_2XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
      
      Text(params.featureDesc)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    
    // 试用提示
    if (params.showTrialTip) {
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('🎁')
          .fontSize(24)
        
        Column({ space: DesignConstants.SPACING_XS }) {
          Text(`免费试用${params.trialDays}天`)
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.brand'))
          
          Text('体验期间解锁全部专业功能')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor('rgba(51, 154, 240, 0.1)')
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    }
    
    // 操作按钮
    Row({ space: DesignConstants.SPACING_MD }) {
      Button('稍后再说')
        .layoutWeight(1)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .fontColor($r('sys.color.font_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          Throttle.click(() => params.onLater());
        })
      
      Button(params.showTrialTip ? '免费体验' : '立即开通')
        .layoutWeight(1)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor('#FF6B6B')
        .fontColor(Color.White)
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          Throttle.click(() => params.onUpgrade());
        })
    }
    .width('100%')
  }
  .width('100%')
  .padding(DesignConstants.SPACING_LG)
}

// ========== 子组件：限制达到内容 ==========
interface LimitReachedParams {
  featureName: string;
  limit: FeatureLimit;
  onUpgrade: () => void;
  onLater: () => void;
}

@Builder
function LimitReachedContentBuilder(params: LimitReachedParams) {
  Column({ space: DesignConstants.SPACING_LG }) {
    // 提示图标
    Text('⚠️')
      .fontSize(48)
    
    Text('使用额度已达上限')
      .fontSize(DesignConstants.FONT_SIZE_XL)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('sys.color.alert'))
    
    Text(`您已达到${params.featureName}的免费使用上限`)
      .fontSize(DesignConstants.FONT_SIZE_MD)
      .fontColor($r('sys.color.font_secondary'))
      .textAlign(TextAlign.Center)
    
    // 进度展示
    Column({ space: DesignConstants.SPACING_SM }) {
      Row() {
        Text('当前使用')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
        
        Blank()
        
        Text(`${params.limit.currentValue}/${params.limit.freeLimit}${params.limit.unit || ''}`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.alert'))
      }
      .width('100%')
      
      // 进度条
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(8)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(4)
        
        Row()
          .width('100%')
          .height(8)
          .backgroundColor($r('sys.color.alert'))
          .borderRadius(4)
      }
      .width('100%')
      .height(8)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor('rgba(255, 107, 107, 0.1)')
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    
    // 升级权益
    Row({ space: DesignConstants.SPACING_SM }) {
      Image($r('app.media.ic_vip'))
        .width(24)
        .height(24)
        .fillColor($r('sys.color.brand'))
      
      Text('开通会员解锁无限使用')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
        .layoutWeight(1)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    
    // 操作按钮
    Row({ space: DesignConstants.SPACING_MD }) {
      Button('稍后再说')
        .layoutWeight(1)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .fontColor($r('sys.color.font_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          Throttle.click(() => params.onLater());
        })
      
      Button('立即开通')
        .layoutWeight(1)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor('#FF6B6B')
        .fontColor(Color.White)
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          Throttle.click(() => params.onUpgrade());
        })
    }
    .width('100%')
  }
  .width('100%')
  .padding(DesignConstants.SPACING_LG)
}

// ========== 子组件：功能对比内容 ==========
interface ComparisonParams {
  featureName: string;
  comparisonList: FeatureComparisonItem[];
  onUpgrade: () => void;
}

@Builder
function ComparisonContentBuilder(params: ComparisonParams) {
  Column({ space: DesignConstants.SPACING_LG }) {
    // 对比表格
    Column({ space: DesignConstants.SPACING_SM }) {
      // 表头
      Row() {
        Text('功能对比')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .width('30%')
        
        Text('基础版')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .width('35%')
        
        Text('专业版')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.brand'))
          .fontWeight(FontWeight.Medium)
          .width('35%')
      }
      .width('100%')
      .padding(DesignConstants.SPACING_SM)
      
      Divider()
        .color($r('sys.color.comp_divider'))
      
      // 对比项
      ForEach(params.comparisonList, (item: FeatureComparisonItem) => {
        Row() {
          Text(item.feature)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
            .width('30%')
          
          Text(item.freeDesc)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .width('35%')
          
          Text(item.proDesc)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor(item.isHighlight ? $r('sys.color.confirm') : $r('sys.color.font_primary'))
            .fontWeight(item.isHighlight ? FontWeight.Medium : FontWeight.Normal)
            .width('35%')
        }
        .width('100%')
        .padding(DesignConstants.SPACING_SM)
        .backgroundColor(item.isHighlight ? 'rgba(81, 207, 102, 0.1)' : Color.Transparent)
        .borderRadius(DesignConstants.BORDER_RADIUS_SM)
      })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    
    // 升级按钮
    Button('开通专业版解锁全部功能')
      .width('100%')
      .height(48)
      .fontSize(DesignConstants.FONT_SIZE_MD)
      .backgroundColor('#FF6B6B')
      .fontColor(Color.White)
      .borderRadius(24)
      .onClick(() => {
        Throttle.click(() => params.onUpgrade());
      })
  }
  .width('100%')
  .padding(DesignConstants.SPACING_LG)
}

// ========== 子组件：试用邀请内容 ==========
interface TrialInviteParams {
  trialDays: number;
  onStartTrial: () => void;
  onLater: () => void;
}

@Builder
function TrialInviteContentBuilder(params: TrialInviteParams) {
  Column({ space: DesignConstants.SPACING_LG }) {
    Text('🎁')
      .fontSize(64)
    
    Text('免费试用专业版')
      .fontSize(DesignConstants.FONT_SIZE_2XL)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('sys.color.font_primary'))
    
    Text(`${params.trialDays}天内解锁全部专业功能`)
      .fontSize(DesignConstants.FONT_SIZE_MD)
      .fontColor($r('sys.color.font_secondary'))
    
    // 权益列表
    Column({ space: DesignConstants.SPACING_SM }) {
      PremiumFeatureTrialItem('🎯', '多频率加权', 'A/C/Z计权模式');
      PremiumFeatureTrialItem('⏱️', '时间加权切换', '快速/慢速/脉冲');
      PremiumFeatureTrialItem('💾', '自动云端保存', '数据永不丢失');
      PremiumFeatureTrialItem('📊', '无限历史记录', '查看全部检测数据');
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    
    // 操作按钮
    Row({ space: DesignConstants.SPACING_MD }) {
      Button('稍后再说')
        .layoutWeight(1)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .fontColor($r('sys.color.font_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          Throttle.click(() => params.onLater());
        })
      
      Button('立即试用')
        .layoutWeight(1)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .backgroundColor('#FF6B6B')
        .fontColor(Color.White)
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          Throttle.click(() => params.onStartTrial());
        })
    }
    .width('100%')
    
    Text('试用结束后可随时取消，不会产生费用')
      .fontSize(DesignConstants.FONT_SIZE_SM)
      .fontColor($r('sys.color.font_tertiary'))
      .textAlign(TextAlign.Center)
  }
  .width('100%')
  .padding(DesignConstants.SPACING_LG)
}

@Builder
function PremiumFeatureTrialItem(emoji: string, title: string, desc: string) {
  Row({ space: DesignConstants.SPACING_SM }) {
    Text(emoji)
      .fontSize(20)
    
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
      
      Text(desc)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
    }
    .layoutWeight(1)
  }
  .width('100%')
  .padding({ top: 4, bottom: 4 })
}

// ========== 工具函数和导出 ==========

@Builder
function MembershipCenterDialogBuilder(props: MembershipCenterDialogProps) {
  MembershipCenterDialog({ onClose: props.onClose })
}

/**
 * 创建功能对比项的快捷方法
 */
export function createFeatureComparison(
  feature: string,
  freeDesc: string,
  proDesc: string,
  isHighlight: boolean = false
): FeatureComparisonItem {
  return { feature, freeDesc, proDesc, isHighlight };
}

/**
 * 创建功能限制的快捷方法
 */
export function createFeatureLimit(
  type: LimitType,
  freeLimit: number,
  proLimit: number,
  currentValue: number,
  unit?: string
): FeatureLimit {
  return { type, freeLimit, proLimit, currentValue, unit };
}

/**
 * 预定义的功能对比配置
 */
interface CommonFeatureComparisons {
  // 历史记录
  historyRecords: FeatureComparisonItem[];

  // 测量精度
  measurementPrecision: FeatureComparisonItem[];

  // 暴露统计
  exposureStats: FeatureComparisonItem[];

  // 数据管理
  dataManagement: FeatureComparisonItem[];
}

export const commonFeatureComparisons: CommonFeatureComparisons = {
  // 历史记录
  historyRecords: [
    createFeatureComparison('保存数量', '最近3条', '无限制', true),
    createFeatureComparison('数据筛选', '不支持', '支持多条件筛选', true),
    createFeatureComparison('批量操作', '不支持', '支持批量收藏/删除', true),
    createFeatureComparison('云端同步', '本机存储', '华为账号自动同步', true),
  ],
  
  // 测量精度
  measurementPrecision: [
    createFeatureComparison('频率加权', '仅A计权', 'A/C/Z计权模式', true),
    createFeatureComparison('时间加权', '仅快速模式', '快速/慢速/脉冲/自定义', true),
    createFeatureComparison('校准方式', '手动校准', '手动+自动校准', true),
    createFeatureComparison('FFT参数', '固定配置', '自定义窗函数/采样率', true),
  ],
  
  // 暴露统计
  exposureStats: [
    createFeatureComparison('当日统计', '✓ 可用', '✓ 可用', false),
    createFeatureComparison('历史趋势', '✗ 不可用', '✓ 完整趋势分析', true),
    createFeatureComparison('健康报告', '基础报告', '详细健康风险评估', true),
    createFeatureComparison('数据导出', '✗ 不支持', '支持导出分享', true),
  ],
  
  // 数据管理
  dataManagement: [
    createFeatureComparison('自动保存', '手动保存', '定时自动保存', true),
    createFeatureComparison('音频录制', '✗ 不支持', '✓ 支持录制回放', true),
    createFeatureComparison('位置标记', '✓ 基础定位', '✓ 详细地址信息', false),
    createFeatureComparison('云端备份', '✗ 不支持', '✓ 自动云端备份', true),
  ],
};
