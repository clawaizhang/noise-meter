/**
 * 专业版锁定设计演示
 * 
 * 展示三种不同场景下的锁定UI设计：
 * 1. 设置页开关场景 - 底部卡片式
 * 2. 列表项场景 - 角标强化式
 * 3. 核心功能场景 - 全屏引导式
 * 
 * 用户操作流程：
 * 点击锁定区域 → 展示功能预览 → 点击解锁 → 弹出升级弹窗 → 引导购买/试用
 */

import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';

// ============ 场景1：设置页开关（底部卡片式）============
@Component
export struct Scene1_SettingToggle {
  @State isPressed: boolean = false

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 模拟设置项标题
      Text('数据管理')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: DesignConstants.SPACING_SM })

      // 锁定区域容器
      Stack({ alignContent: Alignment.Bottom }) {
        // 底层：置灰的内容预览
        Column({ space: DesignConstants.SPACING_MD }) {
          // 自动保存开关（置灰状态）
          Row() {
            Column({ space: DesignConstants.SPACING_XS }) {
              Text('自动保存检测数据')
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('sys.color.font_primary'))
              
              Text('按设定时间间隔自动保存')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.font_secondary'))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            
            // 模拟开关（禁用状态）
            Row()
              .width(48)
              .height(28)
              .backgroundColor('#E0E0E0')
              .borderRadius(14)
          }
          .width('100%')
          .padding(DesignConstants.SPACING_MD)
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)

          // 保存间隔设置（置灰）
          Row() {
            Text('保存间隔')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))
            
            Blank()
            
            Text('5分钟')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_secondary'))
          }
          .width('100%')
          .padding(DesignConstants.SPACING_MD)
          .backgroundColor($r('sys.color.comp_background_primary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        }
        .width('100%')
        .opacity(0.5)
        .enabled(false)
        .blur(1)

        // 渐变遮罩
        Column()
          .width('100%')
          .height(100)
          .background(
            LinearGradient({
              direction: GradientDirection.Top,
              colors: [
                ['rgba(255,255,255,0)', 0],
                ['rgba(255,255,255,0.98)', 1]
              ]
            })
          )

        // 底部解锁引导卡片
        Column({ space: DesignConstants.SPACING_MD }) {
          // 图标 + 标题
          Row({ space: DesignConstants.SPACING_SM }) {
            // 锁定图标（带圆圈）
            Stack() {
              Circle()
                .width(44)
                .height(44)
                .fillColor('rgba(255, 107, 107, 0.1)')
              
              Image($r('app.media.ic_lock'))
                .width(22)
                .height(22)
                .fillColor('#FF6B6B')
            }

            Column({ space: DesignConstants.SPACING_XS }) {
              Row({ space: DesignConstants.SPACING_SM }) {
                Text('自动保存')
                  .fontSize(DesignConstants.FONT_SIZE_LG)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('sys.color.font_primary'))
                
                // PRO 标签
                Row({ space: 2 }) {
                  Image($r('app.media.ic_vip'))
                    .width(10)
                    .height(10)
                    .fillColor('#FFD700')
                  Text('PRO')
                    .fontSize(9)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#B8860B')
                }
                .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                .backgroundColor('#FFF8DC')
                .border({ width: 0.5, color: '#FFD700' })
                .borderRadius(8)
              }

              Text('按设定时间自动保存检测数据，防止丢失')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.font_secondary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')

          // 权益标签
          Row({ space: DesignConstants.SPACING_SM }) {
            this.BenefitTag('🎁', '7天免费试用')
            this.BenefitTag('☁️', '云端同步')
          }
          .width('100%')

          // 解锁按钮
          Button() {
            Row({ space: DesignConstants.SPACING_SM }) {
              Text('🔓')
                .fontSize(16)
              Text('0.01元立即试用')
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
            }
          }
          .width('100%')
          .height(44)
          .backgroundColor('#FF6B6B')
          .borderRadius(22)
          .shadow({
            radius: 8,
            color: 'rgba(255, 107, 107, 0.3)',
            offsetX: 0,
            offsetY: 3
          })
          .stateEffect(true)
          .onClick(() => {
            Throttle.click(() => {
              // 弹出升级弹窗
            });
          })
        }
        .width('100%')
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.background_primary'))
        .borderRadius({ topLeft: 16, topRight: 16 })
        .shadow({
          radius: 8,
          color: 'rgba(0, 0, 0, 0.06)',
          offsetX: 0,
          offsetY: -2
        })
      }
      .width('100%')
      .height(220)
      .backgroundColor($r('sys.color.comp_background_secondary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      .clip(true)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
  }

  @Builder
  BenefitTag(icon: string, text: string) {
    Row({ space: 4 }) {
      Text(icon)
        .fontSize(11)
      Text(text)
        .fontSize(11)
        .fontColor($r('sys.color.font_secondary'))
    }
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(10)
  }
}

// ============ 场景2：列表项（角标强化式）============
@Component
export struct Scene2_ListItem {
  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('历史记录（仅最近3条）')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 列表容器
      Column({ space: DesignConstants.SPACING_SM }) {
        // 第1条 - 可用
        this.HistoryItem('2024-01-15 14:30', '65.2 dB', '办公室', false)
        
        // 第2条 - 可用
        this.HistoryItem('2024-01-15 10:15', '58.7 dB', '家中', false)
        
        // 第3条 - 可用
        this.HistoryItem('2024-01-14 16:45', '72.1 dB', '街道', false)

        // 第4条 - 锁定（带引导）
        this.LockedHistoryItem()

        // 第5条+ - 更多锁定提示
        this.MoreLockedItem()
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
  }

  @Builder
  HistoryItem(time: string, db: string, location: string, isLocked: boolean) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 噪音等级指示
      Column() {
        Text(db)
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getDbColor(parseFloat(db)))
      }
      .width(60)

      Column({ space: DesignConstants.SPACING_XS }) {
        Text(time)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
        
        Text(location)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('app.media.ic_arrow_right'))
        .width(16)
        .height(16)
        .fillColor($r('sys.color.font_tertiary'))
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .opacity(isLocked ? 0.4 : 1)
  }

  @Builder
  LockedHistoryItem() {
    Stack({ alignContent: Alignment.Center }) {
      // 置灰的背景项
      Row({ space: DesignConstants.SPACING_MD }) {
        Column() {
          Text('--.-')
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_tertiary'))
        }
        .width(60)

        Column({ space: DesignConstants.SPACING_XS }) {
          Text('更多记录...')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
          
          Text('解锁查看全部')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .opacity(0.35)

      // 居中解锁提示
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_vip'))
          .width(16)
          .height(16)
          .fillColor('#FFD700')
        
        Text('解锁查看全部 100+ 条记录')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
        
        Text('›')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontColor($r('sys.color.brand'))
      }
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor($r('sys.color.background_primary'))
      .borderRadius(20)
      .shadow({
        radius: 6,
        color: 'rgba(0, 0, 0, 0.1)'
      })
    }
    .width('100%')
    .height(64)
    .onClick(() => {
      Throttle.click(() => {
        // 弹出升级弹窗
      });
    })
  }

  @Builder
  MoreLockedItem() {
    Row({ space: DesignConstants.SPACING_SM }) {
      Image($r('app.media.ic_lock'))
        .width(14)
        .height(14)
        .fillColor($r('sys.color.font_tertiary'))
      
      Text('还有 47 条记录被锁定')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
      
      Blank()
      
      Text('解锁 ›')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.brand'))
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding({ top: DesignConstants.SPACING_SM, bottom: DesignConstants.SPACING_SM })
    .onClick(() => {
      Throttle.click(() => {
        // 弹出升级弹窗
      });
    })
  }

  private getDbColor(db: number): Resource {
    if (db < 60) return '#51CF66'
    if (db < 75) return '#FFD93D'
    return '#FF6B6B'
  }
}

// ============ 场景3：核心功能（全屏引导式）============
@Component
export struct Scene3_CoreFeature {
  @State showDetail: boolean = false

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('频谱分析')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      // 全屏锁定区域
      Stack({ alignContent: Alignment.Center }) {
        // 背景：模糊的频谱预览图
        Column({ space: 0 }) {
          // 模拟频谱图
          Stack() {
            // 背景网格
            Column({ space: 10 }) {
              ForEach([1, 2, 3, 4, 5], () => {
                Row()
                  .width('100%')
                  .height(1)
                  .backgroundColor('rgba(51, 154, 240, 0.3)')
              })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.SpaceEvenly)

            // 模拟频谱柱状图
            Row({ space: 8 }) {
              ForEach([30, 55, 80, 65, 45, 70, 90, 60, 40, 50], (height: number) => {
                Column() {
                  Blank()
                  Row()
                    .width(12)
                    .height(height)
                    .backgroundColor('#339AF0')
                    .borderRadius({ topLeft: 4, topRight: 4 })
                }
                .height('80%')
              })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .height(180)
          .backgroundColor('rgba(51, 154, 240, 0.05)')
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)

          // 参数显示（置灰）
          Row({ space: DesignConstants.SPACING_MD }) {
            this.ParamItem('计权', 'A计权')
            this.ParamItem('窗函数', 'Hanning')
            this.ParamItem('采样率', '44.1kHz')
          }
          .width('100%')
          .padding(DesignConstants.SPACING_MD)
        }
        .width('100%')
        .opacity(0.4)
        .blur(2)
        .grayscale(0.8)

        // 中央解锁卡片（悬浮效果）
        Column({ space: DesignConstants.SPACING_LG }) {
          // VIP 大图标
          Stack() {
            Circle()
              .width(72)
              .height(72)
              .fillColor('rgba(255, 215, 0, 0.15)')
            
            Text('💎')
              .fontSize(36)
          }

          Column({ space: DesignConstants.SPACING_SM }) {
            Text('专业频谱分析')
              .fontSize(DesignConstants.FONT_SIZE_XL)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
            
            Text('解锁高级功能，深入了解声音世界')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_secondary'))
              .textAlign(TextAlign.Center)
          }

          // 功能预览列表
          Column({ space: DesignConstants.SPACING_SM }) {
            this.FeaturePreview('🎚️', 'A/C/Z 三计权模式', '符合国际标准的频率加权')
            this.FeaturePreview('📊', 'FFT 自定义参数', '窗函数、采样率自由调节')
            this.FeaturePreview('📈', '实时频谱追踪', '毫秒级频谱更新')
          }
          .width('100%')
          .padding(DesignConstants.SPACING_MD)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)

          // 试用按钮
          Column({ space: DesignConstants.SPACING_SM }) {
            Button() {
              Row({ space: DesignConstants.SPACING_SM }) {
                Text('🎁')
                  .fontSize(18)
                Text('0.01元试用7天')
                  .fontSize(DesignConstants.FONT_SIZE_LG)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.White)
              }
            }
            .width('100%')
            .height(50)
            .backgroundColor('#FF6B6B')
            .borderRadius(25)
            .shadow({
              radius: 10,
              color: 'rgba(255, 107, 107, 0.4)',
              offsetX: 0,
              offsetY: 4
            })

            Text('试用期后可随时取消，不会产生额外费用')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_tertiary'))
          }
          .width('100%')
        }
        .width('85%')
        .padding(DesignConstants.SPACING_LG)
        .backgroundColor($r('sys.color.background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_LG)
        .shadow({
          radius: 20,
          color: 'rgba(0, 0, 0, 0.12)'
        })
      }
      .width('100%')
      .height(400)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
  }

  @Builder
  ParamItem(label: string, value: string) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(label)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
      
      Text(value)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
    }
    .layoutWeight(1)
  }

  @Builder
  FeaturePreview(icon: string, title: string, desc: string) {
    Row({ space: DesignConstants.SPACING_SM }) {
      Text(icon)
        .fontSize(20)
      
      Column({ space: 2 }) {
        Text(title)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
        
        Text(desc)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
  }
}

// ============ 主演示页面 ============
@Component
export struct PremiumLockDesignDemo {
  @State currentScene: number = 1

  build() {
    Scroll() {
      Column({ space: DesignConstants.SPACING_LG }) {
        // 标题
        Column({ space: DesignConstants.SPACING_SM }) {
          Text('专业版锁定UI设计演示')
            .fontSize(DesignConstants.FONT_SIZE_2XL)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
          
          Text('选择下方标签查看不同场景的设计方案')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width('100%')
        .padding(DesignConstants.SPACING_MD)

        // 场景切换标签
        Row({ space: DesignConstants.SPACING_SM }) {
          this.SceneTab('场景1', '设置页', 1)
          this.SceneTab('场景2', '列表项', 2)
          this.SceneTab('场景3', '核心功能', 3)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .padding(DesignConstants.SPACING_MD)

        // 场景说明卡片
        this.SceneDescription()

        // 场景演示
        if (this.currentScene === 1) {
          Scene1_SettingToggle()
        } else if (this.currentScene === 2) {
          Scene2_ListItem()
        } else {
          Scene3_CoreFeature()
        }

        // 用户操作流程说明
        this.UserFlowDescription()
      }
      .width('100%')
      .padding({ bottom: 100 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }

  @Builder
  SceneTab(title: string, subtitle: string, index: number) {
    Column({ space: DesignConstants.SPACING_XS }) {
      Text(title)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(this.currentScene === index ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentScene === index ? $r('sys.color.brand') : $r('sys.color.font_secondary'))
      
      Text(subtitle)
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor(this.currentScene === index ? $r('sys.color.brand') : $r('sys.color.font_tertiary'))
    }
    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
    .backgroundColor(this.currentScene === index ? 'rgba(51, 154, 240, 0.1)' : Color.Transparent)
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .onClick(() => {
      this.currentScene = index
    })
  }

  @Builder
  SceneDescription() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('当前场景说明')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)
      
      Text(this.getSceneDescription())
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  @Builder
  UserFlowDescription() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('👆 用户操作流程')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)
      
      // 流程步骤
      Column({ space: DesignConstants.SPACING_SM }) {
        this.FlowStep('1', '看到锁定区域', '用户看到置灰的功能预览，产生好奇心')
        this.FlowStep('2', '点击锁定区域', '弹出功能详情/升级引导弹窗')
        this.FlowStep('3', '了解功能价值', '展示该功能的详细介绍和权益')
        this.FlowStep('4', '选择试用/购买', '0.01元试用或直接开通会员')
        this.FlowStep('5', '解锁功能', '立即解锁，享受完整功能')
      }
      .width('100%')
      .padding(DesignConstants.SPACING_MD)
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
  }

  @Builder
  FlowStep(number: string, title: string, desc: string) {
    Row({ space: DesignConstants.SPACING_MD }) {
      // 步骤编号
      Stack() {
        Circle()
          .width(28)
          .height(28)
          .fillColor('rgba(51, 154, 240, 0.15)')
        
        Text(number)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.brand'))
      }

      Column({ space: DesignConstants.SPACING_XS }) {
        Text(title)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
        
        Text(desc)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }

  private getSceneDescription(): string {
    switch (this.currentScene) {
      case 1:
        return '【底部卡片式】适用于设置页开关类功能。置灰显示开关的状态，底部弹出解锁引导卡片，展示功能名称、简介、权益标签和试用按钮。用户能直观看到功能形态，同时被引导解锁。'
      case 2:
        return '【角标强化式】适用于列表项类功能。前3条正常显示，第4条开始显示锁定状态，中央悬浮解锁提示，底部显示"还有XX条被锁定"。制造稀缺感，激发解锁欲望。'
      case 3:
        return '【全屏引导式】适用于核心功能入口。全屏置灰展示功能预览，中央悬浮大卡片展示VIP图标、功能标题、详细功能列表和试用按钮。视觉冲击强，适合重要功能的转化。'
      default:
        return ''
    }
  }
}
