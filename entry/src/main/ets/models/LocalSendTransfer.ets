export enum TransferStatus {
  PENDING = 'pending',
  QUEUED = 'queued',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}

export enum TransferDirection {
  SEND = 'send',
  RECEIVE = 'receive'
}

export interface LocalSendTransfer {
  id: string;
  fileId: string;
  fileName: string;
  fileSize: number;
  deviceId: string;
  deviceName: string;
  direction: TransferDirection;
  status: TransferStatus;
  progress: number;
  startTime: number;
  endTime?: number;
  speed?: number;
  errorMessage?: string;
  fileType: string;
}

export interface TransferStats {
  totalTransfers: number;
  successfulTransfers: number;
  failedTransfers: number;
  totalBytesSent: number;
  totalBytesReceived: number;
  averageSpeed: number;
}