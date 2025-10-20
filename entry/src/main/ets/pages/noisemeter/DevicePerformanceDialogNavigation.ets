import { curves } from '@kit.ArkUI';
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
  {
    category: '系统状态',
    parameterName: '校准状态',
    value: '已校准',
    unit: '',
    description: '设备校准状态',
    status: '正常',
    color: $r('sys.color.confirm')
  },
  {
    category: '系统状态',
    parameterName: '电池状态',
    value: '85',
    unit: '%',
    description: '设备电池剩余电量',
    status: '良好',
    color: $r('sys.color.warning')
  },
  {
    category: '系统状态',
    parameterName: '存储空间',
    value: '256',
    unit: 'MB',
    description: '可用存储空间',
    status: '充足',
    color: $r('sys.color.confirm')
  }
];

// 设备类别
enum DeviceCategory {
  BASIC_SPECS = '基本规格',
  ACCURACY = '精度指标',
  SENSOR = '传感器信息',
  SYSTEM = '系统状态'
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

// 设备类别选择器
interface GeneratedTypeLiteralInterface_1 {
  category: DeviceCategory;
  label: string;
}

@Builder
function buildCategorySelector(selectedCategory: DeviceCategory, onCategoryChange: (category: DeviceCategory) => void) {
  Row({ space: 8 }) {
    ForEach([
      { category: DeviceCategory.BASIC_SPECS, label: '基本规格' },
      { category: DeviceCategory.ACCURACY, label: '精度指标' },
      { category: DeviceCategory.SENSOR, label: '传感器' },
      { category: DeviceCategory.SYSTEM, label: '系统状态' }
    ], (item: GeneratedTypeLiteralInterface_1) => {
      Text(item.label)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(selectedCategory === item.category ? $r('sys.color.font_primary') : $r('sys.color.font_secondary'))
        .padding(12)
        .backgroundColor(selectedCategory === item.category ? $r('sys.color.comp_background_primary') : $r('sys.color.background_secondary'))
        .borderRadius(8)
        .onClick(() => {
          onCategoryChange(item.category);
        });
    })
  }
  .width('100%')
  .justifyContent(FlexAlign.Center)
  .padding(8)
}

// 获取设备状态摘要
interface GeneratedTypeLiteralInterface_2 {
  total: number;
  normal: number;
  warning: number;
  critical: number;
}

function getDeviceStatusSummary(): GeneratedTypeLiteralInterface_2 {
  const total = devicePerformanceData.length;
  const normal = devicePerformanceData.filter(item => item.status === '正常' || item.status === '良好' || item.status === '充足').length;
  const warning = devicePerformanceData.filter(item => item.status === '良好').length;
  const critical = devicePerformanceData.filter(item => item.status === '警告' || item.status === '不足').length;
  
  return { total, normal, warning, critical };
}

// 设备性能参考对话框构建器
@Builder
export function DevicePerformanceDialogBuilder(ak: AppKeys) {

  NavDestination() {
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
              Text(getDeviceStatusSummary().normal.toString())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('sys.color.confirm'));

              Text('正常')
                .fontSize(12)
                .fontColor($r('sys.color.font_secondary'));
            }
            .layoutWeight(1)

            Column({ space: 4 }) {
              Text(getDeviceStatusSummary().warning.toString())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('sys.color.warning'));

              Text('良好')
                .fontSize(12)
                .fontColor($r('sys.color.font_secondary'));
            }
            .layoutWeight(1)

            Column({ space: 4 }) {
              Text(getDeviceStatusSummary().total.toString())
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
        buildCategorySelector(DeviceCategory.BASIC_SPECS, (category: DeviceCategory) => {
        })

        // 性能参数列表
        Text(`${DeviceCategory.BASIC_SPECS}参数`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start);

        ForEach(devicePerformanceData, (performance: DevicePerformanceData) => {
          buildDevicePerformanceCard(performance, ak)
        })
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
  .title({ main: '设备性能参考', sub: '测量设备技术规格参考' })
  .padding(16)
  .backgroundColor($r('sys.color.background_secondary'))
}