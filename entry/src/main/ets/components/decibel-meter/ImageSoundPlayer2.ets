import { ImageRaw } from '../common/ImageRaw';
import { AudioPlayerService } from '../../services/AudioPlayerService';
import { media } from '@kit.MediaKit';

@ComponentV2
export struct ImageSoundPlayer2 {
  @Param @Require image: string;
  @Param @Require initState: media.AVPlayerState;
  @Param @Require audioPlayerService: AudioPlayerService;
  @Local playerState: media.AVPlayerState = 'playing';

  aboutToAppear(): void {
    this.playerState = this.initState;
    this.audioPlayerService.setVolume(1);
    this.audioPlayerService.addOnStateChangeListener((state: media.AVPlayerState) => {
      this.playerState = state;
    });
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      ImageRaw({ image: this.image })
      Button() {
        Image(this.playerState === 'playing' ? $r('app.media.ic_pause') :
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
          if (this.playerState === 'playing') {
            await this.audioPlayerService.pause();
          } else {
            if (this.playerState === 'paused') {
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