import { ImageRaw } from "../common/ImageRaw";
import resourceManager from "@ohos.resourceManager";
import { AudioPlayerService, PlayerState } from "../../services/AudioPlayerService";
import { curves } from "@kit.ArkUI";
import { AudioPlayerGroupService } from "../../services/AudioPlayerGroupService";

@ComponentV2
export struct ImageSoundPlayer {
  @Param @Require image: string;
  @Param @Require file: string;
  @Event onPlayStateChange: (state: PlayerState, playerService: AudioPlayerService) => void;
  @Local rawFileDescriptor: resourceManager.RawFileDescriptor | undefined = undefined;
  @Local playerState: PlayerState = PlayerState.STATE_NOT_INIT;
  private context = getContext(this);
  private audioPlayerService: AudioPlayerService = AudioPlayerGroupService.getPlayerInstance(this.file);
  private autoStopTimeOutId: number | undefined;

  aboutToAppear(): void {
    this.rawFileDescriptor = this.context.resourceManager.getRawFdSync(this.file);
    this.audioPlayerService.setVolume(1);
    this.audioPlayerService.addOnStateChangeListener((state: PlayerState) => {
      this.playerState = state;
      this.onPlayStateChange(state, this.audioPlayerService);
    });
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      ImageRaw({ image: this.image })
      if (this.rawFileDescriptor) {
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
    }.transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
      .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
      .combine(TransitionEffect.translate({ y: 150 }).animation({ curve: curves.springMotion() })))
  }

  aboutToDisappear(): void {
    if (this.playerState === PlayerState.STATE_PLAYING || this.playerState === PlayerState.STATE_PAUSED) {
      this.audioPlayerService.stop();
    }
  }
}