/**
 * 数组转换工具类
 * 用于解决HarmonyOS taskpool序列化问题
 */
export class ArrayConversionUtils {
  
  /**
   * 将Float32Array转换为普通数组
   */
  public static float32ArrayToArray(floatArray: Float32Array): number[] {
    const result: number[] = new Array(floatArray.length);
    for (let i = 0; i < floatArray.length; i++) {
      result[i] = floatArray[i];
    }
    return result;
  }
  
  /**
   * 将Float32Array数组转换为普通二维数组
   */
  public static float32ArrayArrayTo2DArray(floatArrays: Float32Array[]): number[][] {
    const result: number[][] = new Array(floatArrays.length);
    for (let i = 0; i < floatArrays.length; i++) {
      result[i] = ArrayConversionUtils.float32ArrayToArray(floatArrays[i]);
    }
    return result;
  }
  
  /**
   * 将普通数组转换为Float32Array
   */
  public static arrayToFloat32Array(array: number[]): Float32Array {
    return new Float32Array(array);
  }
  
  /**
   * 将普通二维数组转换为Float32Array数组
   */
  public static array2DToFloat32ArrayArray(array2D: number[][]): Float32Array[] {
    const result: Float32Array[] = new Array(array2D.length);
    for (let i = 0; i < array2D.length; i++) {
      result[i] = ArrayConversionUtils.arrayToFloat32Array(array2D[i]);
    }
    return result;
  }
}