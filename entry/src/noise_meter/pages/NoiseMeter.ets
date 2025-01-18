import { DecibelMeter } from '../ets/components/decibel-meter/DecibelMeter';
import { noiseMeterNavStack } from '../ets/constant/ProviderConstant';
import { getTitleName } from '../MainPageInfo';
import { DecibelHistory } from './DecibelHistory';
import { CustomTitleBar } from '../../library/ets/components/common/CustomTitleBar';
import { Settings } from '../ets/components/Settings';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { fileUri } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';

@ComponentV2
export struct NoiseMeter {
  @Provider(noiseMeterNavStack) navStack: NavPathStack = new NavPathStack()
  @Local currentIndex: number = 0

  private async handleScreenshotAndShare(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const filePath = context.tempDir + '/noise_meter_screenshot.jpg';

      // 获取截图
      const pixmap = await this.getUIContext().getComponentSnapshot().get("decibelMeterRoot", {
        scale: 2,
        waitUntilRenderFinished: true
      });

      // 编码图片
      const imagePacker = image.createImagePacker();
      const packOptions: image.PackingOption = {
        format: "image/jpeg",
        quality: 100
      };
      const data = await imagePacker.packToData(pixmap, packOptions);

      // 保存文件
      const file = await fileIo.open(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
      await fileIo.write(file.fd, data);

      // 设置分享数据
      const utdTypeId = utd.getUniformDataTypeByFilenameExtension('.jpg', utd.UniformDataType.IMAGE);
      const shareData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath),
        title: '噪音检测仪截图',
        description: '当前噪音检测结果截图',
      });

      // 分享
      const controller = new systemShare.ShareController(shareData);
      await controller.show(context, {
        selectionMode: systemShare.SelectionMode.SINGLE,
        previewMode: systemShare.SharePreviewMode.DETAIL,
      });
      console.info('分享成功');
    } catch (error) {
      console.error(`分享失败: code=${error.code}, message=${error.message}`);
    }
  }

  @Builder
  TabBuilder(title: string, icon: Resource, index: number) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentIndex === index ? '#2196F3' : '#666666')
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? '#2196F3' : '#666666')
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
            // 使用自定义标题栏
            CustomTitleBar({
              title: getTitleName(),
              rightButton: {
                icon: $r('app.media.ic_share'),
                onClick: () => {
                  this.handleScreenshotAndShare();
                }
              }
            })

            // 噪音检测区域
            DecibelMeter()
              .width('92%')
          }
          .id('decibelMeterRoot')
          .width('100%')
          .height('100%')
          .backgroundColor('#F5F5F5')
          .alignItems(HorizontalAlign.Center)
        }
        .tabBar(this.TabBuilder('噪音检测仪', $r('app.media.ic_meter'), 0))

        TabContent() {
          DecibelHistory({ currentTabIndex: this.currentIndex })
        }
        .tabBar(this.TabBuilder('检测记录', $r('app.media.ic_history'), 1))

        TabContent() {
          Settings()
        }
        .tabBar(this.TabBuilder('设置', $r('app.media.ic_settings'), 2))
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