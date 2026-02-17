import { PreferenceKeys } from '../../models/PreferenceKeys';
import { EditableLeftIconType, EditableTitleBar, PersistenceV2 } from '@kit.ArkUI';
import promptAction from '@ohos.promptAction';
import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';
import { isProMember, openMembershipCenter } from '../membership/PremiumLockViews';

export interface AutoSaveDialogParams {
  onClose: () => void;
  onSettingsApplied?: (settings: AutoSaveSettings) => void;
}

export interface AutoSaveSettings {
  enabled: boolean;
  interval: number;
}

// 预设选项数据模型
interface PresetOption {
  interval: number;
  icon: string;
  title: string;
  scenario: string;
  description: string;
  isRecommended?: boolean;
}

@ComponentV2
export struct AutoSaveSettingsDialog {
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  // 临时状态变量 - 不立即持久化
  @Local tempAutoSaveEnabled: boolean = this.pk.auto_save_enabled;
  @Local tempInterval: number = this.pk.auto_save_interval;

  @Param @Require params!: AutoSaveDialogParams;

  // 预设选项数据
  private readonly PRESET_OPTIONS: PresetOption[] = [
    {
      interval: 3,
      icon: '🏭',
      title: '3分钟',
      scenario: '工厂/车间监测',
      description: '噪声变化快，需密集记录',
      isRecommended: false
    },
    {
      interval: 5,
      icon: '⚡',
      title: '5分钟',
      scenario: '日常使用推荐',
      description: '平衡精度与存储空间',
      isRecommended: true
    },
    {
      interval: 10,
      icon: '🏠',
      title: '10分钟',
      scenario: '家居/办公环境',
      description: '环境噪声相对稳定',
      isRecommended: false
    },
    {
      interval: 20,
      icon: '❤️',
      title: '20分钟',
      scenario: '长期健康监测',
      description: '24小时连续记录',
      isRecommended: false
    }
  ];

  // 计算属性：当前选中的预设索引（-1表示自定义）
  @Computed
  get selectedIndex(): number {
    const index = this.PRESET_OPTIONS.findIndex(opt => opt.interval === this.tempInterval);
    return index >= 0 ? index : -1;
  }

  // 判断是否为专业版用户
  private isPro(): boolean {
    return isProMember();
  }

  // 处理开关变化
  private handleToggleChange(isOn: boolean): void {
    this.tempAutoSaveEnabled = isOn;
    if (isOn && this.selectedIndex === -1) {
      // 默认选择推荐项（5分钟）
      this.tempInterval = 5;
    }
  }

  // 处理预设选项选择
  private handlePresetSelect(index: number): void {
    if (!this.isPro()) {
      this.showUpgradeToast();
      return;
    }
    this.tempInterval = this.PRESET_OPTIONS[index].interval;
    if (!this.tempAutoSaveEnabled) {
      this.tempAutoSaveEnabled = true;
    }
  }

  // 处理自定义输入变化
  private handleCustomIntervalChange(value: string): void {
    const numValue = parseInt(value, 10);
    if (!isNaN(numValue) && numValue >= 1 && numValue <= 120) {
      this.tempInterval = numValue;
    }
  }

  // 保存设置
  private saveSettings(): void {
    if (!this.isPro()) {
      openMembershipCenter();
      return;
    }

    Throttle.click(() => {
      // 持久化所有设置
      this.pk.auto_save_enabled = this.tempAutoSaveEnabled;
      this.pk.auto_save_interval = this.tempInterval;

      // 通知父组件设置已应用
      if (this.params.onSettingsApplied) {
        this.params.onSettingsApplied({
          enabled: this.tempAutoSaveEnabled,
          interval: this.tempInterval
        });
      }

      promptAction.showToast({ message: '自动保存设置已更新' });
      this.params.onClose();
    });
  }

  // 取消/返回
  private handleCancel(): void {
    this.params.onClose();
  }

  // 显示升级提示
  private showUpgradeToast(): void {
    promptAction.showToast({ message: '升级专业版解锁此功能' });
  }

  // 打开会员中心
  private openMembership(): void {
    openMembershipCenter();
  }

  // 构建功能介绍卡片
  @Builder
  private buildFeatureIntroCard() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题行：图标 + 标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('💾')
          .fontSize(24)
        
        Text('自动保存是什么？')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
      }
      .width('100%')

      // 功能描述
      Text('开启后，应用会按照设定的时间间隔自动保存噪声检测数据，无需手动操作。适合长时间监测、工业检测、睡眠监测等场景。')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')

      // 价值标签
      Row({ space: DesignConstants.SPACING_SM }) {
        this.buildBenefitTag('📊', '数据完整')
        this.buildBenefitTag('⏰', '省心省力')
        this.buildBenefitTag('☁️', '云端备份')
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_secondary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  // 构建价值标签
  @Builder
  private buildBenefitTag(icon: string, text: string) {
    Row({ space: 4 }) {
      Text(icon)
        .fontSize(11)
      Text(text)
        .fontSize(11)
        .fontColor($r('sys.color.font_secondary'))
    }
    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(8)
  }

  // 构建解锁引导卡片
  @Builder
  private buildUnlockPromptCard() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题行
      Row({ space: DesignConstants.SPACING_SM }) {
        Image($r('app.media.ic_vip'))
          .width(24)
          .height(24)
          .fillColor('#FFD700')

        Text('解锁自动保存')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
      }
      .width('100%')

      // 功能描述
      Text('解锁后按设定时间自动保存检测数据到本地，支持数据导出和云端同步备份，数据永不丢失。')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')

      // 权益标签
      Row({ space: DesignConstants.SPACING_SM }) {
        Row({ space: 4 }) {
          Text('🎁')
            .fontSize(12)
          Text('7天免费试用')
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'))
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(10)

        Row({ space: 4 }) {
          Text('☁️')
            .fontSize(12)
          Text('云端同步')
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'))
        }
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(10)
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
        color: 'rgba(255, 107, 107, 0.35)',
        offsetX: 0,
        offsetY: 3
      })
      .onClick(() => {
        this.openMembership();
      })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow({
      radius: 12,
      color: 'rgba(0, 0, 0, 0.08)'
    })
  }

  // 构建智能推荐提示
  @Builder
  private buildSmartTip() {
    Row({ space: DesignConstants.SPACING_SM }) {
      Text('💡')
        .fontSize(16)
      
      Column({ space: 2 }) {
        Text('智能推荐')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FF6B35')
        
        Text('5分钟间隔适合大多数场景，平衡数据精度与存储空间')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor('rgba(255, 107, 53, 0.08)')
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
  }

  // 构建预设选项卡片
  @Builder
  private buildPresetOptionCard(option: PresetOption, index: number) {
    Column({ space: 8 }) {
      // 顶部：图标 + 推荐标签
      Row() {
        Text(option.icon)
          .fontSize(28)
        
        Blank()
        
        if (option.isRecommended) {
          Text('推荐')
            .fontSize(10)
            .fontColor('#FFFFFF')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor('#52C41A')
            .borderRadius(4)
        }
      }
      .width('100%')

      // 时间间隔
      Text(option.title)
        .fontSize(18)
        .fontWeight(this.selectedIndex === index ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.selectedIndex === index ? '#FF6B35' : $r('sys.color.font_primary'))

      // 使用场景
      Text(option.scenario)
        .fontSize(13)
        .fontColor(this.selectedIndex === index ? '#FF6B35' : $r('sys.color.font_secondary'))
        .fontWeight(FontWeight.Medium)

      // 描述
      Text(option.description)
        .fontSize(11)
        .fontColor($r('sys.color.font_tertiary'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.selectedIndex === index ? 'rgba(255, 107, 53, 0.08)' : $r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .border({
      width: this.selectedIndex === index ? 2 : 1,
      color: this.selectedIndex === index ? '#FF6B35' : $r('sys.color.comp_divider')
    })
    .onClick(() => {
      if (this.isPro()) {
        this.handlePresetSelect(index);
      }
    })
  }

  // 构建自定义输入区域
  @Builder
  private buildCustomInput() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('⚙️')
          .fontSize(16)
        Text('自定义间隔')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_primary'))
        
        Blank()
        
        // 当前值显示
        if (this.selectedIndex === -1) {
          Text(`${this.tempInterval}分钟`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor('#FF6B35')
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')

      // 输入区域
      Row({ space: DesignConstants.SPACING_MD }) {
        TextInput({ placeholder: '1-120', text: this.selectedIndex === -1 ? this.tempInterval.toString() : '' })
          .width(100)
          .height(44)
          .type(InputType.Number)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .textAlign(TextAlign.Center)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .enabled(this.isPro())
          .onChange((value: string) => {
            if (this.isPro()) {
              this.handleCustomIntervalChange(value);
            }
          })

        Text('分钟')
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))

        Blank()

        // 提示
        Text('范围：1-120分钟')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_MD)
    .opacity(this.isPro() ? 1 : 0.5)
  }

  // 构建当前设置摘要
  @Builder
  private buildCurrentSettingSummary() {
    Row({ space: DesignConstants.SPACING_MD }) {
      Column({ space: 4 }) {
        Text('当前设置')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
        
        if (this.tempAutoSaveEnabled) {
          Row({ space: DesignConstants.SPACING_SM }) {
            Text(`每 ${this.tempInterval} 分钟自动保存`)
              .fontSize(DesignConstants.FONT_SIZE_LG)
              .fontColor('#52C41A')
              .fontWeight(FontWeight.Medium)
            
            Text('✓ 已开启')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor('#52C41A')
          }
        } else {
          Text('自动保存已关闭')
            .fontSize(DesignConstants.FONT_SIZE_LG)
            .fontColor($r('sys.color.font_tertiary'))
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // 开关
      Toggle({ type: ToggleType.Switch, isOn: this.tempAutoSaveEnabled })
        .selectedColor('#52C41A')
        .switchPointColor($r('app.color.background_primary'))
        .enabled(this.isPro())
        .onChange((isOn: boolean) => {
          if (this.isPro()) {
            this.handleToggleChange(isOn);
          }
        })
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  build() {
    Column() {
      // 标题栏
      EditableTitleBar({
        title: '自动保存设置',
        leftIconStyle: EditableLeftIconType.Cancel,
        isSaveIconRequired: this.isPro(),
        onCancel: (): void => this.handleCancel(),
        onSave: (): void => this.saveSettings()
      })

      // 免费版解锁引导卡片（顶部固定显示）
      if (!this.isPro()) {
        Column() {
          this.buildUnlockPromptCard()
        }
        .width('100%')
        .padding(DesignConstants.SPACING_LG)
      }

      // 内容区域
      Scroll() {
        Column({ space: DesignConstants.SPACING_LG }) {
          // 功能介绍卡片
          this.buildFeatureIntroCard()

          // 当前设置摘要（带开关）
          this.buildCurrentSettingSummary()

          // 配置选项区域（开启时显示）
          if (this.tempAutoSaveEnabled || !this.isPro()) {
            // 智能推荐提示
            this.buildSmartTip()

            // 预设选项标题
            Row({ space: DesignConstants.SPACING_SM }) {
              Text('选择保存间隔')
                .fontSize(DesignConstants.FONT_SIZE_MD)
                .fontColor($r('sys.color.font_primary'))
                .fontWeight(FontWeight.Medium)
              
              Text('点击选择适合你的场景')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.font_secondary'))
            }
            .width('100%')

            // 预设选项网格
            GridRow({ columns: 2, gutter: 12 }) {
              ForEach(this.PRESET_OPTIONS, (option: PresetOption, index: number) => {
                GridCol({ span: 1 }) {
                  this.buildPresetOptionCard(option, index)
                }
              })
            }
            .width('100%')
            .opacity(this.isPro() ? 1 : 0.5)

            // 自定义输入区域
            this.buildCustomInput()
          }

          // 数据安全提示
          if (this.tempAutoSaveEnabled && this.isPro()) {
            Row({ space: DesignConstants.SPACING_SM }) {
              Text('🔒')
                .fontSize(16)
              Text('数据仅保存在本地，可随时导出为Excel或CSV格式')
                .fontSize(DesignConstants.FONT_SIZE_SM)
                .fontColor($r('sys.color.font_secondary'))
                .layoutWeight(1)
            }
            .width('100%')
            .padding(DesignConstants.SPACING_MD)
            .backgroundColor('rgba(82, 196, 26, 0.08)')
            .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          }
        }
        .width('100%')
        .padding(DesignConstants.SPACING_LG)
        .alignItems(HorizontalAlign.Start)
      }
      .scrollBar(BarState.Auto)
      .scrollable(ScrollDirection.Vertical)
      .layoutWeight(1)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
  }
}

@Builder
export function AutoSaveSettingsDialogBuilder(params: AutoSaveDialogParams) {
  AutoSaveSettingsDialog({ params: params })
}
