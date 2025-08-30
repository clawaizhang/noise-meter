import common from '@ohos.app.ability.common';
import { NoiseStandard } from '../../models/NoiseStandard';
import { DecibelService } from '../../services/DecibelService';
import {
  responsiveFontSize,
  responsiveSpacing,
  responsiveListItemSpacing,
  responsiveListItemPadding,
  responsiveListItemWidth,
  responsiveListItemMargin,
  responsiveIconSize,
  getCurrentListItemLayoutMode,
  addListItemLayoutChangeListener,
  ListItemLayoutMode,
  Breakpoint,
  LayoutMode,
  responsive
} from '../../utils/ResponsiveLayout';
import { DesignConstants } from '../../constants/DesignConstants';

// 网格间距接口
interface GridGutter {
  x: number;
  y: number;
}

// 网格列跨度配置接口
interface GridColSpans {
  values: number;
  description: number;
}

// 响应式布局配置接口
interface ResponsiveLayoutConfig {
  [LayoutMode.XSMALL]: GridColSpans;
  [LayoutMode.SMALL]: GridColSpans;
  [LayoutMode.MEDIUM]: GridColSpans;
  [LayoutMode.LARGE]: GridColSpans;
  [LayoutMode.XLARGE]: GridColSpans;
}


@ComponentV2
export struct NoiseStandardCard {
  @Param @Require standard: NoiseStandard;
  @Param @Require context: common.Context | null;
  // 响应式布局状态
  @Local private listItemLayoutMode: ListItemLayoutMode = getCurrentListItemLayoutMode();
  @Local private cardWidth: number = responsiveListItemWidth();

  // 响应式网格配置
  private getGridColumns(): number {
    return responsive({
      [LayoutMode.XSMALL]: 1,
      [LayoutMode.SMALL]: 2,
      [LayoutMode.MEDIUM]: 3,
      [LayoutMode.LARGE]: 4,
      [LayoutMode.XLARGE]: 5
    });
  }

  // 响应式网格列跨度配置
  private getGridColSpans(): GridColSpans {
    const responsiveConfig: ResponsiveLayoutConfig = {
      [LayoutMode.XSMALL]: { values: 1, description: 1 },
      [LayoutMode.SMALL]: { values: 1, description: 1 },
      [LayoutMode.MEDIUM]: { values: 1, description: 1 },
      [LayoutMode.LARGE]: { values: 1, description: 1 },
      [LayoutMode.XLARGE]: { values: 1, description: 1 }
    };
    return responsive(responsiveConfig);
  }

  @Builder
  private CardContent() {
    Column() {
      // 标题
      Row() {
        Text(this.standard.typeName)
          .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_2XL))
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')

      // 分贝范围和描述 - 使用响应式网格布局
      GridRow({
        columns: {
          xs: 1,
          sm: 1,
          md: 2,
          lg: 2,
          xl: 3,
          xxl: 3
        }, breakpoints: { reference: BreakpointsReference.WindowSize }
      }) {

        GridCol({ span: this.getGridColSpans().values }) {
          Column() {
            // 白天分贝
            Row() {
              Text('白天')
                .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_SM))
                .fontColor($r('app.color.text_secondary'))
              Text(`${this.standard.dayLimit} dB`)
                .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_XL))
                .fontColor(DecibelService.getDecibelColor(this.standard.dayLimit))
                .fontWeight(FontWeight.Bold)
                .margin({ left: responsiveSpacing(DesignConstants.SPACING_SM) })
            }
            .margin({ bottom: responsiveSpacing(DesignConstants.SPACING_SM) })

            // 夜间分贝
            Row() {
              Text('夜间')
                .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_SM))
                .fontColor($r('app.color.text_secondary'))
              Text(`${this.standard.nightLimit} dB`)
                .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_XL))
                .fontColor(DecibelService.getDecibelColor(this.standard.nightLimit))
                .fontWeight(FontWeight.Bold)
                .margin({ left: responsiveSpacing(DesignConstants.SPACING_SM) })
            }
          }
        }

        GridCol({ span: 1}) {
          Column() {
            Text(this.standard.description)
              .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_SM))
              .fontColor($r('app.color.text_secondary'))
              .lineHeight(responsiveFontSize(DesignConstants.FONT_SIZE_LG))
          }
        }
      }.margin({ top: responsiveSpacing(DesignConstants.SPACING_XS) })
    }
    .padding(responsiveListItemPadding(DesignConstants.SPACING_SM))
    .width(this.cardWidth)
  }

  aboutToAppear() {
    // 注册布局变化监听
    addListItemLayoutChangeListener((newLayoutMode: ListItemLayoutMode, breakpoint: Breakpoint,
      isLandscape: boolean) => {
      this.listItemLayoutMode = newLayoutMode;
      this.cardWidth = responsiveListItemWidth(300, this.getGridColumns());
    });
  }

  build() {
    Column() {
      this.CardContent()
    }
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(responsive({
      [LayoutMode.XSMALL]: 8,
      [LayoutMode.SMALL]: 10,
      [LayoutMode.MEDIUM]: 12,
      [LayoutMode.LARGE]: 14,
      [LayoutMode.XLARGE]: 16
    }))
    .margin({
      bottom: responsiveListItemMargin(DesignConstants.SPACING_MD),
      left: responsiveListItemMargin(DesignConstants.SPACING_SM),
      right: responsiveListItemMargin(DesignConstants.SPACING_SM)
    })
    .shadow({
      radius: responsive({
        [LayoutMode.XSMALL]: 1,
        [LayoutMode.SMALL]: 2,
        [LayoutMode.MEDIUM]: 3,
        [LayoutMode.LARGE]: 4,
        [LayoutMode.XLARGE]: 5
      }),
      color: '#33000000',
      offsetY: responsive({
        [LayoutMode.XSMALL]: 1,
        [LayoutMode.SMALL]: 1,
        [LayoutMode.MEDIUM]: 2,
        [LayoutMode.LARGE]: 2,
        [LayoutMode.XLARGE]: 3
      })
    })
  }
}

@Builder
export function NoiseStandardCardBuilder(standard: NoiseStandard, context: common.Context | null) {
  NoiseStandardCard({ standard: standard, context: context })
}
