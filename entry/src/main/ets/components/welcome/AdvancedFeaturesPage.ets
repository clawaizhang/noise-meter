import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';

// 功能卡片接口定义
interface FeatureCard {
  icon: Resource;
  title: string;
  description: string;
}

@ComponentV2
export struct AdvancedFeaturesPage {
  @Param @Require onComplete: () => void;
  @Param @Require onPrev: () => void;
  @Local private contentOpacity: number = 0.8;
  @Local private titleOpacity: number = 0;
  @Local private featuresOpacity: number = 0;
  @Local private buttonOpacity: number = 0;
  @Local private buttonScale: number = 1.0;
  @Local private cardScales: number[] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0];
  @Local private useNowButtonScale: number = 0.8;
  @Local private useNowButtonOpacity: number = 0;
  @Local private featureIconScale: number = 1.0;
  @Local private featureIconRotation: number = 0;
  // 功能卡片数据
  private readonly features: FeatureCard[] = [
    { icon: $r('app.media.ic_stats'), title: '频谱分析', description: '多频段可视化分析' },
    { icon: $r('app.media.ic_weighting'), title: '计权模式', description: 'A/C/Z专业计权' },
    { icon: $r('app.media.ic_alarm'), title: '智能警报', description: '阈值警报提醒' },
    { icon: $r('app.media.ic_document_edit'), title: '历史记录', description: '数据追踪分析' },
    { icon: $r('app.media.ic_time_weighting'), title: '时段调度', description: '智能时段阈值' },
    { icon: $r('app.media.ic_info'), title: '专业报告', description: '数据分析报告' }
  ];

  aboutToAppear(): void {
    this.startEntranceAnimation();
    this.startFeatureAnimation();
  }

  aboutToDisappear(): void {
    // 移除频谱动画相关代码
  }

  private startFeatureAnimation(): void {
    // 功能图标脉动动画
    animateTo({
      duration: 2000,
      curve: Curve.EaseInOut,
      iterations: -1, // 无限循环
      playMode: PlayMode.Alternate
    }, () => {
      this.featureIconScale = 1.1;
    });

    // 功能图标轻微旋转动画
    animateTo({
      duration: 8000,
      curve: Curve.Linear,
      iterations: -1,
      playMode: PlayMode.AlternateReverse
    }, () => {
      this.featureIconRotation = 5;
    });
  }

  private startEntranceAnimation(): void {
    // 页面整体渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.contentOpacity = 1;
      });
    }, 100);

    // 标题渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.titleOpacity = 1;
      });
    }, 300);

    // 功能卡片渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.featuresOpacity = 1;
      });
    }, 600);

    // 按钮渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.buttonOpacity = 1;
      });
    }, 900);

    // 立即使用按钮渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.useNowButtonScale = 1.0;
        this.useNowButtonOpacity = 1;
      });
    }, 1200);
  }

  // 移除所有频谱图相关的方法


  private handleCardHover(isHover: boolean, index: number): void {
    animateTo({
      duration: DesignConstants.ANIMATION_DURATION_XS,
      curve: Curve.EaseOut
    }, () => {
      this.cardScales[index] = isHover ? 1.05 : 1.0;
    });
  }

  build() {
    Column({ space: DesignConstants.SPACING_XL }) {
      // 功能展示区域
      this.buildFeatureDisplay()

      // 标题区域
      this.buildTitle()

      // 功能卡片网格
      this.buildFeatureGrid()

      // 立即使用按钮
      this.buildUseNowButton()
    }
    .width('100%')
    .height('100%')
    .padding(DesignConstants.SPACING_LG)
    .justifyContent(FlexAlign.Center) // 垂直居中
    .opacity(this.contentOpacity)
  }

  @Builder
  private buildFeatureDisplay() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 动画功能图标 - 纯视觉元素，无文字描述
      Stack({ alignContent: Alignment.Center }) {
        // 品牌色半透明背景光晕效果
        Circle({ width: 100, height: 100 })
          .fill($r('sys.color.brand'))
          .opacity(0.1)
          .scale({ x: this.featureIconScale, y: this.featureIconScale })

        // 功能图标
        Image($r('app.media.ic_audio_analysis'))
          .width(80)
          .height(80)
          .fillColor($r('sys.color.brand'))
          .scale({ x: this.featureIconScale, y: this.featureIconScale })
          .rotate({ angle: this.featureIconRotation })
      } .onClick(() => {
        // 直接完成引导，进入主应用
        Throttle.click(() => {
          this.onComplete();
        })
      })
    }
    .alignItems(HorizontalAlign.Center)
    .padding(DesignConstants.SPACING_XL)
  }

  @Builder
  private buildTitle() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('专业分析，精准守护')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_emphasize'))
        .textAlign(TextAlign.Center)
        .opacity(this.titleOpacity)

      Text('可视化音频分析，智能噪音防护')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .opacity(this.titleOpacity)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildFeatureGrid() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 第一行功能卡片
      Row({ space: DesignConstants.SPACING_MD }) {
        ForEach(this.features.slice(0, 3), (item: FeatureCard, index: number) => {
          this.buildFeatureCard(item, index)
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      // 第二行功能卡片
      Row({ space: DesignConstants.SPACING_MD }) {
        ForEach(this.features.slice(3, 6), (item: FeatureCard, index: number) => {
          this.buildFeatureCard(item, index + 3)
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .margin({ top: DesignConstants.SPACING_XL })
    .opacity(this.featuresOpacity)
  }

  @Builder
  private buildFeatureCard(item: FeatureCard, index: number) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Image(item.icon)
        .fillColor($r('sys.color.brand'))
        .width(DesignConstants.ICON_SIZE_MD)

      Text(item.title)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)

      Text(item.description)
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .maxLines(2)
    }
    .width('30%')
    .height(80)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .shadow(DesignConstants.SHADOW_SM)
    .scale({ x: this.cardScales[index], y: this.cardScales[index] })
    .onHover((isHover: boolean) => this.handleCardHover(isHover, index))
  }

  // 构建立即使用按钮
  @Builder
  private buildUseNowButton() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Button('立即使用', { type: ButtonType.Capsule })
        .width('80%')
        .height(56)
        .backgroundColor($r('sys.color.interactive_active'))
        .fontColor($r('sys.color.font_on_primary'))
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .borderRadius(28)
        .shadow(DesignConstants.SHADOW_MD)
        .scale({ x: this.useNowButtonScale, y: this.useNowButtonScale })
        .opacity(this.useNowButtonOpacity)
        .onClick(() => {
          // 直接完成引导，进入主应用
          Throttle.click(() => {
            this.onComplete();
          })
        })
        .margin({ top: DesignConstants.SPACING_2XL })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}