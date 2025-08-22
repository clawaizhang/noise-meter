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

  // 更新布局模式（带滞后阈值防止频繁切换和缓存优化）
  private updateLayoutMode(width: number) {
    // 计算各布局模式的最小宽度要求
    const minWidthForLargeLayout = 300; // 大屏布局最小宽度
    const minWidthForMediumLayout = 250; // 中屏布局最小宽度
    const minWidthForSmallLayout = 200; // 小屏布局最小宽度
    
    // 添加滞后阈值（15px），防止在边界值附近频繁切换
    const hysteresis = 15;
    
    let newLayoutMode: string;
    
    if (width >= minWidthForLargeLayout + hysteresis) {
      newLayoutMode = 'large';
    } else if (width >= minWidthForMediumLayout + hysteresis) {
      // 如果当前是大屏模式，需要更宽的阈值才能切换到中屏
      newLayoutMode = (this.cachedLayoutMode === 'large' && width >= minWidthForLargeLayout - hysteresis) ?
        'large' : 'medium';
    } else if (width >= minWidthForSmallLayout + hysteresis) {
      // 如果当前是中屏模式，需要更宽的阈值才能切换到中屏
      newLayoutMode = (this.cachedLayoutMode === 'medium' && width >= minWidthForMediumLayout - hysteresis) ?
        'medium' : 'small';
    } else {
      // 如果当前是小屏模式，需要更窄的阈值才能切换到超小屏
      newLayoutMode = (this.cachedLayoutMode === 'small' && width >= minWidthForSmallLayout - hysteresis) ?
        'small' : 'xsmall';
    }
    
    // 只有当布局模式真正改变时才更新
    if (newLayoutMode !== this.cachedLayoutMode) {
      this.layoutMode = newLayoutMode;
      this.cachedLayoutMode = newLayoutMode;
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

  // 根据布局模式获取环形大小
  private getRingSize(): number {
    switch (this.layoutMode) {
      case 'large': return 80;
      case 'medium': return 70;
      case 'small': return 60;
      case 'xsmall': return 50;
      default: return 80;
    }
  }

  // 根据布局模式获取环形宽度
  private getStrokeWidth(): number {
    switch (this.layoutMode) {
      case 'large': return 8;
      case 'medium': return 7;
      case 'small': return 6;
      case 'xsmall': return 5;
      default: return 8;
    }
  }

  // 根据布局模式获取分数字体大小
  private getScoreFontSize(): number {
    switch (this.layoutMode) {
      case 'large': return DesignConstants.FONT_SIZE_3XL;
      case 'medium': return DesignConstants.FONT_SIZE_2XL;
      case 'small': return DesignConstants.FONT_SIZE_XL;
      case 'xsmall': return DesignConstants.FONT_SIZE_LG;
      default: return DesignConstants.FONT_SIZE_3XL;
    }
  }

  // 根据布局模式获取标签字体大小
  private getLabelFontSize(): number {
    switch (this.layoutMode) {
      case 'large': return DesignConstants.FONT_SIZE_MD;
      case 'medium': return DesignConstants.FONT_SIZE_SM;
      case 'small': return DesignConstants.FONT_SIZE_SM;
      case 'xsmall': return DesignConstants.FONT_SIZE_XS;
      default: return DesignConstants.FONT_SIZE_MD;
    }
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