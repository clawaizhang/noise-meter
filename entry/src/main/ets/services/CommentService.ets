import { commentManager } from '@kit.AppGalleryKit';
import { deviceInfo, BusinessError } from '@kit.BasicServicesKit';
import { common, Want } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';

const TAG = 'CommentService';
const DOMAIN = 0x0000;

/**
 * 评论服务类
 * 提供统一的评论功能，根据设备版本自动选择使用应用内评论或应用市场评论
 */
export class CommentService {
  private static instance: CommentService;

  private constructor() {
    // 私有构造函数，确保单例模式
  }

  /**
   * 获取评论服务实例
   * @returns CommentService 实例
   */
  public static getInstance(): CommentService {
    if (!CommentService.instance) {
      CommentService.instance = new CommentService();
    }
    return CommentService.instance;
  }

  /**
   * 显示评论对话框
   * 根据设备版本自动选择使用应用内评论或应用市场评论
   * @param context 应用上下文
   * @returns Promise<void>
   */
  public async showCommentDialog(context: common.UIAbilityContext): Promise<void> {
    try {
      // 检查设备版本，大于等于60000使用应用内评论
      if (deviceInfo.distributionOSApiVersion >= 60000) {
        await this.showInAppCommentDialog(context);
      } else {
        await this.showAppStoreRating(context);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `显示评论对话框失败: ${error instanceof Error ? error.message : String(error)}`);
      throw new Error(`无法显示评论对话框: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 显示应用内评论对话框
   * @param context 应用上下文
   * @returns Promise<void>
   */
  private async showInAppCommentDialog(context: common.UIAbilityContext): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, '使用应用内评论功能');

      if (canIUse("SystemCapability.AppGalleryService.Distribution.Comment")) {
        await commentManager.showCommentDialog(context);
      } else {
        // Fallback for unsupported SystemCapability
      }
      
      hilog.info(DOMAIN, TAG, '应用内评论对话框显示成功');
    } catch (error) {
      const businessError = error as BusinessError<Object>;
      hilog.error(DOMAIN, TAG, `应用内评论失败, Code: ${businessError.code}, message: ${businessError.message}`);
      
      // 如果应用内评论失败，回退到应用市场评论
      hilog.info(DOMAIN, TAG, '应用内评论失败，回退到应用市场评论');
      await this.showAppStoreRating(context);
    }
  }

  /**
   * 显示应用市场评论页面
   * @param context 应用上下文
   * @param appId 应用ID，默认为noise_meter_pro
   * @returns Promise<void>
   */
  private async showAppStoreRating(context: common.UIAbilityContext, appId: string = 'yu.zhang.myapplication.noise_meter_pro'): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, `使用应用市场评论功能，应用ID: ${appId}`);
      
      const want: Want = {
        action: 'ohos.want.action.appdetail',
        uri: `store://appgallery.huawei.com/app/detail?id=${appId}&action=write-review`
      };
      
      await context.startAbility(want);
      
      hilog.info(DOMAIN, TAG, '应用市场评论页面启动成功');
    } catch (error) {
      const businessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, `应用市场评论失败, Code: ${businessError.code}, message: ${businessError.message}`);
      throw new Error(`无法启动应用市场评论页面: ${businessError.message}`);
    }
  }

  /**
   * 检查是否支持应用内评论
   * @returns boolean 是否支持应用内评论
   */
  public isInAppCommentSupported(): boolean {
    return deviceInfo.distributionOSApiVersion >= 60000;
  }

  /**
   * 获取当前设备版本信息
   * @returns 设备版本信息
   */
  public getDeviceVersionInfo(): string {
    return `API版本: ${deviceInfo.distributionOSApiVersion}, 支持应用内评论: ${this.isInAppCommentSupported()}`;
  }
}