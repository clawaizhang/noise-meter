import { navigationStack } from '../../constants/ProviderConstant';
import { curves, PersistenceV2 } from '@kit.ArkUI';
import { DialogHub } from '@hadss/dialoghub';
import { AudioAnalysisSettingsBuilder } from '../settings/AudioAnalysisSettingsNavigation';
import { AlertsSettingsBuilder } from '../settings/AlertsSettingsNavigation';
import { DataPrivacySettingsBuilder } from '../settings/DataPrivacySettingsNavigation';
import { DeviceSettingsBuilder } from '../settings/DeviceSettingsNavigation';
import { AboutSettingsBuilder } from '../settings/AboutSettingsNavigation';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DesignConstants } from '../../constants/DesignConstants';

@Builder
export function SettingsBuilder() {
  Settings()
}

@Extend(Image)
function itemIcon() {
  .width(DesignConstants.ICON_SIZE_MD)
  .height(DesignConstants.ICON_SIZE_MD)
  .fillColor($r('sys.color.font_primary'))
}

@Extend(Text)
function itemTitle() {
  .fontWeight(FontWeight.Medium)
}

@Extend(Column)
function cardStyle() {
  .backgroundColor($r('sys.color.comp_background_secondary'))
  .justifyContent(FlexAlign.Start)
  .alignItems(HorizontalAlign.Start)
  .borderRadius(16)
  .padding(16)
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
    .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
    .combine(TransitionEffect.translate({ x: 0, y: 0 }).animation({ curve: curves.springMotion() })))
}

@Extend(Row)
function listItemRow() {
  .alignItems(VerticalAlign.Center)
  .justifyContent(FlexAlign.Start)
}

interface ListItemParam {
  icon: Resource;
  title: string;
  desc: string;
  action: () => void;
}

@ComponentV2
export struct Settings {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
  }

  // 导航到音频分析设置页面
  private navigateToAudioAnalysis = () => {
    DialogHub.getSheet()
      .setStyle({ title: { title: '音频分析设置' }, backgroundColor: $r('sys.color.background_primary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('settingsId')
      .setContent(wrapBuilder(AudioAnalysisSettingsBuilder))
      .build()
      .show();
  }
  // 导航到警报与通知设置页面
  private navigateToAlerts = () => {
    DialogHub.getSheet()
      .setStyle({ title: { title: '警报与通知' }, backgroundColor: $r('sys.color.background_primary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('settingsId')
      .setContent(wrapBuilder(AlertsSettingsBuilder))
      .build()
      .show();
  }
  // 导航到数据记录与隐私设置页面
  private navigateToDataPrivacy = () => {
    DialogHub.getSheet()
      .setStyle({ title: { title: '数据记录与隐私' }, backgroundColor: $r('sys.color.background_primary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('settingsId')
      .setContent(wrapBuilder(DataPrivacySettingsBuilder))
      .build()
      .show();
  }
  // 导航到设备设置页面
  private navigateToDeviceSettings = () => {
    DialogHub.getSheet()
      .setStyle({ title: { title: '设备设置' }, backgroundColor: $r('sys.color.background_primary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('settingsId')
      .setContent(wrapBuilder(DeviceSettingsBuilder))
      .build()
      .show();
  }
  // 导航到关于页面
  private navigateToAbout = () => {
    DialogHub.getSheet()
      .setStyle({ title: { title: '关于' }, backgroundColor: $r('sys.color.background_primary') })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('settingsId')
      .setContent(wrapBuilder(AboutSettingsBuilder))
      .build()
      .show();
  }

  build() {
    GridRow({
      columns:
      {
        sm: 1,
        md: 2,
        lg: 2,
        xl: 3
      },
      breakpoints: { reference: BreakpointsReference.WindowSize }
    , gutter: 16
    }) {
      // 分贝计权设置
      GridCol() {
        Column({ space: 8 }) {
          Row() {
            Row({ space: 8 }) {
              Image($r('sys.media.ohos_ic_public_device_smartscreen'))
                .itemIcon()
              Text('显示模式')
                .itemTitle()
            }.layoutWeight(1)

            Select([
              { value: '跟随系统' },
              { value: '浅色' },
              { value: '深色' }
            ])
              .selected(this.getDisplayModeIndex(this.pk.display_mode))
              .value(this.getDisplayModeText(this.pk.display_mode))
              .onSelect((index: number) => {
                this.pk.display_mode = this.getDisplayMode(index);
              })
          }
          .listItemRow()
        }
        .cardStyle()
      }

      // 音频分析设置
      this.buildListItem({
        icon: $r('app.media.ic_audio_analysis'),
        title: '音频分析设置',
        desc: '时间计权模式、频率加权、声级校准等设置',
        action: () => {
          this.navigateToAudioAnalysis();
        }
      })

      this.buildListItem({
        icon: $r('app.media.ic_alarm'),
        title: '警报与通知',
        desc: '噪音警报阈值和通知设置',
        action: () => {
          this.navigateToAlerts();
        }
      })

      this.buildListItem({
        icon: $r('app.media.ic_security'),
        title: '数据记录与隐私',
        desc: '地理位置、音频记录等隐私设置',
        action: () => {
          this.navigateToDataPrivacy();
        }
      })

      this.buildListItem({
        icon: $r('app.media.ic_settings'),
        title: '设备设置',
        desc: '屏幕常亮、后台运行等设备设置',
        action: () => {
          this.navigateToDeviceSettings();
        }
      })

      this.buildListItem({
        icon: $r('app.media.ic_info'),
        title: '关于',
        desc: '应用信息、隐私政策和技术支持',
        action: () => {
          this.navigateToAbout();
        }
      })
    }.padding(16).backgroundColor($r('sys.color.background_primary'))
    .id
    ('settingsId'
    )
  }

  getDisplayModeIndex(displayMode: string): number {
    switch (displayMode) {
      case 'default':
        return 0;
      case 'light':
        return 1;
      case 'dark':
        return 2;
      default:
        return 0;
    }
  }

  getDisplayModeText(displayMode: string): string {
    switch (displayMode) {
      case 'default':
        return "跟随系统";
      case 'light':
        return "浅色";
      case 'dark':
        return "深色";
      default:
        return "跟随系统";
    }
  }

  getDisplayMode(index: number): string {
    switch (index) {
      case 0:
        return 'default';
      case 1:
        return 'light';
      case 2:
        return 'dark';
      default:
        return 'default';
    }
  }

  @
  Builder
  buildListItem(param:
    ListItemParam
  ) {
    GridCol({ span: 1 }) {
      Column({ space: 8 }) {
        Row() {
          Row() {
            Image(param.icon)
              .height(20)
              .width(20)
              .fillColor($r('sys.color.font_primary'));
            Text(param.title);
          }.layoutWeight(1);

          Image($r('app.media.ic_arrow_right'))
            .fillColor($r('sys.color.font_primary'))
            .height(24)
            .width(24);
        }.justifyContent(FlexAlign.End);

        Text(param.desc)
          .fontSize(14)
          .fontColor($r('sys.color.font_secondary'));
      }.alignItems(HorizontalAlign.Start);
    }
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .onClick(param.action)
    .padding(16)
    .borderRadius(16)
    .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
      .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
      .combine(TransitionEffect.translate({ x: 0, y: 0 }).animation({ curve: curves.springMotion() })))
  }
}