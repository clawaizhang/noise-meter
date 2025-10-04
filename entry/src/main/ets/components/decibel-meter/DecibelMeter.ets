import { navigationStack } from '../../constants/ProviderConstant';
import { AppStorageV2, curves, LevelMode, PersistenceV2 } from '@kit.ArkUI';
import display from '@ohos.display';
import { ActionPanel } from './ActionPanel';
import { SpectrumChartComponent } from './SpectrumChartComponent';
import { DecibelDisplayComponent } from './DecibelDisplayComponent';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { LocationInfo } from '../../services/LocationService';
import { LocationDisplay } from '../business/LocationDisplay';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { resourceManager } from '@kit.LocalizationKit';
import { image } from '@kit.ImageKit';
import { AppKeys } from '../../models/AppKeys';
import { PermissionService } from '../../services/PermissionService';
import { AudioController } from './AudioController';
import { AudioControllerService } from '../../services/AudioControllerService';

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
  @Local private lastAutoSaveTime: number = Date.now();
  @Local private currentTime: number = Date.now();
  @Local private countdownTimer?: number;
  @Local private hideForXsMd: boolean = false;
  // 服务实例
  private audioControllerService: AudioControllerService = AudioControllerService.getInstance();
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll() {
        GridRow({ columns: 12, breakpoints: { reference: BreakpointsReference.WindowSize }, gutter: 16 }) {

          // 音频控制器（逻辑组件，不渲染UI）
          AudioController({
            pk: this.pk,
            currentLocation: this.currentLocation,
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
            onAutoSaveTimeUpdate: (lastSaveTime: number) => {
              this.lastAutoSaveTime = lastSaveTime;
            },
          })

          // 分贝显示面板 - 简化布局策略
          GridCol({
            span: {
              xs: 12, // 横向XS/SM：单列布局（全宽）
              sm: 12, // 横向XS/SM：单列布局（全宽）
              md: 6, // 横向MD及以上：双列布局（半宽）
              lg: 6, // 横向MD及以上：双列布局（半宽）
              xl: 6    // 横向MD及以上：双列布局（半宽）
            }
          }) {
            Column({ space: 8 }) {

              Stack({ alignContent: Alignment.Top }) {
                // 使用新的分贝显示组件（重新设计版）
                DecibelDisplayComponent({
                  currentDecibel: this.currentDecibel,
                  minDecibel: this.minDecibel, // 这些值现在由AudioController管理
                  maxDecibel: this.maxDecibel, // 这些值现在由AudioController管理
                  avgDecibel: this.avgDecibel, // 这些值现在由AudioController管理
                  weightingType: this.pk.weighting_type,
                  calibrationValue: this.pk.calibration_value,
                  noiseThreshold: this.pk.noise_threshold,
                  systemNotificationEnabled: this.pk.system_notification_enabled,
                  isNoiseAlarm: false, // 报警状态由AudioController管理
                  autoSaveCountdown: this.autoSaveCountdown // 传递自动保存倒计时
                })

                Column({ space: 8 }) {
                  // 错误消息显示区域（支持多个错误同时显示）
                  if (this.errorMessages.length > 0) {
                    this.errorMessagesDisplay()
                  }

                  // 权限提示组件 - 显示在顶部
                  if (!this.as.microphonePermissionGranted) {
                    this.smartPermissionPrompt()
                  }
                }.padding(16)
              }

              if (!this.hideForXsMd) {
                // 位置显示 - 调整UI展现方式以适应新设计
                LocationDisplay({
                  onLocationUpdate: (locationInfo: LocationInfo | null) => {
                    // 更新本地位置状态
                    this.currentLocation = locationInfo;
                    console.info('[FREQ_TRACE][Location] 位置更新事件接收:', locationInfo);
                  }
                }).padding({ left: 16, right: 16, bottom: 16 })
              }

            }
          }
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius(16)

          if (!this.hideForXsMd) {
            // 频谱图 - 简化布局策略
            GridCol({
              span: {
                xs: 12, // 横向XS/SM：单列布局（全宽）
                sm: 12, // 横向XS/SM：单列布局（全宽）
                md: 6, // 横向MD及以上：双列布局（半宽）
                lg: 6, // 横向MD及以上：双列布局（半宽）
                xl: 6    // 横向MD及以上：双列布局（半宽）
              }
            }) {
              SpectrumChartComponent({
                spectrumData: this.currentSpectrum,
              })
            }
          }
        }
        .padding({ bottom: 80 }) // 增加底部内边距为操作按钮留出空间
        .id('mainNoiseMeterDisplayId')
        .onBreakpointChange(breakPoints => {
          // 断点信息现在由 AppStorage 统一管理，这里不再需要处理
          console.info(`[CAT_ANIMATION] GridRow 断点变化: ${breakPoints}`);
        })
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      Column()
        .width(this.dWidthHeight)
        .height(this.dWidthHeight)
        .backgroundImage(this.bgImage)
        .scale({ x: this.dScale, y: this.dScale })
        .translate({ x: this.translateX, y: this.translateY })

      if (!this.hideForXsMd) {
        this.actionPanel()
      }
    }.margin({ top: 16 })
  }

  aboutToDisappear() {
    // 清理资源
    this.audioControllerService.dispose();
    // 停止倒计时更新定时器
    this.stopCountdownTimer();
  }

  @Monitor('as.windowWidth','as.windowHeight')
  onWindowSizeChange(monitor: IMonitor) {
    // 获取当前窗口尺寸
    this.calculateSize();
  }

  private calculateSize() {
    if (this.as.windowWidthBreakpoint <= WidthBreakpoint.WIDTH_SM &&
      this.as.windowHeightBreakpoint <= HeightBreakpoint.HEIGHT_MD) {
      this.hideForXsMd = true;
    } else {
      this.hideForXsMd = false;
    }
  }

  aboutToAppear() {
    // 获取当前窗口尺寸
    this.calculateSize();
    // 启动倒计时更新定时器
    this.currentTime = Date.now();
    this.countdownTimer = setInterval(() => {
      this.currentTime = Date.now();
    }, 1000)
  }

  private stopCountdownTimer() {
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer);
      this.countdownTimer = undefined;
    }
  }

  @Computed
  get autoSaveCountdown(): string {
    if (!this.pk.auto_save_enabled) {
      return '自动保存已禁用';
    }

    // 计算剩余时间
    const elapsed = this.currentTime - this.lastAutoSaveTime;
    const intervalMs = this.pk.auto_save_interval * 60 * 1000;
    const remaining = Math.max(0, intervalMs - elapsed);

    if (remaining <= 0) {
      return '即将自动保存';
    }

    const minutes = Math.floor(remaining / 60000);
    const seconds = Math.floor((remaining % 60000) / 1000);

    return `${minutes}:${seconds.toString().padStart(2, '0')} 后自动保存`;
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
          .padding({
            left: 16,
            right: 16,
            top: 6,
            bottom: 6
          })
          .onClick(async () => {
            const permissionService = PermissionService.getInstance();
            await permissionService.requestMicrophonePermission();
          })
      } else {
        Button('去设置')
          .fontSize(12)
          .padding({
            left: 16,
            right: 16,
            top: 6,
            bottom: 6
          })
          .onClick(async () => {
            const permissionService = PermissionService.getInstance();
            await permissionService.openPermissionSettings();
          })
      }
    }
    .padding(16)
    .width('100%')
    .backgroundColor($r('sys.color.comp_background_warning_secondary'))
    .borderRadius(16)
    .margin(16)
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
            .layoutWeight(1)

          Blank()

          Button('关闭')
            .fontSize(12)
            .type(ButtonType.Capsule)
            .onClick(() => {
              // 移除特定错误消息
              this.errorMessages.splice(index, 1);
            })
        }
        .width('100%')
        .backgroundColor($r('sys.color.comp_background_warning_secondary'))
        .borderRadius(8)
        .padding(8)
      })
    }.margin({ top: 16 })
  }

  @Builder
  actionPanel() {
    ActionPanel({
      weightingType: this.pk.weighting_type,
      onReset: () => {
        // 重置功能由AudioController处理
        // 通过服务触发重置事件
        this.audioControllerService.resetData();
        // 这里可以添加重置UI状态的逻辑
      },
      onSave: (comments) => {
        this.bgImage = this.getUIContext().getComponentSnapshot().getSync('mainNoiseMeterDisplayId');
        // 保存功能由AudioController处理
        // 通过服务触发保存事件
        this.audioControllerService.saveData(comments);
        // 这里只处理UI动画
        this.startCollapseAnimation();
      }
    })
  }

  // 启动折叠动画
  startCollapseAnimation() {
    // 获取屏幕尺寸
    const displayClass = display.getDefaultDisplaySync();
    this.dWidthHeight = '120%';
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
