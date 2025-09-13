import { DetailDialogParams } from './DetailDialogNavigation';
import { PromptAction } from '@ohos.arkui.UIContext';
import { DecibelService } from '../../services/DecibelService';
import { DecibelRecordService } from '../../services/DecibelRecordService';
import { navigationStack } from '../../constants/ProviderConstant';
import { emitter } from '@kit.BasicServicesKit';
import { AudioPlayer } from '../../components/business/AudioPlayer';
import { DecibelRecord } from '../../models/DecibelRecord';
import { FileService } from '../../services/FileService';
import { DesignConstants } from '../../constants/DesignConstants';

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
function DecibelHistoryBuilder() {
  DecibelHistory()
}

@ComponentV2
export struct DecibelHistory {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack()
  @Local records: DecibelRecord[] = [];
  @Local dataSource: DecibelRecordDataSource = new DecibelRecordDataSource([]);
  @Local selectedRecord: DecibelRecord | null = null;
  @Local showingDeleteButtonId: string = ''; // 当前显示删除按钮的记录ID
  @Local currentSlidingId: string = ''; // 当前正在滑动的记录ID
  @Local currentSlideOffset: number = 0; // 当前滑动的偏移量
  @Local pendingDeleteId: string = ''; // 当前正在删除的记录ID
  @Local gridColumns: number = 1; // 网格布局列数
  private startX: number = 0;
  private hasDeleteButtonOnStart: boolean = false; // 滑动开始时是否有删除按钮示
  private context: Context = getContext(this)
  private recordService: DecibelRecordService = new DecibelRecordService(this.context);
  private promptAction: PromptAction = this.getUIContext().getPromptAction();
  private fileService: FileService = new FileService(this.context)
  private pendingHideButtonId: string = ''; // 当前正在隐藏按钮的记录ID

  onPageShow() {
    this.loadRecords();
  }

  // 显示删除确认对话框
  showDeleteConfirmDialog() {
    AlertDialog.show({
      title: '删除记录',
      message: '确定要删除这条记录吗？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '取消',
        fontColor: $r('app.color.text_secondary'),
        backgroundColor: $r('app.color.button_secondary'),
        action: () => {
          // 不执行任何操作
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: $r('app.color.text_primary'),
        backgroundColor: $r('app.color.button_primary'),
        action: async () => {
          try {
            const recordToDelete = this.records.find(r => r.id === this.showingDeleteButtonId);
            if (recordToDelete) {
              // 从列表中除该记录
              const index = this.records.findIndex(r => r.id === recordToDelete.id);
              if (index !== -1) {
                this.records.splice(index, 1);
              }
              // 从数据库中删除记录
              await this.recordService.deleteRecord(recordToDelete.id);
            }
            // 隐藏删除按钮
            this.showingDeleteButtonId = '';
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
      }
    });
  }

  aboutToAppear() {
    emitter.on({ eventId: 101 }, () => {
      this.emptyAll()
    })

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

  @Builder
  HistoryTitle() {
    Stack() {
      Text('检测记录')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .textAlign(TextAlign.Center)

      Row() {
        Image($r('app.media.ic_back'))
          .width(DesignConstants.ICON_SIZE_LG)
          .height(DesignConstants.ICON_SIZE_LG)
          .fillColor($r('app.color.icon_primary'))
          .onClick(() => {
            this.navStack.pop()
          })
        Row() {
        }
        .layoutWeight(1)

        Row() {
          this.EmptyButton()
        }
        .width(56)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height(56)
    .backgroundColor($r('app.color.background_secondary'))
  }

  emptyAll = async () => {
    AlertDialog.show({
      title: '清空检测记录',
      message: '确定要清空检测记录吗？\n已收藏的记录将会保留',
      alignment: DialogAlignment.Center,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '取消',
        fontColor: $r('app.color.background_primary'),
        backgroundColor: $r('app.color.background_tertiary'),
        action: () => {
          // 不执行任何操作
        }
      },
      secondaryButton: {
        value: '清空',
        fontColor: $r('app.color.background_primary'),
        backgroundColor: $r('app.color.button_primary'),
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
  EmptyButton() {
    Button() {
      Text('清空')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
    }
    .height(32)
    .width(56)
    .backgroundColor($r('app.color.button_secondary'))
    .padding({
      left: DesignConstants.SPACING_MD,
      right: DesignConstants.SPACING_MD
    })
    .borderRadius(16)
    .onClick(this.emptyAll)
  }

  @Builder
  RecordItem(record: DecibelRecord) {
    Stack() {

      Column() {
        Row() {
          // 左侧位置和时间信息列
          Column() {
            Row() {
              // 位置信息显示
              Text(record.location || '未获取位置信息')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor(record.location ? $r('app.color.text_secondary') : $r('app.color.text_disabled'))
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
            }
            .width('100%')

            Row() {
              Text(record.comment || '无备注')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('app.color.text_secondary'))
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: DesignConstants.SPACING_SM })
            }

            Row() {
              // 时间信息
              Text(new Date(record.timestamp).toLocaleString('zh-CN', {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
              }))
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: DesignConstants.SPACING_SM }) // 减小间距
            }

            Row() {
              // 检测时长
              Text(`时长: ${Math.round(record.duration / 1000)}秒`)
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: DesignConstants.SPACING_SM })
            }


            // 收藏状态
            Row() {
              if (record.isFavorite) {
                Image($r('app.media.ic_favorite'))
                  .width(DesignConstants.ICON_SIZE_SM)
                  .height(DesignConstants.ICON_SIZE_SM)
                  .fillColor($r('app.color.icon_favorite'))
                  .animation({
                    duration: 450,
                    curve: Curve.EaseInOut,
                    iterations: 1,
                    playMode: PlayMode.Normal
                  })
              }
            }
            .width('100%')
            .height(DesignConstants.ICON_SIZE_SM)
            .margin({ top: DesignConstants.SPACING_XS })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1).flexShrink(1) // 添加弹性收缩


          // 右侧区域：分贝值信息
          Column() {
            Row() {
              Column() {
                Text('最小值')
                  .fontSize(DesignConstants.FONT_SIZE_SM)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ bottom: DesignConstants.SPACING_XS })
                Text(record.minDecibel.toString())
                  .fontSize(DesignConstants.FONT_SIZE_LG)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(DecibelService.getDecibelColor(record.minDecibel))
              }
              .height(40) // 固定高度确保对齐

              Column() {
                Text('平均值')
                  .fontSize(DesignConstants.FONT_SIZE_SM)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ bottom: DesignConstants.SPACING_XS })
                Text(record.avgDecibel.toString())
                  .fontSize(DesignConstants.FONT_SIZE_LG)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(DecibelService.getDecibelColor(record.avgDecibel))
              }
              .height(40) // 固定高度确保对齐
              .margin({ left: 24, right: 24 })

              Column() {
                Text('最大值')
                  .fontSize(DesignConstants.FONT_SIZE_SM)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ bottom: DesignConstants.SPACING_XS })
                Text(record.maxDecibel.toString())
                  .fontSize(DesignConstants.FONT_SIZE_LG)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(DecibelService.getDecibelColor(record.maxDecibel))
              }
              .height(40) // 固定高度确保对齐
            }

            Row() {
              if (record!.audioFilePath) {
                AudioPlayer({
                  audioFilePath: record!.audioFilePath,
                })
              }
            }.margin({ top: DesignConstants.SPACING_SM })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.SpaceBetween)
          .height('80')
          .alignItems(HorizontalAlign.End)
          .flexShrink(0) // 禁止收缩

        }
        .width('100%')
        .padding({
          left: 16,
          right: 16,
          top: 16
        })
        .onClick(() => {
          if (this.showingDeleteButtonId === record.id) {
            this.showingDeleteButtonId = '';
          } else {
            this.selectedRecord = record;
            this.showDetailDialog();

            const DETAIL_DIALOG_CLOSED_EVENT = 100101
            emitter.on({ eventId: DETAIL_DIALOG_CLOSED_EVENT }, (data: emitter.EventData) => {
              let id = data?.data?.id as string;
              if (id) {
                this.recordService.getRecordById(id).then((newRecord) => {
                  record!.comment = newRecord!.comment;
                });
              }
            })
          }
        })

        Divider()
          .width('92%')
          .color($r('app.color.divider_primary'))
      }
      .backgroundColor($r('app.color.background_primary'))
      .borderRadius(16)
      .margin({ left: 8, right: 8 })
      .translate({
        x: record.id === this.currentSlidingId ?
        this.currentSlideOffset : // 直接使用滑动偏移量
          (this.showingDeleteButtonId === record.id ? -160 : 0)
      })
      .scale({
        x: record.id === this.currentSlidingId && this.currentSlideOffset > 0 ?
          0.98 + (80 - this.currentSlideOffset) / 800 : 1,
        y: record.id === this.currentSlidingId && this.currentSlideOffset > 0 ?
          0.98 + (80 - this.currentSlideOffset) / 800 : 1
      })
      .animation({
        duration: 300,
        curve: Curve.EaseOut
      })
      .gesture(
        PanGesture({ direction: PanDirection.Horizontal })
          .onActionStart((event: GestureEvent) => {
            this.startX = event.offsetX;
            this.currentSlidingId = record.id;
            this.hasDeleteButtonOnStart = this.showingDeleteButtonId === record.id;
            this.currentSlideOffset = this.hasDeleteButtonOnStart ? -160 : 0;
          })
          .onActionUpdate((event: GestureEvent) => {
            if (this.currentSlidingId === record.id) {
              const deltaX = event.offsetX - this.startX;
              if (this.hasDeleteButtonOnStart) {
                // 如果开始时有按钮，则只处理右滑隐藏
                this.currentSlideOffset = -160 + deltaX; // 直接使用偏移量
                if (deltaX > 20) { // 降低右滑关闭阈值
                  this.pendingHideButtonId = record.id;
                  this.pendingDeleteId = ''; // 重置删除确认状态
                }
              } else {
                // 允许左滑显示按钮和右滑回弹
                this.currentSlideOffset = deltaX; // 直接使用偏移量
                if (deltaX > 20) { // 右滑时关闭所有按钮
                  this.pendingHideButtonId = record.id;
                  this.pendingDeleteId = ''; // 重置删除确认状态
                } else if (deltaX < -80) { // 左滑超过一半距离时显示按钮
                  this.showingDeleteButtonId = record.id;
                }
              }
            }
          })
          .onActionEnd(() => {
            if (this.currentSlidingId === record.id) {
              // 无论如何都回到初始位置
              animateTo({
                duration: 300,
                curve: Curve.EaseOut,
              }, () => {
                if (this.hasDeleteButtonOnStart) {
                  // 如果开始时有按钮，则处理隐藏按钮的操作
                  if (this.currentSlideOffset > -140) { // 降低右滑关闭阈值
                    this.showingDeleteButtonId = '';
                    this.pendingHideButtonId = '';
                    this.pendingDeleteId = ''; // 重置删除确认状态
                  }
                } else {
                  // 如果开始时没有按钮，处理显示按钮
                  if (this.currentSlideOffset < -80) { // 左滑超过一半距离时显示按钮
                    this.showingDeleteButtonId = record.id;
                    this.pendingHideButtonId = '';
                  } else if (this.currentSlideOffset > 20) { // 右滑时关闭所有按钮
                    this.showingDeleteButtonId = '';
                    this.pendingHideButtonId = '';
                    this.pendingDeleteId = ''; // 重置删除确认状态
                  }
                }
                this.currentSlideOffset =
                  this.showingDeleteButtonId === record.id ? -160 : 0;
                this.currentSlidingId = '';
              })
            }
          })
      )

      if (this.showingDeleteButtonId === record.id || this.currentSlidingId === record.id ||
        this.pendingHideButtonId === record.id) {
        // 右侧按钮组
        Row() {
          if (record.id === this.pendingDeleteId) {
            // 删除确认按钮
            Button() {
              Text('删除并清空检测报告')
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
                .width('100%')
                .padding({
                  left: DesignConstants.SPACING_SM,
                  right: DesignConstants.SPACING_SM
                })
            }
            .width(160)
            .height(96)
            .type(ButtonType.Normal)
            .backgroundColor($r('app.color.button_danger'))
            .onClick(() => {
              this.deleteRecord(record);
            })
          } else {
            // 常规按钮组
            Row() {
              // 收藏按钮
              Button() {
                Text(record.isFavorite ? '取消收藏' : '收藏')
                  .fontSize(DesignConstants.FONT_SIZE_MD)
                  .fontColor(record.isFavorite ? '#FF4081' : Color.White)
              }
              .width(80)
              .height(96)
              .type(ButtonType.Normal)
              .backgroundColor(record.isFavorite ? '#FFE0EB' : '#FF4081')
              .onClick(async () => {
                record.isFavorite = !record.isFavorite;
                await this.recordService.updateRecord(record);
                // 显示操作提示
                this.promptAction.showToast({
                  message: record.isFavorite ? '已添加到收藏' : '已取消收藏',
                  duration: 2000,
                  bottom: '50%'
                });
                // 平滑关闭按钮，跟随历史记录一起滑动
                this.currentSlidingId = record.id;
                this.pendingHideButtonId = record.id;
                animateTo({
                  duration: 300,
                  curve: Curve.EaseOut,
                }, () => {
                  this.currentSlideOffset = 0;
                  this.showingDeleteButtonId = '';
                  this.pendingHideButtonId = '';
                })
              })

              // 删除按钮
              Button() {
                Text('删除')
                  .fontSize(DesignConstants.FONT_SIZE_MD)
                  .fontColor(Color.White)
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .padding({
                    left: DesignConstants.SPACING_SM,
                    right: DesignConstants.SPACING_SM
                  })
              }
              .width(80)
              .height(96)
              .type(ButtonType.Normal)
              .backgroundColor('#666666')
              .onClick(() => {
                this.pendingDeleteId = record.id;
                this.showingDeleteButtonId = '';
                this.currentSlideOffset = -160;
                this.currentSlidingId = record.id;
              })
            }.justifyContent(FlexAlign.Center)
            .alignItems(VerticalAlign.Center)
          }
        }
        .width(160)
        .height(96)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .position({ x: '100%', y: 0 })
        .translate({
          x: record.id === this.currentSlidingId ?
          this.currentSlideOffset : // 直接使用滑动偏移量
            (this.showingDeleteButtonId === record.id ? -160 : 0)
        })
        .animation({
          duration: 300,
          curve: Curve.EaseOut
        })
      }
    }
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
      this.showingDeleteButtonId = '';
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

  async showDetailDialog() {
    if (!this.selectedRecord) {
      return;
    }

    try {
      // 创建导航参数
      const params: DetailDialogParams = {
        selectedRecord: this.selectedRecord,
        context: getContext(this),
        fileService: this.fileService
      };
      // 使用 NavPathInfo 创建导航信息
      const pathInfo = new NavPathInfo('DetailDialog', params);
      // 使用 pushPath 进行导航
      await this.navStack.pushPath(pathInfo);
    } catch (error) {
      console.error('导航到详情页失败:', error);
    }
  }

  build() {
    NavDestination() {
      Column() {
        // 内容区域
        if (this.records.length === 0) {
          this.EmptyStateView()
        } else {
          this.ListLayoutView()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.background_secondary'))
    }.title('历史记录').menus([{
      value: '清空记录',
      icon: $r('app.media.ic_delete'),
      action: () => {
        this.emptyAll();
      }
    }])
  }

  /**
   * 空状态视图
   */
  @Builder
  EmptyStateView() {
    Column() {
      Image($r('app.media.ic_empty'))
        .width(120)
        .height(120)
        .fillColor('#CCCCCC')
        .margin({ bottom: DesignConstants.SPACING_LG })
      Text('暂无检测记录')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontColor('#999999')
      Text('完成一次检测后即可查看记录')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor('#999999')
        .margin({ top: DesignConstants.SPACING_SM })
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor($r('app.color.background_secondary'))
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 列表布局视图
   */
  @Builder
  ListLayoutView() {
    List({ space: 0 }) {
      LazyForEach(this.dataSource, (record: DecibelRecord) => {
        ListItem() {
          Column() {
            this.RecordItem(record)
            Divider()
              .width('100%')
              .height(DesignConstants.SPACING_SM)
              .color($r('app.color.background_secondary'))
          }
        }
      }, (record: DecibelRecord) => record.id)

      // 总记录数显示
      ListItem() {
        Column() {
          Text(`共 ${this.records.length} 条记录`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding(16)

          Divider()
            .width('100%')
            .height(DesignConstants.SPACING_SM)
            .color($r('app.color.background_secondary'))
        }
      }
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor($r('app.color.background_secondary'))
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
    .listDirection(Axis.Vertical)
    .alignListItem(ListItemAlign.Start)
  }
}
