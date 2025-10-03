import { PreferenceKeys } from '../../models/PreferenceKeys';
import { PersistenceV2 } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';

/**
 * 显示模式设置组件
 * 提供自动、浅色、深色三种显示模式选择
 */
@ComponentV2
export struct DisplayModeComponent {
  @Local selectedDisplayMode: string = ''
  @Local hoveredDisplayMode: string | null = null
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!

  aboutToAppear() {
    this.selectedDisplayMode = this.pk.display_mode;
  }

  // 获取显示模式索引
  getDisplayModeIndex(displayMode: string): number {
    switch (displayMode) {
      case 'default':
        return 0;
      case 'light':
        return 1;
      case 'dark':
        return 2;
      default:
        return 0;
    }
  }

  // 获取显示模式文本
  getDisplayModeText(displayMode: string): string {
    switch (displayMode) {
      case 'default':
        return "自动";
      case 'light':
        return "浅色";
      case 'dark':
        return "深色";
      default:
        return "自动";
    }
  }

  // 根据索引获取显示模式
  getDisplayMode(index: number): string {
    switch (index) {
      case 0:
        return 'default';
      case 1:
        return 'light';
      case 2:
        return 'dark';
      default:
        return 'default';
    }
  }

  // 获取显示模式图标
  private getDisplayModeIcon(displayMode: string): Resource {
    switch (displayMode) {
      case 'default':
        return $r('sys.media.ohos_ic_public_device_smartscreen');
      case 'light':
        return $r('sys.media.lamp_ceiling_light');
      case 'dark':
        return $r('sys.media.moon_z_fill');
      default:
        return $r('sys.media.ohos_ic_public_device_smartscreen');
    }
  }

  // 处理显示模式选择
  private handleDisplayModeSelect(displayMode: string) {
    this.selectedDisplayMode = displayMode;
    this.pk.display_mode = displayMode;
  }

  // 构建显示模式选项卡
  @Builder
  private buildDisplayModeTabs() {
    // 选项卡容器
    Row({ space: 2 }) {
      ForEach(['default', 'light', 'dark'], (displayMode: string) => {
        // 选项卡内容
        Row({ space: 2 }) {
          // 显示模式图标（更小的图标）
          Image(this.getDisplayModeIcon(displayMode))
            .width(14)
            .height(14)
            .fillColor(this.selectedDisplayMode === displayMode ?
            $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))

          // 显示模式名称（更小的字体）
          Text(this.getDisplayModeText(displayMode))
            .fontSize(12)
            .fontWeight(this.selectedDisplayMode === displayMode ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(this.selectedDisplayMode === displayMode ?
            $r('sys.color.font_on_primary') : $r('sys.color.font_primary'))
        }
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .height(32)
        .padding({ left: 8, right: 8 })
        .backgroundColor(this.selectedDisplayMode === displayMode ?
        $r('sys.color.interactive_active') : $r('sys.color.comp_background_primary'))
        .borderRadius(16)
        .onClick(() => {
          this.handleDisplayModeSelect(displayMode);
        })
        .onHover((isHover: boolean) => {
          if (isHover) {
            this.hoveredDisplayMode = displayMode;
          } else {
            this.hoveredDisplayMode = null;
          }
        })
      })
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .height(32)
    .padding(2)
  }

  build() {
    Column({ space: 8 }) {
      Row() {
        // 左侧：标题区域
        Row({ space: 8 }) {
          Image($r('sys.media.ohos_ic_public_device_smartscreen'))
            .width(24)
            .height(24)
            .fillColor($r('sys.color.font_primary'))
          Text('色彩')
            .fontSize(16)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Medium)
        }.layoutWeight(1)

        // 右侧：按钮区域
        this.buildDisplayModeTabs()
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(16)
    .padding(16)
  }
}