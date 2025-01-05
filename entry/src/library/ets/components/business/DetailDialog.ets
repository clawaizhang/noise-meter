import { DecibelRecord } from "../../models/DecibelRecord"
import { DecibelService } from "../../../../noise_meter/ets/services/DecibelService"
import { AudioPlayerService, PlayerState } from "../../services/AudioPlayerService"
import common from '@ohos.app.ability.common'
import { FileService } from "../../services/FileService"
import hilog from '@ohos.hilog'

const TAG = 'DetailDialog';
const DOMAIN = 0x0000;

// 标题栏构建器
@Builder
function DialogTitleBuilder(selectedRecord: DecibelRecord, closeDialog: () => void) {
  Row() {
    Row() {
      Text('检测报告')
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
        .width('30%')
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
        .width('70%')
    }
    .width('100%')
    .margin({ bottom: 8 })

    Row() {
      Text('检测时长')
        .fontSize(14)
        .fontColor('#666666')
        .width('30%')
      Text(`${Math.round(selectedRecord!.duration / 1000)}秒`)
        .fontSize(14)
        .fontColor('#333333')
        .width('70%')
    }
    .width('100%')
    .margin({ bottom: 8 })

    if (selectedRecord!.location) {
      Row() {
        Text('检测位置')
          .fontSize(14)
          .fontColor('#666666')
          .width('30%')
        Text(selectedRecord!.location)
          .fontSize(14)
          .fontColor('#333333')
          .width('70%')
          .textOverflow({ overflow: TextOverflow.None })
      }
      .width('100%')
      .margin({ bottom: 8 })
    }
  }
  .width('100%')
  .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  .backgroundColor(Color.White)
  .borderRadius(12)
  .margin({ bottom: 12 })
}

// 噪音级别分布数据接口
interface NoiseSegment {
  name: string;
  value: number;
  color: string;
}

interface NoiseDistribution {
  segments: NoiseSegment[];
  values: number[];
}

@ComponentV2
export struct DetailDialog {
  @Param @Require selectedRecord: DecibelRecord | null;
  @Param @Require context: common.Context;
  @Param @Require  fileService: FileService | null;
  @BuilderParam closeDialog: () => void;
  @Local translateY: number = 0;
  @Local playerState: PlayerState = PlayerState.STATE_NOT_INIT;
  private startY: number = 0;
  private decibelService: DecibelService = new DecibelService();
  private audioPlayerService!: AudioPlayerService;
  @Local noiseDistribution: NoiseDistribution = { segments: [], values: [] };

  aboutToAppear() {
    // 初始化AudioPlayerService，使用传入的FileService
    if (!this.context) {
      hilog.error(DOMAIN, TAG, 'Context is not available');
      return;
    }
    if (!this.fileService) {
      hilog.error(DOMAIN, TAG, 'FileService is not available');
      return;
    }

    try {
      this.audioPlayerService = new AudioPlayerService(this.context, this.fileService);
      // 设置播放状态监听
      this.audioPlayerService.setOnStateChangeListener((state: PlayerState) => {
        this.playerState = state;
      });
      hilog.info(DOMAIN, TAG, 'AudioPlayerService 初始化成功');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'AudioPlayerService 初始化失败: %{public}s', error instanceof Error ? error.message : String(error));
    }

    // 计算噪音分布
    if (this.selectedRecord && this.selectedRecord.decibelValues.length > 0) {
      this.calculateNoiseDistribution();
    }
  }

  // 计算噪音级别分布
  private calculateNoiseDistribution() {
    const values = this.selectedRecord!.decibelValues;
    // 计算各个级别的数量
    const levelCounts = new Map<string, number>();
    values.forEach(value => {
      const level = this.decibelService.getDecibelLevel(value);
      levelCounts.set(level, (levelCounts.get(level) || 0) + 1);
    });

    // 定义级别顺序（从12点钟方向开始，顺时针排列）
    const levelOrder = ['极度危险', '危险', '嘈杂', '正常', '安静'];

    // 转换为饼图数据并按级别排序
    const segments: NoiseSegment[] = [];
    const total = values.length;

    levelOrder.forEach(level => {
      const count = levelCounts.get(level) || 0;
      if (count > 0) {
        // 找到该级别对应的一个分贝值用于获取颜色
        const sampleValue = values.find(v => this.decibelService.getDecibelLevel(v) === level) || 0;
        segments.push({
          name: level,
          value: Math.round((count / total) * 100),
          color: this.decibelService.getDecibelColor(sampleValue)
        });
      }
    });

    // 更新状态
    this.noiseDistribution = {
      segments: segments,
      values: segments.map(s => s.value)
    };
  }

  aboutToDisappear() {
    // 停止音频播放
    if (this.playerState === PlayerState.STATE_PLAYING || this.playerState === PlayerState.STATE_PAUSED) {
      this.audioPlayerService.stop();
    }
  }

  @Builder
  NoiseDistributionBuilder() {
    Column() {
      Text('噪音级别分布')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 8 })

      if (!this.selectedRecord || this.selectedRecord.decibelValues.length === 0) {
        Column() {
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 20, bottom: 20 })
      } else {
        Row() {
          // 饼图
          Stack() {
            DataPanel({
              values: this.noiseDistribution.values,
              max: 100,
              type: DataPanelType.Circle
            })
              .valueColors(this.noiseDistribution.segments.map(segment => segment.color))
              .trackBackgroundColor('#08182431')
              .width(160)
              .height(160)
          }
          .width(160)
          .height(160)
          .margin({ right: 16, top: -16 })

          // 图例
          Column() {
            ForEach(this.noiseDistribution.segments, (segment: NoiseSegment) => {
              Row() {
                Row()
                  .width(12)
                  .height(12)
                  .borderRadius(6)
                  .backgroundColor(segment.color)
                  .margin({ right: 8 })
                Text(segment.name)
                  .fontSize(14)
                  .fontColor('#333333')
                  .width(42)
                  .margin({ right: 2 })
                Text(`${segment.value}%`)
                  .fontSize(14)
                  .fontColor('#666666')
                  .width(40)
                  .textAlign(TextAlign.Start)
              }
              .margin({ bottom: 8 })
              .alignItems(VerticalAlign.Center)
              .justifyContent(FlexAlign.Start)
            })
          }
          .margin({ left: 16, top: -16 })
          .layoutWeight(1)
          .justifyContent(FlexAlign.End)
        }
        .width('100%')
        .padding({ left: 8, right: 16, top: 12, bottom: 12 })
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ bottom: 12 })
      }
    }
  }

  @Builder
  ChartBuilder(selectedRecord: DecibelRecord, decibelService: DecibelService) {
    Column() {
      Row() {
        Text('分贝值变化')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)

        if (selectedRecord!.audioFilePath) {
          Blank()
          Row() {
            // 添加停止按钮
            if (this.playerState === PlayerState.STATE_PLAYING || this.playerState === PlayerState.STATE_PAUSED) {
              Button() {
                Image($r('app.media.ic_stop'))
                  .width(20)
                  .height(20)
                  .fillColor('#666666')
              }
              .type(ButtonType.Normal)
              .backgroundColor(Color.Transparent)
              .margin({ right: 8 })
              .onClick(async () => {
                try {
                  await this.audioPlayerService.stop();
                } catch (error) {
                  hilog.error(DOMAIN, TAG, '停止播放失败: %{public}s', error instanceof Error ? error.message : String(error));
                }
              })
            }
            
            Button() {
              Row() {
                Image(this.playerState === PlayerState.STATE_PLAYING ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
                  .width(20)
                  .height(20)
                  .fillColor('#666666')
                  .margin({ right: 8 })
                Text(this.playerState === PlayerState.STATE_PLAYING ? '暂停播放' : '播放录音')
                  .fontSize(14)
                  .fontColor('#666666')
              }
              .alignItems(VerticalAlign.Center)
              .justifyContent(FlexAlign.Center)
            }
            .type(ButtonType.Capsule)
            .backgroundColor('#F5F5F5')
            .height(36)
            .padding({ left: 16, right: 16 })
            .onClick(async () => {
              try {
                if (this.playerState === PlayerState.STATE_PLAYING) {
                  // 如果正在播放,则暂停
                  await this.audioPlayerService.pause();
                } else {
                  // 如果未播放,检查播放器状态
                  if (this.playerState === PlayerState.STATE_PAUSED) {
                    // 如果是暂停状态,则继续播放
                    await this.audioPlayerService.resume();
                  } else {
                    // 其他状态(完成/错误/未初始化等),重新开始播放
                    if (this.selectedRecord?.audioFilePath) {
                      await this.audioPlayerService.playAudioFile(this.selectedRecord.audioFilePath);
                    }
                  }
                }
              } catch (error) {
                hilog.error(DOMAIN, TAG, '播放音频失败: %{public}s', error instanceof Error ? error.message : String(error));
              }
            })
          }
        }
      }
      .width('100%')
      .margin({ bottom: 12 })
      .alignItems(VerticalAlign.Center)

      if (selectedRecord!.decibelValues.length === 0) {
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
            ForEach(selectedRecord!.decibelValues, (value: number, index: number) => {
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
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12, top: -32 })
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
            Column() {
              // 统计数据部分
              Text('统计数据')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 8, top: -16 })

              Row() {
                Column() {
                  Text('最小值')
                    .fontSize(12)
                    .fontColor('#666666')
                    .margin({ bottom: 8 })
                  Row() {
                    Text(this.selectedRecord!.minDecibel.toString())
                      .fontSize(24)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.minDecibel))
                    Text(' 分贝')
                      .fontSize(12)
                      .fontColor('#666666')
                      .margin({ left: 4 })
                      .alignSelf(ItemAlign.End)
                      .margin({ bottom: 4 })
                  }
                  Text(this.decibelService.getDecibelLevel(this.selectedRecord!.minDecibel))
                    .fontSize(12)
                    .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.minDecibel))
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
                    Text(this.selectedRecord!.avgDecibel.toString())
                      .fontSize(24)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.avgDecibel))
                    Text(' 分贝')
                      .fontSize(12)
                      .fontColor('#666666')
                      .margin({ left: 4 })
                      .alignSelf(ItemAlign.End)
                      .margin({ bottom: 4 })
                  }
                  Text(this.decibelService.getDecibelLevel(this.selectedRecord!.avgDecibel))
                    .fontSize(12)
                    .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.avgDecibel))
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
                    Text(this.selectedRecord!.maxDecibel.toString())
                      .fontSize(24)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.maxDecibel))
                    Text(' 分贝')
                      .fontSize(12)
                      .fontColor('#666666')
                      .margin({ left: 4 })
                      .alignSelf(ItemAlign.End)
                      .margin({ bottom: 4 })
                  }
                  Text(this.decibelService.getDecibelLevel(this.selectedRecord!.maxDecibel))
                    .fontSize(12)
                    .fontColor(this.decibelService.getDecibelColor(this.selectedRecord!.maxDecibel))
                    .margin({ top: 8 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
                .height(90)
              }
              .width('100%')

              // 分割线
              Divider()
                .width('100%')
                .height(1)
                .backgroundColor('#E0E0E0')
                .margin({ top: 12, bottom: 16 })

              if (!this.selectedRecord || this.selectedRecord.decibelValues.length === 0) {
                Column() {
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
              } else {
                Row() {
                  // 饼图
                  Stack() {
                    DataPanel({
                      values: this.noiseDistribution.values,
                      max: 100,
                      type: DataPanelType.Circle
                    })
                      .valueColors(this.noiseDistribution.segments.map(segment => segment.color))
                      .trackBackgroundColor('#08182431')
                      .width(160)
                      .height(160)
                  }
                  .width(160)
                  .height(160)
                  .margin({ right: 16, top: -16 })

                  // 图例
                  Column() {
                    ForEach(this.noiseDistribution.segments, (segment: NoiseSegment) => {
                      Row() {
                        Row()
                          .width(12)
                          .height(12)
                          .borderRadius(6)
                          .backgroundColor(segment.color)
                          .margin({ right: 8 })
                        Text(segment.name)
                          .fontSize(14)
                          .fontColor('#333333')
                          .width(42)
                          .margin({ right: 2 })
                        Text(`${segment.value}%`)
                          .fontSize(14)
                          .fontColor('#666666')
                          .width(40)
                          .textAlign(TextAlign.Start)
                      }
                      .margin({ bottom: 8 })
                      .alignItems(VerticalAlign.Center)
                      .justifyContent(FlexAlign.Start)
                    })
                  }
                  .margin({ left: 16, top: -16 })
                  .layoutWeight(1)
                  .justifyContent(FlexAlign.End)
                }
                .width('100%')
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ bottom: 12 })
            this.ChartBuilder(this.selectedRecord, this.decibelService)
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