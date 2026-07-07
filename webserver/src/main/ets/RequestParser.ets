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
 * parseHeaderOnly 返回结果接口
 */
export interface ParsedHeader {
  method: string;
  path: string;
  headers: Map<string, string>;
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
   * 查找 header 结束位置（\r\n\r\n 的起始字节偏移）
   * @returns header 结束处的偏移，找不到返回 -1
   */
  public static findHeaderEnd(buffer: ArrayBuffer): number {
    const view = new Uint8Array(buffer);
    const len = view.length;
    for (let i = 0; i < len - 3; i++) {
      if (view[i] === 0x0D && view[i + 1] === 0x0A &&
        view[i + 2] === 0x0D && view[i + 3] === 0x0A) {
        return i;
      }
    }
    return -1;
  }

  /**
   * 仅解析 header 部分（不解析 body），用于流式模式
   */
  public static parseHeaderOnly(buffer: ArrayBuffer): ParsedHeader {
    const view = new Uint8Array(buffer);
    const headerEndByte = RequestParser.findHeaderEnd(buffer);
    if (headerEndByte === -1) {
      const empty: ParsedHeader = { method: '', path: '', headers: new Map() };
      return empty;
    }

    // 按字节偏移切片，避免多字节字符导致偏移错位
    const headerBytes = view.slice(0, headerEndByte);
    const headerStr = Utils.uint8ToStr(headerBytes);
    const lines = headerStr.split(RequestParser.CRLF);
    const requestLine = lines[0] || '';
    const parts = requestLine.split(' ');
    const method = parts[0] || '';
    const fullPath = parts.length > 1 ? parts[1] : '/';
    const queryIndex = fullPath.indexOf('?');
    const path = queryIndex !== -1 ? fullPath.substring(0, queryIndex) : fullPath;
    const headers = RequestParser.parseHeaders(lines.slice(1));

    const result: ParsedHeader = { method, path, headers };
    return result;
  }

  /**
   * 检查 chunked body 片段是否包含结束标记 "0\r\n\r\n"
   */
  public static isChunkedComplete(buffer: ArrayBuffer): boolean {
    return RequestParser.hasChunkEnd(new Uint8Array(buffer));
  }

  /**
   * 解析HTTP请求
   * 优化：减少字符串操作，提升解析速度
   */
  public static parse(buffer: ArrayBuffer): ParsedRequest {
    const view = new Uint8Array(buffer);
    const headerEndByte = RequestParser.findHeaderEnd(buffer);

    if (headerEndByte === -1) {
      return RequestParser.createEmptyResult();
    }

    // 按字节偏移切片，避免多字节字符导致偏移错位
    const headerBytes = view.slice(0, headerEndByte);
    const headerStr = Utils.uint8ToStr(headerBytes);
    const bodyData = buffer.slice(headerEndByte + 4);

    const lines = headerStr.split(RequestParser.CRLF);
    const requestLine = lines[0] || '';
    const parts = requestLine.split(' ');

    const method = parts[0] || '';
    const fullPath = parts.length > 1 ? parts[1] : '/';
    const version = parts.length > 2 ? parts[2] : '';

    // 解析路径和查询字符串
    const queryIndex = fullPath.indexOf('?');
    const path = queryIndex !== -1 ? fullPath.substring(0, queryIndex) : fullPath;

    // 解析请求头
    const headers = RequestParser.parseHeaders(lines.slice(1));

    // 检查传输编码
    const transferEncoding = headers.get('transfer-encoding');
    const isChunked = transferEncoding?.toLowerCase().includes('chunked') ?? false;

    // 获取内容长度：使用 radix=10 并校验 NaN，防止 NaN 绕过大小限制比较
    const contentLengthStr = headers.get('content-length');
    const contentLength = contentLengthStr
      ? RequestParser.parseSafeInt(contentLengthStr, 0)
      : 0;

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
   * 安全解析整数：radix=10，非有限数返回 fallback
   */
  private static parseSafeInt(s: string, fallback: number): number {
    const n = parseInt(s, 10);
    return Number.isFinite(n) ? n : fallback;
  }

  /**
   * 快速解析请求头
   * 优化：使用 Map 提升查找性能
   * RFC 7230 §3.2.2：重复头用逗号合并
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
        const existing = headers.get(name);
        headers.set(name, existing ? `${existing}, ${value}` : value);
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
    return match ? RequestParser.parseSafeInt(match[1], 0) : 0;
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
   * 必须以 "0\r\n\r\n" 结尾，且 '0' 位于 chunk 起始位置（前面是 \r\n 或 buffer 起始），
   * 防止 chunk 数据中恰好出现 0x30 0x0D 0x0A 0x0D 0x0A 字节序列时误判
   */
  private static hasChunkEnd(view: Uint8Array): boolean {
    const len = view.length;
    if (len < 5) {
      return false;
    }
    // 末尾必须是 "0\r\n\r\n"
    if (view[len - 5] !== 0x30 ||
      view[len - 4] !== 0x0D ||
      view[len - 3] !== 0x0A ||
      view[len - 2] !== 0x0D ||
      view[len - 1] !== 0x0A) {
      return false;
    }
    // 整个 buffer 就是 "0\r\n\r\n"
    if (len === 5) {
      return true;
    }
    // '0' 前一字节必须是 \n，再前一字节必须是 \r（前一个 chunk 的终止符）
    if (len < 7) {
      return false;
    }
    return view[len - 7] === 0x0D && view[len - 6] === 0x0A;
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
