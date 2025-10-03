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

  build() {
    Column({ space: 8 }) {
      Row() {
        Row({ space: 8 }) {
          Image($r('sys.media.ohos_ic_public_device_smartscreen'))
            .width(DesignConstants.ICON_SIZE_MD)
            .height(DesignConstants.ICON_SIZE_MD)
            .fillColor($r('sys.color.font_primary'))
          Text('显示模式')
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Medium)
        }.layoutWeight(1)
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Start)

      // 选项卡容器
      Row({ space: 0 }) {
        ForEach(['default', 'light', 'dark'], (displayMode: string) => {
          // 选项卡内容
          Row({ space: DesignConstants.SPACING_SM }) {
            // 显示模式图标
            Image(this.getDisplayModeIcon(displayMode))
              .width(DesignConstants.ICON_SIZE_SM)
              .height(DesignConstants.ICON_SIZE_SM)
              .fillColor(this.selectedDisplayMode === displayMode ?
              $r('sys.color.font_on_primary') :
                (this.hoveredDisplayMode === displayMode ?
                $r('sys.color.interactive_active') :
                $r('sys.color.font_primary')))

            // 显示模式名称
            Text(this.getDisplayModeText(displayMode))
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontWeight(this.selectedDisplayMode === displayMode ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(this.selectedDisplayMode === displayMode ?
              $r('sys.color.font_on_primary') :
                (this.hoveredDisplayMode === displayMode ?
                $r('sys.color.interactive_active') :
                $r('sys.color.font_primary')))
          }
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
          .height(56)
          .backgroundColor(this.selectedDisplayMode === displayMode ?
          $r('sys.color.interactive_active') :
            (this.hoveredDisplayMode === displayMode ?
            $r('sys.color.comp_background_secondary') :
            $r('sys.color.comp_background_primary')))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .padding(DesignConstants.SPACING_MD)
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
      .margin(16)
      .borderRadius(16)
      .height(56)
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(16)
    .padding(16)
  }
}