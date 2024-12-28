import { DecibelRecord } from '@ohos/library/src/main/ets/models/DecibelRecord';
import { DecibelRecordService } from '@ohos/library/src/main/ets/services/DecibelRecordService';
import { DecibelService } from '@ohos/library/src/main/ets/services/DecibelService';
import router from '@ohos.router';
import common from '@ohos.app.ability.common';

@CustomDialog
struct DetailDialog {
  @Link selectedRecord: DecibelRecord | null;
  private decibelService: DecibelService = new DecibelService();
  controller: CustomDialogController = new CustomDialogController({
    builder: null,
    alignment: DialogAlignment.Bottom
  });
  cancel: () => void = () => {};

  build() {
    Column() {
      if (this.selectedRecord) {
        // 标题栏
        Row() {
          Text('检测详情')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
          Blank()
          Button() {
            Image($r('app.media.ic_close'))
              .width(24)
              .height(24)
              .fillColor('#666666')
          }
          .type(ButtonType.Circle)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.controller.close();
            this.cancel();
          })
        }
        .width('100%')
        .height(56)
        .padding({ left: 20, right: 12 })

        Scroll() {
          Column() {
            // 基本信息
            Column() {
              Text('基本信息')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 12 })

              Row() {
                Text('检测时间')
                  .fontSize(14)
                  .fontColor('#666666')
                Text(new Date(this.selectedRecord!.timestamp).toLocaleString('zh-CN', {
                  year: 'numeric',
                  month: '2-digit',
                  day: '2-digit',
                  hour: '2-digit',
                  minute: '2-digit',
                  second: '2-digit',
                  hour12: false
                }))
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 8 })

              Row() {
                Text('检测时长')
                  .fontSize(14)
                  .fontColor('#666666')
                Text(`${Math.round(this.selectedRecord!.duration / 1000)}秒`)
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 8 })

              if (this.selectedRecord!.location) {
                Row() {
                  Text('检测位置')
                    .fontSize(14)
                    .fontColor('#666666')
                  Text(this.selectedRecord!.location)
                    .fontSize(14)
                    .fontColor('#333333')
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)
                .margin({ bottom: 8 })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ bottom: 12 })

            // 统计数据
            Column() {
              Text('统计数据')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 12 })

              Row() {
                Column() {
                  Text('最小值')
                    .fontSize(12)
                    .fontColor('#666666')
                    .margin({ bottom: 4 })
                  Text(this.selectedRecord!.minDecibel.toString())
                    .fontSize(20)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.minDecibel))
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)

                Column() {
                  Text('平均值')
                    .fontSize(12)
                    .fontColor('#666666')
                    .margin({ bottom: 4 })
                  Text(this.selectedRecord!.avgDecibel.toString())
                    .fontSize(20)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.avgDecibel))
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)

                Column() {
                  Text('最大值')
                    .fontSize(12)
                    .fontColor('#666666')
                    .margin({ bottom: 4 })
                  Text(this.selectedRecord!.maxDecibel.toString())
                    .fontSize(20)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.maxDecibel))
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ bottom: 12 })

            // 分贝值变化图表
            Column() {
              Text('分贝值变化')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 12 })

              Row() {
                List({ space: 2, scroller: new Scroller() }) {
                  ForEach(this.selectedRecord!.values, (value: number, index: number) => {
                    ListItem() {
                      Column() {
                        Text(value.toString())
                          .fontSize(10)
                          .fontColor(this.decibelService.getDecibelColor(value))
                          .margin({ bottom: 4 })
                        Column() {
                          Column()
                            .width(4)
                            .height(value)
                            .backgroundColor(this.decibelService.getDecibelColor(value))
                        }
                        .width(4)
                        .height(100)
                        .backgroundColor('#F5F5F5')
                        .alignItems(HorizontalAlign.Center)
                        .justifyContent(FlexAlign.End)
                      }
                    }
                  })
                }
                .listDirection(Axis.Horizontal)
                .width('100%')
                .height(140)
                .edgeEffect(EdgeEffect.Spring)
              }
              .width('100%')
              .height(140)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#F5F5F5')
      }
    }
    .width('100%')
    .height('90%')
    .backgroundColor('#F5F5F5')
    .borderRadius({ topLeft: 24, topRight: 24 })
    .clip(true)
  }
}

@Entry
@Component
struct DecibelHistory {
  @State records: DecibelRecord[] = [];
  @State selectedRecord: DecibelRecord | null = null;
  @State showingDeleteButtonId: string = '';  // 当前显示删除按钮的记录ID
  @State currentSlidingId: string = '';  // 当前正在滑动的记录ID
  @State currentSlideOffset: number = 0;  // 当前滑动的偏移量
  private startX: number = 0;
  private hasDeleteButtonOnStart: boolean = false;  // 滑动开始时是否有删除按钮显示
  private recordService: DecibelRecordService = new DecibelRecordService(getContext(this) as common.UIAbilityContext);
  private decibelService: DecibelService = new DecibelService();
  dialogController: CustomDialogController = new CustomDialogController({
    builder: DetailDialog({
      selectedRecord: $selectedRecord,
      cancel: () => {
        this.selectedRecord = null;
      }
    }),
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: 0 },
    customStyle: true,
    autoCancel: true
  });

  // 显示删除确认对话框
  showDeleteConfirmDialog() {
    AlertDialog.show({
      title: '删除记录',
      message: '确定要删除这条记录吗？',
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        fontColor: '#666666',
        backgroundColor: '#F5F5F5',
        action: () => {
          // 不执行任何操作
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#FFFFFF',
        backgroundColor: '#FF4081',
        action: async () => {
          try {
            const recordToDelete = this.records.find(r => r.id === this.showingDeleteButtonId);
            if (recordToDelete) {
              // 从列表中移除该记录
              const index = this.records.findIndex(r => r.id === recordToDelete.id);
              if (index !== -1) {
                this.records.splice(index, 1);
              }
              // 更新存储
              await this.recordService.saveRecords(this.records);
              // 隐藏删除按钮
              this.showingDeleteButtonId = '';
            }
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
  RecordItem(record: DecibelRecord) {
    Stack() {
      Column() {
        Row() {
          // 左侧区域：收藏图标和时间信息
          Row() {
            // 收藏图标区域
            Row() {
              if (record.isFavorite) {
                Image($r('app.media.ic_favorite'))
                  .width(16)
                  .height(16)
                  .fillColor('#FF4081')
              }
            }
            .width(24)
            .height(16)
            .justifyContent(FlexAlign.Center)
            
            // 时间和位置信息
            Column() {
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
                .margin({ bottom: 8 })
              if (record.location) {
                Text(record.location)
                  .fontSize(12)
                  .fontColor('#999999')
              }
              Text(`检测时长: ${Math.round(record.duration / 1000)}秒`)
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 8 })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)
          .alignItems(VerticalAlign.Top)

          // 右侧区域：分贝值信息
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
            .alignItems(HorizontalAlign.Center)

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
            .margin({ left: 16, right: 16 })
            .alignItems(HorizontalAlign.Center)

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
            .alignItems(HorizontalAlign.Center)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.SpaceEvenly)
        }
        .width('100%')
        .padding(16)
        .onClick(() => {
          if (this.showingDeleteButtonId === record.id) {
            this.showingDeleteButtonId = '';
          } else {
            this.selectedRecord = record;
            this.dialogController.open();
          }
        })

        Divider()
          .width('92%')
          .color('#F5F5F5')
      }
      .backgroundColor(Color.White)
      .translate({ 
        x: this.showingDeleteButtonId === record.id ? -80 : 
           (record.id === this.currentSlidingId ? Math.min(0, Math.max(-80, this.currentSlideOffset)) : 0)
      })
      .scale({
        x: record.id === this.currentSlidingId && this.currentSlideOffset > 40 ? 
           0.95 + (80 - this.currentSlideOffset) / 800 : 1,
        y: record.id === this.currentSlidingId && this.currentSlideOffset > 40 ? 
           0.95 + (80 - this.currentSlideOffset) / 800 : 1
      })
      .animation({
        duration: 300,
        curve: Curve.EaseOut
      })
      .gesture(
        PanGesture()
          .onActionStart((event: GestureEvent) => {
            this.startX = event.offsetX;
            this.currentSlidingId = record.id;
            this.hasDeleteButtonOnStart = this.showingDeleteButtonId === record.id;
            this.currentSlideOffset = this.hasDeleteButtonOnStart ? -80 : 0;
          })
          .onActionUpdate((event: GestureEvent) => {
            if (this.currentSlidingId === record.id) {
              const deltaX = event.offsetX - this.startX;
              if (this.hasDeleteButtonOnStart) {
                // 果开始时有删除按钮，则只处理右滑隐藏
                this.currentSlideOffset = Math.max(-80, Math.min(0, -80 + deltaX));
                if (deltaX > 40) {  // 右滑超过一半距离时隐藏删除按钮
                  this.showingDeleteButtonId = '';
                }
              } else {
                // 如果开始时没有删除按钮，则处理左右滑动
                this.currentSlideOffset = Math.max(-80, Math.min(80, deltaX));
                if (deltaX < -40) {  // 左滑超过一半距离时显示删除按钮
                  this.showingDeleteButtonId = record.id;
                }
              }
            }
          })
          .onActionEnd(() => {
            if (this.currentSlidingId === record.id) {
              if (this.hasDeleteButtonOnStart) {
                // 如果开始时有删除按钮，则只处理隐藏删除按钮的操作
                if (this.currentSlideOffset > -40) {  // 右滑超过一半距离时隐藏
                  this.showingDeleteButtonId = '';
                }
                this.currentSlideOffset = this.showingDeleteButtonId === record.id ? -80 : 0;
              } else {
                // 如果开始时没有删除按钮，则处理收藏和显示删除按钮的操作
                if (this.currentSlideOffset < -40) {  // 左滑超过半距离时显示删除按钮
                  this.showingDeleteButtonId = record.id;
                  this.currentSlideOffset = -80;
                } else if (this.currentSlideOffset > 40) {  // 右滑超过阈值时收藏/取消收藏
                  record.isFavorite = !record.isFavorite;
                  // 更新存储
                  this.recordService.saveRecords(this.records);
                }
                this.currentSlideOffset = 0;
              }
              this.currentSlidingId = '';
            }
          })
      )

      if (this.showingDeleteButtonId === record.id || this.currentSlidingId === record.id) {
        // 左侧收藏按钮
        Row() {
          Button() {
            Image($r('app.media.ic_favorite'))
              .width(24)
              .height(24)
              .fillColor(record.isFavorite ? '#FF4081' : Color.White)
          }
          .width(80)
          .height(90)
          .type(ButtonType.Normal)
          .backgroundColor(record.isFavorite ? '#FFE0EB' : '#FF4081')
          .onClick(() => {
            record.isFavorite = !record.isFavorite;
            this.recordService.saveRecords(this.records);
            this.currentSlideOffset = 0;  // 点击后收起按钮
            this.currentSlidingId = '';
          })
        }
        .width(80)
        .height(90)
        .position({ x: '-80vp', y: 0 })
        .translate({ 
          x: this.currentSlideOffset > 0 ? Math.min(80, this.currentSlideOffset) : 0
        })
        .opacity(Math.min(1, Math.abs(this.currentSlideOffset) / 80))
        .animation({
          duration: 300,
          curve: Curve.EaseOut
        })

        // 右侧删除按钮
        Row() {
          Button() {
            Image($r('app.media.ic_delete'))
              .width(24)
              .height(24)
              .fillColor(Color.White)
          }
          .width(80)
          .height(90)
          .type(ButtonType.Normal)
          .backgroundColor('#FF4081')
          .onClick(async () => {
            // 显示删除确认对话框
            this.showDeleteConfirmDialog();
          })
        }
        .width(80)
        .height(90)
        .position({ x: '100%', y: 0 })
        .translate({ 
          x: this.showingDeleteButtonId === record.id ? -80 : 
             Math.max(-80, Math.min(0, this.currentSlideOffset + 80))
        })
        .opacity(this.showingDeleteButtonId === record.id ? 1 : 
                Math.min(1, Math.abs(this.currentSlideOffset) / 80))
        .animation({
          duration: 300,
          curve: Curve.EaseOut
        })
      }
    }
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .onClick(() => {
            router.back();
          })
        Text('历史记录')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

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

        // 清空按钮
        Button({
          type: ButtonType.Capsule
        }) {
          Text('清空历史记录')
            .fontSize(16)
            .fontColor(Color.White)
        }
        .width('92%')
        .height(48)
        .backgroundColor('#FF4081')
        .margin({ bottom: 16 })
        .onClick(async () => {
          AlertDialog.show({
            title: '清空历史记录',
            message: '确定要清空历史记录吗？\n已收藏的记录将会保留',
            alignment: DialogAlignment.Center,
            primaryButton: {
              value: '取消',
              fontColor: '#666666',
              backgroundColor: '#F5F5F5',
              action: () => {
                // 不执行任何操作
              }
            },
            secondaryButton: {
              value: '清空',
              fontColor: '#FFFFFF',
              backgroundColor: '#FF4081',
              action: async () => {
                try {
                  // 保留收藏的记录
                  const favoriteRecords = this.records.filter(r => r.isFavorite);
                  this.records = favoriteRecords;
                  await this.recordService.saveRecords(this.records);
                } catch (error) {
                  console.error('清空历史记录失败:', error);
                }
              }
            }
          });
        })
      } else {
        Column() {
          Image($r('app.media.ic_empty'))
            .width(120)
            .height(120)
            .fillColor('#CCCCCC')
            .margin({ bottom: 16 })
          Text('暂无历史记录')
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
  }
} 