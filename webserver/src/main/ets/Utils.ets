/**
 * @fileName : Utils.ets
 * @author : @cxy
 * @date : 2025/8/15
 * @description : 工具类
 */

import { util } from "@kit.ArkTS";

/**
 * 常见文件扩展名与MIME类型映射表
 */
const MimeTypes: Record<string, string> = {
  'html': 'text/html',
  'htm': 'text/html',
  'css': 'text/css',
  'js': 'application/javascript',
  'json': 'application/json',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'gif': 'image/gif',
  'svg': 'image/svg+xml',
  'webp': 'image/webp',
  'mp4': 'video/mp4',
  'txt': 'text/plain',
  'pdf': 'application/pdf',
  'zip': 'application/zip',
};

/**
 * 通用工具类
 * 提供字符串转换、文件处理、路径操作等实用方法
 */
export class Utils {
  /**
   * 将ArrayBuffer转换为字符串
   * @param arr ArrayBuffer数据
   * @returns 转换后的字符串
   */
  static arrayBufferToStr(arr: ArrayBuffer): string {
    const uint8Array = new Uint8Array(arr)
    return Utils.uint8ToStr(uint8Array)
  }

  /**
   * 将Uint8Array转换为字符串
   * @param arr Uint8Array数据
   * @returns 转换后的字符串
   */
  static uint8ToStr(arr: Uint8Array): string {
    return util.TextDecoder.create().decodeToString(arr)
  }

  /**
   * 将字符串转换为Uint8Array
   * @param str 输入字符串
   * @returns 转换后的Uint8Array
   */
  static strToUint8Array(str: string): Uint8Array {
    return util.TextEncoder.create().encodeInto(str)
  }

  /**
   * 将字符串转换为ArrayBuffer
   * @param str 输入字符串
   * @returns 转换后的ArrayBuffer
   */
  static strToArrayBuffer(str: string): ArrayBuffer {
    return Utils.strToUint8Array(str).buffer
  }

  /**
   * 合并两个ArrayBuffer
   * @param buffer1 第一个缓冲区
   * @param buffer2 第二个缓冲区
   * @returns 合并后的ArrayBuffer
   */
  static mergeArrayBuffers(buffer1: ArrayBuffer, buffer2: ArrayBuffer): ArrayBuffer {
    const merged = new ArrayBuffer(buffer1.byteLength + buffer2.byteLength);
    const mergedView = new Uint8Array(merged);
    mergedView.set(new Uint8Array(buffer1), 0);
    mergedView.set(new Uint8Array(buffer2), buffer1.byteLength);
    return merged;
  }

  /**
   * 根据文件路径获取MIME类型
   * @param filePath 文件路径
   * @returns MIME类型字符串
   */
  static getMimeType(filePath: string): string {
    const extension = filePath.split('.').pop()?.toLowerCase() || '';
    return MimeTypes[extension] || 'application/octet-stream';
  }

  /**
   * 规范化文件路径（类似Node.js的path.normalize）
   * @param path 待规范化的路径
   * @returns 规范化后的路径
   */
  static normalizePath(path: string): string {
    if (!path) {
      return path;
    }

    // 统一路径分隔符为'/'
    let normalized = path.replace(/\\/g, '/');

    // 分割路径为数组（过滤空字符串）
    const segments = normalized.split('/').filter(segment => segment !== '');
    const result: string[] = [];

    for (const segment of segments) {
      if (segment === '.') {
        // 忽略当前目录
        continue;
      } else if (segment === '..') {
        // 处理上级目录（若有可回退的路径）
        if (result.length > 0) {
          result.pop();
        }
      } else {
        // 普通路径片段
        result.push(segment);
      }
    }

    // 拼接结果（若为绝对路径，保留开头的'/'）
    const isAbsolute = path.startsWith('/') || path.startsWith('\\');
    return (isAbsolute ? '/' : '') + result.join('/');
  }

  /**
   * 拼接多个路径片段（类似Node.js的path.join）
   * @param paths 路径片段列表（如['/a/b', 'c', 'index.html']）
   * @returns 拼接后的完整路径
   */
  static joinPath(...paths: string[]): string {
    if (paths.length === 0) {
      return '';
    }

    // 统一路径分隔符为'/'，并分割为片段
    let allSegments: string[] = [];
    for (const path of paths) {
      if (!path) {
        continue;
      } // 跳过空字符串
      // 将路径按'/'或'\\'分割，并过滤空片段
      const segments = path.replace(/\\/g, '/').split('/').filter(s => s !== '');
      allSegments.push(...segments);
    }

    // 处理绝对路径（若存在绝对路径片段，前面的相对路径会被忽略）
    let isAbsolute = false;
    const resultSegments: string[] = [];
    for (const segment of allSegments) {
      // 鸿蒙中绝对路径通常以'/'开头（如'/data/data/'）或协议开头（如'internal://cache/'）
      if (segment === '' && resultSegments.length === 0) {
        // 处理以'/'开头的绝对路径（如第一个片段是''，来自'/a/b'分割后的结果）
        isAbsolute = true;
        continue;
      }
      resultSegments.push(segment);
    }

    // 拼接结果（绝对路径前加'/'，相对路径直接拼接）
    const joined = resultSegments.join('/');
    return isAbsolute ? `/${joined}` : joined;
  }

  /**
   * 清理文件名，移除非法字符
   * @param filename 原始文件名
   * @returns 清理后的安全文件名
   */
  static sanitizeFilename(filename: string): string {
    // 移除路径遍历字符和其它非法字符
    // 只允许字母、数字、下划线、连字符、点
    return filename.replace(/[^a-zA-Z0-9_.-]/g, '');
  }
}