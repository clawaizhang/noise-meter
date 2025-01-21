import router from '@ohos.router';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';

@ComponentV2
export struct PublishPage {
  @Local private files: Array<FileInfo> = [];
  @Local private description: string = '';
  private context = getContext(this) as common.UIAbilityContext;

  aboutToAppear() {
    const params = router.getParams();
    if (params && params.files) {
      this.files = JSON.parse(params.files);
    }
  }

  build() {
    Column() {
      // 文件预览区域
      Scroll() {
        Grid() {
          ForEach(this.files, (file: FileInfo) => {
            GridItem() {
              Column() {
                if (file.type === 'image') {
                  Image(file.uri)
                    .width(100)
                    .height(100)
                    .objectFit(ImageFit.Cover);
                } else if (file.type === 'video') {
                  Video(file.uri)
                    .width(100)
                    .height(100)
                    .controls(false);
                }
              }
              .padding(8)
              .backgroundColor('#F5F5F5')
              .borderRadius(8)
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .padding(16)
      }
      .layoutWeight(1)

      // 描述输入框
      TextArea({ text: this.description })
        .placeholder('添加描述...')
        .height(100)
        .width('90%')
        .margin({ top: 16 })
        .onChange((value: string) => {
          this.description = value;
        })

      // 发布按钮
      Button('发布')
        .width('90%')
        .margin(16)
        .onClick(() => {
          this.publish();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  private publish() {
    // TODO: 实现发布逻辑
    console.log('发布内容:', {
      files: this.files,
      description: this.description
    });
    router.back();
  }
}

interface FileInfo {
  uri: string;
  type: 'image' | 'video';
  name: string;
  size: number;
  lastModified: number;
}

function getFileTypeFromUri(uri: string): 'image' | 'video' {
  const extension = uri.split('.').pop()?.toLowerCase();
  const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  const videoExtensions = ['mp4', 'mov', 'avi', 'mkv'];
  
  if (imageExtensions.includes(extension || '')) {
    return 'image';
  }
  if (videoExtensions.includes(extension || '')) {
    return 'video';
  }
  return 'image'; // 默认处理为图片
}
