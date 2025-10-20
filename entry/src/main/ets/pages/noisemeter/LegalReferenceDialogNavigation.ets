import { curves, AppStorageV2 } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';
import { DecibelService } from '../../services/DecibelService';

// 法规政策数据接口
interface LegalReferenceData {
  category: string;
  lawName: string;
  code: string;
  effectiveDate: string;
  applicableScope: string;
  dayLimit: number;
  nightLimit: number;
  penalty: string;
  description: string;
  color: Resource;
}

// 法规政策数据
const legalReferenceData: LegalReferenceData[] = [
  {
    category: '国家标准',
    lawName: '声环境质量标准',
    code: 'GB 3096-2008',
    effectiveDate: '2008-10-01',
    applicableScope: '全国范围',
    dayLimit: 55,
    nightLimit: 45,
    penalty: '责令改正，处以罚款',
    description: '规定了不同声环境功能区的环境噪声限值',
    color: $r('sys.color.confirm')
  },
  {
    category: '国家标准',
    lawName: '社会生活环境噪声排放标准',
    code: 'GB 22337-2008',
    effectiveDate: '2008-10-01',
    applicableScope: '社会生活噪声源',
    dayLimit: 50,
    nightLimit: 40,
    penalty: '责令改正，处以罚款',
    description: '规定了社会生活噪声排放限值',
    color: $r('sys.color.confirm')
  },
  {
    category: '国家标准',
    lawName: '工业企业厂界环境噪声排放标准',
    code: 'GB 12348-2008',
    effectiveDate: '2008-10-01',
    applicableScope: '工业企业',
    dayLimit: 65,
    nightLimit: 55,
    penalty: '责令改正，处以罚款',
    description: '规定了工业企业厂界环境噪声排放限值',
    color: $r('sys.color.confirm')
  },
  {
    category: '国家标准',
    lawName: '建筑施工场界环境噪声排放标准',
    code: 'GB 12523-2011',
    effectiveDate: '2012-07-01',
    applicableScope: '建筑施工',
    dayLimit: 70,
    nightLimit: 55,
    penalty: '责令改正，处以罚款',
    description: '规定了建筑施工场界环境噪声排放限值',
    color: $r('sys.color.warning')
  },
  {
    category: '地方法规',
    lawName: '北京市环境噪声污染防治办法',
    code: '北京市政府令第181号',
    effectiveDate: '2007-01-01',
    applicableScope: '北京市行政区域',
    dayLimit: 55,
    nightLimit: 45,
    penalty: '责令改正，处以罚款',
    description: '北京市环境噪声污染防治的具体规定',
    color: $r('sys.color.alert')
  },
  {
    category: '地方法规',
    lawName: '上海市社会生活噪声污染防治办法',
    code: '上海市政府令第94号',
    effectiveDate: '2013-03-01',
    applicableScope: '上海市行政区域',
    dayLimit: 50,
    nightLimit: 40,
    penalty: '责令改正，处以罚款',
    description: '上海市社会生活噪声污染防治的具体规定',
    color: $r('sys.color.alert')
  },
  {
    category: '行业标准',
    lawName: '城市区域环境噪声标准',
    code: 'GB/T 14623-93',
    effectiveDate: '1994-03-01',
    applicableScope: '城市区域',
    dayLimit: 55,
    nightLimit: 45,
    penalty: '参考相关法规',
    description: '城市区域环境噪声的测量和评价标准',
    color: $r('sys.color.font_primary')
  },
  {
    category: '行业标准',
    lawName: '环境噪声监测技术规范',
    code: 'HJ 640-2012',
    effectiveDate: '2013-01-01',
    applicableScope: '环境噪声监测',
    dayLimit: 55,
    nightLimit: 45,
    penalty: '技术规范',
    description: '环境噪声监测的技术要求和方法',
    color: $r('sys.color.font_primary')
  }
];

// 法规类别
enum LegalCategory {
  NATIONAL = '国家标准',
  LOCAL = '地方法规',
  INDUSTRY = '行业标准'
}

// 构建法规政策卡片
@Builder
function buildLegalReferenceCard(legal: LegalReferenceData, ak: AppKeys, isCompliant: boolean) {

  Column({ space: 8 }) {
    // 法规类别和名称
    Row() {
      Text(legal.category)
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'))
        .padding(8)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(6);

      Text(legal.lawName)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .layoutWeight(1)
        .margin({ left: 8 });
    }
    .width('100%')

    // 法规代码和生效日期
    Row() {
      Text(legal.code)
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'));

      Text(legal.effectiveDate)
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'))
        .margin({ left: 8 });
    }
    .width('100%')

    // 噪声限值
    Row() {
      Column({ space: 4 }) {
        Text('昼间限值')
          .fontSize(12)
          .fontColor($r('sys.color.font_secondary'));

        Text(`${legal.dayLimit} dB`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(DecibelService.getDecibelColor(legal.dayLimit));
      }
      .layoutWeight(1)

      Column({ space: 4 }) {
        Text('夜间限值')
          .fontSize(12)
          .fontColor($r('sys.color.font_secondary'));

        Text(`${legal.nightLimit} dB`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(DecibelService.getDecibelColor(legal.nightLimit));
      }
      .layoutWeight(1)
    }
    .width('100%')

    // 符合状态
    Row() {
      Text('符合状态:')
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'));

      Text(isCompliant ? '符合法规' : '超出法规限值')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(isCompliant ? $r('sys.color.confirm') : $r('sys.color.alert'))
        .margin({ left: 8 });
    }
    .width('100%')

    // 适用范围
    Text(`适用范围: ${legal.applicableScope}`)
      .fontSize(11)
      .fontColor($r('sys.color.font_secondary'))
      .width('100%')
      .textAlign(TextAlign.Start);

    // 处罚措施
    if (legal.penalty && legal.penalty !== '技术规范') {
      Text(`处罚措施: ${legal.penalty}`)
        .fontSize(11)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
        .textAlign(TextAlign.Start);
    }

    // 法规描述
    Text(legal.description)
      .fontSize(11)
      .fontColor($r('sys.color.font_secondary'))
      .width('100%')
      .textAlign(TextAlign.Start);
  }
  .padding(12)
  .width('100%')
  .backgroundBlurStyle(isCompliant ? BlurStyle.COMPONENT_ULTRA_THIN : BlurStyle.NONE)
  .backgroundColor(isCompliant ? $r('sys.color.comp_background_primary') : legal.color)
  .borderRadius(12)
  .alignItems(HorizontalAlign.Start)
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) })
    .combine(TransitionEffect.scale({ x: 0, y: 0 }))
    .combine(TransitionEffect.translate({ x: -150, y: 0 }).animation({ curve: curves.springMotion() })))
}

// 法规类别选择器类型定义
interface CategorySelectorItem {
  category: LegalCategory;
  label: string;
}

// 法规政策参考组件
interface GeneratedTypeLiteralInterface_1 {
  total: number;
  compliant: number;
  nonCompliant: number;
}

@ComponentV2
struct LegalReferenceComponent {
  @Local selectedCategory: LegalCategory = LegalCategory.NATIONAL
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;

  aboutToAppear() {
  }

  // 获取过滤后的法规数据
  private getFilteredLegalData(): LegalReferenceData[] {
    return legalReferenceData.filter(data => data.category === this.selectedCategory)
  }

  // 获取法规类别标签
  private getCategoryLabel(category: LegalCategory): string {
    switch (category) {
      case LegalCategory.NATIONAL:
        return '国家标准'
      case LegalCategory.LOCAL:
        return '地方法规'
      case LegalCategory.INDUSTRY:
        return '行业标准'
    }
  }

  // 获取类别选择器项目
  private getCategoryItems(): CategorySelectorItem[] {
    return [
      { category: LegalCategory.NATIONAL, label: '国家标准' },
      { category: LegalCategory.LOCAL, label: '地方法规' },
      { category: LegalCategory.INDUSTRY, label: '行业标准' }
    ]
  }

  // 获取合规统计
  private getComplianceStats(currentDb: number): GeneratedTypeLiteralInterface_1 {
    const total = legalReferenceData.length;
    const compliant = legalReferenceData.filter(legal => currentDb <= legal.dayLimit).length;
    const nonCompliant = total - compliant;
    
    return { total, compliant, nonCompliant };
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
          .padding(8)
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
        // 合规统计
        Column({ space: 8 }) {
          Text('法规合规统计')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
            .alignSelf(ItemAlign.Start);

          Row({ space: 12 }) {
            Column({ space: 4 }) {
              Text(this.getComplianceStats(this.ak.uiDisplayState.displayDb).compliant.toString())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('sys.color.confirm'));

              Text('合规')
                .fontSize(12)
                .fontColor($r('sys.color.font_secondary'));
            }
            .layoutWeight(1)

            Column({ space: 4 }) {
              Text(this.getComplianceStats(this.ak.uiDisplayState.displayDb).nonCompliant.toString())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('sys.color.alert'));

              Text('不合规')
                .fontSize(12)
                .fontColor($r('sys.color.font_secondary'));
            }
            .layoutWeight(1)

            Column({ space: 4 }) {
              Text(this.getComplianceStats(this.ak.uiDisplayState.displayDb).total.toString())
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

        // 法规类别选择器
        this.buildCategorySelector()

        // 法规列表
        Text(`${this.getCategoryLabel(this.selectedCategory)}法规`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start);

        ForEach(this.getFilteredLegalData(), (legal: LegalReferenceData) => {
          buildLegalReferenceCard(legal, this.ak, this.ak.uiDisplayState.displayDb <= legal.dayLimit)
        })
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}

// 获取合规统计
interface GeneratedTypeLiteralInterface_2 {
  total: number;
  compliant: number;
  nonCompliant: number;
}

function getComplianceStats(currentDb: number): GeneratedTypeLiteralInterface_2 {
  const total = legalReferenceData.length;
  const compliant = legalReferenceData.filter(legal => currentDb <= legal.dayLimit).length;
  const nonCompliant = total - compliant;
  
  return { total, compliant, nonCompliant };
}

// 法规政策参考对话框构建器
@Builder
export function LegalReferenceDialogBuilder(ak: AppKeys) {

  NavDestination() {
    LegalReferenceComponent()
  }
  .title({ main: '法规政策参考', sub: '噪音相关法律法规参考' })
  .padding(16)
  .backgroundColor($r('sys.color.background_secondary'))
}