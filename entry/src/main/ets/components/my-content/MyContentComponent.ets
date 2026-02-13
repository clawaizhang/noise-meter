import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2, AppStorageV2 } from '@kit.ArkUI';
import { ListItemBuilder } from '../common/ListItemBuilder';
import { AboutSettingsBuilder } from '../../pages/settings/AboutSettingsNavigation';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { common } from '@kit.AbilityKit';
import { DisplayModeCardBuilder } from '../display/DisplayModeComponent';
import { MembershipStatusCard } from '../membership/MembershipStatusCard';
import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';
import { CommentService } from '../../services/CommentService';
import { AppKeys } from '../../models/AppKeys';
import { DecibelRecordService } from '../../services/DecibelRecordService';
import { AlertService } from '../../services/AlertService';
import { ExposureStatisticsService } from '../../services/ExposureStatisticsService';
import { ToolsContent } from '../tools/ToolsContent';
import { AlertsContent } from '../alerts/AlertsContent';
import { EnhancedExposureContent } from '../exposure/EnhancedExposureContent';
import { ReferenceContent } from '../reference/ReferenceContent';

// 今日统计数据
interface TodayStats {
  detectionCount: number;
  totalDuration: string;
  alertCount: number;
}

// 功能入口配置
interface FeatureEntry {
  id: string;
  title: string;
  icon: Resource;
  subtitle: string;
  statusColor: Resource;
  onTap: () => void;
}

/**
 * 我的内容页面组件
 * 整合设置、警报、影响、参考入口，以及原有功能
 */
@ComponentV2
export struct MyContentComponent {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private todayStats: TodayStats = {
    detectionCount: 0,
    totalDuration: '0分钟',
    alertCount: 0
  };
  @Local private isLoadingStats: boolean = false;
  
  private context: Context = getContext(this);
  private recordService: DecibelRecordService = new DecibelRecordService(this.context);
  private alertService: AlertService = AlertService.getInstance(getContext() as common.UIAbilityContext, this.pk);
  private exposureService: ExposureStatisticsService = ExposureStatisticsService.getInstance();

  aboutToAppear() {
    this.loadTodayStats();
  }

  // 加载今日统计数据
  private async loadTodayStats(): Promise<void> {
    this.isLoadingStats = true;
    try {
      // 获取今日检测次数
      const todayCount = await this.recordService.getTodayRecordCount();
      
      // 获取今日总检测时长（分钟）
      const todayDuration = await this.recordService.getTodayTotalDuration();
      const formattedDuration = todayDuration < 60 
        ? `${todayDuration}分钟` 
        : `${(todayDuration / 60).toFixed(1)}小时`;
      
      // 获取今日警报次数
      const todayAlerts = await this.recordService.getTodayAlertCount(this.pk.alarm_threshold.baseThreshold);

      this.todayStats = {
        detectionCount: todayCount,
        totalDuration: formattedDuration,
        alertCount: todayAlerts
      };
    } catch (error) {
      console.error('加载今日统计失败:', error);
    } finally {
      this.isLoadingStats = false;
    }
  }

  // 显示评论对话框
  private showCommentDialog = () => {
    Throttle.click(async () => {
      try {
        const context = getContext(this) as common.UIAbilityContext;
        const commentService = CommentService.getInstance();
        await commentService.showCommentDialog(context);
        console.info('评论对话框显示成功');
      } catch (error) {
        console.error(`显示评论对话框失败: ${error instanceof Error ? error.message : String(error)}`);
      }
    });
  }

  build() {
    // 可滚动内容区域
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {
        // 会员状态卡片
        MembershipStatusCard()
          .margin({ left: 16, right: 16 })

        // 今日统计卡片（紧凑型）
        this.buildTodayStatsCard()

        // 设置入口（单独列出）
        this.buildSettingsEntry()

        // 功能入口区域（警报/影响/参考）
        this.buildFeatureEntrySection()

        // 其他设置列表
        this.buildOtherSettingsList()

      }
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ bottom: DesignConstants.SPACING_LG })
    }
    .align(Alignment.Top)
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
  }

  // 今日统计卡片（紧凑型，修复宽度问题）
  @Builder
  private buildTodayStatsCard() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题行
      Row() {
        Text('今日统计')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        
        Blank()
        
        // 刷新按钮
        Button() {
          Image($r('app.media.ic_refresh'))
            .width(16)
            .height(16)
            .fillColor($r('sys.color.font_secondary'))
            .rotate({ angle: this.isLoadingStats ? 360 : 0 })
            .animation({
              duration: 1000,
              iterations: this.isLoadingStats ? -1 : 0,
              curve: Curve.Linear
            })
        }
        .width(28)
        .height(28)
        .backgroundColor(Color.Transparent)
        .enabled(!this.isLoadingStats)
        .onClick(() => {
          Throttle.click(() => this.loadTodayStats());
        })
      }
      .width('100%')

      // 统计数据横向排列（更紧凑）
      Row({ space: DesignConstants.SPACING_SM }) {
        // 检测次数
        Column({ space: 2 }) {
          Text(`${this.todayStats.detectionCount}`)
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
          Text('检测次数')
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .padding(DesignConstants.SPACING_SM)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)

        // 检测时长
        Column({ space: 2 }) {
          Text(this.todayStats.totalDuration)
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
          Text('累计时长')
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .padding(DesignConstants.SPACING_SM)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)

        // 警报次数
        Column({ space: 2 }) {
          Text(`${this.todayStats.alertCount}`)
            .fontSize(DesignConstants.FONT_SIZE_XL)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.todayStats.alertCount > 0 ? $r('sys.color.alert') : $r('sys.color.font_primary'))
          Text('警报次数')
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_secondary'))
        }
        .layoutWeight(1)
        .padding(DesignConstants.SPACING_SM)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .margin({ left: 16, right: 16 })
  }

  // 设置入口（单独列出）
  @Builder
  private buildSettingsEntry() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题
      Text('设置')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)
        .margin({ left: 16 })

      // 设置入口卡片
      Row({ space: DesignConstants.SPACING_MD }) {
        // 左侧图标
        Image($r('app.media.ic_atom'))
          .width(32)
          .height(32)
          .fillColor($r('sys.color.icon_primary'))

        // 中间内容
        Column({ space: DesignConstants.SPACING_XS }) {
          Text('测量设置')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .textAlign(TextAlign.Start)

          Text(this.getSettingsStatus())
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor(this.getSettingsStatusColor())
            .textAlign(TextAlign.Start)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)

        // 箭头
        Image($r('app.media.ic_arrow_right'))
          .width(16)
          .height(16)
          .fillColor($r('sys.color.font_tertiary'))
      }
      .width('100%')
      .height(72)
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .margin({ left: 16, right: 16 })
      .onClick(() => {
        Throttle.click(() => this.openSettingsPage());
      })
    }
    .width('100%')
  }

  // 功能入口区域（警报/影响/参考）
  @Builder
  private buildFeatureEntrySection() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题
      Text('功能')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)
        .margin({ left: 16 })

      // 3个功能入口（警报/影响/参考）
      Column({ space: DesignConstants.SPACING_MD }) {
        // 警报入口
        this.buildFeatureEntryCard({
          id: 'alerts',
          title: '警报中心',
          icon: $r('app.media.ic_alarm'),
          subtitle: this.getAlertsStatus(),
          statusColor: this.getAlertsStatusColor(),
          onTap: () => this.openAlertsPage()
        })

        // 影响入口
        this.buildFeatureEntryCard({
          id: 'exposure',
          title: '影响分析',
          icon: $r('app.media.i_solar_radar_outline'),
          subtitle: this.getExposureStatus(),
          statusColor: this.getExposureStatusColor(),
          onTap: () => this.openExposurePage()
        })

        // 参考入口
        this.buildFeatureEntryCard({
          id: 'reference',
          title: '参考标准',
          icon: $r('app.media.ic_book2'),
          subtitle: this.getReferenceStatus(),
          statusColor: this.getReferenceStatusColor(),
          onTap: () => this.openReferencePage()
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .margin({ top: DesignConstants.SPACING_SM })
  }

  // 功能入口卡片
  @Builder
  private buildFeatureEntryCard(entry: FeatureEntry) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标
      Image(entry.icon)
        .width(32)
        .height(32)
        .fillColor($r('sys.color.icon_primary'))

      // 中间内容
      Column({ space: DesignConstants.SPACING_XS }) {
        Text(entry.title)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .textAlign(TextAlign.Start)

        Text(entry.subtitle)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(entry.statusColor)
          .textAlign(TextAlign.Start)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)

      // 箭头
      Image($r('app.media.ic_arrow_right'))
        .width(16)
        .height(16)
        .fillColor($r('sys.color.font_tertiary'))
    }
    .width('100%')
    .height(72)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .onClick(() => {
      Throttle.click(() => entry.onTap());
    })
  }

  // 其他设置列表
  @Builder
  private buildOtherSettingsList() {
    List() {
      // 色彩模式列表项
      ListItem() {
        Row({ space: 8 }) {
          Row() {
            Image($r('app.media.ic_display'))
              .width(24)
              .height(24)
              .fillColor($r('sys.color.brand'))
              .margin({ right: 12 })

            Text('色彩模式')
              .fontSize(16)
              .fontColor($r('sys.color.font_primary'))
              .layoutWeight(1)
          }.layoutWeight(1)

          // 当前模式显示
          Text(this.pk.display_mode === 'default' ? '跟随系统' :
               this.pk.display_mode === 'light' ? '浅色主题' : '深色主题')
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
      }
      .borderRadius(16)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .margin({ top: DesignConstants.SPACING_LG, left: 16, right: 16 })
      .onClick(() => {
        Throttle.click(() => {
          DialogHub.getSheet()
            .setStyle({
              title: { title: '色彩模式' },
              backgroundColor: $r('sys.color.background_secondary')
            })
            .setConfig({ scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT })
            .setComponentTargetId('mainId')
            .setContent(wrapBuilder(DisplayModeCardBuilder))
            .build()
            .show();
        });
      })

      // 给作者五星好评设置
      ListItemBuilder(
        $r('app.media.ic_smile'),
        '五星好评',
        () => {
          this.showCommentDialog();
        },
        DesignConstants.SPACING_LG
      )

      // 关于列表项
      ListItemBuilder(
        $r('app.media.ic_info'),
        '关于',
        () => {
          DialogHub.getSheet()
            .setStyle({ title: { title: '关于' }, backgroundColor: $r('sys.color.background_secondary') })
            .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
            .setComponentTargetId('mainId')
            .setContent(wrapBuilder(AboutSettingsBuilder))
            .build()
            .show();
        },
        DesignConstants.SPACING_LG
      )
    }
    .width('100%')
    .alignListItem(ListItemAlign.Start)
  }

  // ==================== 状态获取方法 ====================

  // 设置状态
  private getSettingsStatus(): string {
    const calibrationValue = this.pk.calibration_value || 0;
    if (calibrationValue === 0) {
      return '未校准';
    }
    return `已校准 ${calibrationValue > 0 ? '+' : ''}${calibrationValue}dB`;
  }

  private getSettingsStatusColor(): Resource {
    const calibrationValue = this.pk.calibration_value || 0;
    if (calibrationValue === 0) {
      return $r('sys.color.alert');
    }
    return $r('sys.color.confirm');
  }

  // 警报状态
  private getAlertsStatus(): string {
    const threshold = this.pk.alarm_threshold.baseThreshold || 70;
    const db = this.ak.uiDisplayState.displayDb;
    if (db > threshold) {
      return `警报中: ${db}dB > ${threshold}dB`;
    }
    return `阈值: ${threshold}dB`;
  }

  private getAlertsStatusColor(): Resource {
    const db = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.baseThreshold || 70;
    if (db > threshold) {
      return $r('sys.color.alert');
    }
    return $r('sys.color.confirm');
  }

  // 影响状态
  private getExposureStatus(): string {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) {
      return '当前环境: 低风险';
    }
    if (db < 60) {
      return '当前环境: 中风险';
    }
    if (db < 80) {
      return '当前环境: 高风险';
    }
    return '当前环境: 极高风险';
  }

  private getExposureStatusColor(): Resource {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) {
      return $r('sys.color.confirm');
    }
    if (db < 60) {
      return $r('sys.color.warning');
    }
    return $r('sys.color.alert');
  }

  // 参考状态
  private getReferenceStatus(): string {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 30) {
      return '当前场景: 极安静';
    }
    if (db < 50) {
      return '当前场景: 安静';
    }
    if (db < 70) {
      return '当前场景: 正常';
    }
    if (db < 90) {
      return '当前场景: 嘈杂';
    }
    return '当前场景: 极嘈杂';
  }

  private getReferenceStatusColor(): Resource {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 50) {
      return $r('sys.color.confirm');
    }
    if (db < 70) {
      return $r('sys.color.warning');
    }
    return $r('sys.color.alert');
  }

  // ==================== 页面打开方法 ====================

  // 打开设置页面
  private openSettingsPage(): void {
    let settingsDialog: InfSheet;
    settingsDialog = DialogHub.getSheet()
      .setStyle({ 
        title: { title: '设置' },
        backgroundColor: $r('sys.color.background_secondary') 
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(SettingsContentBuilder))
      .build();
    settingsDialog.show();
  }

  // 打开警报页面
  private openAlertsPage(): void {
    let alertsDialog: InfSheet;
    alertsDialog = DialogHub.getSheet()
      .setStyle({ 
        title: { title: '警报中心' },
        backgroundColor: $r('sys.color.background_secondary') 
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(AlertsContentBuilder))
      .build();
    alertsDialog.show();
  }

  // 打开影响页面
  private openExposurePage(): void {
    let exposureDialog: InfSheet;
    exposureDialog = DialogHub.getSheet()
      .setStyle({ 
        title: { title: '影响分析' },
        backgroundColor: $r('sys.color.background_secondary') 
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(ExposureContentBuilder))
      .build();
    exposureDialog.show();
  }

  // 打开参考页面
  private openReferencePage(): void {
    let referenceDialog: InfSheet;
    referenceDialog = DialogHub.getSheet()
      .setStyle({ 
        title: { title: '参考标准' },
        backgroundColor: $r('sys.color.background_secondary') 
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(ReferenceContentBuilder))
      .build();
    referenceDialog.show();
  }
}

// 设置内容Builder
@Builder
function SettingsContentBuilder() {
  ToolsContent()
}

// 警报内容Builder
@Builder
function AlertsContentBuilder() {
  AlertsContent()
}

// 影响内容Builder
@Builder
function ExposureContentBuilder() {
  EnhancedExposureContent()
}

// 参考内容Builder
@Builder
function ReferenceContentBuilder() {
  ReferenceContent()
}
