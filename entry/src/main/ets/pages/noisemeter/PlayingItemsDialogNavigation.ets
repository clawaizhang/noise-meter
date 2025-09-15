import { DialogContainer } from '../../components/common/DialogContainer';
import { ImageSoundPlayer2 } from '../../components/decibel-meter/ImageSoundPlayer2';
import { ImageSoundPlayerState } from '../../components/decibel-meter/PressureSounds';
import { ImageSoundPlayingService } from '../../services/ImageSoundPlayingService';

@ComponentV2
export struct PlayingItemsDialog {
  @Local contentParams: Array<ImageSoundPlayerState> = ImageSoundPlayingService.getInstance().imageSoundPlayingList;

  build() {
    WaterFlow() {
      ForEach(this.contentParams, (item: ImageSoundPlayerState, index) => {
        FlowItem() {
          Flex({ wrap: FlexWrap.Wrap }) {
            ImageSoundPlayer2({
              image: item.image,
              initState: item.playerState,
              audioPlayerService: item.playerService,
            }).width(100).height(100)
            Text(item.name).width(100)
              .fontSize(12)
          }
        }
      }, (item: ImageSoundPlayerState, index) => item.name)
      FlowItem().height(200)
    }
    .columnsTemplate('repeat(auto-fill,100)')
    .rowsTemplate('1fr 1fr 1fr')
    .rowsGap(16)
    .columnsGap(16)
    .padding({ top: 16, left: 16 })
  }
}

@Builder
export function PlayingItemsDialogBuilder() {
  PlayingItemsDialog()
}