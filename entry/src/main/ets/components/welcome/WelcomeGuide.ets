import { WelcomePage } from './WelcomePage';
import { RealTimeDetectionPage } from './RealTimeDetectionPage';
import { AdvancedFeaturesPage } from './AdvancedFeaturesPage';
import { PrivacyPolicyPage } from './PrivacyPolicyPage';
import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct WelcomeGuide {
  @Event onComplete: () => void;
  @Event onCancel: () => void;
  
  @Local private currentPage: number = 0;
  private totalPages: number = 4;
  @Local private privacyAgreed: boolean = false;
  
  // 滑动指示器动画状态
  @Local private arrowOffset: number = 0;

  aboutToAppear(): void {
    this.startArrowAnimation();
  }

  // 启动箭头跳动动画
  private startArrowAnimation(): void {
    animateTo({
      duration: 1500,
      curve: Curve.EaseInOut,
      iterations: -1,
      playMode: PlayMode.Alternate
    }, () => {
      this.arrowOffset = 8;  // 增加抖动幅度
    });
  }

  // 页面切换方法
  private goToNextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
    } else {
      this.handleComplete();
    }
  }

  private goToPrevPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
    }
  }

  private handleComplete(): void {
    if (this.currentPage === this.totalPages - 1 && this.privacyAgreed) {
      // 用户同意隐私政策，设置隐私政策状态并完成引导
      this.onComplete();
    }
  }

  private setPrivacyAgreed(agreed: boolean): void {
    this.privacyAgreed = agreed;
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
    .backgroundColor($r('sys.color.background_primary'))
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
        onNext: () => this.goToNextPage(),
        onPrev: () => this.goToPrevPage()
      })
    } else if (this.currentPage == 3) {
      PrivacyPolicyPage({
        onAgree: () => {
          this.setPrivacyAgreed(true);
          this.handleComplete();
        },
        onPrev: () => this.goToPrevPage(),
      })
    }
  }

  // 构建底部指示器（向下箭头）
  @Builder
  private buildBottomIndicator() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 使用右箭头旋转90度作为向下箭头
      Image($r('app.media.ic_arrow_right'))
        .width(24)
        .height(24)
        .fillColor($r('sys.color.font_secondary'))
        .rotate({ angle: 90 })
        .translate({ y: this.arrowOffset })
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