/**
 * 通用标题组件
 * @param title - 标题文本
 * @param fontSize - 字体大小，默认24
 * @param marginTop - 上边距，默认20
 * @param marginBottom - 下边距，默认20
 */
@Component
export struct HeaderTitle {
  @Prop title: string = '';
  @Prop fontSize: number = 24;
  @Prop marginTop: number = 20;
  @Prop marginBottom: number = 20;

  build() {
    Row() {
      Text(this.title)
        .fontSize(this.fontSize)
        .fontWeight(FontWeight.Bold)
    }
    .margin({ top: this.marginTop, bottom: this.marginBottom })
  }
} 