import { ImageRaw } from "../common/ImageRaw";
import { ImageSoundPlayer } from "./ImageSoundPlayer";
import { LengthMetrics } from "@kit.ArkUI";

interface ImageSound {
  name: string;
  image: string;
  sound: string;
}

@Preview
@ComponentV2
export struct PressureSounds {
  build() {
    WaterFlow() {
      ForEach(this.imageSounds, (item: ImageSound, index) => {
        FlowItem() {
          Flex({ wrap: FlexWrap.Wrap }) {
            ImageSoundPlayer({ image: item.image, file: item.sound }).width(100).height(100)
            Text(item.name).width(100)
              .fontSize(12)
          }
        }
      })
    }
    .columnsTemplate('repeat(auto-fill,100)')
    .rowsTemplate('1fr 1fr 1fr')
    .width('100%')
    .height('100%')
    .rowsGap(16)
    .columnsGap(16)
    .margin({ left: 16 })
  }

  private imageSounds: Array<ImageSound> = [
    {
      name: '【城郊夏夜蛩音】蟋蟀夜鸣环境声景',
      image: 'rawfile/images/animals/【城郊夏夜蛩音】蟋蟀夜鸣环境声景.jpg',
      sound: 'sounds/animals/【城郊夏夜蛩音】蟋蟀夜鸣环境声景.ogg',
    },
    {
      name: '【牧场夜吟】凌晨一点于牧场池塘录制的蛙鸣与蟋蟀震颤声',
      image: 'rawfile/images/animals/【牧场夜吟】凌晨一点于牧场池塘录制的蛙鸣与蟋蟀震颤声.jpg',
      sound: 'sounds/animals/【牧场夜吟】凌晨一点于牧场池塘录制的蛙鸣与蟋蟀震颤声.ogg'
    },
    {
      name: '【布朗声谱】柔和的双声道布朗噪声',
      image: 'rawfile/images/brownnoise/【布朗声谱】柔和的双声道布朗噪声.jpg',
      sound: 'sounds/brownnoise/【布朗声谱】柔和的双声道布朗噪声.ogg'
    },
    {
      name: '【壁炉柴韵】木柴燃烧时的噼啪细响与环境热力交织',
      image: 'rawfile/images/fire/【壁炉柴韵】木柴燃烧时的噼啪细响与环境热力交织.jpg',
      sound: 'sounds/fire/【壁炉柴韵】木柴燃烧时的噼啪细响与环境热力交织.ogg'
    },
    {
      name: '【安达卢西亚星火】西班牙马拉加篝火声景采样',
      image: 'rawfile/images/fire/【安达卢西亚星火】西班牙马拉加篝火声景采样.jpg',
      sound: 'sounds/fire/【安达卢西亚星火】西班牙马拉加篝火声景采样.ogg'
    },
    {
      name: '【星火细语】一小簇火焰跃动燃烧的噼啪微响',
      image: 'rawfile/images/fire/【星火细语】一小簇火焰跃动燃烧的噼啪微响.jpg',
      sound: 'sounds/fire/【星火细语】一小簇火焰跃动燃烧的噼啪微响.ogg'
    },
    {
      name: '【炉火特写】混响空间内壁炉星火噼啪声的近场实录',
      image: 'rawfile/images/fire/【炉火特写】混响空间内壁炉星火噼啪声的近场实录.jpg',
      sound: 'sounds/fire/【炉火特写】混响空间内壁炉星火噼啪声的近场实录.ogg'
    },
    {
      name: '【篝火细语】一小段篝火噼啪作响的原始环境采样',
      image: 'rawfile/images/fire/【篝火细语】一小段篝火噼啪作响的原始环境采样.jpg',
      sound: 'sounds/fire/【篝火细语】一小段篝火噼啪作响的原始环境采样.ogg'
    },
    {
      name: '【营火星火】篝火堆中木柴迸裂的细碎律动与温暖氛围声景',
      image: 'rawfile/images/fire/【营火星火】篝火堆中木柴迸裂的细碎律动与温暖氛围声景.jpg',
      sound: 'sounds/fire/【营火星火】篝火堆中木柴迸裂的细碎律动与温暖氛围声景.ogg'
    },
  ]
}