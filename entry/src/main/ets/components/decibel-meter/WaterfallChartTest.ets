/**
 * 瀑布图测试组件
 * 用于验证瀑布图动画修复效果
 */

import { WaterfallChartComponent } from './WaterfallChartComponent';
import { AppStorageV2 } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';

@ComponentV2
export struct WaterfallChartTest {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local testRunning: boolean = false;
  @Local testDataGenerated: number = 0;
  @Local testInterval?: number;

  /**
   * 生成测试频谱数据
   */
  private generateTestSpectrumData(): Float32Array {
    const fftSize = 1024;
    const data = new Float32Array(fftSize);
    
    // 生成模拟的频谱数据，包含几个峰值
    for (let i = 0; i < fftSize; i++) {
      // 基础噪声
      let value = Math.random() * 20 - 60;
      
      // 添加几个峰值
      if (i >= 50 && i <= 60) {
        value += 40; // 低频峰值
      } else if (i >= 200 && i <= 210) {
        value += 30; // 中频峰值
      } else if (i >= 400 && i <= 410) {
        value += 25; // 高频峰值
      }
      
      data[i] = value;
    }
    
    return data;
  }

  /**
   * 开始测试
   */
  private startTest(): void {
    if (this.testRunning) {
      return;
    }
    
    this.testRunning = true;
    this.testDataGenerated = 0;
    
    console.info('[瀑布图测试] 开始测试');
    
    // 定期生成测试数据
    this.testInterval = setInterval(() => {
      if (!this.testRunning) {
        return;
      }
      
      // 生成测试频谱数据
      const testData = this.generateTestSpectrumData();
      
      // 更新UI显示状态
      this.ak.uiDisplayState.displaySpectrumData = testData;
      
      this.testDataGenerated++;
      
      console.debug(`[瀑布图测试] 生成测试数据 #${this.testDataGenerated}`);
      
      // 测试100次后自动停止
      if (this.testDataGenerated >= 100) {
        this.stopTest();
      }
    }, 100); // 每100ms生成一次数据，比瀑布图更新频率更快
  }

  /**
   * 停止测试
   */
  private stopTest(): void {
    if (!this.testRunning) {
      return;
    }
    
    this.testRunning = false;
    
    if (this.testInterval) {
      clearInterval(this.testInterval);
      this.testInterval = undefined;
    }
    
    console.info(`[瀑布图测试] 停止测试，共生成${this.testDataGenerated}次数据`);
  }

  /**
   * 重置测试
   */
  private resetTest(): void {
    this.stopTest();
    this.testDataGenerated = 0;
    
    // 清空瀑布图历史
    // 这里需要调用WaterfallChartComponent的clearHistory方法
    console.info('[瀑布图测试] 重置测试');
  }

  build() {
    Column() {
      // 测试控制面板
      Row() {
        Button(this.testRunning ? '停止测试' : '开始测试')
          .onClick(() => {
            if (this.testRunning) {
              this.stopTest();
            } else {
              this.startTest();
            }
          })
          .margin({ right: 10 })
        
        Button('重置')
          .onClick(() => {
            this.resetTest();
          })
          .margin({ right: 10 })
        
        Text(`已生成数据: ${this.testDataGenerated}`)
          .fontSize(14)
          .margin({ right: 10 })
        
        Text(this.testRunning ? '测试中...' : '已停止')
          .fontSize(14)
          .fontColor(this.testRunning ? Color.Green : Color.Red)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .margin({ bottom: 10 })
      
      // 瀑布图组件
      WaterfallChartComponent({
        canvasWidthInput: 0,
        canvasHeightInput: 0
      })
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(10)
  }
  
  aboutToDisappear() {
    this.stopTest();
  }
}