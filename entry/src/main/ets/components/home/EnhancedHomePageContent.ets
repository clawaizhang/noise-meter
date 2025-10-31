
/**
 * 增强版主页内容组件
 * 集成健康影响摘要和音频控制功能
 */

import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { navigationStack } from '../../constants/ProviderConstant';
import { Throttle } from '../../utils/Debounce';
import { common } from '@kit.AbilityKit';
import { DecibelRecordService } from '../../services/DecibelRecordService';
import { AudioControllerService } from '../../services/AudioControllerService';
import { LocationInfo, LocationService } from '../../services/LocationService';
import { HealthImpactService } from '../../services/HealthImpactService';
import { HealthImpactData, DEFAULT_HEALTH_IMPACT_DATA } from '../../models/HealthImpactData';

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
export struct EnhancedHomePageContent {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  @Local private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @Local private currentLocation: LocationInfo | null = null;
  @Local private isLocationRefreshing: boolean = false;
  @Local private healthImpactData: HealthImpactData = DEFAULT_HEALTH_IMPACT_DATA;
  @Local private isAudioControlVisible: boolean = false;
  @Local private healthDataUpdateTimer: number | null = null;
  
  private decibelRecordService: DecibelRecordService = new DecibelRecordService(this.context);
  private locationService: LocationService = LocationService.getInstance();
  private healthImpactService: HealthImpactService = HealthImpactService.getInstance();

  build() {
    Column({ space: DesignConstants.SPACING_XL }) {
      // 核心分贝显示区
      this.buildDecibelDisplay()
      
      // 健康影响摘要区
      this.buildHealthImpactSummary()
      
      // 音频控制面板
      if (this.isAudioControlVisible) {
        this.buildAudioControlPanel()
      }
      
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
  private buildDecibelDisplay() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 分贝值 - 核心显示（大字体）
      Text(`${this.ak.uiDisplayState.displayDb}dB`)
        .fontSize(56)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.decibelColor)
      
      // 分贝描述
      Text(this.ak.uiDisplayState.displayDescription)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
      
      // 统计数据行
      this.buildStatisticsRow()
      
      // 系统状态概要
      this.buildSystemStatus()
    }
    .width('100%')
    .padding(DesignConstants.SPACING_XL)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_XL)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildHealthImpactSummary() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题行
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_atom'))
          .width(16)
          .height(16)
          .fillColor($r('sys.color.icon_primary'))
        Text('健康影响摘要')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
        
        // 详情按钮
        Button('详情', { type: ButtonType.Normal, stateEffect: true })
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_primary'))
          .backgroundColor($r('sys.color.background_secondary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_SM)
          .padding({ left: DesignConstants.SPACING_MD, right: DesignConstants.SPACING_MD })
          .onClick(() => this.navigateToHealthImpact())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 健康影响状态卡片
      Column({ space: DesignConstants.SPACING_SM }) {
        // 主要健康影响状态
        Row({ space: DesignConstants.SPACING_SM }) {
          Circle({ width: 8, height: 8 })
            .fill(this.healthImpactColor)
          Text(this.healthImpactSummary)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_primary'))
            .layoutWeight(1)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 分贝级别指示
        Row({ space: DesignConstants.SPACING_MD }) {
          Text('当前分贝:')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
          Text(`${this.ak.uiDisplayState.displayDb.toFixed(1)} dB`)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.decibelColor)
        }
        .width('100%')

        // 暴露风险评估
        Row({ space: DesignConstants.SPACING_MD }) {
          Text('暴露风险:')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
          Text(this.exposureIndex)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.exposureColor)
        }
        .width('100%')

        // 特殊噪声检测
        Row({ space: DesignConstants.SPACING_MD }) {
          Text('特殊噪声:')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
          Text(this.getSpecialNoiseDetection())
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getSpecialNoiseColor())
        }
        .width('100%')
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .border({ width: 1, color: $r('sys.color.border_secondary') })
    .margin({ bottom: DesignConstants.SPACING_MD })
  }

  @Builder
  private buildAudioControlPanel() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题行
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_mic'))
          .width(16)
          .height(16)
          .fillColor($r('sys.color.icon_primary'))
        Text('音频控制')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
        
        // 关闭按钮
        Button('收起', { type: ButtonType.Normal, stateEffect: true })
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_primary'))
          .backgroundColor($r('sys.color.background_secondary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_SM)
          .padding({ left: DesignConstants.SPACING_MD, right: DesignConstants.SPACING_MD })
          .onClick(() => this.toggleAudioControl())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 音频设备状态
      Column({ space: DesignConstants.SPACING_SM }) {
        // 设备状态行
        Row({ space: DesignConstants.SPACING_MD }) {
          Text('设备状态:')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
          Text(this.audioDeviceStatus)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.audioDeviceStatusColor)
        }
        .width('100%')

        // 采样率显示
        Row({ space: DesignConstants.SPACING_MD }) {
          Text('采样率:')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
          Text(this.getSampleRateDisplay())
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')

        // 音频控制按钮行
        Row({ space: DesignConstants.SPACING_MD }) {
          // 校准按钮
          Button('校准', { type: ButtonType.Normal, stateEffect: true })
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_primary'))
            .backgroundColor($r('sys.color.background_secondary'))
            .borderRadius(DesignConstants.BORDER_RADIUS_SM)
            .padding({ left: DesignConstants.SPACING_MD, right: DesignConstants.SPACING_MD })
            .layoutWeight(1)
            .onClick(() => this.navigateToAudioControl())

          // 测试按钮
          Button('测试', { type: ButtonType.Normal, stateEffect: true })
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_primary'))
            .backgroundColor($r('sys.color.background_secondary'))
            .borderRadius(DesignConstants.BORDER_RADIUS_SM)
            .padding({ left: DesignConstants.SPACING_MD, right: DesignConstants.SPACING_MD })
            .layoutWeight(1)
            .onClick(() => this.testAudioDevice())
        }
        .width('100%')
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .border({ width: 1, color: $r('sys.color.border_secondary') })
    .margin({ bottom: DesignConstants.SPACING_MD })
  }

  @Builder
  private buildFunctionCards() {
    GridRow({ columns: 3, gutter: { x: DesignConstants.SPACING_MD, y: DesignConstants.SPACING_MD } }) {
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
          onTap: () => { this.switchToTab(3) }
        })
      }
      
      // 工具入口 - 显示工具状态
      GridCol({ span: 1 }) {
        this.buildFunctionCard({
          title: '操作台',
          icon: $r('app.media.ic_atom'),
          description: '校准和设置',
          dataDisplay: this.toolsStatus,
          dataColor: this.toolsStatusColor,
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
          onTap: () => { this.switchToTab(4) }
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

      // 音频控制入口 - 新增音频控制卡片
      GridCol({ span: 1 }) {
        this.buildFunctionCard({
          title: '音频控制',
          icon: $r('app.media.ic_audio_analysis'),
          description: '音频设备管理',
          dataDisplay: this.audioControlStatus,
          dataColor: this.audioControlStatusColor,
          onTap: () => { this.toggleAudioControl() }
        })
      }

      // 参考入口 - 第7个功能卡片
      GridCol({ span: 1 }) {
        this.buildFunctionCard({
          title: '参考',
          icon: $r('app.media.ic_book2'),
          description: '标准和法规',
          dataDisplay: '标准库',
          dataColor: $r('sys.color.font_secondary'),
          onTap: () => { this.switchToTab(5) }
        })
      }
    }
    .width('100%')
    .margin({ top: DesignConstants.SPACING_MD })
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
    .height(72)
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


  @Builder
  private buildStatisticsRow() {
    Row({ space: DesignConstants.SPACING_LG }) {
      // 最小值
      Column({ space: DesignConstants.SPACING_XS }) {
        Text('最小值')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
        Text(`${this.ak.uiDisplayState.displayStatistics.minDb.toFixed(1)}dB`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.confirm'))
      }
      
      // 平均值
      Column({ space: DesignConstants.SPACING_XS }) {
        Text('平均值')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
        Text(`${this.ak.uiDisplayState.displayStatistics.avgDb.toFixed(1)}dB`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      
      // 最大值
      Column({ space: DesignConstants.SPACING_XS }) {
        Text('最大值')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
        Text(`${this.ak.uiDisplayState.displayStatistics.maxDb.toFixed(1)}dB`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.alert'))
      }
    }
    .margin({ top: DesignConstants.SPACING_MD })
  }

  @Builder
  private buildSystemStatus() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 第一行：系统状态信息
      Row({ space: DesignConstants.SPACING_LG }) {
        // 测量时长
        Column({ space: DesignConstants.SPACING_XS }) {
          Text('测量时长')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
          Text(this.measurementDuration)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
        }
        
        // 系统状态
        Column({ space: DesignConstants.SPACING_XS }) {
          Text('系统状态')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
          Text(this.systemStatus)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.systemStatusColor)
        }
        
        // 记录数量
        Column({ space: DesignConstants.SPACING_XS }) {
          Text('记录数量')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
          Text(this.ak.totalRecordsCount.toString())
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
        }
      }
      .width('100%')
      
      // 第二行：独立位置信息行
      this.buildLocationInfo()
    }
    .margin({ top: DesignConstants.SPACING_MD })
    .padding({ top: DesignConstants.SPACING_MD })
  }

  @Builder
  private buildLocationInfo() {
    Row({ space: DesignConstants.SPACING_SM }) {
      Image($r('app.media.ic_location'))
        .width(14)
        .height(14)
        .fillColor($r('sys.color.icon_secondary'))
      Text(this.locationStatus)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor(this.locationStatusColor)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
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
  get measurementDuration(): string {
    const duration = this.ak.uiDisplayState.displayStatistics.duration;
    if (duration < 60) {
      return `${Math.floor(duration)}秒`;
    } else if (duration < 3600) {
      return `${Math.floor(duration / 60)}分钟`;
    } else {
      return `${Math.floor(duration / 3600)}小时`;
    }
  }

  @Computed
  get systemStatus(): string {
    try {
      const audioControllerService = AudioControllerService.getInstance(this.ak, this.pk);
      if (audioControllerService && audioControllerService.isInBackground()) {
        return '后台运行';
      }
    } catch (error) {
      console.error('获取AudioControllerService实例失败:', error);
    }
    return '正常运行';
  }

  @Computed
  get systemStatusColor(): Resource {
    try {
      const audioControllerService = AudioControllerService.getInstance(this.ak, this.pk);
      if (audioControllerService && audioControllerService.isInBackground()) {
        return $r('sys.color.warning');
      }
    } catch (error) {
      console.error('获取AudioControllerService实例失败:', error);
    }
    return $r('sys.color.confirm');
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

  // 警报数据 - 
  // 警报数据 - 活跃警报数量
  @Computed
  get activeAlertsCount(): number {
    // 模拟数据 - 实际应该从AlertService获取
    const db = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.baseThreshold || 70;
    
    if (db > threshold) return 1;
    return 0;
  }

  // 工具数据 - 工具状态
  @Computed
  get toolsStatus(): string {
    return '已配置';
  }

  @Computed
  get toolsStatusColor(): Resource {
    const calibrationValue = this.pk.calibration_value || 0;
    if (calibrationValue === 0) return $r('sys.color.alert');
    return $r('sys.color.confirm');
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

  // 音频控制状态
  @Computed
  get audioControlStatus(): string {
    return this.isAudioControlVisible ? '已展开' : '点击展开';
  }

  @Computed
  get audioControlStatusColor(): Resource {
    return this.isAudioControlVisible ? $r('sys.color.confirm') : $r('sys.color.font_secondary');
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

  // 初始化健康影响服务
  private async initializeHealthImpactService(): Promise<void> {
    try {
      // 检查服务是否已初始化
      if (!this.healthImpactService.isServiceInitialized()) {
        console.info('[EnhancedHomePageContent] 健康影响服务未初始化，跳过数据获取');
        return;
      }
      
      // 获取健康影响数据
      const healthData = this.healthImpactService.getCurrentHealthData();
      this.healthImpactData = healthData;
      console.info('[EnhancedHomePageContent] 健康影响服务数据已加载');
      
      // 启动定时更新
      this.startHealthDataUpdates();
    } catch (error) {
      console.error('初始化健康影响服务失败:', error);
    }
  }

  // 启动健康数据定时更新
  private startHealthDataUpdates(): void {
    if (this.healthDataUpdateTimer) {
      clearInterval(this.healthDataUpdateTimer);
    }
    
    // 每5秒更新一次健康数据
    this.healthDataUpdateTimer = setInterval(() => {
      this.updateHealthImpactData();
    }, 5000);
  }

  // 更新健康影响数据
  private updateHealthImpactData(): void {
    try {
      const healthData = this.healthImpactService.getCurrentHealthData();
      this.healthImpactData = healthData;
    } catch (error) {
      console.error('更新健康影响数据失败:', error);
    }
  }

  // 停止健康数据更新
  private stopHealthDataUpdates(): void {
    if (this.healthDataUpdateTimer) {
      clearInterval(this.healthDataUpdateTimer);
      this.healthDataUpdateTimer = null;
    }
  }

  // 位置状态计算属性
  @Computed
  get locationStatus(): string {
    if (!this.pk.location_enabled) {
      return '位置服务已关闭';
    }
    
    const location = this.ak.currentLocation;
    if (!location || !location.address) {
      return '获取位置中...';
    }
    
    return location.address;
  }

  @Computed
  get locationStatusColor(): Resource {
    if (!this.pk.location_enabled) {
      return $r('sys.color.font_secondary');
    }
    
    const location = this.ak.currentLocation;
    if (!location || !location.address) {
      return $r('sys.color.warning');

  // 获取采样率显示
  private getSampleRateDisplay(): string {
    try {
      const audioControllerService = AudioControllerService.getInstance(this.ak, this.pk);
      if (audioControllerService) {
        const sampleRate = audioControllerService.getSampleRate();
        return `${sampleRate} Hz`;
      }
    } catch (error) {
      console.error('获取采样率失败:', error);
    }
    return '未知';
  }

  // 测试音频设备
  private testAudioDevice(): void {
    try {
      const audioControllerService = AudioControllerService.getInstance(this.ak, this.pk);
      if (audioControllerService) {
        audioControllerService.testAudioDevice();
        // 可以添加测试结果提示
        console.log('音频设备测试已启动');
      }
    } catch (error) {
      console.error('测试音频设备失败:', error);
    }
  }
    }
    
    return $r('sys.color.confirm');
  }

  // 健康影响摘要数据 - 使用健康影响服务
  @Computed
  get healthImpactSummary(): string {
    if (this.healthImpactData && this.healthImpactData.riskLevel) {
      switch (this.healthImpactData.riskLevel) {
        case 'LOW':
          return '环境安静，对健康无影响';
        case 'MODERATE':
          return '轻度影响，长期暴露需注意';
        case 'HIGH':
          return '中度影响，建议减少暴露时间';
        case 'SEVERE':
          return '严重影响，立即采取防护措施';
        default:
          return '评估中...';
      }
    }
    
    // 回退到基于分贝值的评估
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) return '环境安静，对健康无影响';
    if (db < 60) return '轻度影响，长期暴露需注意';
    if (db < 80) return '中度影响，建议减少暴露时间';
    return '严重影响，立即采取防护措施';
  }

  @Computed
  get healthImpactColor(): Resource {
    if (this.healthImpactData && this.healthImpactData.riskLevel) {
      switch (this.healthImpactData.riskLevel) {
        case 'LOW':
          return $r('sys.color.confirm');
        case 'MODERATE':
          return $r('sys.color.warning');
        case 'HIGH':
        case 'SEVERE':
          return $r('sys.color.alert');
        default:
          return $r('sys.color.font_secondary');
      }
    }
    
    // 回退到基于分贝值的评估
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) return $r('sys.color.confirm');
    if (db < 60) return $r('sys.color.warning');
    if (db < 80) return $r('sys.color.alert');
    return $r('sys.color.alert');
  }

  // 音频设备状态
  @Computed
  get audioDeviceStatus(): string {
    try {
      const audioControllerService = AudioControllerService.getInstance(this.ak, this.pk);
      if (audioControllerService) {
        // 基于当前分贝值判断设备状态
        const currentDb = this.ak.uiDisplayState.displayDb;
        if (currentDb > 0) {
          return '设备正常';
        } else {
          return '设备异常';
        }
      }
    } catch (error) {
      console.error('获取音频设备状态失败:', error);
    }
    return '未知状态';
  }

  @Computed
  get audioDeviceStatusColor(): Resource {
    try {
      const audioControllerService = AudioControllerService.getInstance(this.ak, this.pk);
      if (audioControllerService) {
        // 基于当前分贝值判断设备状态
        const currentDb = this.ak.uiDisplayState.displayDb;
        if (currentDb > 0) {
          return $r('sys.color.confirm');
        } else {
          return $r('sys.color.alert');
        }
      }
    } catch (error) {
      console.error('获取音频设备状态失败:', error);
    }
    return $r('sys.color.alert');
  }

  // 音频控制面板切换
  private toggleAudioControl(): void {
    this.isAudioControlVisible = !this.isAudioControlVisible;
  }

  // 导航到健康影响详情
  private navigateToHealthImpact(): void {
    this.router.pushUrl({
      url: 'pages/noisemeter/HealthImpactDialogNavigation'
    });
  }

  // 导航到音频控制详情
  private navigateToAudioControl(): void {
    this.router.pushUrl({
      url: 'pages/settings/AudioCalibrationNavigation'
    });
  }

  // 组件生命周期
  aboutToAppear(): void {
    this.initializeRecordInfo();
    this.initializeHealthImpactService();
  }

  // 特殊噪声检测方法 - 使用健康影响服务数据
  private getSpecialNoiseDetection(): string {
    if (this.healthImpactData && this.healthImpactData.specialNoiseDetection) {
      const detection = this.healthImpactData.specialNoiseDetection;
      
      if (detection.isValid()) {
        switch (detection.noiseType) {
          case SpecialNoiseType.IMPULSE:
            return '检测到脉冲噪声';
          case SpecialNoiseType.LOW_FREQUENCY:
            return '检测到低频噪声';
          case SpecialNoiseType.COMBINED:
            return '检测到复合噪声';
          default:
            return '检测到特殊噪声';
        }
      }
    }
    
    // 回退到基于统计数据的检测
    const db = this.ak.uiDisplayState.displayDb;
    const stats = this.ak.uiDisplayState.displayStatistics;
    
    // 检测脉冲噪声
    if (stats.maxDb - stats.avgDb > 20) {
      return '检测到脉冲噪声';
    }
    
    // 检测低频噪声
    if (db < 40 && stats.avgDb > 30) {
      return '检测到低频噪声';
    }
    
    return '无特殊噪声';
  }

  private getSpecialNoiseColor(): Resource {
    if (this.healthImpactData && this.healthImpactData.specialNoiseDetection) {
      const detection = this.healthImpactData.specialNoiseDetection;
      
      if (detection.isValid()) {
        switch (detection.noiseType) {
          case SpecialNoiseType.IMPULSE:
          case SpecialNoiseType.COMBINED:
            return $r('sys.color.alert');
          case SpecialNoiseType.LOW_FREQUENCY:
            return $r('sys.color.warning');
          default:
            return $r('sys.color.warning');
        }
      }
    }
    
    // 回退到基于统计数据的检测
    const db = this.ak.uiDisplayState.displayDb;
    const stats = this.ak.uiDisplayState.displayStatistics;
    
    if (stats.maxDb - stats.avgDb > 20) {
      return $r('sys.color.alert');
    }
    
    if (db < 40 && stats.avgDb > 30) {
      return $r('sys.color.warning');
    }
    
    return $r('sys.color.confirm');
  }


  aboutToDisappear(): void {
    // 清理资源
    this.stopHealthDataUpdates();
  }
}