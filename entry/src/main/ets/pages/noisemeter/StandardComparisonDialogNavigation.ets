import { AppStorageV2, curves } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';
import { DecibelService } from '../../services/DecibelService';
import { Throttle } from '../../utils/Debounce';

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
    color: $r('app.color.confirm')
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
    color: $r('app.color.warning')
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
    color: $r('app.color.alert')
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
    color: $r('app.color.font_primary')
  }
];

// 功能区类型
enum AreaType {
  RESIDENTIAL = 'residential',
  COMMERCIAL = 'commercial',
  INDUSTRIAL = 'industrial'
}

// 功能区选择器类型定义
interface AreaTypeSelectorItem {
  type: AreaType;
  label: string;
}

// 功能区限值数据接口
interface AreaLimits {
  day: number;
  night: number;
}

// 标准对比组件
@ComponentV2
struct StandardComparisonComponent {
  @Local selectedAreaType: AreaType = AreaType.RESIDENTIAL
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;

  aboutToAppear() {
  }

  // 获取功能区限值
  private getAreaLimits(standard: InternationalStandard, areaType: AreaType): AreaLimits {
    switch (areaType) {
      case AreaType.RESIDENTIAL:
        return { day: standard.residentialDay, night: standard.residentialNight }
      case AreaType.COMMERCIAL:
        return { day: standard.commercialDay, night: standard.commercialNight }
      case AreaType.INDUSTRIAL:
        return { day: standard.industrialDay, night: standard.industrialNight }
    }
  }

  // 获取功能区名称
  private getAreaTypeLabel(areaType: AreaType): string {
    switch (areaType) {
      case AreaType.RESIDENTIAL:
        return '居住区'
      case AreaType.COMMERCIAL:
        return '商业区'
      case AreaType.INDUSTRIAL:
        return '工业区'
    }
  }

  // 功能区选择器
  @Builder
  buildAreaTypeSelector() {
    Row({ space: 8 }) {
      ForEach(this.getAreaTypeItems(), (item: AreaTypeSelectorItem) => {
        Text(item.label)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.selectedAreaType === item.type ? $r('app.color.font_primary') : $r('app.color.font_secondary'))
          .padding(12)
          .backgroundColor(this.selectedAreaType === item.type ? $r('app.color.comp_background_primary') : $r('app.color.background_secondary'))
          .borderRadius(8)
          .onClick(() => {
            Throttle.click(() => {
            this.selectedAreaType = item.type
            });
          })
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(8)
  }

  // 获取功能区选择器项目
  private getAreaTypeItems(): AreaTypeSelectorItem[] {
    return [
      { type: AreaType.RESIDENTIAL, label: '居住区' },
      { type: AreaType.COMMERCIAL, label: '商业区' },
      { type: AreaType.INDUSTRIAL, label: '工业区' }
    ]
  }

  // 标准对比卡片
  @Builder
  buildStandardComparisonCard(standard: InternationalStandard) {
    Column({ space: 8 }) {
      // 国家和标准名称
      Row() {
        Text(standard.country)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.font_primary'))
          .layoutWeight(1)

        Text(standard.standardName)
          .fontSize(12)
          .fontColor($r('app.color.font_secondary'))
      }
      .width('100%')

      // 功能区限值
      Row() {
        Column({ space: 4 }) {
          Text('昼间')
            .fontSize(12)
            .fontColor($r('app.color.font_secondary'))

          Text(`${this.getAreaLimits(standard, this.selectedAreaType).day} dB`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(DecibelService.getDecibelColor(this.getAreaLimits(standard, this.selectedAreaType).day))
        }
        .layoutWeight(1)

        Column({ space: 4 }) {
          Text('夜间')
            .fontSize(12)
            .fontColor($r('app.color.font_secondary'))

          Text(`${this.getAreaLimits(standard, this.selectedAreaType).night} dB`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(DecibelService.getDecibelColor(this.getAreaLimits(standard, this.selectedAreaType).night))
        }
        .layoutWeight(1)
      }
      .width('100%')

      // 符合状态 - 添加状态标签
      Row() {
        Text('符合状态:')
          .fontSize(12)
          .fontColor($r('app.color.font_secondary'))

        if (this.isCompliant(standard)) {
          Text('符合标准')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.confirm'))
            .margin({ left: 8 })
        } else {
          Text('超出标准')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_primary'))
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor($r('app.color.alert'))
            .borderRadius(6)
            .opacity(0.9)
            .margin({ left: 8 })
        }
      }
      .width('100%')

      // 标准描述
      Text(standard.description)
        .fontSize(11)
        .fontColor($r('app.color.font_secondary'))
        .width('100%')
        .textAlign(TextAlign.Start)
    }
    .padding(12)
    .width('100%')
    .backgroundBlurStyle(this.isCompliant(standard) ? BlurStyle.COMPONENT_ULTRA_THIN : BlurStyle.NONE)
    .backgroundColor($r('app.color.comp_background_primary'))
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
    .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) })
      .combine(TransitionEffect.scale({ x: 0, y: 0 }))
      .combine(TransitionEffect.translate({ x: -150, y: 0 }).animation({ curve: curves.springMotion() })))
  }

  // 检查是否符合标准
  private isCompliant(standard: InternationalStandard): boolean {
    return this.ak.uiDisplayState.displayDb <= this.getAreaLimits(standard, this.selectedAreaType).day
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // 当前分贝显示
        Row() {
          Text('当前分贝值:')
            .fontSize(14)
            .fontColor($r('app.color.font_secondary'))

          Text(`${this.ak.uiDisplayState.displayDb} dB`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(DecibelService.getDecibelColor(this.ak.uiDisplayState.displayDb))
            .margin({ left: 8 })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        // 功能区选择器
        this.buildAreaTypeSelector()

        // 当前功能区标题
        Text(`${this.getAreaTypeLabel(this.selectedAreaType)}标准对比`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        // 国际标准对比
        ForEach(internationalStandards, (standard: InternationalStandard) => {
          this.buildStandardComparisonCard(standard)
        })
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}

// 标准对比对话框构建器
@Builder
export function StandardComparisonDialogBuilder(ak: AppKeys) {
  NavDestination() {
    StandardComparisonComponent()
  }
  .title({ main: '标准对比参考', sub: '国际噪音标准对比分析' })
  .padding(16)
  .backgroundColor($r('app.color.background_secondary'))
}