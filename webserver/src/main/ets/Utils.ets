/**
 * @fileName : Utils.ets
 * @author : @cxy
 * @date : 2025/8/15
 * @description : 工具类
 */

import { util } from "@kit.ArkTS";

export class Utils {
  static arrayBufferToStr(arr: ArrayBuffer, encoding: 'utf-8' | 'binary' = 'utf-8'): string {
    const uint8Array = new Uint8Array(arr)
    if (encoding === 'binary') {
      let binaryString = '';
      for (let i = 0; i < uint8Array.length; i++) {
        binaryString += String.fromCharCode(uint8Array[i]);
      }
      return binaryString;
    } else {
      return Utils.uint8ToStr(uint8Array)
    }
  }

  static uint8ToStr(arr: Uint8Array): string {
    return util.TextDecoder.create().decodeToString(arr)
  }

  static strToUint8Array(str: string): Uint8Array {
    return util.TextEncoder.create().encodeInto(str)
  }

  static strToArrayBuffer(str: string, encoding: 'utf-8' | 'binary' = 'utf-8'): ArrayBuffer {
    if (encoding === 'binary') {
      const buf = new ArrayBuffer(str.length);
      const bufView = new Uint8Array(buf);
      for (let i = 0, strLen = str.length; i < strLen; i++) {
        bufView[i] = str.charCodeAt(i);
      }
      return buf;
    } else {
      return Utils.strToUint8Array(str).buffer
    }
  }

  // 工具方法：合并ArrayBuffer
  static mergeArrayBuffers(buffer1: ArrayBuffer, buffer2: ArrayBuffer): ArrayBuffer {
    const merged = new ArrayBuffer(buffer1.byteLength + buffer2.byteLength);
    const mergedView = new Uint8Array(merged);
    mergedView.set(new Uint8Array(buffer1), 0);
    mergedView.set(new Uint8Array(buffer2), buffer1.byteLength);
    return merged;
  }

  static getMimeType(filePath: string): string {
    const extension = filePath.split('.').pop()?.toLowerCase() || '';
    const mimeTypes: Record<string, string> = {
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
    return mimeTypes[extension] || 'application/octet-stream';
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
}