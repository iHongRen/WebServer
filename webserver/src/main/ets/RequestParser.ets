/**
 * @fileName : RequestParser.ets
 * @author : @cxy
 * @date : 2025/4/11
 * @description : 高性能HTTP请求解析器
 * https://github.com/iHongRen/WebServer
 */

import { Utils } from './Utils';

/**
 * 解析结果接口
 */
export interface ParsedRequest {
  method: string;
  path: string;
  version: string;
  url: string;
  headers: Map<string, string>;
  body: ArrayBuffer;
  isComplete: boolean;
  contentLength: number;
  isChunked: boolean;
}

/**
 * 高性能HTTP请求解析器
 * 优化解析速度和内存使用
 */
export class RequestParser {
  private static readonly CRLF = '\r\n';
  private static readonly HEADER_END = '\r\n\r\n';

  /**
   * 快速检查请求是否完整
   * 优化：使用字节级别检查，避免字符串转换
   */
  public static isComplete(buffer: ArrayBuffer): boolean {
    const view = new Uint8Array(buffer);
    const len = view.length;

    // 查找 \r\n\r\n (0x0D 0x0A 0x0D 0x0A)
    let headerEnd = -1;
    for (let i = 0; i < len - 3; i++) {
      if (view[i] === 0x0D && view[i + 1] === 0x0A &&
        view[i + 2] === 0x0D && view[i + 3] === 0x0A) {
        headerEnd = i;
        break;
      }
    }

    if (headerEnd === -1) {
      return false;
    }

    // 快速提取 Content-Length 和 Transfer-Encoding
    const headerBytes = view.slice(0, headerEnd);
    const contentLength = RequestParser.extractContentLength(headerBytes);
    const isChunked = RequestParser.isChunkedEncoding(headerBytes);

    if (isChunked) {
      // 检查分块结束标记
      return RequestParser.hasChunkEnd(view);
    }

    // 检查内容长度
    const headerLength = headerEnd + 4; // 包括 \r\n\r\n
    return buffer.byteLength >= headerLength + contentLength;
  }

  /**
   * 解析HTTP请求
   * 优化：减少字符串操作，提升解析速度
   */
  public static parse(buffer: ArrayBuffer): ParsedRequest {
    const bufferStr = Utils.arrayBufferToStr(buffer);
    const headerEndIndex = bufferStr.indexOf(RequestParser.HEADER_END);

    if (headerEndIndex === -1) {
      return RequestParser.createEmptyResult();
    }

    const headerStr = bufferStr.substring(0, headerEndIndex);
    const bodyData = buffer.slice(headerEndIndex + 4);

    const lines = headerStr.split(RequestParser.CRLF);
    const requestLine = lines[0];
    const parts = requestLine.split(' ');

    const method = parts[0];
    const fullPath = parts[1];
    const version = parts[2];

    // 解析路径和查询字符串
    const queryIndex = fullPath.indexOf('?');
    const path = queryIndex !== -1 ? fullPath.substring(0, queryIndex) : fullPath;

    // 解析请求头
    const headers = RequestParser.parseHeaders(lines.slice(1));

    // 检查传输编码
    const transferEncoding = headers.get('transfer-encoding');
    const isChunked = transferEncoding?.toLowerCase().includes('chunked') ?? false;

    // 获取内容长度
    const contentLengthStr = headers.get('content-length');
    const contentLength = contentLengthStr ? parseInt(contentLengthStr) : 0;

    const result: ParsedRequest = {
      method,
      path,
      version,
      url: fullPath,
      headers,
      body: bodyData,
      isComplete: true,
      contentLength,
      isChunked
    };
    return result;
  }

  /**
   * 快速解析请求头
   * 优化：使用 Map 提升查找性能
   */
  private static parseHeaders(lines: string[]): Map<string, string> {
    const headers = new Map<string, string>();

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (!line) {
        continue;
      }

      const colonIndex = line.indexOf(': ');
      if (colonIndex !== -1) {
        const name = line.substring(0, colonIndex).toLowerCase();
        const value = line.substring(colonIndex + 2);
        headers.set(name, value);
      }
    }

    return headers;
  }

  /**
   * 从字节数组中提取 Content-Length
   */
  private static extractContentLength(headerBytes: Uint8Array): number {
    const headerStr = Utils.uint8ToStr(headerBytes);
    const match = headerStr.match(/Content-Length:\s*(\d+)/i);
    return match ? parseInt(match[1]) : 0;
  }

  /**
   * 检查是否使用分块编码
   */
  private static isChunkedEncoding(headerBytes: Uint8Array): boolean {
    const headerStr = Utils.uint8ToStr(headerBytes);
    return /Transfer-Encoding:\s*chunked/i.test(headerStr);
  }

  /**
   * 检查是否有分块结束标记
   */
  private static hasChunkEnd(view: Uint8Array): boolean {
    const len = view.length;
    if (len < 5) {
      return false;
    }

    // 查找 "0\r\n\r\n"
    for (let i = len - 5; i >= 0; i--) {
      if (view[i] === 0x30 && // '0'
        view[i + 1] === 0x0D && // '\r'
        view[i + 2] === 0x0A && // '\n'
        view[i + 3] === 0x0D && // '\r'
        view[i + 4] === 0x0A) { // '\n'
        return true;
      }
    }

    return false;
  }

  /**
   * 创建空结果
   */
  private static createEmptyResult(): ParsedRequest {
    const result: ParsedRequest = {
      method: '',
      path: '',
      version: '',
      url: '',
      headers: new Map<string, string>(),
      body: new ArrayBuffer(0),
      isComplete: false,
      contentLength: 0,
      isChunked: false
    };
    return result;
  }
}
