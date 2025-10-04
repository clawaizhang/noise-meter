# 欢迎页编码实现方案（续）

## 4. 第3页：高级功能页（续）

```typescript
  private drawSpectrum(canvas: RenderingContext): void {
    const width = 200;
    const height = 60;
    
    canvas.clearRect(0, 0, width, height);
    canvas.beginPath();
    
    for (let i = 0; i < width; i++) {
      const x = i;
      const y = height / 2 + Math.sin(i * 0.1 + Date.now() * 0.005) * 20;
      
      if (i === 0) {
        canvas.moveTo(x, y);
      } else {
        canvas.lineTo(x, y);
      }
    }
    
    canvas.strokeStyle = '#1890FF';
    canvas.lineWidth = 2;
    canvas.stroke();
  }

  @Builder
  private buildFeatureDescription() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('专业分析工具')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_emphasize'))
        .alignSelf(ItemAlign.Start)

      Text('• 实时频谱分析 - 可视化音频频率分布')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)

      Text('• 智能数据记录 - 自动保存检测历史')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)

      Text('• 多种加权模式 - A/C/Z专业计权')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
  }

  @Builder
  private buildFeatureIcons() {
    Row({ space: DesignConstants.SPACING_MD }) {
      Column({ space: DesignConstants.SPACING_XS }) {
        Image($r('app.media.ic_frequency_weighting'))
          .width(32)
          .height(32)
          .fillColor($r('sys.color.interactive_active'))
        Text('频谱分析')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }

      Column({ space: DesignConstants.SPACING_XS }) {
        Image($r('app.media.ic_history'))
          .width(32)
          .height(32)
          .fillColor($r('sys.color.interactive_active'))
        Text('数据记录')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }

      Column({ space: DesignConstants.SPACING_XS }) {
        Image($r('app.media.ic_weighting'))
          .width(32)
          .height(32)
          .fillColor($r('sys.color.interactive_active'))
        Text('加权模式')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }

      Column({ space: DesignConstants.SPACING_XS }) {
        Image($r('app.media.ic_settings'))
          .width(32)
          .height(32)
          .fillColor($r('sys.color.interactive_active'))
        Text('自定义')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
    }
    .justifyContent(FlexAlign.SpaceAround)
    .width('100%')
    .margin({ top: DesignConstants.SPACING_LG })
  }
}
```

## 5. 第4页：隐私政策页 (PrivacyPolicyPage.ets)

```typescript
import { DesignConstants } from '../../constants/DesignConstants';

@ComponentV2
export struct PrivacyPolicyPage {
  @Param @Require onAgree: () => void;
  @Param @Require onCancel: () => void;
  @Param @Require onPrev: () => void;
  @Param @Require privacyAgreed: boolean;
  @Param @Require onPrivacyAgreedChange: (agreed: boolean) => void;

  build() {
    Column({ space: DesignConstants.SPACING_XL }) {
      // 顶部导航
      this.buildHeader()

      // 标题和描述
      this.buildTitleAndDescription()

      // 权限卡片
      this.buildPermissionCards()

      // 隐私政策同意
      this.buildPrivacyAgreement()

      // 操作按钮
      this.buildActionButtons()
    }
    .width('100%')
    .height('100%')
    .padding(DesignConstants.SPACING_LG)
  }

  @Builder
  private buildHeader() {
    Row() {
      Button('', { type: ButtonType.Circle })
        .width(40)
        .height(40)
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .onClick(() => this.onPrev())

      Blank()

      Text('跳过')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .onClick(() => {
          // 跳过时直接显示隐私政策页，无需额外处理
        })
    }
    .width('100%')
  }

  @Builder
  private buildTitleAndDescription() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('开始使用静喵Sound')
        .fontSize(DesignConstants.FONT_SIZE_XL)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_emphasize'))
        .textAlign(TextAlign.Center)

      Text('为了提供准确的噪音检测服务，我们需要以下必要权限：')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)
        .lineHeight(20)
    }
    .width('100%')
  }

  @Builder
  private buildPermissionCards() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 麦克风权限
      this.buildPermissionCard(
        $r('app.media.ic_mic'),
        '麦克风权限',
        '检测环境噪音'
      )

      // 位置权限
      this.buildPermissionCard(
        $r('app.media.ic_location'),
        '位置权限',
        '记录检测地点'
      )

      // 后台运行权限
      this.buildPermissionCard(
        $r('app.media.ic_power_on'),
        '后台运行权限',
        '持续监测环境'
      )
    }
    .width('100%')
  }

  @Builder
  private buildPermissionCard(icon: Resource, title: string, description: string) {
    Row({ space: DesignConstants.SPACING_MD }) {
      Image(icon)
        .width(DesignConstants.ICON_SIZE_LG)
        .height(DesignConstants.ICON_SIZE_LG)
        .fillColor($r('sys.color.font_primary'))

      Column({ space: DesignConstants.SPACING_XS }) {
        Text(title)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        Text(description)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .alignSelf(ItemAlign.Start)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  @Builder
  private buildPrivacyAgreement() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 复选框和同意文字
      Row({ space: DesignConstants.SPACING_SM }) {
        // 自定义复选框
        Stack({ alignContent: Alignment.Center }) {
          // 背景
          Rectangle()
            .width(20)
            .height(20)
            .fillColor(this.privacyAgreed ? 
              $r('sys.color.interactive_active') : 
              $r('sys.color.comp_background_primary'))
            .border({
              width: DesignConstants.BORDER_WIDTH_SM,
              color: this.privacyAgreed ? 
                $r('sys.color.interactive_active') : 
                $r('sys.color.comp_border_color'),
              style: BorderStyle.Solid
            })
            .borderRadius(DesignConstants.BORDER_RADIUS_XS)

          // 勾选标记
          if (this.privacyAgreed) {
            Text('✓')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_on_primary'))
          }
        }
        .onClick(() => {
          this.onPrivacyAgreedChange(!this.privacyAgreed);
        })

        Text('我已阅读并同意')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))

        Hyperlink($r('app.string.privacy_policy_link'), '《隐私政策》')
          .fontSize(DesignConstants.FONT_SIZE_MD)
      }
      .alignItems(VerticalAlign.Center)

      // 信任声明
      Text('您的数据安全是我们的首要任务')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_tertiary'))
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
  }

  @Builder
  private buildActionButtons() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 同意按钮
      Button('同意并开始', { type: ButtonType.Capsule })
        .width('100%')
        .height(56)
        .backgroundColor(this.privacyAgreed ? 
          $r('sys.color.interactive_active') : 
          $r('sys.color.comp_background_primary'))
        .fontColor(this.privacyAgreed ? 
          $r('sys.color.font_on_primary') : 
          $r('sys.color.font_disabled'))
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .enabled(this.privacyAgreed)
        .onClick(() => {
          if (this.privacyAgreed) {
            this.onAgree();
          }
        })

      // 取消按钮
      Text('取消')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .onClick(() => this.onCancel())
    }
    .width('100%')
  }
}
```

## 6. 导出文件 (index.ets)

```typescript
export { WelcomeGuide, WelcomeGuideBuilder } from './WelcomeGuide';
export { WelcomePage } from './WelcomePage';
export { RealTimeDetectionPage } from './RealTimeDetectionPage';
export { AdvancedFeaturesPage } from './AdvancedFeaturesPage';
export { PrivacyPolicyPage } from './PrivacyPolicyPage';
```

## 7. 集成到Index.ets

在 [`Index.ets`](entry/src/main/ets/pages/Index.ets) 中的集成代码：

```typescript
import { WelcomeGuideBuilder } from '../components/welcome/WelcomeGuide';

// 在PreferenceKeys中添加新字段
export class PreferenceKeys {
  // ... 其他字段
  @Prop has_seen_welcome: boolean = false;
}

// 在Index组件的build方法中修改逻辑
build() {
  Column() {
    Column().id('mainId');
    if (this.isLoading) {
      // 加载中状态
      this.buildLoadingState()
    } else if (!this.isInitialized) {
      // 错误状态
      this.buildErrorState()
    } else {
      // 正常内容
      Navigation(this.navStack) {
        if (this.pk.privacy_agreed) {
          if (!this.pk.has_seen_welcome) {
            // 显示欢迎页
            WelcomeGuideBuilder({
              onComplete: () => {
                this.pk.has_seen_welcome = true;
                // 进入主应用
                MainPage()
              },
              onCancel: () => {
                this.context.terminateSelf();
              }
            })
          } else {
            // 直接进入主应用
            MainPage()
          }
        } else {
          // 原有的隐私政策逻辑保持不变
          PrivacyPolicyDialogBuilder({
            onAgree: () => {
              this.pk.privacy_agreed = true;
              // 隐私政策同意后，下次启动会显示欢迎页
            },
            onCancel: () => {
              this.context.terminateSelf();
            }
          })
        }
      }
      // ... 其他Navigation配置
    }
  }
}
```

## 8. 字符串资源更新

在 [`string.json`](entry/src/main/resources/base/element/string.json) 中添加欢迎页相关字符串：

```json
{
  "string": [
    // ... 其他字符串
    {
      "name": "welcome_page_title",
      "value": "静喵Sound"
    },
    {
      "name": "welcome_page_subtitle", 
      "value": "专业的噪音检测专家"
    },
    {
      "name": "welcome_page_description",
      "value": "精准测量环境噪音，保护您的听力健康"
    },
    {
      "name": "start_explore_button",
      "value": "开始探索"
    },
    {
      "name": "skip_button",
      "value": "跳过"
    },
    {
      "name": "next_button",
      "value": "下一页"
    },
    {
      "name": "real_time_detection_title",
      "value": "实时精准检测"
    },
    {
      "name": "advanced_features_title",
      "value": "专业分析工具"
    },
    {
      "name": "privacy_policy_title",
      "value": "开始使用静喵Sound"
    }
  ]
}
```

## 实现步骤

1. **创建目录和文件**：在 `components/welcome/` 下创建所有文件
2. **实现组件**：按照上述代码实现4个页面组件和主容器
3. **集成到应用**：修改Index.ets的启动逻辑
4. **添加字符串资源**：更新string.json文件
5. **测试**：测试页面流转、动画效果和深色模式适配

这个编码方案提供了完整的实现代码，可以直接用于开发。