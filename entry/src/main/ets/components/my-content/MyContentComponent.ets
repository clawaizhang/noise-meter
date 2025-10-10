import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2 } from '@kit.ArkUI';
import { ListItemBuilder } from '../common/ListItemBuilder';
import { SettingsBuilder } from '../../pages/noisemeter/SettingsNavigation';
import { AboutSettingsBuilder } from '../../pages/settings/AboutSettingsNavigation';
import { DialogHub } from '@hadss/dialoghub';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { DisplayModeComponent } from '../display/DisplayModeComponent';
import { MembershipStatusCard } from '../membership/MembershipStatusCard';
import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';
import { CommentService } from '../../services/CommentService';

/**
 * 我的内容页面组件
 * 包含显示模式设置、全局设置、五星好评、关于等功能
 */
@ComponentV2
export struct MyContentComponent {
  @Param currentIndex: number = 2
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;

  // 显示评论对话框
  private showCommentDialog = () => {
    Throttle.click(async () => {
      try {
        const context = getContext(this) as common.UIAbilityContext;
        const commentService = CommentService.getInstance();
        await commentService.showCommentDialog(context);
        console.info('评论对话框显示成功');
      } catch (error) {
        console.error(`显示评论对话框失败: ${error instanceof Error ? error.message : String(error)}`);
        // 可以在这里添加用户友好的错误提示
      }
    });
  }

  build() {
    // 可滚动内容区域
    Scroll() {
      Column() {

        // 会员状态卡片
        MembershipStatusCard()
          .margin({ top: DesignConstants.SPACING_MD, left: 16, right: 16 })

        // 全局设置列表项
        List() {

          ListItem() {
            // 显示模式组件
            DisplayModeComponent()
          }.margin({
            left: 16,
            right: 16, top: 16
          })

          // 后台运行设置
          ListItem() {
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                Row() {
                  Image($r('app.media.ic_running'))
                    .width(24)
                    .height(24)
                    .fillColor($r('sys.color.brand'))
                    .margin({ right: 12 })

                  Text($r('app.string.background_running'))
                    .fontSize(16)
                    .fontColor($r('sys.color.font_primary'))
                    .layoutWeight(1)
                }.layoutWeight(1)

                // 状态指示器
                Toggle({ type: ToggleType.Switch, isOn: this.pk.background_running })
                  .selectedColor($r('app.color.toggle_active'))
                  .switchPointColor($r('app.color.background_primary'))
                  .onChange((isOn: boolean) => {
                    this.pk.background_running = isOn;
                  })
              }
              .width('100%')
              .height(24)
              .alignItems(VerticalAlign.Center)

              // 描述文本
              Text(this.pk.background_running ? $r('app.string.background_running_desc_on') : $r('app.string.background_running_desc_off'))
                .fontSize(12)
                .fontColor($r('sys.color.font_secondary'))
                .width('100%')
                .textAlign(TextAlign.Start)
            }
            .width('100%')
            .padding({
              left: 16,
              right: 16,
              top: 12,
              bottom: 12
            })
          }
          .borderRadius(16)
          .backgroundColor($r('sys.color.comp_background_primary'))
          .margin({
            top: 20,
            left: 16,
            right: 16
          })

          ListItemBuilder(
            $r('app.media.ic_settings'),
            '全局设置',
            () => {
              DialogHub.getSheet()
                .setStyle({
                  title: { title: '设置' },
                  backgroundColor: $r('sys.color.background_secondary')
                })
                .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
                .setComponentTargetId('mainId')
                .setContent(wrapBuilder(SettingsBuilder))
                .build()
                .show();
            },
            20
          )

          // 给作者五星好评设置
          ListItemBuilder(
            $r('app.media.ic_smile'),
            '五星好评',
            () => {
              this.showCommentDialog();
            }
          )

          // 关于列表项
          ListItemBuilder(
            $r('app.media.ic_info'),
            '关于',
            () => {
              DialogHub.getSheet()
                .setStyle({ title: { title: '关于' }, backgroundColor: $r('sys.color.background_secondary') })
                .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
                .setComponentTargetId('mainId')
                .setContent(wrapBuilder(AboutSettingsBuilder))
                .build()
                .show();
            }
          )
        }
        .width('100%')
        .alignListItem(ListItemAlign.Start)

      }
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .opacity(this.currentIndex === 2 ? 1 : 0)
      .scale({ x: this.currentIndex === 2 ? 1 : 0.95, y: this.currentIndex === 2 ? 1 : 0.95 })
      .animation({
        duration: 300,
        curve: Curve.EaseOut,
        delay: 0,
        iterations: 1,
        playMode: PlayMode.Normal
      })
    }
    .align(Alignment.Top)
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
  }
}