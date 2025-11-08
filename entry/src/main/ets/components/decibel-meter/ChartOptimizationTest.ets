/**
 * 图表优化测试文件
 * 用于验证坐标轴标签内部显示的优化效果
 */

import { DashBoard } from './Dashboard';

@ComponentV2
export struct ChartOptimizationTest {
  build() {
    Column() {
      Text('图表优化测试')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })
        .textAlign(TextAlign.Center)
        .width('100%')
      
      Text('优化内容：')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 8 })
        .textAlign(TextAlign.Start)
        .width('100%')
        .padding({ left: 16 })
      
      Text('1. 将所有图表的X轴标签移至顶部（内部）')
        .fontSize(14)
        .margin({ bottom: 4 })
        .textAlign(TextAlign.Start)
        .width('100%')
        .padding({ left: 24 })
      
      Text('2. 将所有图表的Y轴标签移至内部')
        .fontSize(14)
        .margin({ bottom: 4 })
        .textAlign(TextAlign.Start)
        .width('100%')
        .padding({ left: 24 })
      
      Text('3. 减少图表外边距，增大显示区域')
        .fontSize(14)
        .margin({ bottom: 4 })
        .textAlign(TextAlign.Start)
        .width('100%')
        .padding({ left: 24 })
      
      Text('4. 优化标签间距，避免重叠')
        .fontSize(14)
        .margin({ bottom: 16 })
        .textAlign(TextAlign.Start)
        .width('100%')
        .padding({ left: 24 })
      
      // 显示优化后的仪表板
      DashBoard({ meterOn: true })
        .layoutWeight(1)
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#191A1C')
    .padding(16)
  }
}