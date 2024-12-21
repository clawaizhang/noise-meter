@Component
export struct PermissionError {
  @Prop errorMessage: string

  build() {
    if (this.errorMessage !== '') {
      Text(this.errorMessage)
        .fontSize(16)
        .fontColor('#F44336')
        .margin({ bottom: 20 })
    }
  }
} 