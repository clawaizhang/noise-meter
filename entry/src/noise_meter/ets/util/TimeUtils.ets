export function secondsToHoursMinutesSeconds(seconds: number): string {
  const hours: number = Math.floor(seconds / 3600);
  const minutes: number = Math.floor((seconds % 3600) / 60);
  const remainingSeconds: number = seconds % 60;

  let result: string = '';
  if (hours > 0) {
    result += `${hours}时`;
  }
  if (minutes > 0 || hours > 0) {
    result += `${minutes}分`;
  }
  result += `${remainingSeconds}秒`;

  return result;
}

export function secondsToHoursMinutesSecondsWithDecimal(milliseconds: number): string {
  const totalSeconds = milliseconds / 1000;
  const hours: number = Math.floor(totalSeconds / 3600);
  const minutes: number = Math.floor((totalSeconds % 3600) / 60);
  const remainingSeconds: number = totalSeconds % 60;
  const decimalPart: number = Math.floor((remainingSeconds % 1) * 10);

  // 使用固定宽度格式：HH:MM:SS.s
  const pad = (num: number, size: number) => String(num).padStart(size, '0');
  
  let result = '';
  if (hours > 0) {
    result += `${pad(hours, 2)}:`;
  }
  result += `${pad(minutes, 2)}:`;
  result += `${pad(Math.floor(remainingSeconds), 2)}.`;
  result += `${decimalPart}`;

  return result;
}


export function formatStartTime(startTime: number) {
  return new Date(startTime).toLocaleTimeString('zh-CN', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false
  });
}
