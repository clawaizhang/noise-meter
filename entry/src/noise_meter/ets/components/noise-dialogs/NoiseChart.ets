import { DecibelRecord } from "../../../../library/ets/models/DecibelRecord"
import { DecibelService } from "../../services/DecibelService"
import { display } from "@kit.ArkUI"
import { AudioPlayer } from "../../../../library/ets/components/business/AudioPlayer";

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
  private decibelService: DecibelService = new DecibelService();
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

  build() {
    Column() {
      Row() {
        Text('声级-时间散点图')
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

              // 绘制更细的辅助线
              this.canvasContext.strokeStyle = '#E8E8E8';
              this.canvasContext.lineWidth = 0.5;
              const ySubStep = bestStep / 2;
              for (let i = yMin; i <= yMax; i += ySubStep) {
                const y = margin.top + chartHeight - ((i - yMin) / (yMax - yMin)) * chartHeight;
                this.canvasContext.beginPath();
                this.canvasContext.moveTo(margin.left, y);
                this.canvasContext.lineTo(margin.left + chartWidth, y);
                this.canvasContext.stroke();
              }

              // 统一主要网格线样式
              this.canvasContext.strokeStyle = '#E0E0E0';
              this.canvasContext.lineWidth = 1;

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

              for (let i = 0; i < targetXGridCount; i++) {
                const x = margin.left + i * xStep;
                const seconds = i * xInterval;
                this.canvasContext.fillText(formatTime(seconds), x, margin.top + chartHeight + vp2px(2));

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
              const xScale = (chartWidth - margin.left - margin.right) / totalSeconds;
              const yScale = chartHeight / (maxValue - minValue);
              const timeInterval = totalSeconds / (values.length - 1);
              const colorCache = new Map<number, string>();

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
}