import { DesignConstants } from '../../constants/DesignConstants';
import { Debounce } from '../../utils/Debounce';

@ComponentV2
export struct PrivacyPolicyPage {
  @Event onPrev: () => void;
  @Event onAgree: () => void;

  @Local private privacyAgreed: boolean = false;
  @Local private contentOpacity: number = 0.8;
  @Local private headerOpacity: number = 0;
  @Local private titleOpacity: number = 0;
  @Local private permissionsOpacity: number = 0;
  @Local private checkboxOpacity: number = 0;
  @Local private buttonsOpacity: number = 0;
  @Local private checkboxShake: number = 0;
  @Local private checkboxScale: number = 1.0;
  @Local private textColor: Resource = $r('sys.color.font_emphasize');

  aboutToAppear(): void {
    this.startEntranceAnimation();
  }

  private startEntranceAnimation(): void {
    // 页面整体渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.contentOpacity = 1;
      });
    }, 100);

    // Header渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.headerOpacity = 1;
      });
    }, 300);

    // 标题渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.titleOpacity = 1;
      });
    }, 600);

    // 权限列表渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.permissionsOpacity = 1;
      });
    }, 900);

    // 复选框区域渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.checkboxOpacity = 1;
      });
    }, 1200);

    // 按钮区域渐显
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_MD,
        curve: Curve.EaseOut
      }, () => {
        this.buttonsOpacity = 1;
      });
    }, 1500);
  }

  private startShakeAnimation(): void {
    // 颜色变化 - 变为温和的橙色
    this.textColor = $r('sys.color.alert');
    
    // 缩放动画
    animateTo({
      duration: DesignConstants.ANIMATION_DURATION_XS,
      curve: Curve.EaseOut
    }, () => {
      this.checkboxScale = 1.05;
    });

    // 增强抖动动画 - 幅度增加到8像素，频率增加到4次
    animateTo({
      duration: DesignConstants.ANIMATION_DURATION_SM,
      curve: Curve.EaseInOut,
      iterations: 4,
      playMode: PlayMode.Alternate
    }, () => {
      this.checkboxShake = 8;
    });

    // 重置所有状态
    setTimeout(() => {
      animateTo({
        duration: DesignConstants.ANIMATION_DURATION_SM,
        curve: Curve.EaseOut
      }, () => {
        this.checkboxShake = 0;
        this.checkboxScale = 1.0;
        this.textColor = $r('sys.color.font_emphasize');
      });
    }, 400);
  }

  private handleAgreeClick(): void {
    if (!this.privacyAgreed) {
      // 未勾选复选框，触发抖动效果
      this.startShakeAnimation();
    } else {
      // 已勾选，执行同意操作
      this.onAgree();
    }
  }

  build() {
    Column({ space: 0 }) {
      // 可滚动内容区域
      Scroll() {
        Column({ space: DesignConstants.SPACING_LG }) {
          // 主要内容区域
          this.buildContent()
        }
        .width('100%')
        .padding({ bottom: DesignConstants.SPACING_LG })
      }
      .scrollBar(BarState.Auto)
      .scrollable(ScrollDirection.Vertical)
      .width('100%')
      .layoutWeight(1)

      // 操作按钮区域
      this.buildActionButtons()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_primary'))
    .opacity(this.contentOpacity)
  }


  // 构建权限说明列表 - 集成隐私政策对话框的设计，添加动画效果
  @Builder
  private buildPermissionList() {
    Column({ space: DesignConstants.SPACING_SM }) {
      // 麦克风权限
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_mic'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.font_primary'))

        Text($r('app.string.privacy_policy_microphone_permission'))
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
      }
      .width('100%')

      // 位置权限
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_location'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.font_primary'))

        Text($r('app.string.privacy_policy_location_permission'))
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
      }
      .width('100%')

      // 后台运行权限
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_power_on'))
          .width(DesignConstants.ICON_SIZE_MD)
          .height(DesignConstants.ICON_SIZE_MD)
          .fillColor($r('sys.color.font_primary'))

        Text($r('app.string.privacy_policy_background_permission'))
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .opacity(this.permissionsOpacity)
  }

  // 构建内容区域 - 专注于隐私政策内容，添加动画效果和APP图标
  @Builder
  private buildContent() {
    Column({ space: DesignConstants.SPACING_LG }) {
      // APP图标和名称 - 利用顶部空白区域
      Column({ space: DesignConstants.SPACING_MD }) {
        Image($r('app.media.app_icon_fore'))
          .width(80)
          .height(80)
          .backgroundColor('#e5000000')
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)

        Text($r('app.string.EntryAbility_label'))
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_emphasize'))
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')
      .padding({ top: DesignConstants.SPACING_XL, bottom: DesignConstants.SPACING_LG })
      .opacity(this.titleOpacity)

      // 隐私政策标题
      Text('隐私保护')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_emphasize'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .opacity(this.titleOpacity)

      // 隐私政策描述
      Text('我们重视您的隐私安全，请了解我们的数据使用政策')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .lineHeight(20)
        .opacity(this.titleOpacity)

      // 权限说明
      Text('应用权限说明')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)
        .opacity(this.permissionsOpacity)

      // 权限列表
      this.buildPermissionList()

      // 隐私政策链接
      this.buildPolicyLink()
    }
    .width('100%')
    .padding({ left: DesignConstants.SPACING_LG, right: DesignConstants.SPACING_LG })
  }

  // 构建隐私政策链接部分 - 简化版本，添加动画效果
  @Builder
  private buildPolicyLink() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 隐私政策链接
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('请阅读并同意')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))

        Hyperlink($r('app.string.privacy_policy_link'),
          $r('app.string.privacy_policy_link_text'))
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width('100%')
    }
    .width('100%')
    .opacity(this.permissionsOpacity)
  }


  // 构建操作按钮区域 - 优化布局和交互
  @Builder
  private buildActionButtons() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 复选框和同意文本 - 增强抖动效果
      Row({ space: DesignConstants.SPACING_MD }) {
        Checkbox({ name: 'privacyAgreement', group: 'privacy' })
          .select(this.privacyAgreed)
          .onChange((value: boolean) => {
            this.privacyAgreed = value;
          })
          .translate({ x: this.checkboxShake })
          .scale({ x: this.checkboxScale, y: this.checkboxScale })

        Text('我已阅读并同意隐私政策')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor(this.textColor)
          .onClick(() => {
            Debounce.click(() => {
              this.privacyAgreed = !this.privacyAgreed;
            });
          })
          .translate({ x: this.checkboxShake })
          .scale({ x: this.checkboxScale, y: this.checkboxScale })
      }
      .opacity(this.checkboxOpacity)

      // 同意按钮 - 始终可用，但点击时检查状态
      Button('同意并继续', { type: ButtonType.Capsule })
        .width('100%')
        .height(56)
        .backgroundColor($r('sys.color.interactive_active'))
        .fontColor($r('sys.color.font_on_primary'))
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .onClick(() => {
          Debounce.click(() => {
            this.handleAgreeClick();
          });
        })
        .opacity(this.buttonsOpacity)

      // 不同意按钮 - 使用更友好的文案
      Button('暂不使用', { type: ButtonType.Normal })
        .width('100%')
        .height(48)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .fontColor($r('sys.color.font_primary'))
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .onClick(() => {
          Debounce.click(() => {
            this.onPrev();
          });
        })
        .opacity(this.buttonsOpacity)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_LG)
  }
}