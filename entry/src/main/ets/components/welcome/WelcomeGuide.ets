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
  private totalPagesArray: string[] = ['welcome', 'realTimeDetection', 'advancedFeatures', 'privacyPolicy'];
  @Local private privacyAgreed: boolean = false;

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

  private skipToEnd(): void {
    this.currentPage = this.totalPages - 1;
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
    Column({ space: 0 }) {
      // 页面内容区域
      Stack({ alignContent: Alignment.TopStart }) {
        this.buildCurrentPage()
      }
      .width('100%')
      .height('100%')

      // 页面指示器和操作按钮
      this.buildFooter()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
  }

  @Builder
  private buildCurrentPage() {
    if (this.currentPage == 0) {
       WelcomePage({
        onNext: () => this.goToNextPage(),
        onSkip: () => this.skipToEnd()
      })
    } else if (this.currentPage == 1) {
      RealTimeDetectionPage({
        onNext: () => this.goToNextPage(),
        onPrev: () => this.goToPrevPage(),
        onSkip: () => this.skipToEnd()
      })
    } else if (this.currentPage == 2) {
      AdvancedFeaturesPage({
        onNext: () => this.goToNextPage(),
        onPrev: () => this.goToPrevPage(),
        onSkip: () => this.skipToEnd()
      })
    } else if (this.currentPage == 3) {
      PrivacyPolicyPage({
        onAgree: () => {
          this.setPrivacyAgreed(true);
          this.handleComplete();
        },
        onSkip: () => this.onCancel(), // 现在对应"暂不使用"按钮
        onPrev: () => this.goToPrevPage(),
      })
    }

  }

  @Builder
  private buildFooter() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 页面指示器
      Row({ space: DesignConstants.SPACING_SM }) {
        ForEach(this.totalPagesArray, (index: number) => {
          Circle({ width: 8, height: 8 })
            .backgroundColor(index === this.currentPage ?
              $r('sys.color.interactive_active') :
              $r('sys.color.comp_background_secondary'))
            .opacity(index === this.currentPage ? 1 : 0.5)
        })
      }
      .justifyContent(FlexAlign.Center)

      // 跳过按钮（所有页面都显示）
      Text('跳过')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .onClick(() => this.skipToEnd())
    }
    .width('100%')
    .padding({
      bottom: DesignConstants.SPACING_XL,
      left: DesignConstants.SPACING_LG,
      right: DesignConstants.SPACING_LG
    })
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