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
                Text(new Date(this.selectedRecord!.timestamp).toLocaleString())
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
    Column() {
      Row() {
        Column() {
          Text(new Date(record.timestamp).toLocaleString())
            .fontSize(14)
            .fontColor('#666666')
            .margin({ bottom: 8 })
          if (record.location) {
            Text(record.location)
              .fontSize(12)
              .fontColor('#999999')
          }
        }
        .alignItems(HorizontalAlign.Start)

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
          }

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
        this.selectedRecord = record;
        this.dialogController.open();
      })

      Divider()
        .width('92%')
        .color('#F5F5F5')
    }
    .backgroundColor(Color.White)
  }

  build() {
    Column() {
      // 顶部导航栏
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
              this.RecordItem(record)
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
          try {
            await this.recordService.clearRecords();
            this.records = [];
          } catch (error) {
            console.error('清空历史记录失败:', error);
          }
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