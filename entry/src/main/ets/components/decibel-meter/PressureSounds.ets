import { ImageSoundPlayer } from "./ImageSoundPlayer";
import { AudioPlayerService, PlayerState } from "../../services/AudioPlayerService";
import { ImageRaw } from "../common/ImageRaw";
import { ImageSoundPlayingService } from "../../services/ImageSoundPlayingService";
import { navigationStack } from "../../constants/ProviderConstant";

export interface ImageSound {
  name: string;
  image: string;
  sound: string;
}

export interface ImageSoundPlayerState extends ImageSound {
  playerState: PlayerState;
  playerService: AudioPlayerService;
}

@Preview
@ComponentV2
export struct PressureSounds {
  @Consumer(navigationStack) navStack: NavPathStack = new NavPathStack();

  @Computed
  get unionImagePath(): string {
    if (this.playingList.length > 0) {
      return this.playingList[this.playingList.length - 1].image;
    }
    return '';
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      WaterFlow() {
        ForEach(this.imageSounds, (item: ImageSound, index) => {
          FlowItem() {
            Flex({ wrap: FlexWrap.Wrap }) {
              ImageSoundPlayer({
                image: item.image,
                file: item.sound,
                onPlayStateChange: (state: PlayerState, playerService: AudioPlayerService) => {
                  this.updateUnionPlayerState(state, playerService, item);
                }
              }).width(100).height(100).animation({ duration: 200, curve: Curve.EaseOut })
              Text(item.name).width(100)
                .fontSize(12).animation({ duration: 200, curve: Curve.EaseOut })
            }
          }
        }, (item: ImageSound, index) => item.name)
        FlowItem().height(200)
      }
      .columnsTemplate('repeat(auto-fill,100)')
      .rowsTemplate('1fr 1fr 1fr')


      .rowsGap(16)
      .columnsGap(16)
      .padding({ left: 16 })

      if (this.playingList.length > 0) {
        Stack({ alignContent: Alignment.Start }) {
          ImageRaw({ image: this.unionImagePath, fit: ImageFit.Auto })
            .onClick(() => {
              this.navStack.pushPathByName('PlayingItemsDialog', undefined)
            })

            .height(50)
          Button() {
            Image(this.unionPlayerState === PlayerState.STATE_PLAYING ? $r('app.media.ic_pause') :
            $r('app.media.ic_play'))
              .fillColor(Color.White)


          }
          .backgroundColor(Color.Transparent)
          .width(32)
          .height(32)
          .margin({ left: 8 })
          .type(ButtonType.Circle)
          .onClick(() => {
            this.playingList.forEach((pItem) => this.unionPlayerState === PlayerState.STATE_PLAYING ?
            pItem.playerService.pause() : pItem.playerService.resume());
          })
        }

        .height(50)
        .padding({ left: 16, right: 16, bottom: 100 })
        .borderRadius(12)
        .animation({})
      }
    }
  }

  @Local unionPlayerState: PlayerState = PlayerState.STATE_NOT_INIT;
  @Local playingList: Array<ImageSoundPlayerState> = ImageSoundPlayingService.getInstance().imageSoundPlayingList;
  private imageSounds: Array<ImageSound> = [
  // 动物类
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

    // 布朗噪声类
    {
      name: '【布朗声谱】柔和的双声道布朗噪声',
      image: 'rawfile/images/brownnoise/【布朗声谱】柔和的双声道布朗噪声.jpg',
      sound: 'sounds/brownnoise/【布朗声谱】柔和的双声道布朗噪声.ogg'
    },

    // 火焰类
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

    // 森林类
    {
      name: '【春松鸣禽】西班牙南部松林声景，群鸟鸣唱与松涛簌簌',
      image: 'rawfile/images/forest/【春松鸣禽】西班牙南部松林声景，群鸟鸣唱与松涛簌簌.jpg',
      sound: 'sounds/forest/【春松鸣禽】西班牙南部松林声景，群鸟鸣唱与松涛簌簌.ogg'
    },
    {
      name: '【风竹私语】于荒野偶遇随风摇曳的孤竹，收录其枝干摩擦的天然嘎吱律动',
      image: 'rawfile/images/forest/【风竹私语】于荒野偶遇随风摇曳的孤竹，收录其枝干摩擦的天然嘎吱律动.jpg',
      sound: 'sounds/forest/【风竹私语】于荒野偶遇随风摇曳的孤竹，收录其枝干摩擦的天然嘎吱律动.ogg'
    },
    {
      name: '【林风絮语】增益处理后的森林风声实录',
      image: 'rawfile/images/forest/【林风絮语】增益处理后的森林风声实录.jpg',
      sound: 'sounds/forest/【林风絮语】增益处理后的森林风声实录.ogg'
    },
    {
      name: '【雨林双声】巴西亚马逊丛林中两只尖叫皮哈鸟的对鸣实录',
      image: 'rawfile/images/forest/【雨林双声】巴西亚马逊丛林中两只尖叫皮哈鸟的对鸣实录.jpg',
      sound: 'sounds/forest/【雨林双声】巴西亚马逊丛林中两只尖叫皮哈鸟的对鸣实录.ogg'
    },
    {
      name: '【仲夏林语】荷兰梵高国家公园软木林春末声景采样',
      image: 'rawfile/images/forest/【仲夏林语】荷兰梵高国家公园软木林春末声景采样.jpg',
      sound: 'sounds/forest/【仲夏林语】荷兰梵高国家公园软木林春末声景采样.ogg'
    },

    // 海浪类
    {
      name: '【海浪涌岸】海洋波涛拍岸之声',
      image: 'rawfile/images/oceanwaves/【海浪涌岸】海洋波涛拍岸之声.png',
      sound: 'sounds/oceanwaves/【海浪涌岸】海洋波涛拍岸之声.ogg'
    },
    {
      name: '【怒涛崩裂】墨西哥下加利福尼亚众圣海滩巨浪轰鸣实录',
      image: 'rawfile/images/oceanwaves/【怒涛崩裂】墨西哥下加利福尼亚众圣海滩巨浪轰鸣实录.jpg',
      sound: 'sounds/oceanwaves/【怒涛崩裂】墨西哥下加利福尼亚众圣海滩巨浪轰鸣实录.ogg'
    },
    {
      name: '【泰式海浪】泡沫翻涌的绵长巨浪拍岸之声，中景穿插航船经过的低频轰鸣',
      image: 'rawfile/images/oceanwaves/【泰式海浪】泡沫翻涌的绵长巨浪拍岸之声，中景穿插航船经过的低频轰鸣.jpg',
      sound: 'sounds/oceanwaves/【泰式海浪】泡沫翻涌的绵长巨浪拍岸之声，中景穿插航船经过的低频轰鸣.ogg'
    },
    {
      name: '【夜海轻语】西班牙马略卡岛帕尔马近岸的夜间细浪声景',
      image: 'rawfile/images/oceanwaves/【夜海轻语】西班牙马略卡岛帕尔马近岸的夜间细浪声景.jpg',
      sound: 'sounds/oceanwaves/【夜海轻语】西班牙马略卡岛帕尔马近岸的夜间细浪声景.ogg'
    },
    {
      name: '【夜海声幕】美国缅因州夜间录制的海洋波涌循环音效，叠加玩具吱喳模拟白昼鸥鸣',
      image: 'rawfile/images/oceanwaves/【夜海声幕】美国缅因州夜间录制的海洋波涌循环音效，叠加玩具吱喳模拟白昼鸥鸣.jpg',
      sound: 'sounds/oceanwaves/【夜海声幕】美国缅因州夜间录制的海洋波涌循环音效，叠加玩具吱喳模拟白昼鸥鸣.ogg'
    },

    // 粉红噪声类
    {
      name: '【粉红声疗】立体声粉红噪声（淡入淡出 默认振幅），专为放松与耳鸣缓解设计',
      image: 'rawfile/images/pinknoise/【粉红声疗】立体声粉红噪声（淡入淡出 默认振幅），专为放松与耳鸣缓解设计.jpg',
      sound: 'sounds/pinknoise/【粉红声疗】立体声粉红噪声（淡入淡出 默认振幅），专为放松与耳鸣缓解设计.ogg'
    },

    // 雨声类
    {
      name: '【城市雨境】滂沱大雨敲击都市人行道，铿锵雨滴迸溅声与地面水流声交织形成沉浸式白噪音',
      image: 'rawfile/images/rains/【城市雨境】滂沱大雨敲击都市人行道，铿锵雨滴迸溅声与地面水流声交织形成沉浸式白噪音.jpg',
      sound: 'sounds/rains/【城市雨境】滂沱大雨敲击都市人行道，铿锵雨滴迸溅声与地面水流声交织形成沉浸式白噪音.ogg'
    },
    {
      name: '【窗畔雨奏】密集雨点撞击窗玻璃的澎湃韵律',
      image: 'rawfile/images/rains/【窗畔雨奏】密集雨点撞击窗玻璃的澎湃韵律.jpg',
      sound: 'sounds/rains/【窗畔雨奏】密集雨点撞击窗玻璃的澎湃韵律.ogg'
    },
    {
      name: '【东西伯利亚雨夜实录】骤雨淅沥，雷鸣浑厚低沉，完整呈现中雨与绵延雷声的交响瞬间',
      image: 'rawfile/images/rains/【东西伯利亚雨夜实录】骤雨淅沥，雷鸣浑厚低沉，完整呈现中雨与绵延雷声的交响瞬间.jpg',
      sound: 'sounds/rains/【东西伯利亚雨夜实录】骤雨淅沥，雷鸣浑厚低沉，完整呈现中雨与绵延雷声的交响瞬间.ogg'
    },
    {
      name: '【林间疏雨】雨滴洒落枝叶的细腻声响，叶片震颤与灌木涟漪声交织成自然白噪音',
      image: 'rawfile/images/rains/【林间疏雨】雨滴洒落枝叶的细腻声响，叶片震颤与灌木涟漪声交织成自然白噪音.jpg',
      sound: 'sounds/rains/【林间疏雨】雨滴洒落枝叶的细腻声响，叶片震颤与灌木涟漪声交织成自然白噪音.ogg'
    },
    {
      name: '【人工雷暴音效】动态混合雷雨声景新作。以白噪音为雨声基底，融合花园实录的洒水音效与真假雷鸣交织。呈现强度渐变的沉浸式暴风雨听觉体验',
      image: 'rawfile/images/rains/【人工雷暴音效】动态混合雷雨声景新作。以白噪音为雨声基底，融合花园实录的洒水音效与真假雷鸣交织。呈现强度渐变的沉浸式暴风雨听觉体验.jpg',
      sound: 'sounds/rains/【人工雷暴音效】动态混合雷雨声景新作。以白噪音为雨声基底，融合花园实录的洒水音效与真假雷鸣交织。呈现强度渐变的沉浸式暴风雨听觉体验.ogg'
    },
    {
      name: '【盛夏雷鸣骤雨之酣畅交响】',
      image: 'rawfile/images/rains/【盛夏雷鸣骤雨之酣畅交响】.jpg',
      sound: 'sounds/rains/【盛夏雷鸣骤雨之酣畅交响】.ogg'
    },
    {
      name: '【叶脉凝珠】湿滑叶片承接着断续雨滴，每一颗水珠坠落的颤音皆泛起清脆共鸣',
      image: 'rawfile/images/rains/【叶脉凝珠】湿滑叶片承接着断续雨滴，每一颗水珠坠落的颤音皆泛起清脆共鸣.jpg',
      sound: 'sounds/rains/【叶脉凝珠】湿滑叶片承接着断续雨滴，每一颗水珠坠落的颤音皆泛起清脆共鸣.ogg'
    },
    {
      name: '【宅邸夜雨】深宵时分捕捉私人领域雨境，雨滴叩击路面与混凝土的清脆韵律交织成静谧夜曲',
      image: 'rawfile/images/rains/【宅邸夜雨】深宵时分捕捉私人领域雨境，雨滴叩击路面与混凝土的清脆韵律交织成静谧夜曲.jpg',
      sound: 'sounds/rains/【宅邸夜雨】深宵时分捕捉私人领域雨境，雨滴叩击路面与混凝土的清脆韵律交织成静谧夜曲.ogg'
    },

    // 溪流类
    {
      name: '【高山雪溪】于华盛顿州山羊岩荒野高海拔区，录得源自残雪的清冽溪流潺潺之声',
      image: 'rawfile/images/stream/【高山雪溪】于华盛顿州山羊岩荒野高海拔区，录得源自残雪的清冽溪流潺潺之声.jpg',
      sound: 'sounds/stream/【高山雪溪】于华盛顿州山羊岩荒野高海拔区，录得源自残雪的清冽溪流潺潺之声.ogg'
    },
    {
      name: '【冷湖溪语】圣海伦斯山脚下，清冽溪流汇入冷湖的自然声景',
      image: 'rawfile/images/stream/【冷湖溪语】圣海伦斯山脚下，清冽溪流汇入冷湖的自然声景.jpg',
      sound: 'sounds/stream/【冷湖溪语】圣海伦斯山脚下，清冽溪流汇入冷湖的自然声景.ogg'
    },
    {
      name: '【林间潺湲】蜿蜒溪流与幽幽鸟鸣的自然协奏',
      image: 'rawfile/images/stream/【林间潺湲】蜿蜒溪流与幽幽鸟鸣的自然协奏.jpg',
      sound: 'sounds/stream/【林间潺湲】蜿蜒溪流与幽幽鸟鸣的自然协奏.ogg'
    },
    {
      name: '【双岩悬瀑】林间溪流系列之飞瀑篇：两道巨岩间奔涌而下的水幕激荡之声',
      image: 'rawfile/images/stream/【双岩悬瀑】林间溪流系列之飞瀑篇：两道巨岩间奔涌而下的水幕激荡之声.jpg',
      sound: 'sounds/stream/【双岩悬瀑】林间溪流系列之飞瀑篇：两道巨岩间奔涌而下的水幕激荡之声.ogg'
    },
    {
      name: '【溪涧自然采样】一段悦耳溪流声景。（保留原始水体动态与空间共鸣）',
      image: 'rawfile/images/stream/【溪涧自然采样】一段悦耳溪流声景。（保留原始水体动态与空间共鸣）.jpg',
      sound: 'sounds/stream/【溪涧自然采样】一段悦耳溪流声景。（保留原始水体动态与空间共鸣）.ogg'
    },
    {
      name: '【新西兰森林溪语】源自原始林间的清澈溪流声景',
      image: 'rawfile/images/stream/【新西兰森林溪语】源自原始林间的清澈溪流声景.jpg',
      sound: 'sounds/stream/【新西兰森林溪语】源自原始林间的清澈溪流声景.ogg'
    },

    // 瀑布类
    {
      name: '【阿尔卑斯融水声景】瑞士萨斯费高山冰川融水穿越森林与瀑布，汇入北向河流的自然声景',
      image: 'rawfile/images/waterfall/【阿尔卑斯融水声景】瑞士萨斯费高山冰川融水穿越森林与瀑布，汇入北向河流的自然声景.jpg',
      sound: 'sounds/waterfall/【阿尔卑斯融水声景】瑞士萨斯费高山冰川融水穿越森林与瀑布，汇入北向河流的自然声景.ogg'
    },
    {
      name: '【晨曦声幕】俄亥俄阿什洞穴公园破晓实录。背瀑面林捕捉晨鸟合唱，左侧溪涧伴唱，纯净无扰声景',
      image: 'rawfile/images/waterfall/【晨曦声幕】俄亥俄阿什洞穴公园破晓实录。背瀑面林捕捉晨鸟合唱，左侧溪涧伴唱，纯净无扰声景.jpg',
      sound: 'sounds/waterfall/【晨曦声幕】俄亥俄阿什洞穴公园破晓实录。背瀑面林捕捉晨鸟合唱，左侧溪涧伴唱，纯净无扰声景.ogg'
    },
    {
      name: '【激瀑湍流】穆姆拉瓦瀑布湍急水流音效实录',
      image: 'rawfile/images/waterfall/【激瀑湍流】穆姆拉瓦瀑布湍急水流音效实录.jpg',
      sound: 'sounds/waterfall/【激瀑湍流】穆姆拉瓦瀑布湍急水流音效实录.ogg'
    },
    {
      name: '【苏格兰隐瀑】录于苏格兰边境，藏身于岩林秘境的瀑布之声。可闻水幕垂落与激溅之清响',
      image: 'rawfile/images/waterfall/【苏格兰隐瀑】录于苏格兰边境，藏身于岩林秘境的瀑布之声。可闻水幕垂落与激溅之清响.jpg',
      sound: 'sounds/waterfall/【苏格兰隐瀑】录于苏格兰边境，藏身于岩林秘境的瀑布之声。可闻水幕垂落与激溅之清响.ogg'
    },

    // 白噪声类
    {
      name: '【白噪音】全频段均匀声波（睡眠辅助 注意力集中 环境音掩蔽）',
      image: 'rawfile/images/whitenoise/【白噪音】全频段均匀声波（睡眠辅助 注意力集中 环境音掩蔽）.jpg',
      sound: 'sounds/whitenoise/【白噪音】全频段均匀声波（睡眠辅助 注意力集中 环境音掩蔽）.ogg'
    },
    {
      name: '【短波声谱】无线电静电噪音，背景含奇特下行音高漂移（类白噪频段与声谱渐变现象）',
      image: 'rawfile/images/whitenoise/【短波声谱】无线电静电噪音，背景含奇特下行音高漂移（类白噪频段与声谱渐变现象）.jpg',
      sound: 'sounds/whitenoise/【短波声谱】无线电静电噪音，背景含奇特下行音高漂移（类白噪频段与声谱渐变现象）.ogg'
    },
    {
      name: '【锐利白噪】由Adobe Audition生成的高强度均匀声波',
      image: 'rawfile/images/whitenoise/【锐利白噪】由Adobe Audition生成的高强度均匀声波.jpg',
      sound: 'sounds/whitenoise/【锐利白噪】由Adobe Audition生成的高强度均匀声波.ogg'
    },
    {
      name: '【异质白噪】立体声场的奇特声波体验',
      image: 'rawfile/images/whitenoise/【异质白噪】立体声场的奇特声波体验.jpg',
      sound: 'sounds/whitenoise/【异质白噪】立体声场的奇特声波体验.ogg'
    },
  ]

  private updateUnionPlayerState(state: PlayerState, playerService: AudioPlayerService, currentItem: ImageSound) {
    if (state === PlayerState.STATE_PLAYING) {
      this.unionPlayerState = state;
      let addedImageSound =
        this.playingList.find((playingItem: ImageSoundPlayerState) => playingItem.name === currentItem.name);
      if (addedImageSound) {
        addedImageSound.playerState = state;
      } else {
        this.playingList.push({
          name: currentItem.name,
          image: currentItem.image,
          sound: currentItem.sound,
          playerState: state,
          playerService: playerService
        });
      }
    }
    if (state === PlayerState.STATE_STOPPED || state === PlayerState.STATE_COMPLETED) {
      let removedImageSound =
        this.playingList.find((playingItem: ImageSoundPlayerState) => playingItem.name === currentItem.name);
      if (removedImageSound) {
        this.playingList.splice(this.playingList.indexOf(removedImageSound), 1);
      }
    }
    if (state === PlayerState.STATE_PAUSED) {
      let playingItem =
        this.playingList.filter((playingItem: ImageSoundPlayerState) => playingItem.name !== currentItem.name)
          .find((playingItem: ImageSoundPlayerState) => playingItem.playerState === PlayerState.STATE_PLAYING);
      if (!playingItem) {
        this.unionPlayerState = state;
      }
      let currentItems =
        this.playingList.find((playingItem: ImageSoundPlayerState) => playingItem.name === currentItem.name);
      if (currentItems) {
        currentItems.playerState = state;
      }
    }
  }
}