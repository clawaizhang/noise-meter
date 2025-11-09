import { WelcomePage } from './WelcomePage';
import { RealTimeDetectionPage } from './RealTimeDetectionPage';
import { AdvancedFeaturesPage } from './AdvancedFeaturesPage';
import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct WelcomeGuide {
  @Event onComplete: () => void;
  @Event onCancel: () => void;
  
  @Local private currentPage: number = 0;
  private totalPages: number = 3;
  
  // 滑动指示器动画状态
  @Local private arrowOffset: number = 0;
  @Local private arrowOpacity: number = 1;
  @Local private arrowScale: number = 1.0;
  
  // 页面切换动画状态
  @Local private pageTransitionOffset: number = 0;
  @Local private isAnimating: boolean = false;

  aboutToAppear(): void {
    this.startArrowAnimation();
  }

  // 启动箭头跳动动画 - 增强浮动效果
  private startArrowAnimation(): void {
    animateTo({
      duration: 2000,
      curve: Curve.EaseInOut,
      iterations: -1,
      playMode: PlayMode.Alternate
    }, () => {
      this.arrowOffset = 12;  // 增加到12px浮动幅度
      this.arrowOpacity = 0.7; // 添加透明度变化
      this.arrowScale = 1.1;  // 添加轻微缩放效果
    });
  }

  // 页面切换方法 - 带动画效果
  private goToNextPage(): void {
    if (this.currentPage < this.totalPages - 1 && !this.isAnimating) {
      this.animateToNextPage();
    }
  }

  private goToPrevPage(): void {
    if (this.currentPage > 0 && !this.isAnimating) {
      this.animateToPrevPage();
    }
  }

  // 前进切换动画 - 新页从下方滑入
  private animateToNextPage(): void {
    this.isAnimating = true;
    
    // 当前页向上滑出
    animateTo({
      duration: 300,
      curve: Curve.EaseOut
    }, () => {
      this.pageTransitionOffset = -100;
    });
    
    // 延迟后切换到新页面并从下方滑入
    setTimeout(() => {
      this.currentPage++;
      this.pageTransitionOffset = 100; // 新页从下方开始
      
      animateTo({
        duration: 300,
        curve: Curve.EaseOut
      }, () => {
        this.pageTransitionOffset = 0;
        this.isAnimating = false;
      });
    }, 150);
  }

  // 后退切换动画 - 新页从上方滑入
  private animateToPrevPage(): void {
    this.isAnimating = true;
    
    // 当前页向下滑出
    animateTo({
      duration: 300,
      curve: Curve.EaseOut
    }, () => {
      this.pageTransitionOffset = 100;
    });
    
    // 延迟后切换到新页面并从上方滑入
    setTimeout(() => {
      this.currentPage--;
      this.pageTransitionOffset = -100; // 新页从上方开始
      
      animateTo({
        duration: 300,
        curve: Curve.EaseOut
      }, () => {
        this.pageTransitionOffset = 0;
        this.isAnimating = false;
      });
    }, 150);
  }

  private handleComplete(): void {
    if (this.currentPage === this.totalPages - 1) {
      // 用户完成欢迎引导，进入主应用
      this.onComplete();
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 页面内容区域
      Column({ space: 0 }) {
        // 页面内容
        Column() {
          this.buildCurrentPage()
        }
          .layoutWeight(1)
        
        // 底部滑动指示器（向下箭头）
        if (this.currentPage < this.totalPages - 1) {
          this.buildBottomIndicator()
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_primary'))
    .gesture(
      PanGesture({ distance: 50 })
        .onActionEnd((event: GestureEvent) => {
          if (event.offsetY < -50) {
            // 向上滑动 - 下一页
            this.goToNextPage();
          } else if (event.offsetY > 50) {
            // 向下滑动 - 上一页
            this.goToPrevPage();
          }
        })
    )
  }

  @Builder
  private buildCurrentPage() {
    if (this.currentPage == 0) {
       WelcomePage({
        onNext: () => this.goToNextPage()
      })
    } else if (this.currentPage == 1) {
      RealTimeDetectionPage({
        onNext: () => this.goToNextPage(),
        onPrev: () => this.goToPrevPage()
      })
    } else if (this.currentPage == 2) {
      AdvancedFeaturesPage({
        onComplete: () => this.handleComplete(),
        onPrev: () => this.goToPrevPage()
      })
    }
  }

  // 构建底部指示器（向下箭头）- 优化大小和浮动效果
  @Builder
  private buildBottomIndicator() {
    Column({ space: DesignConstants.SPACING_SM }) {
      
      // 增大箭头尺寸到36x36，增强浮动效果
      Image($r('app.media.ic_arrow_right'))
        .width(36)
        .height(36)
        .fillColor($r('app.color.font_secondary'))
        .rotate({ angle: 90 })
        .translate({ y: this.arrowOffset })
        .opacity(this.arrowOpacity)
        .scale({ x: this.arrowScale, y: this.arrowScale })
        .shadow(DesignConstants.SHADOW_SM)
    }
    .width('100%')
    .padding({
      top: DesignConstants.SPACING_MD,
      bottom: DesignConstants.SPACING_LG
    })
    .alignItems(HorizontalAlign.Center)
  }
}

// Builder版本
@Builder
export function WelcomeGuideBuilder(params: WelcomeGuideParams) {
  WelcomeGuide({
    onComplete: params.onComplete,
    onCancel: params.onCancel
  })
}

export interface WelcomeGuideParams {
  onComplete: () => void;
  onCancel: () => void;
}