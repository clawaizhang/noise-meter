import bundleManager from '@ohos.bundle.bundleManager';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import buffer from '@ohos.buffer';

/**
 * 文件工具类
 * 提供静态方法处理应用内部存储文件的读写操作
 * 需要在应用启动时调用init方法初始化上下文
 */
export class FileUtils {
  private static context: common.Context | null = null;
  private static filesDir: string;

  /**
   * 初始化文件工具类
   * @param context - 应用上下文
   */
  static init(context: common.Context | undefined): void {
    if (!context) {
      throw new Error('Context is required');
    }
    FileUtils.context = context;
    FileUtils.filesDir = context.filesDir;
  }

  /**
   * 检查是否已初始化
   */
  private static checkInitialized(): void {
    if (!FileUtils.context || !FileUtils.filesDir) {
      throw new Error('FileUtils未初始化，请先调用FileUtils.init(context)');
    }
  }

  /**
   * 获取文件信息
   * @param fileName - 文件名
   * @returns Promise<fs.Stat>
   */
  static getFileInfoSync(fileName: string): fs.Stat {
    try {
      const filePath = `${FileUtils.filesDir}/${fileName}`;
      return fs.statSync(filePath);
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`获取文件信息失败: ${businessError.message}`);
      throw new Error(`获取文件信息失败: ${businessError.message}`);
    }
  }

  /**
   * 获取应用文件存储的基础路径
   * @returns string
   */
  static getBasePath(): string {
    FileUtils.checkInitialized();
    return FileUtils.filesDir!;
  }

  /**
   * 保存文件到应用内部存储
   * @param fileName - 文件名
   * @param content - 文件内容
   * @returns Promise<string> 返回保存文件的绝对路径
   */
  static async saveFile(fileName: string, content: string | ArrayBuffer): Promise<string> {
    try {
      FileUtils.checkInitialized();
      
      // 构建完整的文件路径
      const filePath = `${FileUtils.filesDir}/${fileName}`;
      
      // 如果是字符串内容，转换为ArrayBuffer
      const fileContent = typeof content === 'string' ?
        buffer.from(content).buffer : content;
      
      // 创建文件并写入内容
      const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      await fs.write(file.fd, fileContent);
      await fs.close(file.fd);

      return filePath;  // 返回绝对路径
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`保存文件失败: ${businessError.message}`);
      throw new Error(`保存文件失败: ${businessError.message}`);
    }
  }

  /**
   * 从应用内部存储读取文件
   * @param fileName - 文件名
   * @returns Promise<ArrayBuffer>
   */
  static async readFile(fileName: string): Promise<ArrayBuffer> {
    try {
      FileUtils.checkInitialized();
      
      const filePath = `${FileUtils.filesDir}/${fileName}`;
      
      // 检查文件是否存在
      const exists = await fs.access(filePath);
      if (!exists) {
        throw new Error(`文件不存在: ${fileName}`);
      }

      // 获取文件信息
      const fileInfo = await fs.stat(filePath);
      
      // 打开并读取文件
      const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
      const buffer = new ArrayBuffer(fileInfo.size);
      await fs.read(file.fd, buffer);
      await fs.close(file.fd);
      
      return buffer;
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`读取文件失败: ${businessError.message}`);
      throw new Error(`读取文件失败: ${businessError.message}`);
    }
  }

  /**
   * 删除文件
   * @param fileName - 文件名
   * @returns Promise<void>
   */
  static async deleteFile(fileName: string): Promise<void> {
    try {
      FileUtils.checkInitialized();
      
      const filePath = `${FileUtils.filesDir}/${fileName}`;
      await fs.unlink(filePath);
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`删除文件失败: ${businessError.message}`);
      throw new Error(`删除文件失败: ${businessError.message}`);
    }
  }

  /**
   * 检查文件是否存在
   * @param fileName - 文件名
   * @returns Promise<boolean>
   */
  static async exists(fileName: string): Promise<boolean> {
    try {
      FileUtils.checkInitialized();
      
      const filePath = `${FileUtils.filesDir}/${fileName}`;
      return await fs.access(filePath);
    } catch (error) {
      return false;
    }
  }

  /**
   * 获取文件信息
   * @param fileName - 文件名
   * @returns Promise<fs.Stat>
   */
  static async getFileInfo(fileName: string): Promise<fs.Stat> {
    try {
      FileUtils.checkInitialized();
      
      const filePath = `${FileUtils.filesDir}/${fileName}`;
      return await fs.stat(filePath);
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`获取文件信息失败: ${businessError.message}`);
      throw new Error(`获取文件信息失败: ${businessError.message}`);
    }
  }

  /**
   * 列出目录下的所有文件
   * @param directory - 相对于filesDir的目录路径，默认为根目录
   * @returns Promise<string[]>
   */
  async listFiles(directory: string = ''): Promise<string[]> {
    try {
      const dirPath = directory ? `${FileUtils.filesDir}/${directory}` : FileUtils.filesDir;
      return await fs.listFile(dirPath);
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`列出文件失败: ${businessError.message}`);
      throw new Error(`列出文件失败: ${businessError.message}`);
    }
  }

  /**
   * 创建目录
   * @param directory - 相对于filesDir的目录路径
   * @returns Promise<void>
   */
  static async createDirectory(directory: string): Promise<void> {
    try {
      FileUtils.checkInitialized();
      
      const dirPath = `${FileUtils.filesDir}/${directory}`;
      await fs.mkdir(dirPath);
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`创建目录失败: ${businessError.message}`);
      throw new Error(`创建目录失败: ${businessError.message}`);
    }
  }
}