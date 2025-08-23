import { DesignConstants } from "../constants/DesignConstants"
import display from '@ohos.display';
import { ResponsiveLayout, Breakpoint, LayoutMode, WindowChangeListener } from "../utils/ResponsiveLayout"

// 评分等级枚举
enum RatingLevel {
  EXCELLENT,  // 优秀: 90-100
  GOOD,       // 良好: 70-89  
  FAIR,       // 一般: 60-69
  POOR        // 差: 0-59
}

// 评分等级信息接口
interface RatingLevelInfo {
  level: RatingLevel;
  label: string;
  color: ResourceColor;
  minScore: number;
  maxScore: number;
}

@ComponentV2
export struct RatingPanel {
  @Param @Require score: number = 0; // 0-100的评分
  @Local screenWidth: number = 0;
  @Local layoutMode: LayoutMode = LayoutMode.LARGE;
  @Local cachedLayoutMode: LayoutMode = LayoutMode.LARGE;
  @Local cachedScreenWidth: number = 0;
  @Local lastLayoutUpdateTime: number = 0;
  
  // 缓存变量声明
  @Local cachedRingSize: number | undefined = undefined;
  @Local cachedStrokeWidth: number | undefined = undefined;
  @Local cachedScoreFontSize: number | undefined = undefined;
  @Local cachedLabelFontSize: number | undefined = undefined;

  aboutToAppear() {
    this.updateScreenWidth();
    // 使用统一的ResponsiveLayout监听器
    ResponsiveLayout.getInstance().addChangeListener(this.layoutChangeCallback);
  }

  aboutToDisappear() {
    // 移除ResponsiveLayout监听器
    ResponsiveLayout.getInstance().removeChangeListener(this.layoutChangeCallback);
  }

  // 布局变化回调函数
  private layoutChangeCallback: WindowChangeListener = (width: number, height: number, breakpoint: Breakpoint, layoutMode: LayoutMode) => {
    this.layoutMode = layoutMode;
    this.cachedLayoutMode = layoutMode;
    this.clearCache(); // 清除缓存，确保下次获取新值
    console.debug(`[RatingPanel] Layout mode changed to: ${layoutMode}`);
  }

  // 获取评分等级信息
  private getRatingLevelInfo(): RatingLevelInfo {
    if (this.score >= 90) {
      return {
        level: RatingLevel.EXCELLENT,
        label: '优秀',
        color: $r('app.color.health_good'),
        minScore: 90,
        maxScore: 100
      };
    } else if (this.score >= 70) {
      return {
        level: RatingLevel.GOOD,
        label: '良好',
        color: $r('app.color.primary'),
        minScore: 70,
        maxScore: 89
      };
    } else if (this.score >= 60) {
      return {
        level: RatingLevel.FAIR,
        label: '一般',
        color: $r('app.color.health_warning'),
        minScore: 60,
        maxScore: 69
      };
    } else {
      return {
        level: RatingLevel.POOR,
        label: '差',
        color: $r('app.color.health_bad'),
        minScore: 0,
        maxScore: 59
      };
    }
  }

  // 更新屏幕宽度（初始化时使用）
  private updateScreenWidth() {
    try {
      const displayClass = display.getDefaultDisplaySync();
      const newScreenWidth = displayClass.width;
      this.screenWidth = newScreenWidth;
      this.cachedScreenWidth = newScreenWidth;
      
      // 使用ResponsiveLayout的统一布局模式
      const screenInfo = ResponsiveLayout.getInstance().getCurrentScreenInfo();
      this.layoutMode = screenInfo.layoutMode;
      this.cachedLayoutMode = screenInfo.layoutMode;
    } catch (error) {
      console.error('Failed to get display info:', error);
    }
  }

  // 更新布局模式
  private updateLayoutMode(width: number): void {
    const breakpoint = ResponsiveLayout.getInstance().getBreakpoint(width);
    const layoutMode = ResponsiveLayout.getInstance().getLayoutMode(breakpoint);
    this.layoutMode = layoutMode;
    this.cachedLayoutMode = layoutMode;
    this.clearCache(); // 清除缓存，确保下次获取新值
  }

  @Builder
  buildResponsiveLayout() {
    if (this.layoutMode === LayoutMode.XSMALL) {
      this.buildXSmallLayout();
    } else if (this.layoutMode === LayoutMode.SMALL) {
      this.buildSmallLayout();
    } else if (this.layoutMode === LayoutMode.MEDIUM) {
      this.buildMediumLayout();
    } else {
      this.buildLargeLayout();
    }
  }

  @Builder
  buildLargeLayout() {
    // 大屏布局：完整的评分面板 - 文字叠加在圆环中间
    Stack({ alignContent: Alignment.Center }) {
      this.buildProgressRing()
      Column() {
        this.buildScoreText()
        this.buildRatingLabel()
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')
    }
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_MD)
    .width(180)
    .height(150)
  }

  @Builder
  buildMediumLayout() {
    // 中屏布局：稍微紧凑的布局 - 文字叠加在圆环中间
    Stack({ alignContent: Alignment.Center }) {
      this.buildProgressRing()
      Column() {
        this.buildScoreText()
        this.buildRatingLabel()
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')
    }
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .shadow(DesignConstants.SHADOW_SM)
    .width(160)
    .height(180)
  }

  @Builder
  buildSmallLayout() {
    // 小屏布局：更紧凑的布局 - 文字叠加在圆环中间
    Stack({ alignContent: Alignment.Center }) {
      this.buildProgressRing()
      Column() {
        this.buildScoreText()
        this.buildRatingLabel()
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')
    }
    .padding(DesignConstants.SPACING_SM)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_SM)
    .shadow(DesignConstants.SHADOW_SM)
    .width(140)
    .height(160)
  }

  @Builder
  buildXSmallLayout() {
    // 超小屏布局：最紧凑的布局 - 文字叠加在圆环中间
    Stack({ alignContent: Alignment.Center }) {
      this.buildProgressRing()
      Column() {
        this.buildScoreText()
        this.buildRatingLabel()
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height('100%')
    }
    .padding(DesignConstants.SPACING_XS)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_SM)
    .shadow(DesignConstants.SHADOW_SM)
    .width(120)
    .height(140)
  }

  @Builder
  buildProgressRing() {
    Stack() {
      // 背景环形
      Progress({
        value: 100,
        type: ProgressType.Ring,
      })
        .width(this.getRingSize())
        .height(this.getRingSize())
        .style({
          strokeWidth: this.getStrokeWidth(),
        })
        .backgroundColor($r('app.color.background_tertiary'))
        .color($r('app.color.background_tertiary'))

      // 进度环形
      Progress({
        value: this.score,
        type: ProgressType.Ring,
      })
        .width(this.getRingSize())
        .height(this.getRingSize())
        .style({
          strokeWidth: this.getStrokeWidth(),
        })
        .backgroundColor(Color.Transparent)
        .color(this.getRatingLevelInfo().color)
    }
    .margin({ bottom: 0 })
  }

  @Builder
  buildScoreText() {
    Text(`${this.score}`)
      .fontSize(this.getScoreFontSize())
      .fontWeight(FontWeight.Bold)
      .fontColor(this.getRatingLevelInfo().color)
      .margin({ bottom: 0 })
  }

  @Builder
  buildRatingLabel() {
    Text(this.getRatingLevelInfo().label)
      .fontSize(this.getLabelFontSize())
      .fontColor($r('app.color.text_secondary'))
  }

  // 根据布局模式获取环形大小（使用缓存机制）
  private getRingSize(): number {
    // 缓存计算结果，避免重复switch判断
    if (!this.cachedRingSize) {
      switch (this.layoutMode) {
        case LayoutMode.XLARGE:
        case LayoutMode.LARGE: this.cachedRingSize = DesignConstants.RATING_PANEL.RING_SIZE_LARGE; break;
        case LayoutMode.MEDIUM: this.cachedRingSize = DesignConstants.RATING_PANEL.RING_SIZE_MEDIUM; break;
        case LayoutMode.SMALL: this.cachedRingSize = DesignConstants.RATING_PANEL.RING_SIZE_SMALL; break;
        case LayoutMode.XSMALL: this.cachedRingSize = DesignConstants.RATING_PANEL.RING_SIZE_XSMALL; break;
        default: this.cachedRingSize = DesignConstants.RATING_PANEL.RING_SIZE_LARGE;
      }
    }
    return this.cachedRingSize;
  }

  // 根据布局模式获取环形宽度（使用缓存机制）
  private getStrokeWidth(): number {
    if (!this.cachedStrokeWidth) {
      switch (this.layoutMode) {
        case LayoutMode.XLARGE:
        case LayoutMode.LARGE: this.cachedStrokeWidth = DesignConstants.RATING_PANEL.STROKE_WIDTH_LARGE; break;
        case LayoutMode.MEDIUM: this.cachedStrokeWidth = DesignConstants.RATING_PANEL.STROKE_WIDTH_MEDIUM; break;
        case LayoutMode.SMALL: this.cachedStrokeWidth = DesignConstants.RATING_PANEL.STROKE_WIDTH_SMALL; break;
        case LayoutMode.XSMALL: this.cachedStrokeWidth = DesignConstants.RATING_PANEL.STROKE_WIDTH_XSMALL; break;
        default: this.cachedStrokeWidth = DesignConstants.RATING_PANEL.STROKE_WIDTH_LARGE;
      }
    }
    return this.cachedStrokeWidth;
  }

  // 根据布局模式获取分数字体大小（使用缓存机制）
  private getScoreFontSize(): number {
    if (!this.cachedScoreFontSize) {
      switch (this.layoutMode) {
        case LayoutMode.XLARGE:
        case LayoutMode.LARGE: this.cachedScoreFontSize = DesignConstants.FONT_SIZE_3XL; break;
        case LayoutMode.MEDIUM: this.cachedScoreFontSize = DesignConstants.FONT_SIZE_2XL; break;
        case LayoutMode.SMALL: this.cachedScoreFontSize = DesignConstants.FONT_SIZE_XL; break;
        case LayoutMode.XSMALL: this.cachedScoreFontSize = DesignConstants.FONT_SIZE_LG; break;
        default: this.cachedScoreFontSize = DesignConstants.FONT_SIZE_3XL;
      }
    }
    return this.cachedScoreFontSize;
  }

  // 根据布局模式获取标签字体大小（使用缓存机制）
  private getLabelFontSize(): number {
    if (!this.cachedLabelFontSize) {
      switch (this.layoutMode) {
        case LayoutMode.XLARGE:
        case LayoutMode.LARGE: this.cachedLabelFontSize = DesignConstants.FONT_SIZE_MD; break;
        case LayoutMode.MEDIUM: this.cachedLabelFontSize = DesignConstants.FONT_SIZE_SM; break;
        case LayoutMode.SMALL: this.cachedLabelFontSize = DesignConstants.FONT_SIZE_SM; break;
        case LayoutMode.XSMALL: this.cachedLabelFontSize = DesignConstants.FONT_SIZE_XS; break;
        default: this.cachedLabelFontSize = DesignConstants.FONT_SIZE_MD;
      }
    }
    return this.cachedLabelFontSize;
  }

  // 当布局模式改变时清除缓存
  private clearCache() {
    this.cachedRingSize = undefined;
    this.cachedStrokeWidth = undefined;
    this.cachedScoreFontSize = undefined;
    this.cachedLabelFontSize = undefined;
  }

  build() {
    Column() {
      this.buildResponsiveLayout()
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}