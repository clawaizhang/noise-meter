import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, curves, PersistenceV2, promptAction } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { navigationStack } from '../../constants/ProviderConstant';
import { Throttle } from '../../utils/Debounce';
import { common } from '@kit.AbilityKit';
import { DecibelRecordService } from '../../services/DecibelRecordService';
import { AudioControllerService } from '../../services/AudioControllerService';
import { LocationInfo, LocationService } from '../../services/LocationService';
import { AudioControllerLifecycleState, StateTransitionEvent } from '../../models/AudioControllerLifecycleState';
import { StatusAlertsComponent } from '../status-alerts/StatusAlertsComponent';
import { DecibelService } from '../../services/DecibelService';
import { SpringFestivalConstants } from '../../constants/SpringFestivalConstants';
import { DialogHub, type InfSheet } from '@hadss/dialoghub';
import { BenefitActivityDialogBuilder, BenefitActivityDialogProps } from '../membership/BenefitActivityDialog';
import { DashboardHomeCard } from './DashboardHomeCard';
import { InputDialog } from '../decibel-meter/InputDialog';

// 功能卡片配置接口
interface FunctionCardConfig {
  title: string;
  icon: Resource;
  description: string;
  dataDisplay?: string;
  dataColor?: Resource;
  badgeCount?: number;
  onTap: () => void;
}

// Tab切换事件接口
interface TabSwitchEvent {
  tabIndex: number;
}

@ComponentV2
export struct HomePageContent {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();
  @Local private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @Local private currentLocation: LocationInfo | null = null;
  @Local private isLocationRefreshing: boolean = false;
  @Local private controllerState: AudioControllerLifecycleState = AudioControllerLifecycleState.CONTROLLER_IDLE;
  @Local private saveAnimationOpacity: number = 1.0;
  private decibelRecordService: DecibelRecordService = new DecibelRecordService(this.context);
  private locationService: LocationService = LocationService.getInstance();
  private audioControllerService: AudioControllerService = AudioControllerService.getInstance(this.ak, this.pk);
  private inputDialogController: CustomDialogController = new CustomDialogController({
    builder: this.buildSaveInputDialog,
    cancel: () => { },
    autoCancel: true
  });
  private confirmDialogController: CustomDialogController = new CustomDialogController({
    builder: this.buildResetConfirmDialog,
    cancel: () => { },
    autoCancel: true
  });
  private stopConfirmDialogController: CustomDialogController = new CustomDialogController({
    builder: this.buildStopConfirmDialog,
    cancel: () => { },
    autoCancel: true
  });
  
  // 抽签活动弹窗
  private benefitActivityDialog?: InfSheet;

  build() {
    Scroll() {
      // 减小间距，让卡片之间更紧凑
      Column({ space: DesignConstants.SPACING_MD }) {
        // 马年抽签活动入口（最顶部）
        this.buildNewYearActivityCard()
        
        StatusAlertsComponent()

        // 主页仪表卡片（频谱分析）- 放在分贝显示上方
        DashboardHomeCard()
          .transition(TransitionEffect.scale({ x: 0.95, y: 0.95 }).animation({ curve: curves.springMotion() }))

        // 核心分贝显示区 + 音频控制整合
        this.buildCombinedDecibelControlCard()
        // 功能入口卡片区
        this.buildFunctionCards()
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
  
  @Builder
  private buildCombinedDecibelControlCard() {
    Row({ space: 0 }) {
      // 左侧：分贝显示区域（上下分布）
      Column() {
        // 上半部分：分贝值垂直居中（大数字+小dB）
        Column() {
          if (this.ak.uiDisplayState.displayDb > 0) {
            Row({ space: 0 }) {
              Text(`${this.ak.uiDisplayState.displayDb}`)
                .fontSize(64)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.decibelColor)
                .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }));
              
              Text('dB')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.decibelColor)
                .opacity(0.8)
                .margin({ left: 2, bottom: 10 })
                .alignSelf(ItemAlign.End)
            }
          } else {
            Row({ space: 0 }) {
              Text('--')
                .fontSize(52)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('sys.color.font_secondary'))
                .transition(TransitionEffect.scale({ x: 0, y: 0 }).animation({ curve: curves.springMotion() }));
              
              Text('dB')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.font_secondary'))
                .opacity(0.8)
                .margin({ left: 2, bottom: 10 })
                .alignSelf(ItemAlign.End)
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 下半部分：位置信息（与右侧按钮对齐）
        Column() {
          this.buildExpandableLocationInfo()
        }
        .width('100%')
        .height(70)
        .justifyContent(FlexAlign.End)
        .alignItems(HorizontalAlign.Center)
      }
      .width('40%')
      .height('100%')
      .padding({ top: DesignConstants.SPACING_MD, bottom: DesignConstants.SPACING_MD })

      // 分隔线
      Column()
        .width(1)
        .height('80%')
        .backgroundColor($r('sys.color.comp_divider'))
        .alignSelf(ItemAlign.Center)

      // 右侧：音频控制区域（上下分布）
      Column() {
        // 上半部分：状态指示器
        Column() {
          this.buildStatusIndicator()
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        // 下半部分：控制按钮（与左侧位置信息对齐）
        Column() {
          this.buildControlButtons()
        }
        .width('100%')
        .height(70)
        .justifyContent(FlexAlign.End)
      }
      .width('60%')
      .height('100%')
      .padding({ left: DesignConstants.SPACING_LG, right: DesignConstants.SPACING_LG, 
                 top: DesignConstants.SPACING_MD, bottom: DesignConstants.SPACING_MD })
    }
    .width('100%')
    .height(140)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_XL)
    .shadow(DesignConstants.SHADOW_SM)
  }

  // 状态指示器（带圆点）
  @Builder
  private buildStatusIndicator() {
    Row({ space: DesignConstants.SPACING_XS }) {
      // 状态圆点（动态颜色）
      Stack() {
        Circle()
          .width(8)
          .height(8)
          .fill(this.detectionStatusColor)
          .shadow({
            radius: 4,
            color: this.detectionStatusColor,
            offsetX: 0,
            offsetY: 0
          })
        
        // 检测中时显示脉动动画效果
        if (this.isDetectionRecording) {
          Circle()
            .width(8)
            .height(8)
            .fill(this.detectionStatusColor)
            .opacity(0.5)
            .scale({ x: 1.5, y: 1.5 })
            .animation({
              duration: 1000,
              curve: Curve.EaseInOut,
              iterations: -1,
              playMode: PlayMode.Alternate
            })
        }
      }
      .width(12)
      .height(12)
      .alignSelf(ItemAlign.Center)

      // 状态文字
      Text(this.detectionStatusText)
        .fontSize(13)
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)

      Blank()

      // 计时显示（更突出）
      Row({ space: 4 }) {
        Image($r('app.media.ic_history'))
          .width(12)
          .height(12)
          .fillColor($r('sys.color.font_secondary'))
        Text(this.ak.uiDisplayState.timeDisplay)
          .fontSize(13)
          .fontColor($r('sys.color.font_secondary'))
          .fontWeight(FontWeight.Medium)
          .fontFamily('HarmonyOS Sans Digit')
      }
    }
    .width('100%')
    .height(26)
    .padding({ left: 4, right: 4 })
  }

  // 控制按钮区域（紧凑排布）
  @Builder
  private buildControlButtons() {
    // 主操作按钮（开始/停止）
    if (this.isDetectionIdle || this.isDetectionError) {
      // 空闲状态：显示开始按钮
      Button({ type: ButtonType.Capsule }) {
        Row({ space: 4 }) {
          Image($r('app.media.ic_play'))
            .width(14)
            .height(14)
            .fillColor(Color.White)
          Text('开始检测')
            .fontSize(13)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .height(32)
      .backgroundColor($r('sys.color.font_emphasize'))
      .onClick(() => {
        Throttle.click(() => this.startDetection());
      })
    } else {
      // 运行状态：显示停止+重置+保存
      Column({ space: DesignConstants.SPACING_SM }) {
        // 停止按钮（主要）
        Button({ type: ButtonType.Capsule }) {
          Row({ space: 4 }) {
            Image($r('app.media.ic_stop'))
              .width(14)
              .height(14)
              .fillColor(Color.White)
            Text('停止检测')
              .fontSize(13)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
          }
        }
        .width('100%')
        .height(32)
        .backgroundColor($r('sys.color.alert'))
        .enabled(this.isDetectionRecording)
        .onClick(() => {
          Throttle.click(() => this.showStopConfirmation());
        })

        // 次要操作按钮行（与停止按钮同高）
        Row({ space: DesignConstants.SPACING_SM }) {
          // 重置按钮（图标+文字）
          Button({ type: ButtonType.Capsule }) {
            Row({ space: 4 }) {
              Image($r('app.media.ic_refresh'))
                .width(14)
                .height(14)
                .fillColor($r('sys.color.font_primary'))
              Text('重置')
                .fontSize(12)
                .fontColor($r('sys.color.font_primary'))
            }
          }
          .layoutWeight(1)
          .height(32)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .onClick(() => {
            Throttle.click(() => this.showResetConfirmation());
          })

          // 保存按钮（图标+文字）
          Button({ type: ButtonType.Capsule }) {
            Row({ space: 4 }) {
              Image($r('app.media.ic_save'))
                .width(14)
                .height(14)
                .fillColor(this.isDetectionRecording ? Color.White : $r('sys.color.font_secondary'))
              Text('保存')
                .fontSize(12)
                .fontColor(this.isDetectionRecording ? Color.White : $r('sys.color.font_secondary'))
            }
          }
          .layoutWeight(1)
          .height(32)
          .backgroundColor(this.isDetectionRecording ? $r('sys.color.confirm') : $r('sys.color.comp_background_secondary'))
          .enabled(this.isDetectionRecording)
          .opacity(this.saveAnimationOpacity)
          .onClick(() => {
            Throttle.click(() => this.showSaveDialog());
          })
        }
        .width('100%')
      }
      .width('100%')
    }
  }

  // 可展开的位置信息
  @Builder
  private buildExpandableLocationInfo() {
    Row({ space: DesignConstants.SPACING_XS }) {
      Image($r('app.media.ic_location'))
        .width(12)
        .height(12)
        .fillColor($r('sys.color.icon_secondary'))
      Text(this.locationStatusShort)
        .fontSize(11)
        .fontColor(this.locationStatusColor)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      
      // 刷新按钮
      if (this.pk.location_enabled) {
        this.locationRefreshButton()
      }
      
      // 展开提示图标
      if (this.canExpandLocation) {
        Image($r('app.media.ic_arrow_right'))
          .width(10)
          .height(10)
          .fillColor($r('sys.color.icon_tertiary'))
          .rotate({ angle: 90 }) // 旋转箭头向下
      }
    }
    .width('92%')
    .height(28)
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .justifyContent(FlexAlign.Center)
    .bindMenu(this.buildLocationDetailMenu, { placement: Placement.Bottom })
  }

  // 位置刷新按钮
  @Builder
  private locationRefreshButton() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Image($r("app.media.solar_refresh_circle_bold"))
        .width(12)
        .height(12)
        .fillColor($r('sys.color.icon_secondary'))
        .rotate({
          angle: this.isLocationRefreshing ? 360 : 0,
          centerX: '50%',
          centerY: '50%'
        })
        .animation({
          duration: this.isLocationRefreshing ? 1000 : 0,
          iterations: this.isLocationRefreshing ? -1 : 0,
          curve: Curve.Linear
        });
    }
    .width(18)
    .height(18)
    .backgroundColor(Color.Transparent)
    .enabled(!this.isLocationRefreshing)
    .onClick(() => {
      Throttle.click(() => {
        this.refreshLocation();
      });
    })
  }

  // 位置信息详情 Menu Builder
  @Builder
  private buildLocationDetailMenu() {
    Menu() {
      MenuItem({ content: this.currentLocation?.address || '暂无详细位置' })
        .enabled(false)
      MenuItem({ content: `经纬度: ${this.currentLocation?.coordinates}` })
        .enabled(false)
    }
  }

  @Builder
  private buildFunctionCards() {
    GridRow({
      columns: 12, // 总共12列，便于响应式布局
      gutter: { x: DesignConstants.SPACING_SM, y: DesignConstants.SPACING_SM }, // 行列间距
      breakpoints: {
        reference: BreakpointsReference.WindowSize
      }
    }) {
      // 工具入口 - 显示工具状态
      GridCol({
        span: {
          sm: 6, // 小屏幕：每行2个 (12/6=2)
          md: 4, // 中等屏幕：每行3个 (12/4=3)
          lg: 3  // 大屏幕：每行4个 (12/3=4)
        }
      }) {
        this.buildSimplifiedFunctionCard({
          title: '设置',
          icon: $r('app.media.ic_atom'),
          description: '校准和设置',
          dataDisplay: this.toolsStatus,
          dataColor: this.toolsStatusColor,
          onTap: () => {
            this.switchToTab(1) // 设置
          }
        })
      }

      // 警报入口 - 显示活跃警报数量
      GridCol({
        span: {
          sm: 6, // 小屏幕：每行2个 (12/6=2)
          md: 4, // 中等屏幕：每行3个 (12/4=3)
          lg: 3  // 大屏幕：每行4个 (12/3=4)
        }
      }) {
        this.buildSimplifiedFunctionCard({
          title: '警报',
          icon: $r('app.media.ic_alarm'),
          description: '噪音警报管理',
          badgeCount: this.activeAlertsCount,
          dataDisplay: this.activeAlertsCount > 0 ? '警报中' : '正常',
          dataColor: this.activeAlertsCount > 0 ? $r('sys.color.alert') : $r('sys.color.confirm'),
          onTap: () => {
            this.switchToTab(2) // 警报
          }
        })
      }

      // 影响入口 - 显示暴露指数
      GridCol({
        span: {
          sm: 6, // 小屏幕：每行2个 (12/6=2)
          md: 4, // 中等屏幕：每行3个 (12/4=3)
          lg: 3  // 大屏幕：每行4个 (12/3=4)
        }
      }) {
        this.buildSimplifiedFunctionCard({
          title: '影响',
          icon: $r('app.media.i_solar_radar_outline'),
          description: '暴露统计分析',
          dataDisplay: this.exposureIndex,
          dataColor: this.exposureColor,
          onTap: () => {
            this.switchToTab(3) // 影响
          }
        })
      }

      // 参考入口 - 显示参考信息
      GridCol({
        span: {
          sm: 6, // 小屏幕：每行2个 (12/6=2)
          md: 4, // 中等屏幕：每行3个 (12/4=3)
          lg: 3  // 大屏幕：每行4个 (12/3=4)
        }
      }) {
        this.buildSimplifiedFunctionCard({
          title: '参考',
          icon: $r('app.media.ic_book2'),
          description: '参考资料',
          dataDisplay: this.reference,
          dataColor: this.exposureColor,
          onTap: () => {
            this.switchToTab(4) // 参考
          }
        })
      }

      // 历史记录入口 - 显示最近记录时间，记录总数显示在徽章中
      GridCol({
        span: {
          sm: 6, // 小屏幕：每行2个 (12/6=2)
          md: 4, // 中等屏幕：每行3个 (12/4=3)
          lg: 3  // 大屏幕：每行4个 (12/3=4)
        }
      }) {
        this.buildSimplifiedFunctionCard({
          title: '历史',
          icon: $r('app.media.ic_history'),
          description: '检测记录查看',
          dataDisplay: this.lastRecordTime,
          dataColor: $r('sys.color.font_secondary'),
          badgeCount: this.ak.totalRecordsCount,
          onTap: () => {
            Throttle.click(() => {
              this.navStack.pushPathByName('DecibelHistory', null);
            })
          }
        })
      }
      
    }
    .width('100%')
  }
  
  /**
   * 新年活动卡片 - 马年抽签入口
   * 设计特点：使用渐变色彩营造节日氛围，突出但不突兀
   * 用户可关闭，关闭后可在"我的"页面找到入口
   */
  @Builder
  private buildNewYearActivityCard() {
    Column() {
      // 只有当用户未关闭横幅时才显示
      if (!this.pk.benefit_activity_data.bannerClosed) {
        Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧：活动图标
      Stack({ alignContent: Alignment.Center }) {
        // 背景光晕
        Column()
          .width(44)
          .height(44)
          .backgroundColor(Color.White)
          .borderRadius(22)
          .opacity(0.3)
        
        // 签筒图标
        Text('🧧')
          .fontSize(28)
      }
      .width(44)
      .height(44)
      .alignSelf(ItemAlign.Center)
      
      // 中间：活动信息（点击可进入）
      Column({ space: DesignConstants.SPACING_XS }) {
        Row() {
          Text('马年抽签')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Start)
          
          // 限时标签
          Text('限时')
            .fontSize(10)
            .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
            .backgroundColor(Color.White)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(8)
            .margin({ left: 8 })
          
          Blank()
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        
        Row() {
          Text('抽取新年好运，赢取会员天数')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor('rgba(255, 255, 255, 0.9)')
            .textAlign(TextAlign.Start)
          
          Blank()
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .onClick(() => {
        Throttle.click(() => {
          // 显示马年抽签活动弹窗
          this.showBenefitActivityDialog();
        });
      })
      
      // 右侧：关闭按钮
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Image($r('app.media.ic_close'))
          .width(14)
          .height(14)
          .fillColor('rgba(255, 255, 255, 0.9)')
      }
      .width(28)
      .height(28)
      .backgroundColor('rgba(0, 0, 0, 0.15)')
      .onClick(() => {
        Throttle.click(() => {
          this.showCloseBannerConfirmDialog();
        });
      })
    }
    .width('100%')
    .height(72)
    .padding({ left: DesignConstants.SPACING_MD, right: DesignConstants.SPACING_SM })
    .linearGradient({
      direction: GradientDirection.Right,
      colors: [
        ['#D42426', 0.0],
        ['#E85D5D', 0.5],
        ['#F08A8A', 1.0]
      ]
    })
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .shadow({
      radius: 8,
      color: 'rgba(212, 36, 38, 0.25)',
      offsetY: 3
    })
      }
    }
  }
  
  /**
   * 显示关闭横幅确认对话框
   */
  private showCloseBannerConfirmDialog(): void {
    promptAction.showDialog({
      title: '关闭活动入口',
      message: '关闭后，您可以在"我的"页面找到马年抽签活动入口。确定要关闭吗？',
      buttons: [
        {
          text: '保持显示',
          color: $r('sys.color.font_secondary')
        },
        {
          text: '关闭',
          color: '#D42426'
        }
      ]
    }).then((result) => {
      if (result.index === 1) {
        // 用户选择关闭
        this.pk.benefit_activity_data.bannerClosed = true;
        promptAction.showToast({ 
          message: '已关闭，可在"我的"页面找到活动入口',
          duration: 2000 
        });
      }
    });
  }
  
  /**
   * 显示马年抽签活动弹窗
   */
  private showBenefitActivityDialog(): void {
    const props: BenefitActivityDialogProps = {
      onDismiss: () => {
        if (this.benefitActivityDialog) {
          this.benefitActivityDialog.dismiss();
          this.benefitActivityDialog = undefined;
        }
      }
    };
    
    this.benefitActivityDialog = DialogHub.getSheet()
      .setStyle({
        title: { title: '🐎 马年鸿运抽吉签' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(BenefitActivityDialogBuilder), props)
      .build();
    
    this.benefitActivityDialog.show();
  }

  @Builder
  private buildSimplifiedFunctionCard(config: FunctionCardConfig) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 左侧图标区域 - 垂直居中对齐
      Stack({ alignContent: Alignment.TopEnd }) {
        Image(config.icon)
          .width(32)
          .height(32)
          .fillColor($r('sys.color.icon_primary'))

        // 徽章计数 - 放在图标右上角
        if (config.badgeCount && config.badgeCount > 0) {
          Text(config.badgeCount.toString())
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor(Color.White)
            .backgroundColor($r('sys.color.alert'))
            .borderRadius(DesignConstants.BORDER_RADIUS_FULL)
            .padding({
              left: 6,
              right: 6,
              top: 2,
              bottom: 2
            })
            .margin({ top: -4, right: -4 })
        }
      }
      .width(32)
      .height(32)
      .alignSelf(ItemAlign.Center)

      // 右侧内容区域 - 垂直居中对齐
      Column({ space: DesignConstants.SPACING_XS }) {
        // 标题行
        Row() {
          Text(config.title)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .textAlign(TextAlign.Start)

          Blank()
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        // 描述行
        Row() {
          Text(config.description)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .textAlign(TextAlign.Start)

          Blank()
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        // 数据展示区域
        if (config.dataDisplay) {
          Row() {
            Text(config.dataDisplay)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontWeight(FontWeight.Medium)
              .fontColor(config.dataColor || $r('sys.color.font_primary'))
              .textAlign(TextAlign.Start)

            Blank()
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .margin({ top: DesignConstants.SPACING_XS })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(80)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .shadow(DesignConstants.SHADOW_SM)
    .onClick(() => {
      Throttle.click(() => {
        config.onTap();
      });
    })
    .gesture(
      TapGesture()
        .onAction(() => {
          // 简单的按压效果
        })
    )
  }

  // 切换到指定Tab
  private switchToTab(index: number) {
    this.ak.currentTabIndex = index;
    console.info(`切换到Tab: ${index}`);
  }

  @Builder
  private buildSystemStatus() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 第二行：独立位置信息行
      this.buildLocationInfo()
    }
    .padding({ top: DesignConstants.SPACING_MD })
  }

  @Builder
  private buildLocationInfo() {
    Row({ space: DesignConstants.SPACING_SM }) {
      Image($r('app.media.ic_location'))
        .width(14)
        .height(14)
        .fillColor($r('sys.color.icon_secondary'))
      Text(this.locationStatus)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor(this.locationStatusColor)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')

    // 移除点击事件，改为只读显示
  }

  @Computed
  get decibelColor(): Resource {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) {
      return $r('sys.color.confirm');
    }
    if (db < 60) {
      return $r('sys.color.alert');
    }
    if (db < 80) {
      return $r('sys.color.alert');
    }
    return $r('sys.color.warning');
  }

  @Computed
  get measurementDuration(): string {
    const duration = this.ak.uiDisplayState.displayStatistics.duration;
    if (duration < 60) {
      return `${Math.floor(duration)}秒`;
    } else if (duration < 3600) {
      return `${Math.floor(duration / 60)}分钟`;
    } else {
      return `${Math.floor(duration / 3600)}小时`;
    }
  }

  @Computed
  get systemStatus(): string {
    try {
      const audioControllerService = AudioControllerService.getInstance(this.ak, this.pk);
      if (audioControllerService && audioControllerService.isInBackground()) {
        return '后台运行';
      }
    } catch (error) {
      console.error('获取AudioControllerService实例失败:', error);
    }
    return '正常运行';
  }

  @Computed
  get systemStatusColor(): Resource {
    try {
      const audioControllerService = AudioControllerService.getInstance(this.ak, this.pk);
      if (audioControllerService && audioControllerService.isInBackground()) {
        return $r('sys.color.warning');
      }
    } catch (error) {
      console.error('获取AudioControllerService实例失败:', error);
    }
    return $r('sys.color.confirm');
  }

  // 仪表数据 - 趋势指示器
  @Computed
  get dashboardTrend(): string {
    const currentDb = this.ak.uiDisplayState.displayDb;
    const previousDb = this.ak.uiDisplayState.previousDb || currentDb;
    const diff = currentDb - previousDb;

    if (diff > 5) {
      return `↗ +${diff.toFixed(1)}dB`;
    }
    if (diff < -5) {
      return `↘ ${diff.toFixed(1)}dB`;
    }
    return '→ 稳定';
  }

  @Computed
  get dashboardTrendColor(): Resource {
    const currentDb = this.ak.uiDisplayState.displayDb;
    const previousDb = this.ak.uiDisplayState.previousDb || currentDb;
    const diff = currentDb - previousDb;

    if (diff > 1) {
      return $r('sys.color.alert');
    }
    if (diff < -1) {
      return $r('sys.color.confirm');
    }
    return $r('sys.color.font_secondary');
  }

  // 警报数据 - 活跃警报数量
  @Computed
  get activeAlertsCount(): number {
    // 模拟数据 - 实际应该从AlertService获取
    const db = this.ak.uiDisplayState.displayDb;
    const threshold = this.pk.alarm_threshold.baseThreshold || 70;

    if (db > threshold) {
      return 1;
    }
    return 0;
  }

  // 工具数据 - 工具状态
  @Computed
  get toolsStatus(): string {
    return '已配置';
  }

  @Computed
  get toolsStatusColor(): Resource {
    const calibrationValue = this.pk.calibration_value || 0;
    if (calibrationValue === 0) {
      return $r('sys.color.alert');
    }
    return $r('sys.color.confirm');
  }

  // 影响数据 - 暴露指数
  @Computed
  get exposureIndex(): string {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) {
      return '低风险';
    }
    if (db < 60) {
      return '中风险';
    }
    if (db < 80) {
      return '高风险';
    }
    return '极高风险';
  }

  @Computed
  get reference(): string {
    const db = this.ak.uiDisplayState.displayDb;
    return DecibelService.getDecibelDescription(db);
  }

  @Computed
  get exposureColor(): Resource {
    const db = this.ak.uiDisplayState.displayDb;
    if (db < 40) {
      return $r('sys.color.confirm');
    }
    if (db < 60) {
      return $r('sys.color.warning');
    }
    if (db < 80) {
      return $r('sys.color.alert');
    }
    return $r('sys.color.alert');
  }

  // 历史数据 - 最近记录时间
  @Computed
  get lastRecordTime(): string {
    const lastTimestamp = this.ak.lastRecordTimestamp;
    if (lastTimestamp) {
      return this.formatTimeAgo(lastTimestamp);
    }
    return '暂无记录';
  }

  // 格式化时间差
  private formatTimeAgo(timestamp: number): string {
    const now = Date.now();
    const diffMs = now - timestamp;
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 1) {
      return '刚刚';
    }
    if (diffMins < 60) {
      return `${diffMins}分钟前`;
    }

    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) {
      return `${diffHours}小时前`;
    }

    const diffDays = Math.floor(diffHours / 24);
    return `${diffDays}天前`;
  }

  // 初始化记录信息
  private async initializeRecordInfo(): Promise<void> {
    try {
      // 初始化最后记录时间
      const records = await this.decibelRecordService.getRecordsPaged(1, 0);
      if (records.length > 0) {
        this.ak.lastRecordTimestamp = records[0].timestamp;
      }

      // 初始化记录总数
      const totalCount = await this.decibelRecordService.getTotalCount();
      this.ak.totalRecordsCount = totalCount;
    } catch (error) {
      console.error('初始化记录信息失败:', error);
    }
  }

  // 位置状态计算属性
  @Computed
  get locationStatus(): string {
    if (!this.pk.location_enabled) {
      return '位置服务已关闭';
    }

    if (this.isLocationRefreshing) {
      return '正在获取位置信息...';
    }

    if (this.currentLocation) {
      // 简化地址显示，避免过长
      const address = this.currentLocation.address || '';
      if (address.length > 30) {
        return address.substring(0, 27) + '...';
      }
      return address;
    }

    return '位置服务已开启';
  }

  @Computed
  get locationStatusColor(): Resource {
    if (!this.pk.location_enabled) {
      return $r('sys.color.font_secondary');
    }

    if (this.isLocationRefreshing) {
      return $r('sys.color.warning');
    }

    if (this.currentLocation) {
      return $r('sys.color.confirm');
    }

    return $r('sys.color.font_primary');
  }

  // 短版本位置状态（用于紧凑显示）
  @Computed
  get locationStatusShort(): string {
    if (!this.pk.location_enabled) {
      return '位置关闭';
    }
    if (this.isLocationRefreshing) {
      return '获取中...';
    }
    if (this.currentLocation) {
      const address = this.currentLocation.address || '';
      // 提取城市+区域，简化显示
      const parts = address.split(/[省市县区]/);
      if (parts.length >= 2) {
        return parts[1].replace(/^[区]/, '').substring(0, 8);
      }
      return address.substring(0, 8);
    }
    return '位置已开启';
  }

  // 是否可以展开位置详情
  @Computed
  get canExpandLocation(): boolean {
    return this.currentLocation !== null && !!this.currentLocation.address;
  }

  // 位置服务开关方法 - 已移除，现在只在设置控制

  // 刷新位置信息方法
  private async refreshLocation(): Promise<void> {
    if (!this.pk.location_enabled || this.isLocationRefreshing) {
      return;
    }

    try {
      this.isLocationRefreshing = true;

      // 检查定位服务是否开启
      const isServiceEnabled = this.locationService.checkLocationEnabled();
      if (!isServiceEnabled) {
        this.currentLocation = null;
        return;
      }

      // 检查定位权限
      const hasPermission = await this.locationService.requestLocationPermission();
      if (!hasPermission) {
        this.currentLocation = null;
        this.pk.location_enabled = false;
        return;
      }

      // 获取位置信息
      const locationInfo: LocationInfo = await this.locationService.requestSingleLocation();
      this.currentLocation = locationInfo;
    } catch (error) {
      console.error('获取位置信息失败:', error);
      this.currentLocation = null;
    } finally {
      this.isLocationRefreshing = false;
    }
  }

  // 监听位置服务开关变化
  @Monitor('pk.location_enabled')
  onLocationEnabledChange(monitor: IMonitor) {
    const beforeEnabled = monitor.value<boolean>()?.before;
    const newEnabled = monitor.value<boolean>()?.now;
    if (newEnabled !== beforeEnabled) {
      if (newEnabled) {
        // 开启时自动刷新位置
        this.refreshLocation();
      } else {
        // 关闭时清空位置信息
        this.currentLocation = null;
      }
    }
  }

  aboutToAppear(): void {
    this.initializeRecordInfo();
    // 如果位置服务已开启，自动获取位置
    if (this.pk.location_enabled) {
      this.refreshLocation();
    }
    // 初始化音频控制器状态监听
    this.initializeAudioStateListener();
  }

  // ==================== 音频控制相关计算属性 ====================
  
  @Computed
  get isDetectionIdle(): boolean {
    return this.controllerState === AudioControllerLifecycleState.CONTROLLER_IDLE;
  }

  @Computed
  get isDetectionRecording(): boolean {
    return this.controllerState === AudioControllerLifecycleState.CONTROLLER_RECORDING;
  }

  @Computed
  get isDetectionError(): boolean {
    return this.controllerState === AudioControllerLifecycleState.CONTROLLER_ERROR;
  }

  @Computed
  get detectionStatusText(): string {
    switch (this.controllerState) {
      case AudioControllerLifecycleState.CONTROLLER_IDLE:
        return '空闲';
      case AudioControllerLifecycleState.CONTROLLER_STARTING:
        return '启动中';
      case AudioControllerLifecycleState.CONTROLLER_RECORDING:
        return '检测中';
      case AudioControllerLifecycleState.CONTROLLER_STOPPING:
      case AudioControllerLifecycleState.CONTROLLER_PAUSING:
        return '停止中';
      case AudioControllerLifecycleState.CONTROLLER_ERROR:
        return '错误';
      default:
        return '未知';
    }
  }

  @Computed
  get detectionStatusColor(): Resource {
    switch (this.controllerState) {
      case AudioControllerLifecycleState.CONTROLLER_RECORDING:
        return $r('sys.color.confirm');
      case AudioControllerLifecycleState.CONTROLLER_STARTING:
      case AudioControllerLifecycleState.CONTROLLER_STOPPING:
      case AudioControllerLifecycleState.CONTROLLER_PAUSING:
        return $r('sys.color.alert');
      case AudioControllerLifecycleState.CONTROLLER_ERROR:
        return $r('sys.color.alert');
      default:
        return $r('sys.color.font_secondary');
    }
  }

  // ==================== 音频控制方法 ====================

  private initializeAudioStateListener(): void {
    this.audioControllerService.initializeStateMachine();
    this.audioControllerService.onStateChangeFromExternal((event: StateTransitionEvent) => {
      this.controllerState = event.toState;
      console.info(`[HomePageContent] 状态变更: ${event.fromState} -> ${event.toState}`);
    });
    // 初始化当前状态
    const currentState = this.audioControllerService.getStateMachine()?.getCurrentState();
    if (currentState) {
      this.controllerState = currentState;
    }
  }

  private startDetection(): void {
    Throttle.click(async () => {
      try {
        await this.audioControllerService.startRecordingFromExternal();
      } catch (error) {
        console.error('[HomePageContent] 启动检测失败:', error);
      }
    });
  }

  private showStopConfirmation(): void {
    Throttle.click(() => {
      this.stopConfirmDialogController.open();
    });
  }

  private doStopDetection(): void {
    Throttle.click(async () => {
      try {
        await this.audioControllerService.stopRecordingFromExternal('手动停止');
      } catch (error) {
        console.error('[HomePageContent] 停止检测失败:', error);
      }
    });
  }

  private showResetConfirmation(): void {
    Throttle.click(() => {
      this.confirmDialogController.open();
    });
  }

  private resetData(): void {
    Throttle.click(async () => {
      try {
        await this.audioControllerService.resetStateFromExternal();
      } catch (error) {
        console.error('[HomePageContent] 重置数据失败:', error);
      }
    });
  }

  private showSaveDialog(): void {
    Throttle.click(() => {
      this.inputDialogController.open();
    });
  }

  private saveCurrentData(comment: string): void {
    Throttle.click(async () => {
      try {
        this.startSaveAnimation();
        await this.audioControllerService.restartRecordingFromExternal(comment);
        setTimeout(() => {
          this.endSaveAnimation();
          promptAction.showToast({ message: '保存成功' });
        }, 500);
      } catch (error) {
        console.error('[HomePageContent] 保存数据失败:', error);
        this.endSaveAnimation();
      }
    });
  }

  private startSaveAnimation(): void {
    this.getUIContext().animateTo({
      duration: 300,
      curve: Curve.EaseInOut
    }, () => {
      this.saveAnimationOpacity = 0.7;
    });
  }

  private endSaveAnimation(): void {
    this.getUIContext().animateTo({
      duration: 300,
      curve: Curve.EaseInOut
    }, () => {
      this.saveAnimationOpacity = 1.0;
    });
  }

  // ==================== Builder 方法 ====================

  @Builder
  private buildSaveInputDialog() {
    InputDialog({
      title: '保存数据',
      default: '',
      onConfirm: (comment: string) => {
        this.saveCurrentData(comment);
        this.inputDialogController.close();
      },
      onClose: () => {
        this.inputDialogController.close();
      }
    })
  }

  @Builder
  private buildResetConfirmDialog() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('确认重置')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))

      Text('确定要重置所有检测数据吗？此操作不可撤销。')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)

      Row({ space: DesignConstants.SPACING_MD }) {
        Button('取消', { type: ButtonType.Normal })
          .layoutWeight(1)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .fontColor($r('sys.color.font_primary'))
          .onClick(() => {
            Throttle.click(() => {
              this.confirmDialogController.close();
            });
          })

        Button('确认重置', { type: ButtonType.Normal })
          .layoutWeight(1)
          .backgroundColor($r('sys.color.alert'))
          .fontColor(Color.White)
          .onClick(() => {
            Throttle.click(() => {
              this.resetData();
              this.confirmDialogController.close();
            });
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
  }

  @Builder
  private buildStopConfirmDialog() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('确认停止检测')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))

      Text(`当前检测时长: ${this.ak.uiDisplayState.timeDisplay}\n确定要停止检测吗？`)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)

      Row({ space: DesignConstants.SPACING_MD }) {
        Button('继续检测', { type: ButtonType.Normal })
          .layoutWeight(1)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .fontColor($r('sys.color.font_primary'))
          .onClick(() => {
            Throttle.click(() => {
              this.stopConfirmDialogController.close();
            });
          })

        Button('确认停止', { type: ButtonType.Normal })
          .layoutWeight(1)
          .backgroundColor($r('sys.color.alert'))
          .fontColor(Color.White)
          .onClick(() => {
            Throttle.click(() => {
              this.stopConfirmDialogController.close();
              this.doStopDetection();
            });
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
  }
}
