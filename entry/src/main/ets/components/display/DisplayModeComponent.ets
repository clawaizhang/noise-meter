import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';

/**
 * 显示模式卡片参数接口
 */
interface DisplayModeCardParams {
  displayMode: string;
  isSelected: boolean;
  isHovered: boolean;
}

@Builder
export function DisplayModeCardBuilder(){
  DisplayModeComponent()
}

/**
 * 显示模式设置组件
 * 提供跟随系统、浅色主题、深色主题三种显示模式选择
 */
@ComponentV2
export struct DisplayModeComponent {
  @Local selectedDisplayMode: string = ''
  @Local hoveredDisplayMode: string | null = null
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!

  aboutToAppear() {
    this.selectedDisplayMode = this.pk.display_mode;
  }

  // 获取显示模式描述文本
  private get displayModeDescription(): Resource {
    switch (this.selectedDisplayMode) {
      case 'default':
        return $r('app.string.display_mode_auto_desc');
      case 'light':
        return $r('app.string.display_mode_light_desc');
      case 'dark':
        return $r('app.string.display_mode_dark_desc');
      default:
        return $r('app.string.display_mode_auto_desc');
    }
  }

  // 获取显示模式主标签
  private getDisplayModePrimaryText(displayMode: string): Resource {
    switch (displayMode) {
      case 'default':
        return $r('app.string.display_mode_auto_primary');
      case 'light':
        return $r('app.string.display_mode_light_primary');
      case 'dark':
        return $r('app.string.display_mode_dark_primary');
      default:
        return $r('app.string.display_mode_auto_primary');
    }
  }

  // 获取显示模式副标签
  private getDisplayModeSecondaryText(displayMode: string): Resource {
    switch (displayMode) {
      case 'default':
        return $r('app.string.display_mode_auto_secondary');
      case 'light':
        return $r('app.string.display_mode_light_secondary');
      case 'dark':
        return $r('app.string.display_mode_dark_secondary');
      default:
        return $r('app.string.display_mode_auto_secondary');
    }
  }

  // 获取当前模式显示文本（用于列表项显示）
  private getCurrentModeDisplayText(): Resource {
    switch (this.selectedDisplayMode) {
      case 'default':
        return $r('app.string.display_mode_auto_primary');
      case 'light':
        return $r('app.string.display_mode_light_primary');
      case 'dark':
        return $r('app.string.display_mode_dark_primary');
      default:
        return $r('app.string.display_mode_auto_primary');
    }
  }

  // 获取显示模式图标
  private getDisplayModeIcon(displayMode: string): Resource {
    switch (displayMode) {
      case 'default':
        return $r('app.media.ic_display');
      case 'light':
        return $r('app.media.ic_sun');
      case 'dark':
        return $r('app.media.ic_moon');
      default:
        return $r('app.media.ic_display');
    }
  }

  // 处理显示模式选择
  private handleDisplayModeSelect(displayMode: string) {
    this.selectedDisplayMode = displayMode;
    this.pk.display_mode = displayMode;
  }

  // 构建显示模式卡片
  @Builder
  private buildDisplayModeCard(params: DisplayModeCardParams) {
    Column({ space: 8 }) {
      // 图标区域
      Image(this.getDisplayModeIcon(params.displayMode))
        .width(24)
        .height(24)
        .fillColor(params.isSelected ? $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))

      // 文本区域
      Column({ space: 2 }) {
        // 主标签
        Text(this.getDisplayModePrimaryText(params.displayMode))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(params.isSelected ? $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))
          .textAlign(TextAlign.Center)

        // 副标签
        Text(this.getDisplayModeSecondaryText(params.displayMode))
          .fontSize(12)
          .fontColor(params.isSelected ? $r('sys.color.font_on_primary') : $r('sys.color.font_secondary'))
          .textAlign(TextAlign.Center)
      }
    }
    .width(80)
    .height(80)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(params.isSelected ? $r('sys.color.interactive_active') : $r('sys.color.comp_background_primary'))
    .border({
      width: params.isSelected ? 2 : 1,
      color: params.isSelected ? $r('sys.color.interactive_active') : $r('sys.color.comp_background_primary')
    })
    .borderRadius(16)
    .shadow(params.isHovered ? {
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    } : null)
    .scale({ x: params.isHovered ? 1.05 : 1, y: params.isHovered ? 1.05 : 1 })
    .animation({
      duration: 200,
      curve: Curve.EaseOut
    })
    .onClick(() => {
      Throttle.click(() => {
        this.handleDisplayModeSelect(params.displayMode);
      });
    })
    .onHover((isHover: boolean) => {
      if (isHover) {
        this.hoveredDisplayMode = params.displayMode;
      } else {
        this.hoveredDisplayMode = null;
      }
    })
  }

  // 构建显示模式选择区域
  @Builder
  private buildDisplayModeSelector() {
    Row({ space: 12 }) {
      ForEach(['default', 'light', 'dark'], (displayMode: string) => {
        this.buildDisplayModeCard({
          displayMode: displayMode,
          isSelected: this.selectedDisplayMode === displayMode,
          isHovered: this.hoveredDisplayMode === displayMode
        })
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
    .padding({ top: 8, bottom: 8 })
  }

  build() {
    Column({ space: 16 }) {
      // 标题区域
      Row({ space: 8 }) {
        Image($r('app.media.ic_display'))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.brand'))
        Text($r('app.string.display_mode_title'))
          .fontSize(16)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Start)

      // 模式选择区域
      this.buildDisplayModeSelector()

      // 描述文本区域
      Text(this.displayModeDescription)
        .fontSize(12)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
        .textAlign(TextAlign.Start)
        .lineHeight(16)
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(16)
    .padding({ top: 16, bottom: 16, left: 16, right: 16 })
    .width('92%')
  }
}