import { DetailDialogBuilder, DetailDialogParams } from './DetailDialogNavigation';
import { PromptAction } from '@ohos.arkui.UIContext';
import { DecibelService } from '../../services/DecibelService';
import { DecibelRecordService } from '../../services/DecibelRecordService';
import { navigationStack } from '../../constants/ProviderConstant';
import { AudioPlayer } from '../../components/business/AudioPlayer';
import { DecibelRecord } from '../../models/DecibelRecord';
import { FileUtils } from '../../utils/FileUtils';
import { DesignConstants } from '../../constants/DesignConstants';
import { AppStorageV2, curves, SymbolGlyphModifier } from '@kit.ArkUI';
import { DialogHub, InfSheet } from '@hadss/dialoghub';
import { NoiseStandardDialogBuilder } from './NoiseStandardDialogNavigation';
import { AppKeys } from '../../models/AppKeys';

class DecibelRecordDataSource implements IDataSource {
  private records: DecibelRecord[];
  private listeners: DataChangeListener[] = [];

  constructor(records: DecibelRecord[]) {
    this.records = records;
  }

  replaceData(records: DecibelRecord[]) {
    this.records = records;
  }

  totalCount(): number {
    return this.records.length;
  }

  getData(index: number): DecibelRecord {
    return this.records[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener);
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => listener.onDataReloaded());
  }

  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => listener.onDataAdd(index));
  }

  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => listener.onDataChange(index));
  }

  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => listener.onDataDelete(index));
  }
}

@Builder
export function DecibelHistoryBuilder() {
  DecibelHistory()
}

@ComponentV2
export struct DecibelHistory {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  @Local records: DecibelRecord[] = [];
  @Local dataSource: DecibelRecordDataSource = new DecibelRecordDataSource([]);
  @Local selectedRecord: DecibelRecord | null = null;
  @Local pendingDeleteId: string = ''; // 当前正在删除的记录ID
  @Local pendingDeleteAudioId: string = '';
  @Local shouChangMode: boolean = false;
  @Local deleteMode: boolean = false;
  @Local as: AppKeys = AppStorageV2.connect(AppKeys)!;
  private context: Context = getContext(this)
  private recordService: DecibelRecordService = new DecibelRecordService(this.context);
  private promptAction: PromptAction = this.getUIContext().getPromptAction();
  
  // DialogHub实例缓存
  private detailDialog: InfSheet | null = null;

  onPageShow() {
    this.loadRecords();
  }

  build() {
    NavDestination() {
      // 内容区域
      if (this.records.length == 0) {
        this.EmptyStateView()
      } else {
        this.ListLayoutView()
      }
    }.id('rbgnolqiwuejrbgvwoi').title('历史记录').backgroundColor($r('sys.color.background_secondary')).menus([{
      value: '收藏',
      symbolIcon: new SymbolGlyphModifier($r("sys.symbol.heart")),
      action: () => {
        this.shouChangMode = !this.shouChangMode;
        if (this.shouChangMode) {
          this.deleteMode = false;
        }
      }
    }, {
      value: '删除',
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.edit_badge_star')),
      action: () => {
        this.deleteMode = !this.deleteMode;
        if (this.deleteMode) {
          this.shouChangMode = false;
        } else {
          this.pendingDeleteId = undefined;
          this.pendingDeleteAudioId = undefined;
        }
      }
    }])
  }

  aboutToAppear() {
    this.loadRecords();
    this.dataSource.notifyDataReload();
  }

  async loadRecords() {
    try {
      this.records = await this.recordService.getRecords();
      if (this.dataSource) {
        this.dataSource.replaceData(this.records);
        this.dataSource.notifyDataReload();
      } else {
        this.dataSource = new DecibelRecordDataSource(this.records);
      }
    } catch (error) {
      console.error('加载历史记录失败:', error);
    }
  }

  emptyAll = async () => {
    AlertDialog.show({
      title: '清空检测记录',
      message: '确定要清空检测记录吗？\n已收藏的记录将会保留',
      alignment: DialogAlignment.Center,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '取消',
        action: () => {
          // 不执行任何操作
        }
      },
      secondaryButton: {
        value: '清空',
        action: async () => {
          try {
            // 清空非收藏记录
            await this.recordService.clearUnfavoriteRecords();
            // 重新加载记录列表
            await this.loadRecords();
            // 显示清空成功提示
            this.promptAction.showToast({
              message: '已清空检测记录',
              duration: 2000,
              bottom: '50%'
            });
          } catch (error) {
            console.error('清空历史记录失败:', error);
          }
        }
      }
    });
  }

  @Builder
  RecordItem(record: DecibelRecord) {
    Row() {
      // 左侧位置和时间信息列
      this.LocationNoteDateTime(record) // 添加弹性收缩
      // 右侧区域：分贝值信息
      this.decibelInfoPlayer(record) // 禁止收缩
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Top)
    .padding(16)
    .borderRadius(16)
    .id("showNoiseDetailDialogFromHistory")
    .onClick(() => {
      this.showNoiseDetails(record);
    })
    .transition(TransitionEffect.scale({ x: 0, y: 0 })
      .combine(TransitionEffect.translate({ x: 150 }).animation({ curve: curves.springMotion() })))
  }

  private showNoiseDetails(record: DecibelRecord) {
    this.selectedRecord = record;
    this.showDetailDialog();
  }

  @Builder
  shouChangShanChuButton(record: DecibelRecord) {
    // 右侧按钮组
    Column({ space: 8 }) {
      if (this.deleteMode) {
        // 删除确认按钮
        if (record.id === this.pendingDeleteId) {
          Button('删除并清空检测报告')
            .height(36)
            .type(ButtonType.Capsule)
            .backgroundColor($r('sys.color.warning'))
            .animation({ curve: Curve.EaseInOut })
            .transition(TransitionEffect.scale({ x: 0, y: 0 })
              .combine(TransitionEffect.opacity(1))
              .animation({ curve: curves.springMotion(0.6, 0.8) }))
            .onClick(() => {
              this.deleteRecord(record);
            });
        } else {
          Button('删除')
            .height(36)
            .type(ButtonType.Capsule)
            .backgroundColor($r('sys.color.alert'))
            .animation({ curve: Curve.EaseInOut })
            .transition(TransitionEffect.scale({ x: 0, y: 0 })
              .combine(TransitionEffect.opacity(1))
              .animation({ curve: curves.springMotion(0.6, 0.8) }))
            .onClick(() => {
              this.pendingDeleteId = record.id;
            });
        }
        if (record.id === this.pendingDeleteAudioId) {
          Button('确认删除音频文件')
            .height(36)
            .type(ButtonType.Capsule)
            .backgroundColor($r('sys.color.warning'))
            .animation({ curve: Curve.EaseInOut })
            .transition(TransitionEffect.scale({ x: 0, y: 0 })
              .combine(TransitionEffect.opacity(1))
              .animation({ curve: curves.springMotion(0.6, 0.8) }))
            .onClick(() => {
              this.deleteRecordAudio(record);
            });
        } else {
          if (record.audioFilePath) {
            Button('删除音频文件')
              .height(36)
              .type(ButtonType.Capsule)
              .backgroundColor($r('sys.color.alert'))
              .animation({ curve: Curve.EaseInOut })
              .transition(TransitionEffect.scale({ x: 0, y: 0 })
                .combine(TransitionEffect.opacity(1))
                .animation({ curve: curves.springMotion(0.6, 0.8) }))
              .onClick(() => {
                this.pendingDeleteAudioId = record.id;
              });
          }
        }

      } else {
        // 收藏按钮
        if (this.shouChangMode) {
          Button(record.isFavorite ? '取消收藏' : '收藏')
            .fontColor(record.isFavorite ? '#FF4081' : Color.White)
            .type(ButtonType.Capsule)
            .height(36)
            .backgroundColor(record.isFavorite ? '#FFE0EB' : '#FF4081')
            .animation({ curve: Curve.EaseOut })
            .transition(TransitionEffect.scale({ x: 0, y: 0 })
              .combine(TransitionEffect.opacity(1))
              .animation({ curve: curves.springMotion(0.6, 0.8) }))
            .onClick(async () => {
              record.isFavorite = !record.isFavorite;
              await this.recordService.updateRecord(record);
              // 显示操作提示
              this.promptAction.showToast({
                message: record.isFavorite ? '已添加到收藏' : '已取消收藏',
                duration: 2000,
                bottom: '50%'
              });
            });
        }
      }
    }.justifyContent(FlexAlign.End).alignItems(HorizontalAlign.End).transition(TransitionEffect.opacity(1)
      .animation({ curve: curves.springMotion(0.6, 0.8) }))
  }

  @Builder
  decibelInfoPlayer(record: DecibelRecord) {
    // 右侧区域：分贝值信息
    Column({ space: 8 }) {
      Row() {
        this.decibelAverages(record)
      }

      Row() {
        if (record!.audioFilePath) {
          AudioPlayer({
            audioFilePath: record!.audioFilePath,
          });
        }
      }

      Row() {
        this.shouChangShanChuButton(record)
      }
    }
    .alignItems(HorizontalAlign.End).justifyContent(FlexAlign.Start)
  }

  @Builder
  decibelAverages(record: DecibelRecord) {
    Row({ space: 8 }) {
      Column({ space: 4 }) {
        Text('最小值')
          .fontSize(DesignConstants.FONT_SIZE_SM)
        Text(record.minDecibel.toString())
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(DecibelService.getDecibelColor(record.minDecibel));
      }
      .height(40); // 固定高度确保对齐

      Column({ space: 4 }) {
        Text('平均值')
          .fontSize(DesignConstants.FONT_SIZE_SM)
        Text(record.avgDecibel.toString())
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(DecibelService.getDecibelColor(record.avgDecibel));
      }
      .height(40); // 固定高度确保对齐

      Column({ space: 4 }) {
        Text('最大值')
          .fontSize(DesignConstants.FONT_SIZE_SM)
        Text(record.maxDecibel.toString())
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor(DecibelService.getDecibelColor(record.maxDecibel));
      }
      .height(40); // 固定高度确保对齐
    }
  }

  @Builder
  LocationNoteDateTime(record: DecibelRecord) {
    // 左侧位置和时间信息列
    Column({ space: 8 }) {
      // 位置信息显示
      Text(record.location || '未获取位置信息')
        .fontSize(14)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis });

      Text(record.comment || '无备注')
        .fontSize(14)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 时间信息
      Text(new Date(record.timestamp).toLocaleString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        hour12: false
      }))
        .fontSize(14)

      // 检测时长
      Text(`时长: ${Math.round(record.duration / 1000)}秒`)
        .fontSize(14)

      if (record.audioFilePath) {
        Text(`音频大小: ${this.formatBytes(FileUtils.getFileInfoSync(record.audioFilePath.replace(FileUtils.getBasePath(),
          '')).size)}`)
          .fontSize(14)
      }
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start).animation({ curve: Curve.EaseOut })
  }

  private formatBytes(bytes: number): string {
    if (bytes === 0) {
      return '0 B'
    }
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  private async deleteRecord(record: DecibelRecord) {
    try {
      // 从列表中除该记录
      const index = this.records.findIndex(r => r.id === record.id);
      if (index !== -1) {
        this.records.splice(index, 1);
      }
      // 从数据库中删除记录
      await this.recordService.deleteRecord(record.id);
      // 隐藏删除按钮
      this.pendingDeleteId = '';
      this.dataSource.notifyDataDelete(index);
      // 显示删除成功提示
      this.promptAction.showToast({
        message: '删除成功',
        duration: 2000,
        bottom: '50%'
      });
    } catch (error) {
      console.error('删除记录失败:', error);
    }
  }

  private async deleteRecordAudio(record: DecibelRecord) {
    try {
      record.audioFilePath = '';
      this.recordService.updateRecord(record).then(() => {
        FileUtils.deleteFile(record.audioFilePath!.replace(FileUtils.getBasePath(), '')).then(() => {
        })
      });
      // 隐藏删除按钮
      this.pendingDeleteAudioId = '';
      // 显示删除成功提示
      this.promptAction.showToast({
        message: '删除成功',
        duration: 2000,
        bottom: '50%'
      });
    } catch (error) {
      console.error('删除记录失败:', error);
    }
  }

  async showDetailDialog() {
    if (!this.selectedRecord) {
      return;
    }

    try {
      // 创建导航参数
      const params: DetailDialogParams = {
        selectedRecord: this.selectedRecord,
        context: getContext(this),
      };
      if (!this.detailDialog) {
        this.detailDialog = DialogHub.getSheet()
          .setComponentTargetId('showNoiseDetailDialogFromHistory')
          .setStyle({ showClose: false })
          .setConfig({ enableOutsideInteractive: false, scrollSizeMode: ScrollSizeMode.CONTINUOUS })
          .setContent(wrapBuilder(DetailDialogBuilder), params)
          .build();
      }
      this.detailDialog.show();
    } catch (error) {
      console.error('导航到详情页失败:', error);
    }
  }

  /**
   * 空状态视图
   */
  @Builder
  EmptyStateView() {
    Column() {
      Image($r('app.media.ic_empty'))
        .width(120)
        .fillColor($r('sys.color.font_primary'))
        .height(120)
        .margin({ bottom: DesignConstants.SPACING_LG })
      Text('暂无检测记录')
        .fontSize(DesignConstants.FONT_SIZE_LG)
      Text('完成一次检测后即可查看记录')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .margin({ top: DesignConstants.SPACING_SM })
    }

    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 列表布局视图
   */
  @Builder
  ListLayoutView() {
    Scroll() {
      Column({ space: 16 }) {
        Text(`共 ${this.records.length} 条记录`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .textAlign(TextAlign.Center)
          .alignSelf(ItemAlign.Center)
        GridRow({
          columns: {
            xs: 1,
            sm: 1,
            md: 2,
            lg: 2,
            xl: 3,
            xxl: 3
          },
          breakpoints: { reference: BreakpointsReference.WindowSize },
          gutter: 16
        }) {
          LazyForEach(this.dataSource, (record: DecibelRecord) => {
            GridCol({ span: 1 }) {
              this.RecordItem(record)
            }.animation({
              duration: 300,
              curve: Curve.EaseOut
            })
          }, (record: DecibelRecord) => record.id)
        }
      }.margin({ left: 16, right: 16 }).id('noiseHistoryMainId')
    }.scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring).height('100%').align(Alignment.Top)
  }
}
