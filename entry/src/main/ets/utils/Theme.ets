/*
 * 主题管理工具类
 */
interface ColorPalette {
  // 背景色
  background_primary: string;
  background_secondary: string;
  background_tertiary: string;
  
  // 文字色
  text_primary: string;
  text_secondary: string;
  text_disabled: string;
  
  // 分隔线
  divider: string;
  divider_primary: string;
  
  // 强调色
  primary: string;
  secondary: string;
  error: string;
  
  // 按钮色
  button_primary: string;
  button_secondary: string;
  button_danger: string;
  
  // 图标色
  icon_accent: string;
  icon_primary: string;
  icon_active: string;
  icon_inactive: string;
  icon_favorite: string;
  
  // 功能色
  decibel_safe: string;
  decibel_warning: string;
  decibel_danger: string;
  toggle_active: string;
}

export class Theme {
  // 颜色定义
  static colors: ColorPalette = {
    // 背景色
    background_primary: '#121212',
    background_secondary: '#1E1E1E',
    background_tertiary: '#2D2D2D',
    
    // 开关组件
    toggle_active: '#0091FF',
    
    // 文字色
    text_primary: '#E0E0E0',
    text_secondary: '#AAAAAA',
    text_disabled: '#616161',
    
    // 分隔线
    divider: '#424242',
    divider_primary: '#616161',
    
    // 强调色
    primary: '#BB86FC',
    secondary: '#03DAC6',
    error: '#CF6679',
    
    // 按钮色
    button_primary: '#BB86FC',
    button_secondary: '#424242',
    button_danger: '#CF6679',
    
    // 图标色
    icon_accent: '#03DAC6',
    icon_primary: '#E0E0E0',
    icon_active: '#BB86FC',
    icon_inactive: '#616161',
    icon_favorite: '#FFD700',
    
    // 功能色 (保持不变)
    decibel_safe: '#3EA665',
    decibel_warning: '#FFC107',
    decibel_danger: '#F44336'
  }

  // 获取当前主题颜色 - 使用switch实现类型安全访问
  static getColor(key: keyof ColorPalette): string {
    if (!Theme.colors) {
      console.error('Theme colors not initialized')
      return '#FFFFFF'
    }

    switch(key) {
      case 'background_primary': return Theme.colors.background_primary;
      case 'background_secondary': return Theme.colors.background_secondary;
      case 'background_tertiary': return Theme.colors.background_tertiary;
      case 'text_primary': return Theme.colors.text_primary;
      case 'text_secondary': return Theme.colors.text_secondary;
      case 'text_disabled': return Theme.colors.text_disabled;
      case 'divider': return Theme.colors.divider;
      case 'divider_primary': return Theme.colors.divider_primary;
      case 'primary': return Theme.colors.primary;
      case 'secondary': return Theme.colors.secondary;
      case 'error': return Theme.colors.error;
      case 'button_primary': return Theme.colors.button_primary;
      case 'button_secondary': return Theme.colors.button_secondary;
      case 'button_danger': return Theme.colors.button_danger;
      case 'icon_accent': return Theme.colors.icon_accent;
      case 'icon_primary': return Theme.colors.icon_primary;
      case 'icon_active': return Theme.colors.icon_active;
      case 'icon_inactive': return Theme.colors.icon_inactive;
      case 'icon_favorite': return Theme.colors.icon_favorite;
      case 'decibel_safe': return Theme.colors.decibel_safe;
      case 'decibel_warning': return Theme.colors.decibel_warning;
      case 'decibel_danger': return Theme.colors.decibel_danger;
      case 'toggle_active': return Theme.colors.toggle_active;
      default:
        console.warn(`Color key "${key}" not found in theme palette`);
        return '#FFFFFF';
    }
  }

  // 验证所有颜色键
  static validateColors(): boolean {
    const keys: Array<keyof ColorPalette> = [
      'background_primary', 'background_secondary', 'background_tertiary',
      'text_primary', 'text_secondary', 'text_disabled',
      'divider', 'divider_primary', 'primary', 'secondary', 'error',
      'button_primary', 'button_secondary', 'button_danger',
      'icon_accent', 'icon_primary', 'icon_active', 'icon_inactive', 'icon_favorite',
      'decibel_safe', 'decibel_warning', 'decibel_danger',
      'toggle_active'
    ]

    let allValid = true
    keys.forEach(key => {
      const color = Theme.getColor(key)
      if (color === '#FFFFFF') {
        console.error(`Invalid color for key: ${key}`)
        allValid = false
      }
    })

    return allValid
  }
}