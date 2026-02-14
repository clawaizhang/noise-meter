import { PromptAction } from '@ohos.arkui.UIContext';
import { DecibelService } from '../../services/DecibelService';
import { DecibelRecordService } from '../../services/DecibelRecordService';
import { AudioPlayer } from '../../components/business/AudioPlayer';
import { DecibelRecord } from '../../models/DecibelRecord';
import { FileUtils } from '../../utils/FileUtils';
import { DesignConstants } from '../../constants/DesignConstants';
import { AppStorageV2, curves } from '@kit.ArkUI';
import { AppKeys } from '../../models/AppKeys';
import { Throttle } from '../../utils/Debounce';
import { FilterPanel } from '../../components/filter/FilterPanel';
import { FilterConfig, FilterManager } from '../../models/FilterConfig';
import { DetailDialogBuilder, DetailDialogParams } from '../../pages/noisemeter/DetailDialogNavigation';
import { DialogHub, InfSheet } from '@hadss/dialoghub';

// 历史记录数据源
class DecibelRecordDataSource implements IDataSource {
  private records: DecibelRecord[];
  private listeners: DataChangeListener[] = [];

  constructor(records: DecibelRecord[]) {
    this.records = records;
  }

  replaceData(records: DecibelRecord[]) {
    this.records = records;
  }

  appendData(records: DecibelRecord[]) {
    const startIndex = this.records.length;
    this.records.push(...records);
    this.notifyDataAdd(startIndex);
  }

  totalCount(): number {
    return this.records.length;
  }

  getData(index: number): DecibelRecord {
    return this.records[index];
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener);
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  notifyDataReload(): void {
    this.listeners.forEach(listener => listener.onDataReloaded());
  }

  notifyDataAdd(startIndex: number): void {
    this.listeners.forEach(listener => {
      for (let i = startIndex; i < this.records.length; i++) {
        listener.onDataAdd(i);
      }
    });
  }

  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => listener.onDataDelete(index));
  }
}

interface HistoryContentParams {
  isActiveTab?: boolean;
}

@ComponentV2
export struct HistoryContent {
  @Param isActiveTab: boolean = false;
  @Local records: DecibelRecord[] = [];
  @Local dataSource: DecibelRecordDataSource = new DecibelRecordDataSource([]);
  @Local selectedRecord: DecibelRecord | null = null;
  @Local pendingDeleteId: string = '';
  @Local pendingDeleteAudioId: string = '';
  @Local shouChangMode: boolean = false;
  @Local deleteRecordMode: boolean = false;
  @Local deleteAudioMode: boolean = false;
  @Local showMenu: boolean = false;
  @Local showFilterPanel: boolean = false;
  @Local ak: AppKeys = AppStorageV2.connect(AppKeys)!;
  @Local currentModeName: string = '';
  @Local isLoading: boolean = false;
  // 选中状态存储 - 用 Set 提高查找性能
  @Local selectedIdSet: Set<string> = new Set();
  @Local isLoadingMore: boolean = false;
  @Local hasMoreData: boolean = true;
  @Local totalRecords: number = 0;
  @Local currentOffset: number = 0;
  @Local currentFilters: FilterConfig = new FilterConfig(false);
  @Local filterManager: FilterManager = new FilterManager();
  private readonly PAGE_SIZE: number = 10;
  private context: Context = getContext(this)
  private recordService: DecibelRecordService = new DecibelRecordService(this.context);
  private promptAction: PromptAction = this.getUIContext().getPromptAction();

  aboutToAppear() {
    this.loadInitialRecords();
  }

  // 监听 Tab 切换，当切换到历史 Tab 时刷新数据
  @Monitor('isActiveTab')
  onActiveTabChange(monitor:IMonitor) {
    const isActive = monitor.value<boolean>()?.now;
    if (isActive) {
      this.loadInitialRecords();
    }
  }

  async loadInitialRecords() {
    if (this.isLoading) {
      return;
    }

    this.isLoading = true;
    try {
      // 获取总记录数
      this.totalRecords = await this.recordService.getTotalCount();

      // 根据过滤器状态加载记录
      let initialRecords: DecibelRecord[];
      if (this.currentFilters.isActive) {
        initialRecords = await this.recordService.getFilteredRecordsPaged(this.currentFilters, this.PAGE_SIZE, 0);
        this.totalRecords = await this.recordService.getFilteredTotalCount(this.currentFilters);
      } else {
        initialRecords = await this.recordService.getRecordsPaged(this.PAGE_SIZE, 0);
      }

      this.records = initialRecords;
      this.currentOffset = initialRecords.length;

      if (this.dataSource) {
        this.dataSource.replaceData(this.records);
        this.dataSource.notifyDataReload();
      } else {
        this.dataSource = new DecibelRecordDataSource(this.records);
      }

      // 检查是否还有更多数据
      this.hasMoreData = this.currentOffset < this.totalRecords;
    } catch (error) {
      console.error('加载历史记录失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  async loadMoreRecords() {
    if (this.isLoadingMore || !this.hasMoreData) {
      return;
    }

    this.isLoadingMore = true;
    try {
      let moreRecords: DecibelRecord[];
      if (this.currentFilters.isActive) {
        moreRecords =
          await this.recordService.getFilteredRecordsPaged(this.currentFilters, this.PAGE_SIZE, this.currentOffset);
      } else {
        moreRecords = await this.recordService.getRecordsPaged(this.PAGE_SIZE, this.currentOffset);
      }

      if (moreRecords.length > 0) {
        this.records.push(...moreRecords);
        this.currentOffset += moreRecords.length;
        this.dataSource.appendData(moreRecords);
      }

      // 检查是否还有更多数据
      this.hasMoreData = this.currentOffset < this.totalRecords;
    } catch (error) {
      console.error('加载更多记录失败:', error);
    } finally {
      this.isLoadingMore = false;
    }
  }

  private handleApplyFilters(filters: FilterConfig): void {
    this.currentFilters = filters;
    this.showFilterPanel = false;
    // 重新加载过滤后的数据
    this.loadInitialRecords();
  }

  private handleResetFilters(): void {
    this.currentFilters = new FilterConfig(false);
    this.showFilterPanel = false;
    // 重新加载所有数据
    this.loadInitialRecords();
  }

  // 打开筛选弹窗
  private openFilterDialog(): void {
    Throttle.click(() => {
      let filterDialog: InfSheet | null = null;
      
      // 构建筛选面板参数
      const filterParams: FilterPanelParams = {
        filterConfig: this.currentFilters,
        onApply: (filters: FilterConfig) => {
          // 先关闭弹窗
          if (filterDialog) {
            filterDialog.dismiss();
            filterDialog = null;
          }
          // 再应用过滤
          this.handleApplyFilters(filters);
        },
        onReset: () => {
          // 先关闭弹窗
          if (filterDialog) {
            filterDialog.dismiss();
            filterDialog = null;
          }
          // 再重置过滤
          this.handleResetFilters();
        }
      };

      filterDialog = DialogHub.getSheet()
        .setStyle({
          title: { title: '筛选记录' },
          backgroundColor: $r('sys.color.background_secondary')
        })
        .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
        .setComponentTargetId('mainId')
        .setContent(wrapBuilder(FilterPanelBuilder), filterParams)
        .build();
      filterDialog.show();
    });
  }

  emptyAll = async () => {
    AlertDialog.show({
      title: '清空检测记录',
      message: '确定要清空检测记录吗？\n已收藏的记录将会保留',
      alignment: DialogAlignment.Center,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '取消',
        action: () => {
          // 不执行任何操作
        }
      },
      secondaryButton: {
        value: '清空',
        action: async () => {
          try {
            // 清空非收藏记录
            await this.recordService.clearUnfavoriteRecords();
            // 重新加载记录列表
            await this.loadInitialRecords();
            // 显示清空成功提示
            this.promptAction.showToast({
              message: '已清空检测记录',
              duration: 2000,
              bottom: '50%'
            });
          } catch (error) {
            console.error('清空历史记录失败:', error);
          }
        }
      }
    });
  }



  @Builder
  RecordItem(record: DecibelRecord) {
    Column() {
      // 第一行：复选框 + 头部信息（时间、徽章）
      if (this.isInAnyMode) {
        // 操作模式：复选框在左上角，与时间同行
        Row() {
          // 左侧复选框
          // 复选框 - 使用 @Computed 缓存的选中状态
          this.RecordCheckboxBuilder(record)
          
          // 时间
          Text(this.formatTimestamp(record.timestamp))
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ left: 8 })
          
          Blank()
          
          // 徽章区域
          Row({ space: 8 }) {
            if (record.isFavorite) {
              Image($r('app.media.ic_favorite'))
                .width(16)
                .height(16)
                .fillColor('#FF4081')
            }
            if (record.audioFilePath) {
              Image($r('app.media.ic_audio_analysis'))
                .width(16)
                .height(16)
                .fillColor($r('sys.color.brand'))
            }
            this.RecordActionButtons(record)
          }
        }
        .width('100%')
        .padding({ left: 12, right: 16, top: 12, bottom: 4 })
        
        // 分隔线
        Divider()
          .color($r('sys.color.comp_divider'))
          .height(1)
          .margin({ left: 12, right: 16 })
      }
      
      // 主要内容区域（左侧色条 + 内容）
      Row() {
        // 左侧严重程度色条
        Column()
          .width(3)
          .backgroundColor(DecibelService.getDecibelColor(record.avgDecibel))
          .borderRadius({ topLeft: 16, bottomLeft: 16 })
          .alignSelf(ItemAlign.Stretch)
        
        // 主内容
        Column({ space: 12 }) {
          // 非操作模式时显示头部
          if (!this.isInAnyMode) {
            this.RecordHeader(record)
          }
          
          // 核心数据区域
          this.RecordCoreData(record)
          
          // 位置/备注信息
          this.RecordLocationInfo(record)
          
          // 底部操作栏
          this.RecordActionBar(record)
        }
        .layoutWeight(1)
        .padding({ 
          left: 12, 
          right: 16, 
          top: this.isInAnyMode ? 8 : 12,
          bottom: 12 
        })
      }
      .width('100%')
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .borderRadius(16)
    .shadow(DesignConstants.SHADOW_SM)
    // 点击卡片打开详情（只在非操作模式）
    .onClick(() => {
      if (!this.isInAnyMode) {
        Throttle.click(() => {
          this.showNoiseDetails(record);
        });
      }
    })
    .transition(TransitionEffect.scale({ x: 0, y: 0 })
      .combine(TransitionEffect.translate({ x: 150 }).animation({ curve: curves.springMotion() })))
  }

  @Builder
  RecordHeader(record: DecibelRecord) {
    Row() {
      Text(this.formatTimestamp(record.timestamp))
        .fontSize(DesignConstants.FONT_SIZE_SM)
        .fontColor($r('sys.color.font_secondary'))
      
      Blank()
      
      Row({ space: 8 }) {
        // 收藏徽章
        if (record.isFavorite) {
          Image($r('app.media.ic_favorite'))
            .width(16)
            .height(16)
            .fillColor('#FF4081')
        }
        // 音频徽章
        if (record.audioFilePath) {
          Image($r('app.media.ic_audio_analysis'))
            .width(16)
            .height(16)
            .fillColor($r('sys.color.brand'))
        }
        
        // 操作模式下的按钮
        this.RecordActionButtons(record)
      }
    }
    .width('100%')
  }

  @Builder
  RecordCoreData(record: DecibelRecord) {
    Column({ space: 8 }) {
      // 第一行：平均分贝 + 等级标签（左对齐） + 极值数据（右对齐）
      Row() {
        // 左侧：大数字平均分贝 + 等级
        Row({ space: 8 }) {
          Text(`${record.avgDecibel}`)
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor(DecibelService.getDecibelColor(record.avgDecibel))
          
          Text(DecibelService.getDecibelLevel(record.avgDecibel))
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .alignSelf(ItemAlign.End)
            .margin({ bottom: 6 })
        }
        
        Blank()
        
        // 右侧：极值数据（水平排列）- 从左到右递增：最小 → 最大
        Row({ space: 12 }) {
          // 最小值（左）
          Column({ space: 2 }) {
            Text(`${record.minDecibel}`)
              .fontSize(DesignConstants.FONT_SIZE_LG)
              .fontWeight(FontWeight.Medium)
              .fontColor(DecibelService.getDecibelColor(record.minDecibel))
            Text('最小')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_tertiary'))
          }
          
          // 最大值（右）
          Column({ space: 2 }) {
            Text(`${record.maxDecibel}`)
              .fontSize(DesignConstants.FONT_SIZE_LG)
              .fontWeight(FontWeight.Medium)
              .fontColor(DecibelService.getDecibelColor(record.maxDecibel))
            Text('最大')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor($r('sys.color.font_tertiary'))
          }
        }
      }
      .width('100%')
      
      // 第二行：范围条（贯穿整行）
      this.RangeBarFull(record)
    }
    .width('100%')
  }
  
  // 全宽范围条
  @Builder
  RangeBarFull(record: DecibelRecord) {
    Row({ space: 6 }) {
      Text(`${record.minDecibel}`)
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_tertiary'))
      
      // 范围条背景
      Stack({ alignContent: Alignment.Start }) {
        Row()
          .width('100%')
          .height(4)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(2)
        
        // 平均值指示点
        Row()
          .width(8)
          .height(8)
          .backgroundColor(DecibelService.getDecibelColor(record.avgDecibel))
          .borderRadius(4)
          .position({
            x: this.calculateAvgPosition(record.minDecibel, record.avgDecibel, record.maxDecibel),
            y: -2
          })
      }
      .layoutWeight(1)
      .height(4)
      
      Text(`${record.maxDecibel}`)
        .fontSize(DesignConstants.FONT_SIZE_XS)
        .fontColor($r('sys.color.font_tertiary'))
    }
    .width('100%')
  }

  @Builder
  RecordRangeBar(record: DecibelRecord) {
    Column({ space: 4 }) {
      // 范围条 - 使用 Stack 实现平均值指示器
      Stack({ alignContent: Alignment.Start }) {
        // 背景条
        Row()
          .width('100%')
          .height(4)
          .backgroundColor($r('sys.color.comp_background_secondary'))
          .borderRadius(2)
        
        // 平均值指示器
        Row()
          .width(8)
          .height(8)
          .backgroundColor(DecibelService.getDecibelColor(record.avgDecibel))
          .borderRadius(4)
          .position({
            x: this.calculateAvgPosition(record.minDecibel, record.avgDecibel, record.maxDecibel),
            y: -2
          })
      }
      .width('100%')
      .height(8)
      
      // 数值标注
      Row() {
        Text(`${record.minDecibel}`)
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))
        
        Text('平均值')
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))
        
        Text(`${record.maxDecibel}`)
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
  }
  
  // 计算平均值在范围条中的位置
  private calculateAvgPosition(min: number, avg: number, max: number): string {
    const range = max - min || 1
    const position = ((avg - min) / range) * 100
    // 限制在 0-100 范围内
    const clampedPosition = Math.max(0, Math.min(100, position))
    return `${clampedPosition}%`
  }

  @Builder
  RecordLocationInfo(record: DecibelRecord) {
    Column({ space: 4 }) {
      if (record.location) {
        Row({ space: 4 }) {
          Image($r('app.media.ic_location'))
            .width(12)
            .height(12)
            .fillColor($r('sys.color.font_tertiary'))
          Text(record.location)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
      }
      
      if (record.comment) {
        Row({ space: 4 }) {
          Image($r('app.media.ic_document_edit'))
            .width(12)
            .height(12)
            .fillColor($r('sys.color.font_tertiary'))
          Text(record.comment)
            .fontSize(DesignConstants.FONT_SIZE_SM)
            .fontColor($r('sys.color.font_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
      }
    }
    .width('100%')
  }

  @Builder
  RecordActionBar(record: DecibelRecord) {
    Row() {
      // 左侧：音频播放器
      if (record.audioFilePath) {
        AudioPlayer({
          audioFilePath: record.audioFilePath,
          compact: true
        })
      } else {
        // 无音频时占位
        Row().width(32).height(32)
      }
      
      Blank()
      
      // 右侧：时长和大小
      Row({ space: 6 }) {
        Text(`⏱️ ${record.duration}秒`)
          .fontSize(DesignConstants.FONT_SIZE_XS)
          .fontColor($r('sys.color.font_tertiary'))
        
        if (record.audioFilePath) {
          Text(`·`)
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_tertiary'))
          Text(this.getAudioSizeText(record.audioFilePath))
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor($r('sys.color.font_tertiary'))
        }
      }
    }
    .width('100%')
    .height(32)
  }

  @Builder
  RecordActionButtons(record: DecibelRecord) {
    // 收藏/删除模式按钮组
    if (this.shouChangMode || this.deleteRecordMode || this.deleteAudioMode) {
      Column({ space: 4 }) {
        // 收藏按钮
        if (this.shouChangMode) {
          Button(record.isFavorite ? '取消' : '收藏')
            .fontSize(DesignConstants.FONT_SIZE_XS)
            .fontColor(record.isFavorite ? '#FF4081' : Color.White)
            .height(24)
            .padding({ left: 8, right: 8 })
            .backgroundColor(record.isFavorite ? '#FFE0EB' : '#FF4081')
            .borderRadius(12)
            .gesture(
              TapGesture()
                .onAction(() => {
                  Throttle.click(async () => {
                    record.isFavorite = !record.isFavorite;
                    await this.recordService.updateRecord(record);
                    this.promptAction.showToast({
                      message: record.isFavorite ? '已添加到收藏' : '已取消收藏',
                      duration: 2000,
                      bottom: '50%'
                    });
                  })
                })
            )
        }
        
        // 删除记录按钮
        if (this.deleteRecordMode) {
          if (record.id === this.pendingDeleteId) {
            Button('确认')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor(Color.White)
              .height(24)
              .padding({ left: 8, right: 8 })
              .backgroundColor($r('sys.color.warning'))
              .borderRadius(12)
              .gesture(
                TapGesture()
                  .onAction(() => {
                    Throttle.click(() => {
                      this.deleteRecord(record)
                    })
                  })
              )
          } else {
            Button('删除')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor(Color.White)
              .height(24)
              .padding({ left: 8, right: 8 })
              .backgroundColor($r('sys.color.alert'))
              .borderRadius(12)
              .gesture(
                TapGesture()
                  .onAction(() => {
                    Throttle.click(() => {
                      this.pendingDeleteId = record.id
                    })
                  })
              )
          }
        }
        
        // 删除音频按钮
        if (this.deleteAudioMode && record.audioFilePath) {
          if (record.id === this.pendingDeleteAudioId) {
            Button('确认')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor(Color.White)
              .height(24)
              .padding({ left: 8, right: 8 })
              .backgroundColor($r('sys.color.warning'))
              .borderRadius(12)
              .gesture(
                TapGesture()
                  .onAction(() => {
                    Throttle.click(() => {
                      this.deleteRecordAudio(record)
                    })
                  })
              )
          } else {
            Button('删音频')
              .fontSize(DesignConstants.FONT_SIZE_XS)
              .fontColor(Color.White)
              .height(24)
              .padding({ left: 8, right: 8 })
              .backgroundColor($r('sys.color.alert'))
              .borderRadius(12)
              .gesture(
                TapGesture()
                  .onAction(() => {
                    Throttle.click(() => {
                      this.pendingDeleteAudioId = record.id
                    })
                  })
              )
          }
        }
      }
    }
  }

  // 格式化时间戳（今天/昨天/星期几/日期）
  private formatTimestamp(timestamp: number): string {
    const now = new Date()
    const date = new Date(timestamp)
    const diffDays = Math.floor((now.getTime() - timestamp) / (1000 * 60 * 60 * 24))
    
    const timeStr = date.toLocaleTimeString('zh-CN', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    })
    
    // 今天
    if (diffDays === 0 && now.getDate() === date.getDate()) {
      return `今天 ${timeStr}`
    }
    // 昨天
    if (diffDays === 1 || (diffDays === 0 && now.getDate() !== date.getDate())) {
      return `昨天 ${timeStr}`
    }
    // 本周内
    if (diffDays < 7) {
      const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
      return `${weekdays[date.getDay()]} ${timeStr}`
    }
    // 更早
    return date.toLocaleString('zh-CN', {
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    })
  }

  private showNoiseDetails(record: DecibelRecord) {
    this.selectedRecord = record;
    this.showDetailDialog();
  }

  private formatBytes(bytes: number): string {
    if (bytes === 0) {
      return '0 B'
    }
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }
  
  // 安全获取音频文件大小
  private getAudioSizeText(audioPath: string): string {
    try {
      const fileInfo = FileUtils.getFileInfoSync(audioPath.replace(FileUtils.getBasePath(), ''))
      return this.formatBytes(fileInfo.size)
    } catch (error) {
      return ''
    }
  }

  private async deleteRecord(record: DecibelRecord) {
    try {
      // 从列表中除该记录
      const index = this.records.findIndex(r => r.id === record.id);
      if (index !== -1) {
        this.records.splice(index, 1);
      }
      // 从数据库中删除记录
      await this.recordService.deleteRecord(record.id);
      // 隐藏删除按钮
      this.pendingDeleteId = '';
      this.dataSource.notifyDataDelete(index);
      // 显示删除成功提示
      this.promptAction.showToast({
        message: '删除成功',
        duration: 2000,
        bottom: '50%'
      });
    } catch (error) {
      console.error('删除记录失败:', error);
    }
  }

  private async deleteRecordAudio(record: DecibelRecord) {
    try {
      record.audioFilePath = '';
      this.recordService.updateRecord(record).then(() => {
        FileUtils.deleteFile(record.audioFilePath!.replace(FileUtils.getBasePath(), '')).then(() => {
        })
      });
      // 隐藏删除按钮
      this.pendingDeleteAudioId = '';
      // 显示删除成功提示
      this.promptAction.showToast({
        message: '删除成功',
        duration: 2000,
        bottom: '50%'
      });
    } catch (error) {
      console.error('删除记录失败:', error);
    }
  }

  // 判断是否处于任何操作模式
  @Computed
   get isInAnyMode(): boolean {
    return this.shouChangMode || this.deleteRecordMode || this.deleteAudioMode;
  }

  // 获取当前模式名称
  @Computed
   get getCurrentModeName(): string {
    if (this.shouChangMode) {
      return '收藏';
    }
    if (this.deleteRecordMode) {
      return '删除记录';
    }
    if (this.deleteAudioMode) {
      return '删除音频';
    }
    return '';
  }

  // 退出所有操作模式
  private exitAllModes(): void {
    this.shouChangMode = false;
    this.deleteRecordMode = false;
    this.deleteAudioMode = false;
    this.pendingDeleteId = '';
    this.pendingDeleteAudioId = '';
    this.currentModeName = '';
    this.selectedIdSet = new Set();
  }

  // 切换记录选中状态
  private toggleSelection(recordId: string): void {
    const newSet = new Set(this.selectedIdSet);
    if (newSet.has(recordId)) {
      newSet.delete(recordId);
    } else {
      newSet.add(recordId);
    }
    this.selectedIdSet = newSet;
  }

  // 获取实际选中的记录ID列表
  private getSelectedIds(): string[] {
    return Array.from(this.selectedIdSet);
  }

  // 获取选中记录中的收藏统计 - 返回数组 [已收藏数, 未收藏数]
  private getSelectedFavoriteStats(): number[] {
    const selectedIds = this.getSelectedIds();
    const selectedRecords = this.records.filter(r => selectedIds.includes(r.id));
    const favorited = selectedRecords.filter(r => r.isFavorite).length;
    const unfavorited = selectedRecords.filter(r => !r.isFavorite).length;
    return [favorited, unfavorited];
  }

  // 复选框 Builder - 直接访问 Set 而不是调用方法
  @Builder
  RecordCheckboxBuilder(record: DecibelRecord) {
    // 直接在模板中访问 Set，避免方法调用开销
    Checkbox()
      .select(this.selectedIdSet.has(record.id))
      .selectedColor($r('sys.color.brand'))
      .width(20)
      .height(20)
      .onChange(() => {
        this.toggleSelection(record.id);
      })
  }

  // 批量收藏（只收藏未收藏的记录）
  private async batchFavoriteRecords(): Promise<void> {
    const selectedIds = this.getSelectedIds();
    const selectedRecords = this.records.filter(r => selectedIds.includes(r.id) && !r.isFavorite);
    
    if (selectedRecords.length === 0) {
      this.promptAction.showToast({ message: '没有需要收藏的记录', duration: 2000, bottom: '50%' });
      return;
    }
    
    try {
      for (const record of selectedRecords) {
        record.isFavorite = true;
        await this.recordService.updateRecord(record);
      }
      
      this.promptAction.showToast({
        message: `已收藏 ${selectedRecords.length} 条记录`,
        duration: 2000,
        bottom: '50%'
      });
      
      this.exitAllModes();
    } catch (error) {
      console.error('批量收藏失败:', error);
    }
  }

  // 批量取消收藏（只取消已收藏的记录）
  private async batchUnfavoriteRecords(): Promise<void> {
    const selectedIds = this.getSelectedIds();
    const selectedRecords = this.records.filter(r => selectedIds.includes(r.id) && r.isFavorite);
    
    if (selectedRecords.length === 0) {
      this.promptAction.showToast({ message: '没有需要取消收藏的记录', duration: 2000, bottom: '50%' });
      return;
    }
    
    try {
      for (const record of selectedRecords) {
        record.isFavorite = false;
        await this.recordService.updateRecord(record);
      }
      
      this.promptAction.showToast({
        message: `已取消收藏 ${selectedRecords.length} 条记录`,
        duration: 2000,
        bottom: '50%'
      });
      
      this.exitAllModes();
    } catch (error) {
      console.error('批量取消收藏失败:', error);
    }
  }

  // 批量删除记录
  private async batchDeleteRecords(): Promise<void> {
    const selectedCount = this.selectedIdSet.size;
    if (selectedCount === 0) {
      this.promptAction.showToast({ message: '请先选择记录', duration: 2000, bottom: '50%' });
      return;
    }
    
    AlertDialog.show({
      title: '批量删除记录',
      message: `确定要删除选中的 ${selectedCount} 条记录吗？`,
      alignment: DialogAlignment.Center,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        action: async () => {
          try {
            const idsToDelete = this.getSelectedIds();
            for (const id of idsToDelete) {
              await this.recordService.deleteRecord(id);
            }
            // 从列表中移除
            this.records = this.records.filter(r => !idsToDelete.includes(r.id));
            this.dataSource.replaceData(this.records);
            this.dataSource.notifyDataReload();
            this.totalRecords -= idsToDelete.length;
            
            this.promptAction.showToast({
              message: `已删除 ${idsToDelete.length} 条记录`,
              duration: 2000,
              bottom: '50%'
            });
            this.exitAllModes();
          } catch (error) {
            console.error('批量删除记录失败:', error);
          }
        }
      }
    });
  }

  // 批量删除音频
  private async batchDeleteAudios(): Promise<void> {
    const selectedIds = this.getSelectedIds();
    if (selectedIds.length === 0) {
      this.promptAction.showToast({ message: '请先选择记录', duration: 2000, bottom: '50%' });
      return;
    }
    
    const selectedRecords = this.records.filter(r => selectedIds.includes(r.id) && r.audioFilePath);
    if (selectedRecords.length === 0) {
      this.promptAction.showToast({ message: '选中的记录中没有音频文件', duration: 2000, bottom: '50%' });
      return;
    }
    
    AlertDialog.show({
      title: '批量删除音频',
      message: `确定要删除选中的 ${selectedRecords.length} 个音频文件吗？`,
      alignment: DialogAlignment.Center,
      offset: { dx: 0, dy: -20 },
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        action: async () => {
          try {
            for (const record of selectedRecords) {
              const audioPath = record.audioFilePath;
              record.audioFilePath = '';
              await this.recordService.updateRecord(record);
              if (audioPath) {
                await FileUtils.deleteFile(audioPath.replace(FileUtils.getBasePath(), ''));
              }
            }
            
            this.promptAction.showToast({
              message: `已删除 ${selectedIds.length} 个音频文件`,
              duration: 2000,
              bottom: '50%'
            });
            this.exitAllModes();
          } catch (error) {
            console.error('批量删除音频失败:', error);
          }
        }
      }
    });
  }

  // 更新当前模式名称
  private updateCurrentModeName(): void {
    this.currentModeName = this.getCurrentModeName;
  }

  async showDetailDialog() {
    if (!this.selectedRecord) {
      return;
    }

    try {
      // 创建导航参数
      const params: DetailDialogParams = {
        selectedRecord: this.selectedRecord,
        context: getContext(this),
      };
      let detailDialog = DialogHub.getSheet()
        .setComponentTargetId('mainId')
        .setStyle({ backgroundColor: $r('sys.color.background_secondary') })
        .setConfig({ scrollSizeMode: ScrollSizeMode.CONTINUOUS })
        .setContent(wrapBuilder(DetailDialogBuilder), params)
        .build();
      detailDialog.show();
    } catch (error) {
      console.error('导航到详情页失败:', error);
    }
  }

  @Builder
  MenuBuilder() {
    Column({ space: 8 }) {
      // 批量收藏菜单项
      Button() {
        Row() {
          Image($r('app.media.ic_favorite'))
            .width(20)
            .height(20)
            .fillColor($r('sys.color.brand'))
            .margin({ right: 8 })
          Text('收藏')
            .fontSize(16)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .height(40)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(8)
      .onClick(() => {
        this.shouChangMode = true;
        this.deleteRecordMode = false;
        this.deleteAudioMode = false;
        this.updateCurrentModeName();
        this.showMenu = false;
      })

      // 批量删除记录菜单项
      Button() {
        Row() {
          Image($r('app.media.ic_delete'))
            .width(20)
            .height(20)
            .fillColor($r('sys.color.warning'))
            .margin({ right: 8 })
          Text('删除记录')
            .fontSize(16)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .height(40)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(8)
      .onClick(() => {
        this.deleteRecordMode = true;
        this.shouChangMode = false;
        this.deleteAudioMode = false;
        this.updateCurrentModeName();
        this.showMenu = false;
      })

      // 批量删除音频菜单项
      Button() {
        Row() {
          Image($r('app.media.ic_audio_analysis'))
            .width(20)
            .height(20)
            .fillColor($r('sys.color.warning'))
            .margin({ right: 8 })
          Text('删除音频')
            .fontSize(16)
            .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
      }
      .width('100%')
      .height(40)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('sys.color.comp_background_primary'))
      .borderRadius(8)
      .onClick(() => {
        this.deleteAudioMode = true;
        this.shouChangMode = false;
        this.deleteRecordMode = false;
        this.updateCurrentModeName();
        this.showMenu = false;
      })
    }
    .padding(8)
    .borderRadius(12)
    .width(160)
  }

  @Builder
  EmptyStateView() {
    Column() {
      // 空状态时也显示顶部工具栏
      this.HeaderBar()
      
      // 空状态提示
      Column() {
        Image($r('app.media.ic_empty'))
          .width(120)
          .fillColor($r('sys.color.font_primary'))
          .height(120)
          .margin({ bottom: DesignConstants.SPACING_LG })
        Text('暂无检测记录')
          .fontSize(DesignConstants.FONT_SIZE_LG)
          .fontColor($r('sys.color.font_secondary'))
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  // 顶部固定栏（统计信息 + 操作按钮）
  @Builder
  HeaderBar() {
    Row() {
      // 左侧：根据模式显示不同内容
      if (this.isInAnyMode) {
        Row({ space: 8 }) {
          // 关闭按钮
          Button() {
            Image($r('app.media.ic_close'))
              .width(20)
              .height(20)
              .fillColor($r('sys.color.font_secondary'))
          }
          .type(ButtonType.Circle)
          .backgroundColor(Color.Transparent)
          .width(32)
          .height(32)
          .onClick(() => {
            Throttle.click(() => {
              this.exitAllModes();
            });
          })
          
          // 模式名称和已选数量
          Column({ space: 2 }) {
            Text(this.currentModeName)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
            Text(`已选 ${this.selectedIdSet.size} 项`)
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.brand'))
          }
          .alignItems(HorizontalAlign.Start)
        }
      } else {
        Text(`共 ${this.totalRecords} 条记录`)
          .fontSize(DesignConstants.FONT_SIZE_MD)
          .fontColor($r('sys.color.font_secondary'))
      }
      
      Blank()
      
      // 筛选按钮
      Button() {
        Image($r('app.media.ic_filter'))
          .width(20)
          .height(20)
          .fillColor(this.currentFilters.isActive ? $r('sys.color.brand') : $r('sys.color.font_secondary'))
      }
      .width(36)
      .height(36)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.openFilterDialog();
      })
      
      // 更多菜单按钮
      Button() {
        Image($r('app.media.ic_menus_more'))
          .width(20)
          .height(20)
          .fillColor($r('sys.color.font_secondary'))
      }
      .width(36)
      .height(36)
      .backgroundColor(Color.Transparent)
      .bindMenu(this.showMenu, this.MenuBuilder, {
        placement: Placement.BottomRight,
        enableHoverMode: true,
        onDisappear: () => {
          this.showMenu = false;
        }
      })
      .onClick(() => {
        this.showMenu = true;
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('sys.color.background_secondary'))
  }

  /**
   * 列表布局视图
   */
  @Builder
  ListLayoutView() {
    Column() {
      // 顶部固定栏
      this.HeaderBar()

      // 可滚动列表区域
      Scroll() {
        Column({ space: 16 }) {
          GridRow({
            columns: {
              xs: 1,
              sm: 1,
              md: 2,
              lg: 2,
              xl: 3,
              xxl: 3
            },
            breakpoints: { reference: BreakpointsReference.WindowSize },
            gutter: 16
          }) {
            // 使用 ForEach 代替 LazyForEach，避免复用导致的选中状态问题
            ForEach(this.records, (record: DecibelRecord) => {
              GridCol({ span: 1 }) {
                this.RecordItem(record)
              }.animation({
                duration: 300,
                curve: Curve.EaseOut
              })
            }, (record: DecibelRecord) => record.id)
          }

          // 加载更多指示器
          if (this.hasMoreData) {
            this.LoadMoreIndicator()
          } else if (this.totalRecords > 0) {
            Text('已加载全部记录')
              .fontSize(DesignConstants.FONT_SIZE_SM)
              .fontColor($r('sys.color.font_secondary'))
              .textAlign(TextAlign.Center)
              .alignSelf(ItemAlign.Center)
              .margin({ top: 16 })
          }
        }.margin({ left: 16, right: 16, top: 8 })
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .layoutWeight(1)
      .align(Alignment.Top)
      .onScrollEdge((side: Edge) => {
        if (side === Edge.Bottom && this.hasMoreData && !this.isLoadingMore) {
          this.loadMoreRecords();
        }
      })
      
      // 底部批量操作栏（仅在操作模式显示）
      if (this.isInAnyMode) {
        this.BatchActionBar()
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 底部批量操作栏
   */
  @Builder
  BatchActionBar() {
    Column() {
      // 分割线
      Divider()
        .color($r('sys.color.comp_divider'))
        .height(1)
      
      Row() {
        // 左下角：提示文字
        if (this.shouChangMode) {
          Text('选择要收藏的记录')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        } else if (this.deleteRecordMode) {
          Text('选择要删除的记录')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        } else if (this.deleteAudioMode) {
          Text('选择要删除音频的记录')
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor($r('sys.color.font_secondary'))
        }
        
        Blank()
        
        // 右下角：确认操作选中的按钮
        if (this.shouChangMode) {
          // 有已收藏的记录：显示取消收藏按钮
          if (this.getSelectedFavoriteStats()[0] > 0) {
            Button(`取消收藏(${this.selectedIdSet.size})`)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor('#FF4081')
              .backgroundColor('#FFE0EB')
              .height(40)
              .padding({ left: 16, right: 16 })
              .borderRadius(20)
              .margin({ right: 8 })
              .onClick(() => {
                Throttle.click(() => {
                  this.batchUnfavoriteRecords();
                });
              })
          }
          
          // 有未收藏的记录：显示确认收藏按钮
          if (this.getSelectedFavoriteStats()[1] > 0) {
            Button(`确认收藏(${this.selectedIdSet.size})`)
              .fontSize(DesignConstants.FONT_SIZE_MD)
              .fontColor(Color.White)
              .backgroundColor('#FF4081')
              .height(40)
              .padding({ left: 16, right: 16 })
              .borderRadius(20)
              .onClick(() => {
                Throttle.click(() => {
                  this.batchFavoriteRecords();
                });
              })
          }
        } else if (this.deleteRecordMode) {
          Button(`删除记录(${this.selectedIdSet.size})`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor(Color.White)
            .backgroundColor($r('sys.color.alert'))
            .height(40)
            .padding({ left: 20, right: 20 })
            .borderRadius(20)
            .enabled(this.selectedIdSet.size > 0)
            .onClick(() => {
              Throttle.click(() => {
                this.batchDeleteRecords();
              });
            })
        } else if (this.deleteAudioMode) {
          Button(`删除音频(${this.selectedIdSet.size})`)
            .fontSize(DesignConstants.FONT_SIZE_MD)
            .fontColor(Color.White)
            .backgroundColor($r('sys.color.warning'))
            .height(40)
            .padding({ left: 20, right: 20 })
            .borderRadius(20)
            .enabled(this.selectedIdSet.size > 0)
            .onClick(() => {
              Throttle.click(() => {
                this.batchDeleteAudios();
              });
            })
        }
      }
      .width('100%')
      .height(64)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('sys.color.comp_background_primary'))
    }
    .width('100%')
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: -2
    })
  }

  /**
   * 加载更多指示器
   */
  @Builder
  LoadMoreIndicator() {
    Column() {
      if (this.isLoadingMore) {
        LoadingProgress()
          .enableLoading(true)
          .width(32)
          .height(32)
          .color($r('sys.color.font_primary'))
        Text('正在加载更多记录...')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
          .margin({ top: 8 })
      } else {
        Text('滚动加载更多记录')
          .fontSize(DesignConstants.FONT_SIZE_SM)
          .fontColor($r('sys.color.font_secondary'))
      }
    }
    .width('100%')
    .height(80)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ top: 16 })
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 内容区域
      if (this.records.length == 0) {
        this.EmptyStateView()
      } else {
        this.ListLayoutView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.background_secondary'))
  }
}

// 历史记录复选框子组件（独立管理自身状态）
@Component
struct HistoryRecordCheckbox {
  @Prop recordId: string = '';
  @Prop isChecked: boolean = false;
  onToggle: (id: string) => void = () => {};
  
  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 未选中状态：空心圆圈
      Circle()
        .width(20)
        .height(20)
        .fill(Color.Transparent)
        .stroke($r('sys.color.font_tertiary'))
        .strokeWidth(2)
        .visibility(this.isChecked ? Visibility.Hidden : Visibility.Visible)
      
      // 选中状态：实心圆
      Circle()
        .width(20)
        .height(20)
        .fill($r('sys.color.brand'))
        .visibility(this.isChecked ? Visibility.Visible : Visibility.Hidden)
      
      // 对勾图标
      Text('✓')
        .fontSize(14)
        .fontColor(Color.White)
        .visibility(this.isChecked ? Visibility.Visible : Visibility.Hidden)
    }
    .width(32)
    .height(32)
    .onClick(() => {
      this.onToggle(this.recordId);
    })
  }
}

// 筛选面板Builder
interface FilterPanelParams {
  filterConfig: FilterConfig;
  onApply: (filters: FilterConfig) => void;
  onReset: () => void;
}

@Builder
function FilterPanelBuilder(params: FilterPanelParams) {
  FilterPanel({
    filterConfig: params.filterConfig,
    onApplyFilters: (filters: FilterConfig) => {
      params.onApply(filters);
    },
    onResetFilters: () => {
      params.onReset();
    }
  })
}
