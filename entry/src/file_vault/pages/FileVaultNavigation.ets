import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { PhotoAccessHelperService } from '../services/PhotoAccessHelperService';
import { CustomTitleBar } from '../../library/ets/components/common/CustomTitleBar';

@Builder
function FileVaultBuilder() {
  FileVault()
}

@ComponentV2
export struct FileVault {
  @Local private notes: Array<NoteInfo> = [];
  @Provider() private navStack: NavPathStack = new NavPathStack();
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

  @Builder
  TabBuilder(title: string, icon: Resource, index: number) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? '#007AFF' : '#999999')
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? '#007AFF' : '#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Navigation(this.navStack) {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          Column() {
            CustomTitleBar({
              title: '小蓝书',
            })

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
                    this.navStack.pushDestinationByName('NoteDetail', {
                      noteId: note.id,
                      noteTitle: note.title,
                      noteContent: note.content
                    });
                  });
                }
              });
            }
            .layoutWeight(1)
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#F5F5F5')
        }
        .tabBar(this.TabBuilder('首页', $r('app.media.ic_home'), 0))

        TabContent() {
          Column() {
            CustomTitleBar({
              title: '创作',
              buttons: []
            })
            
            Text('开始创作')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 16 });
          }
        }
        .tabBar(this.TabBuilder('创作', $r('app.media.ic_add'), 1))

        TabContent() {
          Column() {
            CustomTitleBar({
              title: '个人中心',
              buttons: []
            })
            
            Text('个人中心')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 16 });
          }
        }
        .tabBar(this.TabBuilder('我', $r('app.media.ic_user'), 2))
      }
      .scrollable(false)
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .width('100%')
      .height('100%')
      .barHeight(56)
      .barMode(BarMode.Fixed)
      .animationDuration(0)
    }
    .hideTitleBar(true)
    .hideBackButton(true)
    .backgroundColor('#F5F5F5')
    .navBarPosition(NavBarPosition.Start)
    .hideToolBar(true)
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
