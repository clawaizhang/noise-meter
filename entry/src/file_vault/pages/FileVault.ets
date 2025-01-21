import photoAccessHelper from '@ohos.file.photoAccessHelper';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import router from '@ohos.router';

@Builder
function FileVaultBuilder() {
  FileVault()
}

@Component
export struct FileVault {
  @State notes: Array<NoteInfo> = [];
  private context = getContext(this) as common.UIAbilityContext;

  // 创建新笔记
  async createNote() {
    try {
      const newNote = new NoteInfo(
        Date.now().toString(),
        '新笔记',
        '在这里写下你的想法...'
      );
      this.notes = [...this.notes, newNote];
    } catch (error) {
      console.error('创建笔记失败:', error);
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
      Text('暂无笔记')
        .fontSize(16)
        .fontColor('#999999')
      Text('点击右上角的按钮创建新笔记')
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
        Text('小蓝书')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
        Blank()
        Button() {
          Image($r('app.media.ic_pin'))
            .width(24)
            .height(24)
            .fillColor('#333333')
        }
        .type(ButtonType.Circle)
        .width(40)
        .height(40)
        .backgroundColor('#F5F5F5')
        .onClick(() => {
          this.createNote();
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      // 文件列表或空状态
      if (this.notes.length > 0) {
        List() {
          ForEach(this.notes, (note: NoteInfo) => {
            ListItem() {
              Column() {
                // 封面图片
                if (note.images.length > 0) {
                  Image(note.images[0])
                    .width('100%')
                    .height(200)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(8)
                } else {
                  Image($r('app.media.ic_empty'))
                    .width('100%')
                    .height(200)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(8)
                    .backgroundColor('#F5F5F5')
                }

                // 标题和内容
                Column() {
                  Text(note.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .margin({ bottom: 8 })
                  
                  Text(note.content)
                    .fontSize(14)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .fontColor('#666666')
                }
                .padding(12)

                // 标签和操作按钮
                Row() {
                  // 标签
                  if (note.tags.length > 0) {
                    ForEach(note.tags, (tag: string) => {
                      Text(`#${tag}`)
                        .fontSize(12)
                        .fontColor('#666666')
                        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                        .backgroundColor('#F5F5F5')
                        .borderRadius(12)
                        .margin({ right: 8 })
                    })
                  }

                  Blank()

                  // 收藏按钮
                  Button() {
                    Image($r('app.media.ic_favorite'))
                      .width(16)
                      .height(16)
                      .fillColor(note.isFavorite ? '#FF3B30' : '#CCCCCC')
                  }
                  .type(ButtonType.Circle)
                  .width(32)
                  .height(32)
                  .backgroundColor('#FFFFFF')
                  .onClick(() => {
                    note.isFavorite = !note.isFavorite;
                    this.notes = [...this.notes];
                  })
                }
                .padding({ left: 12, right: 12, bottom: 12 })
              }
              .width('100%')
              .backgroundColor(Color.White)
              .borderRadius(8)
              .margin({ top: 8, bottom: 8 })
              .shadow({ radius: 4, color: '#00000010', offsetX: 0, offsetY: 2 })
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/NoteDetail',
                  params: {
                    noteId: note.id,
                    noteTitle: note.title,
                    noteContent: note.content
                  }
                });
              })
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

class NoteInfo {
  id: string;
  title: string;
  content: string;
  images: Array<string> = [];
  tags: Array<string> = [];
  isFavorite: boolean = false;
  createTime: number;
  updateTime: number;

  constructor(id: string, title: string, content: string) {
    this.id = id;
    this.title = title;
    this.content = content;
    this.createTime = new Date().getTime();
    this.updateTime = this.createTime;
  }
}
