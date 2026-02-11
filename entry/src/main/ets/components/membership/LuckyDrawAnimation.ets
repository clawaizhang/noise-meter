/**
 * 马年抽签动画组件
 * 实现签筒摇晃、签文飞出的仪式感动画
 */

import { SpringFestivalConstants, SignLevel, LevelStyle } from '../../constants/SpringFestivalConstants';
import { LuckySign } from '../../services/MembershipRewardService';

// 动画状态
enum DrawAnimationState {
  IDLE = 'idle',           // 初始状态
  SHAKING = 'shaking',     // 摇晃中
  REVEALING = 'revealing', // 揭示中
  REVEALED = 'revealed'    // 已揭示
}

export interface LuckyDrawAnimationProps {
  luckySign: LuckySign;  // 抽中的签文
}

@Builder
export function LuckyDrawAnimationBuilder(props: LuckyDrawAnimationProps) {
  LuckyDrawAnimation({ luckySign: props.luckySign });
}

@Component
export struct LuckyDrawAnimation {
  @Prop luckySign: LuckySign;
  
  @State private animationState: DrawAnimationState = DrawAnimationState.IDLE;
  @State private shakeAngle: number = 0;
  @State private tubeOpacity: number = 1;
  @State private signScale: number = 0;
  @State private signOpacity: number = 0;
  @State private signTranslateY: number = 100;
  @State private glowOpacity: number = 0;
  @State private particleOpacity: number = 0;
  @State private blessingOpacity: number = 0;
  
  aboutToAppear() {
    this.startAnimation();
  }
  
  /**
   * 启动完整动画序列
   */
  private async startAnimation() {
    // 阶段1：摇晃动画（0-800ms）
    this.animationState = DrawAnimationState.SHAKING;
    this.startShakeAnimation();
    
    await this.delay(800);
    
    // 阶段2：揭示动画（800-1800ms）
    this.animationState = DrawAnimationState.REVEALING;
    this.stopShakeAnimation();
    this.startRevealAnimation();
    
    await this.delay(1000);
    
    // 阶段3：完成
    this.animationState = DrawAnimationState.REVEALED;
    this.blessingOpacity = 1;
    
    // 动画完成，等待外部控制关闭弹窗
    await this.delay(1000);
  }
  
  /**
   * 启动摇晃动画
   */
  private startShakeAnimation() {
    this.shakeAngle = -15;
    this.triggerHaptic(SpringFestivalConstants.HAPTIC_MEDIUM);
  }
  
  /**
   * 停止摇晃动画
   */
  private stopShakeAnimation() {
    this.shakeAngle = 0;
    this.tubeOpacity = 0.3;
  }
  
  /**
   * 启动揭示动画
   */
  private startRevealAnimation() {
    this.signScale = 1;
    this.signOpacity = 1;
    this.signTranslateY = 0;
    this.glowOpacity = 0.6;
    this.particleOpacity = 1;
    
    this.triggerHaptic(SpringFestivalConstants.HAPTIC_SUCCESS);
  }
  
  /**
   * 触发震动反馈
   */
  private triggerHaptic(intensity: number) {
    // 震动反馈在 HarmonyOS 上使用 vibrator API
    // 这里简化处理，实际项目中可以接入原生震动
    console.info(`[抽签动画] 触发震动反馈，强度: ${intensity}`);
  }
  
  /**
   * 延迟函数
   */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
  
  /**
   * 获取签文等级对应的样式
   */
  private getSignLevelStyle(level: string): LevelStyle {
    return SpringFestivalConstants.getLevelStyle(level as SignLevel);
  }
  
  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 背景光晕效果
      if (this.animationState !== DrawAnimationState.IDLE) {
        Column()
          .width(300)
          .height(300)
          .backgroundColor(this.getSignLevelStyle(this.luckySign.level).borderColor)
          .opacity(this.glowOpacity)
          .borderRadius(150)
          .blur(60)
          .animation({
            duration: 1000,
            curve: Curve.EaseInOut,
            iterations: -1,
            playMode: PlayMode.Alternate
          })
      }
      
      // 签筒（摇晃阶段显示）
      if (this.animationState === DrawAnimationState.SHAKING || 
          this.animationState === DrawAnimationState.IDLE) {
        this.buildSignTube()
      }
      
      // 签文卡片（揭示阶段显示）
      if (this.animationState !== DrawAnimationState.IDLE &&
          this.animationState !== DrawAnimationState.SHAKING) {
        this.buildSignCard()
      }
      
      // 粒子特效（上上签专属）
      if (this.luckySign.level === '上上签' && this.particleOpacity > 0) {
        this.buildParticleEffect()
      }
    }
    .width('100%')
    .height(400)
  }
  
  /**
   * 构建签筒
   */
  @Builder
  private buildSignTube() {
    Column({ space: SpringFestivalConstants.SPACING_SM }) {
      // 签筒盖
      Row()
        .width(100)
        .height(20)
        .backgroundColor('#8B4513')
        .borderRadius(10)
      
      // 签筒主体
      Column({ space: SpringFestivalConstants.SPACING_XS }) {
        // 装饰纹
        ForEach([1, 2, 3], (index: number) => {
          Row()
            .width(80)
            .height(2)
            .backgroundColor(SpringFestivalConstants.COLOR_GOLD)
            .opacity(0.6)
        }, (index: number) => index.toString())
      }
      .width(90)
      .height(120)
      .backgroundColor('#A0522D')
      .borderRadius(8)
      .justifyContent(FlexAlign.Center)
      
      // 晃动提示
      Text('🎋')
        .fontSize(32)
        .margin({ top: -80 })
        .rotate({ angle: this.shakeAngle })
        .animation({
          duration: 100,
          curve: Curve.Linear,
          iterations: 8,
          playMode: PlayMode.Alternate
        })
    }
    .opacity(this.tubeOpacity)
    .animation({
      duration: 300,
      curve: Curve.EaseInOut
    })
  }
  
  /**
   * 构建签文卡片
   */
  @Builder
  private buildSignCard() {
    Column({ space: SpringFestivalConstants.SPACING_MD }) {
      // 等级徽章
      Text(this.luckySign.level)
        .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .padding({ left: 12, right: 12, top: 4, bottom: 4 })
        .backgroundColor(this.getSignLevelStyle(this.luckySign.level).badgeColor)
        .borderRadius(12)
        .shadow({
          radius: 4,
          color: this.getSignLevelStyle(this.luckySign.level).shadowColor
        })
      
      // 签文主体卡片
      Column({ space: SpringFestivalConstants.SPACING_LG }) {
        // Emoji
        Text(this.luckySign.emoji)
          .fontSize(64)
        
        // 签文名称
        Text(this.luckySign.name)
          .fontSize(SpringFestivalConstants.FONT_SIZE_XL)
          .fontWeight(FontWeight.Bold)
          .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED_DARK)
        
        // 寓意
        Text(this.luckySign.meaning)
          .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
          .fontColor('#666666')
        
        // 分隔线
        Row()
          .width(120)
          .height(2)
          .backgroundColor(SpringFestivalConstants.COLOR_GOLD)
          .margin({ top: 8, bottom: 8 })
        
        // 奖励天数
        Row({ space: 4 }) {
          Text('获得')
            .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
            .fontColor('#666666')
          
          Text(`${this.luckySign.rewardDays}`)
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
          
          Text('天会员')
            .fontSize(SpringFestivalConstants.FONT_SIZE_MD)
            .fontColor('#666666')
        }
        .justifyContent(FlexAlign.Center)
      }
      .width(240)
      .padding(SpringFestivalConstants.SPACING_XL)
      .backgroundColor(Color.White)
      .borderRadius(SpringFestivalConstants.BORDER_RADIUS_XL)
      .border({
        width: 3,
        color: this.getSignLevelStyle(this.luckySign.level).borderColor
      })
      .shadow({
        radius: 16,
        color: this.getSignLevelStyle(this.luckySign.level).shadowColor,
        offsetY: 8
      })
      
      // 祝福语（动画完成后显示）
      if (this.blessingOpacity > 0) {
        Text(this.getBlessingText(this.luckySign.id))
          .fontSize(SpringFestivalConstants.FONT_SIZE_SM)
          .fontColor(SpringFestivalConstants.COLOR_CHINESE_RED)
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .opacity(this.blessingOpacity)
          .animation({
            duration: 500,
            curve: Curve.EaseIn
          })
      }
    }
    .scale({ x: this.signScale, y: this.signScale })
    .opacity(this.signOpacity)
    .translate({ y: this.signTranslateY })
    .animation({
      duration: 800,
      curve: Curve.EaseOut
    })
  }
  
  /**
   * 构建粒子特效（上上签专属）
   */
  @Builder
  private buildParticleEffect() {
    Stack() {
      // 金色粒子
      ForEach([1, 2, 3, 4, 5, 6], (index: number) => {
        Text(this.getParticleEmoji(index))
          .fontSize(this.getParticleSize(index))
          .position({
            x: this.getParticleX(index),
            y: this.getParticleY(index)
          })
          .opacity(this.particleOpacity)
          .animation({
            duration: 1000 + index * 200,
            curve: Curve.EaseInOut,
            iterations: -1,
            playMode: PlayMode.Alternate
          })
      }, (index: number) => index.toString())
    }
    .width(300)
    .height(300)
  }
  
  /**
   * 获取粒子表情
   */
  private getParticleEmoji(index: number): string {
    const emojis: string[] = ['✨', '🌟', '⭐', '💫', '🎊', '🎉'];
    return emojis[index - 1] || '✨';
  }
  
  /**
   * 获取粒子大小
   */
  private getParticleSize(index: number): number {
    const sizes: number[] = [20, 16, 24, 18, 22, 20];
    return sizes[index - 1] || 20;
  }
  
  /**
   * 获取粒子X位置
   */
  private getParticleX(index: number): number {
    const positions: number[] = [50, 150, 250, 80, 200, 120];
    return positions[index - 1] || 100;
  }
  
  /**
   * 获取粒子Y位置
   */
  private getParticleY(index: number): number {
    const positions: number[] = [50, 80, 60, 150, 140, 200];
    return positions[index - 1] || 100;
  }
  
  /**
   * 获取祝福语
   */
  private getBlessingText(signId: string): string {
    const config = SpringFestivalConstants.LUCKY_SIGNS_CONFIG.find(c => c.id === signId);
    return config?.blessing || '祝您马年大吉！';
  }
}
