import { LocationState } from '../constants/LocationStateEnum';
import { LocationService } from './LocationService';
import { PreferenceService } from './PreferenceService';
import { PreferenceKeyConstants } from '../constants/PreferenceKeyConstants';
import common from '@ohos.app.ability.common';
import promptAction from '@ohos.promptAction';

/**
 * 位置状态机
 */
export class LocationStateMachine {
  private static instance: LocationStateMachine;
  private locationService: LocationService = LocationService.getInstance();
  private preferenceService: PreferenceService = PreferenceService.getInstance();
  private currentState: LocationState = LocationState.DISABLED;
  private stateChangeCallbacks: ((state: LocationState) => void)[] = [];

  private constructor() {}

  public static getInstance(): LocationStateMachine {
    if (!LocationStateMachine.instance) {
      LocationStateMachine.instance = new LocationStateMachine();
    }
    return LocationStateMachine.instance;
  }

  public async init(context: common.Context): Promise<void> {
    await this.locationService.init(context);
    // 初始化时检查系统定位服务和权限状态
    const isServiceEnabled = this.locationService.checkLocationEnabled();
    const hasPermission = await this.locationService.requestLocationPermission();
    const enabled = this.preferenceService.isEnabled(PreferenceKeyConstants.LOCATION);
    
    // 只有当系统定位服务开启、有权限且用户偏好设置为开启时，才设置为启用状态
    if (isServiceEnabled && hasPermission && enabled) {
      this.setState(LocationState.ENABLED);
    } else {
      // 否则设置为禁用状态，并确保偏好设置也为关闭
      this.setState(LocationState.DISABLED);
    }
  }

  public getState(): LocationState {
    return this.currentState;
  }

  public isEnabled(): boolean {
    return this.currentState === LocationState.ENABLED || this.currentState === LocationState.LOCATING;
  }

  public async toggle(): Promise<void> {
    if (this.isEnabled()) {
      await this.disable();
    } else {
      await this.enable();
    }
  }

  private async enable(): Promise<void> {
    try {
      const state = await this.checkLocationRequirements();
      this.setState(state);
    } catch (error) {
      console.error('启用位置失败:', error);
      this.setState(LocationState.FAILED);
    }
  }

  private async checkLocationRequirements(): Promise<LocationState> {
    // 检查定位服务
    const isServiceEnabled = this.locationService.checkLocationEnabled();
    if (!isServiceEnabled) {
      // 显示设置对话框
      const shouldOpenSettings = await this.showLocationServiceDialog();
      if (!shouldOpenSettings) {
        return LocationState.SERVICE_DISABLED;
      }
      // 用户同意去设置后，再次检查服务状态
      if (!this.locationService.checkLocationEnabled()) {
        return LocationState.SERVICE_DISABLED;
      }
    }

    // 检查定位权限
    const hasPermission = await this.locationService.requestLocationPermission();
    if (!hasPermission) {
      return LocationState.NO_PERMISSION;
    }

    return LocationState.ENABLED;
  }

  private setState(state: LocationState): void {
    const oldState = this.currentState;
    this.currentState = state;
    
    // 只有状态真正改变时才更新偏好设置和通知监听器
    if (oldState !== state) {
      const enabled = state === LocationState.ENABLED || state === LocationState.LOCATING;
      this.preferenceService.setEnabled(PreferenceKeyConstants.LOCATION, enabled);
      this.notifyStateChange(state);
    }
  }

  private notifyStateChange(state: LocationState): void {
    this.stateChangeCallbacks.forEach(callback => callback(state));
  }

  public onStateChange(callback: (state: LocationState) => void): void {
    this.stateChangeCallbacks.push(callback);
  }

  public offStateChange(callback: (state: LocationState) => void): void {
    const index = this.stateChangeCallbacks.indexOf(callback);
    if (index > -1) {
      this.stateChangeCallbacks.splice(index, 1);
    }
  }

  private async showLocationServiceDialog(): Promise<boolean> {
    const result = await promptAction.showDialog({
      title: '定位服务未开启',
      message: '请在系统设置中开启定位服务，以便获取位置信息',
      buttons: [
        {
          text: '取消',
          color: '#666666'
        },
        {
          text: '去设置',
          color: '#0091FF'
        }
      ]
    });
    return result.index === 1;
  }

  private async disable(): Promise<void> {
    this.locationService.stopLocation();
    this.setState(LocationState.DISABLED);
  }

  public async startLocating(): Promise<void> {
    if (!this.isEnabled()) {
      return;
    }
    this.setState(LocationState.LOCATING);
  }

  public async finishLocating(): Promise<void> {
    this.setState(LocationState.ENABLED);
  }

  public async failLocating(): Promise<void> {
    this.setState(LocationState.FAILED);
  }

  public destroy(): void {
    this.stateChangeCallbacks = [];
    this.locationService.stopLocation();
  }
} 