/**
 * 实时预览面板组件
 * 用于显示时间计权模式的实时预览信息，包括参数对比和响应特性
 */

import { AudioAnalysisMode } from '../../common/AudioConfig';
import { TimeWeightingConstants } from '../../constants/TimeWeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct PreviewPanel {
  @Param @Require currentMode: AudioAnalysisMode; // 当前模式
  @Param @Require selectedMode: AudioAnalysisMode; // 选中的模式
  @Local previewData: number[] = []; // 预览数据（用于模拟响应曲线）

  aboutToAppear() {
    // 初始化预览数据
    this.generatePreviewData();
  }

  @Monitor('selectedMode')
  selectedModeChange(monitor: IMonitor) {
    // 模式变化时更新预览数据
    this.generatePreviewData();
  }

  // 生成预览数据（模拟响应曲线）
  private generatePreviewData() {
    const data: number[] = [];
    const pointCount = 50;

    // 根据模式生成不同的响应曲线
    for (let i = 0; i < pointCount; i++) {
      let value: number;
      const x = i / pointCount;

      switch (this.selectedMode) {
        case AudioAnalysisMode.FAST_TIME_WEIGHTING:
          // 快速模式：快速响应，中等衰减
          value = Math.exp(-x * 3) * Math.sin(x * 20);
          break;
        case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
          // 慢速模式：缓慢响应，平滑衰减
          value = Math.exp(-x * 1) * Math.sin(x * 10);
          break;
        case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
          // 脉冲模式：快速上升，缓慢衰减
          value = Math.exp(-x * 0.5) * (x < 0.1 ? 1 : Math.sin(x * 30));
          break;
        default:
          value = 0;
      }

      data.push(value);
    }

    this.previewData = data;
  }

  // 构建响应曲线预览
  @Builder
  private buildResponseCurve() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题
      Text('响应特性预览')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 曲线图容器
      Row() {
        // Y轴标签
        Column({ space: 0 }) {
          Text('1.0')
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_tertiary'))
          Text('0.5')
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_tertiary'))
            .layoutWeight(1)
          Text('0.0')
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_tertiary'))
        }
        .height(120)
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ right: DesignConstants.SPACING_XS })

        // 曲线图
        Column() {
          // 曲线绘制区域
          Stack() {
            // 背景网格
            ForEach(Array.from({ length: 5 }), (index: number) => {
              Line()
                .width('100%')
                .height(1)
                .strokeWidth(0.5)
                .stroke($r('sys.color.comp_border_color'))
                .opacity(0.3)
                .offset({ y: index * 30 })
            })

            // 响应曲线
            Path()
              .width('100%')
              .height('100%')
              .commands(this.buildCurvePath())
              .stroke($r('sys.color.font_primary'))
              .strokeWidth(2)
              .fill('')
          }
          .width('100%')
          .height(120)
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_SM)

          // X轴标签
          Row() {
            Text('0ms')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_tertiary'))
            Text('时间')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_tertiary'))
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Text('500ms')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_tertiary'))
          }
          .width('100%')
          .margin({ top: DesignConstants.SPACING_XS })

        }
        .layoutWeight(1)

      }
      .width('100%')

      // 曲线说明
      Text(this.getCurveDescription())
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
        .margin({ top: DesignConstants.SPACING_SM })

    }
    .width('100%')
  }

  // 构建曲线路径
  private buildCurvePath(): string {
    if (this.previewData.length === 0) {
      return '';
    }

    const width = 280; // 假设宽度
    const height = 120;
    const step = width / (this.previewData.length - 1);

    let path = `M0 ${height / 2 - this.previewData[0] * height / 2}`;

    for (let i = 1; i < this.previewData.length; i++) {
      const x = i * step;
      const y = height / 2 - this.previewData[i] * height / 2;
      path += ` L${x} ${y}`;
    }

    return path;
  }

  // 获取曲线描述
  private getCurveDescription(): string {
    switch (this.selectedMode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        return '快速响应特性：对瞬时信号有良好的跟踪能力，适合快速变化的噪声测量';
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        return '平滑响应特性：减少瞬时波动，提供稳定的测量结果，适合稳态噪声';
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        return '脉冲响应特性：快速上升缓慢下降，专门优化脉冲信号的检测';
      default:
        return '';
    }
  }

  // 构建模式对比信息
  @Builder
  private buildModeComparison() {

    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题
      Text('模式对比')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      if (this.currentMode === this.selectedMode) {
        Text('当前已选择此模式')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.confirm'))
          .alignSelf(ItemAlign.Start)
      } else {
        Row({ space: DesignConstants.SPACING_SM }) {
          Text('当前:')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))

          Text(TimeWeightingConstants.MODE_DISPLAY_NAMES[this.currentMode])
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Medium)

          Image($r('sys.media.ohos_ic_public_arrow_right'))
            .width(DesignConstants.ICON_SIZE_SM)
            .height(DesignConstants.ICON_SIZE_SM)
            .fillColor($r('sys.color.font_secondary'))
            .margin({ left: DesignConstants.SPACING_XS, right: DesignConstants.SPACING_XS })

          Text('选择:')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))

          Text(TimeWeightingConstants.MODE_DISPLAY_NAMES[this.selectedMode])
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Bold)
        }
        .alignSelf(ItemAlign.Start)
      }

    }
    .width('100%')
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 模式对比信息
      this.buildModeComparison()

      // 分隔线
      Divider()
        .strokeWidth(1)
        .color($r('sys.color.comp_border_color'))
        .margin({ top: DesignConstants.SPACING_SM, bottom: DesignConstants.SPACING_SM })

      // 响应曲线预览
      this.buildResponseCurve()

    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }
}