import router from '@ohos.router';
import common from '@ohos.app.ability.common';

@Component
export struct NoteDetail {
  private noteId: string = '';
  private context = getContext(this) as common.UIAbilityContext;
  @State private noteContent: string = '加载中...';
  @State private noteTitle: string = '';

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>;
    this.noteId = params?.noteId || '';
    this.noteTitle = params?.noteTitle || '无标题';
    this.noteContent = params?.noteContent || '无内容';
  }

  build() {
    Column() {
      // 返回按钮
      Row() {
        Button() {
          Image($r('app.media.ic_back'))
            .width(24)
            .height(24)
            .fillColor('#333333')
        }
        .type(ButtonType.Circle)
        .width(40)
        .height(40)
        .backgroundColor('#F5F5F5')
        .onClick(() => {
          router.back();
        })

        Text('返回')
          .fontSize(16)
          .fontColor('#333333')
          .margin({ left: 8 })
      }
      .width('100%')
      .padding(16)
      .alignItems(VerticalAlign.Center)

      // 笔记内容
      Scroll() {
        Column() {
          Text(this.noteTitle)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ bottom: 16 })
          
          Text(this.noteContent)
            .fontSize(16)
            .fontColor('#666666')
            .width('100%')
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
