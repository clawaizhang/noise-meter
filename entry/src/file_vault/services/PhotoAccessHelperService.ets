import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import common from '@ohos.app.ability.common';

export class FileInfo {
  uri: string;
  type: string;
  name: string;

  constructor(uri: string, type: string, name: string) {
    this.uri = uri;
    this.type = type;
    this.name = name;
  }
}

export class PhotoAccessHelperService {
  private context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  /**
   * 选择图片和视频文件
   * @param maxSelectNumber 最大选择数量，默认5
   * @returns 选择的文件信息列表
   */
  async selectFiles(maxSelectNumber: number = 5): Promise<Array<FileInfo>> {
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE;
      photoSelectOptions.maxSelectNumber = maxSelectNumber;

      const photoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const photoSelectResult = await photoViewPicker.select(photoSelectOptions);

      if (photoSelectResult && photoSelectResult.photoUris.length > 0) {
        return photoSelectResult.photoUris.map(uri => 
          new FileInfo(uri, this.getFileType(uri), this.getFileName(uri))
        );
      }
      return [];
    } catch (err) {
      console.error(`Failed to select files, code: ${(err as BusinessError).code}, message: ${(err as BusinessError).message}`);
      throw new Error(err);
    }
  }

  private getFileType(uri: string): string {
    return uri.endsWith('.mp4') || uri.endsWith('.mov') ? 'video' : 'image';
  }

  private getFileName(uri: string): string {
    const segments = uri.split('/');
    return segments[segments.length - 1];
  }
}
