@Component
export struct ControlButton {
  @Prop isRecording: boolean
  @Prop hasPermission: boolean
  onToggleRecording: () => void = () => {}

  build() {
    Button() {
      Text(this.isRecording ? '停止测量' : '开始测量')
        .fontSize(18)
        .fontColor(Color.White)
    }
    .width(200)
    .height(50)
    .backgroundColor(this.isRecording ? '#FF4081' : '#2196F3')
    .enabled(this.hasPermission)
    .opacity(this.hasPermission ? 1 : 0.5)
    .onClick(this.onToggleRecording)
    .margin({ bottom: 20 })
  }
} 