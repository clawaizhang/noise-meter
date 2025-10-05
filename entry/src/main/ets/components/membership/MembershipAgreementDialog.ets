import { DesignConstants } from "../../constants/DesignConstants"

export interface MembershipAgreementDialogProps {
  onAgree: () => void;
  onCancel: () => void;
}

@Builder
export function MembershipAgreementDialogBuilder(props: MembershipAgreementDialogProps){
  MembershipAgreementDialog(props)
}

@ComponentV2
export struct MembershipAgreementDialog {
  @Param onAgree: () => void = () => {};
  @Param onCancel: () => void = () => {};

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题区域
      Column({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_document_edit'))
          .width(DesignConstants.ICON_SIZE_XL)
          .height(DesignConstants.ICON_SIZE_XL)
          .fillColor($r('sys.color.interactive_active'))
          .margin({ bottom: DesignConstants.SPACING_SM })
        
        Text('会员奖励计划协议')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .textAlign(TextAlign.Center)

        Text('请仔细阅读并同意以下会员奖励规则')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({
        top: DesignConstants.SPACING_LG,
        bottom: DesignConstants.SPACING_MD
      })

      // 协议内容区域（可滚动）
      Scroll() {
        Column({ space: DesignConstants.SPACING_MD }) {
          // 奖励规则说明
          this.buildAgreementSection(
            '会员奖励规则',
            [
              '1. 每日使用奖励：每天使用APP达到1分钟，即可获得1天会员资格',
              '2. 连续使用奖励：',
              '   • 连续使用3天，额外获得2天会员奖励',
              '   • 连续使用7天，额外获得3天会员奖励', 
              '   • 连续使用15天，额外获得5天会员奖励',
              '3. 奖励累计：所有奖励天数会自动累加到您的会员有效期'
            ]
          )

          // 使用条款
          this.buildAgreementSection(
            '使用条款',
            [
              '1. 会员奖励仅限个人使用，不得转让或出售',
              '2. 连续使用天数中断后，将从第一天重新开始计算',
              '3. 会员奖励不可兑换现金或其他形式的补偿',
              '4. 我们保留根据实际情况调整奖励规则的权利',
              '5. 最终解释权归APP所有'
            ]
          )

          // 隐私说明
          this.buildAgreementSection(
            '隐私说明',
            [
              '1. 我们仅收集必要的APP使用时长数据',
              '2. 收集的数据仅用于会员奖励计算和功能优化',
              '3. 我们严格遵守隐私政策，保护您的个人信息安全',
              '4. 您可以随时在设置中查看和管理您的数据'
            ]
          )

          // 生效说明
          this.buildAgreementSection(
            '生效说明',
            [
              '1. 点击"同意并继续"即表示您已阅读并同意本协议',
              '2. 本协议自您同意之日起生效',
              '3. 我们可能会根据法律法规或业务需要更新本协议',
              '4. 协议更新时，我们会通过适当方式通知您'
            ]
          )
        }
        .width('100%')
        .padding(DesignConstants.SPACING_MD)
      }
      .scrollBar(BarState.Auto)
      .scrollable(ScrollDirection.Vertical)
      .layoutWeight(1)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)

      // 操作按钮区域
      Row({ space: DesignConstants.SPACING_MD }) {
        Button('取消')
          .layoutWeight(1)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .fontColor($r('sys.color.font_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .border({
            width: DesignConstants.BORDER_WIDTH_SM,
            color: $r('sys.color.comp_border_color'),
            style: BorderStyle.Solid
          })
          .onClick(() => {
            this.onCancel();
          })

        Button('同意并继续')
          .layoutWeight(1)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .backgroundColor($r('sys.color.interactive_active'))
          .fontColor($r('sys.color.font_on_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onClick(() => {
            this.onAgree();
          })
      }
      .width('100%')
      .padding({
        top: DesignConstants.SPACING_LG
      })
    }
    .width('100%')
    .height('80%')
    .padding(DesignConstants.SPACING_LG)
    .borderRadius(DesignConstants.BORDER_RADIUS_XL)
  }

  // 构建协议段落
  @Builder
  private buildAgreementSection(title: string, items: string[]) {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 段落标题
      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 段落内容
      Column({ space: DesignConstants.SPACING_XS }) {
        ForEach(items, (item: string) => {
          Text(item)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .textAlign(TextAlign.Start)
            .lineHeight(20)
            .width('100%')
        })
      }
      .width('100%')
      .padding({
        left: DesignConstants.SPACING_SM
      })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .border({
      width: DesignConstants.BORDER_WIDTH_SM,
      color: $r('sys.color.comp_border_color'),
      style: BorderStyle.Solid
    })
    .shadow(DesignConstants.SHADOW_SM)
  }
}