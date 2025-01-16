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
