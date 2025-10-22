import { StateTransitionEvent } from "./AudioControllerLifecycleState";

/**
 * AudioController事件类型枚举
 */
export enum AudioControllerEventType {
  START_RECORDING = 'START_RECORDING',
  STOP_RECORDING = 'STOP_RECORDING',
  PAUSE_RECORDING = 'PAUSE_RECORDING',
  RESET_DATA = 'RESET_DATA',
  STATE_CHANGE = 'STATE_CHANGE'
}

/**
 * 基础事件接口
 */
export interface AudioControllerEvent {
  type: AudioControllerEventType;
  timestamp: number;
  payload?: StopRecordingPayload | StateTransitionEvent;
}

/**
 * 启动录制事件
 */
export interface StartRecordingEvent extends AudioControllerEvent {
  type: AudioControllerEventType.START_RECORDING;
}

/**
 * 停止录制事件payload接口
 */
export interface StopRecordingPayload {
  comments: string;
}

/**
 * 停止录制事件
 */
export interface StopRecordingEvent extends AudioControllerEvent {
  type: AudioControllerEventType.STOP_RECORDING;
  payload: StopRecordingPayload;
}

/**
 * 暂停录制事件
 */
export interface PauseRecordingEvent extends AudioControllerEvent {
  type: AudioControllerEventType.PAUSE_RECORDING;
}

/**
 * 重置数据事件
 */
export interface ResetDataEvent extends AudioControllerEvent {
  type: AudioControllerEventType.RESET_DATA;
}

/**
 * 状态变更事件
 */
export interface StateChangeEvent extends AudioControllerEvent {
  type: AudioControllerEventType.STATE_CHANGE;
  payload: StateTransitionEvent;
}

/**
 * 事件发布器接口
 */
export interface AudioControllerEventPublisher {
  publishEvent:(event: AudioControllerEvent)=> void;
  onEvent:(callback: (event: AudioControllerEvent) => void)=> void;
}