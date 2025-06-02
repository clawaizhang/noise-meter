import { resourceManager } from "@kit.LocalizationKit";

export function getDbSteps(): number[] {
  return [-20, 0, 20, 40, 60, 80, 100, 120, 140];
}

export function getFrequencySteps(): number[] {
  // 标准频率步进
  return [16, 31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
}

// 绘制频谱的方法
export function drawSpectrum(canvasContext: CanvasRenderingContext2D, canvasWidth: number, canvasHeight: number,
  rawSpectrum: Float32Array, dbSteps: number[], frequencySteps: number[], fftSize: number, sampleRate: number,
  lineColor: Resource, fontSize: number = 12): void {
  console.info(`[频谱绘制] 开始绘制频谱，数据长度=${rawSpectrum.length}`);
  if (canvasContext) {
    // 清除画布
    const frequencyHigh: number = frequencySteps[frequencySteps.length - 1];
    console.info(`[频谱绘制] 频率步进点=${frequencySteps.join(', ')}`);
    canvasContext.clearRect(0, 0, canvasWidth, canvasHeight);
    // 绘制分贝刻度
    canvasContext.strokeStyle = lineColor.toString();
    canvasContext.lineWidth = 1;
    canvasContext.textAlign = 'right';
    canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
    canvasContext.fillStyle = lineColor.toString();

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
          canvasContext.fillStyle = lineColor.toString();
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

      // 绘制水平网格线（从画布左侧到右侧）
      canvasContext.beginPath();
      canvasContext.moveTo(0, y);
      canvasContext.lineTo(canvasWidth, y);
      canvasContext.stroke();

      // 只为特定分贝值显示标签
      if (dbSteps.includes(db)) {
        canvasContext.fillStyle = lineColor.toString();
        canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
        canvasContext.textAlign = 'right';
        canvasContext.fillText(
          `${db}`,
          30,
          y + 10
        );
      }
    }

    // 绘制频率刻度
    canvasContext.textAlign = 'left';
    canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
    canvasContext.fillStyle = lineColor.toString();

    // 计算对数坐标映射的常量
    const logMin: number = Math.log10(16);
    const logMax: number = Math.log10(frequencyHigh);
    console.info(`[频谱绘制] 对数范围: min=${logMin.toFixed(2)}, max=${logMax.toFixed(2)}`);

    // 计算0分贝对应的Y坐标
    const zeroDbNormalizedValue: number = (0 - minDb) / (maxDb - minDb);
    const zeroDbY: number = canvasHeight * (1 - zeroDbNormalizedValue);

    for (let i = 0; i < frequencySteps.length; i++) {
      const freq: number = frequencySteps[i];
      // 对数坐标映射
      const logFreq: number = Math.log10(freq);

      // 计算X坐标，确保从画布左侧到右侧
      const x: number =
        ((logFreq - logMin) / (logMax - logMin)) * canvasWidth;
      console.info(`[频谱绘制] 频率=${freq}Hz, x坐标=${x.toFixed(2)}`);

      // 跳过最左侧和最右侧的垂直网格线
      if (i === 0 || i === frequencySteps.length - 1) {
        // 绘制第一个频率标签
        if (i === 0) {
          resourceManager.getSystemResourceManager().getStringValue($r('app.color.text_secondary')).then((value) => {
            canvasContext.fillStyle = value;
          });
          canvasContext.font = `${vp2px(fontSize)}px sans-serif`;
          canvasContext.textAlign = 'left';
          canvasContext.fillText(
            `${freq}`,
            x + 2,
            zeroDbY - 2  // 使用0分贝线的位置
          );
        }
        continue;
      }

      // 绘制垂直网格线
      canvasContext.beginPath();
      resourceManager.getSystemResourceManager().getStringValue($r('app.color.divider')).then((value) => {
        canvasContext.strokeStyle = value;
      });
      canvasContext.lineWidth = 0.5;
      canvasContext.moveTo(x, 0);
      canvasContext.lineTo(x, canvasHeight);
      canvasContext.stroke();

      // 绘制频率文本（在0分贝线的上方，左对齐）
      const label: string = freq >= 1000 ?
        (freq === 1000 ? '1k' : `${freq / 1000}k`) :
      freq.toString();
      resourceManager.getSystemResourceManager().getStringValue($r('app.color.text_secondary')).then((value) => {
        canvasContext.fillStyle = value;
      });
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
        // 使用绝对值来比较
        const absValue = Math.abs(value);
        minSpectrum = Math.min(minSpectrum, absValue);
        maxSpectrum = Math.max(maxSpectrum, absValue);
      }
    }

    // 预计算频率相关的常量
    const octaveRatio: number = Math.pow(2, 1 / 3); // 每1/3个八度的比例
    let maxValue: number = -Infinity;
    let peakFreq = 0;

    // 按照八度分频计算每个频点
    for (let i = 0; i < fftSize / 2; i++) {
      // 使用标准频率计算方法
      const centerFreq: number =
        (i * sampleRate) / (2 * fftSize);

      // 过滤超过频率范围的值
      if (centerFreq > frequencyHigh) {
        continue;
      }

      // 计算频带边界
      const lowerFreq: number = centerFreq / Math.pow(octaveRatio, 0.5);
      const upperFreq: number = centerFreq * Math.pow(octaveRatio, 0.5);

      // 将频率转换为FFT bin索引
      const lowerBin: number = Math.max(1, Math.floor(lowerFreq * fftSize / sampleRate));
      const upperBin: number =
        Math.min(Math.floor(upperFreq * fftSize / sampleRate), rawSpectrum.length - 1);

      let binSpectrum = new Float32Array();
      // 计算频段内的平均能量
      for (let bin = lowerBin; bin <= upperBin; bin++) {
        const value: number = rawSpectrum[bin];
        if (isFinite(value)) {
          // 使用绝对值来比较和存储
          const absValue = Math.abs(value);
          binSpectrum.fill(absValue);
          if (absValue > maxValue) {
            maxValue = absValue;
            peakFreq = (bin * sampleRate / fftSize);
          }
        }
      }
    }

    // 绘制主频谱折线
    const spectrumPath = new Path2D(); // 创建新的Path2D对象
    resourceManager.getSystemResourceManager().getStringValue($r('app.color.button_confirm')).then((value) => {
      canvasContext.strokeStyle = value;
    });
    canvasContext.lineWidth = 0.5;

    // 标记是否找到第一个有效点
    let isFirstValidPoint = true;
    // 记录上一个绘制点的坐标
    let lastX: number | null = null;
    let lastY: number | null = null;

    for (let i = 0; i < fftSize; i++) {
      const centerFreq: number = (i * sampleRate) / (2 * fftSize);
      if (centerFreq < 16) {
        continue;
      } // 只显示16Hz以上的范围

      // 安全检查：确保rawSpectrum存在且有效
      if (!rawSpectrum || i >= rawSpectrum.length) {
        continue;
      }

      const logFreq: number = Math.log10(centerFreq);
      const logMin: number = Math.log10(16);
      const logMax: number = Math.log10(frequencyHigh);

      const x: number =
        ((logFreq - logMin) / (logMax - logMin)) * canvasWidth;

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

    // 显示峰值频率
    if (peakFreq > 0) {
      const logPeakFreq: number = Math.log10(peakFreq);
      const logMin: number = Math.log10(16);
      const logMax: number = Math.log10(frequencyHigh);
      const peakX: number = ((logPeakFreq - logMin) / (logMax - logMin)) * canvasWidth;

      // 计算Y坐标的替代方案
      const peakFreqY: number = canvasHeight -
        (maxValue / (maxDb - minDb)) * canvasHeight;
      resourceManager.getSystemResourceManager().getStringValue($r('app.color.text_secondary')).then((value) => {
        canvasContext.fillStyle = value;
      });
      canvasContext.textAlign = 'center';
      canvasContext.font = `bold ${vp2px(fontSize)}px sans-serif`;
      canvasContext.fillText(
        `${Math.round(peakFreq)}Hz`,
        peakX,
        peakFreqY - 30 // 稍微抬高标签位置
      );
    }
  }
}
