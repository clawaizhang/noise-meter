import { AppStorageV2, promptAction } from '@kit.ArkUI';
import { DecibelState } from '../../types/DecibelState';
import { PreferenceService, PreferenceValue } from '../../services/PreferenceService';
import { getWeightingDescription, WeightingType } from '../../constants/WeightingConstants';
import { AudioAnalysisMode, AudioPresets } from '../../common/AudioConfig';
import { PreferenceKeyConstants } from '../../constants/PreferenceKeyConstants';
import { navigationStack } from '../../constants/ProviderConstant';
import {
  responsiveLayout,
  responsiveFontSize,
  responsiveIconSize,
  responsiveListItemSpacing,
  responsiveListItemPadding,
  responsiveListItemMargin,
  responsiveListItemWidth,
  Breakpoint,
  LayoutMode,
  ListItemLayoutMode
} from '../../utils/ResponsiveLayout';
import { DesignConstants } from '../../constants/DesignConstants';

@Extend(Image)
function itemIcon() {
  .width(responsiveIconSize(DesignConstants.ICON_SIZE_MD))
  .height(responsiveIconSize(DesignConstants.ICON_SIZE_MD))
  .margin({ right: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
}

@Extend(Text)
function itemTitle() {
  .fontWeight(FontWeight.Medium)
  .fontColor($r('app.color.text_primary'))
  .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_LG))
}

@Extend(Text)
function itemDescription() {
  .fontColor($r('app.color.text_secondary'))
  .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
  .textAlign(TextAlign.Start)
  .width('100%')
  .margin({ left: responsiveListItemSpacing(DesignConstants.SPACING_XL) })
}

@Extend(Select)
function selectStyle() {
  .backgroundColor($r('app.color.background_secondary'))
  .borderRadius(responsiveListItemSpacing(DesignConstants.BORDER_RADIUS_LG))
  .padding({
    left: responsiveListItemPadding(DesignConstants.SPACING_MD),
    right: responsiveListItemPadding(DesignConstants.SPACING_MD)
  })
  .font({
    size: responsiveFontSize(DesignConstants.FONT_SIZE_MD),
    weight: FontWeight.Normal,
    family: 'HarmonyHeiTi'
  })
  .selectedOptionFont({
    size: responsiveFontSize(DesignConstants.FONT_SIZE_MD),
    weight: FontWeight.Normal,
    family: 'HarmonyHeiTi'
  })
  .optionFont({
    size: responsiveFontSize(DesignConstants.FONT_SIZE_MD),
    weight: FontWeight.Normal,
    family: 'HarmonyHeiTi'
  })
}

@Extend(Column)
function cardStyle() {
  .backgroundColor($r('app.color.background_secondary'))
  .borderRadius(responsiveListItemSpacing(12))
  .shadow({
    radius: responsiveListItemSpacing(8),
    color: $r('app.color.shadow_medium'),
    offsetX: 0,
    offsetY: responsiveListItemSpacing(2)
  })
  .padding({
    top: responsiveListItemPadding(DesignConstants.SPACING_MD),
    bottom: responsiveListItemPadding(DesignConstants.SPACING_MD),
    left: responsiveListItemPadding(DesignConstants.SPACING_LG),
    right: responsiveListItemPadding(DesignConstants.SPACING_LG)
  })
  .margin({
    top: responsiveListItemMargin(DesignConstants.SPACING_MD),
    bottom: responsiveListItemMargin(DesignConstants.SPACING_MD),
    left: responsiveListItemMargin(DesignConstants.SPACING_MD),
    right: responsiveListItemMargin(DesignConstants.SPACING_MD)
  })
}

@Extend(Column)
function listItemStyle() {
  .width('100%')
  .padding({
    left: responsiveListItemPadding(DesignConstants.SPACING_LG),
    right: responsiveListItemPadding(DesignConstants.SPACING_LG)
  })
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(Row)
function listItemRow() {
  .width('100%')
  .height(responsiveListItemSpacing(56))
  .alignItems(VerticalAlign.Center)
}

@Extend(Text)
function detailText() {
  .fontColor($r('app.color.text_secondary'))
  .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
  .margin({
    top: responsiveListItemSpacing(DesignConstants.SPACING_XS),
    left: responsiveListItemSpacing(DesignConstants.SPACING_XL)
  })
}

@Extend(ListItem)
function dividerStyle() {
  .width('100%')
  .height(1)
  .backgroundColor($r('app.color.background_secondary'))
}

@Extend(ListItem)
function descriptionContainer() {
  .backgroundColor($r('app.color.background_secondary'))
  .padding({
    top: responsiveListItemPadding(DesignConstants.SPACING_SM),
    bottom: responsiveListItemPadding(DesignConstants.SPACING_MD)
  })
}

@Extend(Text)
function analysisDescription() {
  .fontColor($r('app.color.text_secondary'))
  .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
  .textAlign(TextAlign.Start)
}

@Extend(Text)
function analysisDetail() {
  .fontColor($r('app.color.text_secondary'))
  .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
  .textAlign(TextAlign.Start)
  .margin({ top: responsiveListItemSpacing(DesignConstants.SPACING_SM) })
}

@ComponentV2
export struct AudioAnalysisSettings {
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  @Local selectedWeighting: WeightingType = WeightingType.A;
  @Local selectedAnalysisMode: AudioAnalysisMode = AudioAnalysisMode.FAST_TIME_WEIGHTING;
  @Local analysisModeDescription: string = '';
  @Local analysisModeDetails: string[] = [];
  @Local isModeChangeEnabled: boolean = true;
  @Local remainingTime: number = 0;
  @Local calibrationValue: number = 0;
  @Local isAutoCalibrating: boolean = false;
  @Local countdown: number = 0;
  @Local calibrationProgress: number = 0;
  @Local decibelState: DecibelState = AppStorageV2.connect(DecibelState, 'DecibelState', () => new DecibelState())!;
  @Local currentListItemLayoutMode: ListItemLayoutMode = ListItemLayoutMode.LIST;
  @Local isLandscape: boolean = false;
  @Local gridColumns: number = 1;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  private readonly COOLDOWN_DURATION: number = 500; // 0.5秒冷却时间

  // 工具方法
  private getWeightingIndex(type: WeightingType): number {
    switch (type) {
      case WeightingType.A:
        return 0;
      case WeightingType.C:
        return 1;
      case WeightingType.Z:
        return 2;
      default:
        return 0;
    }
  }

  private getWeightingType(index: number): WeightingType {
    switch (index) {
      case 0:
        return WeightingType.A;
      case 1:
        return WeightingType.C;
      case 2:
        return WeightingType.Z;
      default:
        return WeightingType.A;
    }
  }

  private getAnalysisModeIndex(mode: AudioAnalysisMode): number {
    switch (mode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        return 0;
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        return 1;
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        return 2;
      default:
        return 0;
    }
  }

  private getAnalysisModeFromIndex(index: number): AudioAnalysisMode {
    switch (index) {
      case 0:
        return AudioAnalysisMode.FAST_TIME_WEIGHTING;
      case 1:
        return AudioAnalysisMode.SLOW_TIME_WEIGHTING;
      case 2:
        return AudioAnalysisMode.IMPULSE_TIME_WEIGHTING;
      default:
        return AudioAnalysisMode.FAST_TIME_WEIGHTING;
    }
  }

  private getAnalysisModeDisplayName(mode: AudioAnalysisMode): string {
    switch (mode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        return '快速(F)';
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        return '慢速(S)';
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        return '脉冲(I)';
      default:
        return '快速(F)';
    }
  }

  private getAnalysisModeDescription(mode: AudioAnalysisMode): string {
    switch (mode) {
      case AudioAnalysisMode.FAST_TIME_WEIGHTING:
        return '时间常数200ms，适合测量快速变化的噪声';
      case AudioAnalysisMode.SLOW_TIME_WEIGHTING:
        return '时间常数500ms，适合测量稳态噪声';
      case AudioAnalysisMode.IMPULSE_TIME_WEIGHTING:
        return '时间常数35ms，适合测量脉冲噪声';
      default:
        return '时间常数200ms，适合测量快速变化的噪声';
    }
  }

  aboutToAppear() {
    this.selectedWeighting =
      (this.preferenceService.getString(PreferenceKeyConstants.WEIGHTING) || WeightingType.A) as WeightingType;
    this.selectedAnalysisMode = (this.preferenceService.getString(PreferenceKeyConstants.ANALYSIS_MODE) ||
    AudioAnalysisMode.FAST_TIME_WEIGHTING) as AudioAnalysisMode;
    this.calibrationValue = this.preferenceService.getNumber(PreferenceKeyConstants.CALIBRATION) || 0;
    this.updateAnalysisModeCache();

    // 初始化响应式布局
    this.initializeResponsiveLayout();

    this.preferenceService.addChangeListener(PreferenceKeyConstants.WEIGHTING,
      (key: string, value: PreferenceValue) => {
        this.selectedWeighting = value as WeightingType;
      })
  }

  /**
   * 初始化响应式布局监听
   */
  private initializeResponsiveLayout(): void {
    // 获取初始布局模式
    const screenInfo = responsiveLayout.getCurrentScreenInfo();
    this.currentListItemLayoutMode = screenInfo.listItemLayoutMode;
    this.isLandscape = screenInfo.isLandscape;
    this.updateGridColumns();

    // 注册布局变化监听器
    responsiveLayout.addChangeListener((width: number, height: number, breakpoint: Breakpoint,
      layoutMode: LayoutMode, listItemLayoutMode: ListItemLayoutMode, isLandscape: boolean) => {
      this.currentListItemLayoutMode = listItemLayoutMode;
      this.isLandscape = isLandscape;
      this.updateGridColumns();
    });
  }

  /**
   * 根据布局模式和屏幕宽度更新网格列数
   */
  private updateGridColumns(): void {
    // 获取当前屏幕宽度
    const screenInfo = responsiveLayout.getCurrentScreenInfo();
    const screenWidth = screenInfo.width;

    switch (this.currentListItemLayoutMode) {
      case ListItemLayoutMode.GRID:
        // 根据屏幕宽度动态计算列数
        if (screenWidth >= 1200) { // XL断点及以上
          this.gridColumns = this.isLandscape ? 4 : 3;
        } else if (screenWidth >= 840) { // LG断点
          this.gridColumns = this.isLandscape ? 3 : 2;
        } else if (screenWidth >= 600) { // MD断点
          this.gridColumns = this.isLandscape ? 2 : 2;
        } else { // SM和XS断点
          this.gridColumns = 1; // 小屏幕使用单列
        }


        break;
      case ListItemLayoutMode.DETAIL:
        this.gridColumns = 1; // 详情布局使用1列
        break;
      case ListItemLayoutMode.COMPACT:
        // 紧凑模式下根据屏幕宽度调整列数
        if (screenWidth >= 840) {
          this.gridColumns = 4;
        } else if (screenWidth >= 600) {
          this.gridColumns = 3;
        } else {
          this.gridColumns = 2;
        }
        break;
      default:
        this.gridColumns = 1; // 列表布局使用1列
    }
  }

  /**
   * 根据列数生成网格模板字符串
   */
  private getGridColumnsTemplate(): string {
    return Array(this.gridColumns).fill('1fr').join(' ');
  }

  private updateAnalysisModeCache() {
    this.analysisModeDescription = this.getAnalysisModeDescription(this.selectedAnalysisMode);
    const config = AudioPresets.getConfig(this.selectedAnalysisMode);
    this.analysisModeDetails = [
      `FFT大小: ${config.fftSize}`,
      `频率分辨率: ${(44100 / config.fftSize).toFixed(1)}Hz`,
      `时间分辨率: ${(config.fftSize / 44100 * 1000).toFixed(1)}ms`,
      `更新间隔: ${config.updateInterval}ms`
    ];
  }

  private startAutoCalibration() {
    this.isAutoCalibrating = true;
    this.countdown = 3;

    // 5秒倒计时
    const countdownInterval = setInterval(() => {
      this.countdown -= 1;
      if (this.countdown <= 0) {
        clearInterval(countdownInterval);
        this.beginCalibration();
      }
    }, 1000);
  }

  private beginCalibration() {
    const calibrationDuration = 8; // 8秒校准
    this.calibrationProgress = 0;
    let totalDecibel = 0;
    let sampleCount = 0;

    // 开始校准
    const calibrationInterval = setInterval(() => {
      this.calibrationProgress += 1;
      totalDecibel += this.decibelState.currentDecibel;
      sampleCount += 1;

      if (this.calibrationProgress >= calibrationDuration) {
        clearInterval(calibrationInterval);
        this.finishCalibration(totalDecibel / sampleCount);
      }
    }, 1000);
  }

  private finishCalibration(averageDecibel: number) {
    this.isAutoCalibrating = false;
    const newCalibrationValue = 26 - averageDecibel; // 计算与26dB的差值
    this.calibrationValue = Math.round(newCalibrationValue * 10) / 10; // 保留1位小数
    void this.preferenceService.setNumber(PreferenceKeyConstants.CALIBRATION, this.calibrationValue);

    promptAction.showToast({
      message: `自动校准完成，新校准值: ${this.calibrationValue}dB`,
      duration: 3000
    });
  }

  build() {
    NavDestination() {

      Column() {
        // 添加Scroll组件包裹主要内容
        Scroll() {
          Column() {
            // 根据布局模式选择不同的容器
            if (this.currentListItemLayoutMode === ListItemLayoutMode.GRID) {
              // 网格布局 - 使用 GridRow 和 GridCol
              GridRow({
                columns: {
                  xs: 1,
                  sm: 2,
                  md: 3,
                  lg: 4,
                  xl: 5
                },
                gutter: {
                  x: {
                    xs: responsiveListItemSpacing(DesignConstants.SPACING_SM),
                    sm: responsiveListItemSpacing(DesignConstants.SPACING_MD),
                    md: responsiveListItemSpacing(DesignConstants.SPACING_MD),
                    lg: responsiveListItemSpacing(DesignConstants.SPACING_MD),
                    xl: responsiveListItemSpacing(DesignConstants.SPACING_MD)
                  },
                  y: {
                    xs: responsiveListItemSpacing(DesignConstants.SPACING_SM),
                    sm: responsiveListItemSpacing(DesignConstants.SPACING_MD),
                    md: responsiveListItemSpacing(DesignConstants.SPACING_MD),
                    lg: responsiveListItemSpacing(DesignConstants.SPACING_MD),
                    xl: responsiveListItemSpacing(DesignConstants.SPACING_MD)
                  }
                },
                breakpoints: {
                  value: ['320vp', '600vp', '840vp', '1080vp', '1320vp']
                }
              }) {
                // 时间计权模式
                GridCol({
                  span: {
                    xs: 1,
                    sm: 1,
                    md: 1,
                    lg: 1,
                    xl: 1
                  }
                }) {
                  Column() {
                    Row() {
                      Row() {
                        Image($r('app.media.ic_time_weighting'))
                          .itemIcon()

                        Text('时间计权模式')
                          .itemTitle()
                      }

                      Blank()

                      Row() {
                        Text(this.remainingTime > 0 ? `${(this.remainingTime / 1000).toFixed(1)}秒` : '')
                          .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
                          .fontColor($r('app.color.text_secondary'))
                          .margin({ right: responsiveListItemSpacing(DesignConstants.SPACING_XS) })

                        Select([
                          { value: '快速(F)' },
                          { value: '慢速(S)' },
                          { value: '脉冲(I)' }
                        ])
                          .selected(this.getAnalysisModeIndex(this.selectedAnalysisMode))
                          .value(this.getAnalysisModeDisplayName(this.selectedAnalysisMode))
                          .selectStyle()

                          .onSelect((index: number) => {
                            if (!this.isModeChangeEnabled) {
                              return;
                            }

                            // 禁用切换
                            this.isModeChangeEnabled = false;

                            const mode = this.getAnalysisModeFromIndex(index);
                            void this.preferenceService.setString(PreferenceKeyConstants.ANALYSIS_MODE, mode);
                            this.selectedAnalysisMode = mode;
                            this.updateAnalysisModeCache();

                            // 启动冷却计时器
                            this.remainingTime = this.COOLDOWN_DURATION;
                            const interval = setInterval(() => {
                              this.remainingTime -= 100;
                              if (this.remainingTime <= 0) {
                                clearInterval(interval);
                                this.isModeChangeEnabled = true;
                                this.remainingTime = 0;
                              }
                            }, 100);
                          })
                          .enabled(this.isModeChangeEnabled)
                      }
                    }
                    .listItemRow()

                    // 描述信息
                    Column() {
                      Text(this.analysisModeDescription)
                        .analysisDescription()
                      ForEach(this.analysisModeDetails, (detail: string) => {
                        Text(detail)
                          .analysisDetail()
                      })
                    }
                    .width('100%')
                    .alignItems(HorizontalAlign.Start)
                    .padding({ left: responsiveListItemSpacing(DesignConstants.SPACING_XL) })
                    .margin({ top: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
                  }
                  .cardStyle()
                  .width('100%')
                }

                // 频率加权设置
                GridCol({
                  span: {
                    xs: 1,
                    sm: 1,
                    md: 1,
                    lg: 1,
                    xl: 1
                  }
                }) {
                  Column() {
                    Row() {
                      Row() {
                        Image($r('app.media.ic_frequency_weighting'))
                          .itemIcon()

                        Text('频率加权')
                          .itemTitle()
                      }

                      Blank()

                      Select([
                        { value: 'A计权' },
                        { value: 'C计权' },
                        { value: 'Z计权' }
                      ])
                        .selected(this.getWeightingIndex(this.selectedWeighting))
                        .value(this.selectedWeighting + '计权')
                        .selectStyle()
                        .onSelect((index: number) => {
                          const weightingType = this.getWeightingType(index);
                          void this.preferenceService.setString(PreferenceKeyConstants.WEIGHTING, weightingType);
                          this.selectedWeighting = weightingType;
                        })
                    }
                    .listItemRow()

                    // 描述信息
                    Text(getWeightingDescription(this.selectedWeighting))
                      .itemDescription()
                      .margin({ top: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
                  }
                  .cardStyle()
                  .width('100%')
                }

                // 声级校准设置
                GridCol({
                  span: {
                    xs: 1,
                    sm: 1,
                    md: 1,
                    lg: 1,
                    xl: 1
                  }
                }) {
                  Column() {
                    Row() {
                      Row() {
                        Image($r('app.media.ic_calibration'))
                          .itemIcon()

                        Text('声级校准')
                          .itemTitle()
                      }

                      Blank()

                      Text(`${this.calibrationValue}dB`)
                        .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
                        .fontColor($r('app.color.text_secondary'))
                        .margin({ right: responsiveListItemSpacing(DesignConstants.SPACING_SM) })
                    }
                    .listItemRow()

                    Slider({
                      value: this.calibrationValue,
                      min: -30,
                      max: 30,
                      style: SliderStyle.InSet
                    })
                      .blockColor($r('app.color.primary'))
                      .trackColor($r('app.color.background_secondary'))
                      .selectedColor($r('app.color.primary'))
                      .showTips(true, `${this.decibelState.currentDecibel}dB`)
                      .onChange((value: number) => {
                        this.calibrationValue = value;
                        void this.preferenceService.setNumber(PreferenceKeyConstants.CALIBRATION, value);
                      })
                      .margin({
                        top: responsiveListItemSpacing(DesignConstants.SPACING_MD),
                        bottom: responsiveListItemSpacing(DesignConstants.SPACING_MD)
                      })
                      .height(responsiveListItemSpacing(24))
                      .trackThickness(responsiveListItemSpacing(24))
                      .blockSize({
                        width: responsiveListItemSpacing(24),
                        height: responsiveListItemSpacing(24)
                      })

                    // 描述信息
                    Text('手动校准麦克风灵敏度，确保测量精度')
                      .itemDescription()
                      .margin({ top: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
                  }
                  .cardStyle()
                  .width('100%')
                }

                // 自动校准按钮
                GridCol({
                  span: {
                    xs: 1,
                    sm: 1,
                    md: 1,
                    lg: 1,
                    xl: 1
                  }
                }) {
                  Column() {
                    Row() {
                      Row() {
                        Image($r('app.media.ic_calibration'))
                          .itemIcon()

                        Text('自动校准')
                          .itemTitle()
                      }

                      Blank()

                      if (this.isAutoCalibrating) {
                        Text(this.countdown > 0 ? `${this.countdown}秒后开始校准` :
                          `校准中,请保持安静...${8 - this.calibrationProgress}秒`)
                          .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
                          .fontColor($r('app.color.text_secondary'))
                          .margin({ right: responsiveListItemSpacing(DesignConstants.SPACING_SM) })
                      } else {
                        Button('开始校准')
                          .type(ButtonType.Normal)
                          .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
                          .backgroundColor($r('app.color.primary'))
                          .borderRadius(responsiveListItemSpacing(DesignConstants.BORDER_RADIUS_LG))
                          .height(responsiveListItemSpacing(32))
                          .width(responsiveListItemSpacing(90))
                          .onClick(async () => {
                            const result = await promptAction.showDialog({
                              title: '自动校准提示',
                              message: '请在非常安静的房间中进行自动校准，特别是夜间效果最佳',
                              buttons: [
                                {
                                  text: '取消',
                                  color: $r('app.color.text_disabled')
                                },
                                {
                                  text: '确认',
                                  color: $r('app.color.primary')
                                }
                              ]
                            });

                            // 根据用户选择处理
                            if (result.index === 1) { // 确认按钮
                              this.startAutoCalibration();
                            }
                          })
                      }
                    }
                    .listItemRow()

                    // 描述信息
                    Text('自动计算并设置校准值')
                      .itemDescription()
                      .margin({ top: responsiveListItemSpacing(DesignConstants.SPACING_MD) })
                  }
                  .cardStyle()
                  .width('100%')
                }
              }
              .width('100%')
              .padding({
                left: responsiveListItemPadding(DesignConstants.SPACING_MD),
                right: responsiveListItemPadding(DesignConstants.SPACING_MD),
                top: responsiveListItemPadding(DesignConstants.SPACING_MD),
                bottom: responsiveListItemPadding(DesignConstants.SPACING_MD)
              })
            } else {
              // 列表布局（保持原有代码）
              List() {
                // 时间计权模式
                ListItem() {
                  Column() {
                    Row() {
                      Row() {
                        Image($r('app.media.ic_time_weighting'))
                          .itemIcon()

                        Text('时间计权模式')
                          .itemTitle()
                      }

                      Blank()

                      Row() {
                        Text(this.remainingTime > 0 ? `${(this.remainingTime / 1000).toFixed(1)}秒` : '')
                          .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
                          .fontColor($r('app.color.text_secondary'))
                          .margin({ right: responsiveListItemSpacing(DesignConstants.SPACING_XS) })

                        Select([
                          { value: '快速(F)' },
                          { value: '慢速(S)' },
                          { value: '脉冲(I)' }
                        ])
                          .selected(this.getAnalysisModeIndex(this.selectedAnalysisMode))
                          .value(this.getAnalysisModeDisplayName(this.selectedAnalysisMode))
                          .selectStyle()

                          .onSelect((index: number) => {
                            if (!this.isModeChangeEnabled) {
                              return;
                            }

                            // 禁用切换
                            this.isModeChangeEnabled = false;

                            const mode = this.getAnalysisModeFromIndex(index);
                            void this.preferenceService.setString(PreferenceKeyConstants.ANALYSIS_MODE, mode);
                            this.selectedAnalysisMode = mode;
                            this.updateAnalysisModeCache();

                            // 启动冷却计时器
                            this.remainingTime = this.COOLDOWN_DURATION;
                            const interval = setInterval(() => {
                              this.remainingTime -= 100;
                              if (this.remainingTime <= 0) {
                                clearInterval(interval);
                                this.isModeChangeEnabled = true;
                                this.remainingTime = 0;
                              }
                            }, 100);
                          })
                          .enabled(this.isModeChangeEnabled)
                      }
                    }
                    .listItemRow()
                  }
                  .cardStyle()
                }

                ListItem() {
                  Column() {
                    Text(this.analysisModeDescription)
                      .analysisDescription()
                    ForEach(this.analysisModeDetails, (detail: string) => {
                      Text(detail)
                        .analysisDetail()
                    })
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                  .padding({ left: responsiveListItemSpacing(DesignConstants.SPACING_XL) })
                }
                .descriptionContainer()

                // 分贝计权设置
                ListItem() {
                  Column() {
                    Row() {
                      Row() {
                        Image($r('app.media.ic_frequency_weighting'))
                          .itemIcon()

                        Text('频率加权')
                          .itemTitle()
                      }

                      Blank()

                      Select([
                        { value: 'A计权' },
                        { value: 'C计权' },
                        { value: 'Z计权' }
                      ])
                        .selected(this.getWeightingIndex(this.selectedWeighting))
                        .value(this.selectedWeighting + '计权')
                        .selectStyle()
                        .onSelect((index: number) => {
                          const weightingType = this.getWeightingType(index);
                          void this.preferenceService.setString(PreferenceKeyConstants.WEIGHTING, weightingType);
                          this.selectedWeighting = weightingType;
                        })
                    }
                    .listItemRow()
                  }
                  .cardStyle()
                }

                ListItem() {
                  Text(getWeightingDescription(this.selectedWeighting))
                    .itemDescription()
                }
                .descriptionContainer()

                // 声级校准设置
                ListItem() {
                  Column() {
                    Row() {
                      Row() {
                        Image($r('app.media.ic_calibration'))
                          .itemIcon()

                        Text('声级校准')
                          .itemTitle()
                      }

                      Blank()

                      Text(`${this.calibrationValue}dB`)
                        .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
                        .fontColor($r('app.color.text_secondary'))
                        .margin({ right: responsiveListItemSpacing(DesignConstants.SPACING_SM) })
                    }
                    .listItemRow()

                    Slider({
                      value: this.calibrationValue,
                      min: -30,
                      max: 30,
                      style: SliderStyle.InSet
                    })
                      .blockColor($r('app.color.primary'))
                      .trackColor($r('app.color.background_secondary'))
                      .selectedColor($r('app.color.primary'))
                      .showTips(true, `${this.decibelState.currentDecibel}dB`)
                      .onChange((value: number) => {
                        this.calibrationValue = value;
                        void this.preferenceService.setNumber(PreferenceKeyConstants.CALIBRATION, value);
                      })
                      .margin({
                        top: responsiveListItemSpacing(DesignConstants.SPACING_MD),
                        bottom: responsiveListItemSpacing(DesignConstants.SPACING_MD)
                      })
                      .height(responsiveListItemSpacing(24))
                      .trackThickness(responsiveListItemSpacing(24))
                      .blockSize({
                        width: responsiveListItemSpacing(24),
                        height: responsiveListItemSpacing(24)
                      })
                  }
                  .cardStyle()
                }

                ListItem() {
                  Text('手动校准麦克风灵敏度，确保测量精度')
                    .itemDescription()
                }
                .descriptionContainer()

                // 自动校准按钮
                ListItem() {
                  Column() {
                    Row() {
                      Row() {
                        Image($r('app.media.ic_calibration'))
                          .itemIcon()

                        Text('自动校准')
                          .itemTitle()
                      }

                      Blank()

                      if (this.isAutoCalibrating) {
                        Text(this.countdown > 0 ? `${this.countdown}秒后开始校准` :
                          `校准中,请保持安静...${8 - this.calibrationProgress}秒`)
                          .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
                          .fontColor($r('app.color.text_secondary'))
                          .margin({ right: responsiveListItemSpacing(DesignConstants.SPACING_SM) })
                      } else {
                        Button('开始校准')
                          .type(ButtonType.Normal)
                          .fontSize(responsiveFontSize(DesignConstants.FONT_SIZE_MD))
                          .backgroundColor($r('app.color.primary'))
                          .borderRadius(responsiveListItemSpacing(DesignConstants.BORDER_RADIUS_LG))
                          .height(responsiveListItemSpacing(32))
                          .width(responsiveListItemSpacing(90))
                          .onClick(async () => {
                            const result = await promptAction.showDialog({
                              title: '自动校准提示',
                              message: '请在非常安静的房间中进行自动校准，特别是夜间效果最佳',
                              buttons: [
                                {
                                  text: '取消',
                                  color: $r('app.color.text_disabled')
                                },
                                {
                                  text: '确认',
                                  color: $r('app.color.primary')
                                }
                              ]
                            });

                            // 根据用户选择处理
                            if (result.index === 1) { // 确认按钮
                              this.startAutoCalibration();
                            }
                          })
                      }
                    }
                    .listItemRow()
                  }
                  .cardStyle()
                }

                ListItem() {
                  Text('自动计算并设置校准值')
                    .itemDescription()
                }
                .descriptionContainer()
              }
              .width('100%')
              .layoutWeight(1)
              .backgroundColor('transparent')
            }
          }
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.On)
        .scrollBarWidth(responsiveListItemSpacing(4))
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)

      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_tertiary')).title('音频分析设置')
  }
}

@Builder
export function AudioAnalysisSettingsBuilder() {
  AudioAnalysisSettings()
}