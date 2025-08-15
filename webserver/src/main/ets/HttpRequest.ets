/**
 * @fileName : HttpRequest.ets
 * @author : @cxy
 * @date : 2025/8/15
 * @description : HTTP 请求解析类
 */
import { Utils } from "./Utils";

export class HttpRequest {
  public method: string = '';
  public path: string = '';
  public version: string = '';
  public headers: Map<string, string> = new Map();
  public body: ArrayBuffer | null = null;
  public query: Map<string, string> = new Map();

  constructor(requestData: ArrayBuffer) {
    this.parse(requestData);
  }

  public getBodyAsJson(): object | null {
    if (this.body) {
      try {
        const bodyStr = Utils.arrayBufferToStr(this.body)
        return JSON.parse(bodyStr);
      } catch (e) {
        console.error("Failed to parse body as JSON", e);
        return null;
      }
    }
    return null;
  }

  private parse(requestData: ArrayBuffer): void {
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
}
