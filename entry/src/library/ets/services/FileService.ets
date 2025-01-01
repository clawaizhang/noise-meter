import bundleManager from '@ohos.bundle.bundleManager';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import buffer from '@ohos.buffer';

/**
 * 文件服务类
 * 用于处理应用内部存储文件的读写操作
 */
export class FileService {
  private context: common.Context;
  private filesDir: string;

  constructor(context: common.Context) {
    this.context = context;
    // 获取应用文件目录
    this.filesDir = this.context.filesDir;
  }

  /**
   * 保存文件到应用内部存储
   * @param fileName - 文件名
   * @param content - 文件内容
   * @returns Promise<void>
   */
  async saveFile(fileName: string, content: string | ArrayBuffer): Promise<void> {
    try {
      // 构建完整的文件路径
      const filePath = `${this.filesDir}/${fileName}`;
      
      // 如果是字符串内容，转换为ArrayBuffer
      const fileContent = typeof content === 'string' ? 
        buffer.from(content).buffer : content;
      
      // 创建文件并写入内容
      const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      await fs.write(file.fd, fileContent);
      await fs.close(file.fd);
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
  async readFile(fileName: string): Promise<ArrayBuffer> {
    try {
      const filePath = `${this.filesDir}/${fileName}`;
      
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
  async deleteFile(fileName: string): Promise<void> {
    try {
      const filePath = `${this.filesDir}/${fileName}`;
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
  async exists(fileName: string): Promise<boolean> {
    try {
      const filePath = `${this.filesDir}/${fileName}`;
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
  async getFileInfo(fileName: string): Promise<fs.Stat> {
    try {
      const filePath = `${this.filesDir}/${fileName}`;
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
      const dirPath = directory ? `${this.filesDir}/${directory}` : this.filesDir;
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
  async createDirectory(directory: string): Promise<void> {
    try {
      const dirPath = `${this.filesDir}/${directory}`;
      await fs.mkdir(dirPath);
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`创建目录失败: ${businessError.message}`);
      throw new Error(`创建目录失败: ${businessError.message}`);
    }
  }
} 