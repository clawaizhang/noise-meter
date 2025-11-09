import { ToolConfig, ToolPriority, ToolCategory } from './ToolsContent';
import { EnhancedDesignConstants, PriorityVisualConfig, LayoutMode, UserSkillLevel } from '../../constants/EnhancedDesignConstants';

// 场景标签组件
@ComponentV2
export struct SceneTag {
  @Param @Require scene: string;
  @Param @Require color: Resource;
  
  build() {
    Text(this.scene)
      .fontSize(EnhancedDesignConstants.FONT_SIZE_XXS)
      .fontColor($r('app.color.background_secondary'))
      .backgroundColor(this.color)
      .borderRadius(EnhancedDesignConstants.BORDER_RADIUS_TAG)
      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      .margin({ right: EnhancedDesignConstants.SPACING_XS })
  }
}

// 进度指示器组件
@ComponentV2
export struct ProgressIndicator {
  @Param @Require progress: number; // 0-1
  @Param @Require color: Resource;
  
  build() {
    Row() {
      Progress({ 
        value: this.progress * 100, 
        total: 100, 
        type: ProgressType.Linear 
      })
        .width(60)
        .height(4)
        .color(this.color)
        .backgroundColor($r('app.color.comp_background_secondary'))
        .borderRadius(2)
    }
    .alignItems(VerticalAlign.Center)
  }
}

// 功能预览卡片组件
@ComponentV2
export struct ToolPreviewCard {
  @Param @Require tool: ToolConfig;
  @Param @Require isVisible: boolean;
  @Param onQuickAction?: () => void;
  
  build() {
    if (this.isVisible) {
      Column({ space: EnhancedDesignConstants.SPACING_SM }) {
        // 预览标题
        Row() {
          Text(this.tool.title)
            .fontSize(EnhancedDesignConstants.FONT_SIZE_SM)
            .fontWeight(EnhancedDesignConstants.FONT_WEIGHT_SEMI_BOLD)
            .fontColor($r('app.color.font_primary'))
          
          Blank()
          
          if (this.onQuickAction) {
            Button('快速设置')
              .fontSize(EnhancedDesignConstants.FONT_SIZE_XXS)
              .fontColor($r('app.color.background_secondary'))
              .backgroundColor(EnhancedDesignConstants.COLOR_QUICK_ACTION)
              .borderRadius(EnhancedDesignConstants.BORDER_RADIUS_TAG)
              .height(28)
              .onClick(() => {
                this.onQuickAction?.();
              })
          }
        }
        .width('100%')
        
        // 预览内容
        Text(this.tool.description)
          .fontSize(EnhancedDesignConstants.FONT_SIZE_XS)
          .fontColor($r('app.color.font_secondary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        
        // 状态信息
        if (this.tool.getStatus?.()) {
          Row() {
            Text('当前状态:')
              .fontSize(EnhancedDesignConstants.FONT_SIZE_XXS)
              .fontColor($r('app.color.font_secondary'))
            
            Text(this.tool.getStatus?.() || '')
              .fontSize(EnhancedDesignConstants.FONT_SIZE_XXS)
              .fontColor(this.tool.getStatusColor?.() || $r('app.color.font_primary'))
              .fontWeight(EnhancedDesignConstants.FONT_WEIGHT_MEDIUM)
            
            Blank()
            
            ProgressIndicator({
              progress: 0.7, // 示例进度
              color: this.tool.getStatusColor?.() || $r('app.color.brand'))
            })
          }
          .width('100%')
          .margin({ top: EnhancedDesignConstants.SPACING_XS })
        }
      }
      .width('100%')
      .padding(EnhancedDesignConstants.SPACING_SM)
      .backgroundColor($r('app.color.comp_background_primary'))
      .borderRadius(EnhancedDesignConstants.BORDER_RADIUS_PREVIEW)
      .shadow(EnhancedDesignConstants.SHADOW_SM)
      .border({
        width: 1,
        color: $r('app.color.comp_background_secondary'))
      })
      .animation({
        duration: EnhancedDesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseInOut
      })
    }
  }
}

// 增强版工具卡片组件
@ComponentV2
export struct EnhancedToolCard {
  @Param @Require tool: ToolConfig;
  @Param @Require isHovered: boolean;
  @Param @Require isPressed: boolean;
  @Param @Require layoutMode: LayoutMode;
  @Param @Require userSkillLevel: UserSkillLevel;
  @Param @Require showPreview: boolean;
  @Param onQuickAction?: () => void;
  @Param onCardHover?: (toolId: string, isHovered: boolean) => void;
  
  // 根据优先级获取卡片配置
  private getCardConfig(): PriorityVisualConfig.CardSizeConfig {
    switch (this.tool.priority) {
      case ToolPriority.ESSENTIAL:
        return PriorityVisualConfig.ESSENTIAL;
      case ToolPriority.RECOMMENDED:
        return PriorityVisualConfig.RECOMMENDED;
      case ToolPriority.ADVANCED:
        return PriorityVisualConfig.ADVANCED;
      default:
        return PriorityVisualConfig.RECOMMENDED;
    }
  }
  
  // 根据优先级获取背景色
  private getBackgroundColor(): Resource {
    if (this.isPressed) {
      return $r('app.color.comp_background_emphasize');
    }
    
    if (this.isHovered) {
      switch (this.tool.priority) {
        case ToolPriority.ESSENTIAL:
          return $r('app.color.essential_hover');
        case ToolPriority.RECOMMENDED:
          return $r('app.color.recommended_hover');
        case ToolPriority.ADVANCED:
          return $r('app.color.advanced_hover');
        default:
          return $r('app.color.comp_background_secondary');
      }
    }
    
    return $r('app.color.background_secondary');
  }
  
  // 获取卡片阴影
  private getCardShadow(): EnhancedDesignConstants.ShadowStyle {
    if (this.isHovered) {
      if (this.tool.priority === ToolPriority.ESSENTIAL) {
        return EnhancedDesignConstants.SHADOW_ESSENTIAL;
      }
      return EnhancedDesignConstants.SHADOW_MD;
    }
    return EnhancedDesignConstants.SHADOW_SM;
  }
  
  build() {
    Column({ space: EnhancedDesignConstants.SPACING_SM }) {
      // 主卡片
      Row({ space: EnhancedDesignConstants.SPACING_MD }) {
        // 左侧图标区域
        this.buildIconSection()
        
        // 中间内容区域
        this.buildContentSection()
        
        // 右侧操作区域
        this.buildActionSection()
      }
      .width('100%')
      .height(this.getCardConfig().height)
      .padding(this.getCardConfig().padding)
      .backgroundColor(this.getBackgroundColor())
      .borderRadius(this.getCardConfig().borderRadius)
      .shadow(this.getCardShadow())
      .scale({ 
        x: this.isPressed ? EnhancedDesignConstants.CARD_PRESS_SCALE : 
           this.isHovered ? EnhancedDesignConstants.CARD_HOVER_SCALE : 1.0,
        y: this.isPressed ? EnhancedDesignConstants.CARD_PRESS_SCALE : 
           this.isHovered ? EnhancedDesignConstants.CARD_HOVER_SCALE : 1.0
      })
      .animation({
        duration: EnhancedDesignConstants.ANIMATION_DURATION_SM,
        curve: Curve.EaseInOut
      })
      .onClick(() => {
        this.tool.onTap();
      })
      .onHover((isHovered: boolean) => {
        this.onCardHover?.(this.tool.id, isHovered);
      })
      .gesture(
        TapGesture()
          .onAction(() => {
            // 添加触觉反馈
          })
      )
      
      // 预览卡片
      ToolPreviewCard({
        tool: this.tool,
        isVisible: this.showPreview && this.isHovered,
        onQuickAction: this.onQuickAction
      })
    }
    .width('100%')
  }
  
  @Builder
  private buildIconSection() {
    Column({ space: EnhancedDesignConstants.SPACING_XS }) {
      Image(this.tool.icon)
        .width(this.getCardConfig().iconSize)
        .height(this.getCardConfig().iconSize)
        .fillColor(this.isHovered ? $r('app.color.brand') :
                 this.tool.priority === ToolPriority.ESSENTIAL ? EnhancedDesignConstants.COLOR_ESSENTIAL :
                 this.tool.priority === ToolPriority.ADVANCED ? EnhancedDesignConstants.COLOR_ADVANCED :
                 $r('app.color.icon_primary'))
        .animation({
          duration: EnhancedDesignConstants.ANIMATION_DURATION_XS,
          curve: Curve.EaseInOut
        })
      
      // 优先级标签
      this.buildPriorityLabel()
    }
    .alignItems(HorizontalAlign.Center)
  }
  
  @Builder
  private buildPriorityLabel() {
    if (this.tool.priority === ToolPriority.ESSENTIAL) {
      Text('核心')
        .fontSize(EnhancedDesignConstants.FONT_SIZE_XXS)
        .fontColor($r('app.color.background_secondary'))
        .backgroundColor(EnhancedDesignConstants.COLOR_ESSENTIAL)
        .borderRadius(EnhancedDesignConstants.BORDER_RADIUS_TAG)
        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
    } else if (this.tool.priority === ToolPriority.ADVANCED) {
      Text('PRO')
        .fontSize(EnhancedDesignConstants.FONT_SIZE_XXS)
        .fontColor($r('app.color.background_secondary'))
        .backgroundColor(EnhancedDesignConstants.COLOR_ADVANCED)
        .borderRadius(EnhancedDesignConstants.BORDER_RADIUS_TAG)
        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
    }
  }
  
  @Builder
  private buildContentSection() {
    Column({ space: EnhancedDesignConstants.SPACING_XS }) {
      // 标题行
      Row() {
        Text(this.tool.title)
          .fontSize(this.getCardConfig().fontSize.title)
          .fontWeight(EnhancedDesignConstants.FONT_WEIGHT_SEMI_BOLD)
          .fontColor(this.isHovered ? $r('app.color.brand') : $r('app.color.font_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        
        // 学习更多按钮
        if (this.tool.learnMore) {
          Button('了解更多')
            .fontSize(EnhancedDesignConstants.FONT_SIZE_XXS)
            .fontColor($r('app.color.brand'))
            .backgroundColor($r('app.color.transparent'))
            .border({
              width: 1,
              color: $r('app.color.brand')
            })
            .borderRadius(EnhancedDesignConstants.BORDER_RADIUS_TAG)
            .height(24)
            .onClick(() => {
              this.tool.learnMore?.();
            })
        }
      }
      .width('100%')
      
      // 描述行
      Text(this.tool.description)
        .fontSize(this.getCardConfig().fontSize.description)
        .fontColor($r('app.color.font_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      
      // 状态行
      if (this.tool.getStatus?.()) {
        Row() {
          Text(this.tool.getStatus?.() || '')
            .fontSize(this.getCardConfig().fontSize.status)
            .fontWeight(EnhancedDesignConstants.FONT_WEIGHT_MEDIUM)
            .fontColor(this.tool.getStatusColor?.() || $r('app.color.font_primary'))
          
          Blank()
          
          // 状态指示器
          if (this.tool.priority === ToolPriority.ESSENTIAL) {
            Row()
              .width(8)
              .height(8)
              .borderRadius(4)
              .backgroundColor(this.tool.getStatusColor?.() || $r('app.color.confirm'))
          }
        }
        .width('100%')
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }
  
  @Builder
  private buildActionSection() {
    Column({ space: EnhancedDesignConstants.SPACING_XS }) {
      // 快速操作按钮
      if (this.onQuickAction && this.tool.priority === ToolPriority.ESSENTIAL) {
        Button({ type: ButtonType.Circle }) {
          Image($r('sys.media.ohos_ic_public_add'))
            .width(16)
            .height(16)
            .fillColor($r('app.color.background_secondary'))
        }
        .width(32)
        .height(32)
        .backgroundColor(EnhancedDesignConstants.COLOR_QUICK_ACTION)
        .onClick(() => {
          this.onQuickAction?.();
        })
      }
      
      // 箭头指示器
      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .width(16)
        .height(16)
        .fillColor($r('app.color.font_secondary'))
        .opacity(this.isHovered ? 1 : 0.6)
        .animation({
          duration: EnhancedDesignConstants.ANIMATION_DURATION_XS,
          curve: Curve.EaseInOut
        })
    }
    .justifyContent(FlexAlign.Center)
  }
}

// 搜索栏组件
@ComponentV2
export struct SearchBar {
  @Param @Require searchText: string;
  @Param onSearchChange?: (text: string) => void;
  @Param onClear?: () => void;
  
  build() {
    Row({ space: EnhancedDesignConstants.SPACING_SM }) {
      Image($r('sys.media.ohos_ic_public_search'))
        .width(20)
        .height(20)
        .fillColor($r('app.color.font_secondary'))
      
      TextInput({ placeholder: '搜索功能或设置...', text: this.searchText })
        .fontSize(EnhancedDesignConstants.FONT_SIZE_SM)
        .fontColor($r('app.color.font_primary'))
        .backgroundColor($r('app.color.transparent'))
        .border({ width: 0 })
        .layoutWeight(1)
        .onChange((value: string) => {
          this.onSearchChange?.(value);
        })
      
      if (this.searchText) {
        Button({ type: ButtonType.Circle }) {
          Image($r('sys.media.ohos_ic_public_cancel'))
            .width(16)
            .height(16)
            .fillColor($r('app.color.font_secondary'))
        }
        .width(24)
        .height(24)
        .backgroundColor($r('app.color.transparent'))
        .onClick(() => {
          this.onClear?.();
        })
      }
    }
    .width('100%')
    .height(EnhancedDesignConstants.LAYOUT_SEARCH_HEIGHT)
    .padding(EnhancedDesignConstants.SPACING_SM)
    .backgroundColor($r('app.color.comp_background_primary'))
    .borderRadius(EnhancedDesignConstants.BORDER_RADIUS_MD)
    .border({
      width: 1,
      color: $r('app.color.comp_background_secondary')
    })
  }
}