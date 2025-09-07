import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';

@ComponentV2
export struct ImageRaw {
  @Param @Require image: string;
  @Local pixelMapImg: PixelMap | undefined = undefined;
  private context = getContext(this);

  aboutToAppear() {
    // 获取文件内容
    this.context.resourceManager.getRawFileContent(this.image, (_err, value) => {
      // 这里读取到文件内容可以进行下一步操作
      let imgData: ArrayBufferLike = value.buffer;
      console.info(`request image success, size: ${imgData.byteLength}`);
      let imgSource: image.ImageSource = image.createImageSource(imgData);

      class sizeTmp {
        height: number = 0;
        width: number = 0;
      }

      let options: Record<string, number | boolean | sizeTmp> = {
        'alphaType': 0,
        'editable': false,
        'pixelFormat': 3,
        'scaleMode': 1,
        'size': { height: 0, width: 0 }
      }
      imgSource.createPixelMap(options).then((pixelMap: PixelMap) => {
        console.error('image createPixelMap success');
        this.pixelMapImg = pixelMap;
        imgSource.release();
      }).catch(() => {
        imgSource.release();
      })
    });
  }

  build() {
    Image(this.pixelMapImg)
      .alt($r('app.media.ic_video'))
      .objectFit(ImageFit.Contain)
      .borderRadius(12)
  }
}