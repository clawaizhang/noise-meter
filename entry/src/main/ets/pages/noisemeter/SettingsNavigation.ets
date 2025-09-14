import { navigationStack } from '../../constants/ProviderConstant';
import { curves } from '@kit.ArkUI';

@Builder
function SettingsBuilder() {
  Settings()
}

interface ListItemParam {
  icon: Resource;
  title: string;
  desc: string;
  action: () => void;
}

@ComponentV2
export struct Settings {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
  }

  // 导航到音频分析设置页面
  private navigateToAudioAnalysis = () => {
    this.navStack.pushPathByName('AudioAnalysisSettings', null);
  }
  // 导航到警报与通知设置页面
  private navigateToAlerts = () => {
    this.navStack.pushPathByName('AlertsSettings', null);
  }
  // 导航到数据记录与隐私设置页面
  private navigateToDataPrivacy = () => {
    this.navStack.pushPathByName('DataPrivacySettings', null);
  }
  // 导航到设备设置页面
  private navigateToDeviceSettings = () => {
    this.navStack.pushPathByName('DeviceSettings', null);
  }
  // 导航到关于页面
  private navigateToAbout = () => {
    this.navStack.pushPathByName('AboutSettings', null);
  }

  build() {
    NavDestination() {
      Scroll() {
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
      }.scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)

    }.title('设置')
  }

  @Builder
  buildListItem(param: ListItemParam) {
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
    .backgroundColor($r('sys.color.background_secondary'))
    .onClick(param.action)
    .padding(16)
    .borderRadius(16)
    .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
      .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
      .combine(TransitionEffect.translate({ y: 150 }).animation({ curve: curves.springMotion() })))
  }
}