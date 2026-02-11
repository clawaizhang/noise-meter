/**
 * 春节/马年活动主题设计常量
 * 包含红色、金色等春节传统色彩
 */

// 签文等级类型
export type SignLevel = '上上签' | '上签' | '中签';

// 签文配置接口
export interface LuckySignConfig {
  id: string;
  name: string;
  emoji: string;
  meaning: string;
  rewardDays: number;
  probability: number;
  level: SignLevel;
  blessing: string;
}

// 等级样式接口
export interface LevelStyle {
  borderColor: number;
  badgeColor: string;
  shadowColor: string;
}

export class SpringFestivalConstants {
  // ========== 春节主题颜色 ==========
  
  // 主色 - 中国红
  static readonly COLOR_CHINESE_RED: number = 0xE53935;
  static readonly COLOR_CHINESE_RED_LIGHT: number = 0xFF6F60;
  static readonly COLOR_CHINESE_RED_DARK: number = 0xAB000D;
  
  // 辅色 - 富贵金
  static readonly COLOR_GOLD: number = 0xFFD700;
  static readonly COLOR_GOLD_LIGHT: number = 0xFFFF52;
  static readonly COLOR_GOLD_DARK: number = 0xC7A500;
  
  // 背景色
  static readonly COLOR_BG_CREAM: number = 0xFFF8E7;  // 暖米色
  static readonly COLOR_BG_WARM: number = 0xFFFAF0;   // 花白
  
  // 签文等级颜色
  static readonly COLOR_SIGN_SUPREME: number = 0xFFD700;  // 上上签 - 金色
  static readonly COLOR_SIGN_GOOD: number = 0xFF8C00;     // 上签 - 橙色
  static readonly COLOR_SIGN_NORMAL: number = 0x4169E1;   // 中签 - 皇家蓝
  
  // ========== 字体大小 ==========
  static readonly FONT_SIZE_XXL: number = 28;  // 超大标题
  static readonly FONT_SIZE_XL: number = 24;   // 主标题
  static readonly FONT_SIZE_LG: number = 20;   // 副标题
  static readonly FONT_SIZE_MD: number = 16;   // 正文
  static readonly FONT_SIZE_SM: number = 14;   // 辅助文字
  static readonly FONT_SIZE_XS: number = 12;   // 最小文字
  
  // ========== 间距 ==========
  static readonly SPACING_XS: number = 4;
  static readonly SPACING_SM: number = 8;
  static readonly SPACING_MD: number = 12;
  static readonly SPACING_LG: number = 16;
  static readonly SPACING_XL: number = 24;
  static readonly SPACING_XXL: number = 32;
  
  // ========== 圆角 ==========
  static readonly BORDER_RADIUS_SM: number = 4;
  static readonly BORDER_RADIUS_MD: number = 8;
  static readonly BORDER_RADIUS_LG: number = 12;
  static readonly BORDER_RADIUS_XL: number = 16;
  static readonly BORDER_RADIUS_XXL: number = 24;
  
  // ========== 签文配置 ==========
  static readonly LUCKY_SIGNS_CONFIG: LuckySignConfig[] = [
    { 
      id: 'success_horse', 
      name: '马到成功', 
      emoji: '🐎', 
      meaning: '事业顺利，快速成功', 
      rewardDays: 28, 
      probability: 0.20, 
      level: '上上签',
      blessing: '愿您马年事业腾飞，一帆风顺！'
    },
    { 
      id: 'congrat_wealth', 
      name: '恭喜发财', 
      emoji: '🧧', 
      meaning: '财运亨通，财源广进', 
      rewardDays: 18, 
      probability: 0.20, 
      level: '上上签',
      blessing: '愿您马年财运亨通，八方来财！'
    },
    { 
      id: 'surplus_yearly', 
      name: '年年有余', 
      emoji: '🎋', 
      meaning: '生活富足，年年有余', 
      rewardDays: 16, 
      probability: 0.15, 
      level: '上签',
      blessing: '愿您马年生活美满，富足安康！'
    },
    { 
      id: 'good_luck', 
      name: '大吉大利', 
      emoji: '🍊', 
      meaning: '万事如意，吉祥顺利', 
      rewardDays: 12, 
      probability: 0.15, 
      level: '上签',
      blessing: '愿您马年吉星高照，万事顺遂！'
    },
    { 
      id: 'lucky_star', 
      name: '福星高照', 
      emoji: '🏮', 
      meaning: '福气满满，好运连连', 
      rewardDays: 10, 
      probability: 0.12, 
      level: '中签',
      blessing: '愿您马年福星高照，好运不断！'
    },
    { 
      id: 'wish_come_true', 
      name: '心想事成', 
      emoji: '🎆', 
      meaning: '愿望实现，梦想成真', 
      rewardDays: 8, 
      probability: 0.10, 
      level: '中签',
      blessing: '愿您马年心想事成，美梦成真！'
    },
    { 
      id: 'family_reunion', 
      name: '团团圆圆', 
      emoji: '🥟', 
      meaning: '家庭和睦，幸福美满', 
      rewardDays: 6, 
      probability: 0.05, 
      level: '中签',
      blessing: '愿您马年阖家欢乐，团团圆圆！'
    },
    { 
      id: 'sweet_life', 
      name: '甜甜蜜蜜', 
      emoji: '🍬', 
      meaning: '生活甜蜜，感情美满', 
      rewardDays: 5, 
      probability: 0.03, 
      level: '中签',
      blessing: '愿您马年生活甜蜜，幸福安康！'
    }
  ];
  
  // ========== 动画时长 ==========
  static readonly ANIMATION_DURATION_SHAKE: number = 500;      // 摇晃动画
  static readonly ANIMATION_DURATION_REVEAL: number = 800;     // 揭示动画
  static readonly ANIMATION_DURATION_CELEBRATION: number = 1500; // 庆祝动画
  static readonly ANIMATION_DURATION_PARTICLE: number = 2000;  // 粒子动画
  
  // ========== 震动反馈强度 ==========
  static readonly HAPTIC_LIGHT: number = 10;   // 轻微震动
  static readonly HAPTIC_MEDIUM: number = 30;  // 中等震动
  static readonly HAPTIC_HEAVY: number = 50;   // 强烈震动
  static readonly HAPTIC_SUCCESS: number = 40; // 成功震动

  // ========== 等级样式 ==========
  static getLevelStyle(level: SignLevel): LevelStyle {
    if (level === '上上签') {
      return {
        borderColor: SpringFestivalConstants.COLOR_SIGN_SUPREME,
        badgeColor: '#FFD700',
        shadowColor: 'rgba(255, 215, 0, 0.4)'
      };
    } else if (level === '上签') {
      return {
        borderColor: SpringFestivalConstants.COLOR_SIGN_GOOD,
        badgeColor: '#FF8C00',
        shadowColor: 'rgba(255, 140, 0, 0.3)'
      };
    } else {
      return {
        borderColor: SpringFestivalConstants.COLOR_SIGN_NORMAL,
        badgeColor: '#4169E1',
        shadowColor: 'rgba(65, 105, 225, 0.2)'
      };
    }
  }
}
