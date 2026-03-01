import { SpectrumDisplayService, FrequencyRange, DecibelRange, SpectrumDisplayConfig } from '../../services/SpectrumDisplayService';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { DesignConstants } from '../../constants/DesignConstants';
import { PersistenceV2 } from '@ohos.arkui.StateManagement';

/**
 * 频谱显示设置对话框参数接口
 */
export interface SpectrumDisplaySettingsParams {
  onClose: () => void;
  onSettingsApplied: (config: SpectrumDisplayConfig) => void;
}

@ComponentV2
export struct SpectrumDisplaySettingsDialog {
  @Param params: SpectrumDisplaySettingsParams | null = null;
  
  // 当前配置
  @Local private smoothingFactor: number = 0.3;
  @Local private exponentialSmoothingFactor: number = 0.3;
  @Local private showPeakFrequency: boolean = true;
  @Local private peakCount: number = 1; // 新增：峰值数量
  @Local private frequencyRange: FrequencyRange = FrequencyRange.FULL;
  @Local private decibelRange: DecibelRange = DecibelRange.AUTO;
  
  // 自定义范围
  @Local private customFrequencyMin: number = 16;
  @Local private customFrequencyMax: number = 20000;
  @Local private customDecibelMin: number = -20;
  @Local private customDecibelMax: number = 140;
  @Local private pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!

  // 服务实例
  @Local private spectrumDisplayService: SpectrumDisplayService = SpectrumDisplayService.getInstance();
  
  aboutToAppear() {
    // 从PreferenceKeys加载当前配置
    const config = this.spectrumDisplayService.getDisplayConfig(this.pk);
    this.smoothingFactor = config.smoothingFactor;
    this.exponentialSmoothingFactor = this.pk.custom_audio_config.exponentialSmoothingFactor;
    this.showPeakFrequency = config.showPeakFrequency;
    this.peakCount = config.peakCount; // 新增：加载峰值数量
    this.frequencyRange = config.frequencyRange;
    this.decibelRange = config.decibelRange;
    
    // 加载自定义范围
    this.customFrequencyMin = config.customFrequencyMin || 16;
    this.customFrequencyMax = config.customFrequencyMax || 20000;
    this.customDecibelMin = config.customDecibelMin || -20;
    this.customDecibelMax = config.customDecibelMax || 140;
  }
  
  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 标题
      Row() {
        Text('频谱显示设置')
          .fontSize(DesignConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
        
        // 关闭按钮
        Image($r('sys.media.ohos_ic_public_cancel'))
          .width(24)
          .height(24)
          .fillColor($r('sys.color.font_secondary'))
          .onClick(() => {
            this.params?.onClose();
          })
      }
      .width('100%')
      .padding({ bottom: DesignConstants.SPACING_MD })
      
      Scroll() {
        Column({ space: DesignConstants.SPACING_LG }) {
          // 平滑设置
          this.buildSmoothingSection()
          
          // 指数平滑设置
          this.buildExponentialSmoothingSection()
          
          // 峰值显示设置
          this.buildPeakDisplaySection()
          
          // 频率范围设置
          this.buildFrequencyRangeSection()
          
          // 分贝范围设置
          this.buildDecibelRangeSection()
          
          // 应用按钮
          this.buildApplyButton()
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .padding(DesignConstants.SPACING_LG)
    .backgroundColor($r('sys.color.background_secondary'))
  }
  
  
  @Builder
  private buildSmoothingSection() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Row() {
        Text('数据平滑')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
        
        Text(`${(this.smoothingFactor * 100).toFixed(0)}%`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      
      Slider({
        value: this.smoothingFactor,
        min: 0,
        max: 1,
        step: 0.1,
        style: SliderStyle.InSet
      })
        .width('100%')
        .trackColor($r('sys.color.comp_background_tertiary'))
        .selectedColor($r('sys.color.icon_emphasize'))
        .blockColor($r('sys.color.icon_emphasize'))
        .onChange((value: number) => {
          this.smoothingFactor = value;
        })
      
      Text('平滑因子越大，频谱变化越平缓')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }
  
  @Builder
  private buildExponentialSmoothingSection() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Row() {
        Text('指数平滑')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
        
        Text(`${(this.exponentialSmoothingFactor * 100).toFixed(0)}%`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }
      .width('100%')
      
      Slider({
        value: this.exponentialSmoothingFactor,
        min: 0.05,
        max: 0.95,
        step: 0.05,
        style: SliderStyle.InSet
      })
        .width('100%')
        .trackColor($r('sys.color.comp_background_tertiary'))
        .selectedColor($r('sys.color.icon_emphasize'))
        .blockColor($r('sys.color.icon_emphasize'))
        .onChange((value: number) => {
          this.exponentialSmoothingFactor = value;
        })
      
      Text('指数平滑因子越大，频谱变化越平缓，抖动越少')
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }
  
  @Builder
  private buildPeakDisplaySection() {
    Column({ space: DesignConstants.SPACING_MD }) {
      // 显示峰值频率开关
      Row({ space: DesignConstants.SPACING_MD }) {
        Text('显示峰值频率')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(1)
        
        Toggle({ type: ToggleType.Switch, isOn: this.showPeakFrequency })
          .selectedColor($r('sys.color.icon_emphasize'))
          .switchPointColor($r('sys.color.background_primary'))
          .onChange((isOn: boolean) => {
            this.showPeakFrequency = isOn;
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      
      // 峰值数量选择
      if (this.showPeakFrequency) {
        Column({ space: DesignConstants.SPACING_SM }) {
          Row() {
            Text('峰值数量')
              .fontSize(DesignConstants.FONT_SIZE_LG)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
              .layoutWeight(1)
            
            Text(`${this.peakCount}`)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_secondary'))
          }
          .width('100%')
          
          Slider({
            value: this.peakCount,
            min: 1,
            max: 5,
            step: 1,
            style: SliderStyle.InSet
          })
            .width('100%')
            .trackColor($r('sys.color.comp_background_tertiary'))
            .selectedColor($r('sys.color.icon_emphasize'))
            .blockColor($r('sys.color.icon_emphasize'))
            .onChange((value: number) => {
              this.peakCount = Math.round(value);
            })
          
          Text('选择要显示的峰值数量（1-5个）')
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .alignSelf(ItemAlign.Start)
        }
        .width('100%')
        .padding(DesignConstants.SPACING_MD)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .borderRadius(DesignConstants.BORDER_RADIUS_LG)
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }
  
  @Builder
  private buildFrequencyRangeSection() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('频率范围')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)
      
      Column({ space: DesignConstants.SPACING_SM }) {
        Row({ space: DesignConstants.SPACING_SM }) {
          Radio({ value: FrequencyRange.FULL, group: 'frequencyRange' })
            .checked(this.frequencyRange === FrequencyRange.FULL)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.frequencyRange = FrequencyRange.FULL;
              }
            })
          
          Text('全频段 (16Hz-20kHz)')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          this.frequencyRange = FrequencyRange.FULL;
        })
        
        Row({ space: DesignConstants.SPACING_SM }) {
          Radio({ value: FrequencyRange.LOW, group: 'frequencyRange' })
            .checked(this.frequencyRange === FrequencyRange.LOW)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.frequencyRange = FrequencyRange.LOW;
              }
            })
          
          Text('低频段 (16Hz-250Hz)')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          this.frequencyRange = FrequencyRange.LOW;
        })
        
        Row({ space: DesignConstants.SPACING_SM }) {
          Radio({ value: FrequencyRange.MID, group: 'frequencyRange' })
            .checked(this.frequencyRange === FrequencyRange.MID)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.frequencyRange = FrequencyRange.MID;
              }
            })
          
          Text('中频段 (250Hz-2kHz)')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          this.frequencyRange = FrequencyRange.MID;
        })
        
        Row({ space: DesignConstants.SPACING_SM }) {
          Radio({ value: FrequencyRange.HIGH, group: 'frequencyRange' })
            .checked(this.frequencyRange === FrequencyRange.HIGH)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.frequencyRange = FrequencyRange.HIGH;
              }
            })
          
          Text('高频段 (2kHz-20kHz)')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          this.frequencyRange = FrequencyRange.HIGH;
        })
        
        Row({ space: DesignConstants.SPACING_SM }) {
          Radio({ value: FrequencyRange.CUSTOM, group: 'frequencyRange' })
            .checked(this.frequencyRange === FrequencyRange.CUSTOM)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.frequencyRange = FrequencyRange.CUSTOM;
              }
            })
          
          Text('自定义')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          this.frequencyRange = FrequencyRange.CUSTOM;
        })
      }
      
      // 自定义频率范围输入
      if (this.frequencyRange === FrequencyRange.CUSTOM) {
        Column({ space: DesignConstants.SPACING_SM }) {
          Row({ space: DesignConstants.SPACING_MD }) {
            Text('最小频率 (Hz)')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))
              .width(120)
            
            TextInput({ placeholder: '16', text: this.customFrequencyMin.toString() })
              .width(100)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .onChange((value: string) => {
                const numValue = parseFloat(value);
                if (!isNaN(numValue) && numValue >= 1 && numValue < this.customFrequencyMax) {
                  this.customFrequencyMin = numValue;
                }
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          
          Row({ space: DesignConstants.SPACING_MD }) {
            Text('最大频率 (Hz)')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))
              .width(120)
            
            TextInput({ placeholder: '20000', text: this.customFrequencyMax.toString() })
              .width(100)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .onChange((value: string) => {
                const numValue = parseFloat(value);
                if (!isNaN(numValue) && numValue > this.customFrequencyMin && numValue <= 20000) {
                  this.customFrequencyMax = numValue;
                }
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
        }
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }
  
  @Builder
  private buildDecibelRangeSection() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('分贝范围')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)
      
      Column({ space: DesignConstants.SPACING_SM }) {
        Row({ space: DesignConstants.SPACING_SM }) {
          Radio({ value: DecibelRange.AUTO, group: 'decibelRange' })
            .checked(this.decibelRange === DecibelRange.AUTO)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.decibelRange = DecibelRange.AUTO;
              }
            })
          
          Text('自动')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          this.decibelRange = DecibelRange.AUTO;
        })
        
        Row({ space: DesignConstants.SPACING_SM }) {
          Radio({ value: DecibelRange.NARROW, group: 'decibelRange' })
            .checked(this.decibelRange === DecibelRange.NARROW)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.decibelRange = DecibelRange.NARROW;
              }
            })
          
          Text('窄范围 (40-80dB)')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          this.decibelRange = DecibelRange.NARROW;
        })
        
        Row({ space: DesignConstants.SPACING_SM }) {
          Radio({ value: DecibelRange.NORMAL, group: 'decibelRange' })
            .checked(this.decibelRange === DecibelRange.NORMAL)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.decibelRange = DecibelRange.NORMAL;
              }
            })
          
          Text('正常范围 (20-100dB)')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          this.decibelRange = DecibelRange.NORMAL;
        })
        
        Row({ space: DesignConstants.SPACING_SM }) {
          Radio({ value: DecibelRange.WIDE, group: 'decibelRange' })
            .checked(this.decibelRange === DecibelRange.WIDE)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.decibelRange = DecibelRange.WIDE;
              }
            })
          
          Text('宽范围 (0-120dB)')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          this.decibelRange = DecibelRange.WIDE;
        })
        
        Row({ space: DesignConstants.SPACING_SM }) {
          Radio({ value: DecibelRange.CUSTOM, group: 'decibelRange' })
            .checked(this.decibelRange === DecibelRange.CUSTOM)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.decibelRange = DecibelRange.CUSTOM;
              }
            })
          
          Text('自定义')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .onClick(() => {
          this.decibelRange = DecibelRange.CUSTOM;
        })
      }
      
      // 自定义分贝范围输入
      if (this.decibelRange === DecibelRange.CUSTOM) {
        Column({ space: DesignConstants.SPACING_SM }) {
          Row({ space: DesignConstants.SPACING_MD }) {
            Text('最小分贝 (dB)')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))
              .width(120)
            
            TextInput({ placeholder: '-20', text: this.customDecibelMin.toString() })
              .width(100)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .onChange((value: string) => {
                const numValue = parseFloat(value);
                if (!isNaN(numValue) && numValue < this.customDecibelMax) {
                  this.customDecibelMin = numValue;
                }
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          
          Row({ space: DesignConstants.SPACING_MD }) {
            Text('最大分贝 (dB)')
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))
              .width(120)
            
            TextInput({ placeholder: '140', text: this.customDecibelMax.toString() })
              .width(100)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor($r('sys.color.font_primary'))
              .backgroundColor($r('sys.color.comp_background_tertiary'))
              .onChange((value: string) => {
                const numValue = parseFloat(value);
                if (!isNaN(numValue) && numValue > this.customDecibelMin) {
                  this.customDecibelMax = numValue;
                }
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
        }
      }
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }
  
  @Builder
  private buildApplyButton() {
    Button('应用设置')
      .width('100%')
      .height(48)
      .fontSize(DesignConstants.FONT_SIZE_MD)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_on_primary'))
      .backgroundColor($r('sys.color.icon_emphasize'))
      .borderRadius(DesignConstants.BORDER_RADIUS_MD)
      .onClick(() => {
        // 创建配置对象
        const config: SpectrumDisplayConfig = {
          smoothingFactor: this.smoothingFactor,
          showPeakFrequency: this.showPeakFrequency,
          peakCount: this.peakCount,
          frequencyRange: this.frequencyRange,
          decibelRange: this.decibelRange,
          customFrequencyMin: this.customFrequencyMin,
          customFrequencyMax: this.customFrequencyMax,
          customDecibelMin: this.customDecibelMin,
          customDecibelMax: this.customDecibelMax,
          exponentialSmoothingFactor: this.exponentialSmoothingFactor
        };
        
        // 保存指数平滑因子到custom_audio_config
        this.pk.custom_audio_config.exponentialSmoothingFactor = this.exponentialSmoothingFactor;
        
        // 应用设置
        this.params?.onSettingsApplied(config);
        this.params?.onClose();
      })
  }
}

/**
 * 频谱显示设置对话框构建器
 */
@Builder
export function SpectrumDisplaySettingsBuilder(params: SpectrumDisplaySettingsParams) {
  SpectrumDisplaySettingsDialog({ params: params })
}