import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2, AppStorageV2 } from '@kit.ArkUI';
import { AboutSettingsBuilder } from '../../pages/settings/AboutSettingsNavigation';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { common } from '@kit.AbilityKit';
import { DisplayModeCardBuilder } from '../display/DisplayModeComponent';
import { MembershipStatusCard } from '../membership/MembershipStatusCard';
import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';
import { CommentService } from '../../services/CommentService';
import { AppKeys } from '../../models/AppKeys';
import { AlertService } from '../../services/AlertService';
import { MeasurementPrecisionContent } from './MeasurementPrecisionContent';
import { DataAndAlertsContent } from './DataAndAlertsContent';

/**
 * 我的内容页面组件 - 重新设计版
 * 优化信息层级，融合原有弹窗功能
 */
@ComponentV2
export struct MyContentComponent {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;

  private context: Context = getContext(this);
  private alertService: AlertService = AlertService.getInstance(getContext() as common.UIAbilityContext, this.pk);

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
      }
    });
  }

  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_MD }) {
        // 会员状态卡片
        MembershipStatusCard()

        // 测量精度设置入口（无标题，卡片即标题）
        this.buildMeasurementPrecisionEntry()

        // 数据与警报设置入口（无标题，卡片即标题）
        this.buildDataAndAlertsEntry()

        // 其他设置列表
        this.buildOtherSettingsList()
      }
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .width('100%')
      .padding({ left: 16, right: 16, bottom: DesignConstants.SPACING_LG })
    }
    .align(Alignment.Top)
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
  }

  // ==================== 测量精度设置入口 ====================

  @Builder
  private buildMeasurementPrecisionEntry() {
    // 设置入口卡片（无外部标题，卡片即标题）
    Row({ space: 12 }) {
      // 左侧图标
      Row() {
        Image($r('app.media.ic_calibration'))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.icon_primary'))
      }
      .width(44)
      .height(44)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 中间内容
      Column({ space: 4 }) {
        Text('测量精度')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        // 状态摘要
        Text(this.getPrecisionSummary())
          .fontSize(13)
          .fontColor($r('sys.color.font_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 箭头
      Image($r('app.media.ic_arrow_right'))
        .width(16)
        .height(16)
        .fillColor($r('sys.color.font_tertiary'))
    }
    .width('100%')
    .height(64)
    .padding({ left: 12, right: 16 })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      Throttle.click(() => this.openMeasurementPrecisionPage());
    })
  }

  // 获取测量精度摘要
  private getPrecisionSummary(): string {
    const parts: string[] = [];

    // 校准状态
    const calibrationValue = this.pk.calibration_value || 0;
    if (calibrationValue !== 0) {
      parts.push(`已校准${calibrationValue > 0 ? '+' : ''}${calibrationValue}dB`);
    } else {
      parts.push('未校准');
    }

    // 频率加权
    const weightingMap: Record<string, string> = {
      'A': 'A计权',
      'C': 'C计权',
      'Z': 'Z计权'
    };
    parts.push(weightingMap[this.pk.weighting_type] || 'A计权');

    // 时间加权
    const modeMap: Record<string, string> = {
      'FAST_TIME_WEIGHTING': '快速',
      'SLOW_TIME_WEIGHTING': '慢速',
      'IMPULSE_TIME_WEIGHTING': '脉冲',
      'CUSTOM_TIME_WEIGHTING': '自定义'
    };
    parts.push(modeMap[this.pk.audio_analysis_mode] || '快速');

    return parts.join(' · ');
  }

  // ==================== 数据与警报设置入口 ====================

  @Builder
  private buildDataAndAlertsEntry() {
    // 设置入口卡片（无外部标题，卡片即标题）
    Row({ space: 12 }) {
      // 左侧图标
      Row() {
        Image($r('app.media.ic_save'))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.icon_primary'))
      }
      .width(44)
      .height(44)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(12)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 中间内容
      Column({ space: 4 }) {
        Text('数据与警报')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        // 状态摘要
        Text(this.getDataAlertsSummary())
          .fontSize(13)
          .fontColor($r('sys.color.font_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 箭头
      Image($r('app.media.ic_arrow_right'))
        .width(16)
        .height(16)
        .fillColor($r('sys.color.font_tertiary'))
    }
    .width('100%')
    .height(64)
    .padding({ left: 12, right: 16 })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      Throttle.click(() => this.openDataAndAlertsPage());
    })
  }

  // 获取数据与警报摘要
  private getDataAlertsSummary(): string {
    const parts: string[] = [];

    // 自动保存
    if (this.pk.auto_save_enabled) {
      parts.push(`自动保存每${this.pk.auto_save_interval}分钟`);
    } else {
      parts.push('自动保存关');
    }

    // 录音
    parts.push(this.pk.record_enabled ? '录音开' : '录音关');

    // 定位
    parts.push(this.pk.location_enabled ? '定位开' : '定位关');

    // 警报
    parts.push(`警报阈值${this.pk.alarm_threshold.currentEffectiveThreshold}dB`);

    return parts.join(' · ');
  }

  // ==================== 其他设置列表 ====================

  @Builder
  private buildOtherSettingsList() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 色彩模式设置项
      this.buildColorModeItem()

      // 给作者五星好评设置项
      this.buildRatingItem()

      // 关于设置项
      this.buildAboutItem()
    }
    .width('100%')
  }

  // 色彩模式设置项
  @Builder
  private buildColorModeItem() {
    Row({ space: 12 }) {
      // 左侧图标容器
      Row() {
        Image($r('app.media.ic_display'))
          .width(22)
          .height(22)
          .fillColor($r('sys.color.icon_primary'))
      }
      .width(40)
      .height(40)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(10)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 内容区
      Row() {
        Text('色彩模式')
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        // 当前模式显示
        Text(this.pk.display_mode === 'default' ? '跟随系统' :
             this.pk.display_mode === 'light' ? '浅色主题' : '深色主题')
          .fontSize(14)
          .fontColor($r('sys.color.font_secondary'))

        // 右侧箭头
        Image($r('app.media.ic_arrow_right'))
          .width(16)
          .height(16)
          .fillColor($r('sys.color.font_tertiary'))
          .margin({ left: 8 })
      }
      .layoutWeight(1)
      .height(40)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(64)
    .padding({ left: 12, right: 16 })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      Throttle.click(() => {
        DialogHub.getSheet()
          .setStyle({
            title: { title: '色彩模式' },
            backgroundColor: $r('sys.color.background_secondary')
          })
          .setConfig({ scrollSizeMode: ScrollSizeMode.FOLLOW_DETENT })
          .setComponentTargetId('mainId')
          .setContent(wrapBuilder(DisplayModeCardBuilder))
          .build()
          .show();
      });
    })
  }

  // 五星好评设置项
  @Builder
  private buildRatingItem() {
    Row({ space: 12 }) {
      // 左侧图标容器
      Row() {
        Image($r('app.media.ic_smile'))
          .width(22)
          .height(22)
          .fillColor($r('sys.color.icon_primary'))
      }
      .width(40)
      .height(40)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(10)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 内容区
      Row() {
        Text('五星好评')
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        // 右侧箭头
        Image($r('app.media.ic_arrow_right'))
          .width(16)
          .height(16)
          .fillColor($r('sys.color.font_tertiary'))
      }
      .layoutWeight(1)
      .height(40)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(64)
    .padding({ left: 12, right: 16 })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.showCommentDialog();
    })
  }

  // 关于设置项
  @Builder
  private buildAboutItem() {
    Row({ space: 12 }) {
      // 左侧图标容器
      Row() {
        Image($r('app.media.ic_info'))
          .width(22)
          .height(22)
          .fillColor($r('sys.color.icon_primary'))
      }
      .width(40)
      .height(40)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(10)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      // 内容区
      Row() {
        Text('关于')
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)

        // 右侧箭头
        Image($r('app.media.ic_arrow_right'))
          .width(16)
          .height(16)
          .fillColor($r('sys.color.font_tertiary'))
      }
      .layoutWeight(1)
      .height(40)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(64)
    .padding({ left: 12, right: 16 })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      Throttle.click(() => {
        DialogHub.getSheet()
          .setStyle({ title: { title: '关于' }, backgroundColor: $r('sys.color.background_secondary') })
          .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
          .setComponentTargetId('mainId')
          .setContent(wrapBuilder(AboutSettingsBuilder))
          .build()
          .show();
      });
    })
  }

  // ==================== 页面打开方法 ====================

  // 打开测量精度设置页面
  private openMeasurementPrecisionPage(): void {
    let settingsDialog: InfSheet;
    settingsDialog = DialogHub.getSheet()
      .setStyle({
        title: { title: '测量精度' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(MeasurementPrecisionContentBuilder))
      .build();
    settingsDialog.show();
  }

  // 打开数据与警报设置页面
  private openDataAndAlertsPage(): void {
    let settingsDialog: InfSheet;
    settingsDialog = DialogHub.getSheet()
      .setStyle({
        title: { title: '数据与警报' },
        backgroundColor: $r('sys.color.background_secondary')
      })
      .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
      .setComponentTargetId('mainId')
      .setContent(wrapBuilder(DataAndAlertsContentBuilder))
      .build();
    settingsDialog.show();
  }
}

// 测量精度设置内容Builder
@Builder
function MeasurementPrecisionContentBuilder() {
  MeasurementPrecisionContent()
}

// 数据与警报设置内容Builder
@Builder
function DataAndAlertsContentBuilder() {
  DataAndAlertsContent()
}
