import { WindowType } from '../../common/WindowType';
import { DesignConstants } from '../../constants/DesignConstants';
import { DialogHub, InfSheet } from '@hadss/dialoghub';

/**
 * 窗函数参数设置对话框参数
 */
export interface WindowFunctionParamsDialogParams {
  currentWindowType: WindowType;
  currentKaiserBeta?: number;
  currentGaussianSigma?: number;
  currentTukeyAlpha?: number;
  currentChebyshevAttenuation?: number;
  onSettingsApplied: (windowType: WindowType, kaiserBeta?: number, gaussianSigma?: number, 
    tukeyAlpha?: number, chebyshevAttenuation?: number) => void;
  onClose: () => void;
}

/**
 * 窗函数参数设置对话框构建器
 */
@ComponentV2
export struct WindowFunctionParamsDialogBuilder {
  @Param @Require params: WindowFunctionParamsDialogParams;
  @Local selectedWindowType: WindowType = WindowType.HANNING;
  @Local kaiserBeta: number = 6.0;
  @Local gaussianSigma: number = 0.4;
  @Local tukeyAlpha: number = 0.5;
  @Local chebyshevAttenuation: number = 60.0;
  
  aboutToAppear(): void {
    this.selectedWindowType = this.params.currentWindowType;
    this.kaiserBeta = this.params.currentKaiserBeta || 6.0;
    this.gaussianSigma = this.params.currentGaussianSigma || 0.4;
    this.tukeyAlpha = this.params.currentTukeyAlpha || 0.5;
    this.chebyshevAttenuation = this.params.currentChebyshevAttenuation || 60.0;
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题
      Row() {
        Text('窗函数参数设置')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .textAlign(TextAlign.Start)
        
        Blank()
        
        // 关闭按钮
        Image($r('app.media.ic_close'))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.icon_secondary'))
          .onClick(() => {
            this.params.onClose();
          })
      }
      .width('100%')
      .padding({ bottom: DesignConstants.SPACING_MD })
      
      // 窗函数类型选择
      Column({ space: DesignConstants.SPACING_SM }) {
        Text('窗函数类型')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .width('100%')
          .textAlign(TextAlign.Start)
        
        Row() {
          Text('当前选择: ')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
          
          Text(this.getWindowDisplayName(this.selectedWindowType))
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .padding(DesignConstants.SPACING_SM)
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .margin({ bottom: DesignConstants.SPACING_MD })
      }
      
      // 参数设置区域
      Scroll() {
        Column({ space: DesignConstants.SPACING_MD }) {
          // Kaiser窗参数
          if (this.selectedWindowType === WindowType.KAISER) {
            this.buildKaiserParams()
          }
          
          // Gaussian窗参数
          if (this.selectedWindowType === WindowType.GAUSSIAN) {
            this.buildGaussianParams()
          }
          
          // Tukey窗参数
          if (this.selectedWindowType === WindowType.TUKEY) {
            this.buildTukeyParams()
          }
          
          // Chebyshev窗参数
          if (this.selectedWindowType === WindowType.CHEBYSHEV) {
            this.buildChebyshevParams()
          }
          
          // 其他窗函数的说明
          if (this.isFixedParameterWindow(this.selectedWindowType)) {
            this.buildFixedParamsInfo()
          }
        }
        .width('100%')
      }
      .width('100%')
      .height('40%')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      
      // 底部按钮
      Row({ space: DesignConstants.SPACING_MD }) {
        Button('取消')
          .width('48%')
          .height(48)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            this.params.onClose();
          })
        
        Button('应用')
          .width('48%')
          .height(48)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .backgroundColor($r('sys.color.confirm'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            this.params.onSettingsApplied(
              this.selectedWindowType,
              this.kaiserBeta,
              this.gaussianSigma,
              this.tukeyAlpha,
              this.chebyshevAttenuation
            );
            this.params.onClose();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ top: DesignConstants.SPACING_MD })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius({ topLeft: DesignConstants.BORDER_RADIUS_XL, topRight: DesignConstants.BORDER_RADIUS_XL })
  }

  @Builder
  private buildKaiserParams() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('Kaiser窗参数')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
      
      Text('简单理解：像调节帽子的厚度，值越大帽子越厚，能更好地阻挡干扰，但可能会模糊一些细节')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: DesignConstants.SPACING_SM })
      
      Text('Beta参数控制旁瓣衰减，值越大旁瓣衰减越好，但主瓣越宽')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
        .margin({ bottom: DesignConstants.SPACING_SM })
      
      Row() {
        Text(`Beta值: ${this.kaiserBeta.toFixed(1)}`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_primary'))
        
        Blank()
        
        Text('范围: 1.0 - 12.0')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      .margin({ bottom: DesignConstants.SPACING_SM })
      
      Slider({
        value: this.kaiserBeta,
        min: 1.0,
        max: 12.0,
        step: 0.1,
        style: SliderStyle.InSet
      })
        .width('100%')
        .trackColor($r('sys.color.comp_background_tertiary'))
        .selectedColor($r('sys.color.confirm'))
        .blockColor($r('sys.color.confirm'))
        .onChange((value: number) => {
          this.kaiserBeta = value;
        })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  @Builder
  private buildGaussianParams() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('Gaussian窗参数')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
      
      Text('简单理解：像调节钟形帽子的宽度，值越大帽子越宽，适合分析持续时间长的声音')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: DesignConstants.SPACING_SM })
      
      Text('Sigma参数控制窗函数的标准差，值越大窗函数越宽')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
        .margin({ bottom: DesignConstants.SPACING_SM })
      
      Row() {
        Text(`Sigma值: ${this.gaussianSigma.toFixed(2)}`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_primary'))
        
        Blank()
        
        Text('范围: 0.1 - 1.0')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      .margin({ bottom: DesignConstants.SPACING_SM })
      
      Slider({
        value: this.gaussianSigma,
        min: 0.1,
        max: 1.0,
        step: 0.05,
        style: SliderStyle.InSet
      })
        .width('100%')
        .trackColor($r('sys.color.comp_background_tertiary'))
        .selectedColor($r('sys.color.confirm'))
        .blockColor($r('sys.color.confirm'))
        .onChange((value: number) => {
          this.gaussianSigma = value;
        })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  @Builder
  private buildTukeyParams() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('Tukey窗参数')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
      
      Text('Alpha参数控制平坦部分的宽度比例，值越大平坦部分越宽')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
        .margin({ bottom: DesignConstants.SPACING_SM })
      
      Row() {
        Text(`Alpha值: ${this.tukeyAlpha.toFixed(2)}`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_primary'))
        
        Blank()
        
        Text('范围: 0.0 - 1.0')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      .margin({ bottom: DesignConstants.SPACING_SM })
      
      Slider({
        value: this.tukeyAlpha,
        min: 0.0,
        max: 1.0,
        step: 0.05,
        style: SliderStyle.InSet
      })
        .width('100%')
        .trackColor($r('sys.color.comp_background_tertiary'))
        .selectedColor($r('sys.color.confirm'))
        .blockColor($r('sys.color.confirm'))
        .onChange((value: number) => {
          this.tukeyAlpha = value;
        })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  @Builder
  private buildChebyshevParams() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('Chebyshev窗参数')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
      
      Text('Attenuation参数控制旁瓣衰减，单位为dB')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
        .margin({ bottom: DesignConstants.SPACING_SM })
      
      Row() {
        Text(`衰减值: ${this.chebyshevAttenuation.toFixed(0)}dB`)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_primary'))
        
        Blank()
        
        Text('范围: 40 - 100 dB')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      .margin({ bottom: DesignConstants.SPACING_SM })
      
      Slider({
        value: this.chebyshevAttenuation,
        min: 40,
        max: 100,
        step: 1,
        style: SliderStyle.InSet
      })
        .width('100%')
        .trackColor($r('sys.color.comp_background_tertiary'))
        .selectedColor($r('sys.color.confirm'))
        .blockColor($r('sys.color.confirm'))
        .onChange((value: number) => {
          this.chebyshevAttenuation = value;
        })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  @Builder
  private buildFixedParamsInfo() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text(`${this.getWindowDisplayName(this.selectedWindowType)}参数`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
      
      Text('此窗函数使用固定参数，无需额外配置')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
        .margin({ bottom: DesignConstants.SPACING_SM })
      
      Text('如需调整窗函数特性，请选择其他可调参数的窗函数')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  /**
   * 判断窗函数是否使用固定参数
   */
  private isFixedParameterWindow(windowType: WindowType): boolean {
    return windowType !== WindowType.KAISER && 
           windowType !== WindowType.GAUSSIAN && 
           windowType !== WindowType.TUKEY && 
           windowType !== WindowType.CHEBYSHEV;
  }

  /**
   * 获取窗函数显示名称
   */
  private getWindowDisplayName(windowType: WindowType): string {
    switch (windowType) {
      case WindowType.HANNING:
        return '汉宁窗';
      case WindowType.BLACKMAN:
        return '布莱克曼窗';
      case WindowType.HAMMING:
        return '汉明窗';
      case WindowType.BARTLETT:
        return '巴特利特窗';
      case WindowType.KAISER:
        return '凯泽窗';
      case WindowType.FLATTOP:
        return '平顶窗';
      case WindowType.TRIANGULAR:
        return '三角窗';
      case WindowType.WELCH:
        return '韦尔奇窗';
      case WindowType.SINE:
        return '正弦窗';
      case WindowType.GAUSSIAN:
        return '高斯窗';
      case WindowType.TUKEY:
        return '图基窗';
      case WindowType.CHEBYSHEV:
        return '切比雪夫窗';
      default:
        return '汉宁窗';
    }
  }
}

@Builder
function WindowFunctionParamsDialogBuilderWrapper(params: WindowFunctionParamsDialogParams) {
  WindowFunctionParamsDialogBuilder({ params: params })
}

/**
 * 显示窗函数参数设置对话框
 */
export function showWindowFunctionParamsDialog(params: WindowFunctionParamsDialogParams): InfSheet {
  return DialogHub.getSheet()
    .setStyle({
      showClose: false,
      backgroundColor: $r('sys.color.comp_background_primary')
    })
    .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
    .setComponentTargetId('mainId')
    .setContent(wrapBuilder(WindowFunctionParamsDialogBuilderWrapper), params)
    .build();
}