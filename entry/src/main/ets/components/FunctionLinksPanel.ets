import { DesignConstants } from "../constants/DesignConstants"
import display from '@ohos.display';
import common from '@ohos.app.ability.common';
import prompt from '@ohos.prompt';
import { ResponsiveLayout, Breakpoint, LayoutMode, type WindowChangeListener } from "../utils/ResponsiveLayout"

// 功能链接项接口
interface FunctionLinkItem {
  id: string;
  icon: Resource;
  label: Resource;
  uri: string; // 系统设置页面的URI
}

@ComponentV2
export struct FunctionLinksPanel {
  @Local screenWidth: number = 0;
  @Local layoutMode: LayoutMode = LayoutMode.LARGE;
  @Local cachedLayoutMode: LayoutMode = LayoutMode.LARGE;
  @Local cachedScreenWidth: number = 0;
  @Local lastLayoutUpdateTime: number = 0;

  // 功能链接数据
  private functionLinks: FunctionLinkItem[] = [
    {
      id: 'data_usage',
      icon: $r('app.media.ic_stats'),
      label: $r('app.string.data_usage_label'),
      uri: 'mobile_network_entry' // 流量管理
    },
    {
      id: 'harassment_block',
      icon: $r('app.media.ic_security'),
      label: $r('app.string.harassment_block_label'),
      uri: 'privacy_settings' // 骚扰拦截（隐私设置）
    },
    {
      id: 'storage_management',
      icon: $r('app.media.ic_storage'),
      label: $r('app.string.storage_management_label'),
      uri: 'storage_settings' // 存储管理
    },
    {
      id: 'app_management',
      icon: $r('app.media.ic_settings'),
      label: $r('app.string.app_management_label'),
      uri: 'application_settings' // 应用管理
    }
  ];

  aboutToAppear() {
    this.updateScreenWidth();
    // 使用统一的ResponsiveLayout监听器
    ResponsiveLayout.getInstance().addChangeListener(this.layoutChangeCallback);
  }

  aboutToDisappear() {
    // 移除ResponsiveLayout监听器
    ResponsiveLayout.getInstance().removeChangeListener(this.layoutChangeCallback);
  }

  // 布局变化回调函数
  private layoutChangeCallback: WindowChangeListener = (width: number, height: number, breakpoint: Breakpoint, layoutMode: LayoutMode) => {
    this.layoutMode = layoutMode;
    this.cachedLayoutMode = layoutMode;
    console.debug(`[FunctionLinksPanel] Layout mode changed to: ${layoutMode}`);
  }

  // 更新屏幕宽度（初始化时使用）
  private updateScreenWidth() {
    try {
      const displayClass = display.getDefaultDisplaySync();
      const newScreenWidth = displayClass.width;
      this.screenWidth = newScreenWidth;
      this.cachedScreenWidth = newScreenWidth;
      
      // 使用ResponsiveLayout的统一布局模式
      const screenInfo = ResponsiveLayout.getInstance().getCurrentScreenInfo();
      this.layoutMode = screenInfo.layoutMode;
      this.cachedLayoutMode = screenInfo.layoutMode;
    } catch (error) {
      console.error('Failed to get display info:', error);
    }
  }

  // 更新布局模式
  private updateLayoutMode(width: number): void {
    const breakpoint = ResponsiveLayout.getInstance().getBreakpoint(width);
    const layoutMode = ResponsiveLayout.getInstance().getLayoutMode(breakpoint);
    this.layoutMode = layoutMode;
    this.cachedLayoutMode = layoutMode;
  }

  // 跳转到系统设置页面
  private navigateToSystemSettings(uri: string) {
    try {
      // 获取 UIAbilityContext
      const context = getContext() as common.UIAbilityContext;
      
      context.startAbility({
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility',
        uri: uri
      }).then(() => {
        console.debug(`Successfully navigated to system settings: ${uri}`);
      }).catch((error: Error) => {
        console.error(`Failed to navigate to ${uri}:`, error);
        // 如果系统设置页面不存在，显示提示
        prompt.showToast({
          message: $r('app.string.system_settings_unavailable').toString(),
          duration: 2000
        });
      });
    } catch (error) {
      console.error('Navigation error:', error);
      prompt.showToast({
        message: $r('app.string.system_settings_unavailable').toString(),
        duration: 2000
      });
    }
  }

  @Builder
  buildResponsiveLayout() {
    if (this.layoutMode === LayoutMode.XSMALL) {
      this.buildXSmallLayout();
    } else if (this.layoutMode === LayoutMode.SMALL) {
      this.buildSmallLayout();
    } else if (this.layoutMode === LayoutMode.MEDIUM) {
      this.buildMediumLayout();
    } else {
      this.buildLargeLayout();
    }
  }

  @Builder
  buildLargeLayout() {
    // 大屏布局：2x2网格
    Grid() {
      ForEach(this.functionLinks, (item: FunctionLinkItem) => {
        GridItem() {
          this.buildFunctionLinkItem(item)
        }
        .width('100%')
        .height('100%')
      })
    }
    .columnsTemplate('1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .columnsGap(DesignConstants.SPACING_MD)
    .rowsGap(DesignConstants.SPACING_MD)
    .width('100%')
    .height(220)
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow(DesignConstants.SHADOW_SM)
  }

  @Builder
  buildMediumLayout() {
    // 中屏布局：2x2网格（稍小）
    Grid() {
      ForEach(this.functionLinks, (item: FunctionLinkItem) => {
        GridItem() {
          this.buildFunctionLinkItem(item)
        }
        .width('100%')
        .height('100%')
      })
    }
    .columnsTemplate('1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .columnsGap(DesignConstants.SPACING_SM)
    .rowsGap(DesignConstants.SPACING_SM)
    .width('100%')
    .height(200)
    .padding(DesignConstants.SPACING_SM)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .shadow(DesignConstants.SHADOW_SM)
  }

  @Builder
  buildSmallLayout() {
    // 小屏布局：4x1垂直列表
    Column() {
      ForEach(this.functionLinks, (item: FunctionLinkItem) => {
        Column() {
          this.buildFunctionLinkItem(item)
        }
        .margin({ bottom: DesignConstants.SPACING_SM })
      })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_SM)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .shadow(DesignConstants.SHADOW_SM)
  }

  @Builder
  buildXSmallLayout() {
    // 超小屏布局：4x1垂直列表（更紧凑）
    Column() {
      ForEach(this.functionLinks, (item: FunctionLinkItem) => {
        Column() {
          this.buildFunctionLinkItem(item)
        }
        .margin({ bottom: DesignConstants.SPACING_XS })
      })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_XS)
    .backgroundColor($r('app.color.background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_SM)
    .shadow(DesignConstants.SHADOW_SM)
  }

  @Builder
  buildFunctionLinkItem(item: FunctionLinkItem) {
    Button({ type: ButtonType.Normal }) {
      Column() {
        Image(item.icon)
          .width(DesignConstants.ICON_SIZE_LG)
          .height(DesignConstants.ICON_SIZE_LG)
          .margin({ bottom: DesignConstants.SPACING_XS })
        
        Text(item.label.toString())
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .onClick(() => {
      this.navigateToSystemSettings(item.uri)
    })
    .backgroundColor(Color.Transparent)
    .width(this.getButtonWidth())
    .height(this.getButtonHeight())
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  // 根据布局模式获取按钮宽度
  private getButtonWidth(): number | string {
    switch (this.layoutMode) {
      case LayoutMode.LARGE:
      case LayoutMode.MEDIUM:
        return '100%';
      case LayoutMode.SMALL:
      case LayoutMode.XSMALL:
        return '100%';
      default:
        return '100%';
    }
  }

  // 根据布局模式获取按钮高度
  private getButtonHeight(): number {
    switch (this.layoutMode) {
      case LayoutMode.LARGE:
        return 80;
      case LayoutMode.MEDIUM:
        return 70;
      case LayoutMode.SMALL:
        return 60;
      case LayoutMode.XSMALL:
        return 50;
      default:
        return 80;
    }
  }

  build() {
    Column() {
      this.buildResponsiveLayout()
    }
    .onAreaChange((oldValue: Area, newValue: Area) => {
      // 添加防抖机制，避免频繁触发布局更新
      const currentTime = Date.now();
      if (currentTime - this.lastLayoutUpdateTime > 300) { // 300ms防抖
        this.updateLayoutMode(Number(newValue.width));
        this.lastLayoutUpdateTime = currentTime;
      }
    })
  }
}