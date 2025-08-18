/**
 * @fileName : HttpRequest.ets
 * @author : @cxy
 * @date : 2025/8/15
 * @description : HTTP 请求解析类
 */
import { Utils } from "./Utils";
import { socket } from '@kit.NetworkKit';

/**
 * 上传文件接口定义
 */
export interface File {
  fieldName: string; // 表单字段名
  fileName: string; // 文件名
  contentType: string; // 文件类型
  data: ArrayBuffer; // 文件数据
}

/**
 * HTTP请求类
 * 用于解析和处理HTTP请求数据
 */
export class HttpRequest {
  public method: string = ''; // HTTP请求方法（GET、POST等）
  public path: string = ''; // 请求路径（不包含查询字符串）
  public version: string = ''; // HTTP版本
  public url: string = ''; // 完整的URL路径（包含查询字符串）
  public ip: string = ''; // 客户端IP地址
  public headers: Map<string, string> = new Map(); // 请求头集合
  public body: Record<string, string> = {}; // 解析后的请求体数据
  public query: Map<string, string> = new Map(); // 查询字符串参数
  public params: Record<string, string> = {}; // 路由参数
  public files: Record<string, File> = {}; // 上传的文件
  private rawBody: ArrayBuffer = new ArrayBuffer(0); // 原始请求体数据

  /**
   * 构造函数
   * @param data Socket消息信息
   */
  constructor(data: socket.SocketMessageInfo) {
    this.parseHeadersAndPath(data.message);
    this.parseClientInfo(data.remoteInfo);
  }

  /**
   * 获取请求的User-Agent
   * @returns User-Agent字符串
   */
  public get userAgent(): string {
    return this.get('user-agent') || '';
  }

  /**
   * 获取请求的Referer
   * @returns Referer字符串
   */
  public get referer(): string {
    return this.get('referer') || this.get('referrer') || '';
  }

  /**
   * 获取请求的Content-Length
   * @returns 内容长度
   */
  public get contentLength(): number {
    const length = this.get('content-length');
    return length ? parseInt(length) : 0;
  }

  /**
   * 解析请求体数据
   * 根据Content-Type自动选择解析方式
   */
  public parseBody(): void {
    const contentType = this.headers.get('content-type');
    if (contentType && this.rawBody.byteLength > 0) {
      if (contentType.includes('application/json')) {
        try {
          const bodyStr = Utils.arrayBufferToStr(this.rawBody);
          this.body = JSON.parse(bodyStr);
        } catch (error) {
          console.error("Failed to parse JSON body", error);
          this.body = {};
        }
      } else if (contentType.includes('application/x-www-form-urlencoded')) {
        const bodyStr = Utils.arrayBufferToStr(this.rawBody);
        const params: Record<string, string> = {};
        const pairs = bodyStr.split('&');
        for (const pair of pairs) {
          const parts = pair.split('=');
          if (parts.length === 2) {
            const key = decodeURIComponent(parts[0].replace(/\+/g, ' '));
            const value = decodeURIComponent(parts[1].replace(/\+/g, ' '));
            params[key] = value;
          }
        }
        this.body = params;
      } else if (contentType.includes('multipart/form-data')) {
        this.parseMultipartFormData(contentType, this.rawBody);
      } else {
        // 对于其他类型，保持原始数据
      }
    }
  }

  /**
   * 获取原始请求体数据
   * @returns 原始ArrayBuffer数据
   */
  public getRawBody(): ArrayBuffer {
    return this.rawBody;
  }

  /**
   * 获取请求头
   * @param headerName 请求头名称
   * @returns 请求头值
   */
  public get(headerName: string): string | undefined {
    return this.headers.get(headerName.toLowerCase());
  }

  /**
   * 检查是否为指定的Content-Type
   * @param type 要检查的内容类型
   * @returns 是否匹配
   */
  public is(type: string): boolean {
    const contentType = this.get('content-type');
    return contentType ? contentType.includes(type) : false;
  }

  /**
   * 解析HTTP请求头和路径
   * @param requestData 原始请求数据
   */
  private parseHeadersAndPath(requestData: ArrayBuffer): void {
    const requestStr = Utils.arrayBufferToStr(requestData)
    const headerEndIndex = requestStr.indexOf('\r\n\r\n');

    if (headerEndIndex === -1) {
      // Invalid request, no headers found
      return;
    }

    const headerStr = requestStr.substring(0, headerEndIndex);
    const bodyData = requestData.slice(headerEndIndex + 4);

    const headerLines = headerStr.split('\r\n');
    const requestLine = headerLines.shift();

    if (requestLine) {
      const requestLineParts = requestLine.split(' ');
      this.method = requestLineParts[0];
      const fullPath = requestLineParts[1];
      this.version = requestLineParts[2];

      this.url = fullPath; // 保存完整URL

      const queryIndex = fullPath.indexOf('?');
      if (queryIndex !== -1) {
        this.path = fullPath.substring(0, queryIndex);
        const queryString = fullPath.substring(queryIndex + 1);
        this.parseQuery(queryString);
      } else {
        this.path = fullPath;
      }
    }

    headerLines.forEach(line => {
      const parts = line.split(': ');
      if (parts.length === 2) {
        this.headers.set(parts[0].toLowerCase(), parts[1]);
      }
    });

    if (bodyData.byteLength > 0) {
      this.rawBody = bodyData;
    }
  }

  /**
   * 解析查询字符串参数
   * @param queryString 查询字符串
   */
  private parseQuery(queryString: string): void {
    const params = queryString.split('&');
    params.forEach(param => {
      const parts = param.split('=');
      if (parts.length === 2) {
        this.query.set(decodeURIComponent(parts[0]), decodeURIComponent(parts[1]));
      }
    });
  }

  /**
   * 从Content-Type中解析boundary
   * @param contentType Content-Type头部值
   * @returns boundary字符串或null
   */
  private parseBoundary(contentType: string): string | null {
    const match = contentType.match(/boundary=(.+)/);
    return match ? match[1].trim() : null;
  }

  /**
   * 解析multipart/form-data格式的请求体
   * @param contentType Content-Type头部值
   * @param body 请求体数据
   */
  private parseMultipartFormData(contentType: string, body: ArrayBuffer): void {
    this.body = {}; // 初始化body为空对象
    const boundary = this.parseBoundary(contentType);
    if (!boundary) {
      return;
    }

    const bodyStr = Utils.arrayBufferToStr(body);
    const parts = bodyStr.split('--' + boundary);

    for (const part of parts) {
      if (part.trim() === '' || part.trim() === '--') {
        continue;
      }

      const headerEndIndex = part.indexOf('\r\n\r\n');
      if (headerEndIndex === -1) {
        continue;
      }

      const headerPart = part.substring(0, headerEndIndex).trim();
      const bodyPartStr = part.substring(headerEndIndex + 4).trim();

      const contentDispositionMatch =
        headerPart.match(/Content-Disposition: form-data; name=\"([^\"]+)\"(?:; filename=\"([^\"]+)\")?/);
      if (!contentDispositionMatch) {
        continue;
      }

      const fieldName = contentDispositionMatch[1];
      const fileName = contentDispositionMatch[2];

      if (fileName) {
        // 文件上传，存储到files中
        const contentTypeMatch = headerPart.match(/Content-Type: (.+)/);
        const contentTypeHeader = contentTypeMatch ? contentTypeMatch[1].trim() : 'application/octet-stream';
        this.files[fieldName] = {
          fieldName: fieldName,
          fileName: fileName,
          contentType: contentTypeHeader,
          data: Utils.strToArrayBuffer(bodyPartStr)
        };
      } else {
        // 普通表单字段，存储到body中
        this.body[fieldName] = bodyPartStr;
      }
    }
  }

  /**
   * 解析客户端信息
   * 包括IP地址、代理信息等
   * @param info Socket远程信息
   */
  private parseClientInfo(info: socket.SocketRemoteInfo): void {
    // 解析IP地址
    if (info) {
      this.ip = info.address;
    }

    // 检查代理头部
    const xForwardedFor = this.get('x-forwarded-for');
    if (xForwardedFor) {
      const ips = xForwardedFor.split(',').map(ip => ip.trim());
      if (ips.length > 0) {
        this.ip = ips[0]; // 使用第一个IP作为真实IP
      }
    }

    const xRealIp = this.get('x-real-ip');
    if (xRealIp) {
      this.ip = xRealIp;
    }
  }
}