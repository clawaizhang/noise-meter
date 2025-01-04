import { DecibelRecord } from '../../library/ets/models/DecibelRecord';
import { DialogParams, DialogService } from '../../library/ets/services/DialogService';
import { DetailDialog } from '../../library/ets/components/business/DetailDialog';
import common from '@ohos.app.ability.common';
import { PromptAction } from '@ohos.arkui.UIContext';
import { DecibelService } from '../ets/services/DecibelService';
import { DecibelRecordService } from '../ets/services/DecibelRecordService';
import { FileService } from '../../library/ets/services/FileService';
import { noiseMeterNavStack } from '../ets/constant/ProviderConstant';

@Builder
function buildDialog(params: DialogParams) {
  DetailDialog({
    selectedRecord: params.selectedRecord,
    closeDialog: params.closeDialog,
    context: params.context,
    fileService: params.fileService
  })
}

export class DecibelHistoryController {
  emptyAll = () => {
  }
}

@Builder
function DecibelHistoryBuilder() {
  DecibelHistory()
}


@ComponentV2
export struct DecibelHistory {
  @Consumer(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack()
  @Local records: DecibelRecord[] = [];
  @Local selectedRecord: DecibelRecord | null = null;
  @Local showingDeleteButtonId: string = ''; // 当前显示删除按钮的记录ID
  @Local currentSlidingId: string = ''; // 当前正在滑动的记录ID
  @Local currentSlideOffset: number = 0; // 当前滑动的偏移量
  private startX: number = 0;
  private hasDeleteButtonOnStart: boolean = false; // 滑动开始时是否有删除按钮示
  private context: Context = getContext(this)
  private recordService: DecibelRecordService = new DecibelRecordService(this.context);
  private decibelService: DecibelService = new DecibelService();
  private promptAction: PromptAction = this.getUIContext().getPromptAction();
  private dialogService: DialogService = new DialogService();
  private fileService: FileService = new FileService(this.context)
  private pendingHideButtonId: string = ''; // 当前正在隐藏按钮的记录ID

  @Builder
  DetailDialogBuilder() {
    DetailDialog({
      selectedRecord: this.selectedRecord,
      context: this.context,
      fileService: this.fileService
    })
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
        fontColor: '#666666',
        backgroundColor: '#EEEEEE',
        action: () => {
          // 不执行任何操作
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#FFFFFF',
        backgroundColor: '#666666',
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
          .fillColor('#333333')
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
    .backgroundColor('#F5F5F5')
  }

  emptyAll = async () =>  {
    AlertDialog.show({
      title: '清空检测记录',
      message: '确定要清空检测记录吗？\n已收藏的记录将会保留',
      alignment: DialogAlignment.Center,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '取消',
        fontColor: '#666666',
        backgroundColor: '#EEEEEE',
        action: () => {
          // 不执行任何操作
        }
      },
      secondaryButton: {
        value: '清空',
        fontColor: '#FFFFFF',
        backgroundColor: '#666666',
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
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
    }
    .height(32)
    .width(56)
    .backgroundColor('#EEEEEE')
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
                .fontColor(record.location ? '#999999' : '#CCCCCC')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
            }
            .height(20) // 减小高度
            .width('100%')

            // 时间信息
            Text(new Date(record.timestamp).toLocaleString('zh-CN', {
              year: 'numeric',
              month: '2-digit',
              day: '2-digit',
              hour: '2-digit',
              minute: '2-digit',
              second: '2-digit',
              hour12: false
            }))
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 4 }) // 减小间距

            // 收藏状态
            Row() {
              if (record.isFavorite) {
                Image($r('app.media.ic_favorite'))
                  .width(16)
                  .height(16)
                  .fillColor('#FF4081')
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
                  .fontColor('#666666')
                  .margin({ bottom: 4 })
                Text(record.minDecibel.toString())
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.decibelService.getDecibelColor(record.minDecibel))
              }
              .height(40) // 固定高度确保对齐

              Column() {
                Text('平均值')
                  .fontSize(12)
                  .fontColor('#666666')
                  .margin({ bottom: 4 })
                Text(record.avgDecibel.toString())
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.decibelService.getDecibelColor(record.avgDecibel))
              }
              .height(40) // 固定高度确保对齐
              .margin({ left: 24, right: 24 })

              Column() {
                Text('最大值')
                  .fontSize(12)
                  .fontColor('#666666')
                  .margin({ bottom: 4 })
                Text(record.maxDecibel.toString())
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.decibelService.getDecibelColor(record.maxDecibel))
              }
              .height(40) // 固定高度确保对齐
            }

            // 检测时长
            Text(`检测时长: ${Math.round(record.duration / 1000)}秒`)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .padding(16)
        .onClick(() => {
          if (this.showingDeleteButtonId === record.id) {
            this.showingDeleteButtonId = '';
          } else {
            this.selectedRecord = record;
            this.showDetailDialog();
          }
        })

        Divider()
          .width('92%')
          .color('#F5F5F5')
      }
      .backgroundColor(Color.White)
      .translate({
        x: this.showingDeleteButtonId === record.id ? -160 :
          (record.id === this.currentSlidingId ? Math.min(80, Math.max(-160, this.currentSlideOffset)) : 0)
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
                this.currentSlideOffset = Math.max(-160, Math.min(80, -160 + deltaX));
                if (deltaX > 20) { // 降低右滑关闭阈值
                  this.pendingHideButtonId = record.id;
                }
              } else {
                // 允许左滑显示按钮和右滑回弹
                this.currentSlideOffset = Math.max(-160, Math.min(80, deltaX));
                if (deltaX > 20) { // 右滑时关闭所有按钮
                  this.pendingHideButtonId = record.id;
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
                  }
                } else {
                  // 如果开始时没有按钮，处理显示按钮
                  if (this.currentSlideOffset < -80) { // 左滑超过一半距离时显示按钮
                    this.showingDeleteButtonId = record.id;
                    this.pendingHideButtonId = '';
                  } else if (this.currentSlideOffset > 20) { // 右滑时关闭所有按钮
                    this.showingDeleteButtonId = '';
                    this.pendingHideButtonId = '';
                  }
                }
                this.currentSlideOffset = this.showingDeleteButtonId === record.id ? -160 : 0;
                this.currentSlidingId = '';
              })
            }
          })
      )

      if (this.showingDeleteButtonId === record.id || this.currentSlidingId === record.id || this.pendingHideButtonId === record.id) {
        // 右侧按钮组
        Row() {
          // 收藏按钮
          Button() {
            Image($r('app.media.ic_favorite'))
              .width(24)
              .height(24)
              .fillColor(record.isFavorite ? '#FF4081' : Color.White)
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
            Image($r('app.media.ic_delete'))
              .width(24)
              .height(24)
              .fillColor(Color.White)
          }
          .width(80)
          .height(96)
          .type(ButtonType.Normal)
          .backgroundColor('#666666')
          .onClick(() => {
            // 显示删除确认对话框
            this.showDeleteConfirmDialog();
          })
        }
        .width(160)
        .height(96)
        .position({ x: '100%', y: 0 })
        .translate({
          x: record.id === this.currentSlidingId ? 
            this.currentSlideOffset : // 直接使用滑动偏移量，不需要加160
            (this.showingDeleteButtonId === record.id ? -160 : 0)
        })
        .opacity(record.id === this.currentSlidingId ? 
          Math.min(1, Math.abs(this.currentSlideOffset) / 80) : // 根据滑动距离渐变显示
          (this.showingDeleteButtonId === record.id ? 1 : 0))
        .animation({
          duration: 300,
          curve: Curve.EaseOut
        })
      }
    }
  }

  showDetailDialog() {
    this.dialogService.showDetailDialog(
      this.getUIContext(),
      wrapBuilder(buildDialog),
      this.selectedRecord,
      getContext(this) as common.Context
    );
  }

  build() {
    NavDestination() {
      Column() {
        this.HistoryTitle()
        // 历史记录列表或空状态提示
        if (this.records.length > 0) {
          List() {
            ForEach(this.records, (record: DecibelRecord) => {
              ListItem() {
                Column() {
                  this.RecordItem(record)
                  Divider()
                    .width('100%')
                    .height(8)
                    .color('#F5F5F5')
                }
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('#F5F5F5')
          .scrollBar(BarState.Auto)
          .edgeEffect(EdgeEffect.Spring)
          .listDirection(Axis.Vertical)
        } else {
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
          .backgroundColor('#F5F5F5')
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
    .backgroundColor('#F5F5F5')
  }
} 