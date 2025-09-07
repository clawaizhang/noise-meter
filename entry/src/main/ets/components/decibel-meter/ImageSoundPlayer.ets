import { AudioPlayer } from "../business/AudioPlayer";
import { ImageRaw } from "../common/ImageRaw";
import resourceManager from "@ohos.resourceManager";
import { AudioPlayerService, PlayerState } from "../../services/AudioPlayerService";

@ComponentV2
export struct ImageSoundPlayer {
  @Param @Require image: string;
  @Param @Require file: string;
  @Local rawFileDescriptor: resourceManager.RawFileDescriptor | undefined = undefined;
  @Local playerState: PlayerState = PlayerState.STATE_NOT_INIT;
  private context = getContext(this);
  private audioPlayerService: AudioPlayerService = new AudioPlayerService();
  private autoStopTimeOutId: number | undefined;

  aboutToAppear(): void {
    this.rawFileDescriptor = this.context.resourceManager.getRawFdSync(this.file);
    this.audioPlayerService.setVolume(1);
    this.audioPlayerService.setOnStateChangeListener((state: PlayerState) => {
      this.playerState = state;
    });
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      ImageRaw({ image: this.image })
      if (this.rawFileDescriptor) {
        Button() {
          Image(this.playerState === PlayerState.STATE_PLAYING ? $r('app.media.ic_pause') :
          $r('app.media.ic_play'))
            .fillColor(Color.White)
            .opacity(0.9)
        }
        .width('50%')
        .height('50%')
        .type(ButtonType.Circle)
        .backgroundColor(Color.Transparent)
        .onClick(async () => {
          try {
            if (this.playerState === PlayerState.STATE_PLAYING) {
              await this.audioPlayerService.pause();
              this.autoStopTimeOutId = setTimeout(() => {
                this.audioPlayerService.stop();
              }, 10_000);
            } else {
              clearTimeout(this.autoStopTimeOutId);
              if (this.playerState === PlayerState.STATE_PAUSED) {
                await this.audioPlayerService.resume();
              } else {
                if (this.rawFileDescriptor) {
                  await this.audioPlayerService.playAudioFileByFd(this.rawFileDescriptor);
                }
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

  aboutToDisappear(): void {
    if (this.playerState === PlayerState.STATE_PLAYING || this.playerState === PlayerState.STATE_PAUSED) {
      this.audioPlayerService.stop();
    }
  }
}