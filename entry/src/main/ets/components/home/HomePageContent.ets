import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { navigationStack } from '../../constants/ProviderConstant';
import { Throttle } from '../../utils/Debounce';
import { common } from '@kit.AbilityKit';

// 功能卡片配置接口
interface FunctionCardConfig {
  title: string;
  icon: Resource;
  description: string;
  onTap: () => void;
}

// Tab切换事件接口
interface TabSwitchEvent {
  tabIndex: number;
}

@ComponentV2
export struct HomePageContent {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  @Local private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 顶部状态区
      this.buildStatusHeader()
      
      // 核心分贝显示区
      this.buildDecibelDisplay()
      
      // 功能入口卡片区
      this.buildFunctionCards()
    }
    .width('100%')
    .height('100%')
    .padding(DesignConstants.SPACING_MD)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  private buildStatusHeader() {
    Row() {
      // 当前时间
      Column({ space: DesignConstants.SPACING_XS }) {
        Text(this.currentTime)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        Text(this.currentDate)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      // 环境质量评级
      Column({ space: DesignConstants.SPACING_XS }) {
        Text(this.environmentQuality)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.environmentColor)
        Text('环境质量')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .alignItems(HorizontalAlign.Center)

      Blank()

      // 会员状态
      Column({ space: DesignConstants.SPACING_XS }) {
        Text(this.membershipStatus)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.membershipColor)
        Text('会员状态')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  @Builder
  private buildDecibelDisplay() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 大字体分贝值
      Text(`${this.ak.uiDisplayState.displayDb}dB`)
        .fontSize(64)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.decibelColor)
      
      // 分贝等级描述
      Text(this.decibelDescription)
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontColor($r('sys.color.font_secondary'))
    }
    .width('100%')
    .padding(DesignConstants.SPACING_XL)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_XL)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildFunctionCards() {
    GridRow({ columns: 2, gutter: DesignConstants.SPACING_MD }) {
      // 仪表盘入口
      GridCol({ span: 1 }) {
        this.buildFunctionCard({
          title: '仪表盘',
          icon: $r('app.media.ic_meter'),
          description: '完整噪音检测',
          onTap: () => { this.switchToTab(1) }
        })
      }
      
      // 警报入口
      GridCol({ span: 1 }) {
        this.buildFunctionCard({
          title: '警报',
          icon: $r('app.media.ic_alarm'),
          description: '噪音警报管理',
          onTap: () => { this.switchToTab(2) }
        })
      }
      
      // 影响入口
      GridCol({ span: 1 }) {
        this.buildFunctionCard({
          title: '影响',
          icon: $r('app.media.i_solar_radar_outline'),
          description: '暴露统计分析',
          onTap: () => { this.switchToTab(3) }
        })
      }
      
      // 历史记录入口
      GridCol({ span: 1 }) {
        this.buildFunctionCard({
          title: '历史',
          icon: $r('app.media.ic_history'),
          description: '检测记录查看',
          onTap: () => { 
            Throttle.click(() => {
              this.navStack.pushPathByName('DecibelHistory', null);
            })
          }
        })
      }
    }
    .width('100%')
  }

  @Builder
  private buildFunctionCard(config: FunctionCardConfig) {
    Column({ space: DesignConstants.SPACING_SM }) {
      Image(config.icon)
        .width(32)
        .height(32)
        .fillColor($r('sys.color.icon_primary'))
      
      Text(config.title)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
      
      Text(config.description)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(config.onTap)
  }

  // 切换到指定Tab
  private switchToTab(index: number) {
    this.ak.currentTabIndex = index;
    console.info(`切换到Tab: ${index}`);
  }

  @Computed
  get currentTime(): string {
    return new Date().toLocaleTimeString('zh-CN', { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  }

  @Computed
  get currentDate(): string {
    return new Date().toLocaleDateString('zh-CN', {
      month: 'long',
      day: 'numeric'
    });
  }

  @Computed
  get environmentQuality(): string {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) return '优秀';
    if (db < 60) return '良好';
    if (db < 80) return '一般';
    return '较差';
  }

  @Computed
  get environmentColor(): Resource {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) return $r('sys.color.confirm');
    if (db < 60) return $r('sys.color.font_primary');
    if (db < 80) return $r('sys.color.warning');
    return $r('sys.color.alert');
  }

  @Computed
  get membershipStatus(): string {
    return this.pk.member_ship.can ? '专业版' : '基础版';
  }

  @Computed
  get membershipColor(): Resource {
    return this.pk.member_ship.can ? $r('sys.color.confirm') : $r('sys.color.font_secondary');
  }

  @Computed
  get decibelColor(): Resource {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) return $r('sys.color.confirm');
    if (db < 60) return $r('sys.color.font_primary');
    if (db < 80) return $r('sys.color.warning');
    return $r('sys.color.alert');
  }

  @Computed
  get decibelDescription(): string {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) return '非常安静';
    if (db < 60) return '环境舒适';
    if (db < 80) return '有些嘈杂';
    return '噪音较大';
  }
}