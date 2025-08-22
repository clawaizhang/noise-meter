/**
 * 性能测试入口文件
 * 在开发环境下运行性能测试
 */

import { runPerformanceTests } from "../utils/PerformanceTest"

@Entry
@ComponentV2
struct PerformanceTestEntry {
  build() {
    Column() {
      Text('性能测试运行中...')
        .fontSize(20)
        .margin(20)
      
      Button('运行性能测试', { type: ButtonType.Capsule })
        .onClick(() => {
          console.log('=== 开始手动性能测试 ===');
          runPerformanceTests();
          console.log('=== 手动性能测试完成 ===');
        })
        .margin(10)
      
      Text('查看控制台输出获取测试结果')
        .fontSize(14)
        .fontColor(0x666666)
        .margin(10)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onAppear(() => {
      // 组件加载时自动运行测试（开发环境）
      if (process.env.NODE_ENV === 'development') {
        console.log('=== 自动运行性能测试 ===');
        runPerformanceTests();
        console.log('=== 自动性能测试完成 ===');
      }
    })
  }
}