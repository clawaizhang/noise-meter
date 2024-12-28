import { ComponentContent, promptAction } from '@kit.ArkUI';
import { DecibelRecord } from '@ohos/library/src/main/ets/models/DecibelRecord';

export interface DialogParams {
  selectedRecord: DecibelRecord | null;
  closeDialog: () => void;
}

export class DialogService {
  async showDetailDialog(context: UIContext, wrappedBuilder: WrappedBuilder<[DialogParams]>,
    record: DecibelRecord | null): Promise<void> {
    try {
      const promptAction = context.getPromptAction();
      let dialogContent: ComponentContent<DialogParams>;

      // 创建关闭函数
      const closeDialog = () => {
        try {
          promptAction.closeCustomDialog(dialogContent);
        } catch (error) {
          console.error('关闭弹窗失败:', error);
        }
      };

      // 创建弹窗内容
      const dialogParams: DialogParams = {
        selectedRecord: record,
        closeDialog: closeDialog
      };

      dialogContent = new ComponentContent(
        context,
        wrappedBuilder,
        dialogParams
      );

      // 创建弹窗配置
      const dialogOptions: promptAction.BaseDialogOptions = {
        alignment: DialogAlignment.Bottom,
        offset: { dx: 0, dy: 0 },
        autoCancel: false,
        transition: TransitionEffect.move(TransitionEdge.BOTTOM).animation({
          duration: 300,
          curve: Curve.EaseOut
        })
      };

      // 显示弹窗
      await promptAction.openCustomDialog(dialogContent, dialogOptions);
    } catch (error) {
      console.error('打开弹窗失败:', error);
    }
  }
} 