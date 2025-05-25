import { Theme } from '../ets/utils/Theme';
import { DetailDialogParams } from '../ets/pages/DetailDialogNavigation';
import { PromptAction } from '@ohos.arkui.UIContext';
import { DecibelService } from '../ets/services/DecibelService';
import { DecibelRecordService } from '../ets/services/DecibelRecordService';
import { noiseMeterNavStack } from '../ets/constants/ProviderConstant';
import { emitter } from '@kit.BasicServicesKit';
import { AudioPlayer } from '../ets/components/business/AudioPlayer';
import { CustomTitleBar } from '../ets/components/common/CustomTitleBar';
import { DecibelRecord } from '../ets/models/DecibelRecord';
import { FileService } from '../ets/services/FileService';

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
  @Consumer(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack()
  @Param currentTabIndex: number = 0
  @Local records: DecibelRecord[] = [];
  @Local dataSource: DecibelRecordDataSource = new DecibelRecordDataSource([]);
  @Local selectedRecord: DecibelRecord | null = null;
  @Local showingDeleteButtonId: string = ''; // 当前显示删除按钮的记录ID
  @Local currentSlidingId: string = ''; // 当前正在滑动的记录ID
  @Local currentSlideOffset: number = 0; // 当前滑动的偏移量
  @Local pendingDeleteId: string = ''; // 当前正在删除的记录ID
  private startX: number = 0;
  private hasDeleteButtonOnStart: boolean = false; // 滑动开始时是否有删除按钮示
  private context: Context = getContext(this)
  private recordService: DecibelRecordService = new DecibelRecordService(this.context);
  private promptAction: PromptAction = this.getUIContext().getPromptAction();
  private fileService: FileService = new FileService(this.context)
  private pendingHideButtonId: string = ''; // 当前正在隐藏按钮的记录ID

  @Monitor('currentTabIndex')
  onTabIndexChange(monitor: IMonitor) {
    const currentValue = monitor.value<number>()?.now;
    if (currentValue === 1) {
      this.loadRecords();
      this.dataSource.notifyDataReload();
    }
  }

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
        fontColor: Theme.getColor('text_secondary'),
        backgroundColor: Theme.getColor('button_secondary'),
        action: () => {
          // 不执行任何操作
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: Theme.getColor('text_primary'),
        backgroundColor: Theme.getColor('button_primary'),
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
    this.loadRecords();
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
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .textAlign(TextAlign.Center)

      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor(Theme.getColor('icon_primary'))
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
    .backgroundColor(Theme.getColor('background_secondary'))
  }

  emptyAll = async () => {
    AlertDialog.show({
      title: '清空检测记录',
      message: '确定要清空检测记录吗？\n已收藏的记录将会保留',
      alignment: DialogAlignment.Center,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '取消',
        fontColor: Theme.getColor('text_secondary'),
        backgroundColor: Theme.getColor('button_secondary'),
        action: () => {
          // 不执行任何操作
        }
      },
      secondaryButton: {
        value: '清空',
        fontColor: Theme.getColor('text_primary'),
        backgroundColor: Theme.getColor('button_primary'),
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
        .fontSize(14)
        .fontColor(Theme.getColor('text_secondary'))
        .textAlign(TextAlign.Center)
    }
    .height(32)
    .width(56)
    .backgroundColor(Theme.getColor('button_secondary'))
    .padding({ left: 12, right: 12 })
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
                .fontSize(12)
                .fontColor(record.location ? Theme.getColor('text_secondary') : Theme.getColor('text_disabled'))
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
            }
            .width('100%')

            Row() {
              Text(record.comment || '无备注')
                .fontSize(12)
                .fontColor(Theme.getColor('text_secondary'))
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 8})
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
                .fontSize(14)
                .fontColor(Theme.getColor('text_secondary'))
                .margin({ top: 8 }) // 减小间距
              // 检测时长
              Text(` 共: ${Math.round(record.duration / 1000)}秒`)
                .fontSize(14)
                .fontColor(Theme.getColor('text_secondary'))
                .margin({ top: 8 })
            }


            // 收藏状态
            Row() {
              if (record.isFavorite) {
                Image($r('app.media.ic_favorite'))
                  .width(16)
                  .height(16)
                  .fillColor(Theme.getColor('icon_favorite'))
                  .animation({
                    duration: 450,
                    curve: Curve.EaseInOut,
                    iterations: 1,
                    playMode: PlayMode.Normal
                  })
              }
            }
            .width('100%')
            .height(16)
            .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 右侧区域：分贝值信息
          Column() {
            Row() {
              Column() {
                Text('最小值')
                  .fontSize(12)
                  .fontColor(Theme.getColor('text_secondary'))
                  .margin({ bottom: 4 })
                Text(record.minDecibel.toString())
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(DecibelService.getDecibelColor(record.minDecibel))
              }
              .height(40) // 固定高度确保对齐

              Column() {
                Text('平均值')
                  .fontSize(12)
                  .fontColor(Theme.getColor('text_secondary'))
                  .margin({ bottom: 4 })
                Text(record.avgDecibel.toString())
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(DecibelService.getDecibelColor(record.avgDecibel))
              }
              .height(40) // 固定高度确保对齐
              .margin({ left: 24, right: 24 })

              Column() {
                Text('最大值')
                  .fontSize(12)
                  .fontColor(Theme.getColor('text_secondary'))
                  .margin({ bottom: 4 })
                Text(record.maxDecibel.toString())
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(DecibelService.getDecibelColor(record.maxDecibel))
              }
              .height(40) // 固定高度确保对齐
            }
            Row(){
              if (record!.audioFilePath) {
                AudioPlayer({
                  audioFilePath: record!.audioFilePath,
                })
              }
            }.margin({ top: 8 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.SpaceBetween)
          .height('80')
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .padding({  left: 16, right: 16, top: 16})
        .onClick(() => {
          if (this.showingDeleteButtonId === record.id) {
            this.showingDeleteButtonId = '';
          } else {
            this.selectedRecord = record;
            this.showDetailDialog();

            const DETAIL_DIALOG_CLOSED_EVENT = 100101
            emitter.on({eventId:DETAIL_DIALOG_CLOSED_EVENT}, (data:emitter.EventData) => {
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
          .color(Theme.getColor('divider_primary'))
      }
      .backgroundColor(Theme.getColor('background_primary'))
      .borderRadius(16)
      .margin({ left: 16,right:16 })
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
                this.currentSlideOffset = this.showingDeleteButtonId === record.id ? -160 : 0;
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
                .fontSize(14)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
                .width('100%')
                .padding({ left: 8, right: 8 })
            }
            .width(160)
            .height(96)
            .type(ButtonType.Normal)
            .backgroundColor(Theme.getColor('button_danger'))
            .onClick(() => {
              this.deleteRecord(record);
            })
          } else {
            // 常规按钮组
            Row() {
              // 收藏按钮
              Button() {
                Text(record.isFavorite ? '取消收藏' : '收藏')
                  .fontSize(14)
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
                  .fontSize(14)
                  .fontColor(Color.White)
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .padding({ left: 8, right: 8 })
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
    Column() {
      // 使用自定义标题栏
      CustomTitleBar({
        title: '检测记录',
        buttons: [{
          text: '清空',
          onClick: this.emptyAll
        }]
      })

      // 内容区域
      if (this.records.length === 0) {
        Column() {
          Image($r('app.media.ic_empty'))
            .width(120)
            .height(120)
            .fillColor('#CCCCCC')
            .margin({ bottom: 16 })
          Text('暂无检测记录')
            .fontSize(16)
            .fontColor('#999999')
          Text('完成一次检测后即可查看记录')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(Theme.getColor('background_secondary'))
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 0 }) {
          LazyForEach(this.dataSource, (record: DecibelRecord) => {
            ListItem() {
              Column() {
                this.RecordItem(record)
                Divider()
                  .width('100%')
                  .height(8)
                  .color(Theme.getColor('background_secondary'))
              }
            }
          }, (record: DecibelRecord) => record.id)

          // 总记录数显示
          ListItem() {
            Column() {
              Text(`共 ${this.records.length} 条记录`)
                .fontSize(14)
                .fontColor('#666666')
                .textAlign(TextAlign.Center)
                .width('100%')
                .padding(16)
              
              Divider()
                .width('100%')
                .height(8)
                .color(Theme.getColor('background_secondary'))
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(Theme.getColor('background_secondary'))
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .listDirection(Axis.Vertical)
        .alignListItem(ListItemAlign.Start)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.getColor('background_secondary'))
  }
}
