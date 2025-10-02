import { navigationStack } from '../../constants/ProviderConstant';
import { AppStorageV2, curves, LevelMode, PersistenceV2 } from '@kit.ArkUI';
import display from '@ohos.display';
import { secondsToHoursMinutesSecondsWithDecimal } from '../../utils/TimeUtils';
import { ActionPanel } from './ActionPanel';
import { SpectrumChartComponent } from './SpectrumChartComponent';
import { DecibelDisplayComponent } from './DecibelDisplayComponent';
import { DisplayManager } from '../../../../main/ets/utils/DisplayManager';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { LocationInfo } from '../../services/LocationService';
import { LocationDisplay } from '../business/LocationDisplay';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { resourceManager } from '@kit.LocalizationKit';
import { image } from '@kit.ImageKit';
import { AppKeys } from '../../models/AppKeys';
import { PermissionService } from '../../services/PermissionService';
import { AudioController } from './AudioController';

@ComponentV2
export struct DecibelMeter {

  @Param @Require meterOn: boolean = true;
  @Local private isRecording: boolean = false
  @Local private recordingTime: number = 0
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local breakPoint: string = '';
  @Local dScale: number = 1; // 页面缩放比例
  @Local translateX: number = 0; // X轴位移
  @Local translateY: number = 0; // Y轴位移
  @Local dOpacity: number = 1; // 页面透明度
  @Local dWidthHeight: string = ''; // 页面透明度
  @Local bgImage: image.PixelMap | undefined = undefined; // 页面透明度
  @Local as: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local private currentSpectrum: Float32Array = new Float32Array(); // 当前频谱数据
  @Local private currentLocation: LocationInfo | null = null; // 当前位置信息，从LocationDisplay接收
  @Local private errorMessages: string[] = []; // 错误消息队列
  @Local private currentDecibel: number = 0;
  @Local private avgDecibel: number = 0;
  @Local private maxDecibel: number = 0;
  @Local private minDecibel: number = 0;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  noiseInfoDialog: InfSheet | undefined
  sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();

  aboutToDisappear() {
    // 清理资源
  }

  async aboutToAppear() {
  }

  build() {
    Stack() {
      GridRow({ columns: 12, breakpoints: { reference: BreakpointsReference.WindowSize }, gutter: 16 }) {

        // 错误消息显示区域（支持多个错误同时显示）
        if (this.errorMessages.length > 0) {
          GridCol({ span: { xs: 12 } }) {
            this.errorMessagesDisplay()
          }
        }

        // 权限提示组件 - 显示在顶部
        GridCol({ span: { xs: 12 } }) {
          if (!this.as.microphonePermissionGranted) {
            this.smartPermissionPrompt()
          }
        }

        // 音频控制器（逻辑组件，不渲染UI）
        AudioController({
          pk: this.pk,
          currentLocation: this.currentLocation,
          onAudioBuffer: (buffer: ArrayBuffer) => {
          },
          onSpectrumData: (spectrum: Float32Array) => {
            this.currentSpectrum = spectrum;
            this.as.spectrumData = spectrum;
          },
          onError: (errors: string[]) => {
            this.errorMessages = errors;
          },
          onRecordingStateChange: (isRecording: boolean) => {
            this.isRecording = isRecording;
          },
          onRecordingTimeUpdate: (time: number) => {
            this.recordingTime = time;
          },
          onMinMaxAvgCurrent: (min: number, max: number, avg: number, current: number) => {
            this.minDecibel = min;
            this.maxDecibel = max;
            this.avgDecibel = avg;
            this.currentDecibel = current;
          },
        })

        GridCol({
          span: {
            xs: 12,
            sm: 12,
            md: 5,
          }
        }) {
          Column({ space: 8 }) {

            // 使用新的分贝显示组件（简化版，只负责显示）
            DecibelDisplayComponent({
              currentDecibel: this.currentDecibel,
              minDecibel: this.minDecibel, // 这些值现在由AudioController管理
              maxDecibel: this.maxDecibel, // 这些值现在由AudioController管理
              avgDecibel: this.avgDecibel, // 这些值现在由AudioController管理
              weightingType: this.pk.weighting_type,
              calibrationValue: this.pk.calibration_value,
              noiseThreshold: this.pk.noise_threshold,
              noiseAlarmEnabled: this.pk.noise_alarm_enabled,
              isNoiseAlarm: false // 报警状态由AudioController管理
            })

            Text(`${secondsToHoursMinutesSecondsWithDecimal(60 * 60_000 - this.recordingTime)} 后自动保存`).fontSize(14)

            // 位置显示
            LocationDisplay({
              onLocationUpdate: (locationInfo: LocationInfo | null) => {
                // 更新本地位置状态
                this.currentLocation = locationInfo;
                console.info('[FREQ_TRACE][Location] 位置更新事件接收:', locationInfo);
              }
            })

            if (["md", "lg", "xl", "xxl"].includes(this.breakPoint)) {
              this.actionPanel()
            }
          }
        }.backgroundColor($r('sys.color.comp_background_primary')).borderRadius(16)

        // 频谱图
        GridCol({
          span: {
            xs: 12,
            sm: 12,
            md: 5,
          }
        }) {
          SpectrumChartComponent({
            spectrumData: this.currentSpectrum,
          })
        }

        GridCol({
          span: {
            xs: 12,
            sm: 12,
            md: 0,
          }
        }) {
          this.actionPanel()
        }.visibility(["md", "lg", "xl", "xxl"].includes(this.breakPoint) ? Visibility.Hidden : Visibility.Visible)

      }
      .padding({ top: 16, bottom: 16 })
      .id('mainNoiseMeterDisplayId')
      .onBreakpointChange(breakPoints => {
        // 断点信息现在由 AppStorage 统一管理，这里不再需要处理
        console.info(`[CAT_ANIMATION] GridRow 断点变化: ${breakPoints}`);
      })

      Column()
        .width(this.dWidthHeight)
        .height(this.dWidthHeight)
        .backgroundImage(this.bgImage)
        .scale({ x: this.dScale, y: this.dScale })
        .translate({ x: this.translateX, y: this.translateY })
    }
  }

  @Builder
  smartPermissionPrompt() {
    Row() {
      Image($r('app.media.ic_mic'))
        .width(20)
        .height(20)
        .margin({ right: 8 })

      Column() {
        Text('需要麦克风权限才能检测噪音')
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_warning'))

        if (!this.pk.microphone_permission_requested) {
          Text('点击按钮授权')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .margin({ top: 2 })
        } else {
          Text('请在系统设置中开启麦克风权限')
            .fontSize(12)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      if (!this.pk.microphone_permission_requested) {
        Button('授权')
          .fontSize(12)
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .onClick(async () => {
            const permissionService = PermissionService.getInstance();
            await permissionService.requestMicrophonePermission();
          })
      } else {
        Button('去设置')
          .fontSize(12)
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .onClick(async () => {
            const permissionService = PermissionService.getInstance();
            await permissionService.openPermissionSettings();
          })
      }
    }
    .padding(12)
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_warning_secondary'))
    .borderRadius(8)
    .margin({ top: 8, left: 16, right: 16 })
  }

  @Builder
  errorMessagesDisplay() {
    Column({ space: 8 }) {
      ForEach(this.errorMessages, (errorMsg: string, index: number) => {
        Row() {
          Image($r('sys.media.ic_grid_unknown'))
            .width(16)
            .height(16)
            .margin({ right: 8 })
            .fillColor($r('sys.color.ohos_id_color_warning'))

          Text(errorMsg)
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_warning'))
            .flexShrink(1)

          Blank()

          Button('关闭')
            .fontSize(12)
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .onClick(() => {
              // 移除特定错误消息
              this.errorMessages.splice(index, 1);
            })
        }
        .padding(12)
        .width('100%')
        .backgroundColor($r('sys.color.comp_background_warning_secondary'))
        .borderRadius(8)
        .border({
          width: 1,
          color: $r('sys.color.ohos_id_color_warning')
        })
      })
    }
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  actionPanel() {
    ActionPanel({
      weightingType: this.pk.weighting_type,
      onReset: () => {
        // 重置功能由AudioController处理
        // 这里可以添加重置UI状态的逻辑
      },
      onSave: (comments) => {
        this.bgImage = this.getUIContext().getComponentSnapshot().getSync('mainNoiseMeterDisplayId');
        // 保存功能由AudioController处理
        // 这里只处理UI动画
        this.startCollapseAnimation();
      }
    })
  }

  // 启动折叠动画
  startCollapseAnimation() {
    // 获取屏幕尺寸
    const displayClass = display.getDefaultDisplaySync();
    this.dWidthHeight = '100%';
    // 页面内容动画
    this.getUIContext().animateTo({
      duration: 800,
      curve: curves.cubicBezier(0.4, 0.0, 0.2, 1.0),
      onFinish: () => {
        this.dScale = 1;
        this.translateX = 0;
        this.translateY = 0;
        this.bgImage = undefined;
        this.dWidthHeight = '';
        DialogHub.getToast()
          .setTextContent('已保存')
          .setAnimation({
            dialogAnimation: TransitionEffect.scale({ x: 0, y: 0 })
              .combine(TransitionEffect.OPACITY)
              .animation({
                curve: curves.springMotion()
              })
          })
          .setConfig({
            dialogBehavior: { levelMode: LevelMode.EMBEDDED },
            dialogPosition: {
              offset: {
                dx: this.getUIContext().px2vp(displayClass.width) / 2 - 85,
                dy: -this.getUIContext().px2vp(displayClass.height) / 2 + 120
              }
            }
          })
          .build()
          .show();
      }
    }, () => {
      this.dScale = 0.05;
      this.translateX = this.getUIContext().px2vp(displayClass.width) / 2 - 80;
      this.translateY = -this.getUIContext().px2vp(displayClass.height) / 2 + 20;
    });

  }
}
