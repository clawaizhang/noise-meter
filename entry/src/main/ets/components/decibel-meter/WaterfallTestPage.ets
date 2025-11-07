/**
 * 瀑布图测试页面
 * 用于独立测试瀑布图动画修复效果
 */

import { WaterfallChartTest } from './WaterfallChartTest';

@Entry
@ComponentV2
struct WaterfallTestPage {
  build() {
    Column() {
      // 页面标题
      Row() {
        Text('瀑布图动画测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .height(50)
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.Gray)
      
      // 测试内容
      WaterfallChartTest()
        .layoutWeight(1)
        .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}