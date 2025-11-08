import { AppStorageV2, PersistenceV2 } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { BaseChartComponent } from '../common/charts/BaseChartComponent';
import { ChartConfig, ChartType, DefaultChartConfig } from '../common/charts/ChartConfig';
import { AudioPresets } from '../../common/AudioConfig';
import { SpectrumDataProcessor, PeakInfo, PeakInterpolationMethod } from './SpectrumDataProcessor';
import { UnifiedChartStyle } from '../common/charts/UnifiedChartStyle';

@ComponentV2
export struct SpectrumChartComponent {
  // 输入参数
  @Param sampleRate: number = 44100
  @Param canvasWidthInput: number = 0
  @Param canvasHeightInput: number = 0
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys) ?? new PreferenceKeys();

  // 依赖注入
  @Local private sysResourceManager: resourceManager.ResourceManager = resourceManager.getSystemResourceManager();
  @Local private ak: AppKeys = AppStorageV2.connect(AppKeys) ?? new AppKeys()

  // 频谱数据
  @Local private currentSpectrumData: Float32Array = new Float32Array();
  @Local private peakInfo: PeakInfo | null = null;

  @Computed
  get fftSize() {
    return AudioPresets.getConfig(this.pk.audio_analysis_mode).fftSize;
  }

  @Computed
  get chartConfig(): ChartConfig {
    return {
      margin: DefaultChartConfig.margin,
      aspectRatio: 1.5,
      backgroundColor: UnifiedChartStyle.BACKGROUND_COLOR,
      gridColor: UnifiedChartStyle.GRID_COLOR,
      textColor: UnifiedChartStyle.TEXT_COLOR,
      fontSize: {
        title: UnifiedChartStyle.FONT_SIZES.title,
        axis: UnifiedChartStyle.FONT_SIZES.axis,
        label: UnifiedChartStyle.FONT_SIZES.value,
        small: UnifiedChartStyle.FONT_SIZES.legend
      },
      chartType: ChartType.SPECTRUM,
      responsive: DefaultChartConfig.responsive
    };
  }

  @Monitor('ak.uiDisplayState.displaySpectrumData')
  onSpectrumDataChange(monitor: IMonitor) {
    const newSpectrum = monitor.value<Float32Array>()?.now;
    if (newSpectrum && this.ak.isDisplayApp) {
      this.currentSpectrumData = newSpectrum;
      // 使用改进的峰值检测方法（默认启用抛物线插值）
      this.peakInfo = SpectrumDataProcessor.findPeakFrequency(
        this.currentSpectrumData,
        this.fftSize,
        this.sampleRate,
        SpectrumDataProcessor.MIN_FREQUENCY,
        SpectrumDataProcessor.MAX_FREQUENCY,
        true, // 默认启用插值
        PeakInterpolationMethod.PARABOLIC // 默认使用抛物线插值
      );
    }
  }

  // 频谱绘制函数
  private drawSpectrumChart(ctx: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number): void {
    if (this.currentSpectrumData.length === 0) {
      return;
    }

    const dbSteps: number[] = SpectrumDataProcessor.getDbSteps();
    const frequencySteps: number[] = SpectrumDataProcessor.getFrequencySteps();

    this.drawSpectrum(
      ctx,
      canvasWidth,
      canvasHeight,
      this.currentSpectrumData,
      dbSteps,
      frequencySteps,
      this.fftSize,
      this.sampleRate,
      this.sysResourceManager
    );
  }

  /**
   * 绘制频谱的方法 - 改进版，使用公共模块
   */
  private drawSpectrum(canvasContext: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number,
    rawSpectrum: Float32Array, dbSteps: number[], frequencySteps: number[], fftSize: number, sampleRate: number,
    sysResourceManager: resourceManager.ResourceManager,
    fontSize: number = 12): void {
    console.info(`[频谱绘制] 开始绘制频谱，数据长度=${rawSpectrum.length}`);
    if (canvasContext) {
      let lineColor = parseInt(UnifiedChartStyle.TEXT_COLOR.replace('#', '0xFF'));
      // 清除画布
      const frequencyHigh: number = frequencySteps[frequencySteps.length - 1];
      console.info(`[频谱绘制] 频率步进点=${frequencySteps.join(', ')}`);
      canvasContext.clearRect(0, 0, canvasWidth, canvasHeight);
      // 绘制分贝刻度
      canvasContext.strokeStyle = lineColor;
      canvasContext.lineWidth = UnifiedChartStyle.LINE_WIDTHS.thin;
      canvasContext.textAlign = 'right';
      canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
      canvasContext.fillStyle = lineColor;

      let minDb = dbSteps[0];
      let maxDb = dbSteps[dbSteps.length -1];
      for (const db of dbSteps) {
        // 重新计算Y坐标，确保分贝均匀分布并填满画布高度
        const normalizedValue: number = (db - minDb) / (maxDb - minDb);
        const y: number = canvasHeight * (1 - normalizedValue);

        // 跳过最顶部和最底部的水平网格线
        if (db === minDb || db === maxDb) {
          // 但是仍然绘制最顶部的标签
          if (db === maxDb) {
            canvasContext.fillStyle = lineColor;
            canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
            canvasContext.textAlign = 'right';
            canvasContext.fillText(
              `${db}`,
              30,
              y + 10
            );
          }
          continue;
        }

        // 只为特定分贝值显示标签
        if (dbSteps.includes(db)) {
          canvasContext.fillStyle = lineColor;
          canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
          canvasContext.textAlign = 'right';
          canvasContext.fillText(
            `${db}`,
            30,
            y + 10
          );
        }
      }

      for (const db of dbSteps) {
        // 重新计算Y坐标，确保分贝均匀分布并填满画布高度
        const normalizedValue: number = (db - minDb) / (maxDb - minDb);
        const y: number = canvasHeight * (1 - normalizedValue);

        // 跳过最顶部和最底部的水平网格线
        if (db === minDb || db === maxDb) {
          continue;
        }

        // 绘制水平网格线（从画布左侧到右侧）
        canvasContext.lineWidth = UnifiedChartStyle.LINE_WIDTHS.grid;
        canvasContext.beginPath();
        canvasContext.moveTo(0, y);
        canvasContext.lineTo(canvasWidth, y);
        canvasContext.stroke();

      }

      // 绘制频率刻度
      canvasContext.textAlign = 'left';
      canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
      canvasContext.fillStyle = lineColor;

      // 使用缓存的对数坐标常量
      const LOG_MIN_FREQ = Math.log10(16);
      const logMax: number = Math.log10(frequencyHigh);
      console.info(`[频谱绘制] 对数范围: min=${LOG_MIN_FREQ.toFixed(2)}, max=${logMax.toFixed(2)}`);

      // 计算0分贝对应的Y坐标
      const zeroDbNormalizedValue: number = (0 - minDb) / (maxDb - minDb);
      const zeroDbY: number = canvasHeight * (1 - zeroDbNormalizedValue);

      for (let i = 0; i < frequencySteps.length; i++) {
        const freq: number = frequencySteps[i];
        // 对数坐标映射
        const logFreq: number = Math.log10(freq);

        // 计算X坐标，确保从画布左侧到右侧
        const x: number =
          ((logFreq - LOG_MIN_FREQ) / (logMax - LOG_MIN_FREQ)) * canvasWidth;
        console.info(`[频谱绘制] 频率=${freq}Hz, x坐标=${x.toFixed(2)}`);

        // 跳过最左侧和最右侧的垂直网格线
        if (i === 0 || i === frequencySteps.length - 1) {
          // 绘制第一个频率标签
          if (i === 0) {
            canvasContext.fillStyle = lineColor;
            canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
            canvasContext.textAlign = 'left';
            canvasContext.fillText(
              UnifiedChartStyle.formatFrequency(freq),
              x + 2,
              zeroDbY - 2  // 使用0分贝线的位置
            );
          }
          continue;
        }

        // 绘制垂直网格线
        canvasContext.beginPath();
        canvasContext.strokeStyle = lineColor;
        canvasContext.lineWidth = UnifiedChartStyle.LINE_WIDTHS.grid;
        canvasContext.moveTo(x, 0);
        canvasContext.lineTo(x, canvasHeight);
        canvasContext.stroke();

        // 绘制频率文本（在0分贝线的上方，左对齐）
        const label: string = UnifiedChartStyle.formatFrequency(freq);
        canvasContext.fillStyle = lineColor;
        canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
        canvasContext.textAlign = 'left';
        canvasContext.fillText(
          label,
          x + 2, // 使用x坐标作为左对齐起点
          zeroDbY - 2  // 使用0分贝线的位置，略微上移5像素
        );
      }

      // 获取频谱数据并记录范围
      let minSpectrum: number = Infinity;
      let maxSpectrum: number = -Infinity;
      for (const value of rawSpectrum) {
        if (isFinite(value)) {
          // 频谱数据已经是分贝值，直接使用
          minSpectrum = Math.min(minSpectrum, value);
          maxSpectrum = Math.max(maxSpectrum, value);
        }
      }

      console.info(`[频谱绘制] 频谱范围: min=${minSpectrum.toFixed(2)}, max=${maxSpectrum.toFixed(2)}`);

      // 使用缓存的对数坐标常量
      const logMaxDraw: number = Math.log10(frequencyHigh);

      // 绘制主频谱折线
      const spectrumPath = new Path2D(); // 创建新的Path2D对象
      canvasContext.strokeStyle = parseInt(UnifiedChartStyle.PRIMARY_COLOR.replace('#', '0xFF'));
      canvasContext.lineWidth = UnifiedChartStyle.LINE_WIDTHS.normal;

      // 标记是否找到第一个有效点
      let isFirstValidPoint = true;
      // 记录上一个绘制点的坐标
      let lastX: number | null = null;
      let lastY: number | null = null;

      for (let i = 0; i < fftSize; i++) {
        const centerFreq: number = SpectrumDataProcessor.getIndexFrequency(i, fftSize, sampleRate);
        if (centerFreq < 16) {
          continue;
        } // 只显示16Hz以上的范围

        // 安全检查：确保rawSpectrum存在且有效
        if (!rawSpectrum || i >= rawSpectrum.length) {
          continue;
        }

        const logFreq: number = Math.log10(centerFreq);
        const x: number = ((logFreq - LOG_MIN_FREQ) / (logMaxDraw - LOG_MIN_FREQ)) * canvasWidth;

        // 频谱数据已经是分贝值，直接使用
        const value: number = Math.max(minDb, Math.min(maxDb, rawSpectrum[i]));
        const normalizedValue: number = (value - minDb) / (maxDb - minDb);
        const height: number = canvasHeight * normalizedValue;
        const y: number = canvasHeight - height;

        // 转换为整数坐标
        const intX = Math.round(x);
        const intY = Math.round(y);

        // 检查是否为重复点
        const isDuplicatePoint = lastX !== null && lastY !== null &&
          intX === lastX && intY === lastY;

        // 只在找到第一个有效点或非重复点时绘制
        if (isFirstValidPoint || !isDuplicatePoint) {
          if (isFirstValidPoint) {
            spectrumPath.moveTo(x, y); // 使用Path2D的moveTo
            isFirstValidPoint = false;
          } else {
            spectrumPath.lineTo(x, y); // 使用Path2D的lineTo
          }

          // 更新最后一个绘制点的坐标
          lastX = intX;
          lastY = intY;
        }
      }

      // 一次性绘制整个路径
      canvasContext.stroke(spectrumPath);

      // 显示峰值频率 - 使用公共模块计算的峰值信息
      if (this.peakInfo && this.peakInfo.frequency > 0) {
        const logPeakFreq: number = Math.log10(this.peakInfo.frequency);
        const peakX: number = ((logPeakFreq - LOG_MIN_FREQ) / (logMaxDraw - LOG_MIN_FREQ)) * canvasWidth;

        const peakFreqY: number = canvasHeight -
          ((this.peakInfo.dbValue - minDb) / (maxDb - minDb)) * canvasHeight;
        canvasContext.fillStyle = parseInt(UnifiedChartStyle.PRIMARY_COLOR.replace('#', '0xFF'));
        canvasContext.textAlign = 'center';
        canvasContext.font = `bold ${vp2px(fontSize + 2)}px sans-serif`;
        canvasContext.fillText(
          UnifiedChartStyle.formatFrequency(this.peakInfo.frequency),
          peakX,
          peakFreqY - 35 // 稍微抬高标签位置
        );

        // 显示峰值分贝值
        canvasContext.fillText(
          UnifiedChartStyle.formatDecibel(this.peakInfo.dbValue),
          peakX,
          peakFreqY - 20 // 在频率标签上方
        );
      }
    }
  }

  build() {
    // 使用基础图表组件，传入频谱特定的绘制函数
    BaseChartComponent({
      canvasWidthInput: this.canvasWidthInput,
      canvasHeightInput: this.canvasHeightInput,
      chartConfig: this.chartConfig,
      onDrawChart: (ctx: CanvasRenderingContext2D, width: number, height: number) => {
        this.drawSpectrumChart(ctx, width, height);
      }
    })
  }
}