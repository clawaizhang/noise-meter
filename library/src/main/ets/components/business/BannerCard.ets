import router from '@ohos.router';

@Component
export struct BannerCard {
  private title: string = '广告标题'
  private description: string = '广告描述文本'
  private imageUrl: string = '/common/images/default_banner.png'
  private onItemClick?: () => void

  build() {
    Column() {
      Row() {
        Image(this.imageUrl)
          .width(120)
          .height(80)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
        
        Column() {
          Text(this.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 4 })
          
          Text(this.description)
            .fontSize(14)
            .fontColor('#666666')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height(96)
      .padding(8)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .onClick(() => {
        if (this.onItemClick) {
          this.onItemClick()
        }
      })
    }
    .width('100%')
    .shadow({ radius: 12, color: '#1A000000', offsetY: 2 })
  }
} 