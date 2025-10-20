import { curves } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';

// 声学参数数据接口
interface AcousticParameter {
  category: string;
  parameterName: string;
  value: string;
  unit: string;
  description: string;
  application: string;
  color: Resource;
}

// 声学参数数据
const acousticParameters: AcousticParameter[] = [
  {
    category: '频率加权',
    parameterName: 'A加权',
    value: 'A',
    unit: '',
    description: '模拟人耳对声音的感知特性，适用于环境噪声测量',
    application: '环境噪声评估、职业健康监测',
    color: $r('sys.color.confirm')
  },
  {
    category: '频率加权',
    parameterName: 'C加权',
    value: 'C',
    unit: '',
    description: '相对平坦的频率响应，适用于高声压级测量',
    application: '工业噪声、脉冲噪声测量',
    color: $r('sys.color.warning')
  },
  {
    category: '频率加权',
    parameterName: 'Z加权',
    value: 'Z',
    unit: '',
    description: '零加权，平坦频率响应，保留原始信号',
    application: '声学分析、信号处理',
    color: $r('sys.color.alert')
  },
  {
    category: '时间加权',
    parameterName: '快速响应',
    value: 'Fast',
    unit: '',
    description: '时间常数125ms，适用于快速变化的噪声',
    application: '交通噪声、瞬时噪声测量',
    color: $r('sys.color.confirm')
  },
  {
    category: '时间加权',
    parameterName: '慢速响应',
    value: 'Slow',
    unit: '',
    description: '时间常数1s，适用于稳定噪声测量',
    application: '环境背景噪声、工业噪声',
    color: $r('sys.color.warning')
  },
  {
    category: '时间加权',
    parameterName: '脉冲响应',
    value: 'Impulse',
    unit: '',
    description: '时间常数35ms，适用于脉冲噪声测量',
    application: '冲击噪声、枪声测量',
    color: $r('sys.color.alert')
  },
  {
    category: '技术参数',
    parameterName: '采样率',
    value: '44.1',
    unit: 'kHz',
    description: '音频信号采样频率',
    application: 'CD质量音频、语音分析',
    color: $r('sys.color.font_primary')
  },
  {
    category: '技术参数',
    parameterName: '位深度',
    value: '16',
    unit: 'bit',
    description: '音频信号量化精度',
    application: '标准音频质量、动态范围',
    color: $r('sys.color.font_primary')
  },
  {
    category: '技术参数',
    parameterName: '频率范围',
    value: '20-20000',
    unit: 'Hz',
    description: '可测量的频率范围',
    application: '人耳可听范围、声学分析',
    color: $r('sys.color.font_primary')
  },
  {
    category: '技术参数',
    parameterName: '动态范围',
    value: '90',
    unit: 'dB',
    description: '最大和最小可测量声压级差值',
    application: '环境噪声测量精度',
    color: $r('sys.color.font_primary')
  }
];

// 参数类别
enum ParameterCategory {
  FREQUENCY_WEIGHTING = '频率加权',
  TIME_WEIGHTING = '时间加权',
  TECHNICAL_PARAMS = '技术参数'
}

// 构建声学参数卡片
@Builder
function buildAcousticParamCard(param: AcousticParameter, ak: AppKeys) {
  Column({ space: 8 }) {
    // 参数类别和名称
    Row() {
      Text(param.category)
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'))
        .padding({ left: 8, top: 4, bottom: 4, right: 8 })
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(6);

      Text(param.parameterName)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .layoutWeight(1)
        .margin({ left: 8 });
    }
    .width('100%')

    // 参数值和单位
    Row() {
      Text(param.value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(param.color);

      if (param.unit) {
        Text(param.unit)
          .fontSize(14)
          .fontColor($r('sys.color.font_secondary'))
          .margin({ left: 4 });
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)

    // 参数描述
    Text(param.description)
      .fontSize(12)
      .fontColor($r('sys.color.font_secondary'))
      .width('100%')
      .textAlign(TextAlign.Start);

    // 应用场景
    Column({ space: 4 }) {
      Text('应用场景:')
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start);

      Text(param.application)
        .fontSize(11)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
        .textAlign(TextAlign.Start);
    }
    .width('100%')
    .margin({ top: 8 })
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

// 参数类别选择器
interface GeneratedTypeLiteralInterface_1 {
  category: ParameterCategory;
  label: string;
}

@Builder
function buildCategorySelector(selectedCategory: ParameterCategory, onCategoryChange: (category: ParameterCategory) => void) {
  Row({ space: 8 }) {
    ForEach([
      { category: ParameterCategory.FREQUENCY_WEIGHTING, label: '频率加权' },
      { category: ParameterCategory.TIME_WEIGHTING, label: '时间加权' },
      { category: ParameterCategory.TECHNICAL_PARAMS, label: '技术参数' }
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

// 获取当前使用的参数
function getCurrentParameters(): AcousticParameter[] {
  // 这里可以根据实际应用状态返回当前使用的参数
  // 目前返回频率加权和时间加权的参数作为示例
  return acousticParameters.filter(param => 
    param.category === '频率加权' || param.category === '时间加权'
  );
}

// 声学参数参考对话框构建器
@Builder
export function AcousticParamsDialogBuilder(ak: AppKeys) {

  NavDestination() {
    Scroll() {
      Column({ space: 16 }) {
        // 当前使用参数
        if (getCurrentParameters().length > 0) {
          Column({ space: 8 }) {
            Text('当前使用参数')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
              .alignSelf(ItemAlign.Start);

            ForEach(getCurrentParameters(), (param: AcousticParameter) => {
              buildAcousticParamCard(param, ak)
            })
          }
          .width('100%')
          .padding({ bottom: 16 })

          // 分隔线
          Divider()
            .strokeWidth(1)
            .color($r('sys.color.comp_divider'))
            .margin({ bottom: 16 })
        }

        // 参数类别选择器
        buildCategorySelector(ParameterCategory.FREQUENCY_WEIGHTING, (category: ParameterCategory) => {
        })

        // 参数列表
        Text(`${ParameterCategory.FREQUENCY_WEIGHTING}参数`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start);

        ForEach(acousticParameters, (param: AcousticParameter) => {
          buildAcousticParamCard(param, ak)
        })
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
  .title({ main: '声学参数参考', sub: '专业声学测量参数说明' })
  .padding(16)
  .backgroundColor($r('sys.color.background_secondary'))
}