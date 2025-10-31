/**
 * 健康风险显示组件
 * 统一健康影响UI的核心组件，展示健康风险等级和暴露剂量
 */
import { HealthImpactData, HealthRiskLevel, SpecialNoiseType } from "../../models/HealthImpactData";


@ComponentV2
export struct HealthRiskDisplay {
  @Param @Require healthData: HealthImpactData;
  @Local private animationProgress: number = 0;

  aboutToAppear(): void {
    // 初始化动画进度
    this.animationProgress = this.healthData.exposurePercentage;
  }

  aboutToUpdate(): void {
    // 当数据更新时，触发动画
    this.animateProgress(this.healthData.exposurePercentage);
  }

  /**
   * 动画效果：平滑过渡到新的暴露剂量百分比
   */
  private animateProgress(targetPercentage: number): void {
    // 使用ArkTS推荐的动画方式
    animateTo({
      duration: 500,
      curve: Curve.EaseOut
    }, () => {
      this.animationProgress = targetPercentage;
    });
  }

  /**
   * 获取风险等级对应的图标
   */
  private getRiskIcon(): string {
    switch (this.healthData.riskLevel) {
      case HealthRiskLevel.EXCELLENT:
        return '✔️';
      case HealthRiskLevel.GOOD:
        return '👍';
      case HealthRiskLevel.ATTENTION:
        return '⚠️';
      case HealthRiskLevel.WARNING:
        return '🔶';
      case HealthRiskLevel.DANGER:
        return '🔴';
      default:
        return '❓';
    }
  }

  /**
   * 获取风险等级对应的背景颜色
   */
  private getRiskBackgroundColor(): Resource {
    switch (this.healthData.riskLevel) {
      case HealthRiskLevel.EXCELLENT:
        return $r('sys.color.confirm'); // 浅绿色
      case HealthRiskLevel.GOOD:
        return $r('sys.color.background_emphasize'); // 浅蓝色
      case HealthRiskLevel.ATTENTION:
        return $r('sys.color.ohos_id_color_palette9'); // 浅黄色
      case HealthRiskLevel.WARNING:
        return $r('sys.color.alert'); // 浅橙色
      case HealthRiskLevel.DANGER:
        return $r('sys.color.warning'); // 浅红色
      default:
        return $r('sys.color.ohos_id_color_palette1');
    }
  }

  /**
   * 获取特殊噪音图标
   */
  private getSpecialNoiseIcon(): string {
    if (!this.healthData.specialNoiseDetection.isValid()) {
      return '';
    }

    switch (this.healthData.specialNoiseDetection.noiseType) {
      case SpecialNoiseType.IMPULSE:
        return '⚡';
      case SpecialNoiseType.LOW_FREQUENCY:
        return '📳';
      case SpecialNoiseType.COMBINED:
        return '🔊';
      default:
        return '';
    }
  }

  /**
   * 渲染环形进度条
   */
  @Builder
  private renderCircularProgress() {
    Stack({ alignContent: Alignment.Center }) {
      // 背景圆环
      Circle({ width: 120, height: 120 })
        .fill(Color.Transparent)
        .stroke($r('sys.color.ohos_id_color_secondary'))
        .strokeWidth(8)

      // 进度圆环
      Circle({ width: 120, height: 120 })
        .fill(Color.Transparent)
        .stroke(this.healthData.getRiskColor())
        .strokeWidth(8)
        .strokeDashArray([this.animationProgress * 3.77, 377]) // 377 = 2 * π * 60

      // 中心内容
      Column({ space: 4 }) {
        Text(`${Math.round(this.animationProgress)}%`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.healthData.getRiskColor())

        Text('暴露剂量')
          .fontSize(12)
          .fontColor($r('sys.color.ohos_id_color_secondary'))
      }
    }
    .width(120)
    .height(120)
  }

  /**
   * 渲染风险等级卡片
   */
  @Builder
  private renderRiskCard() {
    Column({ space: 12 }) {
      // 风险等级标题行
      Row({ space: 8 }) {
        Text(this.getRiskIcon())
          .fontSize(20)

        Text(this.healthData.getRiskDescription())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.healthData.getRiskColor())

        // 特殊噪音图标（如果有）
        if (this.healthData.specialNoiseDetection.isValid()) {
          Text(this.getSpecialNoiseIcon())
            .fontSize(16)
            .fontColor($r('sys.color.warning'))
        }
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')

      // 健康评分
      Row({ space: 8 }) {
        Text('健康评分:')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_secondary'))

        Text(`${this.healthData.healthScore}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.healthData.getRiskColor())
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')

      // 当前分贝值
      Row({ space: 8 }) {
        Text('当前分贝:')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_secondary'))

        Text(`${this.healthData.currentDecibel.toFixed(1)} dB`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.ohos_id_color_primary'))
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')

      // 特殊噪音信息（如果有）
      if (this.healthData.specialNoiseDetection.isValid()) {
        Row({ space: 8 }) {
          Text('特殊噪音:')
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_secondary'))

          Text(this.healthData.specialNoiseDetection.getTypeDescription())
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.warning'))
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')
      }
    }
    .padding(16)
    .backgroundColor(this.getRiskBackgroundColor())
    .borderRadius(12)
    .width('100%')
  }

  /**
   * 渲染健康建议
   */
  @Builder
  private renderRecommendation() {
    Column({ space: 8 }) {
      Text('健康建议')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.ohos_id_color_primary'))
        .textAlign(TextAlign.Start)
        .width('100%')

      Text(this.healthData.recommendation)
        .fontSize(14)
        .fontColor($r('sys.color.ohos_id_color_secondary'))
        .textAlign(TextAlign.Start)
        .width('100%')
        .lineHeight(20)
    }
    .padding(16)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
    .borderRadius(12)
    .border({
      width: 1,
      color: $r('sys.color.comp_border_color')
    })
    .width('100%')
  }

  build() {
    Column({ space: 16 }) {
      // 主内容区域
      Row({ space: 16 }) {
        // 左侧：环形进度条
        this.renderCircularProgress()

        // 右侧：风险等级卡片
        Column({ space: 8 }) {
          this.renderRiskCard()
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height(140)

      // 健康建议
      this.renderRecommendation()
    }
    .padding(16)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
    .borderRadius(16)
    .border({
      width: 1,
      color: $r('sys.color.comp_border_color')
    })
    .width('100%')
    .height(280)
  }
}