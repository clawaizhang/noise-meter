import { common } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { componentSnapshot } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';

export class ScreenshotUtils {
  /**
   * 截图并分享
   * @param context UIAbility上下文
   * @param uiContext UIContext
   * @param componentId 要截图的组件ID
   * @param fileName 保存的文件名
   * @param shareTitle 分享标题
   * @param shareDescription 分享描述
   */
  static async captureAndShare(
    context: common.UIAbilityContext,
    uiContext: UIContext,
    componentId: string,
    fileName: string,
    shareTitle: string,
    shareDescription: string
  ): Promise<void> {
    try {
      const filePath = context.tempDir + '/' + fileName;

      // 获取截图
      const pixmap = await uiContext.getComponentSnapshot().get(componentId, {
        scale: 2,
        waitUntilRenderFinished: true
      });

      // 编码图片
      const imagePacker = image.createImagePacker();
      const packOptions: image.PackingOption = {
        format: "image/jpeg",
        quality: 100
      };
      const data = await imagePacker.packToData(pixmap, packOptions);

      // 保存文件
      const file = await fileIo.open(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
      await fileIo.write(file.fd, data);

      // 设置分享数据
      const utdTypeId = utd.getUniformDataTypeByFilenameExtension('.jpg', utd.UniformDataType.IMAGE);
      const shareData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath),
        title: shareTitle,
        description: shareDescription,
      });

      // 分享
      const controller = new systemShare.ShareController(shareData);
      await controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DETAIL,
      });
      console.info('分享成功');
    } catch (error) {
      console.error(`分享失败: code=${error.code}, message=${error.message}`);
      throw new Error(error);
    }
  }
}