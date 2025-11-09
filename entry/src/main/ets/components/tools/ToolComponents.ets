import { ToolConfig, ToolPriority } from './ToolsContent';
import { DesignConstants } from '../../constants/DesignConstants';

// 优先级标签组件
@ComponentV2
export struct PriorityLabel {
  @Param @Require priority: ToolPriority;
  
  build() {
    if (this.priority === ToolPriority.ADVANCED) {
      Text('PRO')
        .fontSize(DesignConstants.FONT_SIZE_XXS)
        .fontColor($r('app.color.background_secondary'))
        .backgroundColor($r('app.color.warning'))
        .borderRadius(DesignConstants.BORDER_RADIUS_XS)
        .padding({ left: 2, right: 2, top: 1, bottom: 1 })
        .margin({ top: 2 })
    } else if (this.priority === ToolPriority.ESSENTIAL) {
      Text('核心')
        .fontSize(DesignConstants.FONT_SIZE_XXS)
        .fontColor($r('app.color.background_secondary'))
        .backgroundColor($r('app.color.confirm'))
        .borderRadius(DesignConstants.BORDER_RADIUS_XS)
        .padding({ left: 2, right: 2, top: 1, bottom: 1 })
        .margin({ top: 2 })
    }
  }
}

// 学习更多按钮组件
@ComponentV2
export struct LearnMoreButton {
  @Event learnMore?: () => void;
  
  build() {
    if (this.learnMore) {
      Text('了解更多')
        .fontSize(DesignConstants.FONT_SIZE_XXS)
        .fontColor($r('app.color.brand'))
        .padding({ left: 4, right: 4, top: 2, bottom: 2 })
        .borderRadius(DesignConstants.BORDER_RADIUS_XS)
        .backgroundColor($r('app.color.comp_background_secondary'))
        .onClick(() => {
          this.learnMore?.();
        })
    }
  }
}

// 功能提示组件
@ComponentV2
export struct UsageHint {
  @Param @Require usageHint?: string;
  @Param @Require showHint: boolean = false;
  
  build() {
    if (this.usageHint && this.showHint) {
      Text(`💡 ${this.usageHint}`)
        .fontSize(DesignConstants.FONT_SIZE_XXS)
        .fontColor($r('app.color.font_secondary'))
        .width('100%')
        .margin({ top: 2 })
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_MD,
          curve: Curve.EaseInOut
        })
    }
  }
}

// 工具卡片图标区域组件
@ComponentV2
export struct ToolIcon {
  @Param @Require icon: Resource;
  @Param isHovered: boolean = false;
  @Param isPressed: boolean = false;
  @Param priority: ToolPriority = ToolPriority.RECOMMENDED;
  
  build() {
    Column({ space: DesignConstants.SPACING_XS }) {
      Image(this.icon)
        .width(24)
        .height(24)
        .fillColor(this.isHovered ? $r('app.color.brand') : $r('app.color.icon_primary'))
        .scale({ x: this.isPressed ? 0.9 : 1.0, y: this.isPressed ? 0.9 : 1.0 })
        .animation({
          duration: DesignConstants.ANIMATION_DURATION_XS,
          curve: Curve.EaseInOut
        })
      
      PriorityLabel({
        priority: this.priority
      })
    }
    .alignItems(HorizontalAlign.Center)
  }
}

// 工具状态显示组件
@ComponentV2
export struct ToolStatus {
  @Param @Require status?: string;
  @Require @Param statusColor?: Resource;
  
  build() {
    if (this.status && this.statusColor) {
      Text(this.status)
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.statusColor)
    }
  }
}

// 创建PriorityLabel组件的便捷函数
export function createPriorityLabel(priority: ToolPriority): PriorityLabel {
  const label = new PriorityLabel({ priority: priority});
  return label;
}

// 创建LearnMoreButton组件的便捷函数
export function createLearnMoreButton(learnMore?: () => void): LearnMoreButton {
  const button = new LearnMoreButton();
  // 注意：在ArkTS中，@Prop装饰的属性是只读的
  // 不能在运行时赋值，需要在创建组件时通过参数传递
  return button;
}

// 创建UsageHint组件的便捷函数
export function createUsageHint(usageHint?: string, showHint: boolean = false): UsageHint {
  const hint = new UsageHint();
  // 注意：在ArkTS中，@Prop装饰的属性是只读的
  // 不能在运行时赋值，需要在创建组件时通过参数传递
  return hint;
}

// 创建ToolIcon组件的便捷函数
export function createToolIcon(icon: Resource, isHovered: boolean = false, isPressed: boolean = false, priority: ToolPriority = ToolPriority.RECOMMENDED): ToolIcon {
  const toolIcon = new ToolIcon();
  // 注意：在ArkTS中，@Prop装饰的属性是只读的
  // 不能在运行时赋值，需要在创建组件时通过参数传递
  return toolIcon;
}

// 创建ToolStatus组件的便捷函数
export function createToolStatus(status?: string, statusColor?: Resource): ToolStatus {
  const toolStatus = new ToolStatus();
  // 注意：在ArkTS中，@Param和@Require装饰的属性是只读的
  // 不能在运行时赋值，需要在创建组件时通过参数传递
  return toolStatus;
}