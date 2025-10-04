import { DesignConstants } from "../../constants/DesignConstants"

@ComponentV2
export struct UpgradeContent {
  @Param @Require featureName: string; // 功能名称
  @Param @Require featureDesc: string; // 功能描述
  @Param @Require icon: Resource; // 功能图标

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 功能图标和名称
      Row({ space: DesignConstants.SPACING_SM }) {
        if (this.icon) {
          Image(this.icon)
            .width(24)
            .height(24)
            .fillColor($r('sys.color.ohos_id_color_palette1'))
        }

        Text(this.featureName)
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')

      // 功能描述
      Text(this.featureDesc)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Start)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 专业版价值点
      Column({ space: DesignConstants.SPACING_XS }) {
        Text('专业版包含：')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        Text('• 多频率加权（A/C/Z计权）')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .alignSelf(ItemAlign.Start)

        Text('• 多时间加权（快速/慢速/脉冲）')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .alignSelf(ItemAlign.Start)

        Text('• 智能时段警报')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .alignSelf(ItemAlign.Start)

        Text('• 专业数据导出')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .alignSelf(ItemAlign.Start)
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ top: DesignConstants.SPACING_MD })

      // 操作按钮
      Row({ space: DesignConstants.SPACING_MD }) {
        Button('稍后再说')
          .layoutWeight(1)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.background_secondary'))
          .fontColor($r('sys.color.font_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
          })

        Button('立即升级')
          .layoutWeight(1)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.ohos_id_color_palette1'))
          .fontColor($r('sys.color.font_on_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            // 跳转到会员购买页面
            // Router.pushNamed({ name: 'membership' });
            console.info('跳转到会员购买页面');
          })
      }
      .width('100%')
      .margin({ top: DesignConstants.SPACING_LG })
    }
    .padding(DesignConstants.SPACING_LG)
    .width('100%')
  }
}


@Builder
export function UpgradeContentBuilder(props: UpgradeContentProps) {
  UpgradeContent({ featureName: props.featureName, featureDesc: props.featureDesc, icon: props.icon })
}

export interface UpgradeContentProps {
  featureName: string;
  featureDesc: string;
  icon: Resource;
}