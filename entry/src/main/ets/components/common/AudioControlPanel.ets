import { AppKeys } from '../../models/AppKeys';
import { PreferenceKeys } from '../../models/PreferenceKeys';
import { AppStorageV2, PersistenceV2, promptAction } from '@kit.ArkUI';
import { DesignConstants } from '../../constants/DesignConstants';
import { AudioControllerService } from '../../services/AudioControllerService';
import { AudioControllerLifecycleState, StateTransitionEvent } from '../../models/AudioControllerLifecycleState';
import { InputDialog } from '../decibel-meter/InputDialog';
import { Throttle } from '../../utils/Debounce';

// 按钮状态配置类
@ObservedV2
class ButtonState {
  @Trace enabled: boolean = false;
  @Trace text: string = '';
  @Trace backgroundColor: Resource = $r('sys.color.font_secondary');

  constructor(enabled: boolean, text: string, backgroundColor: Resource) {
    this.enabled = enabled;
    this.text = text;
    this.backgroundColor = backgroundColor;
  }

  // 更新按钮状态
  update(enabled: boolean, text: string, backgroundColor: Resource): void {
    this.enabled = enabled;
    this.text = text;
    this.backgroundColor = backgroundColor;
  }
}

// 按钮状态集合类
@ObservedV2
class ButtonStates {
  @Trace startButton: ButtonState;
  @Trace stopButton: ButtonState;
  @Trace resetButton: ButtonState;
  @Trace saveButton: ButtonState;

  constructor() {
    // 初始化默认状态
    this.startButton = new ButtonState(false, '开始检测', $r('sys.color.font_secondary'));
    this.stopButton = new ButtonState(false, '停止', $r('sys.color.font_secondary'));
    this.resetButton = new ButtonState(false, '重置', $r('sys.color.comp_background_secondary'));
    this.saveButton = new ButtonState(false, '保存', $r('sys.color.font_secondary'));
  }

  // 根据控制器状态更新所有按钮状态
  updateStates(controllerState: AudioControllerLifecycleState): void {
    // 开始按钮状态
    this.startButton.update(
      controllerState === AudioControllerLifecycleState.CONTROLLER_IDLE ||
        controllerState === AudioControllerLifecycleState.CONTROLLER_ERROR,
      '开始检测',
      controllerState === AudioControllerLifecycleState.CONTROLLER_IDLE ?
        $r('sys.color.font_emphasize') : $r('sys.color.font_secondary')
    );

    // 停止按钮状态
    this.stopButton.update(
      controllerState === AudioControllerLifecycleState.CONTROLLER_RECORDING,
      '停止',
      controllerState === AudioControllerLifecycleState.CONTROLLER_RECORDING ?
        $r('sys.color.alert') : $r('sys.color.font_secondary')
    );

    // 重置按钮状态
    this.resetButton.update(
      controllerState === AudioControllerLifecycleState.CONTROLLER_IDLE ||
        controllerState === AudioControllerLifecycleState.CONTROLLER_RECORDING ||
        controllerState === AudioControllerLifecycleState.CONTROLLER_ERROR,
      '重置',
      $r('sys.color.comp_background_secondary')
    );

    // 保存按钮状态
    this.saveButton.update(
      controllerState === AudioControllerLifecycleState.CONTROLLER_RECORDING,
      '保存',
      $r('sys.color.confirm')
    );
  }
}

@ComponentV2
export struct AudioControlPanel {
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local pk: PreferenceKeys = PersistenceV2.connect(PreferenceKeys)!;
  @Local private controllerState: AudioControllerLifecycleState =
    AudioControllerService.getInstance(this.ak, this.pk).getStateMachine()?.getCurrentState()!;
  @Local private saveAnimationOpacity: number = 1.0;
  @Local private buttonStates: ButtonStates = new ButtonStates();
  @Local private inputDialogController: CustomDialogController = new CustomDialogController({
    builder: this.buildInputDialog,
    cancel: () => {
      console.info('[AudioControlPanel] 输入对话框已取消');
    },
    autoCancel: true
  });
  @Local private confirmDialogController: CustomDialogController = new CustomDialogController({
    builder: this.buildConfirmDialog,
    cancel: () => {
      console.info('[AudioControlPanel] 确认对话框已取消');
    },
    autoCancel: true
  });

  aboutToAppear(): void {
    this.initializeStateListener();
    // 初始化按钮状态
    this.buttonStates.updateStates(this.controllerState);
  }

  aboutToDisappear(): void {
  }

  // 状态监听初始化
  private initializeStateListener(): void {
    const audioControllerService = AudioControllerService.getInstance(this.ak, this.pk);

    // 确保状态机已初始化
    audioControllerService.initializeStateMachine();

    audioControllerService.onStateChangeFromExternal((event: StateTransitionEvent) => {
      this.controllerState = event.toState;
      // 更新按钮状态
      this.buttonStates.updateStates(this.controllerState);
      console.info(`[AudioControlPanel] 状态机状态变更: ${event.fromState} -> ${event.toState}`);
    });
  }

  build() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('音频检测控制')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
        .alignSelf(ItemAlign.Start)

      Row({ space: DesignConstants.SPACING_MD }) {
        // 开始检测按钮
        Button(this.buttonStates.startButton.text, { type: ButtonType.Capsule })
          .backgroundColor(this.buttonStates.startButton.backgroundColor)
          .fontColor(Color.White)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 8
          })
          .enabled(this.buttonStates.startButton.enabled)
          .onClick(() => {
            this.startDetection();
          })

        // 停止按钮
        Button(this.buttonStates.stopButton.text, { type: ButtonType.Capsule })
          .backgroundColor(this.buttonStates.stopButton.backgroundColor)
          .fontColor(Color.White)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 8
          })
          .enabled(this.buttonStates.stopButton.enabled)
          .onClick(() => {
            this.stopDetection();
          })

        // 重置按钮
        Button(this.buttonStates.resetButton.text, { type: ButtonType.Capsule })
          .backgroundColor(this.buttonStates.resetButton.backgroundColor)
          .fontColor($r('sys.color.font_primary'))
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 8
          })
          .enabled(this.buttonStates.resetButton.enabled)
          .onClick(() => {
            this.showResetConfirmation();
          })

        // 保存按钮
        Button(this.buttonStates.saveButton.text, { type: ButtonType.Capsule })
          .backgroundColor(this.buttonStates.saveButton.backgroundColor)
          .fontColor(Color.White)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .padding({
            left: 16,
            right: 16,
            top: 8,
            bottom: 8
          })
          .enabled(this.buttonStates.saveButton.enabled)
          .opacity(this.saveAnimationOpacity)
          .onClick(() => {
            this.showSaveDialog();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)

      // 状态显示
      Row({ space: DesignConstants.SPACING_SM }) {
        Text('状态:')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))

        Text(this.DetectionStatusText)
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor(this.getDetectionStatusColor())
          .fontWeight(FontWeight.Medium)

        if (this.controllerState === AudioControllerLifecycleState.CONTROLLER_RECORDING) {
          Text(this.ak.uiDisplayState.timeDisplay)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(DesignConstants.BORDER_RADIUS_LG)
  }

  // 开始检测
  private startDetection(): void {
    Throttle.click(async () => {
      try {
        const audioController = AudioControllerService.getInstance(this.ak, this.pk);
        await audioController.startRecordingFromExternal();
        console.info('[ToolsContent] 开始检测请求已通过状态机发送');
      } catch (error) {
        console.error('[ToolsContent] 启动检测失败:', error);
        // 可以在这里添加错误提示
      }
    });
  }

  // 停止检测（真正的停止，不会自动启动）
  private stopDetection(): void {
    Throttle.click(async () => {
      try {
        const audioController = AudioControllerService.getInstance(this.ak, this.pk);
        await audioController.stopRecordingFromExternal('手动停止');
        console.info('[ToolsContent] 停止检测请求已通过状态机发送');
      } catch (error) {
        console.error('[ToolsContent] 停止检测失败:', error);
      }
    });
  }

  // 显示重置确认对话框
  private showResetConfirmation(): void {
    Throttle.click(() => {
      this.confirmDialogController.open();
    });
  }

  // 重置数据
  private resetData(): void {
    Throttle.click(async () => {
      try {
        const audioController = AudioControllerService.getInstance(this.ak, this.pk);
        await audioController.resetStateFromExternal();
        console.info('[ToolsContent] 数据已通过状态机重置');
      } catch (error) {
        console.error('[ToolsContent] 重置数据失败:', error);
      }
    });
  }

  // 显示保存对话框
  private showSaveDialog(): void {
    Throttle.click(() => {
      this.inputDialogController.open();
    });
  }

  // 保存当前数据
  private saveCurrentData(comment: string): void {
    Throttle.click(async () => {
      this.startSaveAnimation();
      try {
        const audioController = AudioControllerService.getInstance(this.ak, this.pk);
        await audioController.restartRecordingFromExternal(comment);
        console.info('[ToolsContent] 数据已通过状态机保存，备注:', comment);

        // 延迟结束动画，让用户看到保存效果
        setTimeout(() => {
          this.endSaveAnimation();
          promptAction.showToast({ message: '保存成功' });
          // 保存完成后保持停止状态，不自动重新开始检测
          console.info('[ToolsContent] 数据保存完成，保持停止状态');
        }, 500);
      } catch (error) {
        console.error('[ToolsContent] 保存数据失败:', error);
        this.endSaveAnimation();
      }
    });
  }

  // 开始保存动画
  private startSaveAnimation(): void {
    // 更新按钮状态
    this.buttonStates.updateStates(this.controllerState);
    this.getUIContext().animateTo({
      duration: 300,
      curve: Curve.EaseInOut
    }, () => {
      this.saveAnimationOpacity = 0.7;
    });
    console.info('[ToolsContent] 开始保存动画');
  }

  // 结束保存动画
  private endSaveAnimation(): void {
    this.getUIContext().animateTo({
      duration: 300,
      curve: Curve.EaseInOut
    }, () => {
      this.saveAnimationOpacity = 1.0;
    });
    // 更新按钮状态
    this.buttonStates.updateStates(this.controllerState);
    console.info('[ToolsContent] 结束保存动画');
  }

  // 获取检测状态文本
  @Computed
  private get DetectionStatusText(): string {
    switch (this.controllerState) {
      case AudioControllerLifecycleState.CONTROLLER_IDLE:
        return '空闲';
      case AudioControllerLifecycleState.CONTROLLER_STARTING:
        return '启动中...';
      case AudioControllerLifecycleState.CONTROLLER_RECORDING:
        return '检测中';
      case AudioControllerLifecycleState.CONTROLLER_STOPPING:
        return '停止中...';
      case AudioControllerLifecycleState.CONTROLLER_PAUSING:
        return '停止中...';
      case AudioControllerLifecycleState.CONTROLLER_ERROR:
        return '错误 - 点击开始重试';
      default:
        return '未知状态';
    }
  }

  // 获取检测状态颜色
  private getDetectionStatusColor(): Resource {
    switch (this.controllerState) {
      case AudioControllerLifecycleState.CONTROLLER_RECORDING:
        return $r('sys.color.confirm');
      case AudioControllerLifecycleState.CONTROLLER_STARTING:
      case AudioControllerLifecycleState.CONTROLLER_STOPPING:
      case AudioControllerLifecycleState.CONTROLLER_PAUSING:
        return $r('sys.color.alert');
      case AudioControllerLifecycleState.CONTROLLER_ERROR:
        return $r('sys.color.alert');
      default:
        return $r('sys.color.font_secondary');
    }
  }

  // 构建输入对话框
  @Builder
  private buildInputDialog() {
    InputDialog({
      title: '保存数据',
      default: '',
      onConfirm: (comment: string) => {
        this.saveCurrentData(comment);
        this.inputDialogController.close();
      },
      onClose: () => {
        console.info('[ToolsContent] 输入对话框已关闭');
        this.inputDialogController.close();
      }
    })
  }

  // 构建确认对话框
  @Builder
  private buildConfirmDialog() {
    Column({ space: DesignConstants.SPACING_MD }) {
      Text('确认重置')
        .fontSize(DesignConstants.FONT_SIZE_LG)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))

      Text('确定要重置所有检测数据吗？此操作不可撤销。')
        .fontSize(DesignConstants.FONT_SIZE_MD)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center)

      Row({ space: DesignConstants.SPACING_MD }) {
        Button('取消', { type: ButtonType.Normal })
          .layoutWeight(1)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .fontColor($r('sys.color.font_primary'))
          .onClick(() => {
            this.confirmDialogController.close();
          })

        Button('确认重置', { type: ButtonType.Normal })
          .layoutWeight(1)
          .backgroundColor($r('sys.color.alert'))
          .fontColor(Color.White)
          .onClick(() => {
            this.resetData();
            this.confirmDialogController.close();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(DesignConstants.SPACING_MD)
  }
}