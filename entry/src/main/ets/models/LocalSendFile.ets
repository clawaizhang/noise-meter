export enum FileType {
  IMAGE = 'image',
  VIDEO = 'video',
  AUDIO = 'audio',
  DOCUMENT = 'document',
  ARCHIVE = 'archive',
  OTHER = 'other'
}

export interface LocalSendFile {
  id: string;
  name: string;
  path: string;
  size: number;
  type: FileType;
  mimeType: string;
  lastModified: number;
  uri: string;
  thumbnail?: string;
}

export interface FileTransfer {
  file: LocalSendFile;
  targetDeviceId: string;
  progress: number;
  status: string;
  startTime: number;
  endTime?: number;
  error?: string;
}