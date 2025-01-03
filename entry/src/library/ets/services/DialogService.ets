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
      console.info('开始显示详情弹窗');
      
      // 检查参数
      if (!context || !wrappedBuilder || !appContext) {
        console.error('显示弹窗失败: 参数无效', { context, wrappedBuilder, appContext });
        return;
      }

      // 初始化或获取FileService实例
      if (!this.fileService) {
        console.info('初始化FileService');
        this.fileService = new FileService(appContext);
      }

      const promptAction = context.getPromptAction();
      if (!promptAction) {
        console.error('获取promptAction失败');
        return;
      }
      
      let dialogContent: ComponentContent<DialogParams>;

      // 创建关闭函数
      const closeDialog = () => {
        try {
          console.info('关闭弹窗');
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

      console.info('创建弹窗内容');
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

      console.info('准备显示弹窗');
      // 显示弹窗
      await promptAction.openCustomDialog(dialogContent, dialogOptions);
      console.info('弹窗显示成功');
    } catch (error) {
      console.error('打开弹窗失败:', error);
      // 显示错误提示
      promptAction.showToast({
        message: '显示详情失败：' + (error instanceof Error ? error.message : String(error)),
        duration: 3000
      });
    }
  }
} 