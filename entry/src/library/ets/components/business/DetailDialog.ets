import { DecibelRecord } from "../../models/DecibelRecord"
import { DecibelService } from "../../../../noise_meter/ets/services/DecibelService"
import { AudioPlayerService, PlayerState } from "../../services/AudioPlayerService"
import common from '@ohos.app.ability.common'
import { FileService } from "../../services/FileService"
import hilog from '@ohos.hilog'
import { noiseMeterNavStack } from '../../../../noise_meter/ets/constant/ProviderConstant'
import { JSON } from '@kit.ArkTS'
import { display } from "@kit.ArkUI"
import { ScreenshotUtils } from "../../utils/ScreenshotUtils"

const TAG = 'DetailDialog';
const DOMAIN = 0x0000;

export interface DetailDialogParams {
  selectedRecord: DecibelRecord;
  context: common.Context;
  fileService: FileService;
}

// 标题栏构建器
@Builder
function DialogTitleBuilder(
  selectedRecord: DecibelRecord,
  closeDialog: () => void,
  onShare: () => Promise<void>
) {
  Row() {
    Row() {
      Text('噪音检测报告')
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
      Image($r('app.media.ic_share'))
        .width(24)
        .height(24)
        .fillColor('#666666')
    }
    .type(ButtonType.Circle)
    .backgroundColor(Color.Transparent)
    .onClick(onShare)
    .margin({ right: 8 })

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
      Text(`${(selectedRecord!.duration / 1000).toFixed(1)}秒`)
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
  .padding({
    left: 16,
    right: 16,
    top: 12,
    bottom: 12
  })
  .backgroundColor(Color.White)
  .borderRadius(12)
  .margin({ bottom: 12 })
}

// 定义边距接口
interface Margin {
  top: number;
  right: number;
  bottom: number;
  left: number;
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
  @Consumer(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack();
  @Local selectedRecord: DecibelRecord | null = null;
  @Local context: common.Context | null = null;
  @Local fileService: FileService | null = null;
  @Local translateY: number = 1000;
  @Local playerState: PlayerState = PlayerState.STATE_NOT_INIT;
  private startY: number = 0;
  private decibelService: DecibelService = new DecibelService();
  private audioPlayerService!: AudioPlayerService;
  @Local noiseDistribution: NoiseDistribution = { segments: [], values: [] };
  @Local private bgOpacity: number = 0;
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true) // Canvas设置
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings) // Canvas上下文
  private canvasWidth = 320;
  private canvasHeight = 160;

  async aboutToAppear() {
    try {
      // 初始化时设置背景透明度为0
      this.bgOpacity = 0;
      // 从导航参数获取数据
      const params = JSON.parse(JSON.stringify(this.navStack.getParamByName('DetailDialog'))) as DetailDialogParams[];

      if (!params || typeof params !== 'object') {
        hilog.error(DOMAIN, TAG, '导航参数无效');
        return;
      }
      const param = params[0];
      // 类型检查
      if (!param.selectedRecord || !param.context || !param.fileService) {
        hilog.error(DOMAIN, TAG, '导航参数缺少必要字段');
        return;
      }

      // 获取实际可用区域
      const availableArea = await display.getDefaultDisplaySync().getAvailableArea();

      // 先把可用区域的像素转换为vp
      const availableWidthVp = px2vp(availableArea.width);
      const availableHeightVp = px2vp(availableArea.height);

      // 然后用vp单位进行计算
      this.canvasWidth = availableWidthVp - 32;
      this.canvasHeight = this.canvasWidth / 1.5;

      this.selectedRecord = param.selectedRecord;
      this.context = param.context;
      this.fileService = param.fileService;

      // 初始化AudioPlayerService
      if (!this.context) {
        hilog.error(DOMAIN, TAG, 'Context is not available');
        return;
      }
      if (!this.fileService) {
        hilog.error(DOMAIN, TAG, 'FileService is not available');
        return;
      }

      this.audioPlayerService = new AudioPlayerService(this.context, this.fileService);
      // 设置播放状态监听
      this.audioPlayerService.setOnStateChangeListener((state: PlayerState) => {
        this.playerState = state;
      });
      hilog.info(DOMAIN, TAG, 'AudioPlayerService 初始化成功');

      // 计算噪音分布
      if (this.selectedRecord && this.selectedRecord.decibelValues.length > 0) {
        this.calculateNoiseDistribution();
      }

      // 弹窗出现动画
      animateTo({ duration: 800, curve: Curve.Smooth }, () => {
        this.translateY = 0;
        // 在弹窗动画的回调中，延迟执行蒙层动画
        setTimeout(() => {
          animateTo({ duration: 400, curve: Curve.EaseIn }, () => {
            this.bgOpacity = 0.3;
          });
        }, 400);
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化失败: %{public}s', error instanceof Error ? error.message : String(error));
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
    const levelOrder = ['难以忍受', '非常吵闹', '吵闹', '一般', '安静', '非常安静'];

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
          value: parseFloat(((count / total) * 100).toFixed(1)),
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
  ChartBuilder(selectedRecord: DecibelRecord, decibelService: DecibelService) {
    Column() {
      Row() {
        Text('声级-时间散点图')
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
                  hilog.error(DOMAIN, TAG, '停止播放失败: %{public}s',
                    error instanceof Error ? error.message : String(error));
                }
              })
            }

            Button() {
              Row() {
                Image(this.playerState === PlayerState.STATE_PLAYING ? $r('app.media.ic_pause') :
                $r('app.media.ic_play'))
                  .width(20)
                  .height(20)
                  .fillColor('#666666')
                  .margin({ right: 8 })
                Text(this.playerState === PlayerState.STATE_PLAYING ? '暂停播放' :
                  this.playerState === PlayerState.STATE_PAUSED ? '继续播放' : '播放录音')
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
                  await this.audioPlayerService.pause();
                } else {
                  if (this.playerState === PlayerState.STATE_PAUSED) {
                    await this.audioPlayerService.resume();
                  } else {
                    if (this.selectedRecord?.audioFilePath) {
                      await this.audioPlayerService.playAudioFile(this.selectedRecord.audioFilePath);
                    }
                  }
                }
              } catch (error) {
                hilog.error(DOMAIN, TAG, '播放音频失败: %{public}s',
                  error instanceof Error ? error.message : String(error));
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
        Column() {
          // Canvas 容器
          Canvas(this.canvasContext)
            .width(this.canvasWidth)
            .height(this.canvasHeight)
            .onReady(() => {
              const values = selectedRecord.decibelValues;
              const duration = selectedRecord.duration;
              const maxValue = Math.max(...values);
              const minValue = Math.min(...values);

              // 设置边距
              const margin: Margin = {
                top: vp2px(2),
                right: vp2px(2),
                bottom: vp2px(4),
                left: vp2px(6)
              };
              const chartWidth = this.canvasContext.width - margin.left - margin.right;
              const chartHeight = this.canvasContext.height - margin.top - margin.bottom;

              // 清空画布
              this.canvasContext.clearRect(0, 0, this.canvasContext.width, this.canvasContext.height);

              // 绘制背景
              this.canvasContext.fillStyle = '#F5F5F5';
              this.canvasContext.fillRect(margin.left, margin.top, chartWidth, chartHeight);

              // 设置字体样式
              this.canvasContext.font = `${vp2px(12)}px sans-serif`;
              this.canvasContext.textBaseline = 'middle';

              // 绘制网格线
              this.canvasContext.strokeStyle = '#E0E0E0';
              this.canvasContext.lineWidth = 1;

              // 计算Y轴刻度
              const yMin = Math.floor(minValue);
              const yMax = Math.ceil(maxValue);
              const range = yMax - yMin;

              // 计算最佳步长
              let bestStep = 5; // 默认步长为5
              let bestGridCount = Math.ceil(range / bestStep);

              // 调整步长使刻度数在5-7之间
              while (bestGridCount < 5) {
                bestStep /= 2;
                bestGridCount = Math.ceil(range / bestStep);
              }
              while (bestGridCount > 7) {
                bestStep *= 2;
                bestGridCount = Math.ceil(range / bestStep);
              }

              // 计算刻度列表
              const ticks: number[] = [];

              // 计算第一个刻度，确保以0或5结尾
              let firstTick = Math.floor(yMin / 5) * 5;
              if (firstTick < yMin) {
                firstTick += 5;
              }
              ticks.push(firstTick);

              // 计算后续刻度
              let current = firstTick;
              while (current < yMax) {
                current += bestStep;
                // 确保刻度值以0或5结尾
                const roundedValue = Math.round(current / 5) * 5;
                if (roundedValue <= yMax) {
                  ticks.push(roundedValue);
                } else {
                  ticks.push(yMax);
                  break;
                }
              }

              // 确保刻度数在5-7之间
              if (ticks.length < 5) {
                // 补充刻度
                const lastTick = ticks[ticks.length - 1];
                while (ticks.length < 5) {
                  const newTick = lastTick + bestStep;
                  ticks.push(Math.min(newTick, yMax));
                }
              } else if (ticks.length > 7) {
                // 截断刻度
                ticks.length = 7;
                ticks[6] = yMax;
              }

              // 绘制更细的辅助线
              this.canvasContext.strokeStyle = '#E8E8E8'; // 加深辅助线颜色
              this.canvasContext.lineWidth = 0.5; // 更细的线宽
              const ySubStep = bestStep / 2; // 在主要网格线之间添加辅助线
              for (let i = yMin; i <= yMax; i += ySubStep) {
                const y = margin.top + chartHeight - ((i - yMin) / (yMax - yMin)) * chartHeight;
                this.canvasContext.beginPath();
                this.canvasContext.moveTo(margin.left, y);
                this.canvasContext.lineTo(margin.left + chartWidth, y);
                this.canvasContext.stroke();
              }

              // 统一主要网格线样式
              this.canvasContext.strokeStyle = '#E0E0E0'; // 加深主要网格线颜色
              this.canvasContext.lineWidth = 1; // 保持线宽一致

              // 绘制Y轴单位
              this.canvasContext.fillStyle = '#666666';
              this.canvasContext.textAlign = 'right';
              this.canvasContext.fillText('分贝', margin.left - vp2px(2), margin.top - vp2px(10));

              // 绘制Y轴刻度
              for (let i = yMin; i <= yMax; i += bestStep) {
                const y = margin.top + chartHeight - ((i - yMin) / (yMax - yMin)) * chartHeight;
                this.canvasContext.fillText(`${i}`, margin.left - vp2px(2), y);
              }

              // 重新设计X轴刻度计算逻辑
              const totalSeconds = duration / 1000;
              const targetXGridCount = 7; // 显示6-8个网格
              const extendedSeconds = Math.max(totalSeconds * 1.1, 0.1); // 增加10%时间跨度，最小0.1秒

              // 计算最佳步长
              let xInterval: number;
              if (totalSeconds >= 3) {
                // 长时间：使用整数刻度
                xInterval = Math.ceil(extendedSeconds / targetXGridCount);
                // 确保步长是合理的整数
                const possibleSteps = [1, 2, 5, 10, 15, 20, 30, 60];
                xInterval = possibleSteps.find(step => step >= xInterval) || xInterval;
              } else {
                // 短时间：使用小数刻度
                xInterval = extendedSeconds / targetXGridCount;
                // 确保步长是0.1的倍数
                xInterval = Math.round(xInterval * 10) / 10; // 使用round而不是ceil
                xInterval = Math.max(xInterval, 0.1); // 最小0.1秒
              }

              // 确保最后一个刻度 >= 总时间
              let actualGridCount = Math.ceil(extendedSeconds / xInterval);
              if ((actualGridCount - 1) * xInterval < totalSeconds) {
                actualGridCount = Math.ceil(totalSeconds / xInterval) + 1;
              }
              const xStep = chartWidth / (actualGridCount - 1);

              // 格式化时间显示，保留1位小数
              const formatTime = (seconds: number) => {
                return seconds % 1 === 0 ? `${seconds}` : `${seconds.toFixed(1)}`;
              };

              // 绘制X轴单位
              this.canvasContext.textAlign = 'center';
              this.canvasContext.fillText('秒', margin.left + chartWidth / 2, margin.top + chartHeight + vp2px(12));

              // 绘制X轴刻度
              for (let i = 0; i < targetXGridCount; i++) {
                const x = margin.left + i * xStep;
                const seconds = i * xInterval;
                this.canvasContext.fillText(formatTime(seconds), x, margin.top + chartHeight + vp2px(2));

                // 绘制X轴主要网格线
                this.canvasContext.beginPath();
                this.canvasContext.moveTo(x, margin.top);
                this.canvasContext.lineTo(x, margin.top + chartHeight);
                this.canvasContext.stroke();
              }

              // 绘制Y轴主要网格线
              for (let i = yMin; i <= yMax; i += bestStep) {
                const y = margin.top + chartHeight - ((i - yMin) / (yMax - yMin)) * chartHeight;
                this.canvasContext.beginPath();
                this.canvasContext.moveTo(margin.left, y);
                this.canvasContext.lineTo(margin.left + chartWidth, y);
                this.canvasContext.stroke();
              }

              // 绘制X轴辅助线
              this.canvasContext.strokeStyle = '#F0F0F0';
              this.canvasContext.lineWidth = 0.5;
              const xSubStep = xStep / 2;
              for (let i = 0; i < targetXGridCount * 2; i++) {
                const x = margin.left + i * xSubStep;
                this.canvasContext.beginPath();
                this.canvasContext.moveTo(x, margin.top);
                this.canvasContext.lineTo(x, margin.top + chartHeight);
                this.canvasContext.stroke();
              }

              // 恢复主要网格线样式
              this.canvasContext.strokeStyle = '#E0E0E0';
              this.canvasContext.lineWidth = 1;

              // 绘制数据点
              // 计算x轴比例，考虑边距
              const xScale = (chartWidth - margin.left - margin.right) / totalSeconds;
              const yScale = chartHeight / (maxValue - minValue);

              // 计算每个点的时间间隔
              const timeInterval = totalSeconds / (values.length - 1);

              // 定义颜色缓存
              const colorCache = new Map<number, string>();

              values.forEach((value, index) => {
                // 计算当前点的时间位置
                const currentTime = index * timeInterval;
                // 计算x坐标，确保在图表区域内
                const x = Math.min(
                  margin.left + currentTime * xScale,
                  margin.left + chartWidth - margin.right
                );
                const y = margin.top + chartHeight - (value - minValue) * yScale;

                // 获取颜色，使用缓存提高性能
                let color = colorCache.get(value);
                if (!color) {
                  color = decibelService.getDecibelColor(value);
                  colorCache.set(value, color);
                }

                // 绘制点
                this.canvasContext.fillStyle = color;
                this.canvasContext.beginPath();
                this.canvasContext.arc(x, y, 1.5, 0, Math.PI * 2);
                this.canvasContext.fill();

                // 绘制连线
                if (index > 0) {
                  this.canvasContext.lineTo(x, y);
                } else {
                  this.canvasContext.moveTo(x, y);
                }
              });

              this.canvasContext.stroke();
            })
        }
        .width('100%')
        .height(200)
        .padding({ bottom: 12 })
      }
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 12,
      bottom: 12
    })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12, top: -32 })
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
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
                this.navStack.pop();
              }, async () => {
                const context = getContext(this) as common.UIAbilityContext;
                const uiContext = this.getUIContext();
                try {
                  const now = new Date();
                  const timestamp = now.toISOString().replace(/[:.]/g, '-').slice(0, 19);
                  await ScreenshotUtils.captureAndShare(
                    context,
                    uiContext,
                    'detailDialogRoot',
                    `noise_report_${timestamp}.jpg`,
                    '噪音检测报告截图',
                    '当前噪音检测报告详情截图'
                  );
                } catch (error) {
                  hilog.error(DOMAIN, TAG, '截图分享失败: %{public}s',
                    error instanceof Error ? error.message : String(error));
                }
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
                .padding({
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 12
                })
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
        .id("detailDialogRoot")
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
                // 根据滑动距离调整背景透明度，在弹窗移动到一半时就完全消失
                this.bgOpacity = Math.max(0, 0.3 * (1 - deltaY / 250));
              }
            })
            .onActionEnd(() => {
              if (this.translateY > 100) {
                // 如果下滑超过阈值，先执行pop()，再执行动画
                this.navStack.pop();
                animateTo({ duration: 1200, curve: Curve.EaseIn }, () => {
                  this.translateY = 1000;
                });
              } else {
                // 否则回弹
                animateTo({ duration: 800, curve: Curve.Smooth }, () => {
                  this.translateY = 0;
                  this.bgOpacity = 0.3;
                });
              }
            })
        )
        .animation({
          duration: 800,
          curve: Curve.Smooth
        })
      }
      .height('100%')
      .width('100%')
    }
    .backgroundColor(`rgba(0,0,0,${this.bgOpacity})`)
    .animation({
      duration: 400,
      curve: Curve.EaseOut,
      iterations: 1,
      playMode: PlayMode.Normal
    })
    .hideTitleBar(true)
    .mode(NavDestinationMode.DIALOG)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onBackPressed(() => {
      // 先执行pop()，再执行动画
      this.navStack.pop();
      animateTo({ duration: 1200, curve: Curve.EaseIn }, () => {
        this.translateY = 1000;
      });
      // 蒙层消失动画使用 EaseIn 曲线，与出现时相反
      animateTo({ duration: 600, curve: Curve.EaseIn }, () => {
        this.bgOpacity = 0;
      });
      return true;
    })
  }
}

@Builder
export function DetailDialogBuilder() {
  DetailDialog()
}
