import { DesignConstants } from "../constants/DesignConstants"
import display from '@ohos.display';
import common from '@ohos.app.ability.common';
import prompt from '@ohos.prompt';

// 功能链接项接口
interface FunctionLinkItem {
  id: string;
  icon: Resource;
  label: Resource;
  uri: string; // 系统设置页面的URI
}

// 布局模式枚举
enum LayoutMode {
  LARGE = 'large',    // 大屏：2x2网格
  MEDIUM = 'medium',  // 中屏：2x2网格（稍小）
  SMALL = 'small',    // 小屏：4x1垂直列表
  XSMALL = 'xsmall'   // 超小屏：4x1垂直列表（更紧凑）
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
    // 监听屏幕旋转和尺寸变化
    display.on('change', () => {
      this.updateScreenWidth();
    });
  }

  aboutToDisappear() {
    // 移除屏幕变化监听器
    display.off('change');
  }

  // 更新屏幕宽度（带缓存优化）
  private updateScreenWidth() {
    try {
      const displayClass = display.getDefaultDisplaySync();
      const newScreenWidth = displayClass.width;
      
      // 只有当屏幕宽度有显著变化时才更新布局模式
      if (Math.abs(newScreenWidth - this.cachedScreenWidth) > 20) { // 20px变化阈值
        this.screenWidth = newScreenWidth;
        this.cachedScreenWidth = newScreenWidth;
        this.updateLayoutMode(this.screenWidth);
      }
    } catch (error) {
      console.error('Failed to get display info:', error);
    }
  }

  // 更新布局模式（带滞后阈值防止频繁切换和缓存优化）
  private updateLayoutMode(width: number) {
    // 计算各布局模式的最小宽度要求
    const minWidthForLargeLayout = 400; // 大屏布局最小宽度
    const minWidthForMediumLayout = 300; // 中屏布局最小宽度
    const minWidthForSmallLayout = 200; // 小屏布局最小宽度
    
    // 添加滞后阈值（15px），防止在边界值附近频繁切换
    const hysteresis = 15;
    
    let newLayoutMode: LayoutMode;
    
    if (width >= minWidthForLargeLayout + hysteresis) {
      newLayoutMode = LayoutMode.LARGE;
    } else if (width >= minWidthForMediumLayout + hysteresis) {
      // 如果当前是大屏模式，需要更宽的阈值才能切换到中屏
      newLayoutMode = (this.cachedLayoutMode === LayoutMode.LARGE && width >= minWidthForLargeLayout - hysteresis) ?
        LayoutMode.LARGE : LayoutMode.MEDIUM;
    } else if (width >= minWidthForSmallLayout + hysteresis) {
      // 如果当前是中屏模式，需要更宽的阈值才能切换到小屏
      newLayoutMode = (this.cachedLayoutMode === LayoutMode.MEDIUM && width >= minWidthForMediumLayout - hysteresis) ?
        LayoutMode.MEDIUM : LayoutMode.SMALL;
    } else {
      // 如果当前是小屏模式，需要更窄的阈值才能切换到超小屏
      newLayoutMode = (this.cachedLayoutMode === LayoutMode.SMALL && width >= minWidthForSmallLayout - hysteresis) ?
        LayoutMode.SMALL : LayoutMode.XSMALL;
    }
    
    // 只有当布局模式真正改变时才更新
    if (newLayoutMode !== this.cachedLayoutMode) {
      this.layoutMode = newLayoutMode;
      this.cachedLayoutMode = newLayoutMode;
      console.debug(`[FunctionLinksPanel LayoutMode] Screen width: ${width}px, Mode: ${this.layoutMode}`);
    }
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