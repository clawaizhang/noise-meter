import { ComponentContent, promptAction } from '@kit.ArkUI';
import { DecibelRecord } from '../models/DecibelRecord';
import common from '@ohos.app.ability.common';
import { FileService } from './FileService';

export interface DialogParams {
  selectedRecord: DecibelRecord | null;
  closeDialog: () => void;
  context: common.Context;
  fileService: FileService | null;
}

export class DialogService {
  private fileService: FileService | null = null;

  async showDetailDialog(context: UIContext, wrappedBuilder: WrappedBuilder<[DialogParams]>,
    record: DecibelRecord | null, appContext: common.Context): Promise<void> {
    try {
      // 初始化或获取FileService实例
      if (!this.fileService) {
        this.fileService = new FileService(appContext);
      }

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
        closeDialog: closeDialog,
        context: appContext,
        fileService: this.fileService  // 传递缓存的FileService实例
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