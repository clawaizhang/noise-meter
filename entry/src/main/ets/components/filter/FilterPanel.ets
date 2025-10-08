import { FilterConfig, FilterManager, DecibelRangeFilter, StatusFilter, WeightingFilter, TextSearchFilter } from '../../models/FilterConfig';
import { WeightingType } from '../../constants/WeightingConstants';
import { DesignConstants } from '../../constants/DesignConstants';
import { Throttle } from '../../utils/Debounce';
import { DecibelRange } from '../../models/DecibelRecord';

/**
 * 过滤器面板组件
 */
@ComponentV2
export struct FilterPanel {
  @Param @Require filterConfig: FilterConfig = new FilterConfig(false);
  @Local customMinDecibel: string = '';
  @Local customMaxDecibel: string = '';
  @Local locationKeyword: string = '';
  @Local commentKeyword: string = '';

  @Event onApplyFilters: (filters: FilterConfig) => void = () => {};
  @Event onResetFilters: () => void = () => {};

  aboutToAppear() {
    // 初始化分贝范围预设
    if (!this.filterConfig.decibelRange) {
      this.filterConfig.decibelRange = new DecibelRangeFilter();
    }
    if (!this.filterConfig.status) {
      this.filterConfig.status = new StatusFilter();
    }
    if (!this.filterConfig.weighting) {
      this.filterConfig.weighting = new WeightingFilter();
    }
    if (!this.filterConfig.textSearch) {
      this.filterConfig.textSearch = new TextSearchFilter();
    }
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 分贝范围过滤器
      this.DecibelRangeSection()

      // 状态过滤器
      this.StatusSection()

      // 权重类型过滤器
      this.WeightingSection()

      // 文本搜索过滤器
      this.TextSearchSection()

      // 操作按钮
      this.ActionButtons()
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
    .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })
  }

  /**
   * 分贝范围过滤器部分
   */
  @Builder
  DecibelRangeSection() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('分贝范围')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      Text('基于平均分贝值')
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: DesignConstants.SPACING_SM })

      // 预设范围选项
      GridRow({
        columns: {
          xs: 2,
          sm: 3,
          md: 4,
          lg: 4,
          xl: 4,
          xxl: 4
        },
        breakpoints: { reference: BreakpointsReference.WindowSize },
        gutter: 8
      }) {
        ForEach(FilterManager.getAllDecibelRanges(), (range: DecibelRange) => {
          GridCol({ span: 1 }) {
            Row({ space: 4 }) {
              Checkbox({
                name: range.desc,
                group: 'decibelRanges'
              })
              .select(this.isDecibelRangeSelected(range))
              .selectedColor($r('sys.color.brand'))
              .onChange((value: boolean) => {
                this.toggleDecibelRange(range, value);
              })
              Text(range.desc)
                .fontSize(DesignConstants.FONT_SIZE_XS)
                .fontColor($r('sys.color.font_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
            }
            .justifyContent(FlexAlign.Start)
            .alignItems(VerticalAlign.Center)
            .width('100%')
          }
          .padding({ left: 8, right: 8, top: 6, bottom: 6 })
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .width('100%')
          .onClick(() => {
            this.toggleDecibelRange(range, !this.isDecibelRangeSelected(range));
          })
        })
      }

      // 自定义范围输入
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('自定义:')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_primary'))

        TextInput({ placeholder: '最小值' })
          .width(80)
          .height(32)
          .type(InputType.Number)
          .maxLength(3)
          .textAlign(TextAlign.Center)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onChange((value: string) => {
            this.customMinDecibel = value;
          })

        Text('-')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))

        TextInput({ placeholder: '最大值' })
          .width(80)
          .height(32)
          .type(InputType.Number)
          .maxLength(3)
          .textAlign(TextAlign.Center)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onChange((value: string) => {
            this.customMaxDecibel = value;
          })

        Text('dB')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .margin({ top: DesignConstants.SPACING_SM })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 状态过滤器部分
   */
  @Builder
  StatusSection() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('状态')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      GridRow({
        columns: {
          xs: 3,
          sm: 3,
          md: 3,
          lg: 3,
          xl: 3,
          xxl: 3
        },
        breakpoints: { reference: BreakpointsReference.WindowSize },
        gutter: 8
      }) {
        GridCol({ span: 1 }) {
          Row({ space: 4 }) {
            Checkbox({
              name: '仅收藏',
              group: 'status'
            })
            .select(this.filterConfig.status?.favoriteOnly || false)
            .selectedColor($r('sys.color.brand'))
            .onChange((value: boolean) => {
              if (!this.filterConfig.status) {
                this.filterConfig.status = new StatusFilter();
              }
              this.filterConfig.status.favoriteOnly = value;
            })
            Text('仅收藏')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_primary'))
              .maxLines(1)
          }
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)
          .width('100%')
        }
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          if (!this.filterConfig.status) {
            this.filterConfig.status = new StatusFilter();
          }
          this.filterConfig.status.favoriteOnly = !this.filterConfig.status.favoriteOnly;
        })

        GridCol({ span: 1 }) {
          Row({ space: 4 }) {
            Checkbox({
              name: '有音频',
              group: 'status'
            })
            .select(this.filterConfig.status?.hasAudio || false)
            .selectedColor($r('sys.color.brand'))
            .onChange((value: boolean) => {
              if (!this.filterConfig.status) {
                this.filterConfig.status = new StatusFilter();
              }
              this.filterConfig.status.hasAudio = value;
            })
            Text('有音频')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_primary'))
              .maxLines(1)
          }
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)
          .width('100%')
        }
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          if (!this.filterConfig.status) {
            this.filterConfig.status = new StatusFilter();
          }
          this.filterConfig.status.hasAudio = !this.filterConfig.status.hasAudio;
        })

        GridCol({ span: 1 }) {
          Row({ space: 4 }) {
            Checkbox({
              name: '有位置',
              group: 'status'
            })
            .select(this.filterConfig.status?.hasLocation || false)
            .selectedColor($r('sys.color.brand'))
            .onChange((value: boolean) => {
              if (!this.filterConfig.status) {
                this.filterConfig.status = new StatusFilter();
              }
              this.filterConfig.status.hasLocation = value;
            })
            Text('有位置')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_primary'))
              .maxLines(1)
          }
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)
          .width('100%')
        }
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          if (!this.filterConfig.status) {
            this.filterConfig.status = new StatusFilter();
          }
          this.filterConfig.status.hasLocation = !this.filterConfig.status.hasLocation;
        })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 权重类型过滤器部分
   */
  @Builder
  WeightingSection() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('权重类型')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      GridRow({
        columns: {
          xs: 3,
          sm: 3,
          md: 3,
          lg: 3,
          xl: 3,
          xxl: 3
        },
        breakpoints: { reference: BreakpointsReference.WindowSize },
        gutter: 8
      }) {
        GridCol({ span: 1 }) {
          Row({ space: 4 }) {
            Checkbox({
              name: 'A计权',
              group: 'weighting'
            })
            .select(this.isWeightingTypeSelected(WeightingType.A))
            .selectedColor($r('sys.color.brand'))
            .onChange((value: boolean) => {
              this.toggleWeightingType(WeightingType.A, value);
            })
            Text('A计权')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_primary'))
              .maxLines(1)
          }
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)
          .width('100%')
        }
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          this.toggleWeightingType(WeightingType.A, !this.isWeightingTypeSelected(WeightingType.A));
        })

        GridCol({ span: 1 }) {
          Row({ space: 4 }) {
            Checkbox({
              name: 'C计权',
              group: 'weighting'
            })
            .select(this.isWeightingTypeSelected(WeightingType.C))
            .selectedColor($r('sys.color.brand'))
            .onChange((value: boolean) => {
              this.toggleWeightingType(WeightingType.C, value);
            })
            Text('C计权')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_primary'))
              .maxLines(1)
          }
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)
          .width('100%')
        }
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          this.toggleWeightingType(WeightingType.C, !this.isWeightingTypeSelected(WeightingType.C));
        })

        GridCol({ span: 1 }) {
          Row({ space: 4 }) {
            Checkbox({
              name: 'Z计权',
              group: 'weighting'
            })
            .select(this.isWeightingTypeSelected(WeightingType.Z))
            .selectedColor($r('sys.color.brand'))
            .onChange((value: boolean) => {
              this.toggleWeightingType(WeightingType.Z, value);
            })
            Text('Z计权')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_primary'))
              .maxLines(1)
          }
          .justifyContent(FlexAlign.Start)
          .alignItems(VerticalAlign.Center)
          .width('100%')
        }
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          this.toggleWeightingType(WeightingType.Z, !this.isWeightingTypeSelected(WeightingType.Z));
        })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 文本搜索过滤器部分
   */
  @Builder
  TextSearchSection() {
    Column({ space: DesignConstants.SPACING_SM }) {
      Text('搜索')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      Column({ space: DesignConstants.SPACING_SM }) {
        Text('位置:')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        TextInput({ placeholder: '输入位置关键词...' })
          .width('100%')
          .height(36)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onChange((value: string) => {
            this.locationKeyword = value;
          })
      }

      Column({ space: DesignConstants.SPACING_SM }) {
        Text('备注:')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_primary'))
          .alignSelf(ItemAlign.Start)

        TextInput({ placeholder: '输入备注关键词...' })
          .width('100%')
          .height(36)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(DesignConstants.BORDER_RADIUS_MD)
          .onChange((value: string) => {
            this.commentKeyword = value;
          })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  /**
   * 操作按钮部分
   */
  @Builder
  ActionButtons() {
    Row({ space: DesignConstants.SPACING_MD }) {
      Button('重置')
        .layoutWeight(1)
        .height(40)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_primary'))
        .backgroundColor($r('sys.color.comp_background_secondary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          Throttle.click(() => {
            this.resetAllFilters();
            this.onResetFilters();
          });
        })

      Button('应用过滤')
        .layoutWeight(1)
        .height(40)
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor(Color.White)
        .backgroundColor($r('sys.color.brand'))
        .borderRadius(DesignConstants.BORDER_RADIUS_MD)
        .onClick(() => {
          Throttle.click(() => {
            this.applyFilters();
            this.onApplyFilters(this.filterConfig);
          });
        })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ top: DesignConstants.SPACING_MD })
  }

  // 辅助方法

  private isDecibelRangeSelected(range: DecibelRange): boolean {
    return this.filterConfig.decibelRange?.presetRanges.some(r => 
      r.min === range.min && r.max === range.max
    ) || false;
  }

  private toggleDecibelRange(range: DecibelRange, selected: boolean): void {
    if (!this.filterConfig.decibelRange) {
      this.filterConfig.decibelRange = new DecibelRangeFilter();
    }

    if (selected) {
      // 添加范围
      if (!this.filterConfig.decibelRange.presetRanges.some(r => 
        r.min === range.min && r.max === range.max
      )) {
        this.filterConfig.decibelRange.presetRanges.push(range);
      }
    } else {
      // 移除范围
      this.filterConfig.decibelRange.presetRanges = 
        this.filterConfig.decibelRange.presetRanges.filter(r => 
          !(r.min === range.min && r.max === range.max)
        );
    }
  }

  private isWeightingTypeSelected(type: WeightingType): boolean {
    return this.filterConfig.weighting?.types.includes(type) || false;
  }

  private toggleWeightingType(type: WeightingType, selected: boolean): void {
    if (!this.filterConfig.weighting) {
      this.filterConfig.weighting = new WeightingFilter();
    }

    if (selected) {
      // 添加类型
      if (!this.filterConfig.weighting.types.includes(type)) {
        this.filterConfig.weighting.types.push(type);
      }
    } else {
      // 移除类型
      this.filterConfig.weighting.types = 
        this.filterConfig.weighting.types.filter(t => t !== type);
    }
  }

  private applyFilters(): void {
    // 处理自定义分贝范围
    if (this.customMinDecibel || this.customMaxDecibel) {
      if (!this.filterConfig.decibelRange) {
        this.filterConfig.decibelRange = new DecibelRangeFilter();
      }
      this.filterConfig.decibelRange.customMin = this.customMinDecibel ? 
        parseInt(this.customMinDecibel) : undefined;
      this.filterConfig.decibelRange.customMax = this.customMaxDecibel ? 
        parseInt(this.customMaxDecibel) : undefined;
    }

    // 处理文本搜索
    if (!this.filterConfig.textSearch) {
      this.filterConfig.textSearch = new TextSearchFilter();
    }
    this.filterConfig.textSearch.locationKeyword = this.locationKeyword || undefined;
    this.filterConfig.textSearch.commentKeyword = this.commentKeyword || undefined;

    // 激活过滤器
    this.filterConfig.isActive = true;
  }

  private resetAllFilters(): void {
    // 重置过滤器配置，不重新赋值整个对象
    this.filterConfig.isActive = false;
    if (this.filterConfig.decibelRange) {
      this.filterConfig.decibelRange.presetRanges = [];
      this.filterConfig.decibelRange.customMin = undefined;
      this.filterConfig.decibelRange.customMax = undefined;
    }
    if (this.filterConfig.status) {
      this.filterConfig.status.favoriteOnly = false;
      this.filterConfig.status.hasAudio = false;
      this.filterConfig.status.hasLocation = false;
    }
    if (this.filterConfig.weighting) {
      this.filterConfig.weighting.types = [];
    }
    if (this.filterConfig.textSearch) {
      this.filterConfig.textSearch.locationKeyword = undefined;
      this.filterConfig.textSearch.commentKeyword = undefined;
    }
    this.customMinDecibel = '';
    this.customMaxDecibel = '';
    this.locationKeyword = '';
    this.commentKeyword = '';
  }

  /**
   * 设置应用过滤器回调
   */
  setOnApplyFilters(callback: (filters: FilterConfig) => void): void {
    this.onApplyFilters = callback;
  }

  /**
   * 设置重置过滤器回调
   */
  setOnResetFilters(callback: () => void): void {
    this.onResetFilters = callback;
  }

  /**
   * 设置过滤器配置
   */
  setFilterConfig(config: FilterConfig): void {
    // 复制配置属性，不重新赋值整个对象
    this.filterConfig.isActive = config.isActive;
    
    if (config.decibelRange) {
      if (!this.filterConfig.decibelRange) {
        this.filterConfig.decibelRange = new DecibelRangeFilter();
      }
      this.filterConfig.decibelRange.presetRanges = [...config.decibelRange.presetRanges];
      this.filterConfig.decibelRange.customMin = config.decibelRange.customMin;
      this.filterConfig.decibelRange.customMax = config.decibelRange.customMax;
    }
    
    if (config.status) {
      if (!this.filterConfig.status) {
        this.filterConfig.status = new StatusFilter();
      }
      this.filterConfig.status.favoriteOnly = config.status.favoriteOnly;
      this.filterConfig.status.hasAudio = config.status.hasAudio;
      this.filterConfig.status.hasLocation = config.status.hasLocation;
    }
    
    if (config.weighting) {
      if (!this.filterConfig.weighting) {
        this.filterConfig.weighting = new WeightingFilter();
      }
      this.filterConfig.weighting.types = [...config.weighting.types];
    }
    
    if (config.textSearch) {
      if (!this.filterConfig.textSearch) {
        this.filterConfig.textSearch = new TextSearchFilter();
      }
      this.filterConfig.textSearch.locationKeyword = config.textSearch.locationKeyword;
      this.filterConfig.textSearch.commentKeyword = config.textSearch.commentKeyword;
    }
    
    // 更新自定义分贝范围显示
    if (this.filterConfig.decibelRange?.customMin !== undefined) {
      this.customMinDecibel = this.filterConfig.decibelRange.customMin.toString();
    }
    if (this.filterConfig.decibelRange?.customMax !== undefined) {
      this.customMaxDecibel = this.filterConfig.decibelRange.customMax.toString();
    }
    
    // 更新文本搜索显示
    if (this.filterConfig.textSearch?.locationKeyword) {
      this.locationKeyword = this.filterConfig.textSearch.locationKeyword;
    }
    if (this.filterConfig.textSearch?.commentKeyword) {
      this.commentKeyword = this.filterConfig.textSearch.commentKeyword;
    }
  }
}