import photoAccessHelper from '@ohos.file.photoAccessHelper';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';

@Component
export struct MainPage {
  @State files: Array<FileInfo> = [];
  private context = getContext(this) as common.UIAbilityContext;

  // 导入文件
  async importFile() {
    try {
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const options: photoAccessHelper.PhotoSelectOptions = {
        maxSelectNumber: 1,
        isEditSupported: false,
        isOriginalSupported: true,
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE
      };
      const result = await photoPicker.select(options);
      if (result && result.photoUris && result.photoUris.length > 0) {
        // TODO: 复制文件到应用私有目录
        // TODO: 加密文件
        // TODO: 保存文件信息到数据库
      }
    } catch (error) {
      console.error('导入文件失败:', error);
    }
  }

  @Builder
  EmptyState() {
    Column() {
      Image($r('app.media.ic_empty'))
        .width(120)
        .height(120)
        .fillColor('#CCCCCC')
        .margin({ bottom: 16 })
      Text('暂无文件')
        .fontSize(16)
        .fontColor('#999999')
      Text('点击右上角的按钮导入文件')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('文件保密柜')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
        Blank()
        Button() {
          Image($r('app.media.ic_import'))
            .width(24)
            .height(24)
            .fillColor('#333333')
        }
        .type(ButtonType.Circle)
        .width(40)
        .height(40)
        .backgroundColor('#F5F5F5')
        .onClick(() => {
          this.importFile();
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      // 文件列表或空状态
      if (this.files.length > 0) {
        List() {
          ForEach(this.files, (file: FileInfo) => {
            ListItem() {
              // TODO: 实现文件列表项UI
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
      } else {
        this.EmptyState()
      }
    }
    .width('100%')
    .height('100%')
  }
}

class FileInfo {
  id: string;
  name: string;
  path: string;
  size: number;
  type: string;
  createTime: number;

  constructor(id: string, name: string, path: string, size: number, type: string) {
    this.id = id;
    this.name = name;
    this.path = path;
    this.size = size;
    this.type = type;
    this.createTime = new Date().getTime();
  }
} 