/**
 * @fileName : HttpRequest.ets
 * @author : @cxy
 * @date : 2025/8/15
 * @description : HTTP 请求解析类
 */
import { Utils } from "./Utils";
import type { WebServer } from './WebServer';

export interface File {
  fieldName: string;
  fileName: string;
  contentType: string;
  data: ArrayBuffer;
}

export class HttpRequest {
  public app: WebServer;
  public method: string = '';
  public path: string = '';
  public version: string = '';
  public headers: Map<string, string> = new Map();
  public body: ArrayBuffer | Record<string, Object> | null = null;
  public query: Map<string, string> = new Map();
  public params: Record<string, string> = {};
  public files: Record<string, File> = {};

  constructor(app: WebServer, requestData: ArrayBuffer) {
    this.app = app;
    this.parseHeadersAndPath(requestData);
  }

  public getConfig(key: string): Object | undefined {
    return this.app.getConfig(key);
  }

  public parseBody(): void {
    const contentType = this.headers.get('content-type');
    if (contentType && this.body instanceof ArrayBuffer) {
      if (contentType.includes('application/json')) {
        try {
          const bodyStr = Utils.arrayBufferToStr(this.body);
          this.body = JSON.parse(bodyStr);
        } catch (error) {
          console.error("Failed to parse JSON body", error);
        }
      } else if (contentType.includes('application/x-www-form-urlencoded')) {
        const bodyStr = Utils.arrayBufferToStr(this.body);
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
        this.parseMultipartFormData(this.body, contentType);
      }
    }
  }

  private parseHeadersAndPath(requestData: ArrayBuffer): void {
    const requestStr = Utils.arrayBufferToStr(requestData, 'binary')
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
      this.body = bodyData;
    }
  }

  private parseQuery(queryString: string): void {
    const params = queryString.split('&');
    params.forEach(param => {
      const parts = param.split('=');
      if (parts.length === 2) {
        this.query.set(decodeURIComponent(parts[0]), decodeURIComponent(parts[1]));
      }
    });
  }

  private parseBoundary(contentType: string): string | null {
    const match = contentType.match(/boundary=(.+)/);
    return match ? match[1].trim() : null;
  }

  private parseMultipartFormData(body: ArrayBuffer, contentType: string): void {
    this.body = {}; // Initialize
    const boundary = this.parseBoundary(contentType);
    if (!boundary) {
      return;
    }

    const bodyStr = Utils.arrayBufferToStr(body, 'binary');
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
        const contentTypeMatch = headerPart.match(/Content-Type: (.+)/);
        const contentTypeHeader = contentTypeMatch ? contentTypeMatch[1].trim() : 'application/octet-stream';
        this.files[fieldName] = {
          fieldName: fieldName,
          fileName: fileName,
          contentType: contentTypeHeader,
          data: Utils.strToArrayBuffer(bodyPartStr, 'binary')
        };
      } else {
        (this.body as Record<string, string>)[fieldName] = bodyPartStr;
      }
    }
  }
}