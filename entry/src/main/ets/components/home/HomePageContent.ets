import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { navigationStack } from '../../constants/ProviderConstant';
import { Throttle } from '../../utils/Debounce';
import { common } from '@kit.AbilityKit';
import { DecibelRecordService } from '../../services/DecibelRecordService';

// 功能卡片配置接口
interface FunctionCardConfig {
  title: string;
  icon: Resource;
  description: string;
  dataDisplay?: string;
  dataColor?: Resource;
  badgeCount?: number;
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
  private decibelRecordService: DecibelRecordService = new DecibelRecordService(this.context);

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
      // 仪表盘入口 - 显示趋势数据
      GridCol({ span: 1 }) {
        this.buildFunctionCard({
          title: '仪表盘',
          icon: $r('app.media.ic_meter'),
          description: '完整噪音检测',
          dataDisplay: this.dashboardTrend,
          dataColor: this.dashboardTrendColor,
          onTap: () => { this.switchToTab(1) }
        })
      }
      
      // 警报入口 - 显示活跃警报数量
      GridCol({ span: 1 }) {
        this.buildFunctionCard({
          title: '警报',
          icon: $r('app.media.ic_alarm'),
          description: '噪音警报管理',
          badgeCount: this.activeAlertsCount,
          dataDisplay: this.activeAlertsCount > 0 ? '警报中' : '正常',
          dataColor: this.activeAlertsCount > 0 ? $r('sys.color.alert') : $r('sys.color.confirm'),
          onTap: () => { this.switchToTab(2) }
        })
      }
      
      // 影响入口 - 显示暴露指数
      GridCol({ span: 1 }) {
        this.buildFunctionCard({
          title: '影响',
          icon: $r('app.media.i_solar_radar_outline'),
          description: '暴露统计分析',
          dataDisplay: this.exposureIndex,
          dataColor: this.exposureColor,
          onTap: () => { this.switchToTab(3) }
        })
      }
      
      // 历史记录入口 - 显示最近记录时间，记录总数显示在徽章中
      GridCol({ span: 1 }) {
        this.buildFunctionCard({
          title: '历史',
          icon: $r('app.media.ic_history'),
          description: '检测记录查看',
          dataDisplay: this.lastRecordTime,
          dataColor: $r('sys.color.font_secondary'),
          badgeCount: this.ak.totalRecordsCount,
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
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标区域
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(config.icon)
          .width(32)
          .height(32)
          .fillColor($r('sys.color.icon_primary'))
        
        // 徽章计数 - 放在图标右上角
        if (config.badgeCount && config.badgeCount > 0) {
          Text(config.badgeCount.toString())
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor(Color.White)
            .backgroundColor($r('sys.color.alert'))
            .borderRadius(DesignConstants.BORDER_RADIUS_FULL)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ top: -4, right: -4 })
        }
      }
      .width(32)
      .height(32)

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

        // 数据展示区域
        if (config.dataDisplay) {
          Row() {
            Text(config.dataDisplay)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontWeight(FontWeight.Medium)
              .fontColor(config.dataColor || $r('sys.color.font_primary'))
            
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

  // 仪表盘数据 - 趋势指示器
  @Computed
  get dashboardTrend(): string {
    const currentDb = this.ak.uiDisplayState.displayDb;
    const previousDb = this.ak.uiDisplayState.previousDb || currentDb;
    const diff = currentDb - previousDb;
    
    if (diff > 5) return `↗ +${diff.toFixed(1)}dB`;
    if (diff < -5) return `↘ ${diff.toFixed(1)}dB`;
    return '→ 稳定';
  }

  @Computed
  get dashboardTrendColor(): Resource {
    const currentDb = this.ak.uiDisplayState.displayDb;
    const previousDb = this.ak.uiDisplayState.previousDb || currentDb;
    const diff = currentDb - previousDb;
    
    if (diff > 1) return $r('sys.color.alert');
    if (diff < -1) return $r('sys.color.confirm');
    return $r('sys.color.font_secondary');
  }

  // 警报数据 - 活跃警报数量
  @Computed
  get activeAlertsCount(): number {
    // 模拟数据 - 实际应该从AlertService获取
    const db = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.baseThreshold || 70;
    
    if (db > threshold) return 1;
    return 0;
  }

  // 影响数据 - 暴露指数
  @Computed
  get exposureIndex(): string {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) return '低风险';
    if (db < 60) return '中风险';
    if (db < 80) return '高风险';
    return '极高风险';
  }

  @Computed
  get exposureColor(): Resource {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) return $r('sys.color.confirm');
    if (db < 60) return $r('sys.color.warning');
    if (db < 80) return $r('sys.color.alert');
    return $r('sys.color.alert');
  }

  // 历史数据 - 最近记录时间
  @Computed
  get lastRecordTime(): string {
    const lastTimestamp = this.ak.lastRecordTimestamp;
    if (lastTimestamp) {
      return this.formatTimeAgo(lastTimestamp);
    }
    return '暂无记录';
  }


  // 格式化时间差
  private formatTimeAgo(timestamp: number): string {
    const now = Date.now();
    const diffMs = now - timestamp;
    const diffMins = Math.floor(diffMs / 60000);
    
    if (diffMins < 1) return '刚刚';
    if (diffMins < 60) return `${diffMins}分钟前`;
    
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours}小时前`;
    
    const diffDays = Math.floor(diffHours / 24);
    return `${diffDays}天前`;
  }

  // 初始化记录信息
  private async initializeRecordInfo(): Promise<void> {
    try {
      // 初始化最后记录时间
      const records = await this.decibelRecordService.getRecordsPaged(1, 0);
      if (records.length > 0) {
        this.ak.lastRecordTimestamp = records[0].timestamp;
      }
      
      // 初始化记录总数
      const totalCount = await this.decibelRecordService.getTotalCount();
      this.ak.totalRecordsCount = totalCount;
    } catch (error) {
      console.error('初始化记录信息失败:', error);
    }
  }

  aboutToAppear(): void {
    this.initializeRecordInfo();
  }
}