import { 
  useAudioService, 
  useAlertService, 
  useDisplayConfig 
} from '../factory/ServiceFactory';

/**
 * 解耦的分贝检测组件
 * 不依赖任何具体实现，只使用接口
 * 自动适配手机/平板/手表
 */
@Component
export struct DecibelMeter {
  // 通过工厂获取服务，不直接创建具体实现
  private audioService = useAudioService();
  private alertService = useAlertService();
  private displayConfig = useDisplayConfig();
  
  @State currentDecibel: number = 0;
  @State minDecibel: number = 0;
  @State avgDecibel: number = 0;
  @State maxDecibel: number = 0;
  @State isDetecting: boolean = false;
  @State isAlerting: boolean = false;

  aboutToAppear() {
    // 订阅数据更新
    this.audioService.onDataUpdate((data) => {
      this.currentDecibel = data.currentDecibel;
      this.minDecibel = data.min;
      this.avgDecibel = data.avg;
      this.maxDecibel = data.max;
      
      // 检查警报
      this.alertService.checkAlert(data.currentDecibel);
    });

    // 订阅警报状态
    this.alertService.onAlertChange((isAlerting) => {
      this.isAlerting = isAlerting;
    });

    // 初始化音频服务
    this.audioService.init();
  }

  aboutToDisappear() {
    this.audioService.release();
  }

  build() {
    Column({ space: 16 }) {
      // 当前分贝显示 - 根据设备使用不同字体大小
      Text(this.isDetecting ? `${this.currentDecibel}` : '--')
        .fontSize(this.displayConfig.largeFontSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isAlerting ? '#F44336' : '#1890FF')

      Text('dB')
        .fontSize(this.displayConfig.defaultFontSize)
        .fontColor('#666')

      // 统计信息 - 所有设备都显示
      if (this.isDetecting) {
        Row({ space: 20 }) {
          this.StatItem('最小', this.minDecibel);
          this.StatItem('平均', this.avgDecibel);
          this.StatItem('最大', this.maxDecibel);
        }
      }

      // 设备特有功能区域
      this.DeviceSpecificArea()

      // 控制按钮
      Button(this.isDetecting ? '停止' : '开始')
        .width(this.displayConfig.buttonSize * 2)
        .height(this.displayConfig.buttonSize)
        .onClick(() => this.toggleDetection())
    }
    .padding(this.displayConfig.pagePadding)
  }

  // 统计项组件
  @Builder
  StatItem(label: string, value: number) {
    Column() {
      Text(label)
        .fontSize(this.displayConfig.defaultFontSize - 2)
        .fontColor('#999')
      Text(value === 0 ? '-' : `${value}`)
        .fontSize(this.displayConfig.defaultFontSize + 2)
        .fontWeight(FontWeight.Medium)
    }
  }

  // 设备特有功能区
  @Builder
  DeviceSpecificArea() {
    // 根据设备配置显示不同内容
    if (this.displayConfig.supportSpectrum && this.isDetecting) {
      // 手机/平板：显示频谱图
      Text('频谱图区域')
        .width('100%')
        .height(100)
        .backgroundColor('#F5F5F5')
        .textAlign(TextAlign.Center)
    }

    if (this.displayConfig.supportVibrate && this.isAlerting) {
      // 手表：显示振动提醒状态
      Row() {
        Circle().width(8).height(8).fill('#F44336')
        Text(' 振动提醒中').fontColor('#F44336')
      }
    }

    if (this.isAlerting && !this.displayConfig.supportVibrate) {
      // 手机：显示通知提醒状态
      Text('⚠️ 噪音超标 - 已发送通知')
        .fontColor('#F44336')
        .padding(8)
        .backgroundColor('#FFEBEE')
        .borderRadius(4)
    }
  }

  private async toggleDetection() {
    if (this.isDetecting) {
      await this.audioService.stop();
      this.isDetecting = false;
    } else {
      const started = await this.audioService.start();
      this.isDetecting = started;
    }
  }
}
