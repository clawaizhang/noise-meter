import { curves } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';
import { DecibelService } from '../../services/DecibelService';

// 国际标准数据接口
interface InternationalStandard {
  country: string;
  standardName: string;
  residentialDay: number;
  residentialNight: number;
  commercialDay: number;
  commercialNight: number;
  industrialDay: number;
  industrialNight: number;
  description: string;
  color: Resource;
}

// 国际噪音标准数据
const internationalStandards: InternationalStandard[] = [
  {
    country: '中国',
    standardName: 'GB 3096-2008',
    residentialDay: 55,
    residentialNight: 45,
    commercialDay: 60,
    commercialNight: 50,
    industrialDay: 65,
    industrialNight: 55,
    description: '声环境质量标准',
    color: $r('sys.color.confirm')
  },
  {
    country: '美国',
    standardName: 'EPA/OSHA',
    residentialDay: 55,
    residentialNight: 45,
    commercialDay: 65,
    commercialNight: 55,
    industrialDay: 85,
    industrialNight: 85,
    description: '环境保护署/职业安全健康管理局',
    color: $r('sys.color.warning')
  },
  {
    country: '欧盟',
    standardName: 'EU Directive',
    residentialDay: 55,
    residentialNight: 45,
    commercialDay: 65,
    commercialNight: 55,
    industrialDay: 70,
    industrialNight: 70,
    description: '欧洲环境噪音指令',
    color: $r('sys.color.alert')
  },
  {
    country: 'WHO',
    standardName: 'WHO Guidelines',
    residentialDay: 55,
    residentialNight: 45,
    commercialDay: 55,
    commercialNight: 45,
    industrialDay: 70,
    industrialNight: 70,
    description: '世界卫生组织指南',
    color: $r('sys.color.font_primary')
  }
];

// 功能区类型
enum AreaType {
  RESIDENTIAL = 'residential',
  COMMERCIAL = 'commercial',
  INDUSTRIAL = 'industrial'
}

// 构建标准对比卡片
@Builder
function buildStandardComparisonCard(standard: InternationalStandard, ak: AppKeys, areaType: AreaType) {

  Column({ space: 8 }) {
    // 国家和标准名称
    Row() {
      Text(standard.country)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .layoutWeight(1);

      Text(standard.standardName)
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'));
    }
    .width('100%')

    // 功能区限值
    Row() {
      Column({ space: 4 }) {
        Text('昼间')
          .fontSize(12)
          .fontColor($r('sys.color.font_secondary'));

        Text(`${standard.residentialDay} dB`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(DecibelService.getDecibelColor(standard.residentialDay));
      }
      .layoutWeight(1)

      Column({ space: 4 }) {
        Text('夜间')
          .fontSize(12)
          .fontColor($r('sys.color.font_secondary'));

        Text(`${standard.residentialNight} dB`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(DecibelService.getDecibelColor(standard.residentialNight));
      }
      .layoutWeight(1)
    }
    .width('100%')

    // 符合状态
    Row() {
      Text('符合状态:')
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'));

      Text(ak.uiDisplayState.displayDb <= standard.residentialDay ? '符合标准' : '超出标准')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(ak.uiDisplayState.displayDb <= standard.residentialDay ? $r('sys.color.confirm') : $r('sys.color.alert'))
        .margin({ left: 8 });
    }
    .width('100%')

    // 标准描述
    Text(standard.description)
      .fontSize(11)
      .fontColor($r('sys.color.font_secondary'))
      .width('100%')
      .textAlign(TextAlign.Start);
  }
  .padding(12)
  .width('100%')
  .backgroundBlurStyle(ak.uiDisplayState.displayDb <= standard.residentialDay ? BlurStyle.COMPONENT_ULTRA_THIN : BlurStyle.NONE)
  .backgroundColor(ak.uiDisplayState.displayDb <= standard.residentialDay ? $r('sys.color.comp_background_primary') : standard.color)
  .borderRadius(12)
  .alignItems(HorizontalAlign.Start)
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) })
    .combine(TransitionEffect.scale({ x: 0, y: 0 }))
    .combine(TransitionEffect.translate({ x: -150, y: 0 }).animation({ curve: curves.springMotion() })))
}

// 功能区选择器
interface GeneratedTypeLiteralInterface_1 {
  type: AreaType;
  label: string;
}

@Builder
function buildAreaTypeSelector(selectedAreaType: AreaType, onAreaTypeChange: (type: AreaType) => void) {
  Row({ space: 8 }) {
    ForEach([
      { type: AreaType.RESIDENTIAL, label: '居住区' },
      { type: AreaType.COMMERCIAL, label: '商业区' },
      { type: AreaType.INDUSTRIAL, label: '工业区' }
    ], (item: GeneratedTypeLiteralInterface_1) => {
      Text(item.label)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(selectedAreaType === item.type ? $r('sys.color.font_primary') : $r('sys.color.font_secondary'))
        .padding(12)
        .backgroundColor(selectedAreaType === item.type ? $r('sys.color.comp_background_primary') : $r('sys.color.background_secondary'))
        .borderRadius(8)
        .onClick(() => {
          onAreaTypeChange(item.type);
        });
    })
  }
  .width('100%')
  .justifyContent(FlexAlign.Center)
  .padding(8)
}

// 标准对比对话框构建器
@Builder
export function StandardComparisonDialogBuilder(ak: AppKeys) {

  NavDestination() {
    Scroll() {
      Column({ space: 16 }) {
        // 当前分贝显示
        Row() {
          Text('当前分贝值:')
            .fontSize(14)
            .fontColor($r('sys.color.font_secondary'));

          Text(`${ak.uiDisplayState.displayDb} dB`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(DecibelService.getDecibelColor(ak.uiDisplayState.displayDb))
            .margin({ left: 8 });
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        // 功能区选择器
        buildAreaTypeSelector(AreaType.RESIDENTIAL, (type: AreaType) => {
        })

        // 国际标准对比
        Text('国际标准对比')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start);

        ForEach(internationalStandards, (standard: InternationalStandard) => {
          buildStandardComparisonCard(standard, ak, AreaType.RESIDENTIAL)
        })
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
  .title({ main: '标准对比参考', sub: '国际噪音标准对比分析' })
  .padding(16)
  .backgroundColor($r('sys.color.background_secondary'))
}