export enum DeviceStatus {
  ONLINE = 'online',
  OFFLINE = 'offline',
  CONNECTING = 'connecting',
  TRANSFERRING = 'transferring'
}

export enum DeviceType {
  PHONE = 'phone',
  TABLET = 'tablet',
  COMPUTER = 'computer',
  OTHER = 'other'
}

export interface LocalSendDevice {
  id: string;
  name: string;
  ipAddress: string;
  macAddress?: string;
  deviceType: DeviceType;
  status: DeviceStatus;
  lastSeen: number;
  isCurrentDevice: boolean;
  osVersion?: string;
  deviceModel?: string;
  port?: number;
}