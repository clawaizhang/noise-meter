import { AppStorageV2, curves } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';
import { DecibelService } from '../../services/DecibelService';

// 场景数据接口
interface ScenarioData {
  scenarioType: string;
  scenarioName: string;
  idealDb: number;
  maxDb: number;
  description: string;
  improvementMeasures: string[];
  color: Resource;
}

// 场景数据
const scenarioData: ScenarioData[] = [
  {
    scenarioType: '居住',
    scenarioName: '卧室',
    idealDb: 30,
    maxDb: 40,
    description: '睡眠和休息环境',
    improvementMeasures: [
      '使用隔音窗帘',
      '安装双层玻璃窗',
      '使用白噪音机',
      '避免夜间使用高噪音设备'
    ],
    color: $r('sys.color.confirm')
  },
  {
    scenarioType: '居住',
    scenarioName: '客厅',
    idealDb: 40,
    maxDb: 50,
    description: '家庭活动和休闲',
    improvementMeasures: [
      '使用地毯减少回声',
      '安装吸音墙板',
      '合理安排家电位置',
      '控制电视音量'
    ],
    color: $r('sys.color.confirm')
  },
  {
    scenarioType: '工作',
    scenarioName: '办公室',
    idealDb: 45,
    maxDb: 55,
    description: '办公和学习环境',
    improvementMeasures: [
      '使用隔断分隔空间',
      '安装吸音天花板',
      '使用降噪耳机',
      '合理安排会议时间'
    ],
    color: $r('sys.color.warning')
  },
  {
    scenarioType: '工作',
    scenarioName: '会议室',
    idealDb: 40,
    maxDb: 50,
    description: '会议和讨论环境',
    improvementMeasures: [
      '使用专业隔音材料',
      '安装声学面板',
      '使用定向麦克风',
      '控制参会人数'
    ],
    color: $r('sys.color.warning')
  },
  {
    scenarioType: '娱乐',
    scenarioName: '餐厅',
    idealDb: 55,
    maxDb: 65,
    description: '餐饮和社交环境',
    improvementMeasures: [
      '使用软质座椅和装饰',
      '安装背景音乐系统',
      '合理布局餐桌',
      '控制背景噪音'
    ],
    color: $r('sys.color.alert')
  },
  {
    scenarioType: '娱乐',
    scenarioName: '电影院',
    idealDb: 35,
    maxDb: 45,
    description: '观影和娱乐环境',
    improvementMeasures: [
      '专业声学设计',
      '使用吸音墙面材料',
      '合理扬声器布局',
      '控制观众噪音'
    ],
    color: $r('sys.color.alert')
  },
  {
    scenarioType: '交通',
    scenarioName: '地铁站',
    idealDb: 70,
    maxDb: 80,
    description: '公共交通环境',
    improvementMeasures: [
      '安装隔音屏障',
      '使用降噪轨道',
      '优化列车设计',
      '合理安排运营时间'
    ],
    color: $r('sys.color.font_primary')
  },
  {
    scenarioType: '交通',
    scenarioName: '高速公路',
    idealDb: 65,
    maxDb: 75,
    description: '道路交通环境',
    improvementMeasures: [
      '建设隔音墙',
      '使用降噪路面',
      '优化交通流量',
      '限制重型车辆'
    ],
    color: $r('sys.color.font_primary')
  }
];

// 场景类型
enum ScenarioType {
  RESIDENTIAL = '居住',
  WORK = '工作',
  ENTERTAINMENT = '娱乐',
  TRANSPORTATION = '交通'
}

// 构建场景建议卡片
@Builder
function buildScenarioAdviceCard(scenario: ScenarioData, ak: AppKeys, isCurrentScenario: boolean) {

  Column({ space: 8 }) {
    // 场景类型和名称
    Row() {
      Text(scenario.scenarioType)
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'))
        .padding(8)
        .backgroundColor($r('sys.color.background_secondary'))
        .borderRadius(6);

      Text(scenario.scenarioName)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .layoutWeight(1)
        .margin({ left: 8 });
    }
    .width('100%')

    // 分贝限值
    Row() {
      Column({ space: 4 }) {
        Text('理想值')
          .fontSize(11)
          .fontColor($r('sys.color.font_secondary'));

        Text(`${scenario.idealDb} dB`)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(DecibelService.getDecibelColor(scenario.idealDb));
      }
      .layoutWeight(1)

      Column({ space: 4 }) {
        Text('最大值')
          .fontSize(11)
          .fontColor($r('sys.color.font_secondary'));

        Text(`${scenario.maxDb} dB`)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(DecibelService.getDecibelColor(scenario.maxDb));
      }
      .layoutWeight(1)
    }
    .width('100%')

    // 场景描述
    Text(scenario.description)
      .fontSize(12)
      .fontColor($r('sys.color.font_secondary'))
      .width('100%')
      .textAlign(TextAlign.Start);

    // 改善措施
    Column({ space: 4 }) {
      Text('改善措施:')
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start);

      ForEach(scenario.improvementMeasures, (measure: string, index: number) => {
        Row({ space: 8 }) {
          Text('•')
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'));

          Text(measure)
            .fontSize(11)
            .fontColor($r('sys.color.font_secondary'))
            .layoutWeight(1);
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      })
    }
    .width('100%')
    .margin({ top: 8 })
  }
  .padding(12)
  .width('100%')
  .backgroundBlurStyle(isCurrentScenario ? BlurStyle.COMPONENT_REGULAR : BlurStyle.NONE)
  .backgroundColor(isCurrentScenario ? scenario.color : $r('sys.color.comp_background_primary'))
  .borderRadius(12)
  .alignItems(HorizontalAlign.Start)
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) })
    .combine(TransitionEffect.scale({ x: 0, y: 0 }))
    .combine(TransitionEffect.translate({ x: -150, y: 0 }).animation({ curve: curves.springMotion() })))
}

// 场景类型选择器类型定义
interface ScenarioTypeSelectorItem {
  type: ScenarioType;
  label: string;
}

// 获取最适合的场景
function getBestMatchingScenario(currentDb: number): ScenarioData | null {
  let bestMatch: ScenarioData | null = null;
  let minDiff = Infinity;

  for (const scenario of scenarioData) {
    const diff = Math.abs(currentDb - scenario.idealDb);
    if (diff < minDiff) {
      minDiff = diff;
      bestMatch = scenario;
    }
  }

  return bestMatch;
}

// 场景化建议组件
@ComponentV2
struct ScenarioAdviceComponent {
  @Local selectedScenarioType: ScenarioType = ScenarioType.RESIDENTIAL
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;

  aboutToAppear() {
  }

  // 获取过滤后的场景数据
  private getFilteredScenarios(): ScenarioData[] {
    return scenarioData.filter(scenario => scenario.scenarioType === this.selectedScenarioType)
  }

  // 获取场景类型标签
  private getScenarioTypeLabel(scenarioType: ScenarioType): string {
    switch (scenarioType) {
      case ScenarioType.RESIDENTIAL:
        return '居住'
      case ScenarioType.WORK:
        return '工作'
      case ScenarioType.ENTERTAINMENT:
        return '娱乐'
      case ScenarioType.TRANSPORTATION:
        return '交通'
    }
  }

  // 获取场景类型选择器项目
  private getScenarioTypeItems(): ScenarioTypeSelectorItem[] {
    return [
      { type: ScenarioType.RESIDENTIAL, label: '居住' },
      { type: ScenarioType.WORK, label: '工作' },
      { type: ScenarioType.ENTERTAINMENT, label: '娱乐' },
      { type: ScenarioType.TRANSPORTATION, label: '交通' }
    ]
  }

  // 场景类型选择器
  @Builder
  buildScenarioTypeSelector() {
    Row({ space: 8 }) {
      ForEach(this.getScenarioTypeItems(), (item: ScenarioTypeSelectorItem) => {
        Text(item.label)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.selectedScenarioType === item.type ? $r('sys.color.font_primary') : $r('sys.color.font_secondary'))
          .padding(12)
          .backgroundColor(this.selectedScenarioType === item.type ? $r('sys.color.comp_background_primary') : $r('sys.color.background_secondary'))
          .borderRadius(8)
          .onClick(() => {
            this.selectedScenarioType = item.type
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
        // 当前分贝和最佳匹配
        Column({ space: 8 }) {
          Row() {
            Text('当前分贝值:')
              .fontSize(14)
              .fontColor($r('sys.color.font_secondary'));

            Text(`${this.ak.uiDisplayState.displayDb} dB`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(DecibelService.getDecibelColor(this.ak.uiDisplayState.displayDb))
              .margin({ left: 8 });
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          if (getBestMatchingScenario(this.ak.uiDisplayState.displayDb)) {
            Row() {
              Text('最适合场景:')
                .fontSize(14)
                .fontColor($r('sys.color.font_secondary'));

              Text(getBestMatchingScenario(this.ak.uiDisplayState.displayDb)!.scenarioName)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(getBestMatchingScenario(this.ak.uiDisplayState.displayDb)!.color)
                .margin({ left: 8 });
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
          }
        }
        .width('100%')

        // 场景类型选择器
        this.buildScenarioTypeSelector()

        // 场景建议列表
        Text(`${this.getScenarioTypeLabel(this.selectedScenarioType)}场景建议`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start);

        ForEach(this.getFilteredScenarios(), (scenario: ScenarioData) => {
          buildScenarioAdviceCard(scenario, this.ak, scenario === getBestMatchingScenario(this.ak.uiDisplayState.displayDb))
        })
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
}

// 场景化建议对话框构建器
@Builder
export function ScenarioAdviceDialogBuilder(ak: AppKeys) {

  NavDestination() {
    ScenarioAdviceComponent()
  }
  .title({ main: '场景化建议', sub: '不同场景的噪音控制参考' })
  .padding(16)
  .backgroundColor($r('sys.color.background_secondary'))
}