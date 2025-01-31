import { DecibelRecord } from "../../../../library/ets/models/DecibelRecord"
import { DecibelService } from "../../services/DecibelService"
import { display } from "@kit.ArkUI"
import { AudioPlayer } from "../../../../library/ets/components/business/AudioPlayer";
import { WeightingType } from "../../../../library/ets/constants/WeightingConstants";

interface Margin {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

@ComponentV2
export struct NoiseChart {
  @Param playAudio: boolean = false;
  @Param selectedRecord: DecibelRecord | null = null;
  private canvasSettings: RenderingContextSettings = new RenderingContextSettings(true)
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.canvasSettings)
  private canvasWidth = 320;
  private canvasHeight = 160;

  async aboutToAppear() {
    const availableArea = await display.getDefaultDisplaySync().getAvailableArea();
    const availableWidthVp = px2vp(availableArea.width);
    this.canvasWidth = availableWidthVp - 32;
    this.canvasHeight = this.canvasWidth / 1.5;
  }

  @Computed
  get uniqueWeightingTypes() {
    return Array.from(new Set(this.selectedRecord!.weightingTypes));
  }

  @Computed
  get uniqueWeightingColors() {
    return this.uniqueWeightingTypes.map((type: WeightingType) => DecibelService.getWeightingColor(type));
  }

  build() {
    Column() {
      Row() {
        Text('统计图(分贝-时间)')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)

        if (this.playAudio && this.selectedRecord!.audioFilePath) {
          Blank()
          Row() {
            if (this.selectedRecord!.audioFilePath) {
              AudioPlayer({
                audioFilePath: this.selectedRecord!.audioFilePath,
              })
            }
          }
        }
      }
      .width('100%')
      .margin({ bottom: 12 })
      .alignItems(VerticalAlign.Center)

      if (this.selectedRecord!.decibelValues.length === 0) {
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
          Canvas(this.canvasContext)
            .width(this.canvasWidth)
            .height(this.canvasHeight)
            .onReady(() => {
              const values = this.selectedRecord!.decibelValues;
              const duration = this.selectedRecord!.duration;
              const maxValue = Math.max(...values);
              const minValue = Math.min(...values);

              const margin: Margin = {
                top: vp2px(2),
                right: vp2px(3),
                bottom: vp2px(4),
                left: vp2px(9)
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
              let bestStep = 5;
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
              let firstTick = Math.floor(yMin / 5) * 5;
              if (firstTick < yMin) {
                firstTick += 5;
              }
              ticks.push(firstTick);

              let current = firstTick;
              while (current < yMax) {
                current += bestStep;
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
                const lastTick = ticks[ticks.length - 1];
                while (ticks.length < 5) {
                  const newTick = lastTick + bestStep;
                  ticks.push(Math.min(newTick, yMax));
                }
              } else if (ticks.length > 7) {
                ticks.length = 7;
                ticks[6] = yMax;
              }

              // 绘制Y轴刻度
              this.canvasContext.fillStyle = '#666666';
              this.canvasContext.textAlign = 'right';
              for (let i = 0; i < ticks.length; i++) {
                const y = margin.top + chartHeight - ((ticks[i] - yMin) / (yMax - yMin)) * chartHeight;
                if (i === 0 || i === ticks.length - 1) {
                  if (ticks[i] % 5 === 0) {
                    this.canvasContext.fillText(`${ticks[i]}`, margin.left - vp2px(2), y);
                  }
                } else {
                  this.canvasContext.fillText(`${ticks[i]}`, margin.left - vp2px(2), y);
                }

                // 绘制垂直网格线，仅在有标签的位置绘制
                if (ticks[i] % 5 === 0) {
                  this.canvasContext.beginPath();
                  this.canvasContext.moveTo(margin.left, y);
                  this.canvasContext.lineTo(margin.left + chartWidth, y);
                  this.canvasContext.strokeStyle = '#E0E0E0'; // 主要网格线颜色
                  this.canvasContext.stroke();
                }
              }

              // 重新设计X轴刻度计算逻辑
              const totalSeconds = duration / 1000;
              const targetXGridCount = 7;
              const extendedSeconds = Math.max(totalSeconds * 1.1, 0.1);

              let xInterval: number;
              if (totalSeconds >= 3) {
                xInterval = Math.ceil(extendedSeconds / targetXGridCount);
                const possibleSteps = [1, 2, 5, 10, 15, 20, 30, 60];
                xInterval = possibleSteps.find(step => step >= xInterval) || xInterval;
              } else {
                xInterval = extendedSeconds / targetXGridCount;
                xInterval = Math.round(xInterval * 10) / 10;
                xInterval = Math.max(xInterval, 0.1);
              }

              let actualGridCount = Math.ceil(extendedSeconds / xInterval);
              if ((actualGridCount - 1) * xInterval < totalSeconds) {
                actualGridCount = Math.ceil(totalSeconds / xInterval) + 1;
              }
              const xStep = chartWidth / (actualGridCount - 1);

              const formatTime = (seconds: number) => {
                return seconds % 1 === 0 ? `${seconds}` : `${seconds.toFixed(1)}`;
              };

              this.canvasContext.textAlign = 'center';
              this.canvasContext.fillText('秒', margin.left + chartWidth / 2, margin.top + chartHeight + vp2px(12));

              for (let i = 0; i < actualGridCount; i++) {
                const x = margin.left + i * xStep;
                const seconds = i * xInterval;
                this.canvasContext.fillText(formatTime(seconds), x, margin.top + chartHeight + vp2px(2));
                this.canvasContext.strokeStyle = '#E0E0E0'; // 辅助网格线颜色
                this.canvasContext.lineWidth = 1; // 更细的线条
                // 绘制垂直网格线
                this.canvasContext.beginPath();
                this.canvasContext.moveTo(x, margin.top);
                this.canvasContext.lineTo(x, margin.top + chartHeight);
                this.canvasContext.stroke();

                // 添加辅助网格线
                if (i < actualGridCount - 1) {
                  const nextX = margin.left + (i + 1) * xStep;
                  const subGridCount = 1;
                  const subXStep = (nextX - x) / (subGridCount + 1);

                  this.canvasContext.strokeStyle = '#D3D3D3'; // 辅助网格线颜色
                  this.canvasContext.lineWidth = 0.2; // 更细的线条

                  for (let j = 1; j <= subGridCount; j++) {
                    const subX = x + j * subXStep;
                    this.canvasContext.beginPath();
                    this.canvasContext.moveTo(subX, margin.top);
                    this.canvasContext.lineTo(subX, margin.top + chartHeight);
                    this.canvasContext.stroke();
                  }
                }
              }

              // 绘制数据点
              const xScale = (chartWidth - margin.left - margin.right) / totalSeconds;
              const yScale = chartHeight / (maxValue - minValue);
              const timeInterval = totalSeconds / (values.length - 1);
              const colorCache = new Map<number, string>();
              const weightingTypes = this.selectedRecord!.weightingTypes;

              // 获取加权类型及其颜色
              const weightingColors: string[] =
                weightingTypes.map(type => DecibelService.getWeightingColor(type));

              // 绘制背景色
              for (let i = 0; i < values.length - 1; i++) {
                const currentTime = i * timeInterval;
                const nextTime = (i + 1) * timeInterval;
                const x1 = margin.left + currentTime * xScale;
                const x2 = margin.left + nextTime * xScale;
                const y1 = margin.top + chartHeight - (values[i] - minValue) * yScale;
                const y2 = margin.top + chartHeight - (values[i + 1] - minValue) * yScale;

                const color: string = weightingColors[i];

                this.canvasContext.fillStyle = color;
                this.canvasContext.globalAlpha = 0.2; // 设置透明度以避免喧宾夺主
                this.canvasContext.beginPath();
                this.canvasContext.moveTo(x1, y1);
                this.canvasContext.lineTo(x2, y2);
                this.canvasContext.lineTo(x2, margin.top + chartHeight);
                this.canvasContext.lineTo(x1, margin.top + chartHeight);
                this.canvasContext.closePath();
                this.canvasContext.fill();
                this.canvasContext.globalAlpha = 1; // 恢复透明度
              }

              values.forEach((value, index) => {
                const currentTime = index * timeInterval;
                const x = Math.min(
                  margin.left + currentTime * xScale,
                  margin.left + chartWidth - margin.right
                );
                const y = margin.top + chartHeight - (value - minValue) * yScale;

                let color = colorCache.get(value);
                if (!color) {
                  color = DecibelService.getDecibelColor(value);
                  colorCache.set(value, color);
                }

                this.canvasContext.fillStyle = color;
                this.canvasContext.beginPath();
                this.canvasContext.arc(x, y, 1.5, 0, Math.PI * 2);
                this.canvasContext.fill();

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

        if (this.uniqueWeightingTypes!.length > 0) {
          Row() {
            ForEach(this.uniqueWeightingTypes, (type: WeightingType, index) => {
              Column()
                .width(16)
                .height(16)// 修改: 将高度改为16以适应圆形
                .backgroundColor(this.uniqueWeightingColors![index])
                .borderRadius(8) // 新增: 设置边框半径为8以形成圆形
              Text(`${type}计权`)
                .fontSize(12)
                .fontColor('#000000')
                .margin({ left: 4, right: 8 })
            })
          }.margin({ top: -30 })
        }
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
}