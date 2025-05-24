import { DecibelMeter } from '../ets/components/decibel-meter/DecibelMeter';
import { Theme } from '../ets/utils/Theme';
import { noiseMeterNavStack } from '../ets/constant/ProviderConstant';
import { getTitleName } from '../MainPageInfo';
import { DecibelHistory } from './DecibelHistoryNavigation';
import { CustomTitleBar } from '../../library/ets/components/common/CustomTitleBar';
import { Settings } from '../ets/components/Settings';
import { common } from '@kit.AbilityKit';
import { ScreenshotUtils } from '../../library/ets/utils/ScreenshotUtils';
import promptAction from '@ohos.promptAction';
import { PreferenceService } from '../../library/ets/services/PreferenceService';
import { PreferenceKeyConstants } from '../../library/ets/constants/PreferenceKeyConstants';

@Builder
export function NoiseMeterBuilder() {
  NoiseMeter()
}

@ComponentV2
export struct NoiseMeter {
  @Consumer(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack()
  @Local currentIndex: number = 0
  @Local meterOn: boolean = true;
  private preferenceService: PreferenceService = PreferenceService.getInstance();

  aboutToAppear(): void {
    this.preferenceService.setBoolean(PreferenceKeyConstants.METER_ON, true);
    this.meterOn = this.preferenceService.getBoolean(PreferenceKeyConstants.METER_ON, true);
  }

  @Builder
  TabBuilder(title: string, icon: Resource, index: number) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? Theme.getColor('icon_active') : Theme.getColor('icon_inactive'))
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? Theme.getColor('text_primary') : Theme.getColor('text_secondary'))
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    NavDestination() {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          Column() {
            // 使用自定义标题栏
            CustomTitleBar({
              title: getTitleName(),
              buttons: [
                {
                  icon: this.meterOn ? $r("app.media.ic_power_off") : $r('app.media.ic_power_on'),
                  onClick: () => {
                    if (this.meterOn) {
                      promptAction.showDialog({
                        title: '确认关机',
                        message: '确认要关闭检测仪吗？',
                        buttons: [
                          {
                            text: '取消',
                            color: Theme.getColor('text_secondary')
                          },
                          {
                            text: '确认',
                            color: Theme.getColor('button_danger')
                          }
                        ]
                      }).then((result) => {
                        if (result.index === 1) { // 1 表示确定按钮
                          this.meterOn = false;
                          this.preferenceService.setBoolean(PreferenceKeyConstants.METER_ON, false);
                        }
                      });
                    } else {
                      this.meterOn = true;
                      this.preferenceService.setBoolean(PreferenceKeyConstants.METER_ON, true);
                    }
                  }
                },
                {
                  icon: $r('app.media.ic_info'),
                  onClick: () => {
                    this.navStack.pushPathByName('NoiseStandardDialog', null);
                  }
                },
                {
                  icon: $r('app.media.ic_share'),
                  onClick: () => {
                    const context = getContext(this) as common.UIAbilityContext;
                    const uiContext = this.getUIContext();
                    const now = new Date();
                    const timestamp = now.toISOString().replace(/[:.]/g, '-').slice(0, 19);
                    ScreenshotUtils.captureAndShare(
                      context,
                      uiContext,
                      'decibelMeterRoot',
                      `noise_meter_screenshot_${timestamp}.jpg`,
                      '止喧噪音检测截图',
                      '当前噪音检测结果截图'
                    );
                  }
                }
              ]
            })

            // 噪音检测区域
            DecibelMeter({ meterOn: this.meterOn })
              .width('92%')
          }
          .id('decibelMeterRoot')
          .width('100%')
          .height('100%')
          .backgroundColor(Theme.getColor('background_secondary'))
          .alignItems(HorizontalAlign.Center)
        }
        .tabBar(this.TabBuilder('检测仪', $r('app.media.ic_meter'), 0))

        TabContent() {
          DecibelHistory({ currentTabIndex: this.currentIndex })
        }
        .tabBar(this.TabBuilder('检测记录', $r('app.media.ic_history'), 1))

        // TabContent() {
        //   LeqStatistics()
        // }
        // .tabBar(this.TabBuilder('统计', $r('app.media.ic_stats'), 2))

        TabContent() {
          Settings()
        }
        .tabBar(this.TabBuilder('设置', $r('app.media.ic_settings'), 2))
      }
      .scrollable(false)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .width('100%')
      .height('100%')
      .barHeight(56)
      .barMode(BarMode.Fixed)
      .animationDuration(0)
    }
    .hideTitleBar(true)
    .backgroundColor(Theme.getColor('background_secondary'))
    .hideToolBar(true)
    .mode(NavDestinationMode.STANDARD)
  }
}
