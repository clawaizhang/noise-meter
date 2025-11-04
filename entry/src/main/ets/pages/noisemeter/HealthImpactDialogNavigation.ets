import { curves } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';
import { DecibelService } from '../../services/DecibelService';

// 健康影响数据接口
interface HealthImpactData {
  dbRange: string;
  safeExposureTime: string;
  riskLevel: string;
  protectionAdvice: string;
  color: Resource;
}

// 健康影响数据
const healthImpactData: HealthImpactData[] = [
  {
    dbRange: '40-50 dB',
    safeExposureTime: '无限制',
    riskLevel: '无风险',
    protectionAdvice: '环境舒适，无需防护',
    color: $r('sys.color.confirm')
  },
  {
    dbRange: '50-60 dB',
    safeExposureTime: '无限制',
    riskLevel: '极低风险',
    protectionAdvice: '正常环境，无需特殊防护',
    color: $r('sys.color.confirm')
  },
  {
    dbRange: '60-70 dB',
    safeExposureTime: '无限制',
    riskLevel: '低风险',
    protectionAdvice: '长期暴露可能引起轻微不适',
    color: $r('sys.color.warning')
  },
  {
    dbRange: '70-80 dB',
    safeExposureTime: '无限制',
    riskLevel: '中等风险',
    protectionAdvice: '可能影响睡眠和注意力',
    color: $r('sys.color.warning')
  },
  {
    dbRange: '80-85 dB',
    safeExposureTime: '8小时',
    riskLevel: '较高风险',
    protectionAdvice: '建议佩戴听力保护设备',
    color: $r('sys.color.alert')
  },
  {
    dbRange: '85-90 dB',
    safeExposureTime: '4小时',
    riskLevel: '高风险',
    protectionAdvice: '必须佩戴听力保护设备',
    color: $r('sys.color.alert')
  },
  {
    dbRange: '90-95 dB',
    safeExposureTime: '2小时',
    riskLevel: '极高风险',
    protectionAdvice: '立即佩戴听力保护设备',
    color: $r('sys.color.alert')
  },
  {
    dbRange: '95-100 dB',
    safeExposureTime: '1小时',
    riskLevel: '严重风险',
    protectionAdvice: '立即离开或佩戴专业防护设备',
    color: $r('sys.color.alert')
  },
  {
    dbRange: '100+ dB',
    safeExposureTime: '立即离开',
    riskLevel: '极度危险',
    protectionAdvice: '立即离开环境，可能造成永久性听力损伤',
    color: $r('sys.color.alert')
  }
];

// 构建健康影响卡片
@Builder
function buildHealthImpactCard(data: HealthImpactData, ak: AppKeys, isCurrentRange: boolean) {
  Column({ space: 8 }) {
    // 分贝范围和风险等级
    Row() {
      Text(data.dbRange)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .layoutWeight(1);

      // 状态标签 - 只在当前状态时显示
      if (isCurrentRange) {
        Text(data.riskLevel)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(data.color)
          .borderRadius(8)
          .opacity(0.9)
      } else {
        Text(data.riskLevel)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(data.color);
      }
    }
    .width('100%')

    // 安全暴露时间
    Row() {
      Text('安全暴露时间:')
        .fontSize(14)
        .fontColor($r('sys.color.font_secondary'));

      Text(data.safeExposureTime)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .margin({ left: 8 });
    }
    .width('100%')

    // 防护建议
    Text(data.protectionAdvice)
      .fontSize(13)
      .fontColor($r('sys.color.font_secondary'))
      .width('100%')
      .textAlign(TextAlign.Start);
  }
  .padding(16)
  .width('100%')
  .backgroundBlurStyle(isCurrentRange ? BlurStyle.COMPONENT_REGULAR : BlurStyle.NONE)
  .backgroundColor($r('sys.color.comp_background_primary'))
  .borderRadius(16)
  .alignItems(HorizontalAlign.Start)
  .transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) })
    .combine(TransitionEffect.scale({ x: 0, y: 0 }))
    .combine(TransitionEffect.translate({ x: -150, y: 0 }).animation({ curve: curves.springMotion() })))
}

// 获取当前分贝范围
function getCurrentDbRange(currentDb: number): HealthImpactData | null {
  for (const data of healthImpactData) {
    const range = data.dbRange;
    if (range.includes('+')) {
      const minDb = parseInt(range.split('+')[0]);
      if (currentDb >= minDb) return data;
    } else {
      const minStr = range.split('-')[0];
      const maxStr = range.split('-')[1];
      const minDb = parseInt(minStr);
      const maxDb = parseInt(maxStr.split(' ')[0]);
      if (currentDb >= minDb && currentDb <= maxDb) return data;
    }
  }
  return null;
}

// 健康影响对话框构建器
@Builder
export function HealthImpactDialogBuilder(ak: AppKeys) {

  NavDestination() {
    Scroll() {
      Column({ space: 12 }) {
        // 当前状态显示
        if (getCurrentDbRange(ak.uiDisplayState.displayDb)) {
          Column({ space: 8 }) {
            Text('当前状态')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
              .alignSelf(ItemAlign.Start);

            buildHealthImpactCard(getCurrentDbRange(ak.uiDisplayState.displayDb)!, ak, true)
          }
          .width('100%')
          .padding({ bottom: 16 })
        }

        // 分隔线
        Divider()
          .strokeWidth(1)
          .color($r('sys.color.comp_divider'))
          .margin({ bottom: 16 })

        // 所有健康影响等级
        Text('健康影响参考标准')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start);

        ForEach(healthImpactData, (data: HealthImpactData) => {
          buildHealthImpactCard(data, ak, data === getCurrentDbRange(ak.uiDisplayState.displayDb))
        })
      }
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
  .title({ main: '健康影响参考', sub: '基于OSHA标准的职业健康安全参考' })
  .padding(16)
  .backgroundColor($r('sys.color.background_secondary'))
}