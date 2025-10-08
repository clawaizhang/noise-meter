import { ImageRaw } from '../common/ImageRaw';
import resourceManager from '@ohos.resourceManager';
import { AudioPlayerService } from '../../services/AudioPlayerService';
import { curves } from '@kit.ArkUI';
import { AudioPlayerGroupService } from '../../services/AudioPlayerGroupService';
import { media } from '@kit.MediaKit';
import { Subscription, timer } from 'rxjs';
import { Throttle } from '../../utils/Debounce';

@ComponentV2
export struct ImageSoundPlayer {
  @Param @Require image: string;
  @Param @Require file: string;
  @Event imagePrepared: (image: PixelMap) => void = (image: PixelMap) => {
  };
  @Event onPlayStateChange: (state: media.AVPlayerState, playerService: AudioPlayerService) => void;
  @Local rawFileDescriptor: resourceManager.RawFileDescriptor | undefined = undefined;
  @Local playerState: media.AVPlayerState = 'idle';
  private context = getContext(this);
  private audioPlayerService: AudioPlayerService = AudioPlayerGroupService.getPlayerInstance(this.file);
  private autoStopTimeOutId: number | undefined;
  timerStop?: Subscription;

  aboutToAppear(): void {
    this.rawFileDescriptor = this.context.resourceManager.getRawFdSync(this.file);
    this.audioPlayerService.setVolume(1);
    this.audioPlayerService.addOnStateChangeListener((state: media.AVPlayerState) => {
      this.playerState = state;
      this.onPlayStateChange(state, this.audioPlayerService);
      if (this.playerState == 'completed' && this.rawFileDescriptor) {
        this.audioPlayerService.playAudioFileByFd(this.rawFileDescriptor)
      }
    });
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      ImageRaw({ image: this.image, imagePrepared: this.imagePrepared })
      if (this.rawFileDescriptor) {
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
          Throttle.click(async () => {
            try {
              if (this.playerState === 'playing') {
                await this.audioPlayerService.pause();
                this.timerStop = timer(10_000).subscribe(() => {
                  this.audioPlayerService.stop();
                });
              } else {
                this.timerStop?.unsubscribe();
                if (this.playerState === 'paused') {
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
        })
      }
    }.transition(TransitionEffect.OPACITY.animation({ curve: curves.springMotion(0.6, 0.8) }) // 透明度动画，使用springMotion曲线
      .combine(TransitionEffect.scale({ x: 0, y: 0 })) // 组合缩放效果（从0放大到1）
      .combine(TransitionEffect.translate({ y: 150 }).animation({ curve: curves.springMotion() })))
  }

  aboutToDisappear(): void {
    this.timerStop?.unsubscribe();
    if (this.playerState === 'playing' || this.playerState === 'paused') {
      this.audioPlayerService.stop();
    }
  }
}