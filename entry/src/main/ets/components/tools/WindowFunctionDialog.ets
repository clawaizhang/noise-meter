import { WindowType } from '../../common/WindowType';
import { DesignConstants } from '../../constants/DesignConstants';
import { DialogHub, InfSheet } from '@hadss/dialoghub';

/**
 * 窗函数设置对话框参数
 */
export interface WindowFunctionDialogParams {
  currentWindowType: WindowType;
  onSettingsApplied: (windowType: WindowType) => void;
  onClose: () => void;
}

/**
 * 窗函数信息
 */
interface WindowFunctionInfo {
  type: WindowType;
  displayName: string;
  description: string;
  characteristics: string;
}

/**
 * 窗函数设置对话框构建器
 */
@ComponentV2
export struct WindowFunctionDialogBuilder {
  @Param @Require currentWindowType: WindowType;
  @Event onSettingsApplied: (windowType: WindowType) => void;
  @Event onClose: () => void;
  @Local selectedWindowType: WindowType = WindowType.HANNING;

  aboutToAppear(): void {
    this.selectedWindowType = this.currentWindowType;
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题
      Row() {
        Text('窗函数设置')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.font_primary'))
          .textAlign(TextAlign.Start)

        Blank()

        // 关闭按钮
        Image($r('app.media.ic_close'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.icon_secondary'))
          .onClick(() => {
            this.onClose();
          })
      }
      .width('100%')
      .padding({ bottom: DesignConstants.SPACING_MD })

      // 当前选择显示
      Row() {
        Text('当前选择: ')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('app.color.font_secondary'))

        Text(this.getWindowDisplayName(this.selectedWindowType))
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.font_primary'))
      }
      .width('100%')
      .padding(DesignConstants.SPACING_SM)
      .backgroundColor($r('app.color.comp_background_tertiary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .margin({ bottom: DesignConstants.SPACING_MD })

      // 窗函数列表
      Scroll() {
        Column({ space: DesignConstants.SPACING_SM }) {
          ForEach(this.getWindowFunctionList(), (windowInfo: WindowFunctionInfo) => {
            this.buildWindowFunctionCard(windowInfo)
          })
        }
        .width('100%')
      }
      .width('100%')
      .height('60%')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // 底部按钮
      Row({ space: DesignConstants.SPACING_MD }) {
        Button('取消')
          .width('48%')
          .height(48)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('app.color.font_primary'))
          .backgroundColor($r('app.color.comp_background_secondary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            this.onClose();
          })

        Button('应用')
          .width('48%')
          .height(48)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('app.color.font_primary'))
          .backgroundColor($r('app.color.confirm'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            this.onSettingsApplied(this.selectedWindowType);
            this.onClose();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ top: DesignConstants.SPACING_MD })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius({ topLeft: DesignConstants.BORDER_RADIUS_XL, topRight: DesignConstants.BORDER_RADIUS_XL })
  }

  @Builder
  private buildWindowFunctionCard(windowInfo: WindowFunctionInfo) {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题行
      Row() {
        Text(windowInfo.displayName)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.font_primary'))

        Blank()

        // 选择指示器
        Radio({ value: windowInfo.type, group: 'windowType' })
          .checked(this.selectedWindowType === windowInfo.type)
          .onChange((isChecked: boolean) => {
            if (isChecked) {
              this.selectedWindowType = windowInfo.type;
            }
          })
      }
      .width('100%')

      // 描述
      Text(windowInfo.description)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('app.color.font_secondary'))
        .width('100%')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 特性
      Text(windowInfo.characteristics)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('app.color.font_secondary'))
        .width('100%')
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor(this.selectedWindowType === windowInfo.type ?
      $r('app.color.comp_background_emphasize') : $r('app.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .shadow(DesignConstants.SHADOW_SM)
    .onClick(() => {
      this.selectedWindowType = windowInfo.type;
    })
  }

  /**
   * 获取窗函数列表
   */
  private getWindowFunctionList(): WindowFunctionInfo[] {
    return [
      {
        type: WindowType.HANNING,
        displayName: '汉宁窗 (Hanning)',
        description: '最常用的窗函数之一，具有良好的频谱特性和较低的旁瓣',
        characteristics: '主瓣宽度较宽，旁瓣衰减-31dB，适用于一般频谱分析'
      },
      {
        type: WindowType.BLACKMAN,
        displayName: '布莱克曼窗 (Blackman)',
        description: '具有更好的旁瓣抑制性能，但主瓣更宽',
        characteristics: '主瓣宽度宽，旁瓣衰减-58dB，适用于需要高旁瓣抑制的场景'
      },
      {
        type: WindowType.HAMMING,
        displayName: '汉明窗 (Hamming)',
        description: '优化的余弦窗，具有良好的旁瓣特性',
        characteristics: '主瓣宽度中等，旁瓣衰减-42dB，旁瓣峰值较低'
      },
      {
        type: WindowType.BARTLETT,
        displayName: '巴特利特窗 (Bartlett)',
        description: '三角窗，简单且计算效率高',
        characteristics: '主瓣宽度中等，旁瓣衰减-26dB，计算简单'
      },
      {
        type: WindowType.KAISER,
        displayName: '凯泽窗 (Kaiser)',
        description: '可调节的窗函数，通过β参数控制旁瓣衰减',
        characteristics: '主瓣宽度和旁瓣衰减可调，β=6.0时旁瓣衰减-44dB'
      },
      {
        type: WindowType.FLATTOP,
        displayName: '平顶窗 (Flat Top)',
        description: '专门用于幅度测量的窗函数',
        characteristics: '主瓣很宽但顶部平坦，旁瓣衰减-44dB，适合精确幅度测量'
      },
      {
        type: WindowType.TRIANGULAR,
        displayName: '三角窗 (Triangular)',
        description: '简单的三角形状窗函数',
        characteristics: '主瓣宽度中等，旁瓣衰减-26dB，与Bartlett窗类似'
      },
      {
        type: WindowType.WELCH,
        displayName: '韦尔奇窗 (Welch)',
        description: '抛物线形状的窗函数',
        characteristics: '主瓣宽度中等，旁瓣衰减-31dB，端点平滑过渡到零'
      },
      {
        type: WindowType.SINE,
        displayName: '正弦窗 (Sine)',
        description: '半周期正弦波窗函数',
        characteristics: '主瓣宽度较宽，旁瓣衰减-23dB，适用于某些特殊应用'
      },
      {
        type: WindowType.GAUSSIAN,
        displayName: '高斯窗 (Gaussian)',
        description: '基于高斯函数的窗函数',
        characteristics: '主瓣宽度可调，旁瓣衰减-44dB，时频局部化特性好'
      },
      {
        type: WindowType.TUKEY,
        displayName: '图基窗 (Tukey)',
        description: '余弦锥度窗，可调节平坦部分宽度',
        characteristics: '主瓣宽度可调，旁瓣衰减-15dB，α=0.5时性能均衡'
      },
      {
        type: WindowType.CHEBYSHEV,
        displayName: '切比雪夫窗 (Chebyshev)',
        description: '等波纹旁瓣的窗函数',
        characteristics: '所有旁瓣等高，衰减60dB，适用于需要均匀旁瓣的场景'
      }
    ];
  }

  /**
   * 获取窗函数显示名称
   */
  private getWindowDisplayName(windowType: WindowType): string {
    const windowInfo = this.getWindowFunctionList().find(info => info.type === windowType);
    return windowInfo?.displayName || windowType;
  }
}

/**
 * 显示窗函数设置对话框
 */
@Builder
export function WindowFunctionDialogContent(params: WindowFunctionDialogParams) {
  WindowFunctionDialogBuilder({
    currentWindowType: params.currentWindowType,
    onSettingsApplied: params.onSettingsApplied,
    onClose: params.onClose
  })
}