import { advertising, AutoAdComponent } from '@kit.AdsKit'

@Component
export struct AdView {
  build() {
    AutoAdComponent({
      adParam: {
        adId: 'testw6vs28auh3',
        adType: 1
      },
      adOptions: {
        height: 150,
        width: 1080
      },
      displayOptions: {
        backgroundColor: '#F5F5F5'
      },
      interactionListener: {
        onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
          switch (status) {
            case 'AD_LOAD':
              console.info('广告加载成功')
              break
            case 'AD_FAIL':
              console.error('广告加载失败:', data)
              break
            case 'AD_CLOSED':
              console.info('广告被关闭')
              break
            case 'AD_CLICKED':
              console.info('广告被点击')
              break
            case 'AD_OPEN':
              console.info('广告被打开')
              break
          }
        }
      }
    })
    .width('100%')
    .height(150)
  }
} 