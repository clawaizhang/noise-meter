/**
 * 颜色映射并行生成器
 * 预计算颜色映射表，避免每帧重复计算HSL转换
 */

/**
 * 并行生成颜色映射表
 * @param colorMapType 颜色映射类型
 * @param minDb 最小分贝值
 * @param maxDb 最大分贝值
 * @param opacity 透明度
 */
@Concurrent
export function concurrentGenerateColorMap(
  colorMapType: string,
  minDb: number,
  maxDb: number,
  opacity: number
): string[] {
  const colors: string[] = new Array(256);
  
  for (let i = 0; i < 256; i++) {
    const normalized = i / 255;
    
    // 根据归一化值计算颜色
    let color: string;
    switch (colorMapType) {
      case 'heat':
        // 计算热力图颜色
        let r: number, g: number, b: number;
        if (normalized < 0.25) {
          r = 0;
          g = Math.floor(normalized * 4 * 255);
          b = 255;
        } else if (normalized < 0.5) {
          r = 0;
          g = 255;
          b = Math.floor((1 - (normalized - 0.25) * 4) * 255);
        } else if (normalized < 0.75) {
          r = Math.floor((normalized - 0.5) * 4 * 255);
          g = 255;
          b = 0;
        } else {
          r = 255;
          g = Math.floor((1 - (normalized - 0.75) * 4) * 255);
          b = 0;
        }
        color = `rgba(${r}, ${g}, ${b}, ${opacity})`;
        break;
      case 'rainbow':
        // 计算彩虹色
        const hue = (1 - normalized) * 360;
        const h = hue / 360;
        
        // 优化的HSL转RGB函数（彩虹色饱和度总是1，所以不需要检查s === 0）
        const hue2rgb = (p: number, q: number, t: number) => {
          if (t < 0) t += 1;
          if (t > 1) t -= 1;
          if (t < 1/6) return p + (q - p) * 6 * t;
          if (t < 1/2) return q;
          if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
          return p;
        };

        const s = 1;
        const l = 0.5;
        const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        const p = 2 * l - q;
        const rr = hue2rgb(p, q, h + 1/3);
        const gg = hue2rgb(p, q, h);
        const bb = hue2rgb(p, q, h - 1/3);
        
        color = `rgba(${Math.round(rr * 255)}, ${Math.round(gg * 255)}, ${Math.round(bb * 255)}, ${opacity})`;
        break;
      case 'grayscale':
      default:
        // 计算灰度颜色
        const intensity = Math.floor(normalized * 255);
        color = `rgba(${intensity}, ${intensity}, ${intensity}, ${opacity})`;
        break;
    }
    
    colors[i] = color;
  }
  
  return colors;
}
