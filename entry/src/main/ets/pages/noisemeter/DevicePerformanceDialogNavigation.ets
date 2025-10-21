import { curves, AppStorageV2 } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';

// 设备性能数据接口
interface DevicePerformanceData {
  category: string;
  parameterName: string;
  value: string;
  unit: string;
  description: string;
  status: string;
  color: Resource;
}

// 设备性能数据
const devicePerformanceData: DevicePerformanceData[] = [
  {
    category: '基本规格',
    parameterName: '测量范围',
    value: '30-120',
    unit: 'dB',
    description: '可测量的声压级范围',
    status: '正常',
    color: $r('sys.color.confirm')
  },
  {
    category: '基本规格',
    parameterName: '频率范围',
    value: '20-20000',
    unit: 'Hz',
    description: '可测量的频率范围',
    status: '正常',
    color: $r('sys.color.confirm')
  },
  {
    category: '基本规格',
    parameterName: '采样率',
    value: '44.1',
    unit: 'kHz',
    description: '音频信号采样频率',
    status: '正常',
    color: $r('sys.color.confirm')
  },
  {
    category: '精度指标',
    parameterName: '测量精度',
    value: '±1.5',
    unit: 'dB',
    description: '典型测量精度误差',
    status: '良好',
    color: $r('sys.color.warning')
  },
  {
    category: '精度指标',
    parameterName: '频率响应',
    value: '±2',
    unit: 'dB',
    description: '频率响应平坦度',
    status: '良好',
    color: $r('sys.color.warning')
  },
  {
    category: '精度指标',
    parameterName: '动态范围',
    value: '90',
    unit: 'dB',
    description: '最大和最小可测量声压级差值',
    status: '良好',
    color: $r('sys.color.warning')
  },
  {
    category: '传感器信息',
    parameterName: '麦克风类型',
    value: 'MEMS',
    unit: '',
    description: '微机电系统麦克风',
    status: '正常',
    color: $r('sys.color.font_primary')
  },
  {
    category: '传感器信息',
    parameterName: '灵敏度',
    value: '-26',
    unit: 'dBFS',
    description: '麦克风灵敏度',
    status: '正常',
    color: $r('sys.color.font_primary')
  },
  {
    category: '传感器信息',
    parameterName: '信噪比',
    value: '64',
    unit: 'dB',
    description: '信号与噪声比值',
    status: '良好',
    color: $r('sys.color.font_primary')
  },
];

// 设备类别
enum DeviceCategory {
  BASIC_SPECS = '基本规格',
  ACCURACY = '精度指标',
  SENSOR = '传感器信息'
}

// 构建设备性能卡片
@Builder
function buildDevicePerformanceCard(performance: DevicePerformanceData, ak: AppKeys) {
  Column({ space: 8 }) {
    // 参数类别和名称
    Row() {
      Text(performance.category)
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'))
        .padding(8)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(6);

      Text(performance.parameterName)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .layoutWeight(1)
        .margin({ left: 8 });
    }
    .width('100%')

    // 参数值和单位
    Row() {
      Text(performance.value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(performance.color);

      if (performance.unit) {
        Text(performance.unit)
          .fontSize(14)
          .fontColor($r('sys.color.font_secondary'))
          .margin({ left: 4 });
      }

      Blank()

      // 状态指示
      Text(performance.status)
        .fontSize(12)
        .fontColor($r('sys.color.font_primary'))
        .padding(8)
        .backgroundColor(performance.color)
        .borderRadius(6);
    }
    .width('100%')

    // 参数描述
    Text(performance.description)
      .fontSize(12)
      .fontColor($r('sys.color.font_secondary'))
      .width('100%')
      .textAlign(TextAlign.Start);
  }
  .padding(12)
  .width('100%')
  .backgroundColor($r('sys.color.comp_background_primary'))
  .borderRadius(12)
  .alignItems(HorizontalAlign.Start)
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) })
    .combine(TransitionEffect.scale({ x: 0, y: 0 }))
    .combine(TransitionEffect.translate({ x: -150, y: 0 }).animation({ curve: curves.springMotion() })))
}

// 设备类别选择器类型定义
interface CategorySelectorItem {
  category: DeviceCategory;
  label: string;
}

// 设备性能参考组件
interface GeneratedTypeLiteralInterface_1 {
  total: number;
  normal: number;
  warning: number;
  critical: number;
}

@ComponentV2
struct DevicePerformanceComponent {
  @Local selectedCategory: DeviceCategory = DeviceCategory.BASIC_SPECS
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;

  aboutToAppear() {
  }

  // 获取过滤后的性能数据
  private getFilteredPerformanceData(): DevicePerformanceData[] {
    return devicePerformanceData.filter(data => data.category === this.selectedCategory)
  }

  // 获取设备类别标签
  private getCategoryLabel(category: DeviceCategory): string {
    switch (category) {
      case DeviceCategory.BASIC_SPECS:
        return '基本规格'
      case DeviceCategory.ACCURACY:
        return '精度指标'
      case DeviceCategory.SENSOR:
        return '传感器信息'
    }
  }

  // 获取类别选择器项目
  private getCategoryItems(): CategorySelectorItem[] {
    return [
      { category: DeviceCategory.BASIC_SPECS, label: '基本规格' },
      { category: DeviceCategory.ACCURACY, label: '精度指标' },
      { category: DeviceCategory.SENSOR, label: '传感器' }
    ]
  }

  // 获取设备状态摘要
  private getDeviceStatusSummary(): GeneratedTypeLiteralInterface_1 {
    const total = devicePerformanceData.length;
    const normal = devicePerformanceData.filter(item => item.status === '正常' || item.status === '良好' || item.status === '充足').length;
    const warning = devicePerformanceData.filter(item => item.status === '良好').length;
    const critical = devicePerformanceData.filter(item => item.status === '警告' || item.status === '不足').length;
    
    return { total, normal, warning, critical };
  }

  // 类别选择器
  @Builder
  buildCategorySelector() {
    Row({ space: 8 }) {
      ForEach(this.getCategoryItems(), (item: CategorySelectorItem) => {
        Text(item.label)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.selectedCategory === item.category ? $r('sys.color.font_primary') : $r('sys.color.font_secondary'))
          .padding(12)
          .backgroundColor(this.selectedCategory === item.category ? $r('sys.color.comp_background_primary') : $r('sys.color.background_secondary'))
          .borderRadius(8)
          .onClick(() => {
            this.selectedCategory = item.category
          })
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(8)
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // 设备状态摘要
        Column({ space: 8 }) {
          Text('设备状态摘要')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
            .alignSelf(ItemAlign.Start);

          Row({ space: 12 }) {
            Column({ space: 4 }) {
              Text(this.getDeviceStatusSummary().normal.toString())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('sys.color.confirm'));

              Text('正常')
                .fontSize(12)
                .fontColor($r('sys.color.font_secondary'));
            }
            .layoutWeight(1)

            Column({ space: 4 }) {
              Text(this.getDeviceStatusSummary().warning.toString())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('sys.color.warning'));

              Text('良好')
                .fontSize(12)
                .fontColor($r('sys.color.font_secondary'));
            }
            .layoutWeight(1)

            Column({ space: 4 }) {
              Text(this.getDeviceStatusSummary().total.toString())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('sys.color.font_primary'));

              Text('总计')
                .fontSize(12)
                .fontColor($r('sys.color.font_secondary'));
            }
            .layoutWeight(1)
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius(12)
        }
        .width('100%')

        // 设备类别选择器
        this.buildCategorySelector()

        // 性能参数列表
        Text(`${this.getCategoryLabel(this.selectedCategory)}参数`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start);

        ForEach(this.getFilteredPerformanceData(), (performance: DevicePerformanceData) => {
          buildDevicePerformanceCard(performance, this.ak)
        })
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}


// 设备性能参考对话框构建器
@Builder
export function DevicePerformanceDialogBuilder(ak: AppKeys) {

  NavDestination() {
    DevicePerformanceComponent()
  }
  .title({ main: '设备性能参考', sub: '测量设备技术规格参考' })
  .padding(16)
  .backgroundColor($r('sys.color.background_secondary'))
}