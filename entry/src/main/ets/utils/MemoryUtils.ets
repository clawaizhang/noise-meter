export function formatMemory(kb: bigint): string {
  const GB = 1024 * 1024; // 1GB = 1024MB = 1024*1024KB
  const MB = 1024;
  
  if (kb >= GB) {
    return `${(Number(kb)/GB).toFixed(2)} GB`;
  } else if (kb >= MB) {
    return `${(Number(kb)/MB).toFixed(2)} MB`;
  }
  return `${kb} KB`;
}