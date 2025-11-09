import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';
import { LocationInfo, LocationService } from '../../services/LocationService';
import { ToolConfigFactory } from './ToolConfigs';
import {
  createLearnMoreButton,
  createToolIcon,
  createToolStatus,
  createUsageHint,
  LearnMoreButton,
  ToolIcon,
  ToolStatus,
  UsageHint
} from './ToolComponents';
import { ToolNavigationService } from './ToolNavigationService';
import { ToolStatusService } from './ToolStatusService';

// 功能分类枚举
export enum ToolCategory {
  BASIC_MEASUREMENT = 'BASIC_MEASUREMENT', // 基础测量
  DATA_MANAGEMENT = 'DATA_MANAGEMENT', // 数据管理
  DISPLAY_SETTINGS = 'DISPLAY_SETTINGS', // 显示设置
  ALERT_SYSTEM = 'ALERT_SYSTEM', // 警报系统
  ADVANCED_SETTINGS = 'ADVANCED_SETTINGS' // 高级设置
}

// 功能优先级枚举
export enum ToolPriority {
  ESSENTIAL = 'ESSENTIAL', // 核心功能，所有用户都需要
  RECOMMENDED = 'RECOMMENDED', // 推荐功能，大多数用户会用
  ADVANCED = 'ADVANCED' // 高级功能，专业用户需要
}

// 用户技能水平枚举
enum UserSkillLevel {
  BEGINNER = 'beginner',
  INTERMEDIATE = 'intermediate',
  EXPERT = 'expert'
}

// 测量场景枚举
enum MeasurementScene {
  INDOOR = 'INDOOR',
  OUTDOOR = 'OUTDOOR',
  INDUSTRIAL = 'INDUSTRIAL',
  RESIDENTIAL = 'RESIDENTIAL',
  TRAFFIC = 'TRAFFIC',
  CUSTOM = 'CUSTOM'
}


// 工具功能配置接口
export interface ToolConfig {
  id: string;
  title: string;
  icon: Resource;
  description: string;
  category: ToolCategory;
  priority: ToolPriority;
  usageHint?: string; // 功能提示
  learnMore?: () => void; // 学习更多
  usageFrequency?: number; // 使用频率 0-1
  progress?: number; // 配置完成度 0-1
  isLocked?: boolean; // 是否锁定
  unlockCondition?: string; // 解锁条件
  quickSetup?: () => void; // 快速设置
  getStatus?: () => string;
  getStatusColor?: () => Resource;
  onTap: () => void;
}

// 功能分类配置接口
export interface CategoryConfig {
  title: string;
  icon: Resource;
  description: string;
  color: Resource;
  tools: ToolConfig[];
}

@ComponentV2
export struct ToolsContent {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local private isLocationRefreshing: boolean = false;
  @Local expandedCategories: Set<ToolCategory> = new Set();
  @Local animatingCategories: Set<ToolCategory> = new Set();
  @Local hoveredTool: string = '';
  @Local pressedTool: string = '';
  @Local showAdvancedHints: boolean = false; // 是否显示高级功能提示
  @Local userSkillLevel: 'beginner' | 'intermediate' | 'expert' = 'beginner'; // 用户技能水平
  private locationService: LocationService = LocationService.getInstance();
  private navigationService: ToolNavigationService = new ToolNavigationService(this.pk);
  private statusService: ToolStatusService = new ToolStatusService(this.pk);

  aboutToAppear(): void {
    // 服务已在属性声明时初始化
    // 根据用户技能水平设置默认展开分类
    this.setupDefaultCategories();
    // 如果位置服务已开启，自动获取位置
    if (this.pk.location_enabled) {
      this.refreshLocation();
    }

    // 默认展开所有分类，让用户自由探索
    this.expandedCategories.add(ToolCategory.BASIC_MEASUREMENT);
    this.expandedCategories.add(ToolCategory.DATA_MANAGEMENT);
    this.expandedCategories.add(ToolCategory.DISPLAY_SETTINGS);
    this.expandedCategories.add(ToolCategory.ALERT_SYSTEM);
    this.expandedCategories.add(ToolCategory.ADVANCED_SETTINGS);


    // 根据使用历史评估用户水平
    this.evaluateUserSkillLevel();
  }

  // 根据技能水平设置默认展开分类
  private setupDefaultCategories(): void {
    switch (this.userSkillLevel) {
      case UserSkillLevel.BEGINNER:
        this.expandedCategories.add(ToolCategory.BASIC_MEASUREMENT);
        break;
      case UserSkillLevel.INTERMEDIATE:
        this.expandedCategories.add(ToolCategory.BASIC_MEASUREMENT);
        this.expandedCategories.add(ToolCategory.DATA_MANAGEMENT);
        this.expandedCategories.add(ToolCategory.ALERT_SYSTEM);
        break;
      case UserSkillLevel.EXPERT:
        this.expandedCategories.add(ToolCategory.BASIC_MEASUREMENT);
        this.expandedCategories.add(ToolCategory.DATA_MANAGEMENT);
        this.expandedCategories.add(ToolCategory.DISPLAY_SETTINGS);
        this.expandedCategories.add(ToolCategory.ALERT_SYSTEM);
        this.expandedCategories.add(ToolCategory.ADVANCED_SETTINGS);
        break;
    }
  }

  aboutToDisappear(): void {
  }

  // 评估用户技能水平
  private evaluateUserSkillLevel(): void {
    // 这里可以根据用户的使用历史、设置复杂度等来评估
    // 简化版本：根据高级功能的使用情况
    let advancedFeaturesUsed = 0;

    if (this.pk.audio_sample_rate !== 44100) {
      advancedFeaturesUsed++;
    }
    if (this.pk.window_function_type !== 'HANNING') {
      advancedFeaturesUsed++;
    }
    if (this.pk.audio_decimation_enabled) {
      advancedFeaturesUsed++;
    }

    if (advancedFeaturesUsed >= 2) {
      this.userSkillLevel = 'expert';
    } else if (advancedFeaturesUsed >= 1) {
      this.userSkillLevel = 'intermediate';
    }
  }

  // 获取所有功能分类配置
  private getCategories(): CategoryConfig[] {
    return [
      this.buildBasicMeasurementCategory(),
      this.buildDataManagementCategory(),
      this.buildDisplaySettingsCategory(),
      this.buildAlertSystemCategory(),
      this.buildAdvancedSettingsCategory()
    ];
  }

  // 创建工具配置工厂实例
  private toolFactory: ToolConfigFactory = new ToolConfigFactory(this.pk, this.ak);

  // 构建基础测量分类
  private buildBasicMeasurementCategory(): CategoryConfig {
    return {
      title: '基础测量',
      icon: $r('app.media.ic_meter'),
      description: '核心测量功能设置',
      color: $r('sys.color.brand'), // 统一使用主色调
      tools: [
        this.toolFactory.createCalibrationTool(this.navigationService.navigateToAudioCalibration),
        this.toolFactory.createFrequencyWeightingTool(this.navigationService.navigateToFrequencyWeighting,
          this.statusService.getWeightingDisplayName.bind(this.statusService)),
        this.toolFactory.createAudioAnalysisModeTool(this.navigationService.navigateToAudioAnalysisMode,
          this.statusService.getAnalysisModeDisplayName.bind(this.statusService))
      ]
    };
  }

  // 构建数据管理分类
  private buildDataManagementCategory(): CategoryConfig {
    return {
      title: '数据管理',
      icon: $r('app.media.ic_save'),
      description: '数据记录和存储设置',
      color: $r('sys.color.brand'), // 统一使用主色调
      tools: [
        this.toolFactory.createAudioRecordingTool(this.navigationService.toggleAudioRecording),
        this.toolFactory.createAutoSaveTool(this.navigationService.navigateToAutoSave),
        this.toolFactory.createLocationServiceTool(this.navigationService.toggleLocationService.bind(this.navigationService,
          this.refreshLocation.bind(this)), this.statusService.getLocationStatus.bind(this.statusService),
          this.statusService.getLocationStatusColor.bind(this.statusService))
      ]
    };
  }

  // 构建显示设置分类
  private buildDisplaySettingsCategory(): CategoryConfig {
    return {
      title: '显示设置',
      icon: $r('app.media.ic_frequency_weighting'),
      description: '频谱显示配置',
      color: $r('sys.color.brand'), // 统一使用主色调
      tools: [
        this.toolFactory.createSpectrumDisplayTool(this.navigationService.navigateToSpectrumDisplaySettings,
          this.statusService.getSpectrumDisplayModeText.bind(this.statusService))
      ]
    };
  }

  // 构建警报系统分类
  private buildAlertSystemCategory(): CategoryConfig {
    return {
      title: '警报系统',
      icon: $r('app.media.ic_alarm'),
      description: '阈值和通知管理',
      color: $r('sys.color.brand'), // 统一使用主色调
      tools: [
        this.toolFactory.createAlertsTool(this.navigationService.navigateToAlerts)
      ]
    };
  }

  // 构建专业设置分类
  private buildAdvancedSettingsCategory(): CategoryConfig {
    return {
      title: '专业设置',
      icon: $r('app.media.ic_filter'),
      description: '高级音频处理和分析',
      color: $r('sys.color.brand'), // 统一使用主色调
      tools: [
        this.toolFactory.createSampleRateTool(this.navigationService.navigateToSampleRateSettings,
          this.statusService.getSampleRateDisplayText.bind(this.statusService)),
        this.toolFactory.createWindowFunctionTool(this.navigationService.navigateToWindowFunctionSettings,
          this.statusService.getWindowFunctionDisplayName.bind(this.statusService)),
        this.toolFactory.createWindowParamsTool(this.navigationService.navigateToWindowFunctionParamsSettings,
          this.statusService.getWindowParamsDisplayName.bind(this.statusService))
      ]
    };
  }

  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {
        // 智能提示区域 - 简化版本
        this.buildSimplifiedTips()

        // 工具网格布局 - 扁平化展示所有工具
        Grid() {
          ForEach(this.getAllTools(), (tool: ToolConfig) => {
            GridItem() {
              this.buildSimplifiedToolCard(tool)
            }
          })
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(DesignConstants.SPACING_SM) // 减小行间距
        .columnsGap(DesignConstants.SPACING_SM) // 减小列间距
        .width('100%')
        .padding(DesignConstants.SPACING_XS) // 减小整体内边距
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .padding(DesignConstants.SPACING_MD)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  private buildSimplifiedTips() {
    Row() {
      Image($r('app.media.ic_info'))
        .width(20)
        .height(20)
        .fillColor($r('sys.color.brand'))

      Text('工具使用提示')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .margin({ left: DesignConstants.SPACING_XS })

      Blank()

      Text('查看')
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.brand'))
        .onClick(() => {
          this.showAdvancedHints = !this.showAdvancedHints;
        })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    
    // 简化的提示内容
    if (this.showAdvancedHints) {
      Text('💡 根据您的使用习惯，我们为您推荐适合的功能配置')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
        .padding({ top: DesignConstants.SPACING_SM, left: DesignConstants.SPACING_MD, right: DesignConstants.SPACING_MD, bottom: DesignConstants.SPACING_SM })
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius({ bottomLeft: DesignConstants.BORDER_RADIUS_MD, bottomRight: DesignConstants.BORDER_RADIUS_MD })
        .margin({ top: -DesignConstants.SPACING_XS })
    }
  }

  @Builder
  private buildTipsHeader() {
    Row() {
      Image($r('app.media.ic_info'))
        .width(20)
        .height(20)
        .fillColor($r('sys.color.brand'))

      Text('智能助手')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .margin({ left: DesignConstants.SPACING_XS })

      Blank()

      Text(this.showAdvancedHints ? '收起提示' : '显示提示')
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.brand'))
        .onClick(() => {
          this.showAdvancedHints = !this.showAdvancedHints;
        })
    }
    .width('100%')
  }

  @Builder
  private buildTipsContent() {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text('💡 根据您的使用习惯，我们为您推荐以下功能：')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))

      Text(this.getSkillLevelTip())
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_secondary'))

      Text('📚 点击功能旁的"了解更多"获取详细说明')
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_secondary'))
    }
    .width('100%')
    .padding({ top: DesignConstants.SPACING_SM })
    .animation({
      duration: DesignConstants.ANIMATION_DURATION_MD,
      curve: Curve.EaseInOut
    })
  }

  // 获取所有工具 - 扁平化处理
  private getAllTools(): ToolConfig[] {
    const allTools: ToolConfig[] = [];
    const categories = this.getCategories();
    
    categories.forEach(category => {
      category.tools.forEach(tool => {
        allTools.push(tool);
      });
    });
    
    return allTools;
  }

  // 获取技能水平提示
  private getSkillLevelTip(): string {
    switch (this.userSkillLevel) {
      case 'beginner':
        return '🎯 建议先熟悉基础测量和校准功能';
      case 'intermediate':
        return '📊 可以尝试频谱显示和警报系统';
      case 'expert':
        return '🔧 专业设置可以让您更精确地控制测量参数';
      default:
        return '🎯 建议先熟悉基础测量和校准功能';
    }
  }

  @Builder
  private buildCategorySection(category: CategoryConfig) {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 分类标题
      this.buildCategoryHeader(category)

      // 分类内容 - 使用动画展开/收起
      if (this.expandedCategories.has(category.tools[0].category)) {
        Column({ space: DesignConstants.SPACING_SM }) {
          ForEach(category.tools, (tool: ToolConfig) => {
            this.buildToolCard(tool)
          })
        }
        .width('100%')
        .margin({ top: DesignConstants.SPACING_SM })
        .opacity(this.animatingCategories.has(category.tools[0].category) ? 0 : 1)
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_MD,
          curve: Curve.EaseInOut,
          delay: this.animatingCategories.has(category.tools[0].category) ? 0 : 50
        })
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_SM)
  }

  @Builder
  private buildCategoryHeader(category: CategoryConfig) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 分类图标
      Image(category.icon)
        .width(24)
        .height(24)
        .fillColor(category.color)
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_SM,
          curve: Curve.EaseInOut
        })

      // 分类信息
      Column({ space: DesignConstants.SPACING_XS }) {
        Row() {
          Text(category.title)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))

          // 专业标识
          if (category.title === '专业设置') {
            Text('PRO')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.background_secondary'))
              .backgroundColor(category.color)
              .borderRadius(DesignConstants.BORDER_RADIUS_XS)
              .padding({
                left: 4,
                right: 4,
                top: 2,
                bottom: 2
              })
              .margin({ left: DesignConstants.SPACING_XS })
              .animation({
                duration: DesignConstants.ANIMATION_DURATION_SM,
                curve: Curve.EaseInOut
              })
          }

          Blank()
        }
        .width('100%')

        Text(category.description)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 展开指示器 - 带动画
      Image($r('sys.media.ohos_ic_public_arrow_down'))
        .width(16)
        .height(16)
        .fillColor($r('sys.color.font_secondary'))
        .rotate({
          angle: this.expandedCategories.has(category.tools[0].category) ? 180 : 0
        })
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_SM,
          curve: Curve.EaseInOut
        })
    }
    .width('100%')
    .padding({ top: DesignConstants.SPACING_SM, bottom: DesignConstants.SPACING_SM })
    .onClick(() => {
      this.toggleCategory(category.tools[0].category)
    })
    .gesture(
      TapGesture()
        .onAction(() => {
          // 添加触觉反馈效果
          this.animateCategoryPress(category.tools[0].category);
        })
    )
  }

  @Builder
  private buildToolCard(tool: ToolConfig) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标区域
      ToolIcon({
        icon: tool.icon,
        isHovered: this.hoveredTool === tool.id,
        isPressed: this.pressedTool === tool.id,
        priority: tool.priority
      })

      // 右侧内容区域
      Column({ space: DesignConstants.SPACING_XS }) {
        // 标题行
        Row() {
          Text(tool.title)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.hoveredTool === tool.id ? $r('sys.color.brand') : $r('sys.color.font_primary'))
            .animation({
              duration: DesignConstants.ANIMATION_DURATION_XS,
              curve: Curve.EaseInOut
            })

          LearnMoreButton({
            learnMore: tool.learnMore
          })

          Blank()
        }
        .width('100%')

        // 描述和状态行
        Row() {
          Text(tool.description)
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)

          ToolStatus({
            status: tool.getStatus?.(),
            statusColor: tool.getStatusColor?.()
          })
        }
        .width('100%')

        // 功能提示
        UsageHint({
          usageHint: tool.usageHint,
          showHint: this.showAdvancedHints
        })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(tool.usageHint && this.showAdvancedHints ? 80 : 60)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor(this.pressedTool === tool.id ? $r('sys.color.comp_background_emphasize') :
      this.hoveredTool === tool.id ? $r('sys.color.comp_background_secondary') :
        $r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .shadow(this.hoveredTool === tool.id ? DesignConstants.SHADOW_MD : DesignConstants.SHADOW_SM)
    .animation({
      duration: DesignConstants.ANIMATION_DURATION_XS,
      curve: Curve.EaseInOut
    })
    .onClick(() => {
      Throttle.click(() => {
        tool.onTap()
      });
    })
    .onHover((isHovered: boolean) => {
      this.hoveredTool = isHovered ? tool.id : '';
    })
  }

  @Builder
  private buildSimplifiedToolCard(tool: ToolConfig) {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 图标和标题区域
      Row({ space: DesignConstants.SPACING_SM }) {
        Image(tool.icon)
          .width(28)
          .height(28)
          .fillColor($r('sys.color.brand'))

        Text(tool.title)
          .fontSize(DesignConstants.FONT_SIZE_MD) // 增大标题字体
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        // 优先级标识 - 简化版本
        if (tool.priority === ToolPriority.ADVANCED) {
          Text('PRO')
            .fontSize(DesignConstants.FONT_SIZE_XS) // 增大PRO标签字体
            .fontColor($r('sys.color.background_secondary'))
            .backgroundColor($r('sys.color.brand'))
            .borderRadius(DesignConstants.BORDER_RADIUS_XS)
            .padding({ left: 4, right: 4, top: 2, bottom: 2 })
        }
      }
      .width('100%')

      // 描述文本
      Text(tool.description)
        .fontSize(DesignConstants.FONT_SIZE_SM) // 增大描述字体
        .fontColor($r('sys.color.font_secondary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .lineHeight(16) // 增加行高，提高可读性

      // 状态区域 - 简化显示
      if (tool.getStatus?.()) {
        Row() {
          Text(tool.getStatus())
            .fontSize(DesignConstants.FONT_SIZE_XS) // 增大状态字体
            .fontColor(tool.getStatusColor?.() || $r('sys.color.font_secondary'))
            .backgroundColor($r('sys.color.comp_background_secondary'))
            .borderRadius(DesignConstants.BORDER_RADIUS_XS)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })

          Blank()
        }
        .width('100%')
      }
    }
    .width('100%')
    .height(100) // 减小卡片高度，让内容更紧凑
    .padding(DesignConstants.SPACING_SM) // 减小内边距
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .shadow(DesignConstants.SHADOW_SM)
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      Throttle.click(() => {
        tool.onTap()
      });
    })
    .gesture(
      TapGesture()
        .onAction(() => {
          // 简单的按压效果
        })
    )
  }

  // 切换分类展开状态
  private toggleCategory(category: ToolCategory): void {
    // 添加动画状态
    this.animatingCategories.add(category);

    if (this.expandedCategories.has(category)) {
      this.expandedCategories.delete(category);
    } else {
      this.expandedCategories.add(category);
    }

    // 延迟清除动画状态
    setTimeout(() => {
      this.animatingCategories.delete(category);
    }, DesignConstants.ANIMATION_DURATION_MD);
  }

  // 分类按压动画效果
  private animateCategoryPress(category: ToolCategory): void {
    // 可以在这里添加更复杂的动画效果
  }

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
        return;
      }

      // 检查定位权限
      const hasPermission = await this.locationService.requestLocationPermission();
      if (!hasPermission) {
        this.pk.location_enabled = false;
        return;
      }

      // 获取位置信息
      const locationInfo: LocationInfo = await this.locationService.requestSingleLocation();
    } catch (error) {
      console.error('获取位置信息失败:', error);
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
      }
    }
  }
}