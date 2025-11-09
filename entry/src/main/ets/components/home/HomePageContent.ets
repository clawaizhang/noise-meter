import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, curves, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { navigationStack } from '../../constants/ProviderConstant';
import { Throttle } from '../../utils/Debounce';
import { common } from '@kit.AbilityKit';
import { DecibelRecordService } from '../../services/DecibelRecordService';
import { AudioControllerService } from '../../services/AudioControllerService';
import { LocationInfo, LocationService } from '../../services/LocationService';
import { AudioControlPanel } from '../common/AudioControlPanel';
import { StatusAlertsComponent } from '../status-alerts/StatusAlertsComponent';
import { DecibelService } from '../../services/DecibelService';

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
  @Local private currentLocation: LocationInfo | null = null;
  @Local private isLocationRefreshing: boolean = false;
  private decibelRecordService: DecibelRecordService = new DecibelRecordService(this.context);
  private locationService: LocationService = LocationService.getInstance();

  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {
        StatusAlertsComponent()
        // 核心分贝显示区
        this.buildDecibelDisplay()

        AudioControlPanel()
        // 功能入口卡片区
        this.buildFunctionCards()
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  private buildDecibelDisplay() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 分贝值 - 核心显示（大字体）
      if (this.ak.uiDisplayState.displayDb > 0) {
        Text(`${this.ak.uiDisplayState.displayDb}dB`)
          .fontSize(56)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.alert'))
          .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }));
      } else {
        Text('--')
          .fontSize(56)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_secondary'))
          .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }));
      }

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
  private buildFunctionCards() {
    GridRow({
      columns: 12, // 总共12列，便于响应式布局
      gutter: { x: DesignConstants.SPACING_SM, y: DesignConstants.SPACING_SM }, // 行列间距
      breakpoints: {
        reference: BreakpointsReference.WindowSize
      }
    }) {
      // 仪表盘入口 - 显示趋势数据
      GridCol({
        span: {
          sm: 6, // 小屏幕：每行2个 (12/6=2)
          md: 4, // 中等屏幕：每行3个 (12/4=3)
          lg: 3  // 大屏幕：每行4个 (12/3=4)
        }
      }) {
        this.buildSimplifiedFunctionCard({
          title: '仪表盘',
          icon: $r('app.media.ic_meter'),
          description: '分析图表展示',
          dataDisplay: this.dashboardTrend,
          dataColor: this.dashboardTrendColor,
          onTap: () => {
            this.switchToTab(1)
          }
        })
      }

      // 工具入口 - 显示工具状态
      GridCol({
        span: {
          sm: 6, // 小屏幕：每行2个 (12/6=2)
          md: 4, // 中等屏幕：每行3个 (12/4=3)
          lg: 3  // 大屏幕：每行4个 (12/3=4)
        }
      }) {
        this.buildSimplifiedFunctionCard({
          title: '操作台',
          icon: $r('app.media.ic_atom'),
          description: '校准和设置',
          dataDisplay: this.toolsStatus,
          dataColor: this.toolsStatusColor,
          onTap: () => {
            this.switchToTab(2)
          }
        })
      }

      // 警报入口 - 显示活跃警报数量
      GridCol({
        span: {
          sm: 6, // 小屏幕：每行2个 (12/6=2)
          md: 4, // 中等屏幕：每行3个 (12/4=3)
          lg: 3  // 大屏幕：每行4个 (12/3=4)
        }
      }) {
        this.buildSimplifiedFunctionCard({
          title: '警报',
          icon: $r('app.media.ic_alarm'),
          description: '噪音警报管理',
          badgeCount: this.activeAlertsCount,
          dataDisplay: this.activeAlertsCount > 0 ? '警报中' : '正常',
          dataColor: this.activeAlertsCount > 0 ? $r('sys.color.alert') : $r('sys.color.confirm'),
          onTap: () => {
            this.switchToTab(3)
          }
        })
      }

      // 影响入口 - 显示暴露指数
      GridCol({
        span: {
          sm: 6, // 小屏幕：每行2个 (12/6=2)
          md: 4, // 中等屏幕：每行3个 (12/4=3)
          lg: 3  // 大屏幕：每行4个 (12/3=4)
        }
      }) {
        this.buildSimplifiedFunctionCard({
          title: '影响',
          icon: $r('app.media.i_solar_radar_outline'),
          description: '暴露统计分析',
          dataDisplay: this.exposureIndex,
          dataColor: this.exposureColor,
          onTap: () => {
            this.switchToTab(4)
          }
        })
      }

      // 参考入口 - 显示参考信息
      GridCol({
        span: {
          sm: 6, // 小屏幕：每行2个 (12/6=2)
          md: 4, // 中等屏幕：每行3个 (12/4=3)
          lg: 3  // 大屏幕：每行4个 (12/3=4)
        }
      }) {
        this.buildSimplifiedFunctionCard({
          title: '参考',
          icon: $r('app.media.ic_book2'),
          description: '参考资料',
          dataDisplay: this.reference,
          dataColor: this.exposureColor,
          onTap: () => {
            this.switchToTab(5)
          }
        })
      }

      // 历史记录入口 - 显示最近记录时间，记录总数显示在徽章中
      GridCol({
        span: {
          sm: 6, // 小屏幕：每行2个 (12/6=2)
          md: 4, // 中等屏幕：每行3个 (12/4=3)
          lg: 3  // 大屏幕：每行4个 (12/3=4)
        }
      }) {
        this.buildSimplifiedFunctionCard({
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
  private buildSimplifiedFunctionCard(config: FunctionCardConfig) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标区域 - 垂直居中对齐
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
            .padding({
              left: 6,
              right: 6,
              top: 2,
              bottom: 2
            })
            .margin({ top: -4, right: -4 })
        }
      }
      .width(32)
      .height(32)
      .alignSelf(ItemAlign.Center)

      // 右侧内容区域 - 垂直居中对齐
      Column({ space: DesignConstants.SPACING_XS }) {
        // 标题行
        Row() {
          Text(config.title)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .textAlign(TextAlign.Start)

          Blank()
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        // 描述行
        Row() {
          Text(config.description)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .textAlign(TextAlign.Start)

          Blank()
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        // 数据展示区域
        if (config.dataDisplay) {
          Row() {
            Text(config.dataDisplay)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontWeight(FontWeight.Medium)
              .fontColor(config.dataColor || $r('sys.color.font_primary'))
              .textAlign(TextAlign.Start)

            Blank()
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .margin({ top: DesignConstants.SPACING_XS })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(80)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .shadow(DesignConstants.SHADOW_SM)
    .onClick(() => {
      Throttle.click(() => {
        config.onTap();
      });
    })
    .gesture(
      TapGesture()
        .onAction(() => {
          // 简单的按压效果
        })
    )
  }

  // 切换到指定Tab
  private switchToTab(index: number) {
    this.ak.currentTabIndex = index;
    console.info(`切换到Tab: ${index}`);
  }

  @Builder
  private buildSystemStatus() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 第二行：独立位置信息行
      this.buildLocationInfo()
    }
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

    // 移除点击事件，改为只读显示
  }

  @Computed
  get decibelColor(): Resource {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) {
      return $r('sys.color.confirm');
    }
    if (db < 60) {
      return $r('sys.color.font_primary');
    }
    if (db < 80) {
      return $r('sys.color.warning');
    }
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

    if (diff > 5) {
      return `↗ +${diff.toFixed(1)}dB`;
    }
    if (diff < -5) {
      return `↘ ${diff.toFixed(1)}dB`;
    }
    return '→ 稳定';
  }

  @Computed
  get dashboardTrendColor(): Resource {
    const currentDb = this.ak.uiDisplayState.displayDb;
    const previousDb = this.ak.uiDisplayState.previousDb || currentDb;
    const diff = currentDb - previousDb;

    if (diff > 1) {
      return $r('sys.color.alert');
    }
    if (diff < -1) {
      return $r('sys.color.confirm');
    }
    return $r('sys.color.font_secondary');
  }

  // 警报数据 - 活跃警报数量
  @Computed
  get activeAlertsCount(): number {
    // 模拟数据 - 实际应该从AlertService获取
    const db = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.baseThreshold || 70;

    if (db > threshold) {
      return 1;
    }
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
    if (calibrationValue === 0) {
      return $r('sys.color.alert');
    }
    return $r('sys.color.confirm');
  }

  // 影响数据 - 暴露指数
  @Computed
  get exposureIndex(): string {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) {
      return '低风险';
    }
    if (db < 60) {
      return '中风险';
    }
    if (db < 80) {
      return '高风险';
    }
    return '极高风险';
  }

  @Computed
  get reference(): string {
    const db = this.ak.uiDisplayState.displayDb;
    return DecibelService.getDecibelDescription(db);
  }

  @Computed
  get exposureColor(): Resource {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) {
      return $r('sys.color.confirm');
    }
    if (db < 60) {
      return $r('sys.color.warning');
    }
    if (db < 80) {
      return $r('sys.color.alert');
    }
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

    if (diffMins < 1) {
      return '刚刚';
    }
    if (diffMins < 60) {
      return `${diffMins}分钟前`;
    }

    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) {
      return `${diffHours}小时前`;
    }

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

  // 位置状态计算属性
  @Computed
  get locationStatus(): string {
    if (!this.pk.location_enabled) {
      return '位置服务已关闭';
    }

    if (this.isLocationRefreshing) {
      return '正在获取位置信息...';
    }

    if (this.currentLocation) {
      // 简化地址显示，避免过长
      const address = this.currentLocation.address || '';
      if (address.length > 30) {
        return address.substring(0, 27) + '...';
      }
      return address;
    }

    return '位置服务已开启';
  }

  @Computed
  get locationStatusColor(): Resource {
    if (!this.pk.location_enabled) {
      return $r('sys.color.font_secondary');
    }

    if (this.isLocationRefreshing) {
      return $r('sys.color.warning');
    }

    if (this.currentLocation) {
      return $r('sys.color.confirm');
    }

    return $r('sys.color.font_primary');
  }

  // 位置服务开关方法 - 已移除，现在只在操作台控制

  // 刷新位置信息方法
  private async refreshLocation(): Promise<void> {
    if (!this.pk.location_enabled || this.isLocationRefreshing) {
      return;
    }

    try {
      this.isLocationRefreshing = true;

      // 检查定位服务是否开启
      const isServiceEnabled = this.locationService.checkLocationEnabled();
      if (!isServiceEnabled) {
        this.currentLocation = null;
        return;
      }

      // 检查定位权限
      const hasPermission = await this.locationService.requestLocationPermission();
      if (!hasPermission) {
        this.currentLocation = null;
        this.pk.location_enabled = false;
        return;
      }

      // 获取位置信息
      const locationInfo: LocationInfo = await this.locationService.requestSingleLocation();
      this.currentLocation = locationInfo;
    } catch (error) {
      console.error('获取位置信息失败:', error);
      this.currentLocation = null;
    } finally {
      this.isLocationRefreshing = false;
    }
  }

  // 监听位置服务开关变化
  @Monitor('pk.location_enabled')
  onLocationEnabledChange(monitor: IMonitor) {
    const beforeEnabled = monitor.value<boolean>()?.before;
    const newEnabled = monitor.value<boolean>()?.now;
    if (newEnabled !== beforeEnabled) {
      if (newEnabled) {
        // 开启时自动刷新位置
        this.refreshLocation();
      } else {
        // 关闭时清空位置信息
        this.currentLocation = null;
      }
    }
  }

  aboutToAppear(): void {
    this.initializeRecordInfo();
    // 如果位置服务已开启，自动获取位置
    if (this.pk.location_enabled) {
      this.refreshLocation();
    }
  }
}