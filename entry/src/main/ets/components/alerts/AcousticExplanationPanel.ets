/**
 * 声学解释面板组件
 * 提供可展开的声学原理说明和技术参数显示
 */

import { ACOUSTIC_EXPLANATIONS, ALERT_COLORS, TECHNICAL_PARAMS } from '../../constants/AlertsConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';
import { curves } from '@kit.ArkUI';

@ComponentV2
export struct AcousticExplanationPanel {
  @Local private isTechnicalPanelExpanded: boolean = false;    // 技术参数面板展开状态
  @Local private isAcousticPanelExpanded: boolean = false;     // 声学原理面板展开状态

  // 构建技术参数面板
  @Builder
  private buildTechnicalPanel() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题行
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_info'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.brand'))

        Text('技术参数')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        // 展开/收起按钮
        Image(this.isTechnicalPanelExpanded ? 
          $r('sys.media.ohos_ic_public_arrow_up') : 
          $r('sys.media.ohos_ic_public_arrow_down'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor($r('sys.color.brand'))
          .onClick(() => {
            Throttle.click(() => {
              this.isTechnicalPanelExpanded = !this.isTechnicalPanelExpanded;
            });
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        Throttle.click(() => {
          this.isTechnicalPanelExpanded = !this.isTechnicalPanelExpanded;
        });
      })

      // 技术参数内容
      if (this.isTechnicalPanelExpanded) {
        Column({ space: DesignConstants.SPACING_XS }) {
          // 参数网格
          GridRow({
            columns: { sm: 1, md: 2 },
            breakpoints: { reference: BreakpointsReference.WindowSize },
            gutter: { x: DesignConstants.SPACING_MD, y: DesignConstants.SPACING_SM }
          }) {
            // 频率范围
            GridCol({ span: 1 }) {
              this.buildParamItem('频率范围', TECHNICAL_PARAMS.frequencyRange)
            }

            // 动态范围
            GridCol({ span: 1 }) {
              this.buildParamItem('动态范围', TECHNICAL_PARAMS.dynamicRange)
            }

            // 精度
            GridCol({ span: 1 }) {
              this.buildParamItem('精度', TECHNICAL_PARAMS.accuracy)
            }

            // 响应时间
            GridCol({ span: 1 }) {
              this.buildParamItem('响应时间', TECHNICAL_PARAMS.responseTime)
            }
          }
          .width('100%')
          .margin({ top: DesignConstants.SPACING_MD })
        }
        .width('100%')
        .animation({
          duration: 300,
          curve: curves.springMotion()
        })
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor(ALERT_COLORS.CARD_BACKGROUND)
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .shadow(DesignConstants.SHADOW_SM)
  }

  // 构建参数项
  @Builder
  private buildParamItem(label: string, value: string) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(label)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)

      Text(value)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(DesignConstants.SPACING_SM)
    .backgroundColor($r('sys.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_SM)
  }

  // 构建声学原理面板
  @Builder
  private buildAcousticPanel() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 标题行
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_audio_analysis'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.brand'))

        Text('声学原理')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        // 展开/收起按钮
        Image(this.isAcousticPanelExpanded ? 
          $r('sys.media.ohos_ic_public_arrow_up') : 
          $r('sys.media.ohos_ic_public_arrow_down'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor($r('sys.color.font_secondary'))
          .onClick(() => {
            Throttle.click(() => {
              this.isAcousticPanelExpanded = !this.isAcousticPanelExpanded;
            });
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        Throttle.click(() => {
          this.isAcousticPanelExpanded = !this.isAcousticPanelExpanded;
        });
      })

      // 声学原理内容
      if (this.isAcousticPanelExpanded) {
        Column({ space: DesignConstants.SPACING_MD }) {
          // 基本原理
          Column({ space: DesignConstants.SPACING_XS }) {
            Text('基本原理')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
              .alignSelf(ItemAlign.Start)

            Text(ACOUSTIC_EXPLANATIONS['alerts'].principle)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_secondary'))
              .textAlign(TextAlign.Start)
              .alignSelf(ItemAlign.Start)
          }

          // 健康影响
          Column({ space: DesignConstants.SPACING_XS }) {
            Text('健康影响')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
              .alignSelf(ItemAlign.Start)

            Text(ACOUSTIC_EXPLANATIONS['alerts'].healthImpact)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_secondary'))
              .textAlign(TextAlign.Start)
              .alignSelf(ItemAlign.Start)
          }

          // 标准依据
          Column({ space: DesignConstants.SPACING_XS }) {
            Text('标准依据')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
              .alignSelf(ItemAlign.Start)

            Text(ACOUSTIC_EXPLANATIONS['alerts'].standardReference)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_secondary'))
              .textAlign(TextAlign.Start)
              .alignSelf(ItemAlign.Start)
          }

          // 物理原理
          Column({ space: DesignConstants.SPACING_XS }) {
            Text('物理原理')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
              .alignSelf(ItemAlign.Start)

            Text(ACOUSTIC_EXPLANATIONS['alerts'].physicalPrinciple)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_secondary'))
              .textAlign(TextAlign.Start)
              .alignSelf(ItemAlign.Start)
          }

        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ top: DesignConstants.SPACING_MD })
        .animation({
          duration: 300,
          curve: curves.springMotion()
        })
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor(ALERT_COLORS.CARD_BACKGROUND)
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .shadow(DesignConstants.SHADOW_SM)
  }

  build() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // 技术参数面板
      this.buildTechnicalPanel()

      // 声学原理面板
      this.buildAcousticPanel()
    }
    .width('100%')
    .animation({
      duration: 400,
      curve: curves.springMotion()
    })
  }
}