# DecibelMeter 重构实施指南

## 阶段一：音频逻辑独立化重构

### 1. 创建 AudioController 组件

#### 文件位置
`entry/src/main/ets/components/decibel-meter/AudioController.ets`

#### 核心职责
- 音频采集启动/停止控制
- 音频数据处理和分发
- 录音时长监控
- 错误处理和重试机制

#### 关键代码结构
```typescript
@ComponentV2
export struct AudioController {
  // 音频状态
  @Local private isRecording: boolean = false
  @Local private recordingTime: number = 0
  @Local private startTime: number = 0
  
  // 错误状态（支持多个错误同时显示）
  @Local private errorMessages: string[] = []
  
  // 服务实例
  private audioService: AudioService
  private recordService: DecibelRecordService
  
  // 事件发射器
  @Event onAudioBuffer: (buffer: ArrayBuffer) => void
  @Event onSpectrumData: (spectrum: Float32Array) => void
  @Event onError: (errors: string[]) => void
  @Event onRecordingStateChange: (isRecording: boolean) => void
  
  // 核心方法
  async startRecording(): Promise<void>
  async stopRecording(comments: string): Promise<void>
  private startDurationMonitoring(): void
  private addErrorMessage(message: string): void
  private clearErrorMessage(type: string): void
}
```

### 2. 重构 DecibelMeter 主组件

#### 主要变更
- 移除音频相关逻辑到 AudioController
- 简化状态管理
- 添加错误消息队列显示

#### 新的构建方法
```typescript
build() {
  Stack() {
    GridRow({ columns: 12, breakpoints: { reference: BreakpointsReference.WindowSize }, gutter: 16 }) {
      
      // 错误消息显示区域（支持多个错误）
      GridCol({ span: { xs: 12 } }) {
        this.errorMessagesDisplay()
      }
      
      // 音频控制器
      GridCol({ span: { xs: 12, md: 5 } }) {
        AudioController({
          onAudioBuffer: (buffer) => { this.currentAudioBuffer = buffer },
          onSpectrumData: (spectrum) => { this.currentSpectrum = spectrum },
          onError: (errors) => { this.errorMessages = errors },
          onRecordingStateChange: (isRecording) => { this.isRecording = isRecording }
        })
      }
      
      // 分贝显示组件
      GridCol({ span: { xs: 12, md: 5 } }) {
        DecibelDisplayComponent({
          audioBuffer: this.currentAudioBuffer,
          // ... 其他参数保持不变
        })
      }
      
      // 频谱图组件
      GridCol({ span: { xs: 12, md: 5 } }) {
        SpectrumChartComponent({
          spectrumData: this.currentSpectrum,
          // ... 其他参数保持不变
        })
      }
    }
  }
}
```

### 3. 错误处理系统设计

#### 错误类型分类
```typescript
enum ErrorType {
  AUDIO_PERMISSION = "audio_permission",
  AUDIO_DEVICE = "audio_device",
  LOCATION_PERMISSION = "location_permission",
  STORAGE = "storage",
  NETWORK = "network"
}
```

#### 错误消息队列管理
- 每个错误类型独立存储
- 支持同时显示多个错误
- 错误恢复时自动清除对应错误
- 优先级排序显示

### 4. 实施步骤

#### 第一步：创建 AudioController
1. 新建 `AudioController.ets` 文件
2. 迁移音频启动逻辑（第67-104行）
3. 迁移音频处理逻辑（第160-214行）
4. 迁移录音时长监控（第228-271行）
5. 迁移停止录音逻辑（第273-360行）

#### 第二步：重构 DecibelMeter
1. 移除音频相关状态变量
2. 添加错误消息状态管理
3. 集成 AudioController 组件
4. 更新构建方法

#### 第三步：测试验证
1. 测试音频采集功能
2. 测试错误处理机制
3. 测试多错误同时显示
4. 验证性能改进

### 5. 预期改进

#### 代码质量
- DecibelMeter 代码行数减少约40%
- 组件职责更清晰
- 可维护性显著提升

#### 用户体验
- 错误信息更清晰，不会相互覆盖
- 音频处理更稳定
- 响应速度提升

### 6. 后续优化建议

完成阶段一后，可考虑：
- 进一步优化响应式布局
- 添加基础动画效果
- 完善权限管理流程