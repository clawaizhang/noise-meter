# 噪音检测记录分析软件源代码

## 引言

本文档包含噪音检测记录分析软件的完整源代码。该软件使用ArkTS语言开发,基于HarmonyOS Next平台。

软件名称: 噪音检测记录分析软件 V1.0
版本号: 1.0.0
开发完成日期: 2024年1月3日
首次发表日期: 2024年1月4日
发表地点: 中国四川省成都市新津区
著作权人: 张雨

## 源代码清单

### 一、应用框架代码

#### 1. 入口能力(EntryAbility.ets)
```typescript
// 应用入口能力类,负责应用生命周期管理
import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { BusinessError } from '@ohos.base';

export default class EntryAbility extends UIAbility {
  onCreate() {
    console.info('EntryAbility onCreate');
  }

  onDestroy() {
    console.info('EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    console.info('EntryAbility onWindowStageCreate');
    try {
      windowStage.loadContent('pages/Index', (err) => {
        if (err) {
          const businessError = err as BusinessError;
          console.error(`加载内容失败: ${businessError.code}, ${businessError.message}`);
          return;
        }
        console.info('成功加载内容');
      });
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`加载内容异常: ${businessError.code}, ${businessError.message}`);
    }
  }

  onWindowStageDestroy() {
    console.info('EntryAbility onWindowStageDestroy');
  }

  onForeground() {
    console.info('EntryAbility onForeground');
  }

  onBackground() {
    console.info('EntryAbility onBackground');
  }
}
```

#### 2. 主页面(Index.ets)
```typescript
// 应用主页面,负责页面布局和导航
import { BusinessError } from '@ohos.base';
import { RelationalStoreService } from '../library/ets/services/RelationalStoreService';

@Entry
@Component
struct Index {
  @State isLoading: boolean = true;
  @State hasError: boolean = false;
  private storeService: RelationalStoreService = new RelationalStoreService(getContext(), 'decibel_records.db');

  aboutToAppear() {
    this.initDatabase();
  }

  async initDatabase() {
    try {
      const SQL_CREATE_TABLE = `
        CREATE TABLE IF NOT EXISTS decibel_records (
          id TEXT PRIMARY KEY NOT NULL,
          timestamp INTEGER NOT NULL,
          minDecibel REAL NOT NULL,
          maxDecibel REAL NOT NULL,
          avgDecibel REAL NOT NULL,
          duration INTEGER NOT NULL,
          decibelValues TEXT NOT NULL,
          location TEXT,
          audioFilePath TEXT,
          isFavorite INTEGER DEFAULT 0
        )
      `;
      
      this.storeService.setInitSql(SQL_CREATE_TABLE);
      await this.storeService.getStore();
      this.isLoading = false;
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(`初始化数据库失败: ${businessError.message}`);
      this.hasError = true;
      this.isLoading = false;
    }
  }

  build() {
    Stack() {
      if (this.isLoading) {
        LoadingProgress()
          .color('#007DFF')
          .width(60)
          .height(60)
      } else if (this.hasError) {
        Column() {
          Image($r('app.media.ic_error'))
            .width(64)
            .height(64)
          Text('初始化失败')
            .fontSize(16)
            .margin({ top: 8 })
        }
      } else {
        Tabs() {
          TabContent() {
            NoiseMeter()
          }
          .tabBar('噪音计')

          TabContent() {
            DecibelHistory()
          }
          .tabBar('历史记录')

          TabContent() {
            FileVault()
          }
          .tabBar('文件保险箱')
        }
      }
    }
    .width('100%')
    .height('100%')
  }
}
```

### 二、核心功能代码

#### 1. 噪音计组件(DecibelMeter.ets)
```typescript
// 噪音计主组件,负责音频采集和分贝计算
@ComponentV2
export struct DecibelMeter {
  @Local private currentDecibel: number = 0
  @Local private minDecibel: number = 0
  @Local private maxDecibel: number = 0
  @Local private avgDecibel: number = 0
  @Local private isRecording: boolean = false
  private decibelService: DecibelService = new DecibelService()
  private audioService: AudioService = new AudioService()
  private locationService: LocationService = LocationService.getInstance()
  private recordService: DecibelRecordService = new DecibelRecordService()

  private async startRecording() {
    try {
      this.isRecording = true;
      this.startTime = new Date().getTime();
      
      await this.audioService.startCapture();
      this.audioService.startProcessing((buffer: ArrayBuffer) => {
        const db = this.decibelService.calculateDecibel(buffer, buffer.byteLength);
        this.currentDecibel = Math.round(db);
        this.updateStatistics(this.currentDecibel);
      });
    } catch (error) {
      this.isRecording = false;
      console.error('启动录音失败:', error);
    }
  }

  private async stopRecording() {
    if (this.isRecording) {
      this.isRecording = false;
      const locationInfo = this.locationService.getCachedLocation();
      const duration = new Date().getTime() - this.startTime;
      
      const record = new DecibelRecord(
        this.minDecibel,
        this.maxDecibel,
        this.avgDecibel,
        duration,
        this.values,
        locationInfo?.address
      );
      
      await this.recordService.saveRecord(record);
    }
  }

  // ... 其他UI构建和辅助方法 ...
}
```

#### 2. 分贝计算服务(DecibelService.ets)
```typescript
// 分贝计算服务,提供音频数据到分贝值的转换功能
export class DecibelService {
  private readonly REF_VALUE: number = 32767.0;  // 16位音频的最大值
  private readonly MIN_DB: number = -90.0;       // 最小分贝值
  private readonly SMOOTH_FACTOR: number = 0.6;  // 平滑因子
  private lastDecibel: number = 0;               // 上一次的分贝值

  calculateDecibel(buffer: ArrayBuffer, bytesRead: number): number {
    const int16Array = new Int16Array(buffer, 0, bytesRead / 2);
    let sum = 0;
    let maxAbs = 0;
    
    // 计算均方根值和最大绝对值
    for (let i = 0; i < int16Array.length; i++) {
      const value = Math.abs(int16Array[i]);
      sum += value * value;
      maxAbs = Math.max(maxAbs, value);
    }

    // 使用均方根值和最大值的组合
    const rms = Math.sqrt(sum / int16Array.length);
    const combined = Math.max(rms, maxAbs * 0.8);
    
    // 计算分贝值
    let decibel = 20 * Math.log10(Math.max(combined, 1) / this.REF_VALUE);
    decibel = Math.max(this.MIN_DB, decibel);
    
    // 应用平滑处理
    if (Math.abs(decibel - this.lastDecibel) > 10) {
      this.lastDecibel = decibel;
    } else {
      this.lastDecibel = this.lastDecibel + this.SMOOTH_FACTOR * (decibel - this.lastDecibel);
    }
    decibel = this.lastDecibel;

    // 归一化到0-120范围
    return Math.round(Math.max(0, Math.min(120, decibel + 90)));
  }
}
```

#### 3. 数据模型(DecibelRecord.ets)
```typescript
// 分贝记录数据模型,定义数据结构和属性
@Entity('DECIBEL_RECORDS')
@ObservedV2
export class DecibelRecord {
  @Id()
  @Columns({ columnName: 'ID', types: ColumnType.str })
  id: string;

  @NotNull()
  @Index()
  @Columns({ columnName: 'TIMESTAMP', types: ColumnType.num })
  timestamp: number;

  @NotNull()
  @Columns({ columnName: 'MIN_DECIBEL', types: ColumnType.real })
  minDecibel: number;

  @NotNull()
  @Columns({ columnName: 'MAX_DECIBEL', types: ColumnType.real })
  maxDecibel: number;

  @NotNull()
  @Columns({ columnName: 'AVG_DECIBEL', types: ColumnType.real })
  avgDecibel: number;

  @NotNull()
  @Columns({ columnName: 'DURATION', types: ColumnType.num })
  duration: number;

  constructor(
    minDecibel: number,
    maxDecibel: number,
    avgDecibel: number,
    duration: number,
    values: number[],
    location?: string,
    audioFilePath?: string
  ) {
    this.id = util.generateRandomUUID();
    this.timestamp = Date.now();
    this.minDecibel = minDecibel;
    this.maxDecibel = maxDecibel;
    this.avgDecibel = avgDecibel;
    this.duration = duration;
    this.values = values;
    this.location = location;
    this.audioFilePath = audioFilePath;
    this.isFavorite = false;
  }
}
```

#### 4. 历史记录页面(DecibelHistory.ets)
```typescript
// 历史记录页面,展示噪音记录历史数据
@Entry
@Component
struct DecibelHistory {
  @State records: DecibelRecord[] = [];
  @State isLoading: boolean = true;
  private recordService: DecibelRecordService = new DecibelRecordService();
  private dialogService: DialogService = new DialogService();
  private audioPlayerService: AudioPlayerService;
  private fileService: FileService;

  aboutToAppear() {
    this.fileService = new FileService(getContext());
    this.audioPlayerService = new AudioPlayerService(getContext(), this.fileService);
    this.loadRecords();
  }

  async loadRecords() {
    try {
      this.records = await this.recordService.getRecords();
    } catch (error) {
      console.error('加载记录失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Stack() {
      if (this.isLoading) {
        LoadingProgress()
          .color('#007DFF')
          .width(60)
          .height(60)
      } else if (this.records.length === 0) {
        Column() {
          Image($r('app.media.ic_empty'))
            .width(120)
            .height(120)
          Text('暂无记录')
            .fontSize(16)
            .margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.records, (record: DecibelRecord) => {
            ListItem() {
              AudioRecordDisplay({ record: record })
                .onClick(() => {
                  this.showDetailDialog(record);
                })
            }
            .padding({ horizontal: 16, vertical: 8 })
          })
        }
        .width('100%')
        .height('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  private showDetailDialog(record: DecibelRecord) {
    this.dialogService.showDetailDialog(
      getContext(),
      (params) => {
        DetailDialog(params)
      },
      record,
      getContext()
    );
  }
}
```

### 三、工具类代码

#### 1. 音频服务(AudioService.ets)
```typescript
import audio from '@ohos.multimedia.audio';
import { PermissionUtil } from '@pura/harmony-utils';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import { WavFileGenerator } from '../utils/WavFileGenerator';

interface AudioStreamInfo {
  samplingRate: audio.AudioSamplingRate;
  channels: audio.AudioChannel;
  sampleFormat: audio.AudioSampleFormat;
  encodingType: audio.AudioEncodingType;
}

interface AudioCapturerInfo {
  source: audio.SourceType;
  capturerFlags: number;
}

interface AudioCapturerOptions {
  streamInfo: AudioStreamInfo;
  capturerInfo: AudioCapturerInfo;
}

export class AudioService {
  private audioCapturerOptions: AudioCapturerOptions = {
    streamInfo: {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
      channels: audio.AudioChannel.CHANNEL_1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
    },
    capturerInfo: {
      source: audio.SourceType.SOURCE_TYPE_MIC,
      capturerFlags: 0
    }
  };

  private audioCapturer: audio.AudioCapturer | null = null;
  private isCapturing: boolean = false;
  private isProcessing: boolean = false;
  private isStoppingCapture: boolean = false;
  private onAudioData: ((buffer: ArrayBuffer) => void) | null = null;
  private context: common.UIAbilityContext;
  private lastProcessTime: number = 0;
  private readonly PROCESS_INTERVAL: number = 500;
  private audioBuffers: ArrayBuffer[] = [];

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  private async checkMicrophonePermission(): Promise<boolean> {
    try {
      const hasPermission = await PermissionUtil.checkPermissions('ohos.permission.MICROPHONE');
      if (hasPermission) {
        return true;
      }

      const granted = await PermissionUtil.requestPermissions(['ohos.permission.MICROPHONE']);
      if (!granted) {
        const result = await promptAction.showDialog({
          title: '需要录音权限',
          message: '检测噪音需要使用麦克风，是否去设置开启权限？',
          buttons: [
            { text: '取消', color: '#666666' },
            { text: '去设置', color: '#2196F3' }
          ]
        });

        if (result.index === 1) {
          await PermissionUtil.requestPermissionOnSettingEasy(['ohos.permission.MICROPHONE']);
          const newPermissionStatus = await PermissionUtil.checkPermissions('ohos.permission.MICROPHONE');
          return newPermissionStatus;
        }
      }
      return granted;
    } catch (err) {
      console.error('Failed to check/request microphone permission:', err);
      return false;
    }
  }

  async startCapture(): Promise<void> {
    if (this.isCapturing || this.isStoppingCapture) {
      return;
    }

    const hasPermission = await this.checkMicrophonePermission();
    if (!hasPermission) {
      throw new Error('没有麦克风权限');
    }

    try {
      this.audioBuffers = [];

      this.audioCapturer = await audio.createAudioCapturer(this.audioCapturerOptions);

      this.audioCapturer.on('readData', (buffer: ArrayBuffer) => {
        if (!this.isCapturing || this.isStoppingCapture) {
          return;
        }
        
        if (buffer && buffer.byteLength > 0) {
          this.audioBuffers.push(buffer.slice(0));
        }
        
        if (this.isProcessing) {
          const currentTime = Date.now();
          if (currentTime - this.lastProcessTime >= this.PROCESS_INTERVAL) {
            if (buffer && buffer.byteLength > 0 && this.onAudioData) {
              this.onAudioData(buffer);
            }
            this.lastProcessTime = currentTime;
          }
        }
      });

      await this.audioCapturer.start();
      this.isCapturing = true;
    } catch (err) {
      const error = new Error('启动音频采集失败：' + (err instanceof Error ? err.message : String(err)));
      console.error(error.message);
      throw error;
    }
  }

  async stopCaptureAndGetWavData(): Promise<ArrayBuffer> {
    if (!this.isCapturing || !this.audioCapturer || this.isStoppingCapture) {
      throw new Error('没有正在进行的录音');
    }

    try {
      this.isStoppingCapture = true;
      this.isCapturing = false;
      this.isProcessing = false;
      this.onAudioData = null;

      this.audioCapturer.off('readData');
      
      await Promise.all([
        this.audioCapturer.stop(),
        this.audioCapturer.release()
      ]);
      
      this.audioCapturer = null;

      const wavData = WavFileGenerator.generateWavFile(
        this.audioBuffers,
        44100,
        1,
        16
      );

      this.audioBuffers = [];

      return wavData;
    } catch (err) {
      const error = new Error('停止音频采集失败：' + (err instanceof Error ? err.message : String(err)));
      console.error(error.message);
      throw error;
    } finally {
      this.isStoppingCapture = false;
    }
  }

  async stopCapture(): Promise<void> {
    if (!this.isCapturing || !this.audioCapturer || this.isStoppingCapture) {
      return;
    }

    try {
      this.isStoppingCapture = true;
      this.isCapturing = false;
      this.isProcessing = false;
      this.onAudioData = null;

      this.audioCapturer.off('readData');
      
      await Promise.all([
        this.audioCapturer.stop(),
        this.audioCapturer.release()
      ]);
      
      this.audioCapturer = null;
      this.audioBuffers = [];
    } catch (err) {
      const error = new Error('停止音频采集失败：' + (err instanceof Error ? err.message : String(err)));
      console.error(error.message);
      throw error;
    } finally {
      this.isStoppingCapture = false;
    }
  }

  startProcessing(callback: (buffer: ArrayBuffer) => void): void {
    this.isProcessing = true;
    this.onAudioData = callback;
    this.lastProcessTime = Date.now();
  }

  stopProcessing(): void {
    this.isProcessing = false;
    this.onAudioData = null;
  }
}
```

#### 2. 位置服务(LocationService.ets)
```typescript
const TAG = 'LocationService';
const DOMAIN = 0x0000;

export interface LocationInfo {
  coordinates: string;
  address: string;
}

export class LocationService {
  private static instance: LocationService;
  private cachedLocation: LocationInfo | null = null;
  private context: common.Context | null = null;

  private constructor() {}

  public static getInstance(): LocationService {
    if (!LocationService.instance) {
      LocationService.instance = new LocationService();
    }
    return LocationService.instance;
  }

  public async init(context: common.Context): Promise<void> {
    this.context = context;
  }

  public async checkLocationEnabled(): Promise<boolean> {
    try {
      return geoLocationManager.isLocationEnabled();
    } catch (error) {
      hilog.error(DOMAIN, TAG, '检查定位服务状态失败: %{public}s', error instanceof Error ? error.message : String(error));
      return false;
    }
  }

  public async requestLocationService(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      return await atManager.requestGlobalSwitch(context, abilityAccessCtrl.SwitchType.LOCATION);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '请求开启定位服务失败: %{public}s', error instanceof Error ? error.message : String(error));
      return false;
    }
  }

  public async requestLocationPermission(): Promise<boolean> {
    try {
      const hasPermission = await PermissionUtil.checkPermissions('ohos.permission.LOCATION');
      if (hasPermission) {
        return true;
      }

      return await PermissionUtil.requestPermissions(['ohos.permission.APPROXIMATELY_LOCATION','ohos.permission.LOCATION']);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '请求位置权限失败: %{public}s', error instanceof Error ? error.message : String(error));
      return false;
    }
  }

  public async requestSingleLocation(): Promise<LocationInfo> {
    return new Promise(async (resolve, reject) => {
      try {
        this.cachedLocation = {
          coordinates: '正在获取位置...',
          address: '正在获取位置信息...'
        };

        const requestInfo: geoLocationManager.LocationRequest = {
          priority: geoLocationManager.LocationRequestPriority.ACCURACY,
          scenario: geoLocationManager.LocationRequestScenario.NAVIGATION,
          timeInterval: 0,
          distanceInterval: 0,
          maxAccuracy: 0
        };

        const location = await geoLocationManager.getCurrentLocation(requestInfo);
        
        const reverseGeocodeRequest: geoLocationManager.ReverseGeoCodeRequest = {
          latitude: location.latitude,
          longitude: location.longitude,
          maxItems: 1,
          locale: "zh_CN"
        };

        const addresses = await geoLocationManager.getAddressesFromLocation(reverseGeocodeRequest);
        let address = '未获取到详细地址';
        
        if (addresses && addresses.length > 0 && addresses[0].placeName) {
          address = addresses[0].placeName;
        }

        this.cachedLocation = {
          coordinates: `${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)}`,
          address: address
        };

        resolve(this.cachedLocation);
      } catch (error) {
        this.cachedLocation = {
          coordinates: '未获取到位置信息',
          address: '请稍后重试'
        };
        reject(new Error('未获取到位置信息'));
      }
    });
  }

  public getCachedLocation(): LocationInfo | null {
    return this.cachedLocation;
  }

  public destroy(): void {
    this.cachedLocation = null;
    this.context = null;
  }
}
```

#### 3. 文件服务(FileService.ets)
```typescript
const TAG = 'FileService';
const DOMAIN = 0x0000;
export class FileService {
  private context: common.Context;
  private readonly baseDir: string;

  constructor(context: common.Context) {
    this.context = context;
    this.baseDir = this.context.filesDir;
  }

  async saveFile(filePath: string, data: ArrayBuffer): Promise<void> {
    try {
      const fullPath = `${this.baseDir}/${filePath}`;
      const dirPath = fullPath.substring(0, fullPath.lastIndexOf('/'));

      await this.createDirectory(dirPath);

      const file = await fs.open(fullPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      await fs.write(file.fd, data);
      await fs.close(file.fd);
    } catch (error) {
      const businessError = error as BusinessError;
      throw new Error(`保存文件失败: ${businessError.message}`);
    }
  }

  async readFile(filePath: string): Promise<ArrayBuffer> {
    try {
      const fullPath = `${this.baseDir}/${filePath}`;
      const file = await fs.open(fullPath, fs.OpenMode.READ_ONLY);
      const fileInfo = await fs.fstat(file.fd);
      const buffer = new ArrayBuffer(fileInfo.size);
      await fs.read(file.fd, buffer);
      await fs.close(file.fd);
      return buffer;
    } catch (error) {
      const businessError = error as BusinessError;
      throw new Error(`读取文件失败: ${businessError.message}`);
    }
  }

  async deleteFile(filePath: string): Promise<void> {
    try {
      const fullPath = `${this.baseDir}/${filePath}`;
      await fs.unlink(fullPath);
    } catch (error) {
      const businessError = error as BusinessError;
      throw new Error(`删除文件失败: ${businessError.message}`);
    }
  }

  async exists(filePath: string): Promise<boolean> {
    try {
      const fullPath = `${this.baseDir}/${filePath}`;
      const stat = await fs.stat(fullPath);
      return stat.isFile();
    } catch (error) {
      return false;
    }
  }

  async getFileInfo(filePath: string): Promise<fs.Stat> {
    try {
      const fullPath = `${this.baseDir}/${filePath}`;
      return await fs.stat(fullPath);
    } catch (error) {
      const businessError = error as BusinessError;
      throw new Error(`获取文件信息失败: ${businessError.message}`);
    }
  }

  async listFiles(dirPath: string): Promise<string[]> {
    try {
      const fullPath = `${this.baseDir}/${dirPath}`;
      const dir = await fs.openDir(fullPath);
      const files: string[] = [];
      let dirent;
      while ((dirent = await fs.readDir(dir)) !== null) {
        files.push(dirent.name);
      }
      await fs.closeDir(dir);
      return files;
    } catch (error) {
      const businessError = error as BusinessError;
      throw new Error(`列出文件失败: ${businessError.message}`);
    }
  }

  async createDirectory(dirPath: string): Promise<void> {
    try {
      await fs.mkdir(dirPath, { recursive: true });
    } catch (error) {
      const businessError = error as BusinessError;
      throw new Error(`创建目录失败: ${businessError.message}`);
    }
  }

  getFullPath(relativePath: string): string {
    return `${this.baseDir}/${relativePath}`;
  }
}
```

### 四、UI组件代码

#### 1. 详情对话框(DetailDialog.ets)
```typescript
const TAG = 'DetailDialog';
const DOMAIN = 0x0000;

interface NoiseSegment {
  name: string;
  value: number;
  color: string;
}

interface NoiseDistribution {
  segments: NoiseSegment[];
  values: number[];
}

@CustomDialog
export struct DetailDialog {
  @State private isPlaying: boolean = false;
  @State private noiseDistribution: NoiseDistribution = { segments: [], values: [] };
  @State private translateY: number = 0;
  @Param @Require selectedRecord: DecibelRecord | null;
  @Param @Require context: common.Context;
  @Param @Require fileService: FileService | null;
  @BuilderParam closeDialog: () => void;
  private startY: number = 0;
  private decibelService: DecibelService = new DecibelService();
  private audioPlayerService!: AudioPlayerService;

  aboutToAppear() {
    if (!this.context) {
      hilog.error(DOMAIN, TAG, 'Context is not available');
      return;
    }
    if (!this.fileService) {
      hilog.error(DOMAIN, TAG, 'FileService is not available');
      return;
    }

    try {
      this.audioPlayerService = new AudioPlayerService(this.context, this.fileService);
      hilog.info(DOMAIN, TAG, 'AudioPlayerService 初始化成功');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'AudioPlayerService 初始化失败: %{public}s', error instanceof Error ? error.message : String(error));
    }

    if (this.selectedRecord && this.selectedRecord.values.length > 0) {
      this.calculateNoiseDistribution();
    }
  }

  aboutToDisappear() {
    if (this.isPlaying) {
      this.audioPlayerService.stop();
    }
  }

  private calculateNoiseDistribution() {
    const values = this.selectedRecord!.values;
    const levelCounts = new Map<string, number>();
    values.forEach(value => {
      const level = this.decibelService.getDecibelLevel(value);
      levelCounts.set(level, (levelCounts.get(level) || 0) + 1);
    });

    const levelOrder = ['极度危险', '危险', '嘈杂', '正常', '安静'];
    const segments: NoiseSegment[] = [];
    const total = values.length;

    levelOrder.forEach(level => {
      const count = levelCounts.get(level) || 0;
      if (count > 0) {
        const sampleValue = values.find(v => this.decibelService.getDecibelLevel(v) === level) || 0;
        segments.push({
          name: level,
          value: Math.round((count / total) * 100),
          color: this.decibelService.getDecibelColor(sampleValue)
        });
      }
    });

    this.noiseDistribution = {
      segments: segments,
      values: segments.map(s => s.value)
    };
  }

  @Builder
  DialogTitleBuilder() {
    Row() {
      Row() {
        Text('检测报告')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        if (this.selectedRecord!.isFavorite) {
          Image($r('app.media.ic_favorite'))
            .width(20)
            .height(20)
            .fillColor('#FF4081')
            .margin({ left: 8 })
        }
      }
      Blank()
      Button() {
        Image($r('app.media.ic_close'))
          .width(24)
          .height(24)
          .fillColor('#666666')
      }
      .type(ButtonType.Circle)
      .backgroundColor(Color.Transparent)
      .onClick(this.closeDialog)
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 12 })
  }

  @Builder
  BasicInfoBuilder() {
    Column() {
      Text('基本信息')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      Row() {
        Text('检测时间')
          
          .fontColor('#666666')
        Text(new Date(this.selectedRecord!.timestamp).toLocaleString('zh-CN', {
          year: 'numeric',
          month: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit',
          hour12: false
        }))
          
          .fontColor('#333333')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 8 })

      Row() {
        Text('检测时长')
          
          .fontColor('#666666')
        Text(`${Math.round(this.selectedRecord!.duration / 1000)}秒`)
          
          .fontColor('#333333')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 8 })

      if (this.selectedRecord!.location) {
        Row() {
          Text('检测位置')
            
            .fontColor('#666666')
          Text(this.selectedRecord!.location)
            
            .fontColor('#333333')
            .textAlign(TextAlign.End)
            .textOverflow({ overflow: TextOverflow.None })
            .width('70%')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 8 })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  NoiseDistributionBuilder() {
    Column() {
      Text('噪音级别分布')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 8 })

      if (!this.selectedRecord || this.selectedRecord.values.length === 0) {
        Column() {
          Image($r('app.media.ic_empty'))
            .width(32)
            .height(32)
            .fillColor('#999999')
            .margin({ bottom: 8 })
          Text('暂无噪音级别分布数据')
            
            .fontColor('#999999')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 20, bottom: 20 })
      } else {
        Row() {
          Stack() {
            DataPanel({
              values: this.noiseDistribution.values,
              max: 100,
              type: DataPanelType.Circle
            })
              .valueColors(this.noiseDistribution.segments.map(segment => segment.color))
              .trackBackgroundColor('#08182431')
              .width(160)
              .height(160)
          }
          .width(160)
          .height(160)
          .margin({ right: 16, top: -16 })

          Column() {
            ForEach(this.noiseDistribution.segments, (segment: NoiseSegment) => {
              Row() {
                Row()
                  .width(12)
                  .height(12)
                  .borderRadius(6)
                  .backgroundColor(segment.color)
                  .margin({ right: 8 })

                Text(segment.name)
                  
                  .fontColor('#666666')

                Text(`${segment.value}%`)
                  
                  .fontColor('#333333')
                  .margin({ left: 8 })
              }
              .width('100%')
              .margin({ bottom: 8 })
              .alignItems(VerticalAlign.Center)
            })
          }
          .layoutWeight(1)
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  build() {
    Column() {
      this.DialogTitleBuilder()

      Scroll() {
        Column() {
          this.BasicInfoBuilder()
          this.NoiseDistributionBuilder()

          if (this.selectedRecord!.audioFilePath) {
            Column() {
              Text('录音回放')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 12 })

              Button() {
                Row() {
                  Image(this.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
                    .width(24)
                    .height(24)
                    .fillColor(Color.White)
                    .margin({ right: 8 })
                  Text(this.isPlaying ? '暂停' : '播放')
                    .fontSize(16)
                    .fontColor(Color.White)
                }
              }
              .width('100%')
              .height(48)
              .type(ButtonType.Normal)
              .backgroundColor('#2196F3')
              .borderRadius(24)
              .onClick(async () => {
                try {
                  if (this.isPlaying) {
                    await this.audioPlayerService.pause();
                    this.isPlaying = false;
                  } else {
                    await this.audioPlayerService.playAudioFile(this.selectedRecord!.audioFilePath!);
                    this.isPlaying = true;
                  }
                } catch (error) {
                  hilog.error(DOMAIN, TAG, '播放音频失败: %{public}s', error instanceof Error ? error.message : String(error));
                }
              })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ bottom: 12 })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('60%')
    .backgroundColor('#F5F5F5')
    .borderRadius({ topLeft: 24, topRight: 24 })
    .translate({ y: this.translateY })
    .gesture(
      PanGesture({ direction: PanDirection.Up })
        .onActionStart((event: GestureEvent) => {
          this.startY = event.offsetY;
        })
        .onActionUpdate((event: GestureEvent) => {
          const deltaY = event.offsetY - this.startY;
          if (deltaY < 0) {
            this.translateY = deltaY;
          }
        })
        .onActionEnd(() => {
          animateTo({
            duration: 200,
            curve: Curve.EaseOut,
            delay: 0,
            iterations: 1,
            playMode: PlayMode.Normal,
            onFinish: () => {
              this.translateY = 0;
            }
          }, () => {
            this.translateY = 0;
          });
        })
    )
  }
}
```

#### 2. 分贝记录服务(DecibelRecordService.ets)
```typescript
const TAG = 'DecibelRecordService';
const DOMAIN = 0x0000;

export class DecibelRecordService {
  private readonly TABLE_NAME = 'decibel_records';
  private readonly DATABASE_NAME = 'noise_meter.db';
  private readonly AUDIO_DIR = 'audio';
  private readonly CREATE_TABLE_SQL = `
    CREATE TABLE IF NOT EXISTS ${this.TABLE_NAME} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp INTEGER NOT NULL,
      duration INTEGER NOT NULL,
      location TEXT,
      values TEXT NOT NULL,
      audioFilePath TEXT,
      isFavorite INTEGER DEFAULT 0
    )
  `;

  private fileService: FileService;
  private daoSession: RelationalStoreService;

  constructor(context: common.Context) {
    this.fileService = new FileService(context);
    this.daoSession = new RelationalStoreService(context, this.DATABASE_NAME);
    this.daoSession.setInitSql(this.CREATE_TABLE_SQL);
  }

  async saveRecord(record: DecibelRecord): Promise<void> {
    try {
      const values = {
        timestamp: record.timestamp,
        duration: record.duration,
        location: record.location,
        values: JSON.stringify(record.values),
        audioFilePath: record.audioFilePath,
        isFavorite: record.isFavorite ? 1 : 0
      };

      const id = await this.daoSession.insert(this.TABLE_NAME, values);
      hilog.info(DOMAIN, TAG, `保存记录成功，ID: ${id}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '保存记录失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw error;
    }
  }

  async getRecords(): Promise<DecibelRecord[]> {
    try {
      const sql = `SELECT * FROM ${this.TABLE_NAME} ORDER BY timestamp DESC`;
      const resultSet = await this.daoSession.query(sql);

      const records: DecibelRecord[] = [];
      while (resultSet.goToNextRow()) {
        records.push({
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          timestamp: resultSet.getLong(resultSet.getColumnIndex('timestamp')),
          duration: resultSet.getLong(resultSet.getColumnIndex('duration')),
          location: resultSet.getString(resultSet.getColumnIndex('location')),
          values: JSON.parse(resultSet.getString(resultSet.getColumnIndex('values'))),
          audioFilePath: resultSet.getString(resultSet.getColumnIndex('audioFilePath')),
          isFavorite: resultSet.getLong(resultSet.getColumnIndex('isFavorite')) === 1
        });
      }

      resultSet.close();
      return records;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '获取记录列表失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw error;
    }
  }

  async clearNonFavoriteRecords(): Promise<void> {
    try {
      // 先获取所有非收藏记录的音频文件路径
      const sql = `SELECT audioFilePath FROM ${this.TABLE_NAME} WHERE isFavorite = 0 AND audioFilePath IS NOT NULL`;
      const resultSet = await this.daoSession.query(sql);

      const audioFiles: string[] = [];
      while (resultSet.goToNextRow()) {
        const audioFilePath = resultSet.getString(resultSet.getColumnIndex('audioFilePath'));
        if (audioFilePath) {
          audioFiles.push(audioFilePath);
        }
      }
      resultSet.close();

      // 删除音频文件
      for (const audioFile of audioFiles) {
        try {
          await this.fileService.deleteFile(audioFile);
        } catch (error) {
          hilog.warn(DOMAIN, TAG, `删除音频文件失败: ${audioFile}, 错误: ${error instanceof Error ? error.message : String(error)}`);
        }
      }

      // 删除数据库记录
      const deleteSql = `DELETE FROM ${this.TABLE_NAME} WHERE isFavorite = 0`;
      await this.daoSession.execute(deleteSql);

      hilog.info(DOMAIN, TAG, '清除非收藏记录成功');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '清除非收藏记录失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw error;
    }
  }

  async updateRecord(record: DecibelRecord): Promise<void> {
    try {
      const sql = `
        UPDATE ${this.TABLE_NAME}
        SET isFavorite = ?
        WHERE id = ?
      `;
      await this.daoSession.execute(sql, [record.isFavorite ? 1 : 0, record.id]);
      hilog.info(DOMAIN, TAG, `更新记录成功，ID: ${record.id}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '更新记录失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw error;
    }
  }

  async deleteRecord(record: DecibelRecord): Promise<void> {
    try {
      // 如果有音频文件，先删除音频文件
      if (record.audioFilePath) {
        try {
          await this.fileService.deleteFile(record.audioFilePath);
        } catch (error) {
          hilog.warn(DOMAIN, TAG, `删除音频文件失败: ${record.audioFilePath}, 错误: ${error instanceof Error ? error.message : String(error)}`);
        }
      }

      // 删除数据库记录
      const sql = `DELETE FROM ${this.TABLE_NAME} WHERE id = ?`;
      await this.daoSession.execute(sql, [record.id]);
      hilog.info(DOMAIN, TAG, `删除记录成功，ID: ${record.id}`);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '删除记录失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw error;
    }
  }

  async saveAudioFile(audioData: ArrayBuffer): Promise<string> {
    try {
      const fileName = `${this.AUDIO_DIR}/${Date.now()}.wav`;
      await this.fileService.saveFile(fileName, audioData);
      hilog.info(DOMAIN, TAG, `保存音频文件成功: ${fileName}`);
      return fileName;
    } catch (error) {
      hilog.error(DOMAIN, TAG, '保存音频文件失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw error;
    }
  }

  async getAudioFile(fileName: string): Promise<ArrayBuffer> {
    try {
      return await this.fileService.readFile(fileName);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '读取音频文件失败: %{public}s', error instanceof Error ? error.message : String(error));
      throw error;
    }
  }
}
```

#### 3. 音频录制显示组件(AudioRecordDisplay.ets)
```typescript
import promptAction from '@ohos.promptAction';
import { AudioService } from '../../services/AudioService';
import common from '@ohos.app.ability.common';

@ComponentV2
export struct AudioRecordDisplay {
  @Param isRecordEnabled: boolean = false;
  @Event onRecordEnabledChange: (value: boolean) => void;

  build() {
    Column() {
      Row() {
        Row() {
          Image($r('app.media.ic_mic'))
            .width(16)
            .height(16)
            .fillColor('#666666')
            .margin({ right: 8 })

          Text('录音')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.black'))

          Text(this.isRecordEnabled ? ' 已开启' : ' 已关闭')
            
            .fontColor(this.isRecordEnabled ? '#0091FF' : '#666666')
        }

        Blank()

        Toggle({ type: ToggleType.Switch, isOn: this.isRecordEnabled })
          .selectedColor('#0091FF')
          .switchPointColor($r('sys.color.comp_background_list_card'))
          .onChange((isOn: boolean) => {
            this.onRecordEnabledChange(isOn);
          })
      }
      .width('100%')
      .height(40)
      .alignItems(VerticalAlign.Center)

      if (this.isRecordEnabled) {
        Text('检测结束后自动保存音频')
          
          .fontColor('#666666')
          .margin({ left: 4, top: 2 })
          .textAlign(TextAlign.Start)
          .width('100%')
      } else {
        Text('开启后将自动保存检测音频')
          
          .fontColor('#999999')
          .margin({ left: 4, top: 2 })
          .textAlign(TextAlign.Start)
          .width('100%')
      }
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 8,
      bottom: 12
    })
    .borderRadius(20)
    .backgroundColor(Color.White)
    .margin({
      top: 16,
      bottom: 16,
      left: 8,
      right: 8
    })
    .shadow({ radius: 1, color: '#1A000000', offsetY: 2 })
  }
}

#### 4. 广告横幅组件(BannerCard.ets)
```typescript
const TAG = 'BannerCard';
const DOMAIN = 0x0000;

@ComponentV2
export struct BannerCard {
  @Param context: common.Context = getContext(this) as common.Context;
  @Param adId: string = '';
  @Param @Require onItemClick?: () => void;

  async checkAndRequestPermissions(): Promise<void> {
    try {
      const permissions: Array<Permissions> = [
        'ohos.permission.INTERNET' as Permissions,
        'ohos.permission.GET_BUNDLE_INFO' as Permissions,
        'ohos.permission.GET_NETWORK_INFO' as Permissions
      ];

      const atManager = abilityAccessCtrl.createAtManager();
      for (const permission of permissions) {
        try {
          const result = await atManager.checkAccessToken(this.context.applicationInfo.accessTokenId, permission);
          hilog.info(DOMAIN, TAG, `Permission ${permission} check result: ${result}`);

          if (result === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
            const requestResult = await atManager.requestPermissionsFromUser(this.context, [permission]);
            hilog.info(DOMAIN, TAG, `Permission ${permission} request result: ${JSON.stringify(requestResult)}`);
          }
        } catch (err) {
          hilog.error(DOMAIN, TAG, `Failed to handle permission ${permission}: ${JSON.stringify(err)}`);
        }
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, `Error checking permissions: ${JSON.stringify(err)}`);
    }
  }
  async aboutToAppear() {
    hilog.info(DOMAIN, TAG, 'aboutToAppear start');
    hilog.info(DOMAIN, TAG, `adId: ${this.adId}`);
    await this.checkAndRequestPermissions();
  }
  aboutToDisappear() {
    hilog.info(DOMAIN, TAG, 'aboutToDisappear');
  }

  build() {
    Row() {
      AutoAdComponent({
        adParam: {
          adId: this.adId,
          adType: 3,
          adWidth: 360,
          adHeight: 57
        },
        adOptions: {
          tagForChildProtection: 0,
          adContentClassification: 'W',
          nonPersonalizedAd: 0
        },
        displayOptions: {
          displayWidth: '360vp',
          displayHeight: '57vp',
          displayRadius: '24vp',
          backgroundColor: '#FFFFFF'
        },
        interactionListener: {
          onStatusChanged: (status: string, ad: advertising.Advertisement, data: string) => {
            switch (status) {
              case 'loaded':
                hilog.info(DOMAIN, TAG, 'Ad loaded successfully');
                break;
              case 'showed':
                hilog.info(DOMAIN, TAG, 'Ad showed');
                break;
              case 'clicked':
                hilog.info(DOMAIN, TAG, 'Ad clicked');
                if (this.onItemClick) {
                  this.onItemClick();
                }
                break;
              case 'closed':
                hilog.info(DOMAIN, TAG, 'Ad closed');
                break;
              case 'error':
                hilog.error(DOMAIN, TAG, `Ad error: ${data}`);
                hilog.error(DOMAIN, TAG, `adId: ${this.adId}`);
                hilog.error(DOMAIN, TAG, `error data: ${JSON.stringify(data)}`);
                hilog.error(DOMAIN, TAG, `error stack: ${new Error().stack}`);
                break;
            }
          }
        }
      })
        .height(57)
    }
    .width('100%')
    .height(57)
    .backgroundColor(Color.White)
    .borderRadius(24)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .shadow({ radius: 1, color: '#1A000000', offsetY: 2 })
  }
}
```

### 五、服务类代码

#### 1. 音频服务(AudioService.ets)
```typescript
interface AudioStreamInfo {
  samplingRate: audio.AudioSamplingRate;
  channels: audio.AudioChannel;
  sampleFormat: audio.AudioSampleFormat;
  encodingType: audio.AudioEncodingType;
}
interface AudioCapturerInfo {
  source: audio.SourceType;
  capturerFlags: number;
}
interface AudioCapturerOptions {
  streamInfo: AudioStreamInfo;
  capturerInfo: AudioCapturerInfo;
}
export class AudioService {
  private audioCapturerOptions: AudioCapturerOptions = {
    streamInfo: {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
      channels: audio.AudioChannel.CHANNEL_1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
    },
    capturerInfo: {
      source: audio.SourceType.SOURCE_TYPE_MIC,
      capturerFlags: 0
    }
  };

  private audioCapturer: audio.AudioCapturer | null = null;
  private isCapturing: boolean = false;
  private isProcessing: boolean = false;
  private isStoppingCapture: boolean = false;
  private onAudioData: ((buffer: ArrayBuffer) => void) | null = null;
  private context: common.UIAbilityContext;
  private lastProcessTime: number = 0;
  private readonly PROCESS_INTERVAL: number = 500;
  private audioBuffers: ArrayBuffer[] = [];

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  private async checkMicrophonePermission(): Promise<boolean> {
    try {
      const hasPermission = await PermissionUtil.checkPermissions('ohos.permission.MICROPHONE');
      if (hasPermission) {
        return true;
      }

      const granted = await PermissionUtil.requestPermissions(['ohos.permission.MICROPHONE']);
      if (!granted) {
        const result = await promptAction.showDialog({
          title: '需要录音权限',
          message: '检测噪音需要使用麦克风，是否去设置开启权限？',
          buttons: [
            { text: '取消', color: '#666666' },
            { text: '去设置', color: '#2196F3' }
          ]
        });

        if (result.index === 1) {
          await PermissionUtil.requestPermissionOnSettingEasy(['ohos.permission.MICROPHONE']);
          const newPermissionStatus = await PermissionUtil.checkPermissions('ohos.permission.MICROPHONE');
          return newPermissionStatus;
        }
      }
      return granted;
    } catch (err) {
      console.error('Failed to check/request microphone permission:', err);
      return false;
    }
  }

  async startCapture(): Promise<void> {
    if (this.isCapturing || this.isStoppingCapture) {
      return;
    }

    const hasPermission = await this.checkMicrophonePermission();
    if (!hasPermission) {
      throw new Error('没有麦克风权限');
    }

    try {
      this.audioBuffers = [];

      this.audioCapturer = await audio.createAudioCapturer(this.audioCapturerOptions);

      this.audioCapturer.on('readData', (buffer: ArrayBuffer) => {
        if (!this.isCapturing || this.isStoppingCapture) {
          return;
        }
        
        if (buffer && buffer.byteLength > 0) {
          this.audioBuffers.push(buffer.slice(0));
        }
        
        if (this.isProcessing) {
          const currentTime = Date.now();
          if (currentTime - this.lastProcessTime >= this.PROCESS_INTERVAL) {
            if (buffer && buffer.byteLength > 0 && this.onAudioData) {
              this.onAudioData(buffer);
            }
            this.lastProcessTime = currentTime;
          }
        }
      });

      await this.audioCapturer.start();
      this.isCapturing = true;
    } catch (err) {
      const error = new Error('启动音频采集失败：' + (err instanceof Error ? err.message : String(err)));
      console.error(error.message);
      throw error;
    }
  }

  async stopCaptureAndGetWavData(): Promise<ArrayBuffer> {
    if (!this.isCapturing || !this.audioCapturer || this.isStoppingCapture) {
      throw new Error('没有正在进行的录音');
    }

    try {
      this.isStoppingCapture = true;
      this.isCapturing = false;
      this.isProcessing = false;
      this.onAudioData = null;

      this.audioCapturer.off('readData');
      
      await Promise.all([
        this.audioCapturer.stop(),
        this.audioCapturer.release()
      ]);
      
      this.audioCapturer = null;

      const wavData = WavFileGenerator.generateWavFile(
        this.audioBuffers,
        44100,
        1,
        16
      );

      this.audioBuffers = [];

      return wavData;
    } catch (err) {
      const error = new Error('停止音频采集失败：' + (err instanceof Error ? err.message : String(err)));
      console.error(error.message);
      throw error;
    } finally {
      this.isStoppingCapture = false;
    }
  }

  async stopCapture(): Promise<void> {
    if (!this.isCapturing || !this.audioCapturer || this.isStoppingCapture) {
      return;
    }

    try {
      this.isStoppingCapture = true;
      this.isCapturing = false;
      this.isProcessing = false;
      this.onAudioData = null;

      this.audioCapturer.off('readData');
      
      await Promise.all([
        this.audioCapturer.stop(),
        this.audioCapturer.release()
      ]);
      
      this.audioCapturer = null;
      this.audioBuffers = [];
    } catch (err) {
      const error = new Error('停止音频采集失败：' + (err instanceof Error ? err.message : String(err)));
      console.error(error.message);
      throw error;
    } finally {
      this.isStoppingCapture = false;
    }
  }

  startProcessing(callback: (buffer: ArrayBuffer) => void): void {
    this.isProcessing = true;
    this.onAudioData = callback;
    this.lastProcessTime = Date.now();
  }

  stopProcessing(): void {
    this.isProcessing = false;
    this.onAudioData = null;
  }
}
```

#### 2. 音频播放服务(AudioPlayerService.ets)
```typescript

const TAG = 'AudioPlayerService';
const DOMAIN = 0x0000;

export class AudioPlayerService {
  private player: CcPlayer | null = null;
  private fileService: FileService;
  private context: common.Context;
  private onProgressListener?: (duration: number) => void;
  private onStateChangeListener?: (state: PlayerState) => void;

  constructor(context: common.Context, fileService: FileService) {
    this.context = context;
    this.fileService = fileService;
    try {
      this.initPlayer();
    } catch (error) {
      hilog.error(DOMAIN, TAG, '初始化播放器失败: %{public}s', error instanceof Error ? error.message : String(error));
    }
  }

  private initPlayer(): void {
    try {
      this.player = new CcPlayer(this.context);
      if (!this.player) {
        throw new Error('播放器创建失败');
      }

      this.player.setLooper(false);
      this.player.setVolume(1.0);

      this.player.addOnCompletionListener(() => {
        if (this.onStateChangeListener) {
          this.onStateChangeListener(PlayerState.STATE_COMPLETED);
        }
      });

      this.player.addOnErrorListener((code: number, message: string) => {
        if (this.onStateChangeListener) {
          this.onStateChangeListener(PlayerState.STATE_ERROR);
        }
      });

      this.player.addOnProgressChangedListener((duration: number) => {
        if (this.onProgressListener) {
          this.onProgressListener(duration);
        }
      });
    } catch (error) {
      throw new Error(error);
    }
  }

  async playAudioFile(audioFilePath: string): Promise<void> {
    try {
      if (!this.player) {
        throw new Error('播放器未初始化');
      }

      if (this.isPlaying()) {
        await this.stop();
      }

      const mediaSource = await MediaSourceFactory.createFile('audio', audioFilePath);
      this.player.setMediaSource(mediaSource, () => {
        this.player?.start();
      });
    } catch (error) {
      throw new Error(`播放音频失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  async pause(): Promise<void> {
    if (this.player && this.isPlaying()) {
      try {
        await this.player.pause();
      } catch (error) {
        throw new Error(`暂停播放失败: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }

  async resume(): Promise<void> {
    if (this.player && !this.isPlaying()) {
      try {
        await this.player.start();
      } catch (error) {
        throw new Error(`恢复播放失败: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }

  async stop(): Promise<void> {
    if (this.player) {
      try {
        await this.player.stop();
      } catch (error) {
        throw new Error(`停止播放失败: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }

  setVolume(volume: number): void {
    if (this.player) {
      this.player.setVolume(Math.max(0, Math.min(1, volume)));
    }
  }

  async seekTo(position: number): Promise<void> {
    if (this.player) {
      try {
        await this.player.seekTo(position);
      } catch (error) {
        const businessError = error as BusinessError;
        throw new Error(`跳转失败: ${businessError.message}`);
      }
    }
  }

  getCurrentPosition(): number {
    return this.player?.getCurrentPosition() ?? 0;
  }

  getDuration(): number {
    return this.player?.getDuration() ?? 0;
  }

  isPlaying(): boolean {
    return this.player?.isPlaying() ?? false;
  }

  getPlayerState(): PlayerState {
    return this.player?.getPlayerState() ?? PlayerState.STATE_NOT_INIT;
  }

  setOnProgressListener(listener: (duration: number) => void): void {
    this.onProgressListener = listener;
  }

  setOnStateChangeListener(listener: (state: PlayerState) => void): void {
    this.onStateChangeListener = listener;
  }

  async release(): Promise<void> {
    if (this.player) {
      try {
        await this.stop();
        await this.player.release();
        this.player = null;
      } catch (error) {
        throw new Error(`释放播放器失败: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }
}
```

#### 6. 分贝计组件(DecibelMeter.ets)
```typescript
import { AudioService } from '../../services/AudioService';
import { DecibelService } from '../../services/DecibelService';
import { LocationService } from '../../services/LocationService';
import { DecibelRecordService } from '../../services/DecibelRecordService';
import { DecibelRecord } from '../../models/DecibelRecord';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import hilog from '@ohos.hilog';

const TAG = 'DecibelMeter';
const DOMAIN = 0x0000;

@ComponentV2
export struct DecibelMeter {
  @State private currentDecibel: number = 0;
  @State private minDecibel: number = 120;
  @State private maxDecibel: number = 0;
  @State private avgDecibel: number = 0;
  @State private isRecording: boolean = false;
  @State private isAudioRecordEnabled: boolean = false;
  @State private recordDuration: number = 0;
  @State private decibelValues: number[] = [];
  @State private recordStartTime: number = 0;
  @State private timerInterval: number | null = null;
  private context: common.Context = getContext(this) as common.Context;
  private audioService: AudioService = new AudioService(this.context);
  private decibelService: DecibelService = new DecibelService();
  private locationService: LocationService = LocationService.getInstance();
  private recordService: DecibelRecordService = new DecibelRecordService(this.context);

  aboutToDisappear() {
    this.stopRecording();
  }

  private async startRecording() {
    try {
      this.isRecording = true;
      this.recordStartTime = Date.now();
      this.decibelValues = [];
      this.minDecibel = 120;
      this.maxDecibel = 0;
      this.avgDecibel = 0;
      this.currentDecibel = 0;
      this.recordDuration = 0;

      await this.audioService.startCapture();
      this.audioService.startProcessing((buffer: ArrayBuffer) => {
        const decibel = this.decibelService.calculateDecibel(buffer);
        this.updateDecibelValues(decibel);
      });

      // 启动计时器
      this.timerInterval = setInterval(() => {
        this.recordDuration = Date.now() - this.recordStartTime;
      }, 1000);

    } catch (error) {
      hilog.error(DOMAIN, TAG, '启动录音失败: %{public}s', error instanceof Error ? error.message : String(error));
      this.isRecording = false;
      promptAction.showToast({
        message: '启动录音失败：' + (error instanceof Error ? error.message : String(error)),
        duration: 3000
      });
    }
  }

  private async stopRecording() {
    if (!this.isRecording) {
      return;
    }

    try {
      this.isRecording = false;

      // 停止计时器
      if (this.timerInterval !== null) {
        clearInterval(this.timerInterval);
        this.timerInterval = null;
      }

      let audioFilePath: string | undefined;
      if (this.isAudioRecordEnabled) {
        const wavData = await this.audioService.stopCaptureAndGetWavData();
        audioFilePath = await this.recordService.saveAudioFile(wavData);
      } else {
        await this.audioService.stopCapture();
      }

      const locationInfo = this.locationService.getCachedLocation();
      const duration = Date.now() - this.recordStartTime;

      const record: DecibelRecord = {
        timestamp: this.recordStartTime,
        duration: duration,
        location: locationInfo?.address,
        values: [...this.decibelValues],
        audioFilePath: audioFilePath,
        isFavorite: false
      };

      await this.recordService.saveRecord(record);

      promptAction.showToast({
        message: '检测记录已保存',
        duration: 2000
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, '停止录音失败: %{public}s', error instanceof Error ? error.message : String(error));
      promptAction.showToast({
        message: '保存记录失败：' + (error instanceof Error ? error.message : String(error)),
        duration: 3000
      });
    }
  }

  private updateDecibelValues(decibel: number) {
    this.currentDecibel = Math.round(decibel);
    this.decibelValues.push(this.currentDecibel);
    
    // 更新最大最小值
    this.minDecibel = Math.min(this.minDecibel, this.currentDecibel);
    this.maxDecibel = Math.max(this.maxDecibel, this.currentDecibel);
    
    // 计算平均值
    const sum = this.decibelValues.reduce((a, b) => a + b, 0);
    this.avgDecibel = Math.round(sum / this.decibelValues.length);
  }

  @Builder
  DecibelDisplay() {
    Column() {
      Text(this.currentDecibel.toString())
        .fontSize(80)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.decibelService.getDecibelColor(this.currentDecibel))
        .margin({ bottom: 8 })

      Text('dB')
        .fontSize(24)
        .fontColor('#666666')
        .margin({ bottom: 16 })

      Text(this.decibelService.getDecibelLevel(this.currentDecibel))
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.decibelService.getDecibelColor(this.currentDecibel))
        .margin({ bottom: 8 })

      Text(this.decibelService.getDecibelDescription(this.currentDecibel))
        
        .fontColor('#666666')
        .textAlign(TextAlign.Center)
        .margin({ horizontal: 24 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding(24)
  }

  @Builder
  StatisticsDisplay() {
    Row() {
      Column() {
        Text('最小')
          
          .fontColor('#666666')
        Text(this.minDecibel.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.decibelService.getDecibelColor(this.minDecibel))
        Text('dB')
          .fontSize(12)
          .fontColor('#666666')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text('平均')
          
          .fontColor('#666666')
        Text(this.avgDecibel.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.decibelService.getDecibelColor(this.avgDecibel))
        Text('dB')
          .fontSize(12)
          .fontColor('#666666')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text('最大')
          
          .fontColor('#666666')
        Text(this.maxDecibel.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.decibelService.getDecibelColor(this.maxDecibel))
        Text('dB')
          .fontSize(12)
          .fontColor('#666666')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(20)
  }

  @Builder
  ControlPanel() {
    Column() {
      if (this.isRecording) {
        Text(new Date(this.recordDuration).toISOString().substr(14, 5))
          .fontSize(16)
          .fontColor('#666666')
          .margin({ bottom: 16 })
      }

      Button() {
        if (this.isRecording) {
          Image($r('app.media.ic_stop'))
            .width(32)
            .height(32)
            .fillColor(Color.White)
        } else {
          Image($r('app.media.ic_play'))
            .width(32)
            .height(32)
            .fillColor(Color.White)
        }
      }
      .width(64)
      .height(64)
      .type(ButtonType.Circle)
      .backgroundColor(this.isRecording ? '#F44336' : '#4CAF50')
      .onClick(() => {
        if (this.isRecording) {
          this.stopRecording();
        } else {
          this.startRecording();
        }
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ vertical: 24 })
  }

  build() {
    Column() {
      LocationDisplay()

      AudioRecordDisplay({
        isRecordEnabled: this.isAudioRecordEnabled,
        onRecordEnabledChange: (enabled: boolean) => {
          this.isAudioRecordEnabled = enabled;
        }
      })

      this.DecibelDisplay()
      
      if (this.isRecording) {
        this.StatisticsDisplay()
      }

      this.ControlPanel()

      if (!this.isRecording) {
        BannerCard({
          context: this.context,
          adId: 'testw6vs28xxxy'
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding({ top: 16, bottom: 24 })
  }
}
```

#### 7. 历史记录组件(DecibelHistory.ets)
```typescript
import { DecibelRecord } from '../../models/DecibelRecord';
import { DecibelRecordService } from '../../services/DecibelRecordService';
import { DialogService } from '../../services/DialogService';
import { AudioPlayerService } from '../../services/AudioPlayerService';
import { FileService } from '../../services/FileService';
import { DecibelService } from '../../services/DecibelService';
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import hilog from '@ohos.hilog';

const TAG = 'DecibelHistory';
const DOMAIN = 0x0000;

@ComponentV2
export struct DecibelHistory {
  @State private records: DecibelRecord[] = [];
  @State private isLoading: boolean = true;
  @State private hasError: boolean = false;
  @State private selectedTab: number = 0;
  private context: common.Context = getContext(this) as common.Context;
  private recordService: DecibelRecordService = new DecibelRecordService(this.context);
  private dialogService: DialogService = new DialogService();
  private decibelService: DecibelService = new DecibelService();

  aboutToAppear() {
    this.loadRecords();
  }

  private async loadRecords() {
    try {
      this.isLoading = true;
      this.hasError = false;
      this.records = await this.recordService.getRecords();
    } catch (error) {
      hilog.error(DOMAIN, TAG, '加载记录失败: %{public}s', error instanceof Error ? error.message : String(error));
      this.hasError = true;
      promptAction.showToast({
        message: '加载记录失败：' + (error instanceof Error ? error.message : String(error)),
        duration: 3000
      });
    } finally {
      this.isLoading = false;
    }
  }

  private async toggleFavorite(record: DecibelRecord) {
    try {
      record.isFavorite = !record.isFavorite;
      await this.recordService.updateRecord(record);
      promptAction.showToast({
        message: record.isFavorite ? '已添加到收藏' : '已取消收藏',
        duration: 2000
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, '更新收藏状态失败: %{public}s', error instanceof Error ? error.message : String(error));
      promptAction.showToast({
        message: '操作失败：' + (error instanceof Error ? error.message : String(error)),
        duration: 3000
      });
    }
  }

  private async deleteRecord(record: DecibelRecord) {
    try {
      const result = await promptAction.showDialog({
        title: '确认删除',
        message: '确定要删除这条记录吗？此操作不可恢复。',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '删除', color: '#F44336' }
        ]
      });

      if (result.index === 1) {
        await this.recordService.deleteRecord(record);
        this.records = this.records.filter(r => r.id !== record.id);
        promptAction.showToast({
          message: '记录已删除',
          duration: 2000
        });
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, '删除记录失败: %{public}s', error instanceof Error ? error.message : String(error));
      promptAction.showToast({
        message: '删除失败：' + (error instanceof Error ? error.message : String(error)),
        duration: 3000
      });
    }
  }

  private async clearNonFavoriteRecords() {
    try {
      const result = await promptAction.showDialog({
        title: '清空非收藏记录',
        message: '确定要清空所有非收藏记录吗？此操作不可恢复。',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '清空', color: '#F44336' }
        ]
      });

      if (result.index === 1) {
        await this.recordService.clearNonFavoriteRecords();
        await this.loadRecords();
        promptAction.showToast({
          message: '非收藏记录已清空',
          duration: 2000
        });
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, '清空非收藏记录失败: %{public}s', error instanceof Error ? error.message : String(error));
      promptAction.showToast({
        message: '清空失败：' + (error instanceof Error ? error.message : String(error)),
        duration: 3000
      });
    }
  }

  @Builder
  RecordItem(record: DecibelRecord) {
    Column() {
      Row() {
        Column() {
          Row() {
            Text(new Date(record.timestamp).toLocaleString('zh-CN', {
              year: 'numeric',
              month: '2-digit',
              day: '2-digit',
              hour: '2-digit',
              minute: '2-digit',
              second: '2-digit',
              hour12: false
            }))
              
              .fontColor('#666666')

            if (record.isFavorite) {
              Image($r('app.media.ic_favorite'))
                .width(16)
                .height(16)
                .fillColor('#FF4081')
                .margin({ left: 8 })
            }
          }
          .width('100%')

          if (record.location) {
            Text(record.location)
              
              .fontColor('#999999')
              .margin({ top: 4 })
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .maxLines(1)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column() {
          Text(Math.round(record.values.reduce((a, b) => a + b, 0) / record.values.length).toString())
            .fontSize(24)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.decibelService.getDecibelColor(record.values[record.values.length - 1]))
          Text('dB')
            .fontSize(12)
            .fontColor('#666666')
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .shadow({ radius: 1, color: '#1A000000', offsetY: 2 })
      .onClick(() => {
        this.dialogService.showDetailDialog(
          getContext(this) as common.UIAbilityContext,
          (params) => DetailDialog(params),
          record,
          this.context
        );
      })
      .gesture(
        LongPressGesture()
          .onAction(() => {
            this.showRecordActions(record);
          })
      )
    }
    .padding({ left: 16, right: 16, bottom: 12 })
  }

  private async showRecordActions(record: DecibelRecord) {
    try {
      const result = await promptAction.showActionSheet({
        title: '记录操作',
        message: '选择要执行的操作',
        buttons: [
          {
            text: record.isFavorite ? '取消收藏' : '添加收藏',
            color: record.isFavorite ? '#666666' : '#FF4081'
          },
          {
            text: '删除记录',
            color: '#F44336'
          }
        ]
      });

      switch (result.index) {
        case 0:
          await this.toggleFavorite(record);
          break;
        case 1:
          await this.deleteRecord(record);
          break;
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, '显示操作菜单失败: %{public}s', error instanceof Error ? error.message : String(error));
    }
  }

  build() {
    Column() {
      Row() {
        Text('历史记录')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.black'))

        Blank()

        Button() {
          Image($r('app.media.ic_refresh'))
            .width(20)
            .height(20)
            .fillColor('#666666')
        }
        .type(ButtonType.Circle)
        .backgroundColor(Color.Transparent)
        .margin({ right: 8 })
        .onClick(() => {
          this.loadRecords();
        })

        Button() {
          Image($r('app.media.ic_delete'))
            .width(20)
            .height(20)
            .fillColor('#666666')
        }
        .type(ButtonType.Circle)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.clearNonFavoriteRecords();
        })
      }
      .width('100%')
      .padding({ left: 20, right: 12, top: 16, bottom: 16 })

      Tabs({
        barPosition: BarPosition.Start,
        index: this.selectedTab
      }) {
        TabContent() {
          if (this.isLoading) {
            LoadingProgress()
              .color('#2196F3')
              .width(32)
              .height(32)
          } else if (this.hasError) {
            Column() {
              Image($r('app.media.ic_error'))
                .width(64)
                .height(64)
                .margin({ bottom: 16 })
              Text('加载失败，请重试')
                .fontSize(16)
                .fontColor('#666666')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          } else if (this.records.length === 0) {
            Column() {
              Image($r('app.media.ic_empty'))
                .width(64)
                .height(64)
                .margin({ bottom: 16 })
              Text('暂无记录')
                .fontSize(16)
                .fontColor('#666666')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
          } else {
            List() {
              ForEach(this.records, (record: DecibelRecord) => {
                ListItem() {
                  this.RecordItem(record)
                }
              })
            }
            .width('100%')
            .height('100%')
            .layoutWeight(1)
          }
        }
        .tabBar('全部')
        .backgroundColor('#F5F5F5')

        TabContent() {
          if (this.isLoading) {
            LoadingProgress()
              .color('#2196F3')
              .width(32)
              .height(32)
          } else {
            List() {
              ForEach(this.records.filter(r => r.isFavorite), (record: DecibelRecord) => {
                ListItem() {
                  this.RecordItem(record)
                }
              })
            }
            .width('100%')
            .height('100%')
            .layoutWeight(1)
          }
        }
        .tabBar('收藏')
        .backgroundColor('#F5F5F5')
      }
      .onChange((index: number) => {
        this.selectedTab = index;
      })
      .width('100%')
      .layoutWeight(1)
      .barMode(BarMode.Fixed)
      .barWidth('100%')
      .barHeight(48)
      .animationDuration(300)

      BannerCard({
        context: this.context,
        adId: 'testw6vs28xxxy'
      })
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
```

#### 8. 文件保险箱组件(FileVault.ets)
```typescript
import { FileService } from '../../services/FileService';
import { DecibelRecordService } from '../../services/DecibelRecordService';
import { AudioPlayerService } from '../../services/AudioPlayerService';
import promptAction from '@ohos.promptAction';
import common from '@ohos.app.ability.common';
import hilog from '@ohos.hilog';

const TAG = 'FileVault';
const DOMAIN = 0x0000;

interface AudioFile {
  name: string;
  size: number;
  lastModified: number;
}

@ComponentV2
export struct FileVault {
  @State private files: AudioFile[] = [];
  @State private isLoading: boolean = true;
  @State private hasError: boolean = false;
  @State private currentPlayingFile: string | null = null;
  private context: common.Context = getContext(this) as common.Context;
  private fileService: FileService = new FileService(this.context);
  private audioPlayerService: AudioPlayerService = new AudioPlayerService(this.context, this.fileService);
  private recordService: DecibelRecordService = new DecibelRecordService(this.context);

  aboutToAppear() {
    this.loadFiles();
  }

  aboutToDisappear() {
    if (this.currentPlayingFile) {
      this.audioPlayerService.stop();
    }
  }

  private async loadFiles() {
    try {
      this.isLoading = true;
      this.hasError = false;

      const audioFiles = await this.fileService.listFiles('audio');
      const fileInfos: AudioFile[] = [];

      for (const fileName of audioFiles) {
        try {
          const fileInfo = await this.fileService.getFileInfo(`audio/${fileName}`);
          fileInfos.push({
            name: fileName,
            size: fileInfo.size,
            lastModified: fileInfo.lastModified
          });
        } catch (error) {
          hilog.warn(DOMAIN, TAG, `获取文件信息失败: ${fileName}, 错误: ${error instanceof Error ? error.message : String(error)}`);
        }
      }

      this.files = fileInfos.sort((a, b) => b.lastModified - a.lastModified);
    } catch (error) {
      hilog.error(DOMAIN, TAG, '加载文件列表失败: %{public}s', error instanceof Error ? error.message : String(error));
      this.hasError = true;
      promptAction.showToast({
        message: '加载文件失败：' + (error instanceof Error ? error.message : String(error)),
        duration: 3000
      });
    } finally {
      this.isLoading = false;
    }
  }

  private formatFileSize(bytes: number): string {
    if (bytes < 1024) {
      return bytes + ' B';
    } else if (bytes < 1024 * 1024) {
      return (bytes / 1024).toFixed(2) + ' KB';
    } else {
      return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
    }
  }

  private async playAudioFile(fileName: string) {
    try {
      if (this.currentPlayingFile === fileName) {
        await this.audioPlayerService.stop();
        this.currentPlayingFile = null;
        return;
      }

      if (this.currentPlayingFile) {
        await this.audioPlayerService.stop();
      }

      await this.audioPlayerService.playAudioFile(`audio/${fileName}`);
      this.currentPlayingFile = fileName;

      this.audioPlayerService.setOnStateChangeListener((state) => {
        if (state === 'completed' || state === 'error') {
          this.currentPlayingFile = null;
        }
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, '播放音频失败: %{public}s', error instanceof Error ? error.message : String(error));
      promptAction.showToast({
        message: '播放失败：' + (error instanceof Error ? error.message : String(error)),
        duration: 3000
      });
      this.currentPlayingFile = null;
    }
  }

  private async deleteFile(fileName: string) {
    try {
      const result = await promptAction.showDialog({
        title: '确认删除',
        message: '确定要删除这个音频文件吗？此操作不可恢复。',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '删除', color: '#F44336' }
        ]
      });

      if (result.index === 1) {
        if (this.currentPlayingFile === fileName) {
          await this.audioPlayerService.stop();
          this.currentPlayingFile = null;
        }

        await this.fileService.deleteFile(`audio/${fileName}`);
        this.files = this.files.filter(f => f.name !== fileName);

        promptAction.showToast({
          message: '文件已删除',
          duration: 2000
        });
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, '删除文件失败: %{public}s', error instanceof Error ? error.message : String(error));
      promptAction.showToast({
        message: '删除失败：' + (error instanceof Error ? error.message : String(error)),
        duration: 3000
      });
    }
  }

  @Builder
  FileItem(file: AudioFile) {
    Row() {
      Row() {
        Image($r('app.media.ic_audio'))
          .width(24)
          .height(24)
          .fillColor('#2196F3')
          .margin({ right: 12 })

        Column() {
          Text(file.name)
            .fontSize(16)
            .fontColor('#333333')
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(1)

          Text(this.formatFileSize(file.size))
            
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Button() {
          Image(this.currentPlayingFile === file.name ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
            .width(24)
            .height(24)
            .fillColor('#666666')
        }
        .type(ButtonType.Circle)
        .backgroundColor(Color.Transparent)
        .margin({ right: 8 })
        .onClick(() => {
          this.playAudioFile(file.name);
        })

        Button() {
          Image($r('app.media.ic_delete'))
            .width(24)
            .height(24)
            .fillColor('#666666')
        }
        .type(ButtonType.Circle)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.deleteFile(file.name);
        })
      }
      .width('100%')
      .padding(16)
      .borderRadius(12)
      .backgroundColor(Color.White)
      .shadow({ radius: 1, color: '#1A000000', offsetY: 2 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 12 })
  }

  build() {
    Column() {
      Row() {
        Text('文件保险箱')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.black'))

        Blank()

        Button() {
          Image($r('app.media.ic_refresh'))
            .width(20)
            .height(20)
            .fillColor('#666666')
        }
        .type(ButtonType.Circle)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.loadFiles();
        })
      }
      .width('100%')
      .padding({ left: 20, right: 12, top: 16, bottom: 16 })

      if (this.isLoading) {
        LoadingProgress()
          .color('#2196F3')
          .width(32)
          .height(32)
      } else if (this.hasError) {
        Column() {
          Image($r('app.media.ic_error'))
            .width(64)
            .height(64)
            .margin({ bottom: 16 })
          Text('加载失败，请重试')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.files.length === 0) {
        Column() {
          Image($r('app.media.ic_empty'))
            .width(64)
            .height(64)
            .margin({ bottom: 16 })
          Text('暂无音频文件')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.files, (file: AudioFile) => {
            ListItem() {
              this.FileItem(file)
            }
          })
        }
        .width('100%')
        .height('100%')
        .layoutWeight(1)
      }

      BannerCard({
        context: this.context,
        adId: 'testw6vs28xxxy'
      })
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
```

#### 9. 详情对话框组件(DetailDialog.ets)
```typescript
import { DecibelRecord } from '../../models/DecibelRecord';
import { DecibelService } from '../../services/DecibelService';
import { AudioPlayerService } from '../../services/AudioPlayerService';
import { FileService } from '../../services/FileService';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';
import hilog from '@ohos.hilog';

const TAG = 'DetailDialog';
const DOMAIN = 0x0000;

interface NoiseSegment {
  name: string;
  value: number;
  color: string;
}

interface NoiseDistribution {
  segments: NoiseSegment[];
  values: number[];
}

@CustomDialog
export struct DetailDialog {
  @State private isPlaying: boolean = false;
  @State private noiseDistribution: NoiseDistribution = { segments: [], values: [] };
  @State private translateY: number = 0;
  @Param @Require selectedRecord: DecibelRecord | null;
  @Param @Require context: common.Context;
  @Param @Require fileService: FileService | null;
  @BuilderParam closeDialog: () => void;
  private startY: number = 0;
  private decibelService: DecibelService = new DecibelService();
  private audioPlayerService!: AudioPlayerService;

  aboutToAppear() {
    if (!this.context) {
      hilog.error(DOMAIN, TAG, 'Context is not available');
      return;
    }
    if (!this.fileService) {
      hilog.error(DOMAIN, TAG, 'FileService is not available');
      return;
    }

    try {
      this.audioPlayerService = new AudioPlayerService(this.context, this.fileService);
      hilog.info(DOMAIN, TAG, 'AudioPlayerService 初始化成功');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'AudioPlayerService 初始化失败: %{public}s', error instanceof Error ? error.message : String(error));
    }

    if (this.selectedRecord && this.selectedRecord.values.length > 0) {
      this.calculateNoiseDistribution();
    }
  }

  aboutToDisappear() {
    if (this.isPlaying) {
      this.audioPlayerService.stop();
    }
  }

  private calculateNoiseDistribution() {
    const values = this.selectedRecord!.values;
    const levelCounts = new Map<string, number>();
    values.forEach(value => {
      const level = this.decibelService.getDecibelLevel(value);
      levelCounts.set(level, (levelCounts.get(level) || 0) + 1);
    });

    const levelOrder = ['极度危险', '危险', '嘈杂', '正常', '安静'];
    const segments: NoiseSegment[] = [];
    const total = values.length;

    levelOrder.forEach(level => {
      const count = levelCounts.get(level) || 0;
      if (count > 0) {
        const sampleValue = values.find(v => this.decibelService.getDecibelLevel(v) === level) || 0;
        segments.push({
          name: level,
          value: Math.round((count / total) * 100),
          color: this.decibelService.getDecibelColor(sampleValue)
        });
      }
    });

    this.noiseDistribution = {
      segments: segments,
      values: segments.map(s => s.value)
    };
  }

  @Builder
  DialogTitleBuilder() {
    Row() {
      Row() {
        Text('检测报告')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        if (this.selectedRecord!.isFavorite) {
          Image($r('app.media.ic_favorite'))
            .width(20)
            .height(20)
            .fillColor('#FF4081')
            .margin({ left: 8 })
        }
      }
      Blank()
      Button() {
        Image($r('app.media.ic_close'))
          .width(24)
          .height(24)
          .fillColor('#666666')
      }
      .type(ButtonType.Circle)
      .backgroundColor(Color.Transparent)
      .onClick(this.closeDialog)
    }
    .width('100%')
    .height(56)
    .padding({ left: 20, right: 12 })
  }

  @Builder
  BasicInfoBuilder() {
    Column() {
      Text('基本信息')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      Row() {
        Text('检测时间')
          
          .fontColor('#666666')
        Text(new Date(this.selectedRecord!.timestamp).toLocaleString('zh-CN', {
          year: 'numeric',
          month: '2-digit',
          day: '2-digit',
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit',
          hour12: false
        }))
          
          .fontColor('#333333')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 8 })

      Row() {
        Text('检测时长')
          
          .fontColor('#666666')
        Text(`${Math.round(this.selectedRecord!.duration / 1000)}秒`)
          
          .fontColor('#333333')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 8 })

      if (this.selectedRecord!.location) {
        Row() {
          Text('检测位置')
            
            .fontColor('#666666')
          Text(this.selectedRecord!.location)
            
            .fontColor('#333333')
            .textAlign(TextAlign.End)
            .textOverflow({ overflow: TextOverflow.None })
            .width('70%')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 8 })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  NoiseDistributionBuilder() {
    Column() {
      Text('噪音级别分布')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 8 })

      if (!this.selectedRecord || this.selectedRecord.values.length === 0) {
        Column() {
          Image($r('app.media.ic_empty'))
            .width(32)
            .height(32)
            .fillColor('#999999')
            .margin({ bottom: 8 })
          Text('暂无噪音级别分布数据')
            
            .fontColor('#999999')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 20, bottom: 20 })
      } else {
        Row() {
          Stack() {
            DataPanel({
              values: this.noiseDistribution.values,
              max: 100,
              type: DataPanelType.Circle
            })
              .valueColors(this.noiseDistribution.segments.map(segment => segment.color))
              .trackBackgroundColor('#08182431')
              .width(160)
              .height(160)
          }
          .width(160)
          .height(160)
          .margin({ right: 16, top: -16 })

          Column() {
            ForEach(this.noiseDistribution.segments, (segment: NoiseSegment) => {
              Row() {
                Row()
                  .width(12)
                  .height(12)
                  .borderRadius(6)
                  .backgroundColor(segment.color)
                  .margin({ right: 8 })

                Text(segment.name)
                  
                  .fontColor('#666666')

                Text(`${segment.value}%`)
                  
                  .fontColor('#333333')
                  .margin({ left: 8 })
              }
              .width('100%')
              .margin({ bottom: 8 })
              .alignItems(VerticalAlign.Center)
            })
          }
          .layoutWeight(1)
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  build() {
    Column() {
      this.DialogTitleBuilder()

      Scroll() {
        Column() {
          this.BasicInfoBuilder()
          this.NoiseDistributionBuilder()

          if (this.selectedRecord!.audioFilePath) {
            Column() {
              Text('录音回放')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 12 })

              Button() {
                Row() {
                  Image(this.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
                    .width(24)
                    .height(24)
                    .fillColor(Color.White)
                    .margin({ right: 8 })
                  Text(this.isPlaying ? '暂停' : '播放')
                    .fontSize(16)
                    .fontColor(Color.White)
                }
              }
              .width('100%')
              .height(48)
              .type(ButtonType.Normal)
              .backgroundColor('#2196F3')
              .borderRadius(24)
              .onClick(async () => {
                try {
                  if (this.isPlaying) {
                    await this.audioPlayerService.pause();
                    this.isPlaying = false;
                  } else {
                    await this.audioPlayerService.playAudioFile(this.selectedRecord!.audioFilePath!);
                    this.isPlaying = true;
                  }
                } catch (error) {
                  hilog.error(DOMAIN, TAG, '播放音频失败: %{public}s', error instanceof Error ? error.message : String(error));
                }
              })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ bottom: 12 })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('60%')
    .backgroundColor('#F5F5F5')
    .borderRadius({ topLeft: 24, topRight: 24 })
    .translate({ y: this.translateY })
    .gesture(
      PanGesture({ direction: PanDirection.Up })
        .onActionStart((event: GestureEvent) => {
          this.startY = event.offsetY;
        })
        .onActionUpdate((event: GestureEvent) => {
          const deltaY = event.offsetY - this.startY;
          if (deltaY < 0) {
            this.translateY = deltaY;
          }
        })
        .onActionEnd(() => {
          animateTo({
            duration: 200,
            curve: Curve.EaseOut,
            delay: 0,
            iterations: 1,
            playMode: PlayMode.Normal,
            onFinish: () => {
              this.translateY = 0;
            }
          }, () => {
            this.translateY = 0;
          });
        })
    )
  }
}