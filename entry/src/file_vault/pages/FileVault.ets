import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { PhotoAccessHelperService } from '../services/PhotoAccessHelperService';

@Builder
function FileVaultBuilder() {
  FileVault()
}
@ComponentV2
export struct FileVault {
  @Local private notes: Array<NoteInfo> = [];
  @Local private currentIndex: number = 0;
  private context = getContext(this) as common.UIAbilityContext;
  private photoService = new PhotoAccessHelperService(this.context);

  // 创建新笔记
  private createNote(title: string, content: string) {
    const newNote = new NoteInfo(
      Date.now().toString(),
      title,
      content
    );
    this.notes = [newNote, ...this.notes];
  }

  build() {
    Column() {
      // 内容区域
      Stack() {
        if (this.currentIndex === 0) {
          // 首页 - 笔记列表
          Column() {
            // 笔记列表
            List() {
              ForEach(this.notes, (note:NoteInfo) => {
                ListItem() {
                  Column() {
                    Text(note.title)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .margin({ bottom: 8 });
                    
                    Text(note.content)
                      .fontSize(14)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis });
                  }
                  .padding(16)
                  .width('100%')
                  .backgroundColor(Color.White)
                  .borderRadius(8)
                  .margin({ bottom: 8 })
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/NoteDetail',
                      params: {
                        noteId: note.id,
                        noteTitle: note.title,
                        noteContent: note.content
                      }
                    });
                  });
                }
              });
            }
            .layoutWeight(1)
          }
        } else if (this.currentIndex === 1) {
          // 发布页面
          Column() {
            // TODO: 添加笔记表单
            Text('发布新笔记')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 16 });
          }
        } else {
          // 个人中心
          Column() {
            Text('个人中心')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 16 });
          }
        }
      }
      .layoutWeight(1)

      // 底部Tab栏
      Row() {
        // 首页
        Column() {
          Image($r('app.media.ic_home'))
            .width(24)
            .height(24)
            .fillColor(this.currentIndex === 0 ? '#007AFF' : '#999999')
          Text('首页')
            .fontSize(12)
            .fontColor(this.currentIndex === 0 ? '#007AFF' : '#999999');
        }
        .layoutWeight(1)
        .onClick(() => {
          this.currentIndex = 0;
        });

        // 发布
        Column() {
          Image($r('app.media.ic_add'))
            .width(24)
            .height(24)
            .fillColor(this.currentIndex === 1 ? '#007AFF' : '#999999')
          Text('发布')
            .fontSize(12)
            .fontColor(this.currentIndex === 1 ? '#007AFF' : '#999999');
        }
        .layoutWeight(1)
        .onClick(async () => {
          try {
            // 使用PhotoAccessHelperService选择文件
            const selectedFiles = await this.photoService.selectFiles();
            
            if (selectedFiles.length > 0) {
              
              // 跳转到发布页面并传递文件
              router.pushUrl({
                url: 'pages/PublishPage',
                params: {
                  files: JSON.stringify(selectedFiles)
                }
              });
            }
          } catch (err) {
            console.error('Failed to pick files:', err);
          }
        });

        // 我
        Column() {
          Image($r('app.media.ic_user'))
            .width(24)
            .height(24)
            .fillColor(this.currentIndex === 2 ? '#007AFF' : '#999999')
          Text('我')
            .fontSize(12)
            .fontColor(this.currentIndex === 2 ? '#007AFF' : '#999999');
        }
        .layoutWeight(1)
        .onClick(() => {
          this.currentIndex = 2;
        });
      }
      .width('100%')
      .height(56)
      .backgroundColor(Color.White)
      .border({ width: 1, color: '#F5F5F5' });
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5');
  }
}

class NoteInfo {
  id: string;
  title: string;
  content: string;
  createTime: number;

  constructor(id: string, title: string, content: string) {
    this.id = id;
    this.title = title;
    this.content = content;
    this.createTime = Date.now();
  }
}
