/**
 * 统计视图组件
 * @param data - 统计数据数组
 * @param title - 统计标题
 */

/**
 * 统计数据点接口
 */
export interface StatisticsDataPoint {
  timestamp: number;
  value: number;
}

interface Point {
  x: number;
  y: number;
}

@Component
export struct StatisticsView {
  @Prop title: string = '';
  @Prop data: Array<StatisticsDataPoint> = [];
  @State chartWidth: string | number = '100%';
  @State chartHeight: number = 200;
  @State chartLineColor: string = '#007DFF';
  @State chartBackgroundColor: string = '#F5F5F5';

  build() {
    Column() {
      if (this.title) {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 10 })
      }

      // 统计图表
      // 这里是简单的线性图表实现
      // 实际项目中可以根据需求使用更复杂的图表库
      Stack() {
        // 背景网格
        Grid()
          .backgroundColor(this.chartBackgroundColor)
          .height('100%')
          .width('100%')

        // 数据线
        if (this.data.length > 0) {
          Polyline()
            .points(this.getPoints())
            .stroke(this.chartLineColor)
            .strokeWidth(2)
        }
      }
      .width(this.chartWidth)
      .height(this.chartHeight)
    }
  }

  private getPoints(): Array<Point> {
    if (this.data.length === 0) return [];

    const maxValue = Math.max(...this.data.map(item => item.value));
    const minValue = Math.min(...this.data.map(item => item.value));
    const valueRange = maxValue - minValue;

    return this.data.map((item, index) => {
      const width = typeof this.chartWidth === 'string' ? 100 : this.chartWidth;
      return {
        x: (index / (this.data.length - 1)) * width,
        y: ((maxValue - item.value) / valueRange) * this.chartHeight
      } as Point;
    });
  }
} 