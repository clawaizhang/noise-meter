/**
 * UUID生成器工具
 */

/**
 * 生成UUID v4
 */
export function generateUUID(): string {
  const chars = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';
  let result = '';
  for (let i = 0; i < chars.length; i++) {
    const c = chars.charAt(i);
    if (c === 'x') {
      const r = Math.random() * 16 | 0;
      result += r.toString(16);
    } else if (c === 'y') {
      const r = (Math.random() * 16 | 0) & 0x3 | 0x8;
      result += r.toString(16);
    } else {
      result += c;
    }
  }
  return result;
}

/**
 * 生成短ID（用于简单的唯一标识）
 */
export function generateShortId(length: number = 8): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    const index = Math.floor(Math.random() * chars.length);
    result += chars.charAt(index);
  }
  return result;
}

/**
 * 生成时间戳ID
 */
export function generateTimestampId(): string {
  return Date.now().toString(36) + '-' + generateShortId(4);
}
