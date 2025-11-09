import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { EnhancedDesignConstants, LayoutMode, UserSkillLevel } from '../../constants/EnhancedDesignConstants';
import { Throttle } from '../../utils/Debounce';
import { LocationInfo, LocationService } from '../../services/LocationService';
import { ToolNavigationService } from './ToolNavigationService';
import { ToolStatusService } from './ToolStatusService';
import { 
  EnhancedToolConfigFactory, 
  EnhancedToolConfig, 
  MeasurementScene, 
  SceneConfig 
} from './EnhancedToolConfigs';
import { 
  EnhancedToolCard, 
  SearchBar, 
  SceneTag 
} from './EnhancedToolComponents';
import { ToolCategory, ToolPriority } from './ToolsContent';

// 布局模式枚举
enum ViewMode {
  GRID = 'grid',
  LIST = 'list',
  CATEGORY = 'category'
}

@ComponentV2
export struct EnhancedToolsContent {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local private isLocationRefreshing: boolean = false;
  @Local expandedCategories: Set<ToolCategory> = new Set();
  @Local animatingCategories: Set<ToolCategory> = new Set();
  @Local hoveredTool: string = '';
  @Local pressedTool: string = '';
  @Local showAdvancedHints: boolean = false;
  @Local userSkillLevel: UserSkillLevel = UserSkillLevel.BEGINNER;
  @Local layoutMode: LayoutMode = LayoutMode.STANDARD;
  @Local viewMode: ViewMode = ViewMode.CATEGORY;
  @Local searchText: string = '';
  @Local selectedScene: MeasurementScene = MeasurementScene.INDOOR;
  @Local showSceneSelector: boolean = false;
  @Local showQuickSetup: boolean = false;
  @Local filteredTools: EnhancedToolConfig[] = [];
  
  private locationService: LocationService = LocationService.getInstance();
  private navigationService: ToolNavigationService = new ToolNavigationService(this.pk);
  private statusService: ToolStatusService = new ToolStatusService(this.pk);
  private enhancedToolFactory: EnhancedToolConfigFactory = new EnhancedToolConfigFactory(this.pk, this.ak);

  aboutToAppear(): void {
    // 初始化用户技能水平评估
    this.evaluateUserSkillLevel();
    
    // 根据技能水平设置默认展开分类
    this.setupDefaultCategories();
    
    // 如果位置服务已开启，自动获取位置
    if (this.pk.location_enabled) {
      this.refreshLocation();
    }
    
    // 初始化工具列表
    this.updateFilteredTools();
  }

  aboutToDisappear(): void {
  }

  // 评估用户技能水平
  private evaluateUserSkillLevel(): void {
    let advancedFeaturesUsed = 0;
    
    if (this.pk.audio_sample_rate !== 44100) advancedFeaturesUsed++;
    if (this.pk.window_function_type !== 'HANNING') advancedFeaturesUsed++;
    if (this.pk.audio_decimation_enabled) advancedFeaturesUsed++;
    if (this.pk.alarm_threshold.currentEffectiveThreshold > 0) advancedFeaturesUsed++;
    
    if (advancedFeaturesUsed >= 3) {
      this.userSkillLevel = UserSkillLevel.EXPERT;
    } else if (advancedFeaturesUsed >= 1) {
      this.userSkillLevel = UserSkillLevel.INTERMEDIATE;
    } else {
      this.userSkillLevel = UserSkillLevel.BEGINNER;
    }
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

  // 更新过滤后的工具列表
  private updateFilteredTools(): void {
    const allTools = this.getAllEnhancedTools();
    
    if (!this.searchText) {
      this.filteredTools = allTools;
    } else {
      this.filteredTools = allTools.filter(tool => 
        tool.title.toLowerCase().includes(this.searchText.toLowerCase()) ||
        tool.description.toLowerCase().includes(this.searchText.toLowerCase())
      );
    }
  }

  // 获取所有增强版工具
  private getAllEnhancedTools(): EnhancedToolConfig[] {
    return [
      // 快速设置工具
      this.enhancedToolFactory.createQuickSetupTool(
        this.applySceneSettings.bind(this),
        this.selectedScene
      ),
      this.enhancedToolFactory.createSceneSelectorTool(
        this.selectScene.bind(this),
        this.selectedScene
      ),
      
      // 基础测量工具
      this.enhancedToolFactory.createEnhancedCalibrationTool(
        this.navigationService.navigateToAudioCalibration,
        this.userSkillLevel
      ),
      this.enhancedToolFactory.createEnhancedFrequencyWeightingTool(
        this.navigationService.navigateToFrequencyWeighting,
        this.statusService.getWeightingDisplayName.bind(this.statusService),
        this.userSkillLevel
      ),
      this.enhancedToolFactory.createEnhancedAudioAnalysisModeTool(
        this.navigationService.navigateToAudioAnalysisMode,
        this.statusService.getAnalysisModeDisplayName.bind(this.statusService),
        this.userSkillLevel
      ),
      
      // 数据管理工具
      this.enhancedToolFactory.createAudioRecordingTool(
        this.navigationService.toggleAudioRecording
      ),
      this.enhancedToolFactory.createAutoSaveTool(
        this.navigationService.navigateToAutoSave
      ),
      this.enhancedToolFactory.createLocationServiceTool(
        this.navigationService.toggleLocationService.bind(this.navigationService, this.refreshLocation.bind(this)), 
        this.statusService.getLocationStatus.bind(this.statusService), 
        this.statusService.getLocationStatusColor.bind(this.statusService)
      ),
      
      // 显示设置工具
      this.enhancedToolFactory.createSpectrumDisplayTool(
        this.navigationService.navigateToSpectrumDisplaySettings,
        this.statusService.getSpectrumDisplayModeText.bind(this.statusService)
      ),
      
      // 警报系统工具
      this.enhancedToolFactory.createEnhancedAlertsTool(
        this.navigationService.navigateToAlerts,
        this.userSkillLevel
      ),
      
      // 专业设置工具
      this.enhancedToolFactory.createEnhancedSampleRateTool(
        this.navigationService.navigateToSampleRateSettings,
        this.statusService.getSampleRateDisplayText.bind(this.statusService),
        this.userSkillLevel
      ),
      this.enhancedToolFactory.createWindowFunctionTool(
        this.navigationService.navigateToWindowFunctionSettings,
        this.statusService.getWindowFunctionDisplayName.bind(this.statusService)
      ),
      this.enhancedToolFactory.createWindowParamsTool(
        this.navigationService.navigateToWindowFunctionParamsSettings,
        this.statusService.getWindowParamsDisplayName.bind(this.statusService)
      )
    ];
  }

  // 应用场景设置
  private applySceneSettings(scene: MeasurementScene): void {
    const sceneConfig = this.enhancedToolFactory.getSceneConfigs()
      .find(config => config.id === scene);
    
    if (sceneConfig) {
      // 应用场景的快速设置
      if (sceneConfig.quickSettings.weighting) {
        this.pk.weighting_type = sceneConfig.quickSettings.weighting;
      }
      if (sceneConfig.quickSettings.analysisMode) {
        this.pk.audio_analysis_mode = sceneConfig.quickSettings.analysisMode;
      }
      if (sceneConfig.quickSettings.threshold) {
        this.pk.alarm_threshold.currentEffectiveThreshold = sceneConfig.quickSettings.threshold;
      }
      if (sceneConfig.quickSettings.sampleRate) {
        this.pk.audio_sample_rate = sceneConfig.quickSettings.sampleRate;
      }
      
      console.info(`[场景设置] 已应用${sceneConfig.title}配置`);
    }
  }

  // 选择场景
  private selectScene(scene: MeasurementScene): void {
    this.selectedScene = scene;
    this.showSceneSelector = false;
    this.applySceneSettings(scene);
  }

  // 切换布局模式
  private toggleLayoutMode(): void {
    switch (this.layoutMode) {
      case LayoutMode.COMPACT:
        this.layoutMode = LayoutMode.STANDARD;
        break;
      case LayoutMode.STANDARD:
        this.layoutMode = LayoutMode.EXPANDED;
        break;
      case LayoutMode.EXPANDED:
        this.layoutMode = LayoutMode.COMPACT;
        break;
    }
  }

  // 切换视图模式
  private toggleViewMode(): void {
    switch (this.viewMode) {
      case ViewMode.CATEGORY:
        this.viewMode = ViewMode.LIST;
        break;
      case ViewMode.LIST:
        this.viewMode = ViewMode.GRID;
        break;
      case ViewMode.GRID:
        this.viewMode = ViewMode.CATEGORY;
        break;
    }
  }

  build() {
    Column({ space: EnhancedDesignConstants.SPACING_MD }) {
      // 顶部工具栏
      this.buildTopToolbar()
      
      // 搜索栏
      SearchBar({
        searchText: this.searchText,
        onSearchChange: (text: string) => {
          this.searchText = text;
          this.updateFilteredTools();
        },
        onClear: () => {
          this.searchText = '';
          this.updateFilteredTools();
        }
      })
      
      // 场景选择器
      this.buildSceneSelector()
      
      // 智能提示区域
      this.buildSmartTips()
      
      // 主要内容区域
      Scroll() {
        if (this.viewMode === ViewMode.CATEGORY) {
          this.buildCategoryView()
        } else if (this.viewMode === ViewMode.LIST) {
          this.buildListView()
        } else {
          this.buildGridView()
        }
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .padding(EnhancedDesignConstants.SPACING_MD)
    .backgroundColor($r('app.color.background_primary'))
  }

  @Builder
  private buildTopToolbar() {
    Row({ space: EnhancedDesignConstants.SPACING_SM }) {
      // 用户技能水平指示器
      Row({ space: EnhancedDesignConstants.SPACING_XS }) {
        Image($r('app.media.ic_user_level'))
          .width(16)
          .height(16)
          .fillColor($r('app.color.brand'))
        
        Text(this.getSkillLevelText())
          .fontSize(EnhancedDesignConstants.FONT_SIZE_XS)
          .fontColor($r('app.color.font_secondary'))
      }
      
      Blank()
      
      // 视图模式切换按钮
      Button({ type: ButtonType.Circle }) {
        Image(this.getViewModeIcon())
          .width(20)
          .height(20)
          .fillColor($r('app.color.font_primary'))
      }
      .width(36)
      .height(36)
      .backgroundColor($r('app.color.comp_background_primary'))
      .onClick(() => {
        this.toggleViewMode();
      })
      
      // 布局模式切换按钮
      Button({ type: ButtonType.Circle }) {
        Image(this.getLayoutModeIcon())
          .width(20)
          .height(20)
          .fillColor($r('app.color.font_primary'))
      }
      .width(36)
      .height(36)
      .backgroundColor($r('app.color.comp_background_primary'))
      .onClick(() => {
        this.toggleLayoutMode();
      })
    }
    .width('100%')
    .padding(EnhancedDesignConstants.SPACING_SM)
  }

  @Builder
  private buildSceneSelector() {
    Row({ space: EnhancedDesignConstants.SPACING_SM }) {
      Text('当前场景:')
        .fontSize(EnhancedDesignConstants.FONT_SIZE_SM)
        .fontColor($r('app.color.font_secondary'))
      
      const sceneConfig = this.enhancedToolFactory.getSceneConfigs()
        .find(config => config.id === this.selectedScene);
      
      if (sceneConfig) {
        SceneTag({
          scene: sceneConfig.title,
          color: sceneConfig.color
        })
      }
      
      Blank()
      
      Button('更换场景')
        .fontSize(EnhancedDesignConstants.FONT_SIZE_XS)
        .fontColor($r('app.color.brand'))
        .backgroundColor($r('app.color.transparent'))
        .border({
          width: 1,
          color: $r('app.color.brand')
        })
        .borderRadius(EnhancedDesignConstants.BORDER_RADIUS_TAG)
        .height(28)
        .onClick(() => {
          this.showSceneSelector = true;
        })
    }
    .width('100%')
    .padding(EnhancedDesignConstants.SPACING_SM)
    .backgroundColor($r('app.color.comp_background_primary'))
    .borderRadius(EnhancedDesignConstants.BORDER_RADIUS_MD)
  }

  @Builder
  private buildSmartTips() {
    Column({ space: EnhancedDesignConstants.SPACING_SM }) {
      this.buildTipsHeader()
      if (this.showAdvancedHints) {
        this.buildTipsContent()
      }
    }
    .width('100%')
    .padding(EnhancedDesignConstants.SPACING_MD)
    .backgroundColor($r('app.color.comp_background_primary'))
    .borderRadius(EnhancedDesignConstants.BORDER_RADIUS_MD)
    .margin({ bottom: EnhancedDesignConstants.SPACING_MD })
  }

  @Builder
  private buildTipsHeader() {
    Row() {
      Image($r('app.media.ic_info'))
        .width(20)
        .height(20)
        .fillColor($r('app.color.brand'))
      
      Text('智能助手')
        .fontSize(EnhancedDesignConstants.FONT_SIZE_MD)
        .fontWeight(EnhancedDesignConstants.FONT_WEIGHT_MEDIUM)
        .fontColor($r('app.color.font_primary'))
        .margin({ left: EnhancedDesignConstants.SPACING_XS })
      
      Blank()
      
      Text(this.showAdvancedHints ? '收起提示' : '显示提示')
        .fontSize(EnhancedDesignConstants.FONT_SIZE_XS)
        .fontColor($r('app.color.brand'))
        .onClick(() => {
          this.showAdvancedHints = !this.showAdvancedHints;
        })
    }
    .width('100%')
  }

  @Builder
  private buildTipsContent() {
    Column({ space: EnhancedDesignConstants.SPACING_XS }) {
      Text('💡 根据您的使用习惯，我们为您推荐以下功能：')
        .fontSize(EnhancedDesignConstants.FONT_SIZE_SM)
        .fontColor($r('app.color.font_secondary'))
      
      Text(this.getSkillLevelTip())
        .fontSize(EnhancedDesignConstants.FONT_SIZE_XS)
        .fontColor($r('app.color.font_secondary'))
      
      Text('📚 点击功能旁的"了解更多"获取详细说明')
        .fontSize(EnhancedDesignConstants.FONT_SIZE_XS)
        .fontColor($r('app.color.font_secondary'))
    }
    .width('100%')
    .padding({ top: EnhancedDesignConstants.SPACING_SM })
    .animation({
      duration: EnhancedDesignConstants.ANIMATION_DURATION_MD,
      curve: Curve.EaseInOut
    })
  }

  @Builder
  private buildCategoryView() {
    Column({ space: EnhancedDesignConstants.SPACING_MD }) {
      // 按分类显示工具
      ForEach(this.getCategoriesByPriority(), (category: { category: ToolCategory, tools: EnhancedToolConfig[] }) => {
        this.buildCategorySection(category.category, category.tools)
      })
    }
    .width('100%')
  }

  @Builder
  private buildListView() {
    Column({ space: EnhancedDesignConstants.SPACING_SM }) {
      ForEach(this.filteredTools, (tool: EnhancedToolConfig) => {
        EnhancedToolCard({
          tool: tool,
          isHovered: this.hoveredTool === tool.id,
          isPressed: this.pressedTool === tool.id,
          layoutMode: this.layoutMode,
          userSkillLevel: this.userSkillLevel,
          showPreview: true,
          onQuickAction: tool.quickSetup,
          onCardHover: (toolId: string, isHovered: boolean) => {
            this.hoveredTool = isHovered ? toolId : '';
          }
        })
      })
    }
    .width('100%')
  }

  @Builder
  private buildGridView() {
    Grid() {
      ForEach(this.filteredTools, (tool: EnhancedToolConfig) => {
        GridItem() {
          EnhancedToolCard({
            tool: tool,
            isHovered: this.hoveredTool === tool.id,
            isPressed: this.pressedTool === tool.id,
            layoutMode: this.layoutMode,
            userSkillLevel: this.userSkillLevel,
            showPreview: true,
            onQuickAction: tool.quickSetup,
            onCardHover: (toolId: string, isHovered: boolean) => {
              this.hoveredTool = isHovered ? toolId : '';
            }
          })
        }
      })
    }
    .columnsTemplate('1fr')
    .rowsGap(EnhancedDesignConstants.CARD_SPACING)
    .width('100%')
  }

  @Builder
  private buildCategorySection(category: ToolCategory, tools: EnhancedToolConfig[]) {
    Column({ space: EnhancedDesignConstants.SPACING_MD }) {
      // 分类标题
      this.buildCategoryHeader(category, tools)
      
      // 分类内容
      if (this.expandedCategories.has(category)) {
        Column({ space: EnhancedDesignConstants.CARD_SPACING }) {
          ForEach(tools, (tool: EnhancedToolConfig) => {
            EnhancedToolCard({
              tool: tool,
              isHovered: this.hoveredTool === tool.id,
              isPressed: this.pressedTool === tool.id,
              layoutMode: this.layoutMode,
              userSkillLevel: this.userSkillLevel,
              showPreview: true,
              onQuickAction: tool.quickSetup,
              onCardHover: (toolId: string, isHovered: boolean) => {
                this.hoveredTool = isHovered ? toolId : '';
              }
            })
          })
        }
        .width('100%')
        .margin({ top: EnhancedDesignConstants.SPACING_SM })
        .opacity(this.animatingCategories.has(category) ? 0 : 1)
        .animation({
          duration: EnhancedDesignConstants.ANIMATION_DURATION_MD,
          curve: Curve.EaseInOut,
          delay: this.animatingCategories.has(category) ? 0 : 50
        })
      }
    }
    .width('100%')
    .padding(EnhancedDesignConstants.SPACING_MD)
    .backgroundColor($r('app.color.comp_background_primary'))
    .borderRadius(EnhancedDesignConstants.BORDER_RADIUS_LG)
    .shadow(EnhancedDesignConstants.SHADOW_SM)
  }

  @Builder
  private buildCategoryHeader(category: ToolCategory, tools: EnhancedToolConfig[]) {
    Row({ space: EnhancedDesignConstants.SPACING_MD }) {
      // 分类图标
      Image(this.getCategoryIcon(category))
        .width(24)
        .height(24)
        .fillColor(this.getCategoryColor(category))
      
      // 分类信息
      Column({ space: EnhancedDesignConstants.SPACING_XS }) {
        Row() {
          Text(this.getCategoryTitle(category))
            .fontSize(EnhancedDesignConstants.FONT_SIZE_MD)
            .fontWeight(EnhancedDesignConstants.FONT_WEIGHT_MEDIUM)
            .fontColor($r('app.color.font_primary'))
          
          // 工具数量
          Text(`(${tools.length})`)
            .fontSize(EnhancedDesignConstants.FONT_SIZE_XS)
            .fontColor($r('app.color.font_secondary'))
            .margin({ left: EnhancedDesignConstants.SPACING_XS })
          
          Blank()
        }
        .width('100%')
        
        Text(this.getCategoryDescription(category))
          .fontSize(EnhancedDesignConstants.FONT_SIZE_SM)
          .fontColor($r('app.color.font_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      
      // 展开指示器
      Image($r('sys.media.ohos_ic_public_arrow_down'))
        .width(16)
        .height(16)
        .fillColor($r('app.color.font_secondary'))
        .rotate({
          angle: this.expandedCategories.has(category) ? 180 : 0
        })
        .animation({
          duration: EnhancedDesignConstants.ANIMATION_DURATION_SM,
          curve: Curve.EaseInOut
        })
    }
    .width('100%')
    .padding({ top: EnhancedancedDesignConstants.SPACING_SM, bottom: EnhancedDesignConstants.SPACING_SM })
    .onClick(() => {
      this.toggleCategory(category);
    })
  }

  // 辅助方法

  private getSkillLevelText(): string {
    switch (this.userSkillLevel) {
      case UserSkillLevel.BEGINNER:
        return '初级用户';
      case UserSkillLevel.INTERMEDIATE:
        return '中级用户';
      case UserSkillLevel.EXPERT:
        return '专业用户';
      default:
        return '初级用户';
    }
  }

  private getSkillLevelTip(): string {
    switch (this.userSkillLevel) {
      case UserSkillLevel.BEGINNER:
        return '🎯 建议先熟悉基础测量和校准功能';
      case UserSkillLevel.INTERMEDIATE:
        return '📊 可以尝试频谱显示和警报系统';
      case UserSkillLevel.EXPERT:
        return '🔧 专业设置可以让您更精确地控制测量参数';
      default:
        return '🎯 建议先熟悉基础测量和校准功能';
    }
  }

  private getViewModeIcon(): Resource {
    switch (this.viewMode) {
      case ViewMode.CATEGORY:
        return $r('app.media.ic_view_category');
      case ViewMode.LIST:
        return $r('app.media.ic_view_list');
      case ViewMode.GRID:
        return $r('app.media.ic_view_grid');
      default:
        return $r('app.media.ic_view_category');
    }
  }

  private getLayoutModeIcon(): Resource {
    switch (this.layoutMode) {
      case LayoutMode.COMPACT:
        return $r('app.media.ic_layout_compact');
      case LayoutMode.STANDARD:
        return $r('app.media.ic_layout_standard');
      case LayoutMode.EXPANDED:
        return $r('app.media.ic_layout_expanded');
      default:
        return $r('app.media.ic_layout_standard');
    }
  }

  private getCategoriesByPriority(): { category: ToolCategory, tools: EnhancedToolConfig[] }[] {
    const toolsByCategory = new Map<ToolCategory, EnhancedToolConfig[]>();
    
    // 按分类分组
    this.filteredTools.forEach(tool => {
      if (!toolsByCategory.has(tool.category)) {
        toolsByCategory.set(tool.category, []);
      }
      toolsByCategory.get(tool.category)?.push(tool);
    });
    
    // 转换为数组并按优先级排序
    const result: { category: ToolCategory, tools: EnhancedToolConfig[] }[] = [];
    
    // 按照优先级顺序添加分类
    [ToolCategory.BASIC_MEASUREMENT, ToolCategory.DATA_MANAGEMENT, 
     ToolCategory.DISPLAY_SETTINGS, ToolCategory.ALERT_SYSTEM, 
     ToolCategory.ADVANCED_SETTINGS].forEach(category => {
      const tools = toolsByCategory.get(category);
      if (tools && tools.length > 0) {
        // 在每个分类内按优先级排序
        tools.sort((a, b) => {
          const priorityOrder = {
            [ToolPriority.ESSENTIAL]: 0,
            [ToolPriority.RECOMMENDED]: 1,
            [ToolPriority.ADVANCED]: 2
          };
          return priorityOrder[a.priority] - priorityOrder[b.priority];
        });
        
        result.push({ category, tools });
      }
    });
    
    return result;
  }

  private getCategoryIcon(category: ToolCategory): Resource {
    switch (category) {
      case ToolCategory.BASIC_MEASUREMENT:
        return $r('app.media.ic_meter');
      case ToolCategory.DATA_MANAGEMENT:
        return $r('app.media.ic_save');
      case ToolCategory.DISPLAY_SETTINGS:
        return $r('app.media.ic_frequency_weighting');
      case ToolCategory.ALERT_SYSTEM:
        return $r('app.media.ic_alarm');
      case ToolCategory.ADVANCED_SETTINGS:
        return $r('app.media.ic_filter');
      default:
        return $r('app.media.ic_meter');
    }
  }

  private getCategoryColor(category: ToolCategory): Resource {
    switch (category) {
      case ToolCategory.BASIC_MEASUREMENT:
        return $r('app.color.brand');
      case ToolCategory.DATA_MANAGEMENT:
        return $r('app.color.confirm');
      case ToolCategory.DISPLAY_SETTINGS:
        return $r('app.color.font_emphasize');
      case ToolCategory.ALERT_SYSTEM:
        return $r('app.color.warning');
      case ToolCategory.ADVANCED_SETTINGS:
        return $r('app.color.font_secondary');
      default:
        return $r('app.color.brand');
    }
  }

  private getCategoryTitle(category: ToolCategory): string {
    switch (category) {
      case ToolCategory.BASIC_MEASUREMENT:
        return '基础测量';
      case ToolCategory.DATA_MANAGEMENT:
        return '数据管理';
      case ToolCategory.DISPLAY_SETTINGS:
        return '显示设置';
      case ToolCategory.ALERT_SYSTEM:
        return '警报系统';
      case ToolCategory.ADVANCED_SETTINGS:
        return '专业设置';
      default:
        return '未知分类';
    }
  }

  private getCategoryDescription(category: ToolCategory): string {
    switch (category) {
      case ToolCategory.BASIC_MEASUREMENT:
        return '核心测量功能设置';
      case ToolCategory.DATA_MANAGEMENT:
        return '数据记录和存储设置';
      case ToolCategory.DISPLAY_SETTINGS:
        return '频谱显示配置';
      case ToolCategory.ALERT_SYSTEM:
        return '阈值和通知管理';
      case ToolCategory.ADVANCED_SETTINGS:
        return '高级音频处理和分析';
      default:
        return '';
    }
  }

  private toggleCategory(category: ToolCategory): void {
    this.animatingCategories.add(category);
    
    if (this.expandedCategories.has(category)) {
      this.expandedCategories.delete(category);
    } else {
      this.expandedCategories.add(category);
    }
    
    setTimeout(() => {
      this.animatingCategories.delete(category);
    }, EnhancedDesignConstants.ANIMATION_DURATION_MD);
  }

  // 刷新位置信息方法
  private async refreshLocation(): Promise<void> {
    if (!this.pk.location_enabled || this.isLocationRefreshing) {
      return;
    }

    try {
      this.isLocationRefreshing = true;

      const isServiceEnabled = this.locationService.checkLocationEnabled();
      if (!isServiceEnabled) {
        return;
      }

      const hasPermission = await this.locationService.requestLocationPermission();
      if (!hasPermission) {
        this.pk.location_enabled = false;
        return;
      }

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
        this.refreshLocation();
      }
    }
  }
}