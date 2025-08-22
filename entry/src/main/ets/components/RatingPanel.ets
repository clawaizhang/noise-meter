import { DesignConstants } from "../constants/DesignConstants"
import display from '@ohos.display';

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
  @Local layoutMode: string = 'large'; // large, medium, small, xsmall
  @Local cachedLayoutMode: string = '';
  @Local cachedScreenWidth: number = 0;
  @Local lastLayoutUpdateTime: number = 0;
  
  // 缓存变量声明
  @Local cachedRingSize: number | undefined = undefined;
  @Local cachedStrokeWidth: number | undefined = undefined;
  @Local cachedScoreFontSize: number | undefined = undefined;
  @Local cachedLabelFontSize: number | undefined = undefined;

  aboutToAppear() {
    this.updateScreenWidth();
    // 监听屏幕旋转和尺寸变化
    display.on('change', () => {
      this.updateScreenWidth();
    });
  }

  aboutToDisappear() {
    // 移除屏幕变化监听器
    display.off('change');
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

  // 更新屏幕宽度（带缓存优化）
  private updateScreenWidth() {
    try {
      const displayClass = display.getDefaultDisplaySync();
      const newScreenWidth = displayClass.width;
      
      // 只有当屏幕宽度有显著变化时才更新布局模式
      if (Math.abs(newScreenWidth - this.cachedScreenWidth) > 20) { // 20px变化阈值
        this.screenWidth = newScreenWidth;
        this.cachedScreenWidth = newScreenWidth;
        this.updateLayoutMode(this.screenWidth);
      }
    } catch (error) {
      console.error('Failed to get display info:', error);
    }
  }

  // 更新布局模式（基于实际内容计算切换阈值，带缓存优化）
  private updateLayoutMode(width: number) {
    // 基于实际内容计算各布局模式的最小宽度要求
    const minWidthForLargeLayout = DesignConstants.RATING_PANEL.WIDTH_LARGE + 40; // 面板宽度 + 边距
    const minWidthForMediumLayout = DesignConstants.RATING_PANEL.WIDTH_MEDIUM + 30;
    const minWidthForSmallLayout = DesignConstants.RATING_PANEL.WIDTH_SMALL + 20;
    
    // 添加滞后阈值（基于屏幕宽度的百分比，更智能的防抖）
    const hysteresis = Math.max(15, width * 0.03); // 至少15px或屏幕宽度的3%
    
    let newLayoutMode: string;
    
    if (width >= minWidthForLargeLayout + hysteresis) {
      newLayoutMode = 'large';
    } else if (width >= minWidthForMediumLayout + hysteresis) {
      // 如果当前是大屏模式，需要更宽的阈值才能切换到中屏
      newLayoutMode = (this.cachedLayoutMode === 'large' && width >= minWidthForLargeLayout - hysteresis) ?
        'large' : 'medium';
    } else if (width >= minWidthForSmallLayout + hysteresis) {
      // 如果当前是中屏模式，需要更宽的阈值才能切换到小屏
      newLayoutMode = (this.cachedLayoutMode === 'medium' && width >= minWidthForMediumLayout - hysteresis) ?
        'medium' : 'small';
    } else {
      // 如果当前是小屏模式，需要更窄的阈值才能切换到超小屏
      newLayoutMode = (this.cachedLayoutMode === 'small' && width >= minWidthForSmallLayout - hysteresis) ?
        'small' : 'xsmall';
    }
    
    // 只有当布局模式真正改变时才更新（带缓存验证）
    if (newLayoutMode !== this.cachedLayoutMode) {
      this.layoutMode = newLayoutMode;
      this.cachedLayoutMode = newLayoutMode;
      this.clearCache(); // 清除缓存，确保下次获取新值
      console.debug(`[RatingPanel LayoutMode] Screen width: ${width}px, Mode: ${this.layoutMode}`);
    }
  }

  @Builder
  buildResponsiveLayout() {
    if (this.layoutMode === 'xsmall') {
      this.buildXSmallLayout();
    } else if (this.layoutMode === 'small') {
      this.buildSmallLayout();
    } else if (this.layoutMode === 'medium') {
      this.buildMediumLayout();
    } else {
      this.buildLargeLayout();
    }
  }

  @Builder
  buildLargeLayout() {
    // 大屏布局：完整的评分面板
    Column() {
      this.buildProgressRing()
      this.buildScoreText()
      this.buildRatingLabel()
    }
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_MD)
    .width(180)
    .height(200)
  }

  @Builder
  buildMediumLayout() {
    // 中屏布局：稍微紧凑的布局
    Column() {
      this.buildProgressRing()
      this.buildScoreText()
      this.buildRatingLabel()
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
    // 小屏布局：更紧凑的布局
    Column() {
      this.buildProgressRing()
      this.buildScoreText()
      this.buildRatingLabel()
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
    // 超小屏布局：最紧凑的布局
    Column() {
      this.buildProgressRing()
      this.buildScoreText()
      this.buildRatingLabel()
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
    .margin({ bottom: DesignConstants.SPACING_SM })
  }

  @Builder
  buildScoreText() {
    Text(`${this.score}`)
      .fontSize(this.getScoreFontSize())
      .fontWeight(FontWeight.Bold)
      .fontColor(this.getRatingLevelInfo().color)
      .margin({ bottom: DesignConstants.SPACING_XS })
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
        case 'large': this.cachedRingSize = DesignConstants.RATING_PANEL.RING_SIZE_LARGE; break;
        case 'medium': this.cachedRingSize = DesignConstants.RATING_PANEL.RING_SIZE_MEDIUM; break;
        case 'small': this.cachedRingSize = DesignConstants.RATING_PANEL.RING_SIZE_SMALL; break;
        case 'xsmall': this.cachedRingSize = DesignConstants.RATING_PANEL.RING_SIZE_XSMALL; break;
        default: this.cachedRingSize = DesignConstants.RATING_PANEL.RING_SIZE_LARGE;
      }
    }
    return this.cachedRingSize;
  }

  // 根据布局模式获取环形宽度（使用缓存机制）
  private getStrokeWidth(): number {
    if (!this.cachedStrokeWidth) {
      switch (this.layoutMode) {
        case 'large': this.cachedStrokeWidth = DesignConstants.RATING_PANEL.STROKE_WIDTH_LARGE; break;
        case 'medium': this.cachedStrokeWidth = DesignConstants.RATING_PANEL.STROKE_WIDTH_MEDIUM; break;
        case 'small': this.cachedStrokeWidth = DesignConstants.RATING_PANEL.STROKE_WIDTH_SMALL; break;
        case 'xsmall': this.cachedStrokeWidth = DesignConstants.RATING_PANEL.STROKE_WIDTH_XSMALL; break;
        default: this.cachedStrokeWidth = DesignConstants.RATING_PANEL.STROKE_WIDTH_LARGE;
      }
    }
    return this.cachedStrokeWidth;
  }

  // 根据布局模式获取分数字体大小（使用缓存机制）
  private getScoreFontSize(): number {
    if (!this.cachedScoreFontSize) {
      switch (this.layoutMode) {
        case 'large': this.cachedScoreFontSize = DesignConstants.FONT_SIZE_3XL; break;
        case 'medium': this.cachedScoreFontSize = DesignConstants.FONT_SIZE_2XL; break;
        case 'small': this.cachedScoreFontSize = DesignConstants.FONT_SIZE_XL; break;
        case 'xsmall': this.cachedScoreFontSize = DesignConstants.FONT_SIZE_LG; break;
        default: this.cachedScoreFontSize = DesignConstants.FONT_SIZE_3XL;
      }
    }
    return this.cachedScoreFontSize;
  }

  // 根据布局模式获取标签字体大小（使用缓存机制）
  private getLabelFontSize(): number {
    if (!this.cachedLabelFontSize) {
      switch (this.layoutMode) {
        case 'large': this.cachedLabelFontSize = DesignConstants.FONT_SIZE_MD; break;
        case 'medium': this.cachedLabelFontSize = DesignConstants.FONT_SIZE_SM; break;
        case 'small': this.cachedLabelFontSize = DesignConstants.FONT_SIZE_SM; break;
        case 'xsmall': this.cachedLabelFontSize = DesignConstants.FONT_SIZE_XS; break;
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
    .onAreaChange((oldValue: Area, newValue: Area) => {
      // 添加防抖机制，避免频繁触发布局更新
      const currentTime = Date.now();
      if (currentTime - this.lastLayoutUpdateTime > 300) { // 300ms防抖
        this.updateLayoutMode(Number(newValue.width));
        this.lastLayoutUpdateTime = currentTime;
      }
    })
  }
}