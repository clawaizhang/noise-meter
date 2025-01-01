import { DecibelRecord } from "../../models/DecibelRecord"
import { DecibelService } from "../../../../noise_meter/ets/services/DecibelService"
import { AudioPlayerService } from "../../services/AudioPlayerService"

// 标题栏构建器
@Builder
function DialogTitleBuilder(selectedRecord: DecibelRecord, closeDialog: () => void) {
  Row() {
    Row() {
      Text('检测详情')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
      if (selectedRecord!.isFavorite) {
        Image($r('app.media.ic_favorite'))
          .width(20)
          .height(20)
          .fillColor('#FF4081')
          .margin({ left: 8 })
      }
    }
    Blank()
    Button() {
      Image($r('app.media.ic_close'))
        .width(24)
        .height(24)
        .fillColor('#666666')
    }
    .type(ButtonType.Circle)
    .backgroundColor(Color.Transparent)
    .onClick(closeDialog)
  }
  .width('100%')
  .height(56)
  .padding({ left: 20, right: 12 })
}

// 基本信息构建器
@Builder
function BasicInfoBuilder(selectedRecord: DecibelRecord) {
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
      Text(new Date(selectedRecord!.timestamp).toLocaleString('zh-CN', {
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
      Text(`${Math.round(selectedRecord!.duration / 1000)}秒`)
        .fontSize(14)
        .fontColor('#333333')
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ bottom: 8 })

    if (selectedRecord!.location) {
      Row() {
        Text('检测位置')
          .fontSize(14)
          .fontColor('#666666')
        Text(selectedRecord!.location)
          .fontSize(14)
          .fontColor('#333333')
          .textAlign(TextAlign.End)
          .textOverflow({ overflow: TextOverflow.None })
          .width('70%')
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
}

// 统计数据构建器
@Builder
function StatisticsBuilder(selectedRecord: DecibelRecord, decibelService: DecibelService) {
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
          .margin({ bottom: 8 })
        Row() {
          Text(selectedRecord!.minDecibel.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(decibelService.getDecibelColor(selectedRecord!.minDecibel))
          Text(' 分贝')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ left: 4 })
            .alignSelf(ItemAlign.End)
            .margin({ bottom: 4 })
        }
        Text(decibelService.getDecibelLevel(selectedRecord!.minDecibel))
          .fontSize(12)
          .fontColor(decibelService.getDecibelColor(selectedRecord!.minDecibel))
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .height(90)

      Divider()
        .width(1)
        .height(60)
        .backgroundColor('#E0E0E0')
        .margin({ left: 12, right: 12 })

      Column() {
        Text('平均值')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ bottom: 8 })
        Row() {
          Text(selectedRecord!.avgDecibel.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(decibelService.getDecibelColor(selectedRecord!.avgDecibel))
          Text(' 分贝')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ left: 4 })
            .alignSelf(ItemAlign.End)
            .margin({ bottom: 4 })
        }
        Text(decibelService.getDecibelLevel(selectedRecord!.avgDecibel))
          .fontSize(12)
          .fontColor(decibelService.getDecibelColor(selectedRecord!.avgDecibel))
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .height(90)

      Divider()
        .width(1)
        .height(60)
        .backgroundColor('#E0E0E0')
        .margin({ left: 12, right: 12 })

      Column() {
        Text('最大值')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ bottom: 8 })
        Row() {
          Text(selectedRecord!.maxDecibel.toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(decibelService.getDecibelColor(selectedRecord!.maxDecibel))
          Text(' 分贝')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ left: 4 })
            .alignSelf(ItemAlign.End)
            .margin({ bottom: 4 })
        }
        Text(decibelService.getDecibelLevel(selectedRecord!.maxDecibel))
          .fontSize(12)
          .fontColor(decibelService.getDecibelColor(selectedRecord!.maxDecibel))
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      .height(90)
    }
    .width('100%')
  }
  .width('100%')
  .padding(16)
  .backgroundColor(Color.White)
  .borderRadius(12)
  .margin({ bottom: 12 })
}

// 分贝值变化图表构建器
@Builder
function ChartBuilder(selectedRecord: DecibelRecord, decibelService: DecibelService) {
  Column() {
    Text('分贝值变化')
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .alignSelf(ItemAlign.Start)
      .margin({ bottom: 12 })

    if (selectedRecord!.values.length === 0) {
      Column() {
        Image($r('app.media.ic_empty'))
          .width(32)
          .height(32)
          .fillColor('#999999')
          .margin({ bottom: 8 })
        Text('暂无分贝值变化数据')
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 20, bottom: 20 })
    } else {
      Row() {
        List({ space: 2, scroller: new Scroller() }) {
          ForEach(selectedRecord!.values, (value: number, index: number) => {
            ListItem() {
              Column() {
                Text(value.toString())
                  .fontSize(10)
                  .fontColor(decibelService.getDecibelColor(value))
                  .margin({ bottom: 4 })
                Column() {
                  Column()
                    .width(4)
                    .height(value)
                    .backgroundColor(decibelService.getDecibelColor(value))
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
  }
  .width('100%')
  .padding(16)
  .backgroundColor(Color.White)
  .borderRadius(12)
}

@Builder
function AudioPlaybackBuilder(selectedRecord: DecibelRecord) {
  if (selectedRecord!.audioData && selectedRecord!.audioData.length > 0) {
    Column() {
      Text('音频回放')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      Row() {
        Button() {
          Row() {
            Image($r('app.media.ic_play'))
              .width(20)
              .height(20)
              .fillColor('#666666')
              .margin({ right: 8 })
            Text('播放录音')
              .fontSize(14)
              .fontColor('#666666')
          }
        }
        .type(ButtonType.Capsule)
        .backgroundColor('#F5F5F5')
        .height(36)
        .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
  }
}

@Component
export struct DetailDialog {
  @Prop selectedRecord: DecibelRecord | null;
  @BuilderParam closeDialog: () => void;
  @State translateY: number = 0;
  @State isPlaying: boolean = false;
  private startY: number = 0;
  private decibelService: DecibelService = new DecibelService();
  private audioPlayerService: AudioPlayerService = new AudioPlayerService();

  aboutToDisappear() {
    // 停止音频播放
    this.audioPlayerService.stopPlaying();
  }

  @Builder
  AudioPlaybackBuilder(selectedRecord: DecibelRecord) {
    if (selectedRecord!.audioData && selectedRecord!.audioData.length > 0) {
      Column() {
        Text('音频回放')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 12 })

        Row() {
          Button() {
            Row() {
              Image(this.isPlaying ? $r('app.media.ic_stop') : $r('app.media.ic_play'))
                .width(20)
                .height(20)
                .fillColor('#666666')
                .margin({ right: 8 })
              Text(this.isPlaying ? '停止播放' : '播放录音')
                .fontSize(14)
                .fontColor('#666666')
            }
          }
          .type(ButtonType.Capsule)
          .backgroundColor('#F5F5F5')
          .height(36)
          .padding({ left: 16, right: 16 })
          .onClick(async () => {
            try {
              if (this.isPlaying) {
                await this.audioPlayerService.stopPlaying();
                this.isPlaying = false;
              } else {
                this.isPlaying = true;
                await this.audioPlayerService.playAudio(selectedRecord!.audioData!);
                this.isPlaying = false;
              }
            } catch (error) {
              console.error('音频播放失败:', error);
              this.isPlaying = false;
            }
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .margin({ bottom: 12 })
    }
  }

  build() {
    Column() {
      // 顶部拖动条
      Row() {
        Row()
          .width(40)
          .height(4)
          .borderRadius(2)
          .backgroundColor('#DDDDDD')
      }
      .width('100%')
      .height(20)
      .justifyContent(FlexAlign.Center)

      // 内容区域
      Column() {
        if (this.selectedRecord) {
          DialogTitleBuilder(this.selectedRecord, () => {
            this.closeDialog()
          })

          Column() {
            BasicInfoBuilder(this.selectedRecord)
            StatisticsBuilder(this.selectedRecord, this.decibelService)
            AudioPlaybackBuilder(this.selectedRecord)
            ChartBuilder(this.selectedRecord, this.decibelService)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 16 })
        }
      }
      .width('100%')
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
    .translate({ y: this.translateY })
    .gesture(
      PanGesture({ direction: PanDirection.Vertical })
        .onActionStart((event: GestureEvent) => {
          this.startY = event.offsetY;
        })
        .onActionUpdate((event: GestureEvent) => {
          const deltaY = event.offsetY - this.startY;
          // 只允许向下滑动
          if (deltaY > 0) {
            this.translateY = deltaY;
          }
        })
        .onActionEnd(() => {
          if (this.translateY > 100) {
            // 如果下滑超过阈值，关闭弹窗
            this.closeDialog();
          } else {
            // 否则回弹
            animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
              this.translateY = 0;
            });
          }
        })
    )
    .animation({
      duration: 300,
      curve: Curve.EaseOut
    })
  }
} 