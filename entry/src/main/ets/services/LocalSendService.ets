import { LocalSendDevice, DeviceStatus, DeviceType } from '../models/LocalSendDevice'
import { LocalSendFile, FileTransfer, FileType } from '../models/LocalSendFile'
import { LocalSendTransfer, TransferStatus, TransferDirection } from '../models/LocalSendTransfer'
import { connection } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { socket } from '@kit.NetworkKit'
import { http } from '@kit.NetworkKit'
import wifiManager from '@ohos.wifiManager'
import deviceInfo from '@ohos.deviceInfo'
import { util } from '@kit.ArkTS'
import fs from '@ohos.file.fs'
import buffer from '@ohos.buffer'
import common from '@ohos.app.ability.common'
import { preferences } from '@kit.ArkData'

interface DeviceInfoData {
  alias: string;
  version: string;
  deviceModel: string;
  deviceType: string;
  fingerprint: string;
  port: number;
}

interface UDPMessageData {
  address: string;
  port: number;
  data: ArrayBuffer;
}

interface FileReceptionState {
  totalChunks: number;
  receivedChunks: ArrayBuffer[];
}

export class LocalSendService {
  private static instance: LocalSendService
  private devices: LocalSendDevice[] = []
  private transfers: LocalSendTransfer[] = []
  private udpSocket: socket.UDPSocket | null = null
  private discoveryInterval: number | null = null
  private preferences: preferences.Preferences | null = null
  private context: common.Context | null = null
  private readonly DISCOVERY_PORT = 53317
  private readonly HTTP_PORT = 53317
  private readonly TRANSFER_PORT = 53317
  private readonly DISCOVERY_MESSAGE = 'LocalSend'
  private readonly TRANSFERS_KEY = 'local_send_transfers'
  private fileReceptions: Map<string, FileReceptionState> = new Map()

  static getInstance(): LocalSendService {
    if (!LocalSendService.instance) {
      LocalSendService.instance = new LocalSendService()
    }
    return LocalSendService.instance
  }

  private constructor() {
    this.initializeSocket()
    this.loadTransfersFromStorage()
  }

  async initializePreferences(context: common.Context): Promise<void> {
    try {
      this.context = context
      const options: preferences.Options = {
        name: 'local_send_data'
      }
      this.preferences = preferences.getPreferencesSync(context, options)
      console.log('LocalSend preferences initialized')
    } catch (error) {
      console.error('初始化首选项失败:', error)
    }
  }

  async discoverDevices(): Promise<LocalSendDevice[]> {
    try {
      // 清空旧设备列表
      this.devices = []
      
      // 添加当前设备
      this.addCurrentDevice()
      
      // 开始广播发现消息
      await this.broadcastDiscovery()
      
      // 设置超时，3秒后停止发现
      setTimeout(() => {
        this.stopDiscovery()
      }, 3000)
      
      return this.devices
    } catch (error) {
      console.error('设备发现失败:', error)
      // 失败时返回模拟设备
      return this.getMockDevices()
    }
  }

  private initializeSocket(): void {
    try {
      this.udpSocket = socket.constructUDPSocketInstance()
      
      // 绑定到随机端口接收消息
      this.udpSocket.bind({ address: '0.0.0.0', port: 0 }, (err: BusinessError) => {
        if (err) {
          console.error('绑定UDP socket失败:', err)
          return
        }
        
        // 监听接收消息
        this.udpSocket?.on('message', (data: socket.SocketMessageInfo) => {
          const udpMessageData: UDPMessageData = {
            address: data.remoteInfo?.address || '',
            port: data.remoteInfo?.port || 0,
            data: data.message
          }
          this.handleDiscoveryMessage(udpMessageData)
        })
      })
    } catch (error) {
      console.error('初始化socket失败:', error)
    }
  }

  // LocalSend使用HTTP协议进行文件传输，不需要TCP服务器

  private async broadcastDiscovery(): Promise<void> {
    if (!this.udpSocket) return
    
    // 获取本地IP地址
    const localIp = await this.getWifiIpAddress();
    if (!localIp) return
    
    // 构建广播地址
    const broadcastIp = this.getBroadcastAddress(localIp)
    
    // 构建LocalSend协议格式的设备信息
    const deviceInfoData: DeviceInfoData = {
      alias: deviceInfo.marketName || 'HarmonyOS Device',
      version: '1.0',
      deviceModel: deviceInfo.productModel || 'Unknown Model',
      deviceType: 'phone',
      fingerprint: `harmony-${deviceInfo.udid || 'unknown'}`,
      port: this.HTTP_PORT
    }
    
    const discoveryMessage = `${this.DISCOVERY_MESSAGE}/${JSON.stringify(deviceInfoData)}`
    
    // 发送广播消息
    const messageBuffer = new util.TextEncoder().encodeInto(discoveryMessage)
    this.udpSocket.send({
      address: { address: broadcastIp, family: 1 }, // family: 1 for IPv4
      data: messageBuffer
    }, (err: BusinessError) => {
      if (err) {
        console.error('发送广播失败:', err)
      }
    })
  }

  private handleDiscoveryMessage(data: UDPMessageData): void {
    const message = new util.TextDecoder().decode(new Uint8Array(data.data))
    
    // 解析LocalSend协议格式: LocalSend/{"alias":"deviceName",...}
    if (message.startsWith(this.DISCOVERY_MESSAGE + '/')) {
      try {
        const jsonStr = message.substring(this.DISCOVERY_MESSAGE.length + 1)
        const deviceInfoParsed = JSON.parse(jsonStr) as DeviceInfoData
        
        this.addDiscoveredDeviceWithInfo(data.address, data.port, deviceInfoParsed)
      } catch (error) {
        console.error('解析设备信息失败:', error)
        // 回退到基本设备发现
        this.addDiscoveredDevice(data.address, data.port)
      }
    } else if (message === this.DISCOVERY_MESSAGE) {
      // 兼容旧格式
      this.addDiscoveredDevice(data.address, data.port)
    }
  }

  private addDiscoveredDeviceWithInfo(ipAddress: string, port: number, deviceInfoData: DeviceInfoData): void {
    // 避免重复添加
    if (this.devices.some(device => device.ipAddress === ipAddress)) {
      return
    }
    
    const device: LocalSendDevice = {
      id: deviceInfoData.fingerprint || `device-${ipAddress}`,
      name: deviceInfoData.alias || `Device (${ipAddress})`,
      ipAddress: ipAddress,
      deviceType: this.mapDeviceType(deviceInfoData.deviceType),
      status: DeviceStatus.ONLINE,
      lastSeen: Date.now(),
      isCurrentDevice: false,
      deviceModel: deviceInfoData.deviceModel,
      port: deviceInfoData.port || this.TRANSFER_PORT
    }
    
    this.devices.push(device)
    this.notifyDevicesUpdate()
  }

  private addDiscoveredDevice(ipAddress: string, port: number): void {
    // 避免重复添加
    if (this.devices.some(device => device.ipAddress === ipAddress)) {
      return
    }
    
    const device: LocalSendDevice = {
      id: `device-${ipAddress}`,
      name: `LocalSend Device (${ipAddress})`,
      ipAddress: ipAddress,
      deviceType: DeviceType.OTHER,
      status: DeviceStatus.ONLINE,
      lastSeen: Date.now(),
      isCurrentDevice: false,
      port: this.TRANSFER_PORT
    }
    
    this.devices.push(device)
    this.notifyDevicesUpdate()
  }

  private mapDeviceType(type: string): DeviceType {
    switch (type?.toLowerCase()) {
      case 'phone': return DeviceType.PHONE
      case 'tablet': return DeviceType.TABLET
      case 'computer': return DeviceType.COMPUTER
      default: return DeviceType.OTHER
    }
  }

  private addCurrentDevice(): void {
    const currentDevice: LocalSendDevice = {
      id: 'current-device',
      name: deviceInfo.marketName || 'HarmonyOS Device',
      ipAddress: '',
      deviceType: DeviceType.PHONE,
      status: DeviceStatus.ONLINE,
      lastSeen: Date.now(),
      isCurrentDevice: true,
      deviceModel: deviceInfo.productModel || 'Unknown Model',
      osVersion: deviceInfo.osFullName || 'HarmonyOS',
      port: this.TRANSFER_PORT
    }
    
    this.devices.push(currentDevice)
  }

  private getBroadcastAddress(ipAddress: string): string {
    // 简单实现：假设是192.168.x.x网段
    const parts = ipAddress.split('.')
    if (parts.length === 4 && parts[0] === '192' && parts[1] === '168') {
      return `192.168.${parts[2]}.255`
    }
    return '255.255.255.255' // 全网络广播
  }

  private stopDiscovery(): void {
    if (this.discoveryInterval) {
      clearInterval(this.discoveryInterval)
      this.discoveryInterval = null
    }
  }

  // LocalSend使用HTTP协议，不需要处理原始TCP数据

  private getMockDevices(): LocalSendDevice[] {
    // 模拟设备用于测试
    return [
      {
        id: 'device-1',
        name: '华为 Mate 60',
        ipAddress: '192.168.1.101',
        deviceType: DeviceType.PHONE,
        status: DeviceStatus.ONLINE,
        lastSeen: Date.now(),
        isCurrentDevice: false
      },
      {
        id: 'device-2', 
        name: '小米 Pad 6',
        ipAddress: '192.168.1.102',
        deviceType: DeviceType.TABLET,
        status: DeviceStatus.ONLINE,
        lastSeen: Date.now(),
        isCurrentDevice: false
      }
    ]
  }

  private notifyDevicesUpdate(): void {
    // 这里可以添加事件通知机制
    console.log('设备列表更新:', this.devices)
  }

  private async loadTransfersFromStorage(): Promise<void> {
    if (!this.preferences) {
      console.log('Preferences not initialized, skipping transfer loading')
      return
    }

    try {
      const transfersJson = this.preferences.getSync(this.TRANSFERS_KEY, '[]')
      if (typeof transfersJson === 'string') {
        const transfers = JSON.parse(transfersJson) as LocalSendTransfer[]
        this.transfers = transfers.filter(transfer => 
          transfer.status === TransferStatus.IN_PROGRESS || 
          transfer.status === TransferStatus.QUEUED
        )
        console.log('Loaded transfers from storage:', this.transfers.length)
      }
    } catch (error) {
      console.error('加载传输记录失败:', error)
    }
  }

  private async saveTransfersToStorage(): Promise<void> {
    if (!this.preferences) {
      console.log('Preferences not initialized, skipping transfer saving')
      return
    }

    try {
      // 只保存最近100条传输记录
      const recentTransfers = this.transfers
        .sort((a, b) => b.startTime - a.startTime)
        .slice(0, 100)
      
      const transfersJson = JSON.stringify(recentTransfers)
      this.preferences.put(this.TRANSFERS_KEY, transfersJson)
      
      await new Promise<void>((resolve, reject) => {
        this.preferences!.flush((err: BusinessError) => {
          if (err) {
            console.error('保存传输记录到持久化存储失败:', err)
            reject(err)
          } else {
            console.log('传输记录已保存到持久化存储')
            resolve()
          }
        })
      })
    } catch (error) {
      console.error('保存传输记录失败:', error)
    }
  }

  async sendFiles(files: LocalSendFile[], targetDeviceId: string): Promise<string> {
    const transferId = `transfer-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
    
    const targetDevice = this.devices.find(device => device.id === targetDeviceId)
    if (!targetDevice) {
      throw new Error('目标设备未找到')
    }

    // 创建传输记录
    files.forEach(file => {
      const transfer: LocalSendTransfer = {
        id: `${transferId}-${file.id}`,
        fileId: file.id,
        fileName: file.name,
        fileSize: file.size,
        deviceId: targetDeviceId,
        deviceName: targetDevice.name,
        direction: TransferDirection.SEND,
        status: TransferStatus.QUEUED,
        progress: 0,
        startTime: Date.now(),
        fileType: file.type
      }
      this.transfers.push(transfer)
    })

    // 开始实际传输
    this.startFileTransfer(transferId, files, targetDevice)
    
    return transferId
  }

  private async startFileTransfer(transferId: string, files: LocalSendFile[], targetDevice: LocalSendDevice): Promise<void> {
    const relatedTransfers = this.transfers.filter(t => t.id.startsWith(transferId))
    
    for (let i = 0; i < files.length; i++) {
      const file = files[i]
      const transfer = relatedTransfers[i]
      
      if (!transfer) continue
      
      try {
        transfer.status = TransferStatus.IN_PROGRESS
        this.notifyTransferUpdate(transfer)
        
        // 实际文件传输逻辑
        await this.transferFile(file, transfer, targetDevice)
        
        transfer.status = TransferStatus.COMPLETED
        transfer.progress = 100
        transfer.endTime = Date.now()
        
      } catch (error) {
        console.error('文件传输失败:', error)
        transfer.status = TransferStatus.FAILED
        transfer.errorMessage = error instanceof Error ? error.message : '未知错误'
      }
      
      this.notifyTransferUpdate(transfer)
    }
  }

  private async transferFile(file: LocalSendFile, transfer: LocalSendTransfer, targetDevice: LocalSendDevice): Promise<void> {
    try {
      // 读取文件内容
      const fileContent = await this.readFileContent(file)
      
      // 创建HTTP请求
      const httpRequest = http.createHttp()
      
      // 构建目标URL
      const targetUrl = `http://${targetDevice.ipAddress}:${targetDevice.port || this.HTTP_PORT}/api/file`
      
      // 使用HTTP流式传输发送文件
      transfer.status = TransferStatus.IN_PROGRESS
      this.notifyTransferUpdate(transfer)
      
      // 监听上传进度
      httpRequest.on('dataSendProgress', (progressInfo: http.DataSendProgressInfo) => {
        const progress = Math.min(100, Math.round((progressInfo.sendSize / progressInfo.totalSize) * 100))
        transfer.progress = progress
        this.notifyTransferUpdate(transfer)
      })
      
      // 发送HTTP POST请求
      await new Promise<void>((resolve, reject) => {
        httpRequest.request(
          targetUrl,
          {
            method: http.RequestMethod.POST,
            header: {
              'Content-Type': 'application/octet-stream',
              'X-File-Name': encodeURIComponent(file.name),
              'X-File-Size': file.size.toString(),
              'X-File-Type': file.type
            },
            extraData: fileContent,
            connectTimeout: 30000,
            readTimeout: 60000
          },
          (err: BusinessError, response: http.HttpResponse) => {
            httpRequest.destroy()
            
            if (err) {
              reject(new Error(`HTTP请求失败: ${err.message}`))
            } else if (response.responseCode === 200) {
              transfer.status = TransferStatus.COMPLETED
              transfer.progress = 100
              transfer.endTime = Date.now()
              this.notifyTransferUpdate(transfer)
              resolve()
            } else {
              reject(new Error(`服务器返回错误: ${response.responseCode}`))
            }
          }
        )
      })
      
    } catch (error) {
      console.error('文件传输失败:', error)
      transfer.status = TransferStatus.FAILED
      transfer.errorMessage = error instanceof Error ? error.message : '传输失败'
      this.notifyTransferUpdate(transfer)
      throw new Error(error instanceof Error ? error.message : '传输失败')
    }
  }

  private startFileReception(fileName: string, totalChunks: number): void {
    this.fileReceptions.set(fileName, {
      totalChunks: totalChunks,
      receivedChunks: new Array(totalChunks)
    })
    console.log('开始接收文件:', fileName, '总块数:', totalChunks)
  }

  private saveFileChunk(fileName: string, chunkData: ArrayBuffer, chunkIndex: number): void {
    const reception = this.fileReceptions.get(fileName)
    if (reception && chunkIndex < reception.totalChunks) {
      reception.receivedChunks[chunkIndex] = chunkData
      
      // 计算接收进度
      const receivedCount = reception.receivedChunks.filter(chunk => chunk !== undefined).length
      const progress = Math.round((receivedCount / reception.totalChunks) * 100)
      
      console.log('文件接收进度:', fileName, progress + '%')
    }
  }

  private async completeFileReception(fileName: string): Promise<void> {
    const reception = this.fileReceptions.get(fileName)
    if (!reception) return
    
    try {
      // 合并所有数据块
      const totalSize = reception.receivedChunks.reduce((sum, chunk) => sum + (chunk?.byteLength || 0), 0)
      const combinedData = new ArrayBuffer(totalSize)
      const combinedView = new Uint8Array(combinedData)
      
      let offset = 0
      for (const chunk of reception.receivedChunks) {
        if (chunk) {
          combinedView.set(new Uint8Array(chunk), offset)
          offset += chunk.byteLength
        }
      }
      
      // 创建接收目录
      const receiveDir = `${this.context?.filesDir || '/tmp'}/received`
      await fs.mkdir(receiveDir, true)
      
      // 保存文件
      const filePath = `${receiveDir}/${fileName}`
      const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE)
      await fs.write(file.fd, combinedData)
      await fs.close(file.fd)
      
      // 创建传输记录
      const receivedTransfer: LocalSendTransfer = {
        id: `receive-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        fileId: `file-${Date.now()}`,
        fileName: fileName,
        fileSize: totalSize,
        deviceId: 'current-device',
        deviceName: deviceInfo.marketName || 'HarmonyOS Device',
        direction: TransferDirection.RECEIVE,
        status: TransferStatus.COMPLETED,
        progress: 100,
        startTime: Date.now(),
        endTime: Date.now(),
        fileType: this.getFileTypeFromName(fileName)
      }
      
      this.transfers.push(receivedTransfer)
      this.notifyTransferUpdate(receivedTransfer)
      
      // 清理接收状态
      this.fileReceptions.delete(fileName)
      
      console.log('文件接收完成:', fileName, '大小:', totalSize, '字节')
      
    } catch (error) {
      console.error('完成文件接收失败:', error)
      this.fileReceptions.delete(fileName)
    }
  }

  private async readFileContent(file: LocalSendFile): Promise<ArrayBuffer> {
    try {
      // 在实际应用中，这里会根据文件URI读取文件内容
      // 由于当前是模拟文件，返回模拟数据
      const mockContent = new ArrayBuffer(file.size)
      return mockContent
    } catch (error) {
      console.error('读取文件内容失败:', error)
      throw new Error('读取文件失败')
    }
  }

  private getFileTypeFromName(fileName: string): FileType {
    const ext = fileName.toLowerCase().split('.').pop() || ''
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].includes(ext)) {
      return FileType.IMAGE
    } else if (['mp4', 'avi', 'mov', 'wmv', 'flv'].includes(ext)) {
      return FileType.VIDEO
    } else if (['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'].includes(ext)) {
      return FileType.DOCUMENT
    }
    return FileType.OTHER
  }

  private async saveReceivedFile(file: LocalSendFile, targetDevice: LocalSendDevice): Promise<void> {
    // 保留原有模拟接收逻辑
    const receivedTransfer: LocalSendTransfer = {
      id: `receive-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      fileId: file.id,
      fileName: file.name,
      fileSize: file.size,
      deviceId: 'current-device',
      deviceName: deviceInfo.marketName || 'HarmonyOS Device',
      direction: TransferDirection.RECEIVE,
      status: TransferStatus.COMPLETED,
      progress: 100,
      startTime: Date.now(),
      endTime: Date.now(),
      fileType: file.type
    }
    
    this.transfers.push(receivedTransfer)
    this.notifyTransferUpdate(receivedTransfer)
  }

  getTransfers(): LocalSendTransfer[] {
    return this.transfers
  }

  getTransferById(transferId: string): LocalSendTransfer | undefined {
    return this.transfers.find(t => t.id === transferId)
  }

  async selectFiles(): Promise<LocalSendFile[]> {
    try {
      // 在实际应用中，这里会调用系统文件选择器
      // 由于HarmonyOS文件选择器需要特定权限和UI，这里返回模拟文件
      
      const mockFiles: LocalSendFile[] = [
        {
          id: 'file-1',
          name: 'document.pdf',
          path: '/sdcard/Documents/document.pdf',
          size: 1024 * 1024 * 2, // 2MB
          type: FileType.DOCUMENT,
          mimeType: 'application/pdf',
          lastModified: Date.now(),
          uri: 'file:///sdcard/Documents/document.pdf'
        },
        {
          id: 'file-2',
          name: 'image.jpg',
          path: '/sdcard/Pictures/image.jpg',
          size: 1024 * 1024 * 5, // 5MB
          type: FileType.IMAGE,
          mimeType: 'image/jpeg',
          lastModified: Date.now() - 3600000,
          uri: 'file:///sdcard/Pictures/image.jpg'
        },
        {
          id: 'file-3',
          name: 'video.mp4',
          path: '/sdcard/Movies/video.mp4',
          size: 1024 * 1024 * 50, // 50MB
          type: FileType.VIDEO,
          mimeType: 'video/mp4',
          lastModified: Date.now() - 86400000,
          uri: 'file:///sdcard/Movies/video.mp4'
        }
      ]
      
      return mockFiles
    } catch (error) {
      console.error('选择文件失败:', error)
      throw new Error('选择文件失败')
    }
  }

  cancelTransfer(transferId: string): void {
    const transfer = this.transfers.find(t => t.id === transferId)
    if (transfer) {
      if (transfer.status === TransferStatus.IN_PROGRESS) {
        // 在实际应用中，这里会关闭TCP连接
        transfer.status = TransferStatus.CANCELLED
        transfer.endTime = Date.now()
        this.notifyTransferUpdate(transfer)
        console.log('传输已取消:', transferId)
      } else if (transfer.status === TransferStatus.QUEUED) {
        // 移除排队中的传输
        this.transfers = this.transfers.filter(t => t.id !== transferId)
        console.log('排队传输已移除:', transferId)
      }
    }
  }

  private notifyTransferUpdate(transfer: LocalSendTransfer): void {
    // 这里可以添加事件通知机制
    console.log('传输更新:', transfer)
    
    // 保存到存储
    this.saveTransfersToStorage().catch((error: Error) => {
      console.error('保存传输记录失败:', error)
    })
  }

  clearCompletedTransfers(): void {
    this.transfers = this.transfers.filter(t =>
      t.status !== TransferStatus.COMPLETED &&
      t.status !== TransferStatus.CANCELLED
    )
  }

  /**
   * 获取Wi-Fi IP地址信息
   * @returns Promise<string> IP地址字符串
   */
  async getWifiIpAddress(): Promise<string> {
    try {
      console.log('开始获取Wi-Fi IP地址信息...')
      
      // 获取IP信息
      const ipInfo = wifiManager.getIpInfo()
      console.log('获取到的IP信息:', JSON.stringify(ipInfo))
      
      if (!ipInfo || ipInfo.ipAddress === 0) {
        throw new Error('无法获取有效的IP地址信息')
      }
      
      // 转换IP地址格式
      const ipAddress = this.convertIpAddress(ipInfo.ipAddress)
      console.log('转换后的IP地址:', ipAddress)
      
      return ipAddress
      
    } catch (error) {
      console.error('获取Wi-Fi IP地址失败:', error)
      throw new Error(`获取Wi-Fi IP地址失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 转换IP地址格式
   * @param ipAddress 整型IP地址
   * @returns string 格式化的IP地址字符串
   */
  private convertIpAddress(ipAddress: number): string {
    return (ipAddress >>> 24) + '.' +
           (ipAddress >> 16 & 0xFF) + '.' +
           (ipAddress >> 8 & 0xFF) + '.' +
           (ipAddress & 0xFF)
  }

  /**
   * 获取网络链路信息
   * @returns Promise<wifiManager.WifiLinkedInfo> 网络链路信息
   */
  async getLinkedInfo(): Promise<wifiManager.WifiLinkedInfo> {
    try {
      console.log('开始获取网络链路信息...')
      
      return new Promise<wifiManager.WifiLinkedInfo>((resolve, reject) => {
        wifiManager.getLinkedInfo((err: BusinessError, data: wifiManager.WifiLinkedInfo) => {
          if (err) {
            console.error('获取网络链路信息失败:', err)
            reject(new Error(`获取网络链路信息失败: ${err.message}`))
          } else {
            console.log('获取到的网络链路信息:', JSON.stringify(data))
            resolve(data)
          }
        })
      })
      
    } catch (error) {
      console.error('获取网络链路信息异常:', error)
      throw new Error(`获取网络链路信息异常: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }

  /**
   * 获取完整的Wi-Fi信息（包括IP地址和链路信息）
   * @returns Promise<FullWifiInfo> 包含IP地址和链路信息的对象
   */
  async getFullWifiInfo(): Promise<FullWifiInfo> {
    try {
      console.log('开始获取完整的Wi-Fi信息...')
      
      const ipAddressPromise = this.getWifiIpAddress();
      const linkedInfoPromise = this.getLinkedInfo();
      
      const ipAddress = await ipAddressPromise;
      const linkedInfo = await linkedInfoPromise;
      
      const result: FullWifiInfo = {
        ipAddress: ipAddress,
        linkedInfo: linkedInfo
      }
      
      return result;
      
    } catch (error) {
      console.error('获取完整Wi-Fi信息失败:', error)
      throw new Error(`获取完整Wi-Fi信息失败: ${error instanceof Error ? error.message : '未知错误'}`)
    }
  }
}

// 定义完整的Wi-Fi信息接口
interface FullWifiInfo {
  ipAddress: string;
  linkedInfo: wifiManager.WifiLinkedInfo;
}