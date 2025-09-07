import { AudioPlayer } from "../business/AudioPlayer";
import { ImageRaw } from "../common/ImageRaw";
import resourceManager from "@ohos.resourceManager";
import { AudioPlayerService, PlayerState } from "../../services/AudioPlayerService";

@ComponentV2
export struct ImageSoundPlayer2 {
  @Param @Require image: string;
  @Param @Require initState: PlayerState;
  @Param @Require audioPlayerService: AudioPlayerService;
  @Local playerState: PlayerState = PlayerState.STATE_PLAYING;

  aboutToAppear(): void {
    this.playerState = this.initState;
    this.audioPlayerService.setVolume(1);
    this.audioPlayerService.addOnStateChangeListener((state: PlayerState) => {
      this.playerState = state;
    });
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      ImageRaw({ image: this.image })
      Button() {
        Image(this.playerState === PlayerState.STATE_PLAYING ? $r('app.media.ic_pause') :
        $r('app.media.ic_play'))
          .fillColor(Color.White)
          .opacity(0.9)
      }
      .width('25%')
      .height('25%')
      .margin({ left: 8, bottom: 8 })
      .type(ButtonType.Circle)
      .backgroundColor(Color.Transparent)
      .onClick(async () => {
        try {
          if (this.playerState === PlayerState.STATE_PLAYING) {
            await this.audioPlayerService.pause();
          } else {
            if (this.playerState === PlayerState.STATE_PAUSED) {
              await this.audioPlayerService.resume();
            }
          }
        } catch (error) {
          console.error('播放音频失败: %{public}s',
            error instanceof Error ? error.message : String(error));
        }
      })
    }
  }
}