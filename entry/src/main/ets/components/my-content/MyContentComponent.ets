import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2 } from '@kit.ArkUI';
import { ListItemBuilder } from '../common/ListItemBuilder';
import { SettingsBuilder } from '../../pages/noisemeter/SettingsNavigation';
import { AboutSettingsBuilder } from '../../pages/settings/AboutSettingsNavigation';
import { DialogHub } from '@hadss/dialoghub';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { DisplayModeComponent } from '../display/DisplayModeComponent';

/**
 * 我的内容页面组件
 * 包含显示模式设置、全局设置、五星好评、关于等功能
 */
@ComponentV2
export struct MyContentComponent {
  @Param currentIndex: number = 2
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!
  // 跳转到应用商店评价页面
  private navigateToAppStoreRating = () => {
    const context = getContext(this) as common.UIAbilityContext;
    const want: Want = {
      action: 'ohos.want.action.appdetail',
      uri: 'store://appgallery.huawei.com/app/detail?id=yu.zhang.myapplication.noise_meter_pro&action=write-review'
    };
    context.startAbility(want).then(() => {
      console.info('Succeeded in starting App Store rating page successfully.');
    }).catch((err: BusinessError) => {
      console.error(`Failed to start App Store rating page. Code: ${err.code}, message: ${err.message}`);
    });
  }

  build() {
    Column() {


      // 全局设置列表项
      List() {

        ListItem() {
          // 显示模式组件
          DisplayModeComponent()
        } .margin({
          left: 16,
          right: 16
        })

        ListItemBuilder(
          $r('app.media.ic_settings'),
          '全局设置',
          () => {
            DialogHub.getSheet()
              .setStyle({ title: { title: '设置' }, backgroundColor: $r('sys.color.background_secondary') })
              .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS, enableOutsideInteractive: true })
              .setComponentTargetId('popupTargetId')
              .setContent(wrapBuilder(SettingsBuilder))
              .build()
              .show();
          },
          20
        )

        // 给作者五星好评设置
        ListItemBuilder(
          $r('app.media.ic_favorite'),
          '五星好评',
          () => {
            this.navigateToAppStoreRating();
          }
        )

        // 关于列表项
        ListItemBuilder(
          $r('app.media.ic_info'),
          '关于',
          () => {
            DialogHub.getSheet()
              .setStyle({ title: { title: '关于' }, backgroundColor: $r('sys.color.background_secondary') })
              .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS, enableOutsideInteractive: true })
              .setComponentTargetId('popupTargetId')
              .setContent(wrapBuilder(AboutSettingsBuilder))
              .build()
              .show();
          }
        )
      }
      .width('100%')
      .alignListItem(ListItemAlign.Center)

    }
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
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
}