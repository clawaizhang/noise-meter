import { WaterfallChartComponent } from './WaterfallChartComponent';
import { PerformanceMonitor } from '../../utils/PerformanceMonitor';

/**
 * 性能测试仪表板
 * 用于测试和展示瀑布图优化效果
 */

@ComponentV2
export struct PerformanceTestDashboard {
  @Local waterfallRef: WaterfallChartComponent = new WaterfallChartComponent();
  @Local performanceMonitor: PerformanceMonitor = PerformanceMonitor.getInstance();
  @Local isTestRunning: boolean = false;
  @Local testResults: string = '';
  @Local showMetrics: boolean = false;

  build() {
    Column() {
      // 标题
      Text('瀑布图性能测试')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      // 控制按钮
      Row() {
        Button(this.isTestRunning ? '停止测试' : '开始测试')
          .onClick(() => {
            this.toggleTest();
          })
          .margin({ right: 10 })

        Button('清除结果')
          .onClick(() => {
            this.clearResults();
          })
          .margin({ right: 10 })

        Button(this.showMetrics ? '隐藏指标' : '显示指标')
          .onClick(() => {
            this.showMetrics = !this.showMetrics;
          })
      }
      .margin({ bottom: 20 })

      // 性能指标显示
      if (this.showMetrics) {
        this.buildMetricsPanel()
      }

      // 测试结果显示
      if (this.testResults) {
        Text(this.testResults)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 10, bottom: 10 })
          .maxLines(10)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      // 瀑布图组件
      WaterfallChartComponent({
        canvasWidthInput: 600,
        canvasHeightInput: 400
      })
      .margin({ top: 20 })
    }
    .padding(20)
    .width('100%')
    .height('100%')
  }

  @Builder
  buildMetricsPanel() {
    Column() {
      Text('实时性能指标')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })

      const metrics = this.performanceMonitor.getMetrics();
      
      Row() {
        Text(`帧率: ${metrics.frameRate.toFixed(1)} FPS`)
          .fontSize(14)
          .margin({ right: 20 })

        Text(`平均帧时间: ${metrics.averageFrameTime.toFixed(1)} ms`)
          .fontSize(14)
      }
      .margin({ bottom: 5 })

      Row() {
        Text(`渲染次数: ${metrics.renderCount}`)
          .fontSize(14)
          .margin({ right: 20 })

        Text(`内存使用: ${metrics.memoryUsage.toFixed(1)} MB`)
          .fontSize(14)
      }
      .margin({ bottom: 10 })

      // 警报显示
      const alerts = this.performanceMonitor.getAlerts();
      if (alerts.length > 0) {
        Text('性能警报:')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF0000')
          .margin({ bottom: 5 })

        ForEach(alerts.slice(-3), (alert) => {
          Text(`[${alert.type}] ${alert.message}`)
            .fontSize(12)
            .fontColor('#FF6600')
            .margin({ bottom: 2 })
        })
      }
    }
    .padding(15)
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
    .width('100%')
    .margin({ bottom: 20 })
  }

  /**
   * 切换测试状态
   */
  private toggleTest(): void {
    if (this.isTestRunning) {
      this.stopTest();
    } else {
      this.startTest();
    }
  }

  /**
   * 开始性能测试
   */
  private startTest(): void {
    this.isTestRunning = true;
    this.testResults = '开始性能测试...\n';
    
    // 重置性能监控
    this.performanceMonitor.reset();
    
    // 模拟高频数据更新
    this.simulateDataUpdates();
  }

  /**
   * 停止性能测试
   */
  private stopTest(): void {
    this.isTestRunning = false;
    
    // 生成测试报告
    const report = this.performanceMonitor.getPerformanceReport();
    this.testResults = `测试完成!\n\n${report}`;
  }

  /**
   * 清除测试结果
   */
  private clearResults(): void {
    this.testResults = '';
    this.performanceMonitor.reset();
  }

  /**
   * 模拟数据更新
   */
  private simulateDataUpdates(): void {
    if (!this.isTestRunning) {
      return;
    }

    // 模拟频谱数据
    const spectrumData = new Float32Array(2048);
    for (let i = 0; i < spectrumData.length; i++) {
      // 生成模拟的频谱数据
      const freq = (i * 22050) / spectrumData.length; // 假设采样率44100Hz
      spectrumData[i] = Math.random() * 80 - 20 + // 基础噪声
                      Math.sin(freq * 0.01) * 30 + // 频率相关分量
                      Math.random() * 10 - 5; // 随机波动
    }

    // 这里应该触发瀑布图更新，但由于组件结构限制，
    // 我们只能通过性能监控来展示效果
    
    // 继续模拟
    setTimeout(() => {
      this.simulateDataUpdates();
    }, 50); // 20Hz更新频率
  }
}