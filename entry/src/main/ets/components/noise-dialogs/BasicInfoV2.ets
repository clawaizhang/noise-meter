import { DecibelRecord } from '../../models/DecibelRecord';
import { Throttle } from '../../utils/Debounce';
import { InputDialog } from '../decibel-meter/InputDialog';
import { DesignConstants } from '../../constants/DesignConstants';

/**
 * 基本信息组件 V2
 */
@ComponentV2
export struct BasicInfoV2 {
  @Param selectedRecord: DecibelRecord | null = null;
  @Event commentChange: (comment: string) => void = () => {};
  @Local comment: string = '';

  aboutToAppear(): void {
    this.comment = this.selectedRecord?.comment ?? '';
  }

  // 格式化日期：1月15日（不带年份，保持与旁边时间高度一致）
  private formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    return `${date.getMonth() + 1}月${date.getDate()}日`;
  }

  // 格式化时间：14:30
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
  }

  // 格式化时长：统一格式，小于60秒显示"XX秒"，大于等于60秒显示"X分XX秒"
  private formatDuration(seconds: number): string {
    if (seconds < 60) {
      return `${seconds}秒`;
    } else {
      const mins = Math.floor(seconds / 60);
      const secs = seconds % 60;
      return secs > 0 ? `${mins}分${secs}秒` : `${mins}分钟`;
    }
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_info'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor($r('sys.color.brand'))
        Text('检测信息')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .width('100%')

      // 信息网格 - 2×2
      GridRow({ columns: 2, gutter: DesignConstants.SPACING_MD }) {
        // 检测日期（带年份）
        GridCol({ span: 1 }) {
          this.InfoCard(
            $r('app.media.ic_history'),
            '检测日期',
            this.formatDate(this.selectedRecord?.timestamp ?? 0)
          )
        }

        // 检测时间
        GridCol({ span: 1 }) {
          this.InfoCard(
            $r('app.media.ic_time_weighting'),
            '检测时间',
            this.formatTime(this.selectedRecord?.timestamp ?? 0)
          )
        }

        // 检测时长（统一格式）
        GridCol({ span: 1 }) {
          this.InfoCard(
            $r('app.media.ic_meter'),
            '检测时长',
            this.formatDuration(this.selectedRecord?.duration ?? 0)
          )
        }

        // 音频文件
        GridCol({ span: 1 }) {
          this.InfoCard(
            $r('app.media.ic_audio_analysis'),
            '录音文件',
            this.selectedRecord?.audioFilePath ? '已保存' : '无'
          )
        }
      }
      .width('100%')

      // 检测位置（如果有）
      if (this.selectedRecord?.location) {
        Row({ space: DesignConstants.SPACING_MD }) {
          Image($r('app.media.ic_location'))
            .width(DesignConstants.ICON_SIZE_MD)
            .height(DesignConstants.ICON_SIZE_MD)
            .fillColor($r('sys.color.brand'))
          Text('位置')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_tertiary'))
            .width(40)
          Text(this.selectedRecord!.location)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      }

      // 备注区域
      this.CommentSection()
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  @Builder
  InfoCard(icon: Resource, label: string, value: string) {
    Row({ space: DesignConstants.SPACING_SM }) {
      Image(icon)
        .width(DesignConstants.ICON_SIZE_MD)
        .height(DesignConstants.ICON_SIZE_MD)
        .fillColor($r('sys.color.brand'))

      Column({ space: DesignConstants.SPACING_XS }) {
        Text(label)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_tertiary'))
        Text(value)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  @Builder
  CommentSection() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_document_edit'))
          .width(DesignConstants.ICON_SIZE_SM)
          .height(DesignConstants.ICON_SIZE_SM)
          .fillColor($r('sys.color.brand'))
        Text('备注')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
        Blank()
        if (this.comment) {
          Text('编辑')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.brand'))
        }
      }
      .width('100%')

      // 备注内容/输入框
      if (this.comment) {
        Row({ space: DesignConstants.SPACING_MD }) {
          Text(this.comment)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1)
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Button() {
            Image($r('app.media.ic_document_edit'))
              .width(DesignConstants.ICON_SIZE_SM)
              .height(DesignConstants.ICON_SIZE_SM)
              .fillColor($r('sys.color.brand'))
          }
          .width(32)
          .height(32)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(16)
          .onClick(() => this.showCommentDialog())
        }
        .width('100%')
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      } else {
        Button() {
          Row({ space: DesignConstants.SPACING_SM }) {
            Image($r('app.media.ic_add'))
              .width(DesignConstants.ICON_SIZE_SM)
              .height(DesignConstants.ICON_SIZE_SM)
              .fillColor($r('sys.color.brand'))
            Text('添加备注')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.brand'))
          }
        }
        .width('100%')
        .height(44)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => this.showCommentDialog())
      }
    }
    .width('100%')
  }

  private showCommentDialog(): void {
    Throttle.click(() => {
      const dialogController = new CustomDialogController({
        builder: InputDialog({
          title: this.comment ? '编辑备注' : '添加备注',
          default: this.comment,
          onConfirm: (comment: string) => {
            this.comment = comment;
            this.commentChange(this.comment);
            dialogController.close();
          },
          onClose: () => {
            dialogController.close();
          }
        }),
        cancel: () => {},
        autoCancel: true
      });
      dialogController.open();
    });
  }
}
